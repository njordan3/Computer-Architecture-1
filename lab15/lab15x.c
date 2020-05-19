//modified by:
//date:
//purpose:
//
//Idea for this lab developed by: Matthew Gaitan
//
//Read an encrypted file, and decrypt it using x86 assembly.
//
#include <stdio.h>
#include <string.h>
#include <malloc.h>

const char fname[] = "file15x";

int main()
{
	unsigned char *str = (unsigned char *)malloc(1000);
	FILE *fpi = fopen(fname,"r");
	if (!fpi) {
		printf("ERROR opening **%s**\n", fname);	
		return 0;
	}
	fread(str, 1, 1000, fpi);
	int slen = strlen((char *)str);
	printf("str len: %i\n", slen);
	fclose(fpi);
	//
	//Encryption method:
	//
	//Each character in string is rolled 2 bits to the left.
	//No bits are lost in the roll operation.
	//
	//Call the decrypt15 function in lab15.s
	//Write the decryption operations there.
	//No changes are needed in this file.
	//
	extern void decrypt15x(unsigned char *str, int slen);
	decrypt15x(str, slen);
	printf("%s\n", (char *)str);
	//
	free(str);
	return 0;
}


