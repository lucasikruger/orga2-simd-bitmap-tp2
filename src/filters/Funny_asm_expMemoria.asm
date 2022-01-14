extern Funny_c
global Funny_asm

section .rodata

bluemask: times 4 dd 0x000000FF
greenmask: times 4 dd 0x0000FF00
redmask: times 4 dd 0x00FF0000
amask: times 4 dd 0xFF000000
mask10: times 4 dd 0x0000000A
mask100: times 4 dd 0x00000064
mask1000: times 4 dd 0x000003E8
maskj: dd 0x00000000, 0x00000001, 0x00000002, 0x00000003 ;puede ser al reves
;maskj: dd 0x00000003, 0x00000002, 0x00000001, 0x00000000 ;puede ser al reves

section .text
;rdi -> *srcj-i
;rsi -> *dst
;edx -> width
;ecx -> height
;r8d -> src_row_size
;r9d -> dst_row_size
Funny_asm:

 push rbp
 mov rbp, rsp
 push rbx
 push r12
;programa:

xor r9d, r9d
xor r8d, r8d


movdqu xmm6, [mask10]
movdqu xmm15, [mask1000]

CVTDQ2PS xmm6, xmm6
CVTDQ2PS xmm15, xmm15
;CVTDQ2PS xmm7, xmm7 


;programa:
;loop

.loopFilas: ; j = r8d | i = r9d

    cmp r9d, ecx
    je .fin
    ;add rsi, 16

.loopColumnas:

    cmp r8d, edx
    je .seguirLoopFilas

    movdqu xmm1, [bluemask]
    movdqu xmm2, [greenmask]
    movdqu xmm3, [redmask]
    movdqu xmm4, [amask]
    movdqu xmm5, [maskj]
    movdqu xmm7, [mask100]

;algoritmo

;codigo
    movdqu xmm0, [rdi]

    ;--funny_r--
    mov ebx, r8d 
    sub ebx,r9d ; ebx =  (j-i)
    pxor xmm8, xmm8
    movd xmm8 , ebx
    pshufd xmm8,xmm8,0 ; xmm8 = |j-i|j-i|j-i|j-i|
    
    paddd xmm8,xmm5 ;xmm8 = |j-i|j+1-i|j+2-i|j+3-i|
    pabsd xmm8,xmm8 ; abs(xmm8)

    CVTDQ2PS xmm8, xmm8 ; convertimos a float para poder sacar la raiz cuadrada
    sqrtps xmm8, xmm8 ;xmm8 = |sqrt(j-i)|sqrt(j+1-i)|sqrt(j+2-i)|sqrt(j+3-i)|

    CVTDQ2PS xmm7, xmm7
    mulps xmm8, xmm7 ;xmm8 = |sqrt(j-i)*100|sqrt(j+1-i)*100|sqrt(j+2-i)*100|sqrt(j+3-i)*100|

    CVTTPS2DQ xmm8, xmm8
    CVTTPS2DQ xmm7, xmm7 

    pand xmm8, xmm1



    ;--funny_g--
    mov ebx, r9d 
    sub ebx,r8d ; ebx =  (i-j)
    pxor xmm9, xmm9
    movd xmm9 , ebx
    pshufd xmm9,xmm9,0 ; xmm9 = |i-j|i-j|i-j|i-j|
    psubd xmm9,xmm5 ;xmm9 = |i-(j)|i-(j+1)|i-(j+2)|i-(j+3)| = |i-j|i-j-1|i-j-2|i-j-3| 

    pabsd xmm9, xmm9

    CVTDQ2PS xmm9, xmm9

    mulps xmm9, xmm6

    
    mov ebx, r9d
    add ebx, r8d
    inc ebx     ; ebx = (i+j+1)
    pxor xmm10, xmm10
    movd xmm10 , ebx
    pshufd xmm10,xmm10,0 ; xmm10 = |i+j+1|i+j+1|i+j+1|i+j+1|
    paddd xmm10,xmm5 ;xmm8 = |j+i+1|j+1+i+1|j+2+i+1|j+3+i+1|
    CVTDQ2PS xmm10, xmm10

    CVTDQ2PS xmm7, xmm7
    divps xmm10, xmm7

    divps xmm9, xmm10 

    CVTTPS2DQ xmm9, xmm9
    CVTTPS2DQ xmm10, xmm10
    CVTTPS2DQ xmm7, xmm7


    pand xmm9, xmm1

    ;--funny_b--
    pxor xmm10, xmm10
    mov ebx, r9d
    shl ebx, 1
    add ebx, 100
    movd xmm10 , ebx ; xmm10 = |0|0|0|i*2+100|
    pshufd xmm10,xmm10,0 ; xmm10 = |i*2+100|i*2+100|i*2+100|i*2+100|
    
    pxor xmm11, xmm11
    mov ebx, r8d
    movd xmm11 , ebx ; xmm11 = |0|0|0|j|
    pshufd xmm11, xmm11, 0 ;xmm11 = |j|j|j|j|
    paddd xmm11,xmm5 ;xmm11 = |j|j+1|j+2|j+3|
    pslld xmm11, 1 ;xmm11 = |j*2|(j+1)*2|(j+2)*2|(j+3)*2|
    paddd xmm11, xmm7 ;xmm11 = |j*2+100|(j+1)*2+100|(j+2)*2+100|(j+3)*2+100|

    CVTDQ2PS xmm10, xmm10
    CVTDQ2PS xmm11, xmm11
    mulps xmm10, xmm11 ;xmm10 = |(i*2+100)*(j*2+100)|(i*2+100)*((j+1)*2+100)|(i*2+100)*((j+2)*2+100)|(i*2+100)*((j+3)*2+100)|


    sqrtps xmm10, xmm10 ;xmm10 = |sqr((i*2+100)*(j*2+100))|sqr((i*2+100)*((j+1)*2+100))|sqr((i*2+100)*((j+2)*2+100))|sqr((i*2+100)*((j+3)*2+100))|

    mulps xmm10, xmm6 ;xmm10 = |10*sqr((i*2+100)*(j*2+100))|10*sqr((i*2+100)*((j+1)*2+100))|10*sqr((i*2+100)*((j+2)*2+100))|10*sqr((i*2+100)*((j+3)*2+100))|
    
    CVTTPS2DQ xmm10, xmm10
    CVTPS2DQ xmm11, xmm11
    pand xmm10, xmm1

    
    ;armamos el pixel resultado
    ; rdi = |src_matrix[i][j+0] | src_matrix[i][j+1] | src_matrix[i][j+2] | src_matrix[i][j+3] |
    ;funny_r = xmm8 - funny_g = xmm9 - funny_b = xmm10
    ; xmm1 = [bluemask] - xmm2 = [greenmask] - xmm3 = [redmask]

    ;--b--
    movdqu xmm11, xmm0
    pand xmm11, xmm1

    psrld xmm11, 1
    psrld xmm10, 1

    PADDUSB xmm10, xmm11 ;esto es de a word osea 2 byte, asumimos que nunca nos pasaremos de este numero ya que va de 0 a 65536. (datos sqrt(10000*10000)=1000)

    pand xmm10, xmm1 ; dejamos con la mascara lo que nos interesa
    

    ;--g--
    
    movdqu xmm11, xmm0
    pand xmm11, xmm2   ;xmm11 = |00g0|00g0|00g0|00g0|

    psrldq xmm11, 1 ;shifteamos para que el green quede en la parte baja - xmm11 = ;|000g|000g|000g|000g|

    psrld xmm11, 1 ;dividimos por 2
    psrld xmm9, 1   ;idem

    PADDUSB xmm9, xmm11 ;esto es de a word osea 2 byte, asumimos que nunca nos pasaremos de este numero ya que va de 0 a 65536. (datos sqrt(10000*10000)=1000)
    pslldq xmm9, 1 ; volvemos el shift
    
    pand xmm9, xmm2 ; dejamos con la mascara lo que nos interesa
    
    por xmm10, xmm9 ; unimos azul y verde 

    ;--r--

        
    movdqu xmm11, xmm0
    pand xmm11, xmm3   ;xmm11 = |0r00|0r00|0r00|0r00|

    psrldq xmm11, 2 ;shifteamos para que el red quede en la parte baja - xmm11 = ;|000r|000r|000r|000r|

    psrld xmm11, 1 ;dividimos por 2
    psrld xmm8, 1   ;idem

    PADDUSB xmm8, xmm11 ;esto es de a word osea 2 byte, asumimos que nunca nos pasaremos de este numero ya que va de 0 a 65536. (datos sqrt(10000*10000)=1000)
    pslldq xmm8, 2 ; volvemos el shift

    pand xmm8, xmm3 ; dejamos con la mascara lo que nos interesa
    
    por xmm10, xmm8 ; unimos azul y verde con rojo


    ;--a--

    por xmm10, xmm4 ;agregamos el alpha con 255
    
    movdqu [rsi], xmm10

;fin loop columnas
    add r8d, 4
    add rdi, 16
    add rsi, 16
    jmp .loopColumnas

.seguirLoopFilas:

    xor r8d, r8d
    add r9d, 1
    jmp .loopFilas

    .fin:
; ;desarmamos el stack
; pop rbp
; La proxima linea debe ser reemplazada por el codigo asm
;jmp Funny_c
pop r12
pop rbx
pop rbp
ret
