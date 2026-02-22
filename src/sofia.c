/*
 * Sofia CLI - Prompt composer for LLM-driven writing workflows
 * 
 * MIT License - See LICENSE for details
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdarg.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>
#include <dirent.h>
#include <errno.h>

#include "../vendor/tomlc99/toml.h"

#define MAX_SWITCHES 256
#define MAX_ALIASES 64
#define MAX_INCLUDES 32
#define MAX_VARS 256
#define MAX_GROUPS 32
#define MAX_WARNINGS 64
#define MAX_PATH_LEN 1024
#define MAX_PROMPT_LEN 65536
#define MAX_LINE_LEN 4096
#define MAX_DEPTH 8

/* Forward declarations */
typedef struct SwitchDef SwitchDef;
typedef struct VarEntry VarEntry;
typedef struct GroupVariant GroupVariant;
typedef struct Registry Registry;
typedef struct ResolveResult ResolveResult;

/* Data structures */
struct SwitchDef {
    char *name;           /* canonical switch name, e.g., "-process" */
    char *help;
    char *tool;
    char *path;
    char *prompt;
    char *id;
    char *exclusive_group;
    char **includes;
    int includes_count;
    char **aliases;
    int aliases_count;
    char **tags;
    int tags_count;
    bool is_default_variant;
};

struct VarEntry {
    char *key;   /* e.g., "paths.incoming" */
    char *value;
};

struct GroupVariant {
    char *group_name;
    char **variants;
    int variant_count;
};

struct Registry {
    SwitchDef switches[MAX_SWITCHES];
    int switch_count;
    
    /* alias -> canonical name mapping */
    struct { char *alias; char *canonical; } aliases[MAX_ALIASES * MAX_SWITCHES];
    int alias_count;
    
    VarEntry vars[MAX_VARS];
    int var_count;
    
    GroupVariant groups[MAX_GROUPS];
    int group_count;
    
    /* Global defaults */
    struct { char *group; char *variant; } defaults[MAX_GROUPS];
    int default_count;
};

struct ResolveResult {
    char *resolved[MAX_SWITCHES];
    int resolved_count;
    
    char *included[MAX_SWITCHES];
    int included_count;
    
    struct { char *group; char *chosen; char *source; } selected_groups[MAX_GROUPS];
    int selected_group_count;
    
    char *warnings[MAX_WARNINGS];
    int warning_count;
};

/* Global state */
static char g_root_path[MAX_PATH_LEN];
static Registry g_registry;

/* Utility functions */
static char *strdup_safe(const char *s) {
    if (!s) return NULL;
    char *dup = strdup(s);
    if (!dup) {
        fprintf(stderr, "Out of memory\n");
        exit(1);
    }
    return dup;
}

static char *read_file(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) return NULL;
    
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    
    char *buf = malloc(len + 1);
    if (!buf) {
        fclose(f);
        return NULL;
    }
    
    size_t read = fread(buf, 1, len, f);
    buf[read] = '\0';
    fclose(f);
    return buf;
}

static bool starts_with(const char *str, const char *prefix) {
    return strncmp(str, prefix, strlen(prefix)) == 0;
}

/* Extract TOML front matter from markdown (between +++ delimiters) */
static char *extract_front_matter(const char *md, char **body_out) {
    const char *fm_start = NULL;
    
    /* Check if file starts with +++ */
    if (strncmp(md, "+++", 3) == 0) {
        fm_start = md + 3;
        if (*fm_start == '\n') fm_start++;
    } else {
        /* Look for +++ after a newline */
        const char *p = strstr(md, "\n+++");
        if (p) {
            fm_start = p + 4;
            if (*fm_start == '\n') fm_start++;
        }
    }
    
    if (!fm_start) {
        if (body_out) *body_out = strdup_safe(md);
        return NULL;
    }
    
    /* Find closing +++ */
    const char *fm_end = strstr(fm_start, "\n+++");
    if (!fm_end) {
        /* Try +++ at start of line without leading content */
        fm_end = strstr(fm_start, "+++");
        if (fm_end && fm_end > fm_start && *(fm_end - 1) != '\n') {
            fm_end = NULL;
        }
    }
    
    if (!fm_end) {
        if (body_out) *body_out = strdup_safe(md);
        return NULL;
    }
    
    size_t fm_len = fm_end - fm_start;
    char *fm = malloc(fm_len + 1);
    memcpy(fm, fm_start, fm_len);
    fm[fm_len] = '\0';
    
    if (body_out) {
        const char *body_start = fm_end;
        if (*body_start == '\n') body_start++;
        body_start += 3; /* skip "+++" */
        if (*body_start == '\n') body_start++;
        *body_out = strdup_safe(body_start);
    }
    
    return fm;
}

/* Extract content from fenced code block with given label */
static char *extract_fenced_block(const char *body, const char *label) {
    char pattern[64];
    snprintf(pattern, sizeof(pattern), "```%s", label);
    
    const char *start = strstr(body, pattern);
    if (!start) return NULL;
    
    /* Find end of opening fence line */
    start = strchr(start, '\n');
    if (!start) return NULL;
    start++;
    
    /* Find closing fence */
    const char *end = strstr(start, "\n```");
    if (!end) {
        end = strstr(start, "```");
        if (!end) return NULL;
    }
    
    size_t len = end - start;
    char *block = malloc(len + 1);
    memcpy(block, start, len);
    block[len] = '\0';
    
    return block;
}

/* Parse a switch definition from markdown file */
static bool parse_switch_file(const char *path, SwitchDef *out) {
    char *content = read_file(path);
    if (!content) return false;
    
    char *body = NULL;
    char *fm_str = extract_front_matter(content, &body);
    if (!fm_str) {
        free(content);
        free(body);
        return false;
    }
    
    /* Parse TOML front matter */
    char errbuf[256];
    toml_table_t *fm = toml_parse(fm_str, errbuf, sizeof(errbuf));
    free(fm_str);
    
    if (!fm) {
        fprintf(stderr, "TOML parse error in %s: %s\n", path, errbuf);
        free(content);
        free(body);
        return false;
    }
    
    /* Check type */
    toml_datum_t type_d = toml_string_in(fm, "type");
    if (!type_d.ok || strcmp(type_d.u.s, "switch") != 0) {
        free(type_d.u.s);
        toml_free(fm);
        free(content);
        free(body);
        return false;
    }
    free(type_d.u.s);
    
    /* Extract fields */
    memset(out, 0, sizeof(*out));
    out->path = strdup_safe(path);
    
    toml_datum_t d;
    
    d = toml_string_in(fm, "switch");
    if (d.ok) out->name = d.u.s;
    
    d = toml_string_in(fm, "help");
    if (d.ok) out->help = d.u.s;
    
    d = toml_string_in(fm, "tool");
    if (d.ok) out->tool = d.u.s;
    
    d = toml_string_in(fm, "id");
    if (d.ok) out->id = d.u.s;
    
    d = toml_string_in(fm, "exclusive_group");
    if (d.ok) out->exclusive_group = d.u.s;
    
    d = toml_bool_in(fm, "default");
    if (d.ok) out->is_default_variant = d.u.b;
    
    /* Parse includes array */
    toml_array_t *includes = toml_array_in(fm, "includes");
    if (includes) {
        int n = toml_array_nelem(includes);
        out->includes = malloc(sizeof(char*) * n);
        out->includes_count = 0;
        for (int i = 0; i < n; i++) {
            toml_datum_t inc = toml_string_at(includes, i);
            if (inc.ok) {
                out->includes[out->includes_count++] = inc.u.s;
            }
        }
    }
    
    /* Parse aliases array */
    toml_array_t *aliases = toml_array_in(fm, "aliases");
    if (aliases) {
        int n = toml_array_nelem(aliases);
        out->aliases = malloc(sizeof(char*) * n);
        out->aliases_count = 0;
        for (int i = 0; i < n; i++) {
            toml_datum_t al = toml_string_at(aliases, i);
            if (al.ok) {
                out->aliases[out->aliases_count++] = al.u.s;
            }
        }
    }
    
    /* Parse tags array */
    toml_array_t *tags = toml_array_in(fm, "tags");
    if (tags) {
        int n = toml_array_nelem(tags);
        out->tags = malloc(sizeof(char*) * n);
        out->tags_count = 0;
        for (int i = 0; i < n; i++) {
            toml_datum_t tg = toml_string_at(tags, i);
            if (tg.ok) {
                out->tags[out->tags_count++] = tg.u.s;
            }
        }
    }
    
    toml_free(fm);
    
    /* Extract prompt block from body */
    if (body) {
        out->prompt = extract_fenced_block(body, "prompt");
        free(body);
    }
    
    free(content);
    return out->name != NULL;
}

/* Parse vars file */
static bool parse_vars_file(const char *path) {
    char *content = read_file(path);
    if (!content) return false;
    
    char *body = NULL;
    char *fm_str = extract_front_matter(content, &body);
    if (!fm_str) {
        free(content);
        free(body);
        return false;
    }
    
    char errbuf[256];
    toml_table_t *fm = toml_parse(fm_str, errbuf, sizeof(errbuf));
    free(fm_str);
    
    if (!fm) {
        free(content);
        free(body);
        return false;
    }
    
    toml_datum_t type_d = toml_string_in(fm, "type");
    if (!type_d.ok || strcmp(type_d.u.s, "vars") != 0) {
        free(type_d.u.s);
        toml_free(fm);
        free(content);
        free(body);
        return false;
    }
    free(type_d.u.s);
    
    toml_datum_t ns_d = toml_string_in(fm, "namespace");
    if (!ns_d.ok) {
        toml_free(fm);
        free(content);
        free(body);
        return false;
    }
    char *ns = ns_d.u.s;
    toml_free(fm);
    
    /* Extract toml block from body */
    if (body) {
        char *toml_block = extract_fenced_block(body, "toml");
        if (toml_block) {
            toml_table_t *vars = toml_parse(toml_block, errbuf, sizeof(errbuf));
            if (vars) {
                /* Iterate all keys */
                for (int i = 0; ; i++) {
                    const char *key = toml_key_in(vars, i);
                    if (!key) break;
                    
                    toml_datum_t val = toml_string_in(vars, key);
                    if (val.ok) {
                        char full_key[256];
                        snprintf(full_key, sizeof(full_key), "%s.%s", ns, key);
                        
                        if (g_registry.var_count < MAX_VARS) {
                            g_registry.vars[g_registry.var_count].key = strdup_safe(full_key);
                            g_registry.vars[g_registry.var_count].value = val.u.s;
                            g_registry.var_count++;
                        }
                    } else {
                        /* Try bool */
                        toml_datum_t bval = toml_bool_in(vars, key);
                        if (bval.ok) {
                            char full_key[256];
                            snprintf(full_key, sizeof(full_key), "%s.%s", ns, key);
                            
                            if (g_registry.var_count < MAX_VARS) {
                                g_registry.vars[g_registry.var_count].key = strdup_safe(full_key);
                                g_registry.vars[g_registry.var_count].value = strdup_safe(bval.u.b ? "true" : "false");
                                g_registry.var_count++;
                            }
                        }
                    }
                }
                toml_free(vars);
            }
            free(toml_block);
        }
        free(body);
    }
    
    free(ns);
    free(content);
    return true;
}

/* Parse defaults file */
static bool parse_defaults_file(const char *path) {
    char *content = read_file(path);
    if (!content) return false;
    
    char *body = NULL;
    char *fm_str = extract_front_matter(content, &body);
    free(fm_str);
    
    if (!body) {
        free(content);
        return false;
    }
    
    char *toml_block = extract_fenced_block(body, "toml");
    free(body);
    
    if (!toml_block) {
        free(content);
        return false;
    }
    
    char errbuf[256];
    toml_table_t *root = toml_parse(toml_block, errbuf, sizeof(errbuf));
    free(toml_block);
    free(content);
    
    if (!root) return false;
    
    /* Parse [groups.*] tables */
    toml_table_t *groups = toml_table_in(root, "groups");
    if (groups) {
        for (int i = 0; ; i++) {
            const char *gname = toml_key_in(groups, i);
            if (!gname) break;
            
            toml_table_t *gtbl = toml_table_in(groups, gname);
            if (gtbl) {
                toml_datum_t def = toml_string_in(gtbl, "default");
                if (def.ok && g_registry.default_count < MAX_GROUPS) {
                    g_registry.defaults[g_registry.default_count].group = strdup_safe(gname);
                    g_registry.defaults[g_registry.default_count].variant = def.u.s;
                    g_registry.default_count++;
                }
            }
        }
    }
    
    toml_free(root);
    return true;
}

/* Recursively scan directory for .md files */
static void scan_directory(const char *dir_path, void (*handler)(const char *)) {
    DIR *dir = opendir(dir_path);
    if (!dir) return;
    
    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (entry->d_name[0] == '.') continue;
        
        char path[MAX_PATH_LEN];
        snprintf(path, sizeof(path), "%s/%s", dir_path, entry->d_name);
        
        struct stat st;
        if (stat(path, &st) != 0) continue;
        
        if (S_ISDIR(st.st_mode)) {
            scan_directory(path, handler);
        } else if (S_ISREG(st.st_mode)) {
            size_t len = strlen(entry->d_name);
            if (len > 3 && strcmp(entry->d_name + len - 3, ".md") == 0) {
                handler(path);
            }
        }
    }
    
    closedir(dir);
}

/* Handler for loading switch files */
static void load_switch_handler(const char *path) {
    SwitchDef sw;
    if (parse_switch_file(path, &sw)) {
        if (g_registry.switch_count < MAX_SWITCHES) {
            g_registry.switches[g_registry.switch_count++] = sw;
            
            /* Register canonical name as alias to itself */
            if (g_registry.alias_count < MAX_ALIASES * MAX_SWITCHES) {
                g_registry.aliases[g_registry.alias_count].alias = strdup_safe(sw.name);
                g_registry.aliases[g_registry.alias_count].canonical = strdup_safe(sw.name);
                g_registry.alias_count++;
            }
            
            /* Register aliases */
            for (int i = 0; i < sw.aliases_count; i++) {
                if (g_registry.alias_count < MAX_ALIASES * MAX_SWITCHES) {
                    g_registry.aliases[g_registry.alias_count].alias = strdup_safe(sw.aliases[i]);
                    g_registry.aliases[g_registry.alias_count].canonical = strdup_safe(sw.name);
                    g_registry.alias_count++;
                }
            }
            
            /* Register in exclusive group */
            if (sw.exclusive_group) {
                int gi = -1;
                for (int i = 0; i < g_registry.group_count; i++) {
                    if (strcmp(g_registry.groups[i].group_name, sw.exclusive_group) == 0) {
                        gi = i;
                        break;
                    }
                }
                if (gi < 0 && g_registry.group_count < MAX_GROUPS) {
                    gi = g_registry.group_count++;
                    g_registry.groups[gi].group_name = strdup_safe(sw.exclusive_group);
                    g_registry.groups[gi].variants = malloc(sizeof(char*) * MAX_SWITCHES);
                    g_registry.groups[gi].variant_count = 0;
                }
                if (gi >= 0) {
                    g_registry.groups[gi].variants[g_registry.groups[gi].variant_count++] = strdup_safe(sw.name);
                }
            }
        }
    }
}

/* Handler for loading vars files */
static void load_vars_handler(const char *path) {
    parse_vars_file(path);
}

/* Load the entire library */
static void load_library(void) {
    char lib_path[MAX_PATH_LEN];
    snprintf(lib_path, sizeof(lib_path), "%s/library", g_root_path);
    
    /* Load switches */
    scan_directory(lib_path, load_switch_handler);
    
    /* Load vars */
    scan_directory(lib_path, load_vars_handler);
    
    /* Load defaults */
    char defaults_path[MAX_PATH_LEN];
    snprintf(defaults_path, sizeof(defaults_path), "%s/config/defaults.md", g_root_path);
    parse_defaults_file(defaults_path);
}

/* Lookup canonical switch name from alias */
static const char *resolve_alias(const char *name) {
    for (int i = 0; i < g_registry.alias_count; i++) {
        if (strcmp(g_registry.aliases[i].alias, name) == 0) {
            return g_registry.aliases[i].canonical;
        }
    }
    return NULL;
}

/* Lookup switch definition by canonical name */
static SwitchDef *find_switch(const char *name) {
    for (int i = 0; i < g_registry.switch_count; i++) {
        if (strcmp(g_registry.switches[i].name, name) == 0) {
            return &g_registry.switches[i];
        }
    }
    return NULL;
}

/* Lookup variable value */
static const char *get_var(const char *key) {
    for (int i = 0; i < g_registry.var_count; i++) {
        if (strcmp(g_registry.vars[i].key, key) == 0) {
            return g_registry.vars[i].value;
        }
    }
    return NULL;
}

/* Check if switch is in resolved list */
static bool in_resolved(ResolveResult *r, const char *name) {
    for (int i = 0; i < r->resolved_count; i++) {
        if (strcmp(r->resolved[i], name) == 0) return true;
    }
    return false;
}

/* Add warning */
static void add_warning(ResolveResult *r, const char *fmt, ...) {
    if (r->warning_count >= MAX_WARNINGS) return;
    
    char buf[512];
    va_list args;
    va_start(args, fmt);
    vsnprintf(buf, sizeof(buf), fmt, args);
    va_end(args);
    
    r->warnings[r->warning_count++] = strdup_safe(buf);
}

/* DFS to expand includes with cycle detection */
static void expand_includes(const char *name, ResolveResult *r, const char **cli_switches, int cli_count, 
                           const char **visited, int *visited_count, int depth) {
    if (depth > MAX_DEPTH) {
        add_warning(r, "Max include depth exceeded at %s", name);
        return;
    }
    
    /* Cycle detection */
    for (int i = 0; i < *visited_count; i++) {
        if (strcmp(visited[i], name) == 0) {
            add_warning(r, "Include cycle detected at %s", name);
            return;
        }
    }
    
    if (in_resolved(r, name)) return;
    
    visited[(*visited_count)++] = name;
    
    SwitchDef *sw = find_switch(name);
    if (!sw) {
        add_warning(r, "Missing switch definition: %s", name);
        return;
    }
    
    /* Expand includes first (pre-order) */
    for (int i = 0; i < sw->includes_count; i++) {
        const char *inc = resolve_alias(sw->includes[i]);
        if (!inc) {
            add_warning(r, "Unknown include %s in %s", sw->includes[i], name);
            continue;
        }
        
        expand_includes(inc, r, cli_switches, cli_count, visited, visited_count, depth + 1);
        
        /* Track as included if not from CLI */
        bool from_cli = false;
        for (int j = 0; j < cli_count; j++) {
            if (strcmp(cli_switches[j], inc) == 0) {
                from_cli = true;
                break;
            }
        }
        if (!from_cli && !in_resolved(r, inc)) {
            bool already_included = false;
            for (int j = 0; j < r->included_count; j++) {
                if (strcmp(r->included[j], inc) == 0) {
                    already_included = true;
                    break;
                }
            }
            if (!already_included) {
                r->included[r->included_count++] = strdup_safe(inc);
            }
        }
    }
    
    r->resolved[r->resolved_count++] = strdup_safe(name);
}

/* Find default variant for a group */
static const char *get_group_default(const char *group_name) {
    /* Check global defaults */
    for (int i = 0; i < g_registry.default_count; i++) {
        if (strcmp(g_registry.defaults[i].group, group_name) == 0) {
            return g_registry.defaults[i].variant;
        }
    }
    
    /* Check registry default flag */
    for (int i = 0; i < g_registry.group_count; i++) {
        if (strcmp(g_registry.groups[i].group_name, group_name) == 0) {
            for (int j = 0; j < g_registry.groups[i].variant_count; j++) {
                SwitchDef *sw = find_switch(g_registry.groups[i].variants[j]);
                if (sw && sw->is_default_variant) {
                    return sw->name;
                }
            }
        }
    }
    
    return NULL;
}

/* Check if switch is a variant of given group */
static bool is_variant_of(const char *sw_name, const char *group_name) {
    for (int i = 0; i < g_registry.group_count; i++) {
        if (strcmp(g_registry.groups[i].group_name, group_name) == 0) {
            for (int j = 0; j < g_registry.groups[i].variant_count; j++) {
                if (strcmp(g_registry.groups[i].variants[j], sw_name) == 0) {
                    return true;
                }
            }
        }
    }
    return false;
}

/* Resolve switches with includes and exclusive groups */
static ResolveResult resolve_switches(const char **requested, int req_count) {
    ResolveResult r = {0};
    
    /* Normalize aliases and validate */
    const char *cli_switches[MAX_SWITCHES];
    int cli_count = 0;
    
    for (int i = 0; i < req_count; i++) {
        const char *can = resolve_alias(requested[i]);
        if (!can) {
            add_warning(&r, "Unknown switch: %s", requested[i]);
            continue;
        }
        cli_switches[cli_count++] = can;
    }
    
    /* Expand includes with cycle detection */
    const char *visited[MAX_SWITCHES];
    int visited_count = 0;
    
    for (int i = 0; i < cli_count; i++) {
        expand_includes(cli_switches[i], &r, cli_switches, cli_count, visited, &visited_count, 0);
    }
    
    /* Handle exclusive groups */
    for (int gi = 0; gi < g_registry.group_count; gi++) {
        const char *group_name = g_registry.groups[gi].group_name;
        const char *chosen = NULL;
        const char *source = NULL;
        
        /* CLI wins */
        for (int i = 0; i < cli_count; i++) {
            if (is_variant_of(cli_switches[i], group_name)) {
                chosen = cli_switches[i];
                source = "cli";
            }
        }
        
        /* Else check includes */
        if (!chosen) {
            for (int i = 0; i < r.resolved_count; i++) {
                if (is_variant_of(r.resolved[i], group_name)) {
                    bool from_cli = false;
                    for (int j = 0; j < cli_count; j++) {
                        if (strcmp(cli_switches[j], r.resolved[i]) == 0) {
                            from_cli = true;
                            break;
                        }
                    }
                    if (!from_cli) {
                        chosen = r.resolved[i];
                        source = "tool";
                        break;
                    }
                }
            }
        }
        
        /* Else use defaults */
        if (!chosen) {
            chosen = get_group_default(group_name);
            if (chosen) source = "defaults";
        }
        
        /* Else use registry default */
        if (!chosen) {
            for (int j = 0; j < g_registry.groups[gi].variant_count; j++) {
                SwitchDef *sw = find_switch(g_registry.groups[gi].variants[j]);
                if (sw && sw->is_default_variant) {
                    chosen = sw->name;
                    source = "group";
                    break;
                }
            }
        }
        
        if (chosen) {
            /* Ensure chosen is in resolved */
            if (!in_resolved(&r, chosen)) {
                r.resolved[r.resolved_count++] = strdup_safe(chosen);
            }
            
            /* Remove other variants */
            for (int j = 0; j < g_registry.groups[gi].variant_count; j++) {
                const char *v = g_registry.groups[gi].variants[j];
                if (strcmp(v, chosen) != 0) {
                    for (int k = 0; k < r.resolved_count; k++) {
                        if (strcmp(r.resolved[k], v) == 0) {
                            add_warning(&r, "Removed conflicting variant %s in group %s (kept %s)", v, group_name, chosen);
                            /* Shift array */
                            for (int m = k; m < r.resolved_count - 1; m++) {
                                r.resolved[m] = r.resolved[m + 1];
                            }
                            r.resolved_count--;
                            k--;
                        }
                    }
                }
            }
            
            /* Record selection */
            r.selected_groups[r.selected_group_count].group = strdup_safe(group_name);
            r.selected_groups[r.selected_group_count].chosen = strdup_safe(chosen);
            r.selected_groups[r.selected_group_count].source = strdup_safe(source);
            r.selected_group_count++;
        }
    }
    
    return r;
}

/* Substitute variables in text */
static char *substitute_vars(const char *text) {
    static char buf[MAX_PROMPT_LEN];
    char *out = buf;
    const char *p = text;
    char *unresolved[64];
    int unresolved_count = 0;
    
    while (*p && (out - buf) < MAX_PROMPT_LEN - 256) {
        if (*p == '{') {
            const char *start = p + 1;
            const char *end = strchr(start, '}');
            if (end) {
                char key[128];
                size_t klen = end - start;
                if (klen < sizeof(key)) {
                    memcpy(key, start, klen);
                    key[klen] = '\0';
                    
                    const char *val = get_var(key);
                    if (val) {
                        size_t vlen = strlen(val);
                        memcpy(out, val, vlen);
                        out += vlen;
                    } else {
                        /* Keep original and track unresolved */
                        *out++ = '{';
                        memcpy(out, key, klen);
                        out += klen;
                        *out++ = '}';
                        
                        if (unresolved_count < 64) {
                            unresolved[unresolved_count++] = strdup_safe(key);
                        }
                    }
                    p = end + 1;
                    continue;
                }
            }
        }
        *out++ = *p++;
    }
    *out = '\0';
    
    /* Report unresolved variables */
    if (unresolved_count > 0) {
        fprintf(stderr, "Warning: Unresolved variables: ");
        for (int i = 0; i < unresolved_count; i++) {
            fprintf(stderr, "{%s}%s", unresolved[i], i < unresolved_count - 1 ? ", " : "\n");
            free(unresolved[i]);
        }
    }
    
    return strdup_safe(buf);
}

/* JSON string escaping */
static void json_escape(FILE *f, const char *s) {
    if (!s) {
        fprintf(f, "null");
        return;
    }
    fputc('"', f);
    while (*s) {
        switch (*s) {
            case '"': fprintf(f, "\\\""); break;
            case '\\': fprintf(f, "\\\\"); break;
            case '\n': fprintf(f, "\\n"); break;
            case '\r': fprintf(f, "\\r"); break;
            case '\t': fprintf(f, "\\t"); break;
            default: fputc(*s, f);
        }
        s++;
    }
    fputc('"', f);
}

/* Create session directory and write manifest */
static void write_session_manifest(const char *json_str) {
    time_t now = time(NULL);
    struct tm *tm = gmtime(&now);
    
    char dirname[64];
    strftime(dirname, sizeof(dirname), "%Y%m%d-%H%M%SZ", tm);
    
    char sess_path[MAX_PATH_LEN];
    snprintf(sess_path, sizeof(sess_path), "%s/sessions/%s", g_root_path, dirname);
    
    mkdir(sess_path, 0755);
    
    char manifest_path[MAX_PATH_LEN];
    snprintf(manifest_path, sizeof(manifest_path), "%s/manifest.json", sess_path);
    
    FILE *f = fopen(manifest_path, "w");
    if (f) {
        fprintf(f, "%s", json_str);
        fclose(f);
    }
}

/* Emit echo JSON */
static void emit_echo_json(const char **requested, int req_count, ResolveResult *r) {
    /* Build composed prompts */
    char *composed[MAX_SWITCHES];
    int composed_count = 0;
    
    for (int i = 0; i < r->resolved_count; i++) {
        SwitchDef *sw = find_switch(r->resolved[i]);
        if (sw && sw->prompt) {
            composed[composed_count++] = substitute_vars(sw->prompt);
        }
    }
    
    /* Determine report kind */
    const char *report_kind = "brief";
    for (int i = 0; i < r->selected_group_count; i++) {
        if (strcmp(r->selected_groups[i].group, "report-detail") == 0) {
            if (strstr(r->selected_groups[i].chosen, "verbose")) {
                report_kind = "verbose";
            }
            break;
        }
    }
    
    /* Determine git policy */
    const char *git_policy = "auto";
    const char *git_source = "defaults";
    for (int i = 0; i < r->selected_group_count; i++) {
        if (strcmp(r->selected_groups[i].group, "commit-policy") == 0) {
            if (strstr(r->selected_groups[i].chosen, "no-commit")) {
                git_policy = "none";
            }
            git_source = r->selected_groups[i].source;
            break;
        }
    }
    
    /* Build JSON to buffer for both stdout and manifest */
    char json_buf[MAX_PROMPT_LEN * 2];
    FILE *mem = fmemopen(json_buf, sizeof(json_buf), "w");
    
    fprintf(mem, "{\n");
    fprintf(mem, "  \"ui\": \"Organize notes: ");
    for (int i = 0; i < r->resolved_count; i++) {
        fprintf(mem, "%s%s", r->resolved[i], i < r->resolved_count - 1 ? ", " : "");
    }
    fprintf(mem, "\",\n");
    
    fprintf(mem, "  \"ask\": {\"confirm\": {\"default\": true, \"options\": [\"continue\", \"revise\", \"cancel\"]}},\n");
    
    fprintf(mem, "  \"data\": {\n");
    fprintf(mem, "    \"tool\": \"notator\",\n");
    
    /* requestedSwitches */
    fprintf(mem, "    \"requestedSwitches\": [");
    for (int i = 0; i < req_count; i++) {
        json_escape(mem, requested[i]);
        if (i < req_count - 1) fprintf(mem, ", ");
    }
    fprintf(mem, "],\n");
    
    /* includedSwitches */
    fprintf(mem, "    \"includedSwitches\": [");
    for (int i = 0; i < r->included_count; i++) {
        json_escape(mem, r->included[i]);
        if (i < r->included_count - 1) fprintf(mem, ", ");
    }
    fprintf(mem, "],\n");
    
    /* resolvedSwitches */
    fprintf(mem, "    \"resolvedSwitches\": [");
    for (int i = 0; i < r->resolved_count; i++) {
        json_escape(mem, r->resolved[i]);
        if (i < r->resolved_count - 1) fprintf(mem, ", ");
    }
    fprintf(mem, "],\n");
    
    /* variables */
    fprintf(mem, "    \"variables\": {");
    for (int i = 0; i < g_registry.var_count; i++) {
        json_escape(mem, g_registry.vars[i].key);
        fprintf(mem, ": ");
        json_escape(mem, g_registry.vars[i].value);
        if (i < g_registry.var_count - 1) fprintf(mem, ", ");
    }
    fprintf(mem, "},\n");
    
    /* composedPrompts */
    fprintf(mem, "    \"composedPrompts\": [");
    for (int i = 0; i < composed_count; i++) {
        json_escape(mem, composed[i]);
        if (i < composed_count - 1) fprintf(mem, ", ");
    }
    fprintf(mem, "],\n");
    
    /* sourceFiles */
    fprintf(mem, "    \"sourceFiles\": {");
    bool first = true;
    for (int i = 0; i < r->resolved_count; i++) {
        SwitchDef *sw = find_switch(r->resolved[i]);
        if (sw) {
            if (!first) fprintf(mem, ", ");
            json_escape(mem, r->resolved[i]);
            fprintf(mem, ": ");
            /* Make path relative */
            const char *rel = sw->path;
            if (starts_with(sw->path, g_root_path)) {
                rel = sw->path + strlen(g_root_path) + 1;
            }
            json_escape(mem, rel);
            first = false;
        }
    }
    fprintf(mem, "},\n");
    
    /* selectedGroups */
    fprintf(mem, "    \"selectedGroups\": {");
    for (int i = 0; i < r->selected_group_count; i++) {
        json_escape(mem, r->selected_groups[i].group);
        fprintf(mem, ": {\"chosen\": ");
        json_escape(mem, r->selected_groups[i].chosen);
        fprintf(mem, ", \"source\": ");
        json_escape(mem, r->selected_groups[i].source);
        fprintf(mem, "}");
        if (i < r->selected_group_count - 1) fprintf(mem, ", ");
    }
    fprintf(mem, "},\n");
    
    /* events (empty for MVP) */
    fprintf(mem, "    \"events\": [],\n");
    
    /* report */
    const char *report_dir = get_var("report.dir");
    const char *report_file = strcmp(report_kind, "brief") == 0 
        ? get_var("report.brief_filename") 
        : get_var("report.verbose_filename");
    fprintf(mem, "    \"report\": {\"kind\": \"%s\", \"intendedPath\": \"%s/%s\"},\n",
            report_kind, 
            report_dir ? report_dir : "reports",
            report_file ? report_file : (strcmp(report_kind, "brief") == 0 ? "brief.md" : "full.md"));
    
    /* git */
    fprintf(mem, "    \"git\": {\"policy\": \"%s\", \"source\": \"%s\"},\n", git_policy, git_source);
    
    /* warnings */
    fprintf(mem, "    \"warnings\": [");
    for (int i = 0; i < r->warning_count; i++) {
        json_escape(mem, r->warnings[i]);
        if (i < r->warning_count - 1) fprintf(mem, ", ");
    }
    fprintf(mem, "]\n");
    
    fprintf(mem, "  },\n");
    fprintf(mem, "  \"next\": {\"cmd\": \"notator.run\", \"args\": {\"apply\": false}}\n");
    fprintf(mem, "}\n");
    
    fclose(mem);
    
    /* Output to stdout */
    printf("%s", json_buf);
    
    /* Write session manifest */
    write_session_manifest(json_buf);
    
    /* Cleanup */
    for (int i = 0; i < composed_count; i++) {
        free(composed[i]);
    }
}

/* notator list command */
static int cmd_notator_list(void) {
    load_library();
    
    printf("%-20s %-60s %s\n", "SWITCH", "HELP", "SOURCE");
    printf("%-20s %-60s %s\n", "------", "----", "------");
    
    for (int i = 0; i < g_registry.switch_count; i++) {
        SwitchDef *sw = &g_registry.switches[i];
        if (sw->tool && (strcmp(sw->tool, "notator") == 0 || strcmp(sw->tool, "shared") == 0)) {
            const char *rel = sw->path;
            if (starts_with(sw->path, g_root_path)) {
                rel = sw->path + strlen(g_root_path) + 1;
            }
            printf("%-20s %-60s %s\n", sw->name, sw->help ? sw->help : "", rel);
        }
    }
    
    return 0;
}

/* notator run command */
static int cmd_notator_run(int argc, const char **argv) {
    load_library();
    
    /* Collect switches from argv */
    const char *switches[MAX_SWITCHES];
    int switch_count = 0;
    
    for (int i = 0; i < argc; i++) {
        if (argv[i][0] == '-') {
            switches[switch_count++] = argv[i];
        }
    }
    
    if (switch_count == 0) {
        fprintf(stderr, "Usage: sofia notator run <switches...>\n");
        fprintf(stderr, "Example: sofia notator run -process -preview\n");
        return 1;
    }
    
    ResolveResult r = resolve_switches(switches, switch_count);
    emit_echo_json(switches, switch_count, &r);
    
    return 0;
}

/* Main entry point */
int main(int argc, char **argv) {
    /* Determine root path (parent of src/) */
    char exe_path[MAX_PATH_LEN];
    if (realpath(argv[0], exe_path)) {
        char *last_slash = strrchr(exe_path, '/');
        if (last_slash) {
            *last_slash = '\0';
            /* Go up from bin/ or src/ */
            last_slash = strrchr(exe_path, '/');
            if (last_slash) {
                *last_slash = '\0';
                strncpy(g_root_path, exe_path, sizeof(g_root_path) - 1);
            }
        }
    }
    
    /* Fallback: use current directory */
    if (g_root_path[0] == '\0') {
        getcwd(g_root_path, sizeof(g_root_path));
    }
    
    if (argc < 2) {
        fprintf(stderr, "Usage: sofia <command> [args...]\n");
        fprintf(stderr, "Commands:\n");
        fprintf(stderr, "  notator list    List available switches\n");
        fprintf(stderr, "  notator run     Run with switches\n");
        return 1;
    }
    
    if (strcmp(argv[1], "notator") == 0) {
        if (argc < 3) {
            fprintf(stderr, "Usage: sofia notator <list|run> [args...]\n");
            return 1;
        }
        
        if (strcmp(argv[2], "list") == 0) {
            return cmd_notator_list();
        } else if (strcmp(argv[2], "run") == 0) {
            return cmd_notator_run(argc - 3, (const char **)&argv[3]);
        } else {
            fprintf(stderr, "Unknown notator subcommand: %s\n", argv[2]);
            return 1;
        }
    } else {
        fprintf(stderr, "Unknown command: %s\n", argv[1]);
        return 1;
    }
    
    return 0;
}
