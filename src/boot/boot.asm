 CPU 8086
 org 0x7c00


;这一个文件的目的是重新写一个在8088上能运行的正确引导文件
;重要的是彻底搞清楚他的原理
;任何地方都可能出bug 所以测试很重要
;注意寄存器有没有写错
;函数和变量都用同一种命名规则这真的好吗

YinDao_KaiShi_Dizhi     equ 0x7c00
BaseOfLoader            equ 0x1000 ;loader程序基址
OffsetOfLoader          equ 0x00   ;loader程序偏移地址 (基址<<4)+偏移地址 =物理地址

RootDirSectors          equ 7      ;根文件扇区数  计算得来 (根文件容纳目录树*32+511)/512 511是为了余出来的数值能包含进去
SectorNumOfRootDirStart equ 5      ;根文件开始扇区
SectorNumOfFAT1Start    equ 1      ;fat表开始扇区


    jmp short Boot_Start
    nop
    BS_OEMName      db 'COMIBoot'
    BPB_BytesPerSec dw 512
    BPB_SecPerClus  db 2             ;每簇扇区数
    BPB_RsvdSecCnt  dw 1             ;保留扇区数
    BPB_NumFATs     db 2             ;fat表份数
    BPB_RootEntCnt  dw 112           ;根文件容纳目录数
    BPB_TotSec16    dw 720           ;总扇区数
    BPB_Media       db 0xf0
    BPB_FATSz16     dw 2
    BPB_SecPerTrk   dw 9             ;每个磁道的扇区数
    BPB_NumHeads    dw 2
    BPB_hiddSec     dd 0
    BPB_TotSec32    dd 0
    BS_DrvNum       db 0             ;int 13h驱动号 0是软盘
    BS_Reserved1    db 0
    BS_BootSig      db 29h
    BS_VolID        dd 0
    BS_VolLab       db 'boot loader' ;卷标
    BS_FileSysType  db 'FAT12   '    ;文件类型

;===============引导开始

Boot_Start: ;引导开始
    mov [BS_DrvNum], dl     ; <--- BIOS 传来的驱动器号存入变量
    ;初始化段寄存器
    mov ax,          cs
    mov ds,          ax
    mov es,          ax
    mov ss,          ax
    mov sp,          0x7c00

;打印提醒文字
   
    mov  si, startboot
    call TTY_Print

;尝试一下磁盘复位
    mov ah, 0
    mov dl, 0
    int 13h

    
;===============查找loader.bin文件
;查找loader.bin 文件 简单来说，将根目录的扇区加载到内存
;然后对比每一项目录的名字前11位
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
;我首先应该获得他的直接扇区数，然后计算成能被中断识别的几个数
;一开始我该定位到根目录的第一个扇区
    mov byte [residue_sec_num], RootDirSectors          ;剩余扇区数
    mov word [now_sec_ord],     SectorNumOfRootDirStart ;现在扇区数

Find_Loader:                  
    cmp  byte [residue_sec_num], 0
    jz   Not_Found
    dec  byte [residue_sec_num]
    ;现在我要处理扇区数数据
    mov  ax,                     00h
    mov  es,                     ax
    mov  ax,                     word [now_sec_ord] ;扇区数超过 一个byte 需要ax存
    mov  bx,                     8000h
    mov  cl,                     1
    call Sector_Load_Memory
    mov  si,                     filename
    mov  di,                     8000h
    cld
    mov  ch,                     10h
    
Inc_Dir: ;递增目录
    test ch, ch
    jz   Next_Sector
    dec  ch
    mov  cl,11

Comparision_char: ;对比字符
    cmp cl,0
    jz   Got_It
    dec cl
    lodsb
    cmp  al, byte [es:di]
    jnz  Next_Dir
    inc  di
    jmp  Comparision_char

Next_Dir:
    and di, 0xffe0
    add di, 20h
    mov si, filename
    jmp Inc_Dir

Next_Sector:
    inc byte [now_sec_ord]
    jmp Find_Loader

Not_Found:
    mov  si, print_not_find
    call TTY_Print
    jmp  $

Got_It:
;接下了到了加载loader文件的时候
;通过之前的查找我们知道了
;di现在指向的是loader.bin的根目录项的结尾
;只要通过它偏移1ah,获取fat表的首项，即可将loader.bin 一簇一簇的加载到内存中
;
Load_Loader:
    ;获得初始簇号
    and di, 0ffe0h
  
    ;[es:di]是簇号 ，要把他转换为逻辑扇区
    mov  ax, word [es:di + 1ah]
    push ax
    mov ax,BaseOfLoader
    mov es,ax
    mov  bx, OffsetOfLoader ;跳转地址偏移
    pop ax
 Loader_Load_Memory:
    cmp ax,0ff8h
    jae Loader_over
    push ax

    xor cx,cx   
    sub  ax, 2
    mov  cl,byte [BPB_SecPerClus]
    mul  cx

    mov  cx, SectorNumOfRootDirStart ;根目录开始扇区
    add  cx, RootDirSectors
    add  ax, cx             ;获得逻辑扇区

    xor cx,cx
    mov cl,byte [BPB_SecPerClus]
.Read_Cluster_Loop:
    push cx             ; 保存循环次数
    push ax             ; 保存当前扇区号 LBA
    mov cl, 1           ; 【强制】每次只读 1 个扇区！
    call Sector_Load_Memory
    
    pop ax              ; 恢复当前扇区号
    inc ax              ; 扇区号 + 1 (准备读下一个)
    
    ; 内存指针后移 512 字节
    add bx, [BPB_BytesPerSec] 
    
    pop cx              ; 恢复循环次数
    loop .Read_Cluster_Loop
    ; ----------------------------------------------------------------
    pop ax              ; 恢复 FAT 表索引
    call Get_Fatdata
    jmp Loader_Load_Memory
Loader_over:
    
    jmp BaseOfLoader:OffsetOfLoader






TTY_Print:
    lodsb
    or  al, al
    jz  TTY_END
    mov bx, 0007h
    mov ah, 0eh
    int 10h
    jmp TTY_Print
TTY_END:
    ret



    
;===============写入扇区到内存
;写入一个扇区到内存 首先最重要的是：
;功能02H 功能描述：读扇区 入口参数：AH＝02H
;AL＝读取的扇区数量
;CH＝柱面
;CL＝扇区
;DH＝磁头
;DL＝驱动器，00H~7FH：软盘；80H~0FFH：硬盘
;ES:BX＝缓冲区的地址
;出口参数：CF＝0——操作成功，AH＝00H，AL＝传输的扇区数，否则，AH＝状态代码，参见功能号01H中的说明
;--------参数---------
; ax: 扇区线性计数
; bx: 缓存区偏移地址
; cl: 读取的扇区数量
; 注意这是一个>=1.44m的软盘,所以柱面不需要用到最高两位
Sector_Load_Memory:
    
    push dx
    push bp
    mov  bp,          sp
    sub  sp,          2
    mov  byte [bp-2], cl
    push bx
    mov  bl,          [BPB_SecPerTrk] ;每个磁道的扇区数
    div  bl                           ;al:商，ah:余数
    ;商就是 磁道/柱面数但因为 磁道有两面 需要除以2  余数就是 剩余的扇区数，但是扇区从1开始 所以要加1
    mov  dh,          al
    and  dh,          01h             ;dl: 磁头号
    mov  dl,          [BS_DrvNum]     ;驱动器号
    inc  ah
    mov  cl,          ah              ;cl: 扇区号
    shr  al,          1
    mov  ch,          al              ;ch: 柱面号
    pop  bx                           ;bx: 缓存区偏移地址

Load_start:
    
    mov ah, 02h
    mov al, [bp-2]
    int 13h
    jc  Load_start ;如果需要打印错误代码则改为跳转到Error_Manage
    mov sp, bp
    pop bp
    pop dx
    ret
; Error_Manage:


;     push cx
;     push bx
;    push si
   
;    mov  al,               ah
;    and  al,               00001111b
;    call Num_ASCII
;    mov  [error_code+3],   al
;    mov  al,               ah
;    and  al,               11110000b
;    mov  cl,               4
;    shr  al,               cl
;    call Num_ASCII
;    mov  [error_code + 2], al
;    mov  si,               error_code
;   call TTY_Print

;    pop si
;    pop bx
;    pop cx
;    jmp $


Num_ASCII:
   cmp AL, 9
   jg  To_16
   add AL, "0"
   ret
To_16:
   ADD AL, 37H
   ret
    

;===============获取fat表
;参数： ax: 簇号
Get_Fatdata:
    push es
    push bx
    push dx
    xor  cx, cx
    mov  es, cx
    mov  bx, 3
    mul  bx
    mov  bx, 2
    div  bx     ;ax：商 簇在fat表的字节地址， dx: 余数 余1是奇数
    push dx
  
Fat_Load_Memory:
    xor  dx, dx
    mov  bx, [BPB_BytesPerSec]
    div  bx                       ;dx 偏移地址
    add  ax, SectorNumOfFAT1Start
    mov  bx, 500h
    mov  cl, 2
    call Sector_Load_Memory
    add  bx, dx
    mov  ax, [es:bx]
    pop  dx  
    test dx, dx
    jz   Fat_Odd
    mov  cl, 4
    shr  ax, cl
Fat_Odd:
    
    and ax, 0fffh
    pop dx
    pop bx
    pop es
    ret

    
startboot       db 0AH,0DH,"Start Boot",0

filename        db "KERNEL  BIN",0
residue_sec_num db 0
now_sec_ord     dw 0

print_not_find  db 0AH,0DH,"KERNEL.bin Not Found!",0
new_line        db 0AH,0DH,0
error_code      db 0AH,0DH,0,0,0

;========填充完1.44M后结束
    times 510-($-$$) db 0
    dw                  0xaa55
    