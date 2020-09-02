#include <stdlib.h>
#include <stdio.h>
#include <string.h>

typedef struct {
  char debug_mode;
  char file_name[128];
  int unit_size;
  unsigned char mem_buf[10000];
  size_t mem_count;
  int display_mode;
} state;

void toggleDebugMode(state* s){
    if(s->debug_mode == 1){
        s->debug_mode = 0;
        fprintf(stderr, "Debug flag now off\n");
    }
    else {
        s->debug_mode = 1;
        fprintf(stderr, "Debug flag now on\n");
    }
}

void setFileName(state* s) {
    fgets(s->file_name, 130, stdin);
    if(s->file_name[strlen(s->file_name) - 1] == '\n')
        s->file_name[strlen(s->file_name) - 1] = 0;
    if(s->debug_mode == 1)
        fprintf(stderr, "Debug: file name set to '%s'\n", s->file_name);
}

void setUnitSize(state* s) {
    char input[100];
    int converted_input  = -1;
    fgets(input, 100, stdin);
    sscanf(input, "%d", &converted_input);
    if (converted_input != 1 && converted_input != 2 && converted_input != 4) {
        fprintf(stderr, "Illegal size\n");
        return;
    }
    s->unit_size = converted_input;
    if (s->debug_mode == 1) {
        if (s->display_mode == 0)
            fprintf(stderr, "Debug: set size to %d\n", s->unit_size);
        else
            fprintf(stderr, "Debug: set size to %X\n", s->unit_size);
    }
}

void loadIntoMemory(state* s) {
    char input[100];
    int length = 0;
    int location = 0;
    FILE* read_file = 0;

    if (s->file_name == NULL) {
        printf("Error:\tFile name doesn't set\n");
        return;
    }
    read_file = fopen(s->file_name, "r+");

    perror("open: ");


    if (read_file == 0) {
        printf("Error:\tCouldn't open the file\n");
        return;
    }
    printf("Please enter <location> <length>\n");
    fgets(input, 100, stdin);
    sscanf(input,"%X %d", &location, &length);
    fseek(read_file, location, SEEK_SET);
    if(s->debug_mode == 1) {
        if (s->display_mode == 0)
            fprintf(stderr, "File Name:\t%s\nFile Location:\t%d\nFile Length:\t%d\n", s->file_name, location, length);
        else
            fprintf(stderr, "File Name:\t%s\nFile Location:\t%X\nFile Length:\t%X\n", s->file_name, location, length);
    }
    s->mem_count = fread(s->mem_buf, s->unit_size, length,read_file);


    perror("read: ");


    printf("Loaded %d units into memory\n", length);
    fclose(read_file);
}

void toggleDisplayMode(state* s) {
    if (s->display_mode == 0) {
        s->display_mode = 1;
        printf("Display flag now on, hexadecimal representation\n");
    }
    else {
        s->display_mode == 0;
        printf("Display flag now off, decimal representation\n");
    }
}

void memoryDisplay(state* s) {
    char* hexa_formats[] = {"%#hhx\n", "%#hx\n", "No such unit", "%#x\n"};
    char* decimal_formats[] = {"%#hhd\n", "%#hd\n", "No such unit", "%#d\n"};
    char input[100];
    int u = 0;
    int addr = 0;
    char* buf;

    if (s->display_mode == 0) {
        printf("Decimal\n===========\n");
        /*setted_formats = decimal_formats;*/
    }
    else {
        printf("Hexadecimal\n===========\n");
        /*setted_formats = hexa_formats;*/
    }

    fgets(input, 100, stdin);
    sscanf(input, "%d", &u);
    fgets(input, 100, stdin);
    sscanf(input, "%X", &addr);

    if (addr == 0)
        buf = s->mem_buf + addr;
    else
        buf = (unsigned char*)addr;

    int i = 0;
    if (s->display_mode == 0) {
        while (i < u * s->unit_size) {
            int var = *((int*) (buf + i));
            printf(decimal_formats[s->unit_size - 1],var);
            i += s->unit_size;
        }
    }
    else {
        while (i < u * s->unit_size) {
            int var = *((int*) (buf + i));
            printf(hexa_formats[s->unit_size - 1],var);
            i += s->unit_size;
        }
    }
}


void saveIntoFile(state* state) {
    FILE* write;
    char input [100];
    int sourceadd;
    int target;
    int length;
    unsigned char* towrite=state->mem_buf;

    write = fopen(state->file_name,"r+");
  
    if (write == NULL) {
        printf("Error:\tCouldn't open the file\n");
        return;
    }
  printf("Please enter <source-address> <target-location> <length>\n");
  fgets(input,100,stdin);
  sscanf(input,"%X %X %d",&sourceadd,&target,&length);
  fseek(write,0,SEEK_END);
  if(ftell(write)<target)
  {
    fprintf(stderr,"destination is outside of file");
    exit(1);
  }
  fseek(write,target,SEEK_SET);
  if(sourceadd!=0)
    towrite=(unsigned char*)sourceadd;
  fwrite(towrite,state->unit_size,length,write);
  fclose(write);
}


void saveIntoFile1(state* s) {
    printf("Please enter <source-address> <target-location> <length>\n");
    int source_address;
    int target_location;
    int length;
    char input[100];
    fgets(input, 100, stdin);
    sscanf(input, "%X %X %d", &source_address, &target_location, &length);

    FILE *file = fopen(s->file_name, "r+");

    if(file == NULL){
        printf("Error:\tCouldn't open the file\n");
        return;
    }
    fseek(file, target_location, SEEK_SET);

    perror("seek: ");


    int written_units = fwrite((unsigned char*) s->mem_buf + source_address, s->unit_size, length, file);


    perror("write: ");


    if(s->debug_mode){
        if(written_units < length){
            if(s->display_mode == 1) printf("Error: only %x elements were written to file.. \n", written_units);
            else printf("Error: only %x elements were written to file.. \n", written_units);
        }
        else printf("Success: all units were written to file.. \n");
    }

    fclose(file);
}

void memoryModify(state* s) {
    int location = 0;
    int val = 0;
    char input[100];
    printf("Please enter <location> <val>\n");
    fgets(input, 100, stdin);
    sscanf(input, "%X %X", &location, &val);

    if(s->debug_mode == 1)
        printf("Value:\t%X, Loaction:\t%X, state unit size:ֿ\t%d\n", val, location, s->unit_size);

    memcpy(&s->mem_buf[location], &val, s->unit_size);
}

void quit(state *s){
    if(s->debug_mode)
        printf("quitting..\n");
    exit(0);
}

struct fun_desc {
    char* name;
    void (*fun)(state*);
};

void initializeState(state* s) {
    s->debug_mode = 0;
    s->unit_size = 1;
    s->mem_count = 0;
    s->display_mode = 0;
}

void printStateStatus(state* s) {
    if (s->display_mode == 0)
        fprintf(stderr, "\nUnit Size:\t%d\nFile Name:\t%s\nMemory Count:\t%ld\n\n", s->unit_size, s->file_name, s->mem_count);
    else
        fprintf(stderr, "\nUnit Size:\t%X\nFile Name:\t%s\nMemory Count:\t%lX\n\n", s->unit_size, s->file_name, s->mem_count);
}

int main(int argc, char **argv){
    int base_len = 5;
    char userInput[11];

    struct fun_desc menu[]= { { "Toggle Debug Mode", toggleDebugMode }, { "Set File Name", setFileName }, { "Set Unit Size", setUnitSize }, { "Load Into Memory", loadIntoMemory },
                                { "Toggle Display Mode", toggleDisplayMode }, { "Memory Display", memoryDisplay }, { "Save Into File", saveIntoFile }, { "Memory Modify", memoryModify }, { "Quit", quit }, { NULL, NULL } };
    int menuLen = (sizeof(menu) / sizeof(menu[0])) - 1;
    state s;
    initializeState(&s);
    printf("menu\n");
    while (1) {
        if(s.debug_mode == 1)
            printStateStatus(&s);
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