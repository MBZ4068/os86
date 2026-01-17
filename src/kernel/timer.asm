[BITS 16]

%include "sys_mmc.inc"

time_isr:           ;定时器中断
    mov [cs:save_sp],sp
    mov sp,clock_stack_bottom
    push ax
    push ds

    mov ax, cs
    mov ds, ax

    inc word [cs:tick_count]

    mov ax,[cs:tick_count]
    and al,0x07           ;间隔八个周期
    cmp al,0
    jz .refresh_cursor
    .time_end:
        mov al, 0x20
        out 0x20, al
        pop ds
        pop ax
        iret

    .refresh_cursor:
        mov ax,0300h
        int 60h
        jmp .time_end

tick_count dw 0
save_sp  dw 0x0000