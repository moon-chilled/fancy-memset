#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <stdlib.h>

extern void *fancy_memset_basic(void *s, int c, size_t n);
extern void *fancy_memset_sse2(void *s, int c, size_t n);
extern void *fancy_memset_avx2(void *s, int c, size_t n);

void check(void *(*memsetter)(void*,int,size_t), void *buf, size_t l, const char *name) {
	for (size_t i = 0; i < 4; i++) {
		for (char c = 0; c < 4; c++) {
			char *t1 = memcpy(malloc(l), buf, l);
			char *t2 = memcpy(malloc(l), buf, l);
			void *n1 = memset(t1 + 1, c, l - 2);
			void *n2 = memsetter(t2 + 1, c, l - 2);
			if (n1 != t1+1 || n2 != t2+1 || memcmp(t1, t2, l)) {
				printf("error %s/%zu/%d\n", name, l, c);
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
	void *(*fs[])(void*,int,size_t) = {fancy_memset_basic, fancy_memset_sse2, fancy_memset_avx2};
	const char *ns[] = {"basic", "sse2", "avx2"};
	for (int j = 0; j < sizeof(fs)/sizeof(fs[0]); j++) {
#define T(z) check(fs[j], malloc(z), (z), ns[j])
		for (int i = 2; i < 0x500; i++) T(i);
		T(2047); T(2048); T(2049);
		T(3071); T(3072); T(3073);
		T(4095); T(4096); T(4097);
		T(256*1024 - 1); T(256*1024); T(256*1024 + 1);
	}
	// todo 32-bit signed/unsigned overflow test
}
