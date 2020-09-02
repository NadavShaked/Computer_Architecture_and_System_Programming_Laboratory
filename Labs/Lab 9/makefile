
skeleton: skeleton.o
	ld -m elf_i386 -o skeleton skeleton.o

# Depends on the source and header files
 
skeleton.o: skeleton.s
	nasm -g -f elf -w+all -o skeleton.o skeleton.s


#tell make that "clean" is not a file name!
.PHONY: clean

#Clean the build directory
clean: 
	rm -f *.o skeleton
