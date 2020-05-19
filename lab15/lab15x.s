
# Please complete this decryption function.
.text
.global decrypt15x
.type decrypt15x, @function  # <--- this line is important

decrypt15x:
    xor %rcx, %rcx          # clear %rcx to be used for counting
loop:
    cmp %rsi, %rcx          # %rsi = slen (the second argument in the function call)
    je return               # if %rcx = slen, jump to return
    mov (%rdi), %bl         # move contents stored at address %rdi to %bl
    ror $2, %bl             # rotate the bits in %bl twice to the right
    mov %bl, %bh            # copy %bl to %bh
    and $0b01000010, %bh    # bitwise and %bh through the mask 01000010 to get the 1st and 6th bits
    jpe done                # if the bitwise and results in an even number of 1's, jump to done
    xor $0b01000010, %bl    # if not, then bitwise xor %bh through the mask 01000010 to swap the 1st and 6th bits
done:
    mov %bl, (%rdi)         # move the now decrypted %bl back to the address of %rdi
    add $1, %rdi            # increment %rdi to get to the next element in the character array
    add $1, %rcx            # increment the counter
    jmp loop                # jump back to the top of the loop

return:
    ret                     # return to where the function was called
