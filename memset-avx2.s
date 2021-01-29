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

.globl fancy_memset_avx2
.p2align 4
fancy_memset_avx2:
# dst: rdi
# c: sil
# l: rdx

mov	rax, rdi # todo would it be more efficient re codesize to use rax?

movzx	esi, sil
imul	esi, 0x01010101
movd	xmm0, esi
vpbroadcastb ymm0, xmm0

cmp	rdx, 128
jb	.under128

.ifdef erms
cmp	rdx, 800
jae	.huge
.endif

# big
vmovups	[rdi], ymm0
lea	rsi, [rdi + 32]
and	rsi, ~31
sub	rdi, rsi
add	rdx, rdi

lea	rcx, [rsi + rdx - 96] # last 3 aligned stores
and	rcx, ~31
lea	r8, [rsi + rdx - 32]  # last (unaligned) store

cmp	rdx, 128
jb	.trailing

.bigloop:
vmovaps	[rsi], ymm0
vmovaps	[rsi + 32], ymm0
vmovaps	[rsi + 64], ymm0
vmovaps	[rsi + 96], ymm0
add	rsi, 128
cmp	rsi, rcx
jb	.bigloop

.trailing:
# trailing <128 bytes
vmovaps	[rcx], ymm0
vmovaps	[rcx + 32], ymm0
vmovaps	[rcx + 64], ymm0
vmovups	[r8], ymm0
vzeroupper
ret

.under128:
cmp	rdx, 32
jb	.under32

# 32-127 bytes
lea	rcx, [rdi + rdx - 32]
and	rdx, 64
vmovups	[rdi], ymm0
shr	rdx, 1            # rdx ← 32 × rdx ≥ 64
vmovups	[rcx], ymm0
vmovups	[rdi + rdx], ymm0
neg	rdx
vmovups	[rcx + rdx], ymm0
vzeroupper
ret

.under32:
cmp	rdx, 16
jb	.under16
movups	[rdi], xmm0
movups	[rdi + rdx - 16], xmm0
vzeroupper
ret

# basically a repeat of under128, but with 4-byte chunks instead of 32
.under16:
cmp	rdx, 4
jb	.under4

lea	rcx, [rdi + rdx - 4]
mov	[rdi], esi
and	rdx, 8
shr	rdx, 1          # rdx ← 4 × rdx ≥ 8
mov	[rcx], esi
mov	[rdi + rdx], esi
neg	rdx
mov	[rcx + rdx], esi
vzeroupper
ret

.under4:
cmp	rdx, 1
jb	.done
mov	[rdi], sil
jbe	.done
mov	[rdi + 1], sil
mov	[rdi + rdx - 1], sil

.done:
vzeroupper
ret

# todo apparently stosq is worth it for very large sizes (tipping point is >800 <4096) on amd chips.  Investigate.  (At least, it's better than the above loop; maybe an even-more-unrolled one beats it?)
.ifdef erms
.huge:
vzeroupper
xchg	rax, rsi
mov	rcx, rdx
rep	stosb
mov	rax, rsi
ret
.endif
