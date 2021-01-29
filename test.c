#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <stdlib.h>

extern void *fancy_memset(void *s, int c, size_t n);
extern void *fancy_memset_avx2(void *s, int c, size_t n);

void check(void *(*memsetter)(void*,int,size_t), void *buf, size_t l) {
	for (size_t i = 0; i < l; i++) {
		for (char c = 0; c < 4; c++) {
			void *t1 = memset(memcpy(malloc(l), buf, l), c, l);
			void *t2 = memsetter(memcpy(malloc(l), buf, l), c, l);
			if(memcmp(t1, t2, l)) {
				printf("error: %zu/%d\n", l, c);
				exit(1);
			}
			free(t1);
			free(t2);
		}
	}
	free(buf);
}

int main() {
	for (size_t i = 0; i < 0x500; i++) check(fancy_memset, malloc(i), i);
	for (size_t i = 0; i < 0x500; i++) check(fancy_memset_avx2, malloc(i), i);
}
