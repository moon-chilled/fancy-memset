#include <stddef.h>
void *naive_memset(void *s, int c, size_t n) {
	for (char *x = s, *e = s + n; x < e; x++) *x = c;
	return s;
}
