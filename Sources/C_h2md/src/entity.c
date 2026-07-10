#include "entity.h"
#include <string.h>
#include <stdlib.h>

/* Entity hash table for O(1) lookup.
 * Uses open addressing with linear probing.
 * Table size is power of 2 for fast modulo via bitmask. */

#define ENTITY_TABLE_BITS 7
#define ENTITY_TABLE_SIZE (1 << ENTITY_TABLE_BITS)
#define ENTITY_TABLE_MASK (ENTITY_TABLE_SIZE - 1)

typedef struct {
    const char *name;
    const char *value;
    uint8_t     name_len;
} entity_entry;

/* FNV-1a hash for entity names */
static inline uint32_t entity_hash(const char *s, size_t len) {
    uint32_t h = 2166136261u;
    for (size_t i = 0; i < len; i++) {
        h ^= (uint8_t)s[i];
        h *= 16777619u;
    }
    return h;
}

/* Static entity data */
static const entity_entry all_entities[] = {
    {"amp", "&", 3}, {"lt", "<", 2}, {"gt", ">", 2},
    {"quot", "\"", 4}, {"apos", "'", 5}, {"nbsp", "\xC2\xA0", 4},
    {"mdash", "\xE2\x80\x94", 5}, {"ndash", "\xE2\x80\x93", 5},
    {"hellip", "\xE2\x80\xA6", 6}, {"laquo", "\xC2\xAB", 5},
    {"raquo", "\xC2\xBB", 5}, {"copy", "\xC2\xA9", 4},
    {"reg", "\xC2\xAE", 3}, {"trade", "\xE2\x84\xA2", 5},
    {"times", "\xC3\x97", 5}, {"divide", "\xC3\xB7", 6},
    {"cent", "\xC2\xA2", 4}, {"pound", "\xC2\xA3", 5},
    {"yen", "\xC2\xA5", 3}, {"euro", "\xE2\x82\xAC", 4},
    {"lsquo", "\xE2\x80\x98", 5}, {"rsquo", "\xE2\x80\x99", 5},
    {"ldquo", "\xE2\x80\x9C", 5}, {"rdquo", "\xE2\x80\x9D", 5},
    {"bull", "\xE2\x80\xA2", 4}, {"middot", "\xC2\xB7", 6},
    {"para", "\xC2\xB6", 4}, {"sect", "\xC2\xA7", 4},
    {"deg", "\xC2\xB0", 3}, {"plusmn", "\xC2\xB1", 6},
    {"sup1", "\xC2\xB9", 4}, {"sup2", "\xC2\xB2", 4}, {"sup3", "\xC2\xB3", 4},
    {"frac14", "\xC2\xBC", 6}, {"frac12", "\xC2\xBD", 6}, {"frac34", "\xC2\xBE", 6},
    {"iexcl", "\xC2\xA1", 5}, {"iquest", "\xC2\xBF", 6},
    {"Agrave", "\xC3\x80", 6}, {"Aacute", "\xC3\x81", 6},
    {"Acirc", "\xC3\x82", 5}, {"Atilde", "\xC3\x83", 6},
    {"Auml", "\xC3\x84", 4}, {"Aring", "\xC3\x85", 5},
    {"AElig", "\xC3\x86", 5}, {"Ccedil", "\xC3\x87", 6},
    {"Egrave", "\xC3\x88", 6}, {"Eacute", "\xC3\x89", 6},
    {"Ecirc", "\xC3\x8A", 5}, {"Euml", "\xC3\x8B", 4},
    {"Igrave", "\xC3\x8C", 6}, {"Iacute", "\xC3\x8D", 6},
    {"Icirc", "\xC3\x8E", 5}, {"Iuml", "\xC3\x8F", 4},
    {"ETH", "\xC3\x90", 3}, {"Ntilde", "\xC3\x91", 6},
    {"Ograve", "\xC3\x92", 6}, {"Oacute", "\xC3\x93", 6},
    {"Ocirc", "\xC3\x94", 5}, {"Otilde", "\xC3\x95", 6},
    {"Ouml", "\xC3\x96", 4}, {"Oslash", "\xC3\x98", 6},
    {"Ugrave", "\xC3\x99", 6}, {"Uacute", "\xC3\x9A", 6},
    {"Ucirc", "\xC3\x9B", 5}, {"Uuml", "\xC3\x9C", 4},
    {"Yacute", "\xC3\x9D", 6}, {"THORN", "\xC3\x9E", 5},
    {"szlig", "\xC3\x9F", 5},
    {"agrave", "\xC3\xA0", 6}, {"aacute", "\xC3\xA1", 6},
    {"acirc", "\xC3\xA2", 5}, {"atilde", "\xC3\xA3", 6},
    {"auml", "\xC3\xA4", 4}, {"aring", "\xC3\xA5", 5},
    {"aelig", "\xC3\xA6", 5}, {"ccedil", "\xC3\xA7", 6},
    {"egrave", "\xC3\xA8", 6}, {"eacute", "\xC3\xA9", 6},
    {"ecirc", "\xC3\xAA", 5}, {"euml", "\xC3\xAB", 4},
    {"igrave", "\xC3\xAC", 6}, {"iacute", "\xC3\xAD", 6},
    {"icirc", "\xC3\xAE", 5}, {"iuml", "\xC3\xAF", 4},
    {"eth", "\xC3\xB0", 3}, {"ntilde", "\xC3\xB1", 6},
    {"ograve", "\xC3\xB2", 6}, {"oacute", "\xC3\xB3", 6},
    {"ocirc", "\xC3\xB4", 5}, {"otilde", "\xC3\xB5", 6},
    {"ouml", "\xC3\xB6", 4}, {"oslash", "\xC3\xB8", 6},
    {"ugrave", "\xC3\xB9", 6}, {"uacute", "\xC3\xBA", 6},
    {"ucirc", "\xC3\xBB", 5}, {"uuml", "\xC3\xBC", 4},
    {"yacute", "\xC3\xBD", 6}, {"thorn", "\xC3\xBE", 5},
    {"yuml", "\xC3\xBF", 4},
};

#define NUM_ENTITIES (sizeof(all_entities) / sizeof(all_entities[0]))

/* Hash table: stores indices into all_entities[] */
static int entity_table[ENTITY_TABLE_SIZE];
static int entity_table_initialized = 0;

static void entity_table_init(void) {
    /* Fill with -1 (empty) */
    for (int i = 0; i < ENTITY_TABLE_SIZE; i++)
        entity_table[i] = -1;

    /* Insert all entities */
    for (int i = 0; i < (int)NUM_ENTITIES; i++) {
        const entity_entry *e = &all_entities[i];
        uint32_t h = entity_hash(e->name, e->name_len);
        int slot = (int)(h & ENTITY_TABLE_MASK);
        /* Linear probing */
        while (entity_table[slot] != -1)
            slot = (slot + 1) & ENTITY_TABLE_MASK;
        entity_table[slot] = i;
    }
    entity_table_initialized = 1;
}

static const entity_entry *entity_lookup(const char *name, size_t name_len) {
    if (!entity_table_initialized)
        entity_table_init();

    uint32_t h = entity_hash(name, name_len);
    int slot = (int)(h & ENTITY_TABLE_MASK);

    while (entity_table[slot] != -1) {
        const entity_entry *e = &all_entities[entity_table[slot]];
        if (e->name_len == (int)name_len && memcmp(e->name, name, name_len) == 0)
            return e;
        slot = (slot + 1) & ENTITY_TABLE_MASK;
    }
    return NULL;
}

static int hex_val(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

static inline void append_utf8(h2md_buf *buf, unsigned int cp) {
    if (cp < 0x80) {
        h2md_buf_append_char(buf, (char)cp);
    } else if (cp < 0x800) {
        h2md_buf_append_char(buf, (char)(0xC0 | (cp >> 6)));
        h2md_buf_append_char(buf, (char)(0x80 | (cp & 0x3F)));
    } else if (cp < 0x10000) {
        h2md_buf_append_char(buf, (char)(0xE0 | (cp >> 12)));
        h2md_buf_append_char(buf, (char)(0x80 | ((cp >> 6) & 0x3F)));
        h2md_buf_append_char(buf, (char)(0x80 | (cp & 0x3F)));
    } else {
        h2md_buf_append_char(buf, (char)(0xF0 | (cp >> 18)));
        h2md_buf_append_char(buf, (char)(0x80 | ((cp >> 12) & 0x3F)));
        h2md_buf_append_char(buf, (char)(0x80 | ((cp >> 6) & 0x3F)));
        h2md_buf_append_char(buf, (char)(0x80 | (cp & 0x3F)));
    }
}

int h2md_entity_decode(h2md_buf *buf, const char *s, size_t max_len) {
    if (max_len < 2 || s[0] != '&')
        return 0;

    /* Numeric entity: &#NNN; or &#xHHH; */
    if (s[1] == '#') {
        size_t pos = 2;
        unsigned int cp = 0;
        int base = 10;

        if (pos < max_len && (s[pos] == 'x' || s[pos] == 'X')) {
            base = 16;
            pos++;
        }

        int started = 0;
        while (pos < max_len && s[pos] != ';') {
            int v = (base == 16) ? hex_val(s[pos]) : (s[pos] - '0');
            if (v < 0 || v >= base) return 0;
            cp = cp * (unsigned)base + (unsigned)v;
            started = 1;
            pos++;
        }
        if (!started || pos >= max_len || s[pos] != ';')
            return 0;
        append_utf8(buf, cp);
        return (int)(pos + 1);
    }

    /* Named entity: hash table lookup */
    size_t name_len = 0;
    while (name_len < max_len && s[1 + name_len] != ';' && s[1 + name_len] != '\0')
        name_len++;
    if (name_len == 0 || name_len >= max_len || s[1 + name_len] != ';')
        return 0;

    const entity_entry *e = entity_lookup(s + 1, name_len);
    if (e) {
        h2md_buf_append_str(buf, e->value);
        return (int)(name_len + 2); /* & + name + ; */
    }
    return 0;
}
