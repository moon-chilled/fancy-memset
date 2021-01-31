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
# ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# based on https://msrc-blog.microsoft.com/2021/01/11/building-faster-amd64-memset-routines/
.intel_syntax noprefix

.globl fancy_memset_sse2
.p2align 4
fancy_memset_sse2:
# dst: rdi
# c: sil
# l: rdx

mov	rax, rdi # todo would it be more efficient re codesize to use rax?

movzx	esi, sil
imul	esi, 0x01010101
movd	xmm0, esi
pshufd	xmm0, xmm0, 0

cmp	rdx, 64
jb	.under64

.ifdef erms
cmp	rdx, 800
jae	.huge
.endif

# big
movups	[rdi], xmm0
lea	rsi, [rdi + 16]
and	rsi, ~15
sub	rdi, rsi
add	rdx, rdi

lea	rcx, [rsi + rdx - 48] # last 3 aligned stores
and	rcx, ~15
lea	r8, [rsi + rdx - 16]  # last (unaligned) store

cmp	rdx, 64
jb	.trailing

.bigloop:
movaps	[rsi], xmm0
movaps	[rsi + 16], xmm0
movaps	[rsi + 32], xmm0
movaps	[rsi + 48], xmm0
add	rsi, 64
cmp	rsi, rcx
jb	.bigloop

.trailing:
# trailing <64 bytes
movaps	[rcx], xmm0
movaps	[rcx + 16], xmm0
movaps	[rcx + 32], xmm0
movups	[r8], xmm0
ret

.under64:
cmp	edx, 16
jb	.under16

# 16-63 bytes
lea	rcx, [rdi + rdx - 16]
and	edx, 32
movups	[rdi], xmm0
shr	edx, 1            # rdx ← 16 × rdx ≥ 32
movups	[rdi + rdx], xmm0
neg	rdx
movups	[rcx + rdx], xmm0
movups	[rcx], xmm0
ret

# basically a repeat of under64, but with 4-byte chunks instead of 16
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
movups	[rdi], xmm0
movups	[rdi + 16], xmm0
movups	[rdi + 32], xmm0
movups	[rdi + 48], xmm0
mov	rcx, rdx
mov	r8, rdi
add 	rdi, 63
and	rdi, ~63
sub	r8, rdi
add	rcx, r8
xchg	rax, rsi
rep	stosb
mov	rax, rsi
ret
.endif
