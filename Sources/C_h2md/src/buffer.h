#ifndef H2MD_BUFFER_H
#define H2MD_BUFFER_H

#include <stddef.h>

typedef struct {
    char   *data;
    size_t  len;
    size_t  cap;
} h2md_buf;

int    h2md_buf_init(h2md_buf *buf, size_t cap);
void   h2md_buf_destroy(h2md_buf *buf);
int    h2md_buf_ensure(h2md_buf *buf, size_t needed);
void   h2md_buf_append(h2md_buf *buf, const char *s, size_t len);
void   h2md_buf_append_str(h2md_buf *buf, const char *s);
void   h2md_buf_append_char(h2md_buf *buf, char c);
void   h2md_buf_append_repeated(h2md_buf *buf, char c, int n);
char   h2md_buf_last_char(h2md_buf *buf);
char  *h2md_buf_detach(h2md_buf *buf);
int    h2md_buf_shrink(h2md_buf *buf);  /* Shrink to fit, release excess memory */

#endif
