#include <stdio.h>
#include <stdlib.h>
#define MAX_LEN 11			/* maximal input string size */

extern int assFunc(int, int);

int main(int argc, char** argv) {
  char str_buf[MAX_LEN + 1];
	str_buf[0] = 0;
	
	fgets(str_buf, MAX_LEN, stdin);
	int x = atoi(str_buf);
	fgets(str_buf, MAX_LEN, stdin);
	int y = atoi(str_buf);
	
	assFunc(x, y);
	return 0;
}

char c_checkValidity(int x, int y) {
  if (x >= y)
    return 1;
  return 0;
}