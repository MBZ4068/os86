[BITS 16]

; =================================================================
; 中断服务程序 INT 80h
; =================================================================
draw_hanzi:
    push ds
    push es
    push si
    push di
    push ax
    push bx
    push dx
    push cx
    
    xor di,di
    
    ; --- 1. 计算屏幕地址 (ES:DI) ---
    mov al, dh
    xor ah, ah
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1       ; Row * 16
    mov di, ax
    shl ax, 1
    shl ax, 1       ; Row * 64
    add di, ax      ; DI = Row * 80
    
    xor ax, ax
    mov al, dl
    add di, ax      ; DI Ready
    ; --- 2. 判断 ASCII 还是 汉字 ---
    cmp bl, 80h
    jb ascii_jizhi_shezhi
    ; --- 3. 汉字处理 (GB2312 查表优化版) ---
    ; 这里的逻辑：SI = (Table[区索引] + 位索引) * 8
    
    ; 准备位索引 (存入 DX)
    xor dx, dx
    mov dl, bl
    sub dx, 0xa1    ; DX = 位索引 (0~93)
    ; 准备区索引 (存入 AX)
    xor ax, ax
    mov al, bh   
    sub ax, 0xa1    ; AX = 区索引 (0~93) 注意这里是 A1，不是 A0，保持 0-based
    
    ; 计算查表地址
    shl ax, 1       ; 关键修正：因为是 dw 表，所以索引要 * 2
    mov bx, quma_biao
    add bx, ax      ; BX 指向表中对应的数据
    ; 读取基准值
    ; 关键修正：必须使用 CS: 前缀，因为是在中断里，表在代码段
    ; 关键修正：直接覆盖 SI，不要用 add si (因为 si 初始值是脏的)
    mov si, [cs:bx] 
    ; 加上位索引
    add si, dx    
    
    ; 乘以 8 (字模大小)
    shl si, 1
    shl si, 1
    shl si, 1
    ; 设置字库段
    mov ax, 0xc000
    mov ds, ax
    
    jmp shezhi_xiancun_jizhi
    
ascii_jizhi_shezhi:
    mov ax, 0xf000
    mov ds, ax
    xor bh, bh
    shl bx, 1
    shl bx, 1
    shl bx, 1
    mov si, 0xFA6E
    add si, bx
    
shezhi_xiancun_jizhi:
    mov ax, 0xB800
    mov es, ax
    xor bx, bx
    mov dx, 79      ; 优化：循环中使用寄存器加法
    
    cmp cl, 0
    jz draw_loop_pair
    mov bx, 0xffff
draw_loop_pair:
    ; 绘制 1、2 行
    lodsb
    xor ax, bx
    stosb
    lodsb
    xor ax, bx
    mov byte [es:di+0x1fff], al
    add di, dx      ; add di, 79
    ; 绘制 3、4 行
    lodsb
    xor ax, bx
    stosb
    lodsb
    xor ax, bx
    mov byte [es:di+0x1fff], al
    add di, dx
    ; 绘制 5、6 行
    lodsb
    xor ax, bx
    stosb
    lodsb
    xor ax, bx
    mov byte [es:di+0x1fff], al
    add di, dx
    ; 绘制 7、8 行
    lodsb
    xor ax, bx
    stosb
    lodsb
    xor ax, bx
    mov byte [es:di+0x1fff], al
    
draw_end:
    pop cx
    pop dx
    pop bx
    pop ax
    pop di
    pop si
    pop es
    pop ds
    iret
; -----------------------------------------------------------
; 预计算的乘法表: Index * 94
; -----------------------------------------------------------
quma_biao:
    dw 0,94,188,282,376,470,564,658,752,846,940,1034,1128,1222,1316,1410
    dw 1504,1598,1692,1786,1880,1974,2068,2162,2256,2350,2444,2538,2632,2726,2820
    dw 2914,3008,3102,3196,3290,3384,3478,3572,3666,3760,3854,3948,4042,4136,4230
    dw 4324,4418,4512,4606,4700,4794,4888,4982,5076,5170,5264,5358,5452,5546,5640
    dw 5734,5828,5922,6016,6110,6204,6298,6392,6486,6580,6674,6768,6862,6956,7050
    dw 7144,7238,7332,7426,7520,7614,7708,7802,7896,7990,8084,8178,8272,8366,8460
    dw 8554,8648,8742 ; 只要到这里就够了，一共 94 个区