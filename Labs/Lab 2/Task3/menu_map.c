#include <stdlib.h>
#include <stdio.h>
#include <string.h>
 
char censor(char c) {
  if(c == '!')
    return '.';
  else
    return c;
}
 
char* map(char *array, int array_length, char (*f) (char)){
    char* mapped_array = (char*)(malloc(array_length*sizeof(char)));
    for (int i = 0; i < array_length; i++)
    {
        mapped_array[i] = f(array[i]);
    }
    return mapped_array;
}

/* Gets a char c and returns its encrypted form by adding 3 to its value.
If c is not between 0x20 and 0x7E it is returned unchanged */
char encrypt(char c){   
    if (c >= 0x20 && c <= 0x7E)
        return c + 3;
    return c;
} 

/* Gets a char c and returns its decrypted form by reducing 3 to its value.
If c is not between 0x20 and 0x7E it is returned unchanged */
char decrypt(char c){
    if (c >= 0x20 && c <= 0x7E)
        return c - 3;
    return c;
}

/* dprt prints the value of c in a decimal representation followed by a
new line, and returns c unchanged. */
char dprt(char c){  
    printf("%d\n", c);
    return c;
}

/* If c is a number between 0x20 and 0x7E, cprt prints the character of ASCII value c followed 
by a new line. Otherwise, cprt prints the dot ('.') character. After printing, cprt returns the value of c unchanged. */
char cprt(char c) {
    if (c >= 0x20 && c <= 0x7E)
        printf("%c\n", c);
    else
        printf("%c\n", '.');
    return c;
}

/* Ignores c, reads and returns a character from stdin using fgetc. */
char my_get(char c){
    return fgetc(stdin);
}

/* Gets a char c,  and if the char is 'q' , ends the program with exit code 0. Otherwise returns c. */
char quit(char c){
    if (c == 'q')
        exit(0);
    return c;
}

struct fun_desc {
  char *name;
  char (*fun)(char);
};

int main(int argc, char **argv){
    int base_len = 5;
    char* carray = (char*)(calloc(base_len, sizeof(char)));
    char userInput[11];

    struct fun_desc menu[]= { { "Censor", censor }, { "Encrypt", encrypt }, { "Decrypt", decrypt }, { "Print dec", dprt },
                                 { "Print string", cprt }, { "Get string", my_get}, { "Quit", quit }, { NULL, NULL } };
    int menuLen = (sizeof(menu) / sizeof(menu[0])) - 1;
    printf("menu\n");
    while (1)
    {
        printf("Please choose a function:\n");
        for (int i = 0; i < menuLen; i++) {
            printf("%d) %s\n", i, menu[i].name);
        }
        printf("Option: ");
        fgets(userInput, 10, stdin);
        int i = atoi(userInput);

        if (i >= 0 && i < menuLen)
        {
            printf("Within bounds\n");
            carray = map(carray, base_len, menu[i].fun);
            printf("DONE.\n\n");
        }
        else
        {
            printf("Not within bounds\n");
            free(carray);
            quit('q');
        }
    }
}