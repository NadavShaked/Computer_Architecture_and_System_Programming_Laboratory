all: Task1

Task1: Task1.o
	gcc -m32 -g -Wall -o Task1 Task1.o

Task1.o: Task1.c
	gcc -g -Wall -m32  -c -o Task1.o Task1.c

 .PHONY: clean

clean:
	rm -f *.o Task1