all: count-words

count-words: count-words.o
	gcc -m32 -g -Wall -o count-words count-words.o

count-words.o: count-words.c
	gcc -g -Wall -m32  -c -o count-words.o count-words.c

 .PHONY: clean

clean:
	rm -f *.o count-words

