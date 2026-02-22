/*
 * Sofia Compile - Compile notes with temporal layering
 * Groups notes by category, surfaces newest, nests older iterations
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <time.h>
#include <ctype.h>
#include <dirent.h>
#include <sys/stat.h>

/* Categories for book notes */
typedef enum {
    CAT_CHARACTER,
    CAT_PLOT,
    CAT_WORLDBUILDING,
    CAT_CHAPTER,
    CAT_THEME,
    CAT_TECHNOLOGY,
    CAT_RESEARCH,
    CAT_MISC,
    CAT_COUNT
} Category;

static const char *category_names[] = {
    "characters",
    "plot",
    "worldbuilding", 
    "chapters",
    "themes",
    "technology",
    "research",
    "misc"
};

static const char *category_keywords[][10] = {
    /* CHARACTER */ {"character", "mara", "backstory", "arc", "motivation", "dialogue", "personality", NULL},
    /* PLOT */ {"plot", "heist", "conflict", "scene", "sequence", "twist", "climax", "resolution", NULL},
    /* WORLDBUILDING */ {"world", "society", "exodite", "dynasty", "culture", "history", "setting", "location", NULL},
    /* CHAPTER */ {"chapter", "draft", "revision", "edit", "canon", "manuscript", NULL},
    /* THEME */ {"theme", "meaning", "symbol", "metaphor", "message", NULL},
    /* TECHNOLOGY */ {"tech", "quantum", "encryption", "biotech", "cyber", "hack", "system", NULL},
    /* RESEARCH */ {"research", "reference", "source", "fact", "science", NULL},
    /* MISC */ {NULL}
};

typedef struct {
    char *path;
    char *title;
    char *content;
    time_t date;
    Category category;
    char *subject;      /* Specific subject within category (e.g., character name) */
    bool is_canon;      /* True if this is actual chapter content */
} Note;

typedef struct {
    Note *items;
    size_t count;
    size_t capacity;
} NoteList;

static char *read_file(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    char *buf = malloc(len + 1);
    if (!buf) { fclose(f); return NULL; }
    size_t read_bytes = fread(buf, 1, len, f);
    buf[read_bytes] = '\0';
    fclose(f);
    return buf;
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

static Category detect_category(const char *title, const char *content) {
    /* Check title first (stronger signal) */
    for (int cat = 0; cat < CAT_MISC; cat++) {
        for (int k = 0; category_keywords[cat][k]; k++) {
            if (contains_ci(title, category_keywords[cat][k])) {
                return (Category)cat;
            }
        }
    }
    
    /* Check content */
    for (int cat = 0; cat < CAT_MISC; cat++) {
        int matches = 0;
        for (int k = 0; category_keywords[cat][k]; k++) {
            if (contains_ci(content, category_keywords[cat][k])) {
                matches++;
            }
        }
        if (matches >= 2) return (Category)cat;
    }
    
    return CAT_MISC;
}

static bool detect_canon(const char *title, const char *content) {
    /* Canon indicators: actual chapter content, not discussion */
    if (contains_ci(title, "chapter") && 
        (contains_ci(title, "draft") || contains_ci(title, "revision"))) {
        return false; /* Discussion about chapter */
    }
    if (contains_ci(title, "chapter") && !contains_ci(title, "feedback") &&
        !contains_ci(title, "edit") && !contains_ci(title, "review")) {
        /* Check if content looks like prose vs discussion */
        /* Simple heuristic: prose has fewer questions, more narrative */
        int questions = 0;
        for (const char *p = content; *p; p++) {
            if (*p == '?') questions++;
        }
        size_t len = strlen(content);
        if (len > 1000 && questions < (int)(len / 500)) {
            return true; /* Likely prose */
        }
    }
    return false;
}

static time_t parse_date_from_filename(const char *filename) {
    /* Expected format: YYYY-MM-DD-title.md */
    int year, month, day;
    if (sscanf(filename, "%d-%d-%d", &year, &month, &day) == 3) {
        struct tm tm = {0};
        tm.tm_year = year - 1900;
        tm.tm_mon = month - 1;
        tm.tm_mday = day;
        return mktime(&tm);
    }
    return 0;
}

static void note_list_add(NoteList *list, Note note) {
    if (list->count >= list->capacity) {
        list->capacity = list->capacity ? list->capacity * 2 : 16;
        list->items = realloc(list->items, list->capacity * sizeof(Note));
    }
    list->items[list->count++] = note;
}

static int note_cmp_date_desc(const void *a, const void *b) {
    const Note *na = a;
    const Note *nb = b;
    if (nb->date > na->date) return 1;
    if (nb->date < na->date) return -1;
    return 0;
}

static void load_notes_from_dir(const char *dir_path, NoteList *list) {
    DIR *dir = opendir(dir_path);
    if (!dir) return;
    
    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (entry->d_name[0] == '.') continue;
        
        size_t namelen = strlen(entry->d_name);
        if (namelen < 4 || strcmp(entry->d_name + namelen - 3, ".md") != 0) continue;
        
        char path[1024];
        snprintf(path, sizeof(path), "%s/%s", dir_path, entry->d_name);
        
        char *content = read_file(path);
        if (!content) continue;
        
        /* Extract title from first line */
        char *title = NULL;
        char *line_end = strchr(content, '\n');
        if (line_end && content[0] == '#') {
            size_t title_len = line_end - content - 2; /* Skip "# " */
            title = malloc(title_len + 1);
            memcpy(title, content + 2, title_len);
            title[title_len] = '\0';
        } else {
            title = strdup(entry->d_name);
        }
        
        Note note;
        note.path = strdup(path);
        note.title = title;
        note.content = content;
        note.date = parse_date_from_filename(entry->d_name);
        note.category = detect_category(title, content);
        note.is_canon = detect_canon(title, content);
        note.subject = NULL; /* TODO: extract specific subject */
        
        note_list_add(list, note);
    }
    
    closedir(dir);
}

static void write_compiled_output(NoteList *list, const char *output_dir, const char *project_name) {
    mkdir(output_dir, 0755);
    
    /* Sort by date descending */
    qsort(list->items, list->count, sizeof(Note), note_cmp_date_desc);
    
    /* Group by category */
    NoteList by_category[CAT_COUNT] = {0};
    for (size_t i = 0; i < list->count; i++) {
        note_list_add(&by_category[list->items[i].category], list->items[i]);
    }
    
    /* Write index file */
    char index_path[1024];
    snprintf(index_path, sizeof(index_path), "%s/index.md", output_dir);
    FILE *index = fopen(index_path, "w");
    if (index) {
        fprintf(index, "# %s - Compiled Notes\n\n", project_name);
        fprintf(index, "**Generated**: %s\n\n", __DATE__);
        fprintf(index, "## Summary\n\n");
        fprintf(index, "| Category | Notes | Latest |\n");
        fprintf(index, "|----------|-------|--------|\n");
        
        for (int cat = 0; cat < CAT_COUNT; cat++) {
            if (by_category[cat].count > 0) {
                char date_str[32] = "N/A";
                if (by_category[cat].items[0].date > 0) {
                    struct tm *tm = localtime(&by_category[cat].items[0].date);
                    strftime(date_str, sizeof(date_str), "%Y-%m-%d", tm);
                }
                fprintf(index, "| [%s](%s.md) | %zu | %s |\n", 
                    category_names[cat], category_names[cat],
                    by_category[cat].count, date_str);
            }
        }
        
        fprintf(index, "\n## Canon Status\n\n");
        int canon_count = 0;
        for (size_t i = 0; i < list->count; i++) {
            if (list->items[i].is_canon) canon_count++;
        }
        fprintf(index, "- **Canon chapters**: %d\n", canon_count);
        fprintf(index, "- **Discussion notes**: %zu\n", list->count - canon_count);
        
        fclose(index);
        printf("Wrote: %s\n", index_path);
    }
    
    /* Write category files with temporal layering */
    for (int cat = 0; cat < CAT_COUNT; cat++) {
        if (by_category[cat].count == 0) continue;
        
        char cat_path[1024];
        snprintf(cat_path, sizeof(cat_path), "%s/%s.md", output_dir, category_names[cat]);
        FILE *f = fopen(cat_path, "w");
        if (!f) continue;
        
        fprintf(f, "# %s - %s\n\n", project_name, category_names[cat]);
        fprintf(f, "Notes are ordered newest-first. Older iterations of the same topic are nested below.\n\n");
        fprintf(f, "---\n\n");
        
        for (size_t i = 0; i < by_category[cat].count; i++) {
            Note *note = &by_category[cat].items[i];
            
            char date_str[32] = "Unknown date";
            if (note->date > 0) {
                struct tm *tm = localtime(&note->date);
                strftime(date_str, sizeof(date_str), "%Y-%m-%d", tm);
            }
            
            fprintf(f, "## %s\n\n", note->title);
            fprintf(f, "**Date**: %s", date_str);
            if (note->is_canon) {
                fprintf(f, " | **Status**: CANON");
            }
            fprintf(f, "\n\n");
            
            /* Include content preview (first 2000 chars) */
            const char *content_start = note->content;
            /* Skip the title line */
            char *newline = strchr(content_start, '\n');
            if (newline) content_start = newline + 1;
            
            size_t preview_len = strlen(content_start);
            if (preview_len > 2000) {
                fprintf(f, "%.2000s\n\n*[Content truncated - see full note: %s]*\n\n", 
                    content_start, note->path);
            } else {
                fprintf(f, "%s\n\n", content_start);
            }
            
            fprintf(f, "---\n\n");
        }
        
        fclose(f);
        printf("Wrote: %s (%zu notes)\n", cat_path, by_category[cat].count);
    }
}

static void print_usage(const char *prog) {
    fprintf(stderr, "Usage: %s <input_dir> [options]\n", prog);
    fprintf(stderr, "Options:\n");
    fprintf(stderr, "  --output <dir>     Output directory (default: <input_dir>/compiled)\n");
    fprintf(stderr, "  --project <name>   Project name for headers (default: 'Project')\n");
    fprintf(stderr, "  --list             List notes by category without compiling\n");
}

int main(int argc, char **argv) {
    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }
    
    const char *input_dir = NULL;
    const char *output_dir = NULL;
    const char *project_name = "Project";
    bool list_only = false;
    
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--output") == 0 && i + 1 < argc) {
            output_dir = argv[++i];
        } else if (strcmp(argv[i], "--project") == 0 && i + 1 < argc) {
            project_name = argv[++i];
        } else if (strcmp(argv[i], "--list") == 0) {
            list_only = true;
        } else if (argv[i][0] != '-') {
            input_dir = argv[i];
        }
    }
    
    if (!input_dir) {
        fprintf(stderr, "Error: No input directory specified\n");
        return 1;
    }
    
    NoteList list = {0};
    load_notes_from_dir(input_dir, &list);
    
    if (list.count == 0) {
        fprintf(stderr, "No notes found in %s\n", input_dir);
        return 1;
    }
    
    printf("Loaded %zu notes\n", list.count);
    
    /* Sort by date descending */
    qsort(list.items, list.count, sizeof(Note), note_cmp_date_desc);
    
    if (list_only) {
        printf("\nNotes by category:\n\n");
        for (int cat = 0; cat < CAT_COUNT; cat++) {
            printf("## %s\n", category_names[cat]);
            for (size_t i = 0; i < list.count; i++) {
                if (list.items[i].category == cat) {
                    char date_str[32] = "????-??-??";
                    if (list.items[i].date > 0) {
                        struct tm *tm = localtime(&list.items[i].date);
                        strftime(date_str, sizeof(date_str), "%Y-%m-%d", tm);
                    }
                    printf("  %s: %s%s\n", date_str, list.items[i].title,
                        list.items[i].is_canon ? " [CANON]" : "");
                }
            }
            printf("\n");
        }
        return 0;
    }
    
    /* Compile output */
    char default_output[1024];
    if (!output_dir) {
        snprintf(default_output, sizeof(default_output), "%s/compiled", input_dir);
        output_dir = default_output;
    }
    
    write_compiled_output(&list, output_dir, project_name);
    
    return 0;
}
