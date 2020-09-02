all: myElf

myElf: myElf.o 
	gcc -g -m32 -fno-pie -no-pie -Wall -o myElf myElf.o
myElf.o: myElf.c
	gcc -m32 -g -fno-pie -no-pie -Wall -c -o myElf.o myElf.c 
.PHONY: clean

clean:
	rm -rf ./*.o myElf