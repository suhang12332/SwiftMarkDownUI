#include "buffer.h"
#include <stdlib.h>
#include <string.h>

#define H2MD_BUF_INIT_CAP  4096
#define H2MD_BUF_MAX_GROW  (1 << 20) /* 1MB max single grow */

int h2md_buf_init(h2md_buf *buf, size_t cap) {
    if (cap < H2MD_BUF_INIT_CAP)
        cap = H2MD_BUF_INIT_CAP;
    buf->data = (char *)malloc(cap);
    if (!buf->data)
        return -1;
    buf->len = 0;
    buf->cap = cap;
    return 0;
}

void h2md_buf_destroy(h2md_buf *buf) {
    free(buf->data);
    buf->data = NULL;
    buf->len = 0;
    buf->cap = 0;
}

int h2md_buf_ensure(h2md_buf *buf, size_t needed) {
    if (buf->len + needed <= buf->cap)
        return 0;
    size_t new_cap = buf->cap;
    while (new_cap < buf->len + needed)
        new_cap *= 2;
    if (new_cap - buf->cap > H2MD_BUF_MAX_GROW)
        new_cap = buf->cap + H2MD_BUF_MAX_GROW;
    if (new_cap < buf->len + needed)
        new_cap = buf->len + needed;
    char *p = (char *)realloc(buf->data, new_cap);
    if (!p)
        return -1;
    buf->data = p;
    buf->cap = new_cap;
    return 0;
}

void h2md_buf_append(h2md_buf *buf, const char *s, size_t len) {
    if (len == 0) return;
    h2md_buf_ensure(buf, len);
    memcpy(buf->data + buf->len, s, len);
    buf->len += len;
}

void h2md_buf_append_str(h2md_buf *buf, const char *s) {
    h2md_buf_append(buf, s, strlen(s));
}

void h2md_buf_append_char(h2md_buf *buf, char c) {
    h2md_buf_ensure(buf, 1);
    buf->data[buf->len++] = c;
}

void h2md_buf_append_repeated(h2md_buf *buf, char c, int n) {
    if (n <= 0) return;
    h2md_buf_ensure(buf, (size_t)n);
    memset(buf->data + buf->len, c, (size_t)n);
    buf->len += (size_t)n;
}

char h2md_buf_last_char(h2md_buf *buf) {
    if (buf->len == 0) return '\0';
    return buf->data[buf->len - 1];
}

char *h2md_buf_detach(h2md_buf *buf) {
    /* Ensure we have room for null terminator without realloc when possible */
    if (buf->len < buf->cap) {
        buf->data[buf->len] = '\0';
    } else {
        /* Need to grow by 1 byte */
        char *p = (char *)realloc(buf->data, buf->len + 1);
        if (!p) {
            /* Fallback: free and return NULL */
            free(buf->data);
            buf->data = NULL;
            buf->len = 0;
            buf->cap = 0;
            return NULL;
        }
        buf->data = p;
        buf->data[buf->len] = '\0';
    }
    char *result = buf->data;
    buf->data = NULL;
    buf->len = 0;
    buf->cap = 0;
    return result;
}

int h2md_buf_shrink(h2md_buf *buf) {
    /* If buffer has less than 25% utilization and is >4KB, shrink to fit */
    if (buf->cap > 4096 && buf->len < buf->cap / 4) {
        size_t new_cap = buf->len + 1; /* +1 for null terminator */
        if (new_cap < 256) new_cap = 256; /* Minimum 256 bytes */
        char *p = (char *)realloc(buf->data, new_cap);
        if (p) {
            buf->data = p;
            buf->cap = new_cap;
            return 0;
        }
        return -1;
    }
    return 0;
}
