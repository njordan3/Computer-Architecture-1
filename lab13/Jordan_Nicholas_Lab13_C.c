#include <stdlib.h>
#include <string.h>
#include <stdio.h>

int add(int a, int b)
{
    return a + b;
}

int main()
{
    int a=10,b=20;
    int c = add(a,b);
    printf("int c: %d\n",c);
    int * pointer = &c;
    printf("int pointer: %d\n",*pointer);
    if(*pointer != c)
        printf("pointer != c\n");
    else
        printf("pointer == c\n");

    return 0;
}
