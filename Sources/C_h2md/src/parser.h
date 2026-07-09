#ifndef H2MD_PARSER_H
#define H2MD_PARSER_H

#include "buffer.h"
#include <stdint.h>

#define MAX_LIST_DEPTH 16

typedef struct {
    int in_ol;
    int counter;
} list_state;

typedef struct {
    h2md_buf *buf;
    int       in_pre;
    int       in_code;
    int       need_blocksep;
    int       list_depth;
    int       list_counter;
    int       in_ol;
    list_state list_stack[MAX_LIST_DEPTH];
    int       list_stack_top;
    int       in_blockquote;
    int       in_table;
    int       table_row_count;
    int       in_first_row;
    int       table_col_count;
    char      tag_name[32];
    int       tag_name_len;
    char      attr_buf[1024];
    int       attr_len;
    int       in_tag;
    int       self_closing;
    /* Extracted attributes */
    char      href[256];
    int       href_len;
    char      src[512];
    int       src_len;
    char      alt[128];
    int       alt_len;
    char      lang[64];
    int       lang_len;
    /* Saved href for <a> tags (only href is saved, not src/alt/lang) */
    char      saved_href[256];
    int       saved_href_len;
    int       in_link;
} h2md_parser;

void h2md_parser_init(h2md_parser *p, h2md_buf *buf);
void h2md_parser_run(h2md_parser *p, const char *input);

#endif
