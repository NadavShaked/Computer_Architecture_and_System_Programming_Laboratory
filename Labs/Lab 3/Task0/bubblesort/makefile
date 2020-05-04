all: bubblesort

bubblesort: bubblesort.o
	gcc -m32 -g -Wall -o bubblesort bubblesort.o

bubblesort.o: bubblesort.c
	gcc -g -Wall -m32  -c -o bubblesort.o bubblesort.c

 .PHONY: clean

clean:
	rm -f *.o bubblesort