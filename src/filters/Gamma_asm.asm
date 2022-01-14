extern Gamma_c
global Gamma_asm

section .rodata

bluemask: times 4 dd 0x000000FF
greenmask: times 4 dd 0x0000FF00
redmask: times 4 dd 0x00FF0000
mask255: times 4 dd 0x000000FF
amask: times 4 dd 0xFF000000

section .text
;rdi -> *src
;rsi -> *dst
;edx -> width (en pixeles)
;ecx -> height (en pixeles)
;r8d -> src_row_size
;r9d -> dst_row_size

Gamma_asm:
    push rbp
    mov rbp, rsp

    xor r9d, r9d
    xor r8d, r8d

; ;programa:
;loop

.loopFilas: 

    cmp r9d, ecx
    je .fin
    ;add rsi, 16
    xor r8d, r8d
    add r9d, 1

.loopColumnas:

    cmp r8d, edx
    je .loopFilas
;algoritmo
    movdqu xmm0, [rdi]
    movdqu xmm1, [bluemask]
    movdqu xmm2, [greenmask]
    movdqu xmm3, [redmask]
    movdqu xmm4, [mask255]
    movdqu xmm15, [amask]

    pxor xmm10, xmm10

    CVTDQ2PS xmm4, xmm4
    ;color azul
    movdqu xmm5, xmm0
    pand xmm5, xmm1
    CVTDQ2PS xmm5, xmm5
    mulps xmm5, xmm4
    sqrtps xmm5, xmm5
    CVTPS2DQ xmm5, xmm5
    movdqu xmm10, xmm5
    ;color verde


    movdqu xmm6, xmm0
    pand xmm6, xmm2
    psrldq xmm6, 1 
    CVTDQ2PS xmm6, xmm6
    mulps xmm6, xmm4
    sqrtps xmm6, xmm6
    CVTPS2DQ xmm6, xmm6
    pslldq xmm6, 1
    por xmm10, xmm6

    ;color rojo

    movdqu xmm7, xmm0
    pand xmm7, xmm3
    psrldq xmm7, 2
    CVTDQ2PS xmm7, xmm7
    mulps xmm7, xmm4
    sqrtps xmm7, xmm7
    CVTPS2DQ xmm7, xmm7
    
    pslldq xmm7, 2
    por xmm10, xmm7
    por xmm10, xmm15


    movdqu [rsi], xmm10



;fin loop columnas

    add r8d, 4
    add rdi, 16
    add rsi, 16
    jmp .loopColumnas


    .fin:
;desarmamos el stack
  pop rbp

; La proxima linea debe ser replazada por el codigo asm
;jmp Gamma_c

    ret
