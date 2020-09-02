#format is target-name: target dependencies
#{-tab-}actions

#All Targets
all: mypipeline

#Tool invocations
#Executable "mypipeline" depends on the files LineParser.o, mypipeline.o and add.o
mypipeline: mypipeline.o
	gcc -m32 -g -Wall -o mypipeline mypipeline.o

mypipeline.o: mypipeline.c
	gcc -g -Wall -m32 -ansi -c -o mypipeline.o mypipeline.c

#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean:
	rm -f *.o mypipeline