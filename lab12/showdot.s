
# This program follows the GNU AS (GAS) syntax rules.
# It is also AT&T syntax.

# This program to be called from a C program.
# Data can be declared here.
.section .data
string: .ascii  "Hello from assembler\n"


# The code is here...
.section .text
.global showDot
.type showDot, @function  # <--- this line is important

showDot:
	                 # The setPixel function is defined inside the C program.
	                 # Please get the pixel to draw at the center position.
	                 # How could you optimize this call somewhat?
	                 #
	mov  $200, %rdi  # put x coordinate into argument 1
	mov  $200, %rsi  # put y coordinate into argument 2
	call setPixel    # call an external function

