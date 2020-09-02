#include <stdio.h>

int digit_cnt(char* str){
    int i = 0;
    while (str[i])
    {
    	++i;
    }
    return i;
}

int main(int argc, char *argv[]){
    if(argc != 2) return 1;
    printf("%d \n", digit_cnt(argv[1]));
}


