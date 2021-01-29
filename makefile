FLAGS := -O3 -g -fno-builtin -lm

default: dobench

bench: bench.c memset.s
	$(CC) $(FLAGS) -o bench bench.c memset.s
dobench: bench
	./bench
test: test.c memset.s
	$(CC) $(FLAGS) -o test test.c memset.s
dotest: test
	./test
