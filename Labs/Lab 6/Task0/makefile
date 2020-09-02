#format is target-name: target dependencies
#{-tab-}actions

#All Targets
all: myPipe

#Tool invocations
#Executable "myPipe" depends on the files LineParser.o, myPipe.o and add.o
myPipe: myPipe.o
	gcc -m32 -g -Wall -o myPipe myPipe.o

myPipe.o: myPipe.c
	gcc -g -Wall -m32 -ansi -c -o myPipe.o myPipe.c

#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean:
	rm -f *.o myPipe