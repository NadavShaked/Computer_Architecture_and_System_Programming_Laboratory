assignment0: run

run: asmAssignment0.o mainAssignment0.o
	gcc -m32 -g -Wall -o asmAssignment0.out mainAssignment0.o asmAssignment0.o
	
mainAssignment0.o: mainAssignment0.c
	gcc -g -Wall -m32 -c -o mainAssignment0.o mainAssignment0.c
	
asmAssignment0.o: asmAssignment0.s
	nasm -f elf32 asmAssignment0.s -o asmAssignment0.o

 .PHONY: clean

clean:
	rm -f *.o asmAssignment0.out