task2Assignment1: run

run: asm_task2Assignment1.o main_task2Assignment1.o
	gcc -m32 -g -Wall -o t main_task2Assignment1.o asm_task2Assignment1.o
	
main_task2Assignment1.o: main_task2Assignment1.c
	gcc -g -Wall -m32 -c -o main_task2Assignment1.o main_task2Assignment1.c
	
asm_task2Assignment1.o: asm_task2Assignment1.s
	nasm -f elf32 asm_task2Assignment1.s -o asm_task2Assignment1.o

 .PHONY: clean

clean:
	rm -f *.o asm_task2Assignment1.out