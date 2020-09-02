#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>

int main(int argc, char **argv) {
	int fd[2];
	char buf[10];

	pid_t pId;
	if (pipe(fd) < 0)  {
		perror("Pipe Doesnt work");
		return 0;
	}
	
	pId = fork();
	if (pId < 0) {
		perror("Fork Doesnt work");
		return 0;
	}
	else if (pId == 0) {
		close(fd[0]);
		write(fd[1], "hello\n", 7);
		return 0;
	}
	
	close(fd[1]);
	read(fd[0], buf, 7);
	printf(buf);

	return 0;
}