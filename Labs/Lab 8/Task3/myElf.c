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

char* get_Type(int type){
    if(type == 0) return "NULL";
    if(type == 1) return "PROGBITS";
    if(type == 2) return "SYMTAB";
    if(type == 3) return "STRTAB";
    if(type == 4) return "RELA";
    if(type == 5 || type == 1979048190) return "HASH";
    if(type == 6) return "DYNAMIC";
    if(type == 7) return "NOTE";
    if(type == 8) return "NOBITS";
    if(type == 9) return "REL";
    if(type == 10) return "SHLIB";
    if(type == 11) return "DYNSYM";
    if(type == 0x6ffffffa) return "SUNW_move";
    if(type == 0x6ffffffb) return "SUNW_COMDAT";
    if(type == 0x6ffffffc) return "SUNW_syminfo";
    if(type == 0x6ffffffd) return "SUNW_verdef";
    if(type == 0x6ffffffe) return "SUNW_verneed";
    if(type == 0x6fffffff) return "SUNW_versym";
    if(type == 0x70000000) return "LOPROC";
    if(type == 0x7fffffff) return "HIPROC";
    if(type == 0x80000000) return "LOUSER";
    if(type == 0xffffffff) return "HIUSER";
    else return "";
}

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

    // printf("\n\n\n%d\n\n\n", s->debug_mode);

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

void printSectionNames(state* s) {
    if (s->header == NULL) {
        printf("There Is No ELF File To Print...\n");
        return;
    }

    Elf32_Shdr* sectionHeader_table = (s->map_start + s->header->e_shoff);
    Elf32_Shdr* cur_sectionHeader = sectionHeader_table;

    char* stringTable = (char*) s->map_start + (sectionHeader_table + s->header->e_shstrndx)->sh_offset;
    
    printf("[i]\tSection Name\tSection Address\tSection Offset\tSection Size\tSection Type\n");
    for (int i = 0; i < s->header->e_shnum; i++) {
        printf("[%d]\t%s\t%X\t%X\t%d\t%s\n", i , (stringTable + cur_sectionHeader->sh_name), cur_sectionHeader->sh_addr, cur_sectionHeader->sh_offset, cur_sectionHeader->sh_size, get_Type(cur_sectionHeader->sh_type));
        cur_sectionHeader++;
    }
}

void printSymbols(state* s) {
    if (s->header == NULL) {
        printf("There Is No ELF File To Print...\n");
        return;
    }

    Elf32_Shdr* sh_symbolTable = (s->map_start + s->header->e_shoff);

    char* stringtable = (char*)s->map_start + ( sh_symbolTable + s->header->e_shstrndx)->sh_offset;
    char* symStringtable;

    Elf32_Shdr* sectionHeaderTable = (s->map_start + s->header->e_shoff);

    for ( int i = 0; i < s->header->e_shnum; i++) {
        if(sh_symbolTable->sh_type == 2){
            symStringtable = (char*)(s->map_start + (sectionHeaderTable + sectionHeaderTable[i].sh_link)->sh_offset);
            break;
        }
        sh_symbolTable++;
    }

    int numOfSymbols = sh_symbolTable->sh_size / sizeof(Elf32_Sym);

    Elf32_Sym* cur_in_symbolTable = (Elf32_Sym*)(s->map_start + (sh_symbolTable->sh_offset)); 
    Elf32_Shdr* curSymbolSectionHeader;

    int sectionHeaderName;
    int symbolName;
    printf("index\tvalue\tsection_index\tsection_name\tsymbol_name\n");
    for (int i = 0; i < numOfSymbols; i++){
        curSymbolSectionHeader = (Elf32_Shdr*)( s->map_start + s->header->e_shoff);
        symbolName = cur_in_symbolTable->st_name;

        if ((cur_in_symbolTable->st_shndx == 0) || (cur_in_symbolTable->st_shndx == 0xff00) || (cur_in_symbolTable->st_shndx == 0xff1f) || (cur_in_symbolTable->st_shndx == 0xfff1) || (cur_in_symbolTable->st_shndx == 0xfff2) || (cur_in_symbolTable->st_shndx == 0xffff)) {
            printf("[%d]\t%-4X\t%d\t%s\t%s\n", i, cur_in_symbolTable->st_value, cur_in_symbolTable->st_shndx, "" ,(symStringtable + symbolName));
        }
        else {
            sectionHeaderName = (curSymbolSectionHeader + cur_in_symbolTable->st_shndx)->sh_name;
            printf("[%d]\t%-4X\t%d\t%s\t%s\n", i, cur_in_symbolTable->st_value, cur_in_symbolTable->st_shndx, (stringtable + sectionHeaderName) ,(symStringtable + symbolName));
        }
        cur_in_symbolTable++;
    }
}

void relocationTables(state* s) {
    Elf32_Ehdr *header = (Elf32_Ehdr *) s->map_start;
    Elf32_Shdr* relSh = (s->map_start + s->header->e_shoff);
    Elf32_Shdr* dymSymSh = (s->map_start + s->header->e_shoff);
    Elf32_Shdr* sh = (s->map_start + s->header->e_shoff);
    Elf32_Sym* curS;
    Elf32_Sym* SymTbl;
    char* dymSymStringtable;
    int symIndex;
    int sizeOfRelTbl;
    Elf32_Rel* rel;

    char* stringtable = (char*) s->map_start + (sh + header->e_shstrndx)->sh_offset;

    // if (currentfd == NULL){
    //     fprintf( stderr, "no ELF file\n");
    //     exit(-1);
    // }

    // dynamic symbol table:
    for ( int i = 0; i < s->header->e_shnum; i++){
        if(dymSymSh->sh_type == 11){
            dymSymStringtable = (char*) (s->map_start + (sh + dymSymSh->sh_link)->sh_offset);
            break;
        }
        dymSymSh++;
    }

    SymTbl = ( Elf32_Sym* ) (s->map_start + (dymSymSh->sh_offset));

    for( int i = 0; i < header->e_shnum; i++ ){
        if(relSh->sh_type == 9){

            sizeOfRelTbl = relSh->sh_size / sizeof(Elf32_Rel);

            rel = ( Elf32_Rel* ) (s->map_start + (relSh->sh_offset));
            
            printf("Relocation section '%s' at offset 0x%X contains %d entries: \n",(stringtable + relSh->sh_name) ,relSh->sh_offset ,sizeOfRelTbl);
        
            printf("offset\tinfo\ttype\tSym.Value\tSym.Name\n");

            for (int i = 0; i < sizeOfRelTbl; i++){
                printf("%08X\t%08X\t%d\t", rel->r_offset, rel->r_info, ELF32_R_TYPE(rel->r_info));
                symIndex = ELF32_R_SYM(rel->r_info);
                curS = (Elf32_Sym*) SymTbl + symIndex;
                printf("%08X\t%s\n", curS->st_value, (dymSymStringtable + curS->st_name));
                rel++;
            }
        }
        relSh++;
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

    struct fun_desc menu[]= { { "Toggle Debug Mode", toggleDebugMode }, { "Examine ELF File", examineELFFile }, { "Print Section Names", printSectionNames }, { "Print Symbols", printSymbols }, {"Relocation Tables", relocationTables}, { "Quit", quit }, { NULL, NULL } };
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