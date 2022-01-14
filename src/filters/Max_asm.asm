global Max_asm

section .rodata
;Creamos mascaras:
bluemask: times 4 dd 0x000000FF ;nos saca el color azul
greenmask: times 4 dd 0x0000FF00; saca el color verde
redmask: times 4 dd 0x00FF0000 ; saca el color rojo
whitemask: times 4 dd 0xFFFFFFFF ;para llenar la imagen de blanco
imask1: dw  0x0000,0x0000, 0x0004, 0x0000,0x0008 ,0x0000,0x000c, 0x0000 
imask2: dw  0x0001,0x0000, 0x0005, 0x0000,0x0009 ,0x0000,0x000d, 0x0000 
imask3: dw  0x0002,0x0000, 0x0006, 0x0000,0x000a ,0x0000,0x000e, 0x0000 
imask4: dw  0x0003,0x0000, 0x0007, 0x0000,0x000b ,0x0000,0x000f, 0x0000 
dmask: dw 0x0000, 0x0001, 0x0000, 0x0001 ,0x0000, 0x0001, 0x0000, 0x0001  
amask: times 4 dd 0xFF000000
section .text


;rdi -> *src
;rsi -> *dst
;edx -> width
;ecx -> height
;r8d -> src_row_size
;r9d -> dst_row_size


Max_asm:
;armamos el stack
push rbp
mov rbp, rsp
push rbx
push r12
push r13
push r14
push r15
sub rsp, 8



; arranca programa:

;primero volvemos la imagen a color blanco en el destino:
mov rbx, rsi                ;rbx = *dst

movdqu xmm4, [whitemask]    ;xmm4 = whitemask = |FFFFFFFF|FFFFFFFF|FFFFFFFF|FFFFFFFF|
mov  r11d,edx               ;r11d = width
shr r11d,2                  ;r11d = width/4
mov  r12d,ecx               ;r12d = height
mov r13d, r12d
dec r13d

mov r15d, r11d
dec r15d

xor rax, rax                ;rax = contador = 0
.loopFilaBlanco:            ;comenzamos el loop por filas
xor r14,r14                 ;r14 = contador = 0

    .loopColumnaBlanco:     ;comenzamos el loop por columnas

    cmp rax, 0
    je .pinta
    cmp eax, r13d
    je .pintaUltima

    cmp r14d, r15d
    je .pintaBorde
    jmp .noPinta

    .pintaBorde:
    movdqu [rbx+3], xmm4      ;ponemos los pixeles en blanco en el destiino
    jmp .noPinta
    .pintaUltima:
    movdqu [rbx], xmm4   
    jmp .noPinta
    .pinta:
    movdqu [rbx], xmm4   
    cmp r14d, r15d
    je .pintaBorde

       ;ponemos los pixeles en blanco en el destiino

    .noPinta:
    add rbx,16              ;avanzamos a los siguientes cuatro pixeles
    inc r14d                ;avanzamos una columna
    cmp r14d, r11d          ;si aun no llegamos a la ultima columna seguimos iterando
    jne .loopColumnaBlanco

                            ;si terminamos con la ultima fila de esa columna...
inc eax                     ;avanzamos una fila
cmp eax, r12d               ;si aun no es la ultima fila seguimos iterando
jne .loopFilaBlanco
;si ya pasamos la ultima columna de la ultima fila terminamos. 





;conservo width y height ara poder hacer las divs
movdqu xmm4, [bluemask]     ; xmm4 = bluemask
movdqu xmm5, [greenmask]    ; xmm5 = greenmask
movdqu xmm6, [redmask]      ; xmm6 = redmask
movdqu xmm1, [dmask]
shr ecx, 1                  ; ecx = height/2
dec ecx                     ; ecx = (height/2) -1

shr edx, 1                  ;edx = width/2
dec edx                     ;edx = (width/2)-1


xor rbx, rbx
mov ebx, r8d

;necesitamos un contador de filas y columnas
;contador Filas

.loopFilas:



; el contador arranca en 0 hasta height/2-1
;contador Columnas
mov r11d,edx
.loopCol:
; arranca en 0 suma de a dos hasta  width/2-1
;cuando llega al final le suma al contador de col el src_row_size+8


pxor xmm12, xmm12 ;maximo global en valor
movdqu xmm11, [amask] ; max global en rgba
xor r14,r14
mov r14d, 4         ; ponemos el contador en 4
xor r8,r8
;este loop recorre de a 4 pixeles y corre 4 veces 
;evaluando los pixeles de la matriz 4x4
.loop:

;----------------Buscamos max entre los 4 de ahora --------------------------
movdqu xmm0, [rdi + r8]

movdqu xmm7, xmm0 
pand xmm7, xmm4     ; sacamos el color azul en xmm7

movdqu xmm8, xmm0
pand xmm8, xmm5     ; sacamos e lcolor verde en xmm8
psrldq xmm8, 1      ; lo movemos a la parte menos significativa
movdqu xmm9, xmm0 
pand xmm9, xmm6     ; sacamos e lcolor rojo en xmm9
psrldq xmm9, 2      ; lo movemos a la parte menos significativa

paddd xmm7, xmm8    ; sumamos los valores y quedan en xmm7
paddd xmm7, xmm9    ;|P4|P3|P2|P1|

movdqu xmm8, xmm7   ; ahora la suma de los valores esta en xmm8 
                    ;|***|***|P2|P1|
psrldq xmm8,8       ;|***|***|P4|P3| 

pmaxud xmm8,xmm7
movdqu xmm9,xmm8    ;|***|***|max(P2,P4)|max(P2,P4)|    
psrldq xmm8,4   
pmaxud xmm8,xmm9    ;|***|***|***|max| => posible candidato a max global

;max encontrado en xmm8

;--------------------- Buscamos el max con rgba -----------------------------


    pshufd xmm8,xmm8,0  ;|max |max |max |max|
    movdqu xmm15, xmm8
    por xmm8, xmm1
    pcmpeqw xmm8,xmm7   ;comparamos cada suma de xmm7 con la suma max que esta en xmm8 |0|-1|0|-1|0|-1||-1|


    ;-------------------buscamos los cuatro bytes indices para formar el pshufb ---------------

    pcmpeqw xmm2, xmm2 ;xmm8= |111...111|
    pxor xmm2, xmm8

    movdqu xmm3, xmm8
    movdqu xmm13, [imask1]
    pand xmm8,xmm13     ;nos queda el xmm con los indices |0|3|0|2|0|1|0
    por xmm8,xmm2
    PHMINPOSUW xmm8,xmm8 ; nos queda el indice menor en la parte baja de xmm8 = |*|*|*|indice a parte con menor|
    movdqu xmm14, xmm8
    movdqu xmm8, xmm3
    movdqu xmm13, [imask2]
    pand xmm8,xmm13     ;nos queda el xmm con los indices |4|0|2|0
    por xmm8,xmm2
    PHMINPOSUW xmm8,xmm8 
    
    punpcklbw xmm14, xmm8

    movdqu xmm8, xmm3
    movdqu xmm13, [imask3]
    pand xmm8,xmm13     ;nos queda el xmm con los indices |4|0|2|0
    por xmm8,xmm2
    PHMINPOSUW xmm8,xmm8 
    movdqu xmm9, xmm8

    movdqu xmm8, xmm3
    movdqu xmm13, [imask4]
    pand xmm8,xmm13     ;nos queda el xmm con los indices |4|0|2|0
    por xmm8,xmm2
    PHMINPOSUW xmm8,xmm8 

    punpcklbw xmm9, xmm8

    punpcklwd xmm14,xmm9

    movdqu xmm8, xmm14

    pshufd xmm8,xmm8,0 ; xmm8 = |i|i|i|i|

    movdqu xmm14, xmm0

    pshufb xmm14, xmm8 ; xmm14 = |argb|argb|argb|argb| => candidato a max global en argb
    
;--------------------- aplicamos el nuevo max (se mantiene o cambia)----------
    movdqu xmm7, xmm15
    pcmpgtd xmm7, xmm12 ; si xmm7<=xmm12 => xmm7 = |0|0|0|0|. SINO: xmm7 =|-1|-1|-1|-1|

    ;aplicamos xmm7 a xmm14 y a xmm15
    pand xmm14,xmm7
    pand xmm15, xmm7
    ;aplicar xmm7 negado a xmm12(max g) y xmm11 (ma g argb)
    pcmpeqb xmm8, xmm8 ;xmm8= |111...111|
    pxor xmm7,xmm8 ; volteamos
    pand xmm11,xmm7
    pand xmm12, xmm7
    ;hacemos or entre (xmm14 y xmm11 , xmm15 y xmm12)
    por xmm11, xmm14
    por xmm12, xmm15


    

.seguir:


;sino que siga


add r8, rbx
dec r14d
cmp r14d, 0 
jg .loop

; pone el pixel con la suma maxima en la posicion de 2x2
mov r9, rsi
add r9, rbx
movd [r9 + 4],xmm11
movd  [r9 + 8],xmm11
add r9, rbx
movd  [r9 + 4],xmm11
movd  [r9 + 8],xmm11


    


; cierra loop mas chico
;chequea si tiene que cambiar de fila o no
dec r11d
cmp r11d,0
je .cambiaFila
;si no cambia de fila  se mueve 2 pixeles
add rdi,8
add rsi,8
jmp .loopCol
;si cambia de fila chequea no estar al final de la imagen
.cambiaFila:
dec ecx
cmp ecx,0
; cierra loop mas grande
je .final
;si no esta al final de la imagen se mueve 4 pixeles y baja una fila
add rdi,16
add rdi,rbx
add rsi,16
add rsi,rbx
jmp .loopFilas


; ;desarmamos el stack
.final:
add rsp,8
pop r15
pop r14
pop r13
pop r12
pop rbx
pop rbp

ret
