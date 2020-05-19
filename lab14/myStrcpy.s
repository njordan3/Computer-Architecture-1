.text
.global myStrcpy
.type myStrcpy, @function

# rsi contains the first argument from the function call (string)
# rdi contains the second argument from the function call (int)

myStrcpy:
    mov %rdi, %rcx      # rcx = SIZE
    lea (%rax), %rdi    # load effective address of rax to rdi
    rep movsb           # moves a byte of string1 to string2 SIZE times
    ret                 # returns rax ,which is a copy of string1, to where it was called
