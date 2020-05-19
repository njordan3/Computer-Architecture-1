#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <malloc.h>

const int SIZE = 400;
const int REPEAT = 1000000;


int main()
{
    int i, j;
    char *string1, *string2;
    string1 = (char *)malloc(SIZE); //Allocate space on the heap.
    string2 = (char *)malloc(SIZE);
    srand((unsigned)time(NULL));    //random seed
    for (i=0; i<SIZE-1; i++)        //Fill string1 with random characters.
        string1[i] = (rand() % 26) + 97;
    string1[SIZE-1] = '\0';         //Add a null terminator.
    printf("%s\n", string1);        //Display the string.
    //========================================================
    //Copy string1 to string2 using loops
    printf("..... copying with loops .....\n");
    for (j=0; j<REPEAT; j++) {
        for (i=0; i<SIZE; i++) {
            string2[i] = string1[i];
        }
    }
    printf("%s\n", string2);
    //========================================================
    //Copy string1 to string2 using strcpy
    memset(string2, 0, SIZE);
    printf("..... copying with strcpy .....\n");
    for (j=0; j<REPEAT*10; j++) {
        strcpy(string2, string1);   // C library function to copy string1 to string2
    }
    printf("%s\n", string2);
    //========================================================
    //Copy string1 to string2 using inline assembly
    memset(string2, 0, SIZE);
    printf("..... copying with inline movsb .....\n");
    for (j=0; j<REPEAT*10; j++) {
        //write inline code here...
        asm(
            "lea (%%rax), %%rsi;"       // load effective address of string1 to rsi
            "lea -487(%%rsp), %%rbx;"   // load the effective address of rsp with -487 offset to string2
            "lea (%%rbx), %%rdi;"       // load the effective address of string2 to rdi
            "rep movsb;"                // moves a byte of string1 to string2 SIZE times
           :"=b"(string2)               // output: rbx represents string2
           :"a"(string1), "c"(SIZE)     // inputs: rax represents string1, rcx represents SIZE
          );

    }
    printf("%s\n", string2);

    //========================================================
    //Copy string1 to string2 using an assembly function
    memset(string2, 0, SIZE);
    printf("_____ copying with myStrcpy.s _____\n");
    for (j=0; j<REPEAT*10; j++) {
        //call myStrcpy here...
        extern char* myStrcpy(int, char*);  // declaration of external assembly function of return type string
        string2 = myStrcpy(SIZE, string1);  // string2 = the return value of the external assembly function

    }
    //========================================================
    //Show final string.
    printf("%s\n", string2);
    printf("\n");
    printf("program complete.\n");
    //Free the string memory.
    free(string1);      // having to "free" function calls gave an error
    //free(string2);    ***Error in './lab14': double free or corruption (!prev): 0x0000000000de3010 *** Aborted
    return 0;
}
