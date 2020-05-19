# author: Nicholas Jordan
# date: Fall 2018
# desc: 2240 semester project
#       This program reads and prints the image of a PPM type P3 file
# usage: spim -f prog70.s csub3.ppm
#        spim -f prog70.s csub3_.ppm

.data
# array initialized with characters to be used in displaying the image
# each character in the array has more substance than the last
# each character will be used as color where black is a space and white is @
color_array: .ascii " .+:=&#@"
             .word 0

description: .asciiz "\n2240 prog70.s\nRead and display a PPM image file.\n"

# error messages in case something runs wrong
errormsg1:   .asciiz "\nImproper command line format. Usage: spim -f prog70.s file-name.ppm\n"

# buffer to store each byte read from the file to
buffer:      .space 1       # a buffer of size 1 byte
             .space 1 '\0'  # stuff a null character at the end of the buffer
             .word 0        # do this to align things

# labels for the details of the file being read
newline:     .asciiz "\n"
goodP3_prmpt:.asciiz "Good P3 file found.\n"
notP3_prmpt: .asciiz "File is not P3.\n" 

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

    jal checkP3             # make sure we have a valid P3 PPM file
                            # $a1 is initialized to hold the address of our data buffer in checkP3

# read the comment
    jal findComment         # finds '#' and reads the comment until [newline] is found         
   
# read the height
    jal storeWidth_Height   # store width into $s2 and height into $s1     
    
# read the maximum color value of the image
    jal readMCV 
    
# print newline for readability
    jal printNewline

# read and print the image stored in the file
readFile_Image:
    li $t3, 0               # $t3 = 0 (outer loop counter)   
    li $t4, 0               # $t4 = 0 (inner loop counter)
outerLoop:
    beq $t3, $s1, closeFile # if $t3 = height, then close the file
    add $t4, $zero, $zero   # reset the innerloop counter to 0

innerLoop:
    beq $t4, $s2, done      # if $t4 = width, then leave the inner loop
 
    li $t5, 0               # reset $t5 to 0(used in readRGB)
    jal readRGB             # reads every data value, but only uses every third value
    jal atoi                # converts the string stored in $a0 into an integer returned in $v0
    jal printCharacter      # prints the proper character according to the value read in readRGB
 
    addi $t4, $t4, 1        # $t4++
    j innerLoop             # jump back to the top of innerLoop      

done:   
    jal printNewline        # prints newline after the inner loop completes its round
    addi $t3, $t3, 1        # $t3++
    j outerLoop             # jump back to the top of outerLoop

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


readRGB:
# this function reads three full data values from the file but only utilizes the third value
    li $v0, 14              
    move $a0, $s0
    li $a2, 1               # make sure to only read one character
    syscall                 # read a single character from the file
    
    addi $t5, $t5, 1        # $t5++ ($t5 represents how many characters are read until [newline] is found

    lb $a0, buffer          
    bne $a0, 10, readRGB    # if the character read is [newline], stop reading one character at a time

    li $v0, 14
    move $a0, $s0
    move $a2, $t5           # read $t5 characters
    syscall                 # we don't want any value from this read
    li $v0, 14
    move $a0, $s0
    move $a2, $t5           # read $t5 characters
    syscall
    la $a0, buffer          # load the value read into $a0
    
    jr $ra


storeWidth_Height:
# this function reads and stores the width of the image into $s2
    move $s3, $ra           # the address of where the function was called needs to be 
                            # saved into $s3 because we are calling another function
    jal readUntil_nonWhitespace
        
    la $a0, buffer
    jal atoi                # converts the string stored in $a0 into an integer returned in $v0
    move $t6, $v0           

    jal readOneCharacter
    la $a0, buffer
    jal atoi
    move $t7, $v0

    mul $t6, $t6, 10
    add $s2, $t6, $t7       # $s2 = width

    jal readUntil_nonWhitespace

    la $a0, buffer
    jal atoi
    move $t6, $v0

    jal readOneCharacter
    la $a0, buffer
    jal atoi
    move $t7, $v0

    mul $t6, $t6, 10
    add $s1, $t6, $t7       # $s1 = height

    jr $s3                  # $s3 holds the return address of where the function was called


readMCV:
# this function reads the max color value of the file
# this file must only be called after the width and height have been read
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


findComment:
# this function reads until '#' is found and then reads until [newline] is found
    li $v0, 14
    move $a0, $s0           # read next byte          
    li $a2, 1
    syscall

    lb $a0, buffer          # load byte read into $a0
    
# if byte read is a '#' then we have found the comment
    bne $a0, 35, findComment

readComment:
    li $v0, 14
    move $a0, $s0           
    li $a2, 1
    syscall                 # read the comment one character at a time

    lb $a0, buffer          # load byte read into $a0

# if byte read is a [newline] return to where the function was called  
    bne $a0, 10, readComment
    jr $ra 


readOneCharacter:
    li $v0, 14
    move $a0, $s0
    li $a2, 1
    syscall

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


checkP3:
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
                            # we have an actually P3 file
notP3:
    li $v0, 4
    la $a0, notP3_prmpt 
    syscall                 # let the user know that the file is not P3
    j closeFile             # close file if it was not P3
goodP3:
    li $v0, 4
    la $a0, goodP3_prmpt
    syscall                 # let the user know the file is P3
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







