//Task1 and Task2 Together

#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
    int c = 0;
    int debufFlag = 0;
    int encodeFlag = 0;
    char *enc;
    int encoderPlusMinus = 0;
    int charInPlace = 0;
    int inputFlag = 0;
    FILE *outputFileStream = stdout;
    FILE *inputFileStream = stdin;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-D") == 0) {
            debufFlag = 1;
        }
        else if (strncmp(argv[i], "-e", 2) == 0) {
            enc = argv[i] + 2;
            encodeFlag = 1;
            encoderPlusMinus = -1;
        }
        else if (strncmp(argv[i], "+e", 2) == 0) {
            enc = argv[i] + 2;
            encodeFlag = 1;
            encoderPlusMinus = 1;
        }
        else if (strncmp(argv[i], "-o", 2) == 0) {
            outputFileStream = fopen(argv[i] + 2, "w");
        }
        else if (strncmp(argv[i], "-i", 2) == 0) {
            inputFlag = 1;
            inputFileStream = fopen(argv[i] + 2, "r");
        }
    }

    if (debufFlag > 0) { //Print The Command On Debug Mode
        for (int i = 1; i < argc; i++) {
            fprintf(stderr, "%s", argv[i]);
            if (i < argc - 1) {
                fprintf(stderr, " ");
            }
        }
        fprintf(stderr, "\n");
    }

    while ((c = fgetc(inputFileStream)) != EOF) {
        char originalChar = c;
        if (c == '\n' || c == '0') {
            if (debufFlag > 0) {
                fprintf(stderr, "\n");
            }
            charInPlace = 0;
        }
        else if (encodeFlag != 0) { //Encode Mode
            c = c + (encoderPlusMinus) * (enc[charInPlace] - '0');
            charInPlace++;
            if (enc[charInPlace] == '\0') {
                charInPlace = 0;
            }
        }
        else if (c >= 'a' && c <= 'z') { //Regular Mode - LowerCase To UpperCase
            c = c - 'a' + 'A';
        }
        if (debufFlag != 0 && c != '\n') {
            fprintf(stderr, "%d\t%d\n", originalChar, c);
        }
        fprintf(outputFileStream, "%c", c);
    }
    if (inputFlag != 0) {
        printf("\n");
    }

    return 0;
}