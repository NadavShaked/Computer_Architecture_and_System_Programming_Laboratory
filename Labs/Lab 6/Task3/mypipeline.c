#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>

int main(int argc, char **argv) {
    int debugFlag = 0;
	int fd[2];
	pid_t pId1;
    pid_t pId2;

	int i = 0;
	while (i < argc) { /* Check Modes */
    	if (strcmp(argv[i], "-d") == 0)
    		debugFlag = 1;
		i++;
	}

	if (pipe(fd) < 0)  {
		perror("Pipe Doesnt work");
		return 0;
	}
	
    if (debugFlag == 1)
        fprintf(stderr, "parent_process>forking...\n");
	pId1 = fork();
    if (debugFlag == 1)
        fprintf(stderr, "parent_process>create process with id: %d\n", pId1);
	if (pId1 < 0) {
		perror("Fork Doesnt work");
		return 0;
	}
	else if (pId1 == 0) {
        if (debugFlag == 1)
            fprintf(stderr, "child1>redirecting stdout to the write end of the pipe...\n");
		close(1);
        int fdDup1 = dup(fd[1]);
        close(fd[1]);
        char* args[] = {"ls", "-l", NULL};
        if (debugFlag == 1)
            fprintf(stderr, "child1>going to execute cmd: %s...\n", args[0]);
        execvp(args[0], args);
		return 0;
	}

    if (debugFlag == 1)
        fprintf(stderr, "parent_process>closing the write end of the pipe...\n");
	close(fd[1]);
    pId2 = fork();
    if (pId2 < 0) {
		perror("Fork Doesnt work");
		return 0;
	}
	else if (pId2 == 0) {
        if (debugFlag == 1)
            fprintf(stderr, "child2>redirecting stdout to the write end of the pipe...\n");
        close(0);
        int fdDup2 = dup(fd[0]);
        close(fd[0]);
        char* args[] = {"tail", "-n", "2", NULL};
        if (debugFlag == 1)
            fprintf(stderr, "child2>going to execute cmd: %s...\n", args[0]);
        execvp(args[0], args);
        return 0;
    }
    if (debugFlag == 1)
        fprintf(stderr, "parent_process>closing the read end of the pipe...\n");
	close(fd[0]);
    
    if (debugFlag == 1)
        fprintf(stderr, "parent_process>waiting for child processes to terminate...\n");
	waitpid(pId1, NULL, 0);
	waitpid(pId2, NULL, 0);

    if (debugFlag == 1)
        fprintf(stderr, "parent_process>exiting...\n");
	return 0;
}