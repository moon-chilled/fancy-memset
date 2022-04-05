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

#ifndef MEMSET
#define MEMSET fancy_memset_avx2
#endif

.globl MEMSET
.p2align 4
MEMSET:
# dst: rdi
# c: sil
# l: rdx

mov	rax, rdi # todo would it be more efficient re codesize to use rax?

movd	xmm0, esi
vpbroadcastb ymm0, xmm0
#vpbroadcastb ymm0, esi - break in case of avx512

cmp	rdx, 128
jb	.Lunder128

#ifdef erms
cmp	rdx, 256 * 1024 #~l2
jae	.Lhuge
#endif

# big
vmovups	[rdi], ymm0
lea	rsi, [rdi + 32]
and	rsi, ~31
sub	rdi, rsi
add	rdx, rdi

lea	rcx, [rsi + rdx - 96] # last 3 aligned stores
and	rcx, ~31
lea	r8,  [rsi + rdx - 32]  # last (unaligned) store

cmp	rdx, 128
jl	.Ltrailing

.Lbigloop:
vmovaps	[rsi], ymm0
vmovaps	[rsi + 32], ymm0
vmovaps	[rsi + 64], ymm0
vmovaps	[rsi + 96], ymm0
add	rsi, 128
cmp	rsi, rcx
jb	.Lbigloop

.Ltrailing:
# trailing <128 bytes
vmovaps	[rcx], ymm0
vmovaps	[rcx + 32], ymm0
vmovaps	[rcx + 64], ymm0
vmovups	[r8], ymm0
vzeroupper
ret

.Lunder128:
cmp	edx, 64
jb	.Lunder64
# 64-127 bytes
lea	rcx, [rdi + rdx - 32]
and	edx, 64
vmovups	[rdi], ymm0
shr	edx, 1            # rdx ← 32 × rdx ≥ 64
vmovups	[rdi + rdx], ymm0
neg	rdx
vmovups	[rcx + rdx], ymm0
vmovups	[rcx], ymm0
vzeroupper
ret

.Lunder64:
cmp	edx, 32
jb	.Lunder32
# 32-63 bytes
vmovups	[rdi], ymm0
vmovups	[rdi + rdx - 32], ymm0
vzeroupper
ret


.Lunder32:
vzeroupper
cmp	edx, 16
jb	.Lunder16
movups	[rdi], xmm0
movups	[rdi + rdx - 16], xmm0
ret

# basically a repeat of under128, but with 4-byte chunks instead of 32
.Lunder16:
cmp	edx, 4
jb	.Lunder4

movzx	esi, sil
imul	esi, 0x01010101
lea	rcx, [rdi + rdx - 4]
mov	[rdi], esi
and	edx, 8
shr	edx, 1          # rdx ← 4 × rdx ≥ 8
mov	[rdi + rdx], esi
neg	rdx
mov	[rcx + rdx], esi
mov	[rcx], esi
ret

.Lunder4:
cmp	edx, 1
jb	.Ldone
mov	[rdi], sil
jbe	.Ldone
mov	[rdi + 1], sil
mov	[rdi + rdx - 1], sil

.Ldone:
ret

# todo apparently stosq is worth it for very large sizes (tipping point is >800 <4096) on amd chips.  Investigate.  (At least, it's better than the above loop; maybe an even-more-unrolled one beats it?)
#ifdef erms
.Lhuge:
vmovups	[rdi], ymm0
vmovups	[rdi + 32], ymm0
mov	rcx, rdx
mov	r8, rdi
add	rdi, 63
and	rdi, ~63
sub	r8, rdi
add	rcx, r8
xchg	rax, rsi
rep	stosb
mov	rax, rsi
vzeroupper
ret
#endif
