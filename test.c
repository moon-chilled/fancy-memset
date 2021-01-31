#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <stdlib.h>

extern void *fancy_memset_basic(void *s, int c, size_t n);
extern void *fancy_memset_sse2(void *s, int c, size_t n);
extern void *fancy_memset_avx2(void *s, int c, size_t n);

void check(void *(*memsetter)(void*,int,size_t), void *buf, size_t l) {
	for (size_t i = 0; i < l; i++) {
		for (char c = 0; c < 4; c++) {
			char *t1 = memcpy(malloc(l), buf, l);
			char *t2 = memcpy(malloc(l), buf, l);
			void *n1 = memset(t1 + 1, c, l - 2);
			void *n2 = memsetter(t2 + 1, c, l - 2);
			if (n1 != t1+1 || n2 != t2+1 || memcmp(t1, t2, l)) {
				printf("error: %zu/%d\n", l, c);
				exit(1);
			}
			free(t1);
			free(t2);
		}
	}
	free(buf);
}

#define GB (1024ul * 1024 * 1024)

int main() {
	for (size_t i = 2; i < 0x500; i++) check(fancy_memset_basic, malloc(i), i);
	for (size_t i = 2; i < 0x500; i++) check(fancy_memset_sse2, malloc(i), i);
	for (size_t i = 2; i < 0x500; i++) check(fancy_memset_avx2, malloc(i), i);
	// todo 32-bit signed/unsigned overflow test
}
