#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    FILE* input = fopen(argv[1], "r");

    unsigned char buffer[13];
    while (fread(buffer, 1, 1, input) != 0)
    {
        printf("%02X ", buffer[0]);
    }
    printf("\n");
    fclose(input);
    return 0;
}