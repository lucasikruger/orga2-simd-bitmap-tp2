extern Broken_c
global Broken_asm
;rdi -> *src
;rsi -> *dst
;edx -> width
;ecx -> height
;r8d -> src_row_size
;r9d -> dst_row_size
Broken_asm:
;armamos el stack

; mov rbp, rsp
; push rbp
; ;programa:


; ;desarmamos el stack
; pop rbp

; La proxima linea debe ser replazada por el codigo asm
jmp Broken_c

ret
