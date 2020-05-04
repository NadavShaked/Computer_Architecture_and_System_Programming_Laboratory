#include "util.h"

#define SYS_EXIT 1
#define SYS_READ 3
#define SYS_WRITE 4
#define SYS_OPEN 5
#define SYS_CLOSE 6
#define SYS_LSEEK 19
#define SYS_GETDENTS 141
#define SEEK_SET 0
#define STDIN 0
#define STDOUT 1
#define STDERR 2
#define O_RDONLY 0
#define O_WRONLY 1
#define O_RDRW 2
#define O_CREATE 64
#define BUFFER_SIZE 8192

extern int system_call(int,...);
extern void infection();
extern void infector(char* file_name);
extern void code_start();
extern void code_end();

typedef struct ent {
    int inode;
    int offset;
    short len;
    char buf[1];
} ent;

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
  int prefixIndex = 0;
  int infectedIndex = 0;
  char buffer[BUFFER_SIZE];

  int i = 0;
  while (i < argc) { /* Check Modes */
    if (strcmp(argv[i], "-D") == 0)
      debugFlag = 1;
    else if (strncmp(argv[i], "-p", 2) == 0)
      prefixIndex = i;
    else if (strncmp(argv[i], "-a", 2) == 0) {
      infectedIndex = i;
      system_call(SYS_WRITE, STDOUT, itoa(&code_start), strlen(itoa(&code_start)));
      system_call(SYS_WRITE, STDOUT, "\n", 1);
      system_call(SYS_WRITE, STDOUT, itoa(&code_end), strlen(itoa(&code_end)));
      system_call(SYS_WRITE, STDOUT, "\n", 1);
    }
    i++;
  }

  int fileDesc = system_call(SYS_OPEN, ".", O_RDONLY, 0777);
  if (debugFlag == 1)
      debugPrint(SYS_OPEN, fileDesc);
  if (fileDesc < 0) {
    printToStdFile(STDOUT, "Error opening file..");
    system_call(SYS_EXIT, 0x55);
    return 0;
  }
  
  int wirtenBytes = system_call(SYS_GETDENTS, fileDesc, buffer, BUFFER_SIZE);
  if (debugFlag == 1)
      debugPrint(SYS_GETDENTS, wirtenBytes);

  i = 0;
  while (i < wirtenBytes) {
    struct ent* entity = (struct ent *)(buffer + i);
    if (prefixIndex > 0) {
      if (strncmp(entity->buf, argv[prefixIndex] + 2, strlen(argv[prefixIndex] + 2)) == 0) {
        char* type = buffer + i + entity->len - 1; /* pointer to file type*/
        printToStdFile(STDOUT, entity->buf);
        printToStdFile(STDOUT, "\t\t");
        printToStdFile(STDOUT, itoa(*type));
        printToStdFile(STDOUT, "\n");
        if (debugFlag == 1)
          debugPrint(SYS_WRITE, 1);
      }
    } else if (infectedIndex > 0) {
        if (strncmp(entity->buf, argv[infectedIndex] + 2, strlen(argv[infectedIndex] + 2)) == 0)  {
          infector(entity->buf);
          char* type = buffer + i + entity->len - 1; /* pointer to file type*/
          printToStdFile(STDOUT, entity->buf);
          printToStdFile(STDOUT, "\t\t");
          printToStdFile(STDOUT, itoa(*type));
          printToStdFile(STDOUT, "\n");
          if (debugFlag == 1)
            debugPrint(SYS_WRITE, 1);
        }
    }
    else {
      char* type = buffer + i + entity->len - 1;  /* pointer to file type*/
      printToStdFile(STDOUT, entity->buf);
      printToStdFile(STDOUT, "\t\t");
      printToStdFile(STDOUT, itoa(*type));
      printToStdFile(STDOUT, "\n");
      if (debugFlag == 1)
        debugPrint(SYS_WRITE, 1);
    }
    i += entity->len;
  }

  return 0;
}