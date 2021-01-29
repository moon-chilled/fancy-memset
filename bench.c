#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include <stdint.h>
#include <x86intrin.h>

extern void *fancy_memset(void *s, int c, size_t n);
#define N1 20
#define N2 10000000

#define bencher(before, after, avg, stddev, fn) \
	for (int i = 0; i < 16; i++) fn(buf, 0, l); /* cache! */\
	uint64_t before[N1], after[N1]; \
	uint64_t avg = 0, stddev = 0; \
	for (int i = 0; i < N1; i++) { \
		before[i] = __rdtsc(); \
		for (int _ = 0; _ < N2; _++) fn(buf, 0, l); \
		after[i] = __rdtsc(); \
		avg += after[i] - before[i]; \
	} \
	avg /= N1; \
	for (int i = 0; i < N1; i++) stddev += (after[i] - before[i] - avg) * (after[i] - before[i] - avg); \
	stddev = sqrt(stddev/N1);

void bench(void *buf, size_t l) {
	bencher(sys_before, sys_after, sys_avg, sys_stddev, memset);
	bencher(fm_before, fm_after, fm_avg, fm_stddev, fancy_memset);

	printf("%4zu: %lf\t(%lli/%lli)\n", l, sys_avg / (double)fm_avg, sys_avg, fm_avg);
	//printf("Sys: %llu +/- %llu cycles;\n fm: %llu +/- %llu cycles\n", sys_avg, sys_stddev, fm_avg, fm_stddev);
}

void test(size_t l) {
	void *x = malloc(l);
	bench(x, l);
	free(x);
}

int main() {
	printf("Numbers are ratios of systemmemset:fancymemset time.  Higher is better (for us).\n");
	for (int i = 0; i <= 8; i++) test(i);
	test(13);
	test(15);
	test(16);
	test(17);
	test(31);
	test(32);
	test(33);
	test(55);
	test(63);
	test(64);
	test(65);
	test(128);
	test(512);
	test(800);
	test(4096);
}
