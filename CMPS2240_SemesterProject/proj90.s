# author: Nicholas Jordan
# date: Fall 2018
# desc: 2240 semester project
#       This program reads and prints the image of a PPM type P3 or P6 file
# usage: spim -f prog90.s csub3.ppm
#        spim -f prog90.s csub3_.ppm
#        spim -f prog90.s p6test.ppm
#        spim -f prog90.s spock.ppm

.data
# array initialized with characters to be used in displaying the image
# each character in the array has more substance than the last
# each character will be used as color where black is a space and white is @
color_array: .ascii " .+:=&#@"
             .word 0

description: .asciiz "\n2240 prog90.s\nRead and display a PPM image file.\n"

# error messages in case something runs wrong
errormsg1:   .asciiz "\nImproper command line format. Usage: spim -f prog90.s file-name.ppm\n"

# buffer to store each byte read from the file to
buffer:      .space 1       # a buffer of size 1 byte
             .space 1 '\0'  # stuff a null character at the end of the buffer
             .word 0        # do this to align things

# labels for the details of the file being read
newline:     .asciiz "\n"
goodP3_prmpt:.asciiz "Good P3 file found.\n"
goodP6_prmpt:.asciiz "Good P6 file found.\n"
notP3_prmpt: .asciiz "File is not P3 or P6.\n" 

.text
main:
    add $t0, $t0, 2         # $t0 is the proper argument count
    move $s0, $a0           # $a0 holds the number of command line arguments
    beq $s0, $t0, openFile  # we are okay to attempt to open file if the number of command line arguments is 2 
    
    # display errormsg1 if the ammount of command line arguments is not 2 and exit program
    la $a0, errormsg1       
    li $v0, 4
    syscall
    j exit

openFile:
    li $v0, 4
    la $a0, description     # print program description
    syscall
    
    lw $s0, 4($a1)          # get file name from command line
    li $v0, 13              # 13 is file open syscall
    move $a0, $s0           # move file name into $a0
    add $a1, $0, $0         # flags=O_RDONLY=0         
    add $a2, $0, $0         # mode=0
    syscall
    
    add $s0, $v0, $0        # store file descriptor in $s0 before it is overwritten

    jal checkType           # checks type of PPM (P3 or P6), if neither then the program exits
                            # $a1 is initialized to hold the address of our data buffer in checkType
                            # $s4 holds the number after P (3 or 6)
readSpecs:
# readComment, readWidth_Height, and readMCV must be called in the order they were just listed
# otherwise they'll return useless data
    li $v0, 14
    move $a0, $s0
    li $a2, 1       # make sure to read one character
    syscall         # read the next character in the file

    lb $a0, buffer
    
    beq $a0, 9, readSpecs       # if the byte read is [tab] jump to the top of the loop
    beq $a0, 10, readSpecs      # if the byte read is [newline] jump to the top of the loop
    beq $a0, 32, readSpecs      # if the byte read is [space] jump to to the top of the loop
    beq $a0, 35, readComment    # if the byte read is '#' then the line is a comment
                                # (readComment does not store the comments anywhere)
   
# if the byte read is not [tab], [newline], [space], or '#'
    jal readWidth_Height        # reads the entire width/height line ($s2 = width, $s1 = height)
                                # (readWidth_Height does not store any comment on the line)
    jal readMCV                 # reads the entire MCV line (does not store anything on the line)

# print newline for readability
    jal printNewline

# the program knows whether the file is P3 or P6 and will read and print the file accordingly
    beq $s4, 6, P6readFile_Image    # if $s4 = 6, then we read and print the file as a P6
    beq $s4, 3, P3readFile_Image    # if $s4 = 3, then we read and print the file as a P3
    j closeFile

P3readFile_Image:
# read and print the P3 image stored in the file
    li $t3, 0               # $t3 = 0 (outer loop counter)   
    li $t4, 0               # $t4 = 0 (inner loop counter)
P3outerLoop:
    beq $t3, $s1, closeFile # if $t3 = height, then close the file
    add $t4, $zero, $zero   # reset the innerloop counter to 0

P3innerLoop:
    beq $t4, $s2, P3done    # if $t4 = width, then leave the inner loop

    li $t5, 0               # reset $t5 to 0(used in P3readRGB)
    jal P3readRGB           # reads every third data value and puts that data into atoi which
                            # converts the data from a string to an integer stored in $v0
    jal printCharacter      # prints the proper character according to the value read in readRGB
 
    addi $t4, $t4, 1        # $t4++
    j P3innerLoop           # jump back to the top of innerLoop      

P3done:   
    jal printNewline        # prints newline after the inner loop completes its round
    addi $t3, $t3, 1        # $t3++
    j P3outerLoop           # jump back to the top of outerLoop


P6readFile_Image:
# read and print the P6 image stored in the file
    li $t3, 0               # $t3 = 0 (outer loop counter)   
    li $t4, 0               # $t4 = 0 (inner loop counter)
    
    li $v0, 9               # 9 is allocate heap memory
    mul $a0, $s2, $s1
    mul $a0, $a0, 3         # $a0 = width * height * 3       
    syscall                 # $a0 is the number of bytes to allocate

    move $a1, $v0           # $a1 = $v0 ($v0 contains the address of allocate memory from syscall 9)
    move $a2, $a0           # $a2 = $a0 ($a0 contains the amount of bytes for syscall 9 to allocate
                            # which is how many characters we want to read)
    li $v0, 14              
    move $a0, $s0
    syscall                 # reads $a2 characters from the file and stores them at address $a1

P6outerLoop:
    beq $t3, $s1, closeFile # if $t3 = height, then close the file
    add $t4, $zero, $zero   # reset the innerloop counter to 0

P6innerLoop:
    beq $t4, $s2, P6done    # if $t4 = width, then leave the inner loop
 
    jal P6readRGB           # reads every third data value and loads the unsigned byte of that data into $v0
    jal printCharacter      # prints the proper character according to the value read in readRGB
 
    addi $t4, $t4, 1        # $t4++
    j P6innerLoop           # jump back to the top of innerLoop      

P6done:   
    jal printNewline        # prints newline after the inner loop completes its round
    addi $t3, $t3, 1        # $t3++
    j P6outerLoop           # jump back to the top of the outerLoop 


closeFile:
    li $v0, 16              # 16 is close file syscall
    add $a0, $s0, $0        # store file descriptor in $a0
    syscall
    
exit:    
    li $v0, 10              # exit program cleanly
    syscall 


# ------- FUNCTIONS USED -----------------------------------------------------------

printCharacter:
# this function scales an integer and prints the character represented by that scaled value
    move $s3, $v0           # $s3 = $v0 ($v0 is the return value of the atoi function)
    li $t5, 32              # $t5 = 32 (used to scale the value of the data)
    la $s4, color_array     # load the address of color_array into $s4
    div $s3, $t5            # data is divided by 32 to scale it
    mflo $s3                # $s3 = lo (lo holds the value of the scaled data)
    add $s4, $s4, $s3       # add the scaled data, $s3, to the address of color_array
                            # $s3 is used as the offset into color_array
    lb $a0, ($s4)               
    li $v0, 11              # 11 is print character syscall
    syscall                 # print the character represented by the scaled data
    
    jr $ra                  # return to where the function was called


P3readRGB:
# this function reads three full data values from the file but only utilizes the third value
    move $s3, $ra           # the address of where the function was called needs
                            # to be saved into $s3 because we are called another function
    li $v0, 14              
    move $a0, $s0
    li $a2, 1               # make sure to only read one character
    syscall                 # read a single character from the file
    
    addi $t5, $t5, 1        # $t5++ ($t5 represents how many characters are read until [newline] is found

    lb $a0, buffer          
    bne $a0, 10, P3readRGB    # if the character read is [newline], stop reading one character at a time

    li $v0, 14
    move $a0, $s0
    move $a2, $t5           # read $t5 characters
    syscall                 # we don't want any value from this read
    li $v0, 14
    move $a0, $s0
    move $a2, $t5           # read $t5 characters
    syscall
    la $a0, buffer          # load the value read into $a0
    
    jal atoi                # convert $a0 from string to an integer stored in $v0

    jr $s3                  # return to where the function was called


P6readRGB:
# this function reads every third data value from the allocated memory that contains the image file
    lbu $v0, ($a1)          # load the unsigned byte at address $a1 into $v0
    addi $a1, $a1, 3        # increment address $a1 by 3 to get to the next third element

    jr $ra                  # return to where the function was called


readWidth_Height:
# this function reads and stores the width and height of the image into $s2 and $s1 respectively
# we store this line onto the stack so that we can move back and forth as needed    
    move $s3, $ra           # the address of where the function was called needs to be 
                            # saved into $s3 because we are calling another function
    la $a0, buffer
    jal atoi                # converts the string stored in $a0 into an integer returned in $v0
    li $s1, 1               # $s1 = 1 ($s1 is used keep track where we are on the stack) 
    add $sp, $sp, -4        # decrement the stack 4 bytes to make room for data to be stored there
    sw $v0, ($sp)           # push the return value of atoi onto the stack
                            # $v0 contains the first byte read on the line where width and height are

Numberloop:
# this is where we push the entire width/height line from the file onto the stack
    li $v0, 14
    move $a0, $s0
    li $a2, 1               # make sure to read one character
    syscall                 # read the next character on the width/height line

    lb $a0, buffer
    beq $a0, 10, Numberloop_done    # if the byte read is [newline] then the entire width/height line has been read
    beq $a0, 32, StoreOther         # if the byte read is [space] then we store -1 on the stack
    beq $a0, 9, StoreOther          # if the byte read is [tab] then we store -1 on the stack

    la $a0, buffer
    jal atoi                # convert the byte read into an integer to be stored on the stack

    addi $s1, $s1, 1        # $s1++
    addi $sp, $sp, -4       # decrement the stack 4 bytes to make room for data to be stored there
    sw $v0, ($sp)           # push the return value of atoi onto the stack
            
    j Numberloop            # jump back to the top of the loop

StoreOther:
# this is where we store -1 onto the stack if the byte read is [space] or [tab]
    li $s2, -1              # $s2 = -1
    addi $s1, $s1, 1        # $s1++
    addi $sp, $sp, -4       # decrement the stack 4 bytes to make room for data to be stored there
    sw $s2, ($sp)           # push $s2 onto the stack
    j Numberloop            # jump back to the top of the loop

Numberloop_done:
# we no longer need to read from the file but just from the stack from here
    
# the next 3 lines push -1 onto the stack for [newline]
    addi $s1, $s1, 1        # $s1++
    addi $sp, $sp, -4       # decrement the stack 4 bytes to make room for data to be stored there
    sw $s2, ($sp)           # push $s2 onto the stack
  
    li $s5, 0               # $s5 = 0 ($s5 increments to the size of the width)
    
# the next 3 lines get us to the bottom of the stack to read the width/height line from the beginning
    addi $s1, $s1, -1       # $s1--
    mul $s1, $s1, 4         # $s1 = $s1 * 4
    add $sp, $sp, $s1       # $sp = $sp + $s1

Store_Width:    
    lw $a0, ($sp)           # load the next element of the stack into $a0
    beq $a0, -1, Width_Calculate    # if $a0 = -1, then we reached the end of width

    addi $s5, $s5, 1        # $s5++
    addi $sp, $sp, -4       # decrement the stack to get the next element
    j Store_Width           # loop back to the top of the loop

Width_Calculate:
    mul $s5, $s5, 4         # $s5 = $s5 * 4
    add $sp, $sp, $s5       # $sp = $sp + $s5 (goes back in the stack $s5 bytes)
    
# $s5 is now a multiple of 4, so if we divide $s5 by 4 we get how many digits width has
    beq $s5, 12, Width_has_3    # if $s5 = 12, then the width has 3 digits
    beq $s5, 8, Width_has_2     # if $s5 = 8, then the width has 2 digits

    lw $s2, ($sp)   # assume $s5 = 4 if $s5 is not 12 or 8
    j Store_Height  # jump to Store_Height

Width_has_3:
    lw $t0, ($sp)       # load the first digit of width into $t0
    mul $t0, $t0, 100   # $t0 = $t0 * 100
    lw $t1, -4($sp)     # load the second digit of width into $t1
    mul $t1, $t1, 10    # $t1 = $t1 * 10
    lw $t2, -8($sp)     # load the third digit of width into $t2

    add $s2, $t0, $t1   # $s2 = $t0 + $t1
    add $s2, $s2, $t2   # $s2 = $s2 + $t2 ($s2 = width)
    
    j Store_Height      # jump to Store_Height

Width_has_2:
    lw $t0, ($sp)       # load the first digit of width into $t0
    mul $t0, $t0, 10    # $t0 = $t0 * 10
    lw $t1, -4($sp)     # load the second digit of width into $t0
    
    add $s2, $t0, $t1   # $s2 = $t0 + $t1 ($s2 = width)

Store_Height:
# the width has now been stored so we can move onto the height
    li $s1, 0           # $s1 = 1 ($s1 keeps track of how many digits height has)

# the next two lines get us to where the width ends
    mul $s5, $s5, -1    # $s5 = $s5 * -1
    add $sp, $sp, $s5   # $sp = $sp + $s5

Find_Height:
# finds where the height starts because after width there may be some whitespace
    lw $a0, ($sp)       # load the next element on the stack into $a0
    bne $a0, -1, Height_Count       # if $a0 is not -1 then we have reached the start of height
    addi $sp, $sp, -4   # decrement the stack to get to the next element 
    j Find_Height       # jump back to the top of the loop

Height_Count:
# we are now at the where the height starts
    lw $a0, ($sp)       # load the next element on the stack into $a0
    beq $a0, -1, Height_Calculate   # if $a0 = -1 then we have reached the end of height

    addi $s1, $s1, 1    # $s1++
    addi $sp, $sp, -4   # decrement the stack to get to the next element
    j Height_Count      # jump back to the top of the loop

Height_Calculate:
# now we know how many digits width has
    mul $s1, $s1, 4     # $s1 = $s1 * 4
    add $sp, $sp, $s1   # $sp = $sp + $s1

    beq $s1, 12, Height_has_3       # if $s1 = 12, then the height has 3 digits
    beq $s1, 8, Height_has_2        # if $s1 = 8, then the height has 2 digits
    
    lw $s1, ($sp)       # assume $s1 = 4 if $s1 is not 12 or 8
    j return             # jump to retrn since we have stored what we needed

Height_has_3:
    lw $t0, ($sp)       # load the first digit of height into $t0
    mul $t0, $t0, 100   # $t0 = $t0 * 100
    lw $t1, -4($sp)     # load the second digit of height into $t1
    mul $t1, $t1, 10    # $t1 = $t1 * 10
    lw $t2, -8($sp)     # load the third digit of height into $t2

    add $s1, $t0, $t1   # $s1 = $t0 + $t1
    add $s1, $s1, $t2   # $s1 = $s1 + $t2 ($s1 = height)
    
    j return             # jump to retrn since we have stored what we needed

Height_has_2:
    lw $t0, ($sp)       # load the first digit of height into $t0
    mul $t0, $t0, 10    # $t0 = $t0 * 10
    lw $t1, -4($sp)     # load the second digit of height into $t1
    
    add $s1, $t0, $t1   # $s1 = $t0 + $t1 ($s1 = height)

return:
    jr $s3              # return to where the function was called
    

readMCV:
# this function reads the max color value of the file
    move $s3, $ra           # the address of where the function was called needs to be
                            # saved into $s3 because we are calling another function
    jal readUntil_nonWhitespace

loop:
    li $v0, 14
    move $a0, $s0           
    li $a2, 1               # read 1 characters
    syscall                 

    lb $a0, buffer

# if the character read is [newline] then we've reached the end of MCV
    bne $a0, 10, loop       

    jr $s3                  # return to where the function was called


readComment:
    li $v0, 14
    move $a0, $s0           
    li $a2, 1
    syscall                 # read the comment one character at a time

    lb $a0, buffer          # load byte read into $a0

# if byte read is a [newline] return to where the function was called  
    bne $a0, 10, readComment
    jr $ra 


readUntil_nonWhitespace:
    li $v0, 14
    move $a0, $s0           # read next byte
    li $a2, 1
    syscall

    lb $a0, buffer          # load byte read into $a0

# if byte read is not a [tab] or [space] return to where function was called
    beq $a0, 9, readUntil_nonWhitespace
    beq $a0, 32, readUntil_nonWhitespace
    beq $a0, 10, readUntil_nonWhitespace
    jr $ra


checkType:
# reads the first two characters, but only checks the second value to make sure
# that the file we are reading is actually a P3 file
    li $v0, 14
    move $a0, $s0
    la $a1, buffer          # a1 remains constant throughout the program
    li $a2, 1               # read first character, but do nothing with it
    syscall
    
    li $v0, 14
    move $a0, $s0
    la $a1, buffer
    li $a2, 1               # read second character
    syscall

    lb $a0, buffer          # load byte read into $a0
    
    beq $a0, 51, goodP3     # if the second character is a 3 (51 in ascii) then 
                            # we have an P3 file
    beq $a0, 54, goodP6     # if the second character is a 6 (54 in ascii) then 
                            # we have a P6 file
notP3:
    li $v0, 4
    la $a0, notP3_prmpt 
    syscall                 # let the user know that the file is not P3
    j closeFile             # close file if it was not P3
goodP3:
    li $v0, 4
    la $a0, goodP3_prmpt
    syscall                 # let the user know the file is P3
    li $s4, 3               # $s4 = 3 (indicates type of PPM)
    jr $ra                  # return to where function was called
goodP6:
    li $v0, 4
    la $a0, goodP6_prmpt
    syscall                 # let the user know the file is P6
    li $s4, 6               # $s4 = 6 (indicates type of PPM)
    jr $ra                  # return to where function was called


printNewline:
    li $v0, 4
    la $a0, newline         # print newline
    syscall
    jr $ra                  # return to where function was called


atoi:
    move $v0, $zero

    # detect sign
    li $t0, 1
    lbu $t1, 0($a0)
    bne $t1, 45, digit
    li $t0, -1
    addu $a0, $a0, 1

digit:
    # read character
    lbu $t1, 0($a0)

    # finish when non-digit encountered
    bltu $t1, 48, finish
    bgtu $t1, 57, finish

    # translate character into digit
    subu $t1, $t1, 48

    # multiply the accumulator by ten
    li $t2, 10
    mult $v0, $t2
    mflo $v0

    # add digit to the accumulator
    add $v0, $v0, $t1

    # next character
    addu $a0, $a0, 1
    b digit

finish:
    mult $v0, $t0
    mflo $v0
    jr $ra

# ------------------------------------------------------------------------------------







