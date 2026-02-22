/*
 * Sofia Extract - ChatGPT conversation extractor
 * Parses conversations.json exports and filters by project/topic
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <time.h>
#include <ctype.h>
#include <dirent.h>
#include <sys/stat.h>

/* Simple JSON value extraction (not a full parser, but sufficient for ChatGPT exports) */

static char *read_file(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    char *buf = malloc(len + 1);
    if (!buf) { fclose(f); return NULL; }
    size_t read = fread(buf, 1, len, f);
    buf[read] = '\0';
    fclose(f);
    return buf;
}

static char *json_string_value(const char *json, const char *key) {
    char pattern[256];
    snprintf(pattern, sizeof(pattern), "\"%s\":", key);
    const char *p = strstr(json, pattern);
    if (!p) return NULL;
    p += strlen(pattern);
    while (*p == ' ' || *p == '\t' || *p == '\n') p++;
    if (*p != '"') return NULL;
    p++;
    const char *end = p;
    while (*end && *end != '"') {
        if (*end == '\\' && *(end+1)) end += 2;
        else end++;
    }
    size_t len = end - p;
    char *val = malloc(len + 1);
    memcpy(val, p, len);
    val[len] = '\0';
    return val;
}

static double json_number_value(const char *json, const char *key) {
    char pattern[256];
    snprintf(pattern, sizeof(pattern), "\"%s\":", key);
    const char *p = strstr(json, pattern);
    if (!p) return 0;
    p += strlen(pattern);
    while (*p == ' ' || *p == '\t' || *p == '\n') p++;
    return atof(p);
}

static bool contains_ci(const char *haystack, const char *needle) {
    if (!haystack || !needle) return false;
    size_t hlen = strlen(haystack);
    size_t nlen = strlen(needle);
    if (nlen > hlen) return false;
    for (size_t i = 0; i <= hlen - nlen; i++) {
        bool match = true;
        for (size_t j = 0; j < nlen; j++) {
            if (tolower((unsigned char)haystack[i+j]) != tolower((unsigned char)needle[j])) {
                match = false;
                break;
            }
        }
        if (match) return true;
    }
    return false;
}

/* Match confidence levels */
typedef enum {
    CONF_NONE = 0,
    CONF_LOW,      /* Only in content, weak signal */
    CONF_MEDIUM,   /* Multiple mentions in content */
    CONF_HIGH      /* In title or very strong content match */
} Confidence;

static const char *conf_names[] = {"NONE", "LOW", "MEDIUM", "HIGH"};

/* Conversation structure */
typedef struct {
    char *title;
    double create_time;
    double update_time;
    char *content;  /* Extracted text content */
    size_t content_len;
    Confidence confidence;
    int match_count;  /* Number of times topic appears */
} Conversation;

typedef struct {
    Conversation *items;
    size_t count;
    size_t capacity;
} ConversationList;

static void conv_list_init(ConversationList *list) {
    list->items = NULL;
    list->count = 0;
    list->capacity = 0;
}

static void conv_list_add(ConversationList *list, Conversation conv) {
    if (list->count >= list->capacity) {
        list->capacity = list->capacity ? list->capacity * 2 : 16;
        list->items = realloc(list->items, list->capacity * sizeof(Conversation));
    }
    list->items[list->count++] = conv;
}

static int conv_cmp_time_desc(const void *a, const void *b) {
    const Conversation *ca = a;
    const Conversation *cb = b;
    if (cb->create_time > ca->create_time) return 1;
    if (cb->create_time < ca->create_time) return -1;
    return 0;
}

/* Extract text content from a conversation's mapping */
static char *extract_conversation_text(const char *conv_json) {
    /* Find all "parts" arrays and extract text */
    size_t buf_size = 65536;
    char *buf = malloc(buf_size);
    size_t buf_len = 0;
    buf[0] = '\0';
    
    const char *p = conv_json;
    while ((p = strstr(p, "\"parts\":")) != NULL) {
        p += 8;
        while (*p == ' ' || *p == '\t' || *p == '\n') p++;
        if (*p != '[') continue;
        p++;
        
        /* Look for text content */
        while (*p && *p != ']') {
            if (*p == '"') {
                p++;
                const char *start = p;
                while (*p && !(*p == '"' && *(p-1) != '\\')) p++;
                size_t len = p - start;
                if (len > 10 && buf_len + len + 3 < buf_size) {
                    /* Unescape and append */
                    for (size_t i = 0; i < len && buf_len < buf_size - 2; i++) {
                        if (start[i] == '\\' && i + 1 < len) {
                            char c = start[i+1];
                            if (c == 'n') buf[buf_len++] = '\n';
                            else if (c == 't') buf[buf_len++] = '\t';
                            else if (c == '"') buf[buf_len++] = '"';
                            else if (c == '\\') buf[buf_len++] = '\\';
                            else buf[buf_len++] = c;
                            i++;
                        } else {
                            buf[buf_len++] = start[i];
                        }
                    }
                    buf[buf_len++] = '\n';
                    buf[buf_len++] = '\n';
                }
                if (*p == '"') p++;
            } else if (*p == '{') {
                /* Nested object - look for "text" key */
                const char *text_start = strstr(p, "\"text\":");
                if (text_start && text_start < strstr(p, "}")) {
                    text_start += 7;
                    while (*text_start == ' ') text_start++;
                    if (*text_start == '"') {
                        text_start++;
                        const char *text_end = text_start;
                        while (*text_end && !(*text_end == '"' && *(text_end-1) != '\\')) text_end++;
                        size_t len = text_end - text_start;
                        if (len > 10 && buf_len + len + 3 < buf_size) {
                            for (size_t i = 0; i < len && buf_len < buf_size - 2; i++) {
                                if (text_start[i] == '\\' && i + 1 < len) {
                                    char c = text_start[i+1];
                                    if (c == 'n') buf[buf_len++] = '\n';
                                    else if (c == 't') buf[buf_len++] = '\t';
                                    else if (c == '"') buf[buf_len++] = '"';
                                    else if (c == '\\') buf[buf_len++] = '\\';
                                    else buf[buf_len++] = c;
                                    i++;
                                } else {
                                    buf[buf_len++] = text_start[i];
                                }
                            }
                            buf[buf_len++] = '\n';
                            buf[buf_len++] = '\n';
                        }
                    }
                }
                /* Skip to end of object */
                int depth = 1;
                p++;
                while (*p && depth > 0) {
                    if (*p == '{') depth++;
                    else if (*p == '}') depth--;
                    else if (*p == '"') {
                        p++;
                        while (*p && !(*p == '"' && *(p-1) != '\\')) p++;
                    }
                    p++;
                }
            } else {
                p++;
            }
        }
    }
    
    buf[buf_len] = '\0';
    return buf;
}

/* Count occurrences of needle in haystack (case-insensitive) */
static int count_occurrences(const char *haystack, const char *needle) {
    if (!haystack || !needle) return 0;
    int count = 0;
    size_t nlen = strlen(needle);
    const char *p = haystack;
    while (*p) {
        bool match = true;
        for (size_t j = 0; j < nlen && p[j]; j++) {
            if (tolower((unsigned char)p[j]) != tolower((unsigned char)needle[j])) {
                match = false;
                break;
            }
        }
        if (match) count++;
        p++;
    }
    return count;
}

/* Parse conversations.json and filter by topic */
static void parse_conversations(const char *json, const char *topic, ConversationList *list, bool include_all) {
    /* Find each conversation object */
    const char *p = json;
    if (*p == '[') p++;
    
    while (*p) {
        /* Skip whitespace */
        while (*p == ' ' || *p == '\t' || *p == '\n' || *p == ',') p++;
        if (*p != '{') break;
        
        /* Find end of this conversation object */
        const char *start = p;
        int depth = 1;
        p++;
        while (*p && depth > 0) {
            if (*p == '{') depth++;
            else if (*p == '}') depth--;
            else if (*p == '"') {
                p++;
                while (*p && !(*p == '"' && *(p-1) != '\\')) p++;
            }
            if (*p) p++;
        }
        
        /* Extract this conversation */
        size_t conv_len = p - start;
        char *conv_json = malloc(conv_len + 1);
        memcpy(conv_json, start, conv_len);
        conv_json[conv_len] = '\0';
        
        char *title = json_string_value(conv_json, "title");
        double create_time = json_number_value(conv_json, "create_time");
        double update_time = json_number_value(conv_json, "update_time");
        
        /* Check if this conversation matches the topic filter */
        Confidence conf = CONF_NONE;
        int match_count = 0;
        
        if (!topic || strlen(topic) == 0) {
            conf = CONF_HIGH;  /* No filter = include all */
        } else {
            /* Check title first (strongest signal) */
            if (title && contains_ci(title, topic)) {
                conf = CONF_HIGH;
                match_count += 10;  /* Title match worth more */
            }
            
            /* Check content */
            char *content = extract_conversation_text(conv_json);
            if (content) {
                int content_matches = count_occurrences(content, topic);
                match_count += content_matches;
                
                if (content_matches > 0 && conf < CONF_HIGH) {
                    if (content_matches >= 5) {
                        conf = CONF_MEDIUM;
                    } else {
                        conf = CONF_LOW;
                    }
                }
                free(content);
            }
        }
        
        if (conf > CONF_NONE || include_all) {
            Conversation conv;
            conv.title = title ? title : strdup("Untitled");
            conv.create_time = create_time;
            conv.update_time = update_time;
            conv.content = extract_conversation_text(conv_json);
            conv.content_len = conv.content ? strlen(conv.content) : 0;
            conv.confidence = conf;
            conv.match_count = match_count;
            conv_list_add(list, conv);
        } else {
            free(title);
        }
        
        free(conv_json);
    }
}

/* Load titles from a file (one per line) */
static char **load_titles_file(const char *path, size_t *count) {
    FILE *f = fopen(path, "r");
    if (!f) return NULL;
    
    char **titles = NULL;
    size_t capacity = 0;
    *count = 0;
    
    char line[512];
    while (fgets(line, sizeof(line), f)) {
        /* Trim newline */
        size_t len = strlen(line);
        while (len > 0 && (line[len-1] == '\n' || line[len-1] == '\r')) {
            line[--len] = '\0';
        }
        if (len == 0) continue;  /* Skip empty lines */
        if (line[0] == '#') continue;  /* Skip comments */
        
        if (*count >= capacity) {
            capacity = capacity ? capacity * 2 : 16;
            titles = realloc(titles, capacity * sizeof(char*));
        }
        titles[(*count)++] = strdup(line);
    }
    fclose(f);
    return titles;
}

/* Check if title matches any in the list */
static bool title_in_list(const char *title, char **list, size_t count) {
    for (size_t i = 0; i < count; i++) {
        if (strcasecmp(title, list[i]) == 0) return true;
        /* Also check partial match */
        if (contains_ci(title, list[i])) return true;
    }
    return false;
}

static void print_usage(const char *prog) {
    fprintf(stderr, "Usage: %s <conversations.json> [options]\n", prog);
    fprintf(stderr, "Options:\n");
    fprintf(stderr, "  --topic <name>     Filter by topic/project name (searches title and content)\n");
    fprintf(stderr, "  --titles <file>    Only extract conversations with titles in this file\n");
    fprintf(stderr, "  --output <dir>     Output directory (default: stdout)\n");
    fprintf(stderr, "  --format <fmt>     Output format: markdown, json (default: markdown)\n");
    fprintf(stderr, "  --list             List matching conversations without extracting\n");
    fprintf(stderr, "  --candidates       Output candidate list with confidence scores (for review)\n");
}

int main(int argc, char **argv) {
    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }
    
    const char *input_file = NULL;
    const char *topic = NULL;
    const char *titles_file = NULL;
    const char *output_dir = NULL;
    const char *format = "markdown";
    bool list_only = false;
    bool candidates_mode = false;
    
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--topic") == 0 && i + 1 < argc) {
            topic = argv[++i];
        } else if (strcmp(argv[i], "--titles") == 0 && i + 1 < argc) {
            titles_file = argv[++i];
        } else if (strcmp(argv[i], "--output") == 0 && i + 1 < argc) {
            output_dir = argv[++i];
        } else if (strcmp(argv[i], "--format") == 0 && i + 1 < argc) {
            format = argv[++i];
        } else if (strcmp(argv[i], "--list") == 0) {
            list_only = true;
        } else if (strcmp(argv[i], "--candidates") == 0) {
            candidates_mode = true;
        } else if (argv[i][0] != '-') {
            input_file = argv[i];
        }
    }
    
    if (!input_file) {
        fprintf(stderr, "Error: No input file specified\n");
        print_usage(argv[0]);
        return 1;
    }
    
    char *json = read_file(input_file);
    if (!json) {
        fprintf(stderr, "Error: Could not read %s\n", input_file);
        return 1;
    }
    
    /* Load titles filter if specified */
    char **filter_titles = NULL;
    size_t filter_count = 0;
    if (titles_file) {
        filter_titles = load_titles_file(titles_file, &filter_count);
        if (!filter_titles) {
            fprintf(stderr, "Error: Could not read titles file %s\n", titles_file);
            return 1;
        }
        fprintf(stderr, "Loaded %zu titles from %s\n", filter_count, titles_file);
    }
    
    ConversationList list;
    conv_list_init(&list);
    parse_conversations(json, topic, &list, false);
    free(json);
    
    /* Filter by titles if specified */
    if (filter_titles) {
        ConversationList filtered;
        conv_list_init(&filtered);
        for (size_t i = 0; i < list.count; i++) {
            if (title_in_list(list.items[i].title, filter_titles, filter_count)) {
                conv_list_add(&filtered, list.items[i]);
            }
        }
        /* Swap lists */
        free(list.items);
        list = filtered;
        fprintf(stderr, "Filtered to %zu conversations\n", list.count);
    }
    
    /* Sort by time descending (newest first) */
    qsort(list.items, list.count, sizeof(Conversation), conv_cmp_time_desc);
    
    /* Candidates mode: output for review with confidence scores */
    if (candidates_mode) {
        printf("# Candidate conversations for '%s'\n", topic ? topic : "*");
        printf("# Delete lines you don't want, then use --titles with this file\n");
        printf("# Format: CONFIDENCE | DATE | TITLE\n\n");
        
        /* Group by confidence */
        printf("## HIGH confidence (title match or strong content)\n\n");
        for (size_t i = 0; i < list.count; i++) {
            Conversation *c = &list.items[i];
            if (c->confidence == CONF_HIGH) {
                time_t t = (time_t)c->create_time;
                struct tm *tm = localtime(&t);
                char date[32];
                strftime(date, sizeof(date), "%Y-%m-%d", tm);
                printf("%s\n", c->title);
            }
        }
        
        printf("\n## MEDIUM confidence (multiple content mentions)\n\n");
        for (size_t i = 0; i < list.count; i++) {
            Conversation *c = &list.items[i];
            if (c->confidence == CONF_MEDIUM) {
                printf("%s\n", c->title);
            }
        }
        
        printf("\n## LOW confidence (weak match - review carefully)\n\n");
        for (size_t i = 0; i < list.count; i++) {
            Conversation *c = &list.items[i];
            if (c->confidence == CONF_LOW) {
                printf("# %s\n", c->title);  /* Commented out by default */
            }
        }
        
        return 0;
    }
    
    if (list_only) {
        printf("Found %zu conversations matching '%s':\n\n", list.count, topic ? topic : "*");
        for (size_t i = 0; i < list.count; i++) {
            Conversation *c = &list.items[i];
            time_t t = (time_t)c->create_time;
            struct tm *tm = localtime(&t);
            char date[32];
            strftime(date, sizeof(date), "%Y-%m-%d", tm);
            printf("%s [%s]: %s (%zu chars)\n", date, conf_names[c->confidence], c->title, c->content_len);
        }
        return 0;
    }
    
    /* Output */
    if (output_dir) {
        mkdir(output_dir, 0755);
    }
    
    for (size_t i = 0; i < list.count; i++) {
        Conversation *c = &list.items[i];
        time_t t = (time_t)c->create_time;
        struct tm *tm = localtime(&t);
        char date[32];
        strftime(date, sizeof(date), "%Y-%m-%d", tm);
        
        if (output_dir) {
            /* Write to file */
            char filename[512];
            /* Sanitize title for filename */
            char safe_title[128];
            size_t j = 0;
            for (size_t k = 0; c->title[k] && j < sizeof(safe_title) - 1; k++) {
                char ch = c->title[k];
                if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || 
                    (ch >= '0' && ch <= '9') || ch == '-' || ch == '_') {
                    safe_title[j++] = tolower((unsigned char)ch);
                } else if (ch == ' ') {
                    safe_title[j++] = '-';
                }
            }
            safe_title[j] = '\0';
            
            snprintf(filename, sizeof(filename), "%s/%s-%s.md", output_dir, date, safe_title);
            FILE *f = fopen(filename, "w");
            if (f) {
                fprintf(f, "# %s\n\n", c->title);
                fprintf(f, "**Date**: %s\n\n", date);
                fprintf(f, "---\n\n");
                fprintf(f, "%s", c->content ? c->content : "");
                fclose(f);
                printf("Wrote: %s\n", filename);
            }
        } else {
            /* Print to stdout */
            printf("# %s\n\n", c->title);
            printf("**Date**: %s\n\n", date);
            printf("---\n\n");
            printf("%s", c->content ? c->content : "");
            printf("\n\n---\n\n");
        }
    }
    
    if (!output_dir) {
        fprintf(stderr, "\nExtracted %zu conversations\n", list.count);
    }
    
    return 0;
}
