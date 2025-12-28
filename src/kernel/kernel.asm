
[BITS 16]
[ORG 0x10000]

jmp short start

tick_count dw 0


start:
    mov ax, cs
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    push ds
    cli 
    xor  ax,              ax
    mov  ds,              ax
    mov  word [ds:0x180], video_service
    mov  word [ds:0x182], cs            ;设置60中断

    mov  word [ds:0x8*4],time_isr
    mov  word [ds:0x8*4+2],cs
    
    sti
    pop ds
        ; 1. 设置 CGA Mode 06h
    ; ------------------------------------------------
    mov ax, 0006h
    int 10h

    mov ax,0004h
    int 60h

        MOV AH, 08H
   
    mov  al, 0
    mov  cl, 0
    xchg bx, bx
    mov  si, print_str
    
print_hang:
    
    mov ch, 0
    cmp al, 25
    jz  print_end
print_lie:
    
    cmp ch, 80
    jz  print_hang_add
    
    mov dh, al
    mov dl, ch

    push ax
    lodsb

    mov bl, al
    lodsb
    mov bh, al
  
    pop ax

    
    
    int 60h
    inc CH
    jmp print_lie
print_hang_add:
    inc al
    jmp print_hang
print_end:
    xchg bx, bx
    mov  ax, print_str
    mov  dx, 0x1844
    call Error_Manage

    mov  ax, print_str
    mov  ah, al
    mov  dx, 0x1847
    call Error_Manage

    mov  ax, si
    mov  dx, 0x184b
    call Error_Manage

    mov  ax, si
    mov  ah, al
    mov  dx, 0x184e
    call Error_Manage
    jmp $

Error_Manage:


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
   
  
   


time_isr:           ;定时器中断
    xchg bx,bx
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


    

video_service: ;汉显
    push ds
    push es
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
        mov  si,word [cs:video_mem_rowlist+si]
        add  si, ax     
        xor bx,bx                  
        mov  bl,byte [cs:active_cursor]
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
    xchg bx,bx
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
    mov ax, 0xd000
    mov ds, ax
    
    jmp .shezhi_xiancun_jizhi
    
    .ascii_jizhi_shezhi:
        mov ax, 0xf000
        mov ds, ax
        xor bh, bh
        shl bx, 1
        shl bx, 1
        shl bx, 1
        mov si, 0xFA6E
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
    
    iret

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

print_str   dw "“    糟得很”和“好得很”    "
　　        dw "农民在乡里造反，搅动了绅士们的酣梦。乡里消息传到城里来，城里的绅士立刻大哗。我初到长沙时，会到各方面的人，听到许多的街谈巷议。从中层以上社会至国民党右派，无不一言以蔽之曰：“糟得很。”即使是很革命的人吧，受了那班“糟得很”派的满城风雨的议论的压迫，他闭眼一想乡村的情况，也就气馁起来，没有法子否认这“糟”字。很进步的人也只是说：“这是革命过程中应有的事，虽则是糟。”总而言之，无论什么人都无法完全否认这“糟”字。实在呢，如前所说，乃是广大的农民群众起来完成他们的历史使命，乃是乡村的民主势力起来打翻乡村的封建势力。宗法封建性的土豪劣绅，不法地主阶级，是几千年专制政治的基础，帝国主义、军阀、贪官污吏的墙脚。打翻这个封建势力，乃是国民革命的真正目标。孙中山先生致力国民革命凡四十年，所要做而没有做到的事，农民在几个月内做到了。这是四十年乃至几千年未曾成就过的奇勋。这是好得很。完全没有什么“糟”，完全不是什么“糟得很”。“糟得很”。“糟得很”，明明是站在地主利益方面打击农民起来的理论，明明是地主阶级企图保存封建旧秩序，阻碍建设民主新秩序的理论，明明是反革命的理论。每个革命的同志，都不应该跟着瞎说。你若是一个确定了革命观点的人，而且是跑到乡村里去看过一遍的，你必定觉到一种从来未有的痛快。无数万成群的奴隶——农民，在那里打翻他们的吃人的仇敌。农民的举动，完全是对的，他们的举动好得很！“好得很”是农民及其他革命派的理论。一切革命同志须知：国民革命需要一个大的农村变动。辛亥革命⑶没有这个变动，所以失败了。现在有了这个变动，乃是革命完成的重要因素。一切革命同志都要拥护这个变动，否则他就站到反革命立场上去了。"

            dw "    所谓“过分”的问题    "

            dw "又有一般人说：“农会虽要办，但是现在农会的举动未免太过分了。”这是中派的议论。实际怎样呢？的确的，农民在乡里颇有一点子“乱来”。农会权力无上，不许地主说话，把地主的威风扫光。这等于将地主打翻在地，再踏上一只脚。“把你入另册！”向土豪劣绅罚款捐款，打轿子。反对农会的土豪劣绅的家里，一群人涌进去，杀猪出谷。土豪劣绅的小姐少奶奶的牙床上，也可以踏上去滚一滚。动不动捉人戴高帽子游乡，“劣绅！今天认得我们！”为所欲为，一切反常，竟在乡村造成一种恐怖现象。这就是一些人的所谓“过分”，所谓“矫枉过正”，所谓“未免太不成话”。这派议论貌似有理，其实也是错的。第一，上述那些事，都是土豪劣绅、不法地主自己逼出来的。土豪劣绅、不法地主，历来凭借势力称霸，践踏农民，农民才有这种很大的反抗。凡是反抗最力、乱子闹得最大的地方，都是土豪劣绅、不法地主为恶最甚的地方。农民的眼睛，全然没有错的。谁个劣，谁个不劣，谁个最甚，谁个稍次，谁个惩办要严，谁个处罚从轻，农民都有极明白的计算，罚不当罪的极少。第二，革命不是请客吃饭，不是做文章，不是绘画绣花，不能那样雅致，那样从容不迫，文质彬彬，那样温良恭俭让。革命是暴动，是一个阶级推翻一个阶级的暴烈的行动。农村革命是农民阶级推翻封建地主阶级的权力的革命。农民若不用极大的力量，决不能推翻几千年根深蒂固的地主权力。农村中须有一个大的革命热潮，才能鼓动成千成万的群众，形成一个大的力量。上面所述那些所谓“过分”的举动，都是农民在乡村中由大的革命热潮鼓动出来的力量所造成的。这些举动，在农民运动第二时期（革命时期）是非常之需要的。在第二时期内，必须建立农民的绝对权力。必须不准人恶意地批评农会。必须把一切绅权都打倒，把绅士打在地下，甚至用脚踏上。所有一切所谓“过分”的举动，在第二时期都有革命的意义。质言之，每个农村都必须造成一个短时期的恐怖现象，非如此决不能镇压农村反革命派的活动，决不能打倒绅权。矫枉必须过正，不过正不能矫枉⑷。这一派的议论，表面上和前一派不同，但其实质则和前一派同站在一个观点上，依然是拥护特权阶级利益的地主理论。这种理论，阻碍农民运动的兴起，其结果破坏了革命，我们不能不坚决地反对。",0
