#define ALIGN_TEXT      .p2align 4,0x90 /* 16-byte alignment, nop filled */

.globl freebsd_memset
freebsd_memset:
	movq	%rdi,%rax
	movq	%rdx,%rcx
	movzbq	%sil,%r8
	movabs	$0x0101010101010101,%r10
	imulq	%r8,%r10

	cmpq	$32,%rcx
	jbe	101632f

	cmpq	$256,%rcx
	ja	1256f

103200:
	movq	%r10,(%rdi)
	movq	%r10,8(%rdi)
	movq	%r10,16(%rdi)
	movq	%r10,24(%rdi)
	leaq	32(%rdi),%rdi
	subq	$32,%rcx
	cmpq	$32,%rcx
	ja	103200b
	cmpb	$16,%cl
	ja	201632f
	movq	%r10,-16(%rdi,%rcx)
	movq	%r10,-8(%rdi,%rcx)
	ret
	ALIGN_TEXT
101632:
	cmpb	$16,%cl
	jl	100816f
201632:
	movq	%r10,(%rdi)
	movq	%r10,8(%rdi)
	movq	%r10,-16(%rdi,%rcx)
	movq	%r10,-8(%rdi,%rcx)
	ret
	ALIGN_TEXT
100816:
	cmpb	$8,%cl
	jl	100408f
	movq	%r10,(%rdi)
	movq	%r10,-8(%rdi,%rcx)
	ret
	ALIGN_TEXT
100408:
	cmpb	$4,%cl
	jl	100204f
	movl	%r10d,(%rdi)
	movl	%r10d,-4(%rdi,%rcx)
	ret
	ALIGN_TEXT
100204:
	cmpb	$2,%cl
	jl	100001f
	movw	%r10w,(%rdi)
	movw	%r10w,-2(%rdi,%rcx)
	ret
	ALIGN_TEXT
100001:
	cmpb	$0,%cl
	je	100000f
	movb	%r10b,(%rdi)
100000:
	ret
	ALIGN_TEXT
1256:
	movq	%rdi,%r9
	movq	%r10,%rax
	testl	$15,%edi
	jnz	3f
1:
# real freebsd systems unconditionally disable this by default, so I do too
#if defined(erms) && 0
	rep
	stosb
	movq	%r9,%rax
#else
	movq	%rcx,%rdx
	shrq	$3,%rcx
	rep
	stosq
	movq	%r9,%rax
	andl	$7,%edx
	jnz	2f
	ret
2:
	movq	%r10,-8(%rdi,%rdx)
#endif
	ret
	ALIGN_TEXT
3:
	movq	%r10,(%rdi)
	movq	%r10,8(%rdi)
	movq	%rdi,%r8
	andq	$15,%r8
	leaq	-16(%rcx,%r8),%rcx
	neg	%r8
	leaq	16(%rdi,%r8),%rdi
	jmp	1b
