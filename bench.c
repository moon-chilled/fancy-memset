#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include <stdint.h>
#include <x86intrin.h>

extern void *fancy_memset(void *s, int c, size_t n);
extern void *fancy_memset_avx2(void *s, int c, size_t n);
extern void *stos_memset(void *s, int c, size_t n);
extern void *bionic_memset(void *s, int c, size_t n);
extern void *freebsd_memset(void *s, int c, size_t n);
#define N1 5
#define N2 1000000

#define bencher(p, fn) \
	for (int i = 0; i < 16; i++) fn(buf, 0, l); /* cache! */\
	uint64_t p##before[N1], p##after[N1]; \
	uint64_t p##avg = 0, p##stddev = 0; \
	for (int i = 0; i < N1; i++) { \
		p##before[i] = __rdtsc(); \
		for (int _ = 0; _ < N2; _++) fn(buf, 0, l); \
		p##after[i] = __rdtsc(); \
		p##avg += p##after[i] - p##before[i]; \
	} \
	p##avg /= N1; \
	for (int i = 0; i < N1; i++) p##stddev += (p##after[i] - p##before[i] - p##avg) * (p##after[i] - p##before[i] - p##avg); \
	p##stddev = sqrt(p##stddev/N1);

void bench(void *buf, size_t l) {
	bencher(sys_, memset);
	bencher(bionic_, bionic_memset);
	bencher(freebsd_, freebsd_memset);
	bencher(stos_, stos_memset);
	bencher(fancy_, fancy_memset);
	bencher(fancy_avx2_, fancy_memset_avx2);

	double avg = fancy_avg, stddev = fancy_stddev;
	uint64_t d[] = {sys_avg, bionic_avg, freebsd_avg, stos_avg, fancy_avg, fancy_avx2_avg};
	uint64_t d2[] = {sys_stddev, bionic_stddev, freebsd_stddev, stos_stddev, fancy_stddev, fancy_avx2_stddev};
	printf("%10zu:", l);
	for (int i = 0; i < sizeof(d)/sizeof(d[0]); i++) {
		double x = avg / d[i];
		double delta = abs(avg - d[i]);
		if (delta < d2[i] || delta < stddev
		    || (0.95 < x && x < 1.05)) ; //insignificant
		else if (x < 1) printf("\x1b[31m");
		else if (x > 1) printf("\x1b[32m");
		if (x < 0.8 || x > 1.2) printf("\x1b[1m");
		printf("	%2.3lf\x1b[0m", x);
	}
	putchar('\n');
}

void test(size_t l) {
	void *x = malloc(l);
	bench(x, l);
	free(x);
}

int main() {
	printf("numbers are proportions; higher is better\n");
	printf("size class:	system	bionic	fbsd	stos	fancy	avx2\n");
	for (int i = 0; i <= 135; i++) test(i);
	for (int i = 505; i <= 515; i++) test(i);
	for (int i = 795; i <= 805; i++) test(i);
	for (int i = 4090; i <= 4100; i++) test(i);
}
