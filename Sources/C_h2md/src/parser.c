#include "parser.h"
#include "entity.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h>

/* ======================================================================
 * SIMD-accelerated scanning for '<' and '&' characters.
 * Uses NEON on ARM64, SSE2 on x86_64, scalar fallback otherwise.
 * ====================================================================== */

#if defined(__ARM_NEON) || defined(__ARM_NEON__)
#include <arm_neon.h>

/* Scan 16 bytes at a time for '<' or '&' using NEON */
static const char *scan_special_neon(const char *s, const char *end) {
    const uint8x16_t v_lt = vdupq_n_u8('<');
    const uint8x16_t v_amp = vdupq_n_u8('&');
    while (s + 16 <= end) {
        uint8x16_t v = vld1q_u8((const uint8_t *)s);
        uint8x16_t cmp_lt = vceqq_u8(v, v_lt);
        uint8x16_t cmp_amp = vceqq_u8(v, v_amp);
        uint8x16_t cmp = vorrq_u8(cmp_lt, cmp_amp);
        uint64x2_t cmp64 = vreinterpretq_u64_u8(cmp);
        uint64_t lo = vgetq_lane_u64(cmp64, 0);
        uint64_t hi = vgetq_lane_u64(cmp64, 1);
        if (lo | hi) {
            uint64_t mask = lo | hi;
            int lane = __builtin_ctzll(mask) / 8;
            return s + lane;
        }
        s += 16;
    }
    return s;
}

#elif defined(__SSE2__)
#include <emmintrin.h>

static const char *scan_special_sse2(const char *s, const char *end) {
    const __m128i v_lt = _mm_set1_epi8('<');
    const __m128i v_amp = _mm_set1_epi8('&');
    while (s + 16 <= end) {
        __m128i v = _mm_loadu_si128((const __m128i *)s);
        __m128i cmp_lt = _mm_cmpeq_epi8(v, v_lt);
        __m128i cmp_amp = _mm_cmpeq_epi8(v, v_amp);
        __m128i cmp = _mm_or_si128(cmp_lt, cmp_amp);
        int mask = _mm_movemask_epi8(cmp);
        if (mask) {
            int lane = __builtin_ctz(mask);
            return s + lane;
        }
        s += 16;
    }
    return s;
}

#endif

/* Find next '<' or '&' character, using SIMD when available */
static inline const char *scan_special(const char *s, const char *end) {
#if defined(__ARM_NEON) || defined(__ARM_NEON__)
    /* Scalar prefix for alignment */
    while (s + 16 <= end) {
        /* Check alignment */
        if (((uintptr_t)s & 15) == 0) break;
        if (*s == '<' || *s == '&') return s;
        s++;
    }
    if (s + 16 <= end) {
        s = scan_special_neon(s, end);
    }
    /* Scalar suffix */
    while (s < end) {
        if (*s == '<' || *s == '&') return s;
        s++;
    }
    return end;
#elif defined(__SSE2__)
    while (s + 16 <= end) {
        if (((uintptr_t)s & 15) == 0) break;
        if (*s == '<' || *s == '&') return s;
        s++;
    }
    if (s + 16 <= end) {
        s = scan_special_sse2(s, end);
    }
    while (s < end) {
        if (*s == '<' || *s == '&') return s;
        s++;
    }
    return end;
#else
    /* Scalar fallback */
    while (s < end) {
        if (*s == '<' || *s == '&') return s;
        s++;
    }
    return end;
#endif
}

/* ======================================================================
 * FNV-1a hash for O(1) tag name matching
 * ====================================================================== */

enum {
    TAG_UNKNOWN = 0,
    TAG_H1, TAG_H2, TAG_H3, TAG_H4, TAG_H5, TAG_H6,
    TAG_P, TAG_DIV, TAG_BR,
    TAG_B, TAG_STRONG, TAG_I, TAG_EM,
    TAG_DEL, TAG_S, TAG_A, TAG_IMG,
    TAG_CODE, TAG_PRE, TAG_HR,
    TAG_IFRAME, TAG_VIDEO, TAG_EMBED, TAG_OBJECT,
    TAG_UL, TAG_OL, TAG_LI,
    TAG_BLOCKQUOTE, TAG_TABLE, TAG_TR, TAG_TH, TAG_TD,
    TAG_CENTER, TAG_DETAILS, TAG_SUMMARY,
};

#define TAG_TABLE_SIZE 64
#define TAG_TABLE_MASK (TAG_TABLE_SIZE - 1)

typedef struct {
    const char *name;
    int         id;
    uint8_t     len;
} tag_entry;

static const tag_entry tag_table_data[] = {
    {"h1", TAG_H1, 2}, {"h2", TAG_H2, 2}, {"h3", TAG_H3, 2},
    {"h4", TAG_H4, 2}, {"h5", TAG_H5, 2}, {"h6", TAG_H6, 2},
    {"p", TAG_P, 1}, {"div", TAG_DIV, 3}, {"br", TAG_BR, 2},
    {"b", TAG_B, 1}, {"strong", TAG_STRONG, 6},
    {"i", TAG_I, 1}, {"em", TAG_EM, 2},
    {"del", TAG_DEL, 3}, {"s", TAG_S, 1}, {"a", TAG_A, 1},
    {"img", TAG_IMG, 3}, {"code", TAG_CODE, 4}, {"pre", TAG_PRE, 3},
    {"hr", TAG_HR, 2}, {"iframe", TAG_IFRAME, 6},
    {"video", TAG_VIDEO, 5}, {"embed", TAG_EMBED, 5}, {"object", TAG_OBJECT, 6},
    {"ul", TAG_UL, 2}, {"ol", TAG_OL, 2}, {"li", TAG_LI, 2},
    {"blockquote", TAG_BLOCKQUOTE, 10},
    {"table", TAG_TABLE, 5}, {"tr", TAG_TR, 2},
    {"th", TAG_TH, 2}, {"td", TAG_TD, 2},
    {"center", TAG_CENTER, 6}, {"details", TAG_DETAILS, 7}, {"summary", TAG_SUMMARY, 7},
};

#define NUM_TAG_ENTRIES (sizeof(tag_table_data) / sizeof(tag_table_data[0]))

static int tag_hash_table[TAG_TABLE_SIZE];
static int tag_hash_initialized = 0;

static inline uint32_t fnv1a(const char *s, int len) {
    uint32_t h = 2166136261u;
    for (int i = 0; i < len; i++) {
        h ^= (uint8_t)s[i];
        h *= 16777619u;
    }
    return h;
}

static void tag_hash_init(void) {
    for (int i = 0; i < TAG_TABLE_SIZE; i++)
        tag_hash_table[i] = -1;

    for (int i = 0; i < (int)NUM_TAG_ENTRIES; i++) {
        const tag_entry *e = &tag_table_data[i];
        uint32_t h = fnv1a(e->name, e->len);
        int slot = (int)(h & TAG_TABLE_MASK);
        while (tag_hash_table[slot] != -1)
            slot = (slot + 1) & TAG_TABLE_MASK;
        tag_hash_table[slot] = i;
    }
    tag_hash_initialized = 1;
}

static int tag_lookup(const char *name, int len) {
    if (!tag_hash_initialized) tag_hash_init();

    /* Lowercase hash for case-insensitive lookup */
    char lower[64];
    if (len > 63) return TAG_UNKNOWN;
    for (int i = 0; i < len; i++)
        lower[i] = (char)tolower((unsigned char)name[i]);

    uint32_t h = fnv1a(lower, len);
    int slot = (int)(h & TAG_TABLE_MASK);

    while (tag_hash_table[slot] != -1) {
        int idx = tag_hash_table[slot];
        const tag_entry *e = &tag_table_data[idx];
        if (e->len == len) {
            int match = 1;
            for (int i = 0; i < len; i++) {
                if (lower[i] != e->name[i]) { match = 0; break; }
            }
            if (match) return e->id;
        }
        slot = (slot + 1) & TAG_TABLE_MASK;
    }
    return TAG_UNKNOWN;
}

/* ======================================================================
 * Parser state machine
 * ====================================================================== */

enum {
    ST_TEXT,
    ST_TAG_OPEN,
    ST_TAG_NAME,
    ST_TAG_ATTRS,
    ST_CLOSE_OPEN,
    ST_CLOSE_NAME,
};

/* ======================================================================
 * Helper functions
 * ====================================================================== */

static void ensure_blocksep(h2md_parser *p) {
    if (p->need_blocksep) {
        if (h2md_buf_last_char(p->buf) != '\n')
            h2md_buf_append_char(p->buf, '\n');
        h2md_buf_append_char(p->buf, '\n');
        p->need_blocksep = 0;
    }
}

static void ensure_newline(h2md_parser *p) {
    char last = h2md_buf_last_char(p->buf);
    if (last != '\n' && last != '\0') {
        h2md_buf_append_char(p->buf, '\n');
    }
}

/* Output a blockquote prefix if we're at the start of a line inside a blockquote */
static void ensure_blockquote_prefix(h2md_parser *p) {
    if (p->in_blockquote > 0) {
        char last = h2md_buf_last_char(p->buf);
        if (last == '\n' || last == '\0') {
            h2md_buf_append_str(p->buf, "> ");
        }
    }
}

/* Zero-copy: flush raw text without entity decoding */
static void flush_raw(h2md_parser *p, const char *start, const char *end) {
    if (end > start) {
        if (p->in_blockquote > 0) {
            /* Need to add '> ' prefix after each newline in blockquote context */
            const char *s = start;
            while (s < end) {
                if (*s == '\n') {
                    h2md_buf_append_char(p->buf, '\n');
                    s++;
                    /* After newline inside blockquote, prefix next line */
                    if (s < end && p->in_blockquote > 0) {
                        h2md_buf_append_str(p->buf, "> ");
                    }
                } else {
                    const char *line_end = s;
                    while (line_end < end && *line_end != '\n')
                        line_end++;
                    if (p->in_blockquote > 0) {
                        char last = h2md_buf_last_char(p->buf);
                        if (last == '\n' || last == '\0') {
                            h2md_buf_append_str(p->buf, "> ");
                        }
                    }
                    h2md_buf_append(p->buf, s, (size_t)(line_end - s));
                    s = line_end;
                }
            }
        } else {
            h2md_buf_append(p->buf, start, (size_t)(end - start));
        }
    }
}

/* Append text with entity decoding (for non-pre/code contexts) */
static void append_text_decoded(h2md_parser *p, const char *s, int len) {
    int i = 0;
    while (i < len) {
        if (s[i] == '&') {
            int consumed = h2md_entity_decode(p->buf, s + i, (size_t)(len - i));
            if (consumed > 0) {
                i += consumed;
                continue;
            }
        }
        /* Handle newlines in blockquote context */
        if (p->in_blockquote > 0 && s[i] == '\n') {
            h2md_buf_append_char(p->buf, '\n');
            i++;
            /* After newline inside blockquote, prefix next line */
            if (i < len) {
                h2md_buf_append_str(p->buf, "> ");
            }
            continue;
        }
        /* Copy consecutive non-entity characters in bulk */
        int start = i;
        while (i < len && s[i] != '&' && !(p->in_blockquote > 0 && s[i] == '\n'))
            i++;
        if (i > start) {
            ensure_blockquote_prefix(p);
            h2md_buf_append(p->buf, s + start, (size_t)(i - start));
        }
    }
}

/* Single-pass attribute extraction for all common attributes */
static void sanitize_url(char *url, int *len);
static void extract_all_attrs(h2md_parser *p) {
    const char *attrs = p->attr_buf;
    int alen = p->attr_len;
    
    /* Reset all output lengths */
    p->href_len = 0; p->src_len = 0; p->alt_len = 0; p->lang_len = 0;
    p->href[0] = '\0'; p->src[0] = '\0'; p->alt[0] = '\0'; p->lang[0] = '\0';
    
    for (int i = 0; i < alen; i++) {
        /* Skip whitespace */
        while (i < alen && isspace((unsigned char)attrs[i])) i++;
        if (i >= alen) break;
        
        /* Check for known attribute names */
        char *out = NULL;
        int *out_len = NULL;
        int max_out = 0;

        int prev_is_word = (i > 0 && isalnum((unsigned char)attrs[i-1]));

        if (!prev_is_word && attrs[i] == 'h' && i + 3 < alen &&
            tolower((unsigned char)attrs[i+1]) == 'r' &&
            tolower((unsigned char)attrs[i+2]) == 'e' &&
            tolower((unsigned char)attrs[i+3]) == 'f') {
            out = p->href; out_len = &p->href_len; max_out = (int)sizeof(p->href);
            i += 4;
        } else if (!prev_is_word && attrs[i] == 's' && i + 2 < alen &&
                   tolower((unsigned char)attrs[i+1]) == 'r' &&
                   tolower((unsigned char)attrs[i+2]) == 'c') {
            out = p->src; out_len = &p->src_len; max_out = (int)sizeof(p->src);
            i += 3;
        } else if (!prev_is_word && attrs[i] == 'a' && i + 2 < alen &&
                   tolower((unsigned char)attrs[i+1]) == 'l' &&
                   tolower((unsigned char)attrs[i+2]) == 't') {
            out = p->alt; out_len = &p->alt_len; max_out = (int)sizeof(p->alt);
            i += 3;
        } else if (!prev_is_word && attrs[i] == 'c' && i + 4 < alen &&
                   tolower((unsigned char)attrs[i+1]) == 'l' &&
                   tolower((unsigned char)attrs[i+2]) == 'a' &&
                   tolower((unsigned char)attrs[i+3]) == 's' &&
                   tolower((unsigned char)attrs[i+4]) == 's') {
            out = p->lang; out_len = &p->lang_len; max_out = (int)sizeof(p->lang);
            i += 5;
        } else {
            /* Skip unknown attribute */
            while (i < alen && attrs[i] != '=') i++;
            if (i < alen) {
                i++; /* skip = */
                if (i < alen) {
                    char q = attrs[i];
                    if (q == '"' || q == '\'') {
                        i++;
                        while (i < alen && attrs[i] != q) i++;
                        if (i < alen) i++;
                    } else {
                        while (i < alen && !isspace((unsigned char)attrs[i])) i++;
                    }
                }
            }
            continue;
        }
        
        /* Parse value */
        while (i < alen && attrs[i] == ' ') i++;
        if (i < alen && attrs[i] == '=') {
            i++;
            while (i < alen && attrs[i] == ' ') i++;
            if (i < alen) {
                char q = attrs[i];
                if (q == '"' || q == '\'') {
                    i++;
                    while (i < alen && attrs[i] != q && *out_len < max_out - 1)
                        out[(*out_len)++] = attrs[i++];
                    if (i < alen) i++;
                } else {
                    while (i < alen && !isspace((unsigned char)attrs[i]) && *out_len < max_out - 1)
                        out[(*out_len)++] = attrs[i++];
                }
                out[*out_len] = '\0';
                if (out == p->href || out == p->src) {
                    sanitize_url(out, out_len);
                }
            }
        }
    }
}

static void sanitize_url(char *url, int *len) {
    int w = 0;
    for (int r = 0; r < *len; r++) {
        if (r + 7 < *len &&
            url[r] == 'h' && url[r+1] == 't' && url[r+2] == 't' && url[r+3] == 'p' &&
            url[r+4] == 's' && url[r+5] == ':' && url[r+6] == ' ' && url[r+7] == '/') {
            url[w++] = 'h'; url[w++] = 't'; url[w++] = 't'; url[w++] = 'p';
            url[w++] = 's'; url[w++] = ':'; url[w++] = '/';
            r += 7;
        } else if (r + 6 < *len &&
                   url[r] == 'h' && url[r+1] == 't' && url[r+2] == 't' && url[r+3] == 'p' &&
                   url[r+4] == ':' && url[r+5] == ' ' && url[r+6] == '/') {
            url[w++] = 'h'; url[w++] = 't'; url[w++] = 't'; url[w++] = 'p';
            url[w++] = ':'; url[w++] = '/';
            r += 6;
        } else {
            url[w++] = url[r];
        }
    }
    url[w] = '\0';
    *len = w;
}

static int has_gif_ext(const char *s, int len) {
    if (len < 4) return 0;
    char c3 = (char)tolower((unsigned char)s[len-3]);
    char c2 = (char)tolower((unsigned char)s[len-2]);
    char c1 = (char)tolower((unsigned char)s[len-1]);
    if (s[len-4] == '.' && c3 == 'g' && c2 == 'i' && c1 == 'f') return 1;
    if (len >= 15 && memcmp(s, "data:image/gif", 14) == 0) return 1;
    return 0;
}

static int has_svg_ext(const char *s, int len) {
    if (len < 4) return 0;
    char c3 = (char)tolower((unsigned char)s[len-3]);
    char c2 = (char)tolower((unsigned char)s[len-2]);
    char c1 = (char)tolower((unsigned char)s[len-1]);
    if (s[len-4] == '.' && c3 == 's' && c2 == 'v' && c1 == 'g') return 1;
    if (len >= 18 && memcmp(s, "data:image/svg+xml", 18) == 0) return 1;
    return 0;
}

static int has_video_ext(const char *s, int len) {
    if (len < 4) return 0;
    if (len >= 8 && s[len-4] == '.') {
        char c3 = (char)tolower((unsigned char)s[len-3]);
        char c2 = (char)tolower((unsigned char)s[len-2]);
        char c1 = (char)tolower((unsigned char)s[len-1]);
        if ((c3=='m' && c2=='p' && c1=='4') ||
            (c3=='o' && c2=='g' && c1=='g') ||
            (c3=='m' && c2=='o' && c1=='v'))
            return 1;
    }
    if (len >= 8 && tolower((unsigned char)s[len-5])=='w' &&
        tolower((unsigned char)s[len-4])=='e' &&
        tolower((unsigned char)s[len-3])=='b' &&
        tolower((unsigned char)s[len-2])=='m')
        return 1;
    if (len >= 11 && memcmp(s, "data:video/", 11) == 0) return 1;
    return 0;
}

/* ======================================================================
 * Tag processing — hash-based dispatch
 * ====================================================================== */

static void process_open_tag(h2md_parser *p) {
    const char *name = p->tag_name;
    int len = p->tag_name_len;

    /* Extract all common attributes in a single pass */
    extract_all_attrs(p);

    int tag = tag_lookup(name, len);

    switch (tag) {
    case TAG_H1: case TAG_H2: case TAG_H3:
    case TAG_H4: case TAG_H5: case TAG_H6: {
        int level = tag - TAG_H1 + 1;
        ensure_blocksep(p);
        h2md_buf_append_repeated(p->buf, '#', level);
        h2md_buf_append_char(p->buf, ' ');
        p->need_blocksep = 1;
        return;
    }
    case TAG_P: case TAG_DIV: case TAG_CENTER: case TAG_DETAILS: case TAG_SUMMARY:
        ensure_blocksep(p);
        p->need_blocksep = 1;
        return;
    case TAG_BR:
        ensure_newline(p);
        return;
    case TAG_B: case TAG_STRONG:
        h2md_buf_append_str(p->buf, "**");
        return;
    case TAG_I: case TAG_EM:
        h2md_buf_append_char(p->buf, '*');
        return;
    case TAG_DEL: case TAG_S:
        h2md_buf_append_str(p->buf, "~~");
        return;
    case TAG_A:
        memcpy(p->saved_href, p->href, (size_t)p->href_len + 1);
        p->saved_href_len = p->href_len;
        p->in_link = 1;
        h2md_buf_append_char(p->buf, '[');
        return;
    case TAG_IMG:
        if (p->src_len > 0 && !has_gif_ext(p->src, p->src_len)) {
            const char *label = p->alt_len > 0 ? p->alt : "image";
            int is_svg = has_svg_ext(p->src, p->src_len);
            if (!is_svg) h2md_buf_append_char(p->buf, '!');
            h2md_buf_append_char(p->buf, '[');
            h2md_buf_append(p->buf, label, (size_t)p->alt_len ? (size_t)p->alt_len : 5);
            h2md_buf_append_str(p->buf, "](");
            h2md_buf_append(p->buf, p->src, (size_t)p->src_len);
            h2md_buf_append_char(p->buf, ')');
        }
        return;
    case TAG_CODE:
        p->in_code++;
        if (!p->in_pre) h2md_buf_append_char(p->buf, '`');
        return;
    case TAG_PRE:
        p->in_pre++;
        ensure_blocksep(p);
        h2md_buf_append_str(p->buf, "```\n");
        return;
    case TAG_HR:
        ensure_blocksep(p);
        h2md_buf_append_str(p->buf, "---\n");
        p->need_blocksep = 1;
        return;
    case TAG_IFRAME:
        if (p->src_len > 0 && !has_video_ext(p->src, p->src_len)) {
            ensure_blocksep(p);
            h2md_buf_append_char(p->buf, '[');
            if (p->alt_len > 0)
                h2md_buf_append(p->buf, p->alt, (size_t)p->alt_len);
            else if (p->lang_len > 0)
                h2md_buf_append(p->buf, p->lang, (size_t)p->lang_len);
            else
                h2md_buf_append_str(p->buf, "embedded content");
            h2md_buf_append_str(p->buf, "](");
            h2md_buf_append(p->buf, p->src, (size_t)p->src_len);
            h2md_buf_append_str(p->buf, ")\n");
            p->need_blocksep = 1;
        }
        return;
    case TAG_VIDEO: case TAG_EMBED: case TAG_OBJECT:
        return;
    case TAG_UL:
        if (p->list_stack_top < MAX_LIST_DEPTH) {
            p->list_stack[p->list_stack_top].in_ol = p->in_ol;
            p->list_stack[p->list_stack_top].counter = p->list_counter;
            p->list_stack_top++;
        }
        p->list_depth++;
        p->in_ol = 0;
        ensure_blocksep(p);
        return;
    case TAG_OL:
        if (p->list_stack_top < MAX_LIST_DEPTH) {
            p->list_stack[p->list_stack_top].in_ol = p->in_ol;
            p->list_stack[p->list_stack_top].counter = p->list_counter;
            p->list_stack_top++;
        }
        p->list_depth++;
        p->in_ol = 1;
        p->list_counter = 0;
        ensure_blocksep(p);
        return;
    case TAG_LI:
        ensure_newline(p);
        if (p->list_depth > 0 && p->in_ol) {
            p->list_counter++;
            char numbuf[16];
            int n = snprintf(numbuf, sizeof(numbuf), "%d. ", p->list_counter);
            h2md_buf_append(p->buf, numbuf, (size_t)n);
        } else {
            h2md_buf_append_str(p->buf, "- ");
        }
        return;
    case TAG_BLOCKQUOTE:
        ensure_blocksep(p);
        p->in_blockquote++;
        p->need_blocksep = 1;
        return;
    case TAG_TABLE:
        ensure_blocksep(p);
        p->in_table = 1;
        p->table_row_count = 0;
        p->table_col_count = 0;
        p->need_blocksep = 1;
        return;
    case TAG_TR:
        ensure_newline(p);
        p->table_row_count++;
        p->in_first_row = (p->table_row_count == 1);
        return;
    case TAG_TH: case TAG_TD:
        h2md_buf_append_str(p->buf, "| ");
        if (p->table_row_count == 1) p->table_col_count++;
        return;
    default:
        return;
    }
}

static void process_close_tag(h2md_parser *p) {
    const char *name = p->tag_name;
    int len = p->tag_name_len;
    int tag = tag_lookup(name, len);

    switch (tag) {
    case TAG_H1: case TAG_H2: case TAG_H3:
    case TAG_H4: case TAG_H5: case TAG_H6:
        ensure_newline(p);
        p->need_blocksep = 1;
        return;
    case TAG_P: case TAG_DIV: case TAG_CENTER: case TAG_DETAILS: case TAG_SUMMARY:
        ensure_newline(p);
        p->need_blocksep = 1;
        return;
    case TAG_B: case TAG_STRONG:
        h2md_buf_append_str(p->buf, "**");
        return;
    case TAG_I: case TAG_EM:
        h2md_buf_append_char(p->buf, '*');
        return;
    case TAG_DEL: case TAG_S:
        h2md_buf_append_str(p->buf, "~~");
        return;
    case TAG_A:
        h2md_buf_append_str(p->buf, "](");
        if (p->saved_href_len > 0)
            h2md_buf_append(p->buf, p->saved_href, (size_t)p->saved_href_len);
        h2md_buf_append_char(p->buf, ')');
        p->in_link = 0;
        return;
    case TAG_CODE:
        if (p->in_code > 0) p->in_code--;
        if (!p->in_pre) h2md_buf_append_char(p->buf, '`');
        return;
    case TAG_PRE:
        if (p->in_pre > 0) p->in_pre--;
        ensure_newline(p);
        h2md_buf_append_str(p->buf, "```\n");
        p->need_blocksep = 1;
        return;
    case TAG_UL: case TAG_OL:
        if (p->list_depth > 0) p->list_depth--;
        if (p->list_stack_top > 0) {
            p->list_stack_top--;
            p->in_ol = p->list_stack[p->list_stack_top].in_ol;
            p->list_counter = p->list_stack[p->list_stack_top].counter;
        } else {
            p->in_ol = 0;
            p->list_counter = 0;
        }
        ensure_newline(p);
        p->need_blocksep = 1;
        return;
    case TAG_BLOCKQUOTE:
        if (p->in_blockquote > 0) p->in_blockquote--;
        ensure_newline(p);
        p->need_blocksep = 1;
        return;
    case TAG_TABLE:
        p->in_table = 0;
        ensure_newline(p);
        p->need_blocksep = 1;
        return;
    case TAG_TR:
        if (p->in_first_row && p->table_col_count > 0) {
            /* Header row ended — insert separator row */
            ensure_newline(p);
            h2md_buf_append_char(p->buf, '|');
            for (int i = 0; i < p->table_col_count; i++) {
                h2md_buf_append_str(p->buf, " --- |");
            }
            h2md_buf_append_char(p->buf, '\n');
        }
        p->in_first_row = 0;
        return;
    case TAG_TH: case TAG_TD:
        h2md_buf_append_char(p->buf, '|');
        return;
    default:
        return;
    }
}

static int read_tag_name(const char *s, int max_len, char *out, int *out_len) {
    int i = 0;
    while (i < max_len && (isalnum((unsigned char)s[i]) || s[i] == '-'))
        i++;
    if (i == 0 || i > 63) return 0;
    memcpy(out, s, (size_t)i);
    out[i] = '\0';
    *out_len = i;
    return i;
}

/* ======================================================================
 * Main parser entry point
 * ====================================================================== */

void h2md_parser_init(h2md_parser *p, h2md_buf *buf) {
    memset(p, 0, sizeof(*p));
    p->buf = buf;
    if (!tag_hash_initialized) tag_hash_init();
}

void h2md_parser_run(h2md_parser *p, const char *input) {
    if (!input || !*input) return;

    const char *s = input;
    const char *end = input + strlen(input);
    int state = ST_TEXT;
    const char *text_start = s;
    p->tag_name_len = 0;
    p->attr_len = 0;
    p->in_tag = 0;

    while (s < end) {
        char c = *s;

        switch (state) {
        case ST_TEXT:
            /* Current char is '<' or '&' — handle it directly */
            if (c == '<') {
                /* Flush text before this '<' */
                if (s > text_start) {
                    if (p->in_pre || p->in_code)
                        flush_raw(p, text_start, s);
                    else
                        append_text_decoded(p, text_start, (int)(s - text_start));
                }
                text_start = NULL;
                state = ST_TAG_OPEN;
                s++;
                break;
            }
            if (c == '&') {
                /* Flush text before this '&' */
                if (s > text_start) {
                    if (p->in_pre || p->in_code)
                        flush_raw(p, text_start, s);
                    else
                        append_text_decoded(p, text_start, (int)(s - text_start));
                }
                text_start = NULL;
                if (!p->in_pre && !p->in_code) {
                    int consumed = h2md_entity_decode(p->buf, s, (size_t)(end - s));
                    if (consumed > 0) {
                        s += consumed;
                        text_start = s;
                        break;
                    }
                }
                /* Not a valid entity, output '&' literally */
                h2md_buf_append_char(p->buf, '&');
                s++;
                text_start = s;
                break;
            }
            {
                /* Scan forward to next '<' or '&' using SIMD */
                const char *next = scan_special(s + 1, end);
                if (next < end) {
                    s = next;
                } else {
                    s = end;
                }
            }
            break;

        case ST_TAG_OPEN:
            if (c == '/') {
                state = ST_CLOSE_OPEN;
                s++;
                continue;
            }
            if (c == '!') {
                /* Comment or doctype: skip until > */
                s++;
                while (s < end && *s != '>') s++;
                if (s < end) s++;
                text_start = s;
                state = ST_TEXT;
                continue;
            }
            if (isalpha((unsigned char)c)) {
                if (read_tag_name(s, 63, p->tag_name, &p->tag_name_len)) {
                    s += p->tag_name_len;
                    p->attr_len = 0;
                    p->in_tag = 1;
                    state = ST_TAG_NAME;
                    continue;
                }
            }
            /* Not a valid tag, output '<' as text */
            h2md_buf_append_char(p->buf, '<');
            text_start = s;
            state = ST_TEXT;
            break;

        case ST_TAG_NAME:
            if (c == '>') {
                p->attr_buf[p->attr_len] = '\0';
                p->in_tag = 0;
                process_open_tag(p);
                state = ST_TEXT;
                s++;
                text_start = s;
                continue;
            }
            if (c == '/' && s + 1 < end && s[1] == '>') {
                p->attr_buf[p->attr_len] = '\0';
                p->in_tag = 0;
                process_open_tag(p);
                state = ST_TEXT;
                s += 2;
                text_start = s;
                continue;
            }
            if (isspace((unsigned char)c)) {
                state = ST_TAG_ATTRS;
            } else {
                s++;
                continue;
            }
            /* fall through */
        case ST_TAG_ATTRS:
            if (c == '>') {
                p->attr_buf[p->attr_len] = '\0';
                p->in_tag = 0;
                process_open_tag(p);
                state = ST_TEXT;
                s++;
                text_start = s;
                continue;
            }
            if (c == '/' && s + 1 < end && s[1] == '>') {
                p->attr_buf[p->attr_len] = '\0';
                p->in_tag = 0;
                process_open_tag(p);
                state = ST_TEXT;
                s += 2;
                text_start = s;
                continue;
            }
            if (p->attr_len < (int)sizeof(p->attr_buf) - 1) {
                p->attr_buf[p->attr_len++] = c;
            }
            s++;
            break;

        case ST_CLOSE_OPEN:
            if (isalpha((unsigned char)c)) {
                if (read_tag_name(s, 63, p->tag_name, &p->tag_name_len)) {
                    s += p->tag_name_len;
                    state = ST_CLOSE_NAME;
                    continue;
                }
            }
            h2md_buf_append_str(p->buf, "</");
            text_start = s;
            state = ST_TEXT;
            break;

        case ST_CLOSE_NAME:
            if (c == '>') {
                process_close_tag(p);
                state = ST_TEXT;
                s++;
                text_start = s;
                continue;
            }
            s++;
            break;

        default:
            s++;
            break;
        }
    }

    /* Flush remaining text */
    if (text_start && text_start < end) {
        size_t remaining = (size_t)(end - text_start);
        if (p->in_pre || p->in_code) {
            h2md_buf_append(p->buf, text_start, remaining);
        } else {
            append_text_decoded(p, text_start, (int)remaining);
        }
    }
}
