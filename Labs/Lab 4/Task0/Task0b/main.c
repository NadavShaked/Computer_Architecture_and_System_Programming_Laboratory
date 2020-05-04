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
  int fileDesc = system_call(SYS_OPEN, "greeting", O_RDRW, 0777);
  system_call(SYS_LSEEK, fileDesc, 0x291, SEEK_SET);
  system_call(SYS_WRITE, fileDesc, "Mira.\n\0", 7);
  system_call(SYS_CLOSE, fileDesc);

  return 0;
}