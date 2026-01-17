CPU 8086

org 0x10000
%include "sys_mmc.inc"
;kernel_setoff 内核加载偏移地址
;han_setoff 汉显缓存区偏移地址
;irq_setoff 中断加载偏移地址   
;sysbuf_setoff 系统缓存区偏移地址

;各模块栈顶与栈底地址定义
;kernel_stack_top 内核栈顶
;kernel_stack_bottom 内核栈底
;clock_stack_bottom 时钟栈底
;keyboard_stack_bottom 键盘栈底
;disk_stack_bottom 磁盘栈底
;video_stack_bottom 视频栈底
;otherirq_stack_bottom 其他中断栈底
;app_stack_bottom 应用程序栈底
jmp short loader_start
nop

%include "fat12.inc"

timer_setoff dw irq_setoff
video_setoff dw 0
test_setoff  dw 0

loader_start:
    
    ;初始化段寄存器
    cli
    
    mov ax,          cs
    mov ds,          ax
    mov es,          ax
    mov ax,          0
    mov ss,          ax
    mov sp,          0xffff
    sti
    mov [BS_DrvNum], dl     ; <--- BIOS 传来的驱动器号存入变量
;清屏
    mov ax, 03h
    int 10h
;打印提醒文字
    mov  si, startloader_str
    call TTY_Print

;尝试一下磁盘复位
    mov ah, 0
    mov dl, 0
    int 13h


;加载fat表项
call load_fat

;=========  加载中断程序到内存
; 时钟中断
mov  si,                timername
xor  ax,                ax
mov  bx,                [timer_setoff]
call find_and_loader

;视频中断
add  bx,                2
mov  [video_setoff],  ax
mov  si,                videoname
xor  ax,                ax
call find_and_loader

;测试中断

add  bx,                2
mov  [test_setoff],     ax
mov  si,                testname
xor  ax,                ax
call find_and_loader
xchg bx,bx


;=======加载哨兵位
call set_magicnum


;安装中断
push ds
cli 
xor  ax,                ax
mov  ds,                ax
mov  ax,                [video_setoff]
mov  word [ds:0x180],   ax
mov  word [ds:0x182],   cs             ;设置60中断
mov  ax,                [timer_setoff]
mov  word [ds:0x8*4],   ax             ;时钟中断
mov  word [ds:0x8*4+2], cs

sti
pop  ds
xchg bx,bx


jmp  $

;=============查找并加载文件
;因为是中断文件，所以不会有超过64kb的情况，不用考虑es
;参数：
;si 文件名地址
;ax:bx 文件加载位置
;出口参数：
;bx 下一个文件该加载的内存地址的变量位置

find_and_loader:
    push es
    mov  es, ax
    call Find_file
    push si

    ;有返回值 ; ax 文件起始簇号 cx,dx, 文件大小字节
    call Load_file

    mov  si, print_load
    call TTY_Print
    pop  si
    push si
    call TTY_Print
    pop  si
    
    pop es
    ret

   
;加载哨兵内存布局的哨兵位
;魔数位 a55a
;kernel_setoff 内核加载偏移地址
;han_setoff 汉显缓存区偏移地址
;irq_setoff 中断加载偏移地址   
;sysbuf_setoff 系统缓存区偏移地址

;各模块栈顶与栈底地址定义
;kernel_stack_top 内核栈顶
;kernel_stack_bottom 内核栈底
;clock_stack_bottom 时钟栈底
;keyboard_stack_bottom 键盘栈底
;disk_stack_bottom 磁盘栈底
;video_stack_bottom 视频栈底
;otherirq_stack_bottom 其他中断栈底
;app_stack_bottom 应用程序栈底

set_magicnum:
    push ax
    push ds

    xor  ax,                    ax
    mov  ds,                    ax
    mov  ax,                    word [magic_num]
    
    mov  [kernel_stack_top],    ax               ; fat表项底
    mov  [kernel_stack_bottom], ax               ; 内核栈底

    mov [clock_stack_bottom],    ax ; 时钟栈底
    mov [keyboard_stack_bottom], ax ; 键盘栈底
    mov [disk_stack_bottom],     ax ; 磁盘栈底
    mov [video_stack_bottom],    ax ; 视频栈底
    mov [otherirq_stack_bottom], ax ; 其他中断栈底
    mov [app_stack_bottom],      ax ; 应用程序栈底

    mov [kernel_setoff-2], ax ; 内核加载偏移地址
    mov [han_setoff-2],    ax ; 汉显缓存区偏移地址
    mov [irq_setoff-2],    ax ; 中断加载偏移地址   
    mov [sysbuf_setoff-2], ax ; 系统缓存区偏移地址

    ;中断文件是在loader文件中才确定内存地址的
    mov [timer_setoff-2], ax
    mov [video_setoff-2], ax
    mov [test_setoff-2],  ax

    
    pop ds
    pop ax
    ret

;读取所有的fat表项到0x500
;检测无问题
load_fat:
    push es
    push ax
    push bx
    push cx

    mov  si, print_loadfat
    call TTY_Print

    mov ax, 0
    mov es, ax
    mov bx, fat_setoff            ;参数
    mov cx, word [BPB_FATSz16]    ;fat表几扇区
    mov ax, word [BPB_RsvdSecCnt] ;逻辑扇区计数 1
    .load_fat_loop:
        push cx
        
        mov  cx, 1
        call Sector_Load_Memory
       
        
        push ax
        push bx
        mov  al, '.'
        mov  ah, 0eh
        mov  bx, 000fh
        int  10h
        pop  bx
        pop  ax

        pop cx
        inc ax
        
        add  bx, word [BPB_BytesPerSec]
        loop .load_fat_loop

    .load_fat_over:
        pop cx
        pop bx
        pop ax
        pop es
        ret

TTY_Print:   
    push ax
    push bx
    .tty_loop:
    lodsb
    or  al, al
    jz  .TTY_END
    mov bx, 0007h
    mov ah, 0eh
    int 10h
    jmp .tty_loop
    .TTY_END:
        pop bx
        pop ax

        ret
    
;===============写入扇区到内存
; 写入一个扇区到内存 首先最重要的是：
; 功能02H 功能描述：读扇区 入口参数：AH＝02H
; AL＝读取的扇区数量
; CH＝柱面
; CL＝扇区
; DH＝磁头
; DL＝驱动器，00H~7FH：软盘；80H~0FFH：硬盘
; ES:BX＝缓冲区的地址
; 出口参数：CF＝0——操作成功，AH＝00H，AL＝传输的扇区数，否则，AH＝状态代码，参见功能号01H中的说明
;--------参数---------
; ax: 扇区线性计数
; bx: 缓存区偏移地址
; cl: 读取的扇区数量
; 注意这是一个>=1.44m的软盘,所以柱面不需要用到最高两位
Sector_Load_Memory:
    
    push dx
    push bp
    push ax

    mov  bp,          sp
    sub  sp,          2
    mov  byte [bp-2], cl
    push bx
    mov  bx,          word [BPB_SecPerTrk] ; 每个磁道的扇区数
    div  bl                                ; al:商，ah:余数
    ; 商就是 磁道/柱面数但因为 磁道有两面 需要除以2  余数就是 剩余的扇区数，但是扇区从1开始 所以要加1
    mov  dh,          al
    and  dh,          01h                  ; dl: 磁头号
    mov  dl,          byte [ds:BS_DrvNum]  ; 驱动器号
    inc  ah
    mov  cl,          ah                   ; cl: 扇区数
    shr  al,          1
    mov  ch,          al                   ; ch: 柱面号
    pop  bx                                ; bx: 缓存区偏移地址
    
    .Load_start:
        
        mov  ah, 02h
        mov  al, [bp-2]
        
        int  13h
        
        jc   Error_Manage ; 如果需要打印错误代码则改为跳转到Error_Manage
    .Load_success:
        mov sp, bp
        pop ax
        pop bp
        pop dx
        ret
;错误代码打印函数
;参数： ah      
Error_Manage:
   push cx
   push bx
   push si
   
   mov  al,               ah         ; 对ah的两个16进制的字符分开处理
   and  al,               00001111b
   call Num_ASCII
   mov  [error_code+3],   al         ; 写入error_code 字符中
   mov  al,               ah
   and  al,               11110000b
   mov  cl,               4
   shr  al,               cl
   call Num_ASCII
   mov  [error_code + 2], al
   mov  si,               error_code
   call TTY_Print                    ; 电传输出

   pop si
   pop bx
   pop cx
   jmp $


Num_ASCII:
    cmp     AL, 9   ; 如果al>9，意味着他将是字母
    jg      .To_16
    add     AL, "0"
    ret
    .To_16:         ; +37h 编程ascii码的字母
    ADD     AL, 37H
    ret


;===============查找根目录文件

; =============================================================================
; FAT12 目录项结构 (32 bytes per entry)
; =============================================================================
; 偏移     长度     名称          描述
; 0x00     11      DIR_Name      文件名(8字节) + 扩展名(3字节)
; 0x0B     1       DIR_Attr      文件属性字节
; 0x0C     10      保留          保留字段
; 0x16     2       DIR_WrtTime   最后写入时间
; 0x18     2       DIR_WrtDate   最后写入日期
; 0x1A     2       DIR_FstClus   文件起始簇号
; 0x1C     4       DIR_FileSize  文件大小(字节)
; =============================================================================
; 我首先应该获得他的直接扇区数，然后计算成能被中断识别的几个数
; 一开始我该定位到根目录的第一个扇区
; 参数 
; si 指向文件名
; 出口参数 
; ax 文件起始簇号
; cx,dx, 文件大小字节
Find_file:    
    push es
    push si
    push di
    push ds
    
    push bx
    mov  byte [residue_sec_num], RootDirSectors          ;剩余扇区数
    mov  word [now_sec_ord],     SectorNumOfRootDirStart ;现在扇区数

    .find_loop:                  
        cmp  byte [residue_sec_num], 0
        jz   .Not_Found
        dec  byte [residue_sec_num]
        ; 现在我要处理扇区数数据
        mov  ax,                     00h
        mov  es,                     ax
        mov  ax,                     word [now_sec_ord] ;扇区数超过 一个byte 需要ax存
        mov  bx,                     0xf000
        mov  cl,                     1
        call Sector_Load_Memory
        mov  di,                     0xf000
        cld
        mov  ch,                     10h
        
    .inc_Dir: ;递增目录
        test ch, ch
        jz   .Next_Sector
        dec  ch
        mov  cl, 11
        
        push si

    .comparision_char: ;对比字符
        cmp cl, 0
        jz  .found_file
        dec cl
        lodsb
        
        cmp al, byte [es:di]
        jnz .Next_Dir
        inc di
        jmp .comparision_char
        
    .found_file:
        mov ax, loader_bottom
        mov es, ax
        
        mov  si, print_find
        call TTY_Print
        
        pop  si
        call TTY_Print
        xor  ax, ax
        mov  es, ax
        
        and  di, 0xffe0            ;对齐32字节 回到目录项开头
        mov  ax, word [es:di+0x1A] ;文件起始簇号偏移
        mov  cx, word [es:di+0x1e] ; 文件大小高位
        mov  dx, word [es:di+0x1c] ; 文件大小低位
        
       
        jmp .find_ret

    .Next_Dir:
        and di, 0xffe0
        add di, 20h
        pop si
        jmp .inc_Dir

    .Next_Sector:
        inc word [now_sec_ord]
        jmp .find_loop

    .Not_Found:
        push si
        mov  ax, loader_bottom
        mov  es, ax
        mov  si, print_not_find
        call TTY_Print
        pop  si
        call TTY_Print

    .find_ret:
        pop bx
        pop ds
        pop di
        pop si
        pop es
        ret 


;读取在内存中的fat表 簇号对应的fat项 
;参数 
;ax 簇
;出口参数
;ax fat项数据
Clus_to_fat:
        push es
        push bx
        push dx
        
        xor  cx, cx
        mov  es, cx
        mov  bx, 3
        mul  bx
        mov  bx, 2
        div  bx     ;ax：商 簇在fat表的字节地址， dx: 余数 余1是奇数
        
    .Fat_Load_Memory:
        
        mov  bx, fat_setoff
        add  bx, ax
        
        mov  ax, word [es:bx]
        test dx, dx
        jz   .Fat_Odd
        mov  cl, 4
        shr  ax, cl
    .Fat_Odd:
        
        and ax, 0fffh
        
        pop dx
        pop bx
        pop es
        ret


;-----------加载文件到内存
;参数 
;ax 初始簇号
;es:bx 文件加载的目标内存地址
;cx,dx 文件大小 dx是低位

;出口参数
;es:bx 文件结束的内存地址


Load_file:
    
    push ax
    push bx
    push cx
    push dx
    
    .Loader_Load_Memory:
        
        cmp  ax, 0ff8h
        
        jae  .Loader_over
        push ax  

        push ax
        push bx
        mov  al, '.'
        mov  ah, 0eh
        mov  bx, 000fh
        int  10h
        pop  bx
        pop  ax
        
        xor cx, cx
        sub ax, 2
        mov cl, byte [BPB_SecPerClus]
        mul cx

        mov cx, SectorNumOfRootDirStart ;根目录开始扇区
        add cx, RootDirSectors          ;根目录扇区数
        add ax, cx                      ;获得逻辑扇区

        xor cx, cx
        mov cl, byte [BPB_SecPerClus]
        
    .Read_Cluster_Loop:
        push cx                 ; 保存循环次数
        push ax                 ; 保存当前扇区号 LBA
        mov  cl, 1              ; 【强制】每次只读 1 个扇区！
        
        call Sector_Load_Memory
        pop ax ; 恢复当前扇区号
         ; --- 准备下一个扇区 ---
        inc ax                    ; 下一个 LBA (注意这里也要处理进位到 DX)
        add bx, [BPB_BytesPerSec]
        jnc .no_segment_change    ; 如果没有进位(溢出)，继续
        
        ; --- 处理段跨越 (64KB 边界) ---
        push ax
        mov  ax, es
        add  ax, 0x1000 ; ES += 4KB (0x1000 * 16 = 64KB)
        mov  es, ax
        pop  ax
        ; BX 这里因为溢出自动变成了 0 (假设 512字节对齐且正好跨越)，不需要 xor bx, bx
         
    .no_segment_change:
        
        pop  cx                  ; 恢复计数
        
        loop .Read_Cluster_Loop
        
        ; --- 一个簇读完了，查 FAT 表找下一个簇 ---
        pop ax                  ; 弹出之前保存的当前簇号
        call Clus_to_fat         ; 查表：输入 AX(当前簇)，返回 AX(下一个簇)
        
        jmp  .Loader_Load_Memory

    .Loader_over:
    

        pop dx
        pop cx
        pop bx
        pop ax
        add bx, dx ;文件偏移地址的末尾位置  dx是文件大小地位 bx是偏移地址 加起来就是文件末尾的偏移地址
        ret


        


    
 












magic_num         dw 0xa55a
startloader_str   db 0AH,0DH,"Start loader",0
videoname         db "VIDEO   BIN",0
timername         db "TIMER   BIN",0
testname          db "TEST    BIN",0
residue_sec_num   db 0
now_sec_ord       dw 0
cata_stack_bottom dw 0
print_not_find    db 0AH,0DH,"Not Found ",0
error_code        db 0AH,0DH,"  ",0
print_find        db 0AH,0DH,"Found ",0
print_loadfat     db 0ah,0dh,"Loading the fat table to 0x500",0
print_load        db 0ah,0dh,"Loading the ",0