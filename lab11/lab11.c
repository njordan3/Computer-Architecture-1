//lab11.c 
//a program that computes a^b and log_b(a^b) LOTS of times
//values 'a' and 'b' are read in from the keyboard
//modify to optimize if base is 2 by using shift left and shift right
//
#include <stdio.h>
#include <stdlib.h>
#define ITERATIONS 80000

int main(int argc, char **argv)
{
	if (argc < 3) {
		printf("Usage: ./lab12 <base> <exp>\n");
		exit(0);
	}
	unsigned long long base = atoi(argv[1]);
	unsigned long long exp  = atoi(argv[2]);
	int i, j;
	unsigned long long exponential = 1;
	int brute;
	//
	//Repeatedly compute the exponential for time testing
	#ifdef OPTIMIZE
		printf("---> Optimization is set on.\n");
		if (base == 2) {
			for (i=0; i<ITERATIONS; i++) {
				exponential = 1;
				//%0 = exponential (output)
				//%1 = base (input)
				//%2 = exp (input)
				asm (
					"movq $1, %0;"
					"movq %2, %%rcx;"
					"sal %%cl, %0;"
					: "=r"(exponential)
					: "r"(base),"r"(exp)
					: "%rcx"
				);
			}
		}
	#else //OPTIMIZE
		for (i=0; i<ITERATIONS; i++) {
			exponential = 1;
			//brute force
			for (j=1; j<=exp; j++)
				exponential = base*exponential;
		}
	#endif //OPTIMIZE
	printf("%llu^%llu is %llu\n",base,exp,exponential);
	//
	int log = 0;
	unsigned long long dividend = exponential;
	//repeatedly compute the log to get substantial numbers for time.
	#ifdef OPTIMIZE

		//Remove the while loop just below, and
		//put your optimized asm code there.

		for (i=1; i<=ITERATIONS; i++) {
			log = 0;
			dividend = exponential;
            //%%rbx = dividend (output and input)
            //%%rax = log (output and input)
            //%4 = base (input)
            asm (
                "loop:  ;"
                "cmp %3, %%rbx;"
                "jl done;"          //end loop if dividend < base
                "sar $1, %%rbx;"    //shift dividend right once
                "add $1, %%rax;"    //log++
                "jmp loop;"         //jump to the top of the loop
                "done:  ;"          //loop ends if 'done' is reached
                : "=a"(log)
                : "a"(log), "b"(dividend), "r"(base)
                );
        }
	#else //OPTIMIZE
		for (i=1; i<=ITERATIONS; i++) {
			log = 0;
			dividend = exponential;
			while (dividend >= base) {
				dividend = dividend / base;
				log++;
			}
		}
	#endif //OPTIMIZE
	//
	printf("%llu log %llu is %i\n",exponential,base,log);
	return 0;
}

