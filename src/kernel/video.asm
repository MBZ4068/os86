[BITS 16]
%include "sys_mmc.inc"


org video_setoff  ; 使用宏定义的地址


;kernel_setoff 内核加载偏移地址
;han_setoff 汉显缓存区偏移地址
;irq_setoff 中断加载偏移地址   
;sysbuf_setoff 系统缓存区偏移地址

;各模块栈顶与栈底地址定义
;kernel_stack_top 内核栈顶
;kernel_stack_bottom 内核栈底
;clock_stack_top 时钟栈顶
;clock_stack_bottom 时钟栈底
;keyboard_stack_top 键盘栈顶
;keyboard_stack_bottom 键盘栈底
;disk_stack_top 磁盘栈顶
;disk_stack_bottom 磁盘栈底
;video_stack_top 视频栈顶
;video_stack_bottom 视频栈底
;otherirq_stack_top 其他中断栈顶
;otherirq_stack_bottom 其他中断栈底
;app_stack_top 应用程序栈顶
;app_stack_bottom 应用程序栈底



video_service: ;汉显
    ;汉显这里出错了！
    
    mov [cs:save_sp],sp
    mov sp,video_stack_bottom
    push ds
    push es
    push ax
    mov ax,cs
    mov ds,ax
    mov es,ax
    pop ax

    push si
    push di
    push ax
    push bx
    push dx
    push cx

    ;功能号判断
    cld
    push bx
    mov  bl, ah
    xor  bh, bh
    shl  bx, 1
    mov  si, bx
    pop  bx
    jmp  word [cs:function_num_list+si]
    
    


set_cursor_shape: ;00 设置光标形状
    ;AL 选择光标形状
    ;光标字模：
    ;00 _
    ;01 厚的_
    ;02 =
    ;03 4x4方块
    ;04 实方块
    ;05 虚方块
    ;06 空方块
    ;07 |
    ;08 <
    
    mov byte [cs:active_cursor],al
    jmp hanxian_end

    


set_cursor_weizhi: ;01 设置光标位置 该坐标是显存坐标
    ;dx 位置
    mov word [video_mem_cursor_coord],dx
    jmp hanxian_end

get_cursor:        ;02 h获取光标信息
show_cursor:       ;03 显示光标
    
    mov dx,  [cs:video_mem_cursor_coord]  ;在显存中的位置  （以8x8像素分割成80x25）


    cmp dx,  0xffff
    jnz .read_cursor
    jmp hanxian_end

    .read_cursor:
        
        ;DX 为坐标
        mov ax, 0xb800
        mov ds, ax
        mov ax, cs
        mov es, ax

        xor  ax, ax
        mov  al, dl
        xchg dl, dh
        xor  dh, dh
        mov  si, dx
        shl  si, 1
        mov  si,word [ds:video_mem_rowlist+si]
        add  si, ax     
        xor bx,bx                  
        mov  bl,byte [ds:active_cursor]
        shl  bx,1
        shl  bx,1
        shl  bx,1
        add  bx, cursor_typehead
        mov  di,  bx

        mov  dx, 80

    .read_to_cursor_typehead:
        ;绘制光标1，2行
        
        mov al,byte [ds:si]
        mov bh,al
        mov al,byte [ds:si+0x2000]
        mov bl,al
        
        xor bx, word [es:di]
        mov byte [ds:si],bh
        mov byte [ds:si+0x2000],bl

        add si ,dx
        add di ,2

        ;绘制光标3，4行
        mov al,byte [ds:si]
        mov bh,al
        mov al,byte [ds:si+0x2000]
        mov bl,al
        
        xor bx, word [es:di]
        mov byte [ds:si],bh
        mov byte [ds:si+0x2000],bl

        add si ,dx
        add di ,2

        ;绘制光标5，6行

        mov al,byte [ds:si]
        mov bh,al
        
        mov al,byte [ds:si+0x2000]
        mov bl,al
        
        xor bx, word [es:di]
        mov byte [ds:si],bh
        mov byte [ds:si+0x2000],bl

        add si ,dx
        add di ,2

        ;绘制光标7，8行
        
        mov al,byte [ds:si]
        mov bh,al
        mov al,byte [ds:si+0x2000]
        mov bl,al
        xor bx, word [es:di]
        mov byte [ds:si],bh
        mov byte [ds:si+0x2000],bl
        
        jmp hanxian_end


set_artive_page: ;04 设置活动页
redraw:          ;05 刷新屏幕   
up_roll:         ;06 往上滚动屏幕
down_roll:       ;07 往下滚动屏幕

draw_word:       ;08 写一个word到显存
    ;bx,字符
    ;cx,反色
    ;dx,坐标 
    
    xor di, di
    
    ; --- 1. 计算屏幕地址 (ES:DI) ---
    xor ax, ax
    mov al, dh
    shl ax, 1
    mov di, ax
    mov di, [cs:video_mem_rowlist+di]
  
    ;列
    xor ax, ax
    mov al, dl
    add di, ax ; DI Ready

    ; --- 2. 判断 ASCII 还是 汉字 ---
    cmp  bl, 80h
    jb   .ascii_jizhi_shezhi
    ; --- 3. 汉字处理 (GB2312 查表优化版) ---
    ; 这里的逻辑：SI = (Table[区索引] + 位索引) * 8
    xchg bh, bl
    ; 准备位索引 (存入 DX)
    xor  dx, dx
    mov  dl, bl
    sub  dx, 0xa1            ; DX = 位索引 (0~93)
    ; 准备区索引 (存入 AX)
    xor  ax, ax
    mov  al, bh
    sub  ax, 0xa1            ; AX = 区索引 (0~93) 注意这里是 A1，不是 A0，保持 0-based
    
    ; 计算查表地址
    shl ax, 1                 ; 关键修正：因为是 dw 表，所以索引要 * 2
    mov si, ax                ; BX 指向表中对应的数据
    ; 读取基准值
    ; 关键修正：必须使用 CS: 前缀，因为是在中断里，表在代码段
    ; 关键修正：直接覆盖 SI，不要用 add si (因为 si 初始值是脏的)
    mov si, [cs:zone_list+si]
    ; 加上位索引        
    add si, dx
    
    ; 乘以 8 (字模大小)
    shl si, 1
    shl si, 1
    shl si, 1
    ; 设置字库段
    mov ax, zimo_dizhi
    mov ds, ax
    
    jmp .shezhi_xiancun_jizhi
    
    .ascii_jizhi_shezhi:
        mov ax, 0xf000
        mov ds, ax
        xor bh, bh
        shl bx, 1
        shl bx, 1
        shl bx, 1
        mov si, 0xFA6E     ;ascii码字模所在的位置    
        add si, bx
        
    .shezhi_xiancun_jizhi:
        mov ax, 0xB800
        mov es, ax
        xor bx, bx
        mov dx, 79     ; 优化：循环中使用寄存器加法
        
        cmp cl, 0           ;cl是是否反色的参数
        jz  .draw_loop_pair
        mov bx, 0xffff
    .draw_loop_pair:
        ; 绘制 1、2 行
        lodsb
        xor ax,                  bx
        stosb
        lodsb
        xor ax,                  bx
        mov byte [es:di+0x1fff], al
        add di,                  dx ; add di, 79
        ; 绘制 3、4 行
        lodsb
        xor ax,                  bx
        stosb
        lodsb
        xor ax,                  bx
        mov byte [es:di+0x1fff], al
        add di,                  dx
        ; 绘制 5、6 行
        lodsb
        xor ax,                  bx
        stosb
        lodsb
        xor ax,                  bx
        mov byte [es:di+0x1fff], al
        add di,                  dx
        ; 绘制 7、8 行
        lodsb
        xor ax,                  bx
        stosb
        lodsb
        xor ax,                  bx
        mov byte [es:di+0x1fff], al
        jmp hanxian_end

to_cache: ;09 写到缓存

tty:      ;0a 电传模式 

hanxian_end:
    pop cx
    pop dx
    pop bx
    pop ax
    pop di
    pop si

    pop es
    pop ds

    cli
    mov sp, [cs:save_sp]
    sti

    iret
zimo_dizhi   equ 0xd000
ascii_pianyi equ 0xfa6e
save_sp  dw 0x0000
video_modlist          db 0x1a,0x0a                    ;为了显示模式的可扩展性
active_videomod        db 0eh
active_page            db 0                            ;记录当前活动缓存页
page_offset            db 0                            ;记录缓存页偏移行

active_cursor          db 0                       ;当前使用在光标
cache_cursor_coord     dw 0                            ;记录光标所在的缓存页为基础的坐标
video_mem_cursor_coord dw 0                            ;记录光标在显存中的坐标 （以汉显模式布局的）
cache_typehead         db 0,0,0,0,0,0,0,0
;光标字模：
;00 _
;01 厚的_
;02 =
;03 4x4方块
;04 实方块
;05 虚方块
;06 空方块
;07 |
;08 <
cursor_typehead:        dw 0x0000, 0x0000, 0x0000, 0xFE00
                       dw 0x0000, 0x0000, 0x00fe, 0xFE00
                       dw 0x0000, 0x0000, 0xfe00, 0xFE00
                       dw 0x0000, 0x00fe, 0xfefe, 0xFE00
                       dw 0xfefe, 0xfefe, 0xfefe, 0xFE00
                       dw 0xfe82, 0x8282, 0x8282, 0xfe00
                       dw 0xaa54, 0xaa54, 0xaa54, 0xaa00
                       dw 0x8080, 0x8080, 0x8080, 0x8000
                       dw 0x1e3e, 0x7efe, 0x7e3e, 0x1e00
; -----------------------------------------------------------
; 预计算的乘法表: Index * 94
; -----------------------------------------------------------
zone_list: ;区码的计算表
    dw 0,94,188,282,376,470,564,658,752,846,940,1034,1128,1222,1316,1410
    dw 1504,1598,1692,1786,1880,1974,2068,2162,2256,2350,2444,2538,2632,2726,2820
    dw 2914,3008,3102,3196,3290,3384,3478,3572,3666,3760,3854,3948,4042,4136,4230
    dw 4324,4418,4512,4606,4700,4794,4888,4982,5076,5170,5264,5358,5452,5546,5640
    dw 5734,5828,5922,6016,6110,6204,6298,6392,6486,6580,6674,6768,6862,6956,7050
    dw 7144,7238,7332,7426,7520,7614,7708,7802,7896,7990,8084,8178,8272,8366,8460
    dw 8554,8648,8742                                                             ; 只要到这里就够了，一共 94 个区

video_mem_rowlist: dw 0,320,640,960,1280,1600 ;显存的以8行像素为一行的行偏移表
               dw 1920,2240,2560,2880,3200
               dw 3520,3840,4160,4480,4800
               dw 5120,5440,5760,6080,6400
               dw 6720,7040,7360,7680

function_num_list: ;此中断的快速跳转功能的表
                dw set_cursor_shape  ;00 设置光标形状
                dw set_cursor_weizhi ;01 设置光标位置
                dw get_cursor        ;02 获取光标信息
                dw show_cursor       ;03 显示光标
                dw set_artive_page   ;04 设置活动页
                dw redraw            ;05 刷新屏幕   
                dw up_roll           ;06 往上滚动屏幕
                dw down_roll         ;07 往下滚动屏幕
                dw draw_word         ;08 在显存绘制单个字
                dw to_cache          ;09 写到缓存
                dw tty               ;0a 电传模式

;60h中断结束=============