#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <signal.h>

void redText(){
  	printf("\033[1;31m");
}

void handle_sigint(int sig){
	redText();
    printf("Process number %d cought signal SIGINT: %d",getpid(), sig);
    printf("\033[0m");
	printf("\n");
	_exit(1);
}

void handle_sigcont(int sig){
	redText();
    printf("Process number %d cought signal SIGCONT: %d",getpid(), sig);
	printf("\033[0m");
	printf("\n");	
} 
void handle_sigtstp(int sig){
	redText();
    printf("Process number %d cought signal SIGTSTP: %d", getpid(), sig);
	printf("\033[0m");
	printf("\n");	
}



int main(int argc, char **argv){ 
	redText();
	printf("Process number %d is starting to run...", getpid());
	printf("\033[0m");
	printf("\n");	
	signal(SIGINT, handle_sigint);
    signal(SIGCONT, handle_sigcont);
    signal(SIGTSTP , handle_sigtstp);
    int i = 0;
	while(i < 10) {
		sleep(2);
        i++;
	}
	redText();
    printf("Process number %d finished sleeping...", getpid());
	printf("\033[0m");
	printf("\n");	
	exit(1);
}