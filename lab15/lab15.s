
# Please complete this decryption function.
.text
.global decrypt15
.type decrypt15, @function  # <--- this line is important

decrypt15:
    xor %rcx, %rcx      # clear %rcx to be used for counting
loop:
    cmp %rsi, %rcx      # %rsi = slen (the second argument in the function call)
    je return           # if %rcx = slen, jump to return
    mov (%rdi), %bl     # move contents stored at address %rdi to %bl
    ror $2, %bl         # rotate the bits in %bl twice to the right
    mov %bl, (%rdi)     # move the new decrypted %bl back to the address of %rdi
    add $1, %rdi        # increment %rdi to get to the next element in the character array
    add $1, %rcx        # increment the counter
    jmp loop            # jump back to the top of the loop

return:
    ret                 # return to where the function was called
