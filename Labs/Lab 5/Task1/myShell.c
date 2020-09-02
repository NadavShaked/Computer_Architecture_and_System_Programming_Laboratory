#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include "LineParser.h"
#include <linux/limits.h>

#define BUFFER_LEN 2048

void execute(cmdLine* pCmdLine) {
	int wstatus;

	if (strcmp(pCmdLine->arguments[0], "cd") == 0) {
		if (chdir(pCmdLine->arguments[1]) < 0)
			fprintf(stderr, "cd %s Operation Failed", pCmdLine->arguments[1]);
	}
	else {
		int pId = fork();
		if (pId == -1) {
			perror("Fork Doesnt Work");
		}
		else if (pId == 0) {
			if (execvp(pCmdLine->arguments[0], pCmdLine->arguments) < 0) {
				perror("Execute Doesnt Work");
				_exit(1);
			}
		}
		else if (pCmdLine->blocking == 1)
			waitpid(pId, &wstatus, 0);
	}
}

void printDirectory() {
	char curDir[PATH_MAX];
	getcwd(curDir, 2048);
	fprintf(stdout, "%s$ ", curDir);
	memset(curDir, 0, sizeof(curDir)); /* empty char array */
}

int main(int argc, char **argv){
	char buffer[BUFFER_LEN];
	int debugFlag = 0;

	int i = 0;
	while (i < argc) { /* Check Modes */
    	if (strcmp(argv[i], "-d") == 0)
    		debugFlag = 1;
		i++;
	}

	while(1) {
		printDirectory();
		fgets(buffer, BUFFER_LEN, stdin);
		cmdLine* pCmdLine = parseCmdLines(buffer);
		if(debugFlag == 1) {
			fprintf(stderr, "Proccess ID: %d\nExecuting Command: %s\n", getpid(), pCmdLine->arguments[0]);
		}

		if (strcmp(pCmdLine->arguments[0], "quit") == 0)
			return 0;
		
		execute(pCmdLine);
		freeCmdLines(pCmdLine);
	}

	return 0;
}