# author: Nicholas Jordan
# date: Fall 2018
# desc: 2240 semester project
#       This program reads the information of a PPM type P3 file
# usage: spim -f prog60.s csub3.ppm
#        spim -f prog60.s csub3_.ppm

.data
description: .asciiz "\n2240 prog60.s\nRead the information of a PPM image file.\n"

# error messages in case something runs wrong
errormsg1:   .asciiz "\nImproper command line format. Usage: spim -f prog60.s file-name.ppm\n"
errormsg2:   .asciiz "\nError opening file. Usage: spim -f prog60.s file-name.ppm\n"

# buffer to store each byte read from the file to
buffer:      .space 1       # a buffer of size 1 byte
             .space 1 '\0'  # stuff a null character at the end of the buffer
             .word 0        # do this to align things

# labels for the details of the file being read
newline:     .asciiz "\n"
fd_prompt:   .asciiz "\nFile descriptor: "
goodP3_prmpt:.asciiz "Good P3 file found.\n"
commentFound:.asciiz "Found a comment: "
widthFound:  .asciiz "Image width: "
heightFound: .asciiz "Image height: "
max_colorval:.asciiz "Maximum color value: "
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

    li $v0, 14              # 14 is read file syscall
    move $a0, $s0           # store file descriptor in $a0
    la $a1, buffer          # load the address to the buffer
    li $a2, 1               # load the size of the buffer
    syscall

# print the file descriptor info
    jal showFileDescriptor  
    jal printNewline        
    jal checkP3             
    
# print the comment
    jal findComment         
    la $a0, commentFound    
    li $v0, 4               
    syscall                 
    jal printComment        
    
# find the end of whitespace
    jal readUntil_nonWhitespace     
    
# print the width of the image
    la $a0, widthFound
    li $v0, 4
    syscall
    jal printWidth
    
# print newline for readability
    jal printNewline
    
# print the height of the image
    la $a0, heightFound
    li $v0, 4
    syscall
    jal printHeight

# find the end of whitespace
    jal readUntil_nonWhitespace    
    
# print the maximum color value of the image
    la $a0, max_colorval
    li $v0, 4
    syscall
    jal printMCV 
    
# print newline for readability
    jal printNewline

closeFile:
    li $v0, 16              # 16 is close file syscall
    add $a0, $s0, $0        # store file descriptor in $a0
    syscall
    
exit:    
    li $v0, 10              # exit program cleanly
    syscall 


# ------- FUNCTIONS USED -----------------------------------------------------------

readUntil_nonWhitespace:
    li $v0, 14
    move $a0, $s0           # read next byte
    syscall

    lb $a0, buffer          # load byte read into $a0

# if byte read is not a [tab] or [space] return to where function was called  
    beq $a0, 9, readUntil_nonWhitespace
    beq $a0, 32, readUntil_nonWhitespace
    jr $ra


printMCV:
    li $v0, 4
    la $a0, buffer          # print byte read
    syscall
    
    li $v0, 14
    move $a0, $s0           # read next byte
    syscall
    
    lb $a0, buffer          # load byte read into $a0

# if byte read is a [newline] return to where the function was called  
    bne $a0, 10, printMCV
    jr $ra 


printHeight:
    li $v0, 14
    move $a0, $s0           # read next byte
    syscall
    
    li $v0, 4
    la $a0, buffer          # print byte read
    syscall
   
    lb $a0, buffer          # load byte read into $a0

# if byte read is a [newline] return to where the function was called  
    bne $a0, 10, printHeight
    jr $ra 
    

printWidth:
    li $v0, 4
    la $a0, buffer          # print byte read
    syscall
    
    li $v0, 14
    move $a0, $s0           # read next byte
    syscall

    lb $a0, buffer          # load byte read into $a0

# if byte read is a [space] return to where the function was called  
    bne $a0, 32, printWidth
    jr $ra 


findComment:
    li $v0, 14
    move $a0, $s0           # read next byte
    syscall

    lb $a0, buffer          # load byte read into $a0
    
# if byte read is a '#' then we have found the comment
    bne $a0, 35, findComment
    jr $ra


printComment:
    li $v0, 14
    move $a0, $s0           # read next byte
    syscall

    li $v0, 4
    la $a0, buffer          # print byte read
    syscall

    lb $a0, buffer          # load byte read into $a0

# if byte read is a [newline] return to where the function was called  
    bne $a0, 10, printComment
    jr $ra 


showFileDescriptor:
    li $v0, 4
    la $a0, fd_prompt 
    syscall          
    li $v0, 1
    move $a0, $s0           # print file descriptor
    syscall   
    jr $ra                  # return to where function was called


checkP3:
# if file descriptor is 3 then a good P3 was found
    move $a0, $s0
    beq $a0, 3, goodP3     
notP3:
    li $v0, 4
    la $a0, notP3_prmpt 
    syscall
    j closeFile             # close file if P3 was not found
goodP3:
    li $v0, 4
    la $a0, goodP3_prmpt
    syscall
    jr $ra                  # return to where function was called


printNewline:
    li $v0, 4
    la $a0, newline         # print newline
    syscall
    jr $ra                  # return to where function was called

# ------------------------------------------------------------------------------------








