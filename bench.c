#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include <stdint.h>
#include <x86intrin.h>

extern void *fancy_memset(void *s, int c, size_t n);
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

	double avg = fancy_avg;
	uint64_t d[] = {sys_avg, bionic_avg, freebsd_avg, stos_avg, fancy_avg};
	printf("%10zu:", l);
	for (int i = 0; i < sizeof(d)/sizeof(d[0]); i++) {
		double x = avg / d[i];
		if (x > 1) printf("\x1b[31m");
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
	printf("size class:	system	bionic	fbsd	stos	fancy\n");
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
	for (int i = 120; i <= 135; i++) test(i);
	for (int i = 505; i <= 515; i++) test(i);
	for (int i = 795; i <= 805; i++) test(i);
	for (int i = 4090; i <= 4100; i++) test(i);
}
