#include <stdlib.h>
#include <stdio.h>
#include <string.h>

typedef struct {
  char debug_mode;
  char file_name[128];
  int unit_size;
  unsigned char mem_buf[10000];
  size_t mem_count;
  int hexadecimal_mode;
} state;

void toggleDebugMode(state* s){
  if(s->debug_mode == 1){
    s->debug_mode = 0;
        fprintf(stderr, "Debug flag now off \n", s->file_name);
  }
  else {
    s->debug_mode = 1;
    fprintf(stderr, "Debug flag now on \n", s->file_name);
  }
}

void setFileName(state* s) {
    fgets(s->file_name, 102, stdin);
    if(s->file_name[strlen(s->file_name) - 1] == '\n')
        s->file_name[strlen(s->file_name) - 1] = 0;
    if(s->debug_mode == 1)
        fprintf(stderr, "Debug: file name set to '%s'\n", s->file_name);
}

void setUnitSize(state* s) {
    char input[3];
    int converted_input  = -1;
    fgets(input, 3, stdin);
    sscanf(input, "%d", &converted_input);
    if (converted_input != 1 && converted_input != 2 && converted_input != 4) {
        fprintf(stderr, "Illegal size\n", s->file_name);
        return;
    }
    s->unit_size = converted_input;
    if (s->debug_mode == 1)
        fprintf(stderr, "Debug: set size to %d \n", s->file_name);
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
}

void printStateStatus(state* s) {
    fprintf(stderr, "Unit Size:\t%d\nFile Name:\t%s\nMemory Count:\t%d\n", s->unit_size, s->file_name, s->mem_count);
}

int main(int argc, char **argv){
    int base_len = 5;
    char userInput[11];

    struct fun_desc menu[]= { { "Toggle Debug Mode", toggleDebugMode }, { "Set File Name", setFileName }, { "Set Unit Size", setUnitSize }, { "Quit", quit }, { NULL, NULL } };
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