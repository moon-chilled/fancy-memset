CFLAGS := -O3 -fno-builtin

default: dobench

bench: bench.c memset.s
	$(CC) $(CFLAGS) -o bench bench.c memset.s
dobench: bench
	./bench
test: test.c memset.s
	$(CC) $(CFLAGS) -o test test.c memset.s
dotest: tst
	./test
