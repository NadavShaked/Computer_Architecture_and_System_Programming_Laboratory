#include <stdlib.h>
#include <stdio.h>
#include <sys/mman.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include "elf.h"

int fd = -1;

typedef struct {
    char debug_mode;
    void *map_start;
    Elf32_Ehdr* header; /* this will point to the header structure */
} state;

struct fun_desc {
    char* name;
    void (*fun)(state*);
};

void toggleDebugMode(state* s){
    if(s->debug_mode == 1){
        s->debug_mode = 0;
        printf("Debug flag now off \n");
    }
    else {
        s->debug_mode = 1;
        printf("Debug flag now on \n");
    }
}

void examineELFFile(state* s) {
    char input_file[200];
    if(fd != -1)
        close(fd);
    printf("Enter File Name: ");
    fgets(input_file, 200, stdin);
    sscanf(input_file, "%s", input_file);

    if(s->debug_mode == 1)
        printf("File Name:\t%s\n", input_file);

    if((fd = open(input_file, O_RDWR)) < 0) {
        perror("Couldn't Open The File:\t");
        exit(-1);
    }

    struct stat fd_stat;
    if (fstat(fd, &fd_stat) != 0) {
        perror("Couldn't Get Stat's File:ֿ\t");
        close(fd);
        fd = -1;
        exit(-1);
    }

    if ( (s->map_start = mmap(0, fd_stat.st_size, PROT_READ | PROT_WRITE , MAP_SHARED, fd, 0)) == MAP_FAILED ) {
        perror("mmap Failed:\t");
        munmap(s->map_start, fd_stat.st_size);
        close(fd);
        fd = -1;
        exit(-4);
    }

    s->header = (Elf32_Ehdr*) s->map_start;

    if (strncmp("ELF", s->header->e_ident + 1, 3) != 0) {
        printf("The File Isn't ELF File\n");
        munmap(s->map_start, fd_stat.st_size);
        close(fd);
        fd = -1;
        exit(1);
    }

    // Print the Magic Numbers
    printf("Magic Numbers:\n");
    for(int i = 1; i <= 3; i++){
        printf("%d -\t%c\n", i, s->header->e_ident[i]);
    }

    // Print The Encoding Scheme Of The Object File
    if(s->header->e_ident[EI_DATA] == 0)
        printf("Data:\nInvalid data encoding\n");
    else if(s->header->e_ident[EI_DATA] == 1)
        printf("Data:\n2's complement, little endian\n");
    else
        printf("Data:\n2's complement, big endian\n");

    // Print The Entry Point (Hexadecimal Address)
    printf("Entry point:\n%X\n", s->header->e_entry);

    // Print The File Offset In Which The Section Header Table Resides
    printf("Start of section headers:\n%d\n",s->header->e_shoff);

    // Print The Number Of Section Header Entries
    printf("Number of section headers:\n%d\n", s->header->e_shnum);

    // Print The Size Of Each Section Header Entry
    Elf32_Shdr* cur_sectionHeader = (s->map_start + s->header->e_shoff);
    printf("Section Headers Size:\n");
    for (int i = 0; i < s->header->e_shnum; i++) {
        printf("[%d]\t%x\n", i, cur_sectionHeader->sh_size);
        cur_sectionHeader++;
    }

    // Print The File Offset In Which The Program Header Table Resides
    printf("Start of program headers:\n%d\n", s->header->e_phoff);

    // Print The Number Of Program Header Entries
    printf("Number of program headers:\n%d\n", s->header->e_phnum);

    // Print The Size Of Each Program Header Entry
    printf("Size program headers:\n%d\n", s->header->e_phentsize);

    Elf32_Phdr* cur_programHeader = (s->map_start + s->header->e_phoff);
    printf("Program Headers Size:\n");
    for (int i = 0; i < s->header->e_phnum; i++) {
        printf("[%d]\t%x\n", i, cur_programHeader->p_filesz);
        cur_programHeader++;
    }
}

void quit(state* s) {
    if (fd != -1)
        close(fd);
    exit(0);
}

void initializeState(state* s) {
    s->debug_mode = 0;
    fd  = -1;
}

int main(int argc, char **argv){
    int base_len = 5;
    char userInput[11];

    struct fun_desc menu[]= { { "Toggle Debug Mode", toggleDebugMode }, { "Examine ELF File", examineELFFile }, { "Quit", quit }, { NULL, NULL } };
    int menuLen = (sizeof(menu) / sizeof(menu[0])) - 1;
    state s;
    initializeState(&s);
    printf("menu\n");
    while (1) {
        if(s.debug_mode == 1)
            //printStateStatus(&s);
        printf("Please choose a function:\n");
        for (int i = 0; i < menuLen; i++) {
            printf("%d) %s\n", i, menu[i].name);
        }
        printf("Option: ");
        fgets(userInput, 10, stdin);
        int i = atoi(userInput);

        if (i >= 0 && i < menuLen)
            menu[i].fun(&s);
        else {
            printf("Not within bounds\n");
            quit(&s);
        }
    }
}