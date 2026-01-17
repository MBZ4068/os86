[BITS 16]
%include "sys_mmc.inc"
Error_Manage:
    mov [cs:save_sp],sp
    mov sp,otherirq_stack_bottom

    push cx
    push bx
    push si
   
    mov  al, ah
    and  al, 00001111b
    call Num_ASCII
    push ax
    xor  bx, bx
    mov  bl, al
    mov  ah, 07h
    mov  cl, 0
    int  60h
    pop  ax
    
    mov  al, ah
    and  al, 11110000b
    mov  cl, 4
    shr  al, cl
    call Num_ASCII

    push ax
     xor bx, bx
    mov bl, al
    mov ah, 07h
    dec dl
    mov cl, 0
    int 60h
    pop ax
    
    pop si
    pop bx
    pop cx
    ret

Num_ASCII:
   cmp AL, 9
   jg  To_16
   add AL, "0"
   ret
To_16:
   ADD AL, 37H
   ret



save_sp  dw 0x0000