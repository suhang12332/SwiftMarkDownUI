#ifndef H2MD_H
#define H2MD_H

#ifdef __cplusplus
extern "C" {
#endif

/* Convert HTML or HTML+Markdown mixed content to standard Markdown.
 * Caller must free() the returned string. Returns NULL on failure. */
char *h2md_convert(const char *input);

/* Free a string returned by h2md_convert(). */
void h2md_free(char *result);

/* Library version string. */
const char *h2md_version(void);

#ifdef __cplusplus
}
#endif

#endif
