# based on https://msrc-blog.microsoft.com/2021/01/11/building-faster-amd64-memset-routines/
.globl fast_memset
.intel_syntax noprefix
fast_memset:
# dst: rdi
# c: sil
# l: rdx

mov rax, rdi # todo would it be more efficient re codesize to use rax?

movzx esi, sil
imul esi, 0x01010101
vmovd xmm0, esi
vbroadcastss xmm0, xmm0

cmp rdx, 64
jb under64

# big
movups [rdi], xmm0
lea rsi, [rdi + 16]
and rsi, ~15
sub rdi, rsi
add rdx, rdi
neg rdi
add rdi, rsi

cmp rdx, 64
jb trailing

# todo this is wrong
bigloop:
movaps [rsi], xmm0
movaps [rsi + 16], xmm0
movaps [rsi + 32], xmm0
movaps [rsi + 48], xmm0
add rsi, 64
sub rdx, 64
cmp rdx, 64
jae bigloop

#add rsi, 16
#sub rsi, 64
trailing:
# trailing <64 bytes
lea rcx, [rsi + rdx - 16] # last (unaligned) store
lea rdx, [rsi + rdx - 48] # last 3 aligned stores.  Overwrite rdx because we don't need it anymore
and rdx, ~15
movaps [rdx], xmm0
movaps [rdx + 16], xmm0
movaps [rdx + 32], xmm0
movups [rcx], xmm0
ret

under64:
cmp rdx, 16
jb under16

# 16-63 bytes
lea rcx, [rdi + rdx - 16]
movups [rdi], xmm0
and rdx, 32
shr rdx, 1            # rdx ← 16 × rdx ≥ 32
movups [rcx], xmm0
movups [rdi + rdx], xmm0
neg rdx
movups [rcx + rdx], xmm0
ret

# basically a repeat of under64, but with 4-byte chunks instead of 16
under16:
cmp rdx, 4
jb under4

lea rcx, [rdi + rdx - 4]
mov [rdi], esi
and rdx, 8
shr rdx, 1          # rdx ← 4 × rdx ≥ 8
mov [rcx], esi
mov [rdi + rdx], esi
neg rdx
mov [rcx + rdx], esi
ret

under4:
jz done
mov [rdi], sil
cmp rdx, 1
je done
mov [rdi + 1], sil
mov [rdi + rdx - 1], sil

done:
ret
