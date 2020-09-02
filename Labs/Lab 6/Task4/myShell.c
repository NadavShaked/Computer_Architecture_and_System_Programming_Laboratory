#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>
#include <linux/limits.h>
#include <sys/fcntl.h>
#include "LineParser.h"

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

typedef struct variablesLink {
	char* varName;
	char* varValue;
	struct variablesLink* next;
} variablesLink;

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
	while (cur != NULL)
	{
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

void redirect(cmdLine* pCmdLine) {
	if (pCmdLine->inputRedirect != NULL) {
		close(0);
    	open(pCmdLine->inputRedirect, O_RDONLY);
	}
	if (pCmdLine->outputRedirect != NULL) {
		close(1);
    	open(pCmdLine->outputRedirect, O_WRONLY | O_CREAT, 777);
	}
}

int execute(cmdLine *pCmdLine) {
    int fd[2];
    if(pCmdLine->next != NULL) {
        if(pipe(fd) < 0) {
                perror("Pipe Doesnt Work");
                return -1;
        }
		pid_t child1 = fork();
		if (child1 == -1) {
        	perror("Fork Doesnt Work");
            return child1;
        }
        else if (child1 == 0) {
            if (pCmdLine->inputRedirect != NULL) {
                int inputRedirect = open(pCmdLine->inputRedirect, O_RDONLY);
                dup2(inputRedirect, 0);
                close(inputRedirect);
            }
            dup2(fd[1], 1);
            close(fd[1]);
            if (execvp(pCmdLine->arguments[0], pCmdLine->arguments) < 0) {
                perror("Execute Doesnt Work");
                _exit(1);
            }
        }

        close(fd[1]);
		pid_t child2 = fork();
		if (child2 == -1) {
            perror("Fork Doesnt Work");
            return -1;
        }
        else if (child2 == 0) {   
            dup2(fd[0],0);
            close(fd[0]); 
            if (pCmdLine->next->outputRedirect != NULL) {
                int outputRedirect = open(pCmdLine->next->outputRedirect, O_CREAT | O_WRONLY, 0777);
                dup2(outputRedirect, 1);
                close(outputRedirect);
            }
            if (execvp(pCmdLine->next->arguments[0], pCmdLine->next->arguments) < 0) {
                perror("Execute Doesnt Work");
                _exit(1);
            }
        }
        close(fd[0]);
        waitpid(child1, NULL, 0);
        waitpid(child2, NULL, 0);
		return child2;
    }
    else {
		pid_t child = fork();
		if (child == -1) {
        	perror("couldnt execute the fork");
    	}
		else if (child == 0) {
        	if (pCmdLine->inputRedirect) {
            	int inputRedirect = open(pCmdLine->inputRedirect, O_RDONLY);
            	dup2(inputRedirect, 0);
            	close(inputRedirect);
			}
        	if (pCmdLine->outputRedirect) {
            	int outputRedirect = open(pCmdLine->outputRedirect, O_CREAT | O_WRONLY, 0777);
            	dup2(outputRedirect, 1);
        		close(outputRedirect);
			}
        	if (execvp(pCmdLine->arguments[0], pCmdLine->arguments) < 0) {
            	perror("Execute Doesnt Work");
            	_exit(1);
			}
        }
    	if (pCmdLine->blocking == 1)
        	waitpid(child, NULL, 0);
		
		return child;
	}
    return 0;
}

void printDirectory() {
	char curDir[PATH_MAX];
	getcwd(curDir, 2048);
	fprintf(stdout, "%s$ ", curDir);
}

void addNewVarToVariablesLinkList(variablesLink** variables_list, char* var, char* val) {
	variablesLink* cur = *variables_list;
	while (cur != NULL) {
		if (strcmp(cur->varName, var) == 0) {
			free(cur->varValue);
			cur->varValue = strdup(val);
			return 0;
		}
		cur = cur->next;
	}
	
	variablesLink* link = calloc(1, sizeof(variablesLink));
	link->varName = strdup(var);
	link->varValue = strdup(val);
	link->next = *variables_list;
	*variables_list = link;
}

void printVariablesLinkList(variablesLink** head) {
	variablesLink* cur = *head;
	while (cur != NULL) {
		fprintf(stdout, "Variable Name: %s\tVariable Value: %s\n", cur->varName, cur->varValue);
		cur = cur->next;
	}
}

void freeVariablesLinkList(variablesLink** head) {
	variablesLink* cur = *head;
	while (cur != NULL)  {
		variablesLink* tmp = cur->next;
		free(cur->varName);
		free(cur->varValue);
		free(cur);
		cur = tmp;
	}
	head = NULL;
}

void replaceSetArgsCmdLine(cmdLine* pCmdLine, variablesLink** head) {
	char* val;
	int i = 0;
	while (i < pCmdLine->argCount) {
		if (strncmp(pCmdLine->arguments[i], "$", 1) == 0) {
			variablesLink* cur = *head;
			while (cur != NULL) {
				printf("varname: %s ", cur->varName);
				if ((strcmp(cur->varName, pCmdLine->arguments[i] + 1) == 0)) {
					replaceCmdArg(pCmdLine, i, cur->varValue);
					break;
				}
				cur = cur->next;
			}
		}
		i++;
	}
}

int main(int argc, char **argv) {
	char buffer[BUFFER_LEN];
	int debugFlag = 0;
	process* process_list = NULL;
	variablesLink* variables_list = NULL;

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

		replaceSetArgsCmdLine(pCmdLine, &variables_list);


		if (strcmp(pCmdLine->arguments[0], "quit") == 0) {
			freeProcessList(process_list);
			freeVariablesLinkList(&variables_list);
			freeCmdLines(pCmdLine);
			return 0;
		}
		else if (strcmp(pCmdLine->arguments[0], "set") == 0) {
			addNewVarToVariablesLinkList(&variables_list, pCmdLine->arguments[1], pCmdLine->arguments[2]);
		}
		else if (strcmp(pCmdLine->arguments[0], "vars") == 0) {
			printVariablesLinkList(&variables_list);
		}
		else if (strcmp(pCmdLine->arguments[0], "cd") == 0) {
			char* path = pCmdLine->arguments[1];
			if (strcmp(path, "~") == 0)
				path = getenv("HOME");
			printf(path);
			if (chdir(path) < 0)
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
		else if (strcmp(pCmdLine->arguments[0], "suspend") == 0) {
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