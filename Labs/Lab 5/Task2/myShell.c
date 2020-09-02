#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>
#include "LineParser.h"
#include <linux/limits.h>

#define BUFFER_LEN 2048
#define TERMINATED  -1
#define RUNNING 1
#define SUSPENDED 0

typedef struct process {
    cmdLine* cmd;                     /* the parsed command line*/
    pid_t pid; 		                  /* the process id that is running the command*/
    int status;                       /* status of the process: RUNNING/SUSPENDED/TERMINATED */
    struct process *next;	          /* next process in chain */
} process;

char* getStatus(int status) {
	if (status == TERMINATED)
		return "TERMINATED";
	else if (status == SUSPENDED)
		return "SUSPENDED";
	else if (status == RUNNING)
		return "RUNNING";
	return "";
}

void addProcess(process** process_list, cmdLine* cmd, pid_t pid) {
	process* prcs = (process*) calloc(1, sizeof(process));
	prcs->cmd = strdup(cmd->arguments[0]);
	prcs->pid = pid;
	prcs->status = RUNNING;
	prcs->next = *process_list;
	*process_list = prcs;
}

void removeTerminatedProcessesFromList(process** process_list) {
	process* cur = *process_list;
	while (cur != NULL && cur->status == TERMINATED) {
		process* tmp = cur->next;
		free(cur->cmd);
		free(cur);
		cur = tmp;
	}
	*process_list = cur;

	if (cur != NULL) {
		process* prev = cur;

		cur  = cur->next;
		while (cur != NULL) {
			process* tmp = cur->next;
			if (cur->status == TERMINATED) {
				free(cur->cmd);
				free(cur);
				prev->next = tmp;
			}
			cur = tmp;
		}
	}
}

void updateProcessList(process** process_list) {
	process* cur = *process_list;
	while (cur != NULL) {
		int  wStatus;
		int val =  waitpid(cur->pid, &wStatus, WNOHANG | WUNTRACED | 8); /*WCONTINUED*/
		if (val == -1)
			cur->status = TERMINATED;
		else if (val != 0) {
			if (WIFEXITED(wStatus) || WIFSIGNALED(wStatus))
				cur->status = TERMINATED;
			else if (WIFSTOPPED(wStatus))
				cur->status = SUSPENDED;
			/*
			else if (WIFCONTINUED(wStatus))
				cur->status = RUNNING;
			*/
		}
		cur = cur->next;
	}
}

void printList(process* process_list) {
	if (process_list != NULL) {
		fprintf(stdout, "%d\t%s\t%s\n", process_list->pid, process_list->cmd, getStatus(process_list->status));
		printList(process_list->next);
	}
}

void printProcessList(process** process_list) {
	updateProcessList(process_list);
	fprintf(stdout, "PID\tCommand\tSTATUS\n");
	if (*process_list != NULL)
		printList(*process_list);
	removeTerminatedProcessesFromList(process_list);
}

void freeProcessList(process* process_list) {
	process* cur = process_list;
	while (cur != NULL) {
		process* tmp = cur->next;
		free(cur->cmd);
		free(cur);
		cur = tmp;
	}
}

void updateProcessStatus(process* process_list, int pid, int status) {
	process* cur = process_list;
	while (cur != NULL) {
		if (cur->pid == pid)
			cur->status = status;
		cur = cur->next;
	}
}

int execute(cmdLine* pCmdLine) {
	int pId = getpid();

	pId = fork();
	if (pId == -1) {
		perror("Fork Doesnt Work");
	}
	else if (pId == 0) {
		if (execvp(pCmdLine->arguments[0], pCmdLine->arguments) < 0) {
			perror("Execute Doesnt Work");
			_exit(1);
		}
	}
	else if (pCmdLine->blocking == 1) {
		waitpid(pId, NULL, WUNTRACED);
	}
	return pId;
}

void printDirectory() {
	char curDir[PATH_MAX];
	getcwd(curDir, 2048);
	fprintf(stdout, "%s$ ", curDir);
}

int main(int argc, char **argv) {
	char buffer[BUFFER_LEN];
	int debugFlag = 0;
	process* process_list = NULL;

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

		if(pCmdLine == NULL)
			continue;
		
		if (strcmp(pCmdLine->arguments[0], "quit") == 0) {
			freeProcessList(process_list);
			freeCmdLines(pCmdLine);
			return 0;
		}
		else if (strcmp(pCmdLine->arguments[0], "cd") == 0) {
			if (chdir(pCmdLine->arguments[1]) < 0)
			fprintf(stderr, "cd %s Operation Failed", pCmdLine->arguments[1]);
		}
		else if (strcmp(pCmdLine->arguments[0], "procs") == 0)
			printProcessList(&process_list);
		else if (strcmp(pCmdLine->arguments[0], "kill") == 0) /*new code*/
		{
			if (kill(atoi(pCmdLine->arguments[1]), SIGINT) == -1) /*SIGINT*/
				perror("Error Occurred");
			else
				updateProcessStatus(process_list, atoi(pCmdLine->arguments[1]), TERMINATED);
		}
		else if (strcmp(pCmdLine->arguments[0], "wake") == 0)
		{
			if (kill(atoi(pCmdLine->arguments[1]), SIGCONT) == -1) /*SIGCONT*/
				perror("Error Occurred");
			else
				updateProcessStatus(process_list, atoi(pCmdLine->arguments[1]), RUNNING);
		}
		else if (strcmp(pCmdLine->arguments[0], "suspend") == 0)
		{
			if (kill(atoi(pCmdLine->arguments[1]), SIGTSTP) == -1) /*SIGTSTP*/
				perror("Error Occurred");
			else
				updateProcessStatus(process_list, atoi(pCmdLine->arguments[1]), SUSPENDED);
		}/*end new code*/
		else {
			int pId = execute(pCmdLine);
			addProcess(&process_list, pCmdLine, pId);
		}
		freeCmdLines(pCmdLine);
	}

	return 0;
}