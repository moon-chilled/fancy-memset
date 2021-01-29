CFLAGS := -O3 -g -fno-builtin
LFLAGS := -lm
erms := --defsym erms=1
AFLAGS := -g $(erms)
AS := as

default: dobench

bench: bench.o memset.o
	$(CC) $(LFLAGS) -o bench bench.o memset.o
dobench: bench
	./bench
test: test.o memset.o
	$(CC) $(LFLAGS) -o test test.o memset.o

dotest: test
	./test

memset.o: memset.s
	$(AS) $(AFLAGS) -o memset.o memset.s

clean:
	rm -f memset.o test.o bench.o test bench
