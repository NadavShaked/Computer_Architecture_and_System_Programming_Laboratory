#format is target-name: target dependencies
#{-tab-}actions

#All Targets
all: myShell

#Tool invocations
#Executable "myShell" depends on the files LineParser.o, myShell.o and add.o
myShell: LineParser.o myShell.o
	gcc -m32 -g -Wall -o myShell LineParser.o myShell.o

#Depends on the source and header files
LineParser.o: LineParser.c
	gcc -g -Wall -m32 -ansi -c -o LineParser.o LineParser.c

myShell.o: myShell.c
	gcc -g -Wall -m32 -ansi -c -o myShell.o myShell.c

#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean:
	rm -f *.o myShell