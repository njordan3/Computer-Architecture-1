	.text
	.file	"main.c"
	.globl	add
	.align	16, 0x90
	.type	add,@function
add:                                    # @add
	.cfi_startproc
# BB#0:
	pushq	%rbp
.Ltmp0:
	.cfi_def_cfa_offset 16
.Ltmp1:
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
.Ltmp2:
	.cfi_def_cfa_register %rbp
	movl	%edi, -4(%rbp)
	movl	%esi, -8(%rbp)
	movl	-4(%rbp), %esi
	addl	-8(%rbp), %esi
	movl	%esi, %eax
	popq	%rbp
	retq
.Ltmp3:
	.size	add, .Ltmp3-add
	.cfi_endproc

	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:
	pushq	%rbp
.Ltmp4:
	.cfi_def_cfa_offset 16
.Ltmp5:
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
.Ltmp6:
	.cfi_def_cfa_register %rbp
	subq	$48, %rsp
	movl	$0, -4(%rbp)
	movl	$10, -8(%rbp)
	movl	$20, -12(%rbp)
	movl	-8(%rbp), %edi
	movl	-12(%rbp), %esi
	callq	add
	movabsq	$.L.str, %rdi
	movl	%eax, -16(%rbp)
	movl	-16(%rbp), %esi
	movb	$0, %al
	callq	printf
	movabsq	$.L.str1, %rdi
	leaq	-16(%rbp), %rcx
	movq	%rcx, -24(%rbp)
	movq	-24(%rbp), %rcx
	movl	(%rcx), %esi
	movl	%eax, -28(%rbp)         # 4-byte Spill
	movb	$0, %al
	callq	printf
	movq	-24(%rbp), %rcx
	movl	(%rcx), %esi
	cmpl	-16(%rbp), %esi
	movl	%eax, -32(%rbp)         # 4-byte Spill
	je	.LBB1_2
# BB#1:
	movabsq	$.L.str2, %rdi
	movb	$0, %al
	callq	printf
	movl	%eax, -36(%rbp)         # 4-byte Spill
	jmp	.LBB1_3
.LBB1_2:
	movabsq	$.L.str3, %rdi
	movb	$0, %al
	callq	printf
	movl	%eax, -40(%rbp)         # 4-byte Spill
.LBB1_3:
	movl	$0, %eax
	addq	$48, %rsp
	popq	%rbp
	retq
.Ltmp7:
	.size	main, .Ltmp7-main
	.cfi_endproc

	.type	.L.str,@object          # @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"int c: %d\n"
	.size	.L.str, 11

	.type	.L.str1,@object         # @.str1
.L.str1:
	.asciz	"int pointer: %d\n"
	.size	.L.str1, 17

	.type	.L.str2,@object         # @.str2
.L.str2:
	.asciz	"pointer != c\n"
	.size	.L.str2, 14

	.type	.L.str3,@object         # @.str3
.L.str3:
	.asciz	"pointer == c\n"
	.size	.L.str3, 14


	.ident	"Debian clang version 3.5.0-10 (tags/RELEASE_350/final) (based on LLVM 3.5.0)"
	.section	".note.GNU-stack","",@progbits
