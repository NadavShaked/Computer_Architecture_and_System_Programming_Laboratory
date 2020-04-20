#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// ----------------- START OF VIRUS TYPE ---------------- //
typedef struct virus {
    unsigned short SigSize;
    char virusName[16];
    unsigned char* sig;
} virus;

virus* readVirus(FILE* virusFile) {
    virus* virus = malloc(sizeof(*virus));
    virus->sig = NULL;
	if (fread(virus, 1, 18, virusFile) > 0) {
        virus->sig = malloc(virus->SigSize);
        fread(virus->sig, 1, virus->SigSize, virusFile);
        return virus;
    }
    free(virus);
    return NULL;
}

void printVirus(virus* virus, FILE* output) {
    fprintf(output, "Virus Name: %s\n", virus->virusName);
    fprintf(output, "Virus Size: %d\n", virus->SigSize);
    fprintf(output, "Signature:\n");
    for (int i = 0; i < virus->SigSize; i++)
    {
        fprintf(output, "%02X ", virus->sig[i]);
    }
    fprintf(output, "\n\n");
}

void virus_free(virus* virus) {
    free(virus->sig);
    free(virus);
}
// ------------------ END OF VIRUS TYPE ----------------- //

// -------------- START OF VIRUS_LINK TYPE -------------- //
typedef struct link link;

struct link {
    link *nextVirus;
    virus *vir;
};

void list_print(link*  virusList, FILE* output) {
    if (virusList->nextVirus != NULL)
        list_print(virusList->nextVirus, output);
    printVirus(virusList->vir, output);
}

link* list_append(link* virusList, virus* data) {
    link* head = malloc(sizeof(link));
    head->vir = data;
    head->nextVirus = virusList;
    return head;
}

void list_free(link* virusList) {
    if (virusList->nextVirus != NULL)
        list_free(virusList->nextVirus);
    virus_free(virusList->vir);
    free(virusList);
}

void detect_virus(char *buffer, unsigned int size, link *virus_list) {
    for (int i = 0; i < size; i++) {
        link* curVirus = virus_list;
        while (curVirus != NULL) {
            if (i + curVirus->vir->SigSize < size) {
                if (memcmp(buffer + i, curVirus->vir->sig, curVirus->vir->SigSize) == 0) {
                fprintf(stdout, "Starting Byte Location: %d\nVirus Name: %s\nVirus Signature Size: %d\n", i, curVirus->vir->virusName, curVirus->vir->SigSize);
                }
            }  
            curVirus  = curVirus ->nextVirus;
        }
    }
}
// --------------- END OF VIRUS_LINK TYPE --------------- //

void kill_virus(char *fileName, int signitureOffset, int signitureSize) {
    FILE* detectedFile = fopen(fileName, "r+");
    fseek(detectedFile, signitureOffset, SEEK_SET);
    char fixBytes[signitureSize];
    for(int i = 0; i < signitureSize; i++)
        fixBytes[i] = 0x90;
    fwrite(fixBytes, 1, signitureSize, detectedFile);
    fclose(detectedFile);
}

struct fun_desc {
  char *name;
  link* (*fun)(link*, char*);
};

link* loadSignatures(link* virusList, char* fileName) {
    /*
    if (virusList != NULL) // delete the current virus list
        list_free(virusList);
    */
    virus* virus;
    char source[100];
    printf("Inset Input File Path: ");
    fgets(source, 100, stdin);
    if (source[strlen(source)-1] == '\n')
        source[strlen(source)-1] = 0; // remove the \n from the input
    FILE* inputFile = fopen(source, "r");
    virus = readVirus(inputFile);
    while (virus != NULL) {
        virusList = list_append(virusList, virus);
        virus = readVirus(inputFile); // get the next virus
    }
    fclose(inputFile);
    return virusList;
}

link* printSignatures(link* virusList, char* fileName) {
    if (virusList != NULL) {
        char source[100];
        printf("Inset Output File Path: ");
        fgets(source, 100, stdin);
        source[strlen(source)-1] = 0; // remove the \n from the input
        FILE* outputFile = fopen(source, "w");
        list_print(virusList, outputFile); // change to source
        fclose(outputFile);
    }
    return virusList;
}

link* virusDetector(link* virusList, char* fileName) {
    if (virusList != NULL) {
        char buffer[10000];
        FILE* detectedFile = fopen(fileName, "r");
        unsigned int bufferSize = fread(buffer, 1, 10000, detectedFile);
        detect_virus(buffer, bufferSize, virusList);
        fclose(detectedFile);
    }
    return virusList;
}

link* quit(link* virusList, char* fileName) {
    if (virusList != NULL)
            list_free(virusList);
    exit(0);
}

link* fixFile(link* virusList, char* fileName) {
    char buffer[6];
    printf("Start Location: ");
    fgets(buffer, 10, stdin);
    if (buffer[strlen(buffer)-1] == '\n')
        buffer[strlen(buffer)-1] = 0; // remove the \n from the input
    int signitureOffset = atoi(buffer);
    printf("Virus Signature Size: ");
    fgets(buffer, 10, stdin);
    if (buffer[strlen(buffer)-1] == '\n')
        buffer[strlen(buffer)-1] = 0; // remove the \n from the input
    int signitureSize = atoi(buffer);
    kill_virus(fileName, signitureOffset, signitureSize);

    return virusList;
}

int main(int argc, char **argv) {
    char userInput[11];
    link* virusList = NULL;
    
    struct fun_desc menu[]= { { "Load signatures", loadSignatures }, { "Print signatures", printSignatures },  { "Detect viruses", virusDetector}, { "Fix file", fixFile}, { "Quit", quit }, { NULL, NULL } };
    int menuLen = (sizeof(menu) / sizeof(menu[0])) - 1;
    printf("menu\n");
    while (1) {
        for (int i = 0; i < menuLen; i++) 
            printf("%d) %s\n", i + 1, menu[i].name);
        printf("Please choose a function: ");
        fgets(userInput, 10, stdin);
        int choosen = atoi(userInput) - 1;
        if (choosen < 0 || choosen >= menuLen)
            quit(virusList, argv[1]);
        virusList = menu[choosen].fun(virusList, argv[1]);
        printf("\n");
    }
    return 0;
}