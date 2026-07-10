#include "h2md.h"
#include "buffer.h"
#include "parser.h"
#include <stdlib.h>
#include <string.h>

#define H2MD_VERSION "2.0.0"

/* Estimate output buffer size from input size.
 * HTML->Markdown conversion typically reduces size by ~20-40%.
 * Small inputs (<1KB) use 1KB buffer, larger use 80% of input. */
static size_t estimate_capacity(size_t input_len) {
    if (input_len < 1024) return 1024;
    size_t est = input_len + (input_len >> 2); /* 1.25x */
    if (est > (1 << 20)) est = 1 << 20;
    return est;
}

char *h2md_convert(const char *input) {
    if (!input || !*input) {
        char *empty = (char *)malloc(1);
        if (empty) empty[0] = '\0';
        return empty;
    }

    size_t input_len = strlen(input);
    size_t cap = estimate_capacity(input_len);

    h2md_buf buf;
    if (h2md_buf_init(&buf, cap) != 0)
        return NULL;

    h2md_parser parser;
    h2md_parser_init(&parser, &buf);
    h2md_parser_run(&parser, input);

    /* Shrink buffer to release excess memory before returning */
    h2md_buf_shrink(&buf);

    return h2md_buf_detach(&buf);
}

void h2md_free(char *result) {
    free(result);
}

const char *h2md_version(void) {
    return H2MD_VERSION;
}
