# Copyright (c) 2021, Elijah Stone
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# based on https://msrc-blog.microsoft.com/2021/01/11/building-faster-amd64-memset-routines/
.intel_syntax noprefix

# memset implementation not relying on simd registers, suitable for a multitasking kernel
.globl fancy_memset_basic
.p2align 4
fancy_memset_basic:
# dst: rdi
# c: sil
# l: rdx

mov	rax, rdi # todo would it be more efficient re codesize to use rax?

movzx	esi, sil
mov	r8, 0x0101010101010101
imul	rsi, r8

cmp	rdx, 32
jb	.under32

.ifdef erms
cmp	rdx, 800
jae	.huge
.endif

# big
lea	r9, [rdx - 1] #round _down_; that is, if rdx is a multiple of 32, r9 should be the next one down; otherwise trunc
                      #this reduces the number of redundant stores (though it doesn't get rid of them in the case when rdx=32)
and	r9, ~31
lea	rcx, [rdi + r9]

.bigloop:
mov	[rdi], rsi
mov	[rdi +  8], rsi
mov	[rdi + 16], rsi
mov	[rdi + 24], rsi
add	rdi, 32
cmp	rdi, rcx
jb	.bigloop

# last 32 bytes
mov	[rax + rdx - 32], rsi
mov	[rax + rdx - 24], rsi
mov	[rax + rdx - 16], rsi
mov	[rax + rdx -  8], rsi
ret

.under32:
cmp	edx, 16
jb	.under16

# 16-31 bytes
lea	rcx, [rdi + rdx - 8]
and	edx, 16
shr	edx, 1            # rdx ← 8 × rdx ≥ 16
mov	[rdi], rsi
mov	[rdi + rdx], rsi
neg	rdx
mov	[rcx + rdx], rsi
mov	[rcx], rsi
ret

# basically a repeat of under32, but with 4-byte chunks instead of 8
.under16:
cmp	edx, 4
jb	.under4

lea	rcx, [rdi + rdx - 4]
mov	[rdi], esi
and	edx, 8
shr	edx, 1          # rdx ← 4 × rdx ≥ 8
mov	[rdi + rdx], esi
neg	rdx
mov	[rcx + rdx], esi
mov	[rcx], esi
ret

.under4:
cmp	edx, 1
jb	.done
mov	[rdi], sil
jbe	.done
mov	[rdi + 1], sil
mov	[rdi + rdx - 1], sil

.done:
ret

# todo apparently stosq is worth it for very large sizes (tipping point is >800 <4096) on non-erms chips.  Investigate.  (At least, it's better than the above loop; maybe an even-more-unrolled one beats it?)
.ifdef erms
.huge:
mov	[rdi], rsi
mov	[rdi +  8], rsi
mov	[rdi + 16], rsi
mov	[rdi + 24], rsi
mov	rcx, rdx
mov	r8, rdi
add 	rdi, 31
and	rdi, ~31
sub	r8, rdi
add	rcx, r8
xchg	rax, rsi
rep	stosb
mov	rax, rsi
ret
.endif
