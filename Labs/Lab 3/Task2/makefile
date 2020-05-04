all: Task2

Task2: Task2.o
	gcc -m32 -g -Wall -o Task2 Task2.o

Task2.o: Task2.c
	gcc -g -Wall -m32  -c -o Task2.o Task2.c

 .PHONY: clean

clean:
	rm -f *.o Task2