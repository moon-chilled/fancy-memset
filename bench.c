#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <stdlib.h>
#include <stdint.h>
#include <x86intrin.h>

extern void *fast_memset(void *s, int c, size_t n);

#define bencher(name, fn) \
	for (int i = 0; i < 16; i++) fn(buf, 0, l); \
	uint64_t name ## _before = __rdtsc(); \
	for (int i = 0; i < 2000; i++) fn(buf, 0, l); \
	uint64_t name ## _after = __rdtsc()

void bench(void *buf, size_t l) {
	bencher(sys, memset);
	bencher(fm, fast_memset);

	printf("Sys: %llu cycles; fm: %llu cycles\n", sys_after - sys_before, fm_after - fm_before);
}

void test(size_t l) {
	void *x = malloc(l);
	bench(x, l);
	free(x);
}

int main() {
	//for (size_t i = 0; i < 0x50; i++) test(i);
	test(0x90);
}
