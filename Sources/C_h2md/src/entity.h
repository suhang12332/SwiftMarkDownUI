#ifndef H2MD_ENTITY_H
#define H2MD_ENTITY_H

#include "buffer.h"
#include <stdint.h>

/* Decode an HTML entity starting at `s`. Writes decoded output to `buf`.
 * Returns the number of characters consumed from `s` (0 if not valid entity). */
int h2md_entity_decode(h2md_buf *buf, const char *s, size_t max_len);

#endif
