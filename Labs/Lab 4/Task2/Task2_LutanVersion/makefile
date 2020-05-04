all: setup flame2

flame2: flame2.o util.o start.o
	gcc -g -O0 -m32 -Wall -nostdlib -fno-stack-protector start.o flame2.o util.o -o flame2

flame2.o: flame2.c
	gcc -g -O0 -m32 -Wall -c -nostdlib -fno-stack-protector flame2.c -o flame2.o

util.o: util.c
	gcc -g -O0 -m32 -Wall -c -nostdlib -fno-stack-protector util.c -o util.o

start.o: start.s
	nasm -f elf32 start.s -o start.o

.PHONEY: clean
clean: 
	rm ./*.o flame2 ./a ./b -rf

setup:
	wget https://www.cs.bgu.ac.il/~caspl202/wiki.files/greeting -O greeting
	chmod +x ./greeting
	mkdir -p ./a/aa
	mkdir -p ./a/ab
	mkdir -p ./b/ba
	mkdir -p ./b/bb
	mkdir -p ./b/bc
	cp ./greeting ./a/aa/target1
	cp ./greeting ./a/aa/target2
	cp ./greeting ./a/ab/target3
	cp ./greeting ./b/ba/target4
	cp ./greeting ./b/ba/target5
	cp ./greeting ./b/ba/target6
	cp ./greeting ./b/bb/target7
	cp ./greeting ./b/bc/target8
	cp ./greeting ./a/non_target1
	cp ./greeting ./b/non_target2
	cp ./greeting ./b/non_target3