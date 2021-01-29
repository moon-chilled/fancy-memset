CFLAGS := -O3 -g -fno-builtin
LFLAGS := -lm
erms := --defsym erms=1
AFLAGS := -g $(erms)
AS := as

default: dobench

bench: bench.o memset.o competition/stos.o competition/bionic-memset.o
	$(CC) $(LFLAGS) -o bench bench.o memset.o competition/stos.o competition/bionic-memset.o
dobench: bench
	./bench
test: test.o memset.o
	$(CC) $(LFLAGS) -o test test.o memset.o

dotest: test
	./test

.s.o:
	$(AS) $(AFLAGS) -o $@ $<
competition/bionic-memset.o: competition/bionic-memset.s
	$(CC) -x assembler-with-cpp -c -o competition/bionic-memset.o competition/bionic-memset.s

clean:
	rm -f *.o competition/*.o test bench
