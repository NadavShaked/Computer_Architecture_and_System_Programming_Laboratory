#include "util.h"

#define SYS_EXIT 1
#define SYS_READ 3
#define SYS_WRITE 4
#define SYS_OPEN 5
#define SYS_CLOSE 6
#define SYS_LSEEK 19
#define SEEK_SET 0
#define STDIN 0
#define STDOUT 1
#define STDERR 2
#define O_RDONLY 0
#define O_WRONLY 1
#define O_RDRW 2
#define O_CREATE 64

extern int system_call(int,...);

void printToStdFile(int std, char* str) {
  system_call(SYS_WRITE, std, str, strlen(str));
}

void debugPrint(int systemCall, int ret) {
    system_call(SYS_WRITE, STDERR,"SYSTEM_CALL:\n", 13);
    system_call(SYS_WRITE, STDERR,"id: ", 4);
    system_call(SYS_WRITE, STDERR, itoa(systemCall), strlen(itoa(systemCall)));
    system_call(SYS_WRITE, STDERR,"\nreturn code: ", 14);
    system_call(SYS_WRITE, STDERR, itoa(ret), strlen(itoa(ret)));
    system_call(SYS_WRITE, STDERR, "\n", 1);
}

int main (int argc , char* argv[], char* envp[]) {
  int debugFlag = 0;
  int inputFile = STDIN;
  int outputFile = STDOUT;

  char c[2];
  c[1] = '\0';

  int i = 0;
  while (i < argc) { /* Check Modes */
    if (strcmp(argv[i], "-D") == 0)
      debugFlag = 1;
    else if (strncmp(argv[i], "-i", 2) == 0)
      inputFile = system_call(SYS_OPEN, argv[i] + 2, O_RDONLY, 0777);
    else if (strncmp(argv[i], "-o", 2) == 0)
      outputFile = system_call(SYS_OPEN, argv[i] + 2, O_CREATE | O_WRONLY, 0644);
    if (inputFile < 0 || outputFile < 0)
    {
      printToStdFile(STDOUT, "Error opening file..");
      system_call(SYS_EXIT, 0x55);
    }
    i++;
  }

  int isNotEOF = system_call(SYS_READ, inputFile, c, 1);
  if (debugFlag == 1)
    debugPrint(SYS_READ, isNotEOF);
  while (isNotEOF > 0)
  {
    char editedC[2];
    editedC[0] = c[0];
    editedC[1] = '\0';

    if (c[0] == 'q') { /* DELETE */
      if (inputFile != STDIN) {
        int ret = system_call(SYS_CLOSE, inputFile);
        if (debugFlag == 1)
          debugPrint(SYS_CLOSE, ret);
      }
      if (inputFile != STDOUT) {
        int ret = system_call(SYS_CLOSE, outputFile);
        if (debugFlag == 1)
          debugPrint(SYS_CLOSE, ret);
      }
      return 0;
    }
    
    if ('a' <= c[0] &&  c[0] <= 'z')
      editedC[0] = c[0] - 'a' + 'A';
    
    printToStdFile(outputFile, editedC);
    
    isNotEOF = system_call(SYS_READ, inputFile, c, 1);
    if (debugFlag == 1)
      debugPrint(SYS_READ, isNotEOF);
  }
  
  if (inputFile != STDIN) {
    int ret = system_call(SYS_CLOSE, inputFile);
    if (debugFlag == 1)
      debugPrint(SYS_CLOSE, ret);
  }
  if (inputFile != STDOUT) {
    int ret = system_call(SYS_CLOSE, outputFile);
    if (debugFlag == 1)
      debugPrint(SYS_CLOSE, ret);
  }
  
  return 0;
}