#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <stdlib.h>

extern void *fast_memset(void *s, int c, size_t n);

void check(void *buf, size_t l) {
	for (size_t i = 0; i < l; i++) {
		for (char c = 0; c < 4; c++) {
			void *t1 = memset(memcpy(malloc(l), buf, l), c, l);
			void *t2 = fast_memset(memcpy(malloc(l), buf, l), c, l);
			assert(!memcmp(t1, t2, l));
			free(t1);
			free(t2);
		}
	}
	free(buf);
}

int main() {
	for (size_t i = 0; i < 0x500; i++) check(malloc(i), i);
}
