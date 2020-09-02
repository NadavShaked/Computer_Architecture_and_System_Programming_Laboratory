#include "util.h"

#define SYS_WRITE 4
#define SYS_OPEN 5
#define SYS_CLOSE 6
#define SYS_LSEEK 19
#define SEEK_SET 0
#define STDOUT 1
#define O_RDRW 2

int main (int argc , char* argv[], char* envp[])
{
    fork();
    fork();
    putc(c++, stdout);
  return 0;
}