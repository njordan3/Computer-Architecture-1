; Nicholas Jordan; CMPS2240 Lab10
section .rodata
	prompt1    db "In this program, the user enters 10 integers and the sum will be displayed.", 10, 0   ; 0 is null character
	prompt2    db "Please enter a number: ",0
	format_str db "The sum is: %ld.",10,0  ; 10 is LF 
	num_format db "%ld",0
section .text
	global main                 ; main and _start are both valid entry points
	extern printf, scanf        ; these will be linked in from glibc 
main:                           ; prologue
	push    rbp                 ; save base pointer to the stack
	mov     rbp, rsp            ; base pointer = stack pointer 
	sub     rsp, 80             ; make room for integers on the stack
	push    rbx                 ; push callee saved registers onto the stack 
	push    r12                 ; push automatically decrements stack pointer
	push    r13          
	push    r14
	push    r15
	pushfq                      ; push register flags onto the stack
    mov    rdi, dword prompt1   ; prompt the user the program functionality
    xor    rax, rax             ; rax is the return value register - zero it out
    call   printf
    xor    rbx, rbx             ; i = 0
    xor    r12, r12             ; sum = 0
read_loop:                      ; prompt for 10 integers and push them onto the stack
    cmp    rbx, 10              ; if i = 10
    je     loop_exit            ; jump to loop_exit
	mov    rdi, dword prompt2   ; double word is 4 bytes; a word is 2 bytes
	xor    rax, rax             ; rax is return value register - zero it out
	call   printf               ; call the C function from glibc 
    sub    rbp, 8               ; go to the next empty space in the stack
    lea    rsi, [rbp]           ; load effective address - this instruction
	mov    rdi, dword num_format; load rdi with address to format string
	xor    rax, rax             ; zero out return value register
	call   scanf                ; scanf reads the input as an integer
    mov    rax, [rbp]           ; rax = integer pointed to by address rbp
    add    r12, rax             ; sum = sum + rax
    add    rbx, 1               ; i++
    jmp    read_loop            ; jump to read_loop
loop_exit:
    mov    rsi, r12             ; print the sum of the integers
    mov    rdi, dword format_str
	xor    rax, rax             ; rax is return value register - zero it out
	call printf                 ; call the C function from glibc 
exit:                           ; epilogue
      popfq
      pop     r15
      pop     r14
      pop     r13
      pop     r12
      pop     rbx
      add     rbp, 80           ; set back the stack level
      add     rsp, 80           
      leave
      ret			
