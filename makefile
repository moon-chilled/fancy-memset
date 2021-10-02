CFLAGS := -O3 -g -fno-builtin
LFLAGS := -lm
merms := --defsym erms=1
mq := --defsym ermsq=1
cerms := -Derms=1
cq := -Dermsq=1
erms ?= erms
AFLAGS := -g $(m$(erms))
CAFLAGS := $(c$(erms))
AS := as
M := memset-basic.o memset-sse2.o memset-avx2.o
C := competition/stos.o competition/bionic-memset.o competition/freebsd-memset.o competition/naive-memset.o competition/solaris-memset.o

default: dobench

bench: bench.o $(M) $(C)
	$(CC) $(LFLAGS) -o bench bench.o $(M) $(C)
dobench: bench
	./bench
test: test.o $(M)
	$(CC) $(LFLAGS) -o test test.o $(M)

memset: $(M)
	$(CC) -shared -o memset-basic.so memset-basic.o
	$(CC) -shared -o memset-sse2.so memset-sse2.o
	$(CC) -shared -o memset-avx2.so memset-avx2.o

dotest: test
	./test

.s.o:
	$(AS) $(AFLAGS) -o $@ $<
.S.o:
	$(CC) $(CAFLAGS) -x assembler-with-cpp -c -o $@ $<

clean:
	rm -f *.o competition/*.o test bench
