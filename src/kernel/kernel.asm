;系统内存布局
;0x0500   内存的开始,为了和BIOS有缓冲，从0x600开始
;0x05ff   哨兵位，不知道需不需要，保守起见
;0x0600   集中的栈空间 
;14.5kb
;0x4000   内核
;12kb
;0x7000   汉显缓存区
;12,240B, 约12kb 3页
;0x9fd0  
;48B   
;0xa000   中断加载到这里
;16kb      
;0xe000


;栈空间布局 
;0x05ff 哨兵位
;0x0600 最高系统栈位
;5kbkb
;0x1A00 系统栈底
;1kb
;0x1e00 时钟栈底
;0.5kb 
;0x2000 键盘栈底
;2kb
;0x2800 磁盘栈底
;2kb    
;0x3000 视频栈底
;1kb
;0x3400 其他中断栈底
;3kb
;0x3fff 应用程序栈





;魔数 55aa,a55a
[BITS 16]
%include "sys_mmc.inc"
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


[ORG kernel_setoff]

Stack_Base equ 0x0000
Kernel_StackTop equ 0x1A00

jmp short start
nop

tick_count dw 0


start:
    mov ax, cs
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ax,Stack_Base
    mov ss, ax
    mov sp, Kernel_StackTop
    ; push ds
    ; cli 
    ; xor  ax,              ax
    ; mov  ds,              ax
    ; mov  word [ds:0x180], video_service
    ; mov  word [ds:0x182], cs            ;设置60中断

    ; mov  word [ds:0x8*4],time_isr
    ; mov  word [ds:0x8*4+2],cs
    
    ; sti
    ; pop ds
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
   
  
   





    



print_str   dw "“    糟得很”和“好得很”    "
　　        dw "农民在乡里造反，搅动了绅士们的酣梦。乡里消息传到城里来，城里的绅士立刻大哗。我初到长沙时，会到各方面的人，听到许多的街谈巷议。从中层以上社会至国民党右派，无不一言以蔽之曰：“糟得很。”即使是很革命的人吧，受了那班“糟得很”派的满城风雨的议论的压迫，他闭眼一想乡村的情况，也就气馁起来，没有法子否认这“糟”字。很进步的人也只是说：“这是革命过程中应有的事，虽则是糟。”总而言之，无论什么人都无法完全否认这“糟”字。实在呢，如前所说，乃是广大的农民群众起来完成他们的历史使命，乃是乡村的民主势力起来打翻乡村的封建势力。宗法封建性的土豪劣绅，不法地主阶级，是几千年专制政治的基础，帝国主义、军阀、贪官污吏的墙脚。打翻这个封建势力，乃是国民革命的真正目标。孙中山先生致力国民革命凡四十年，所要做而没有做到的事，农民在几个月内做到了。这是四十年乃至几千年未曾成就过的奇勋。这是好得很。完全没有什么“糟”，完全不是什么“糟得很”。“糟得很”。“糟得很”，明明是站在地主利益方面打击农民起来的理论，明明是地主阶级企图保存封建旧秩序，阻碍建设民主新秩序的理论，明明是反革命的理论。每个革命的同志，都不应该跟着瞎说。你若是一个确定了革命观点的人，而且是跑到乡村里去看过一遍的，你必定觉到一种从来未有的痛快。无数万成群的奴隶——农民，在那里打翻他们的吃人的仇敌。农民的举动，完全是对的，他们的举动好得很！“好得很”是农民及其他革命派的理论。一切革命同志须知：国民革命需要一个大的农村变动。辛亥革命⑶没有这个变动，所以失败了。现在有了这个变动，乃是革命完成的重要因素。一切革命同志都要拥护这个变动，否则他就站到反革命立场上去了。"

            dw "    所谓“过分”的问题    "

            dw "又有一般人说：“农会虽要办，但是现在农会的举动未免太过分了。”这是中派的议论。实际怎样呢？的确的，农民在乡里颇有一点子“乱来”。农会权力无上，不许地主说话，把地主的威风扫光。这等于将地主打翻在地，再踏上一只脚。“把你入另册！”向土豪劣绅罚款捐款，打轿子。反对农会的土豪劣绅的家里，一群人涌进去，杀猪出谷。土豪劣绅的小姐少奶奶的牙床上，也可以踏上去滚一滚。动不动捉人戴高帽子游乡，“劣绅！今天认得我们！”为所欲为，一切反常，竟在乡村造成一种恐怖现象。这就是一些人的所谓“过分”，所谓“矫枉过正”，所谓“未免太不成话”。这派议论貌似有理，其实也是错的。第一，上述那些事，都是土豪劣绅、不法地主自己逼出来的。土豪劣绅、不法地主，历来凭借势力称霸，践踏农民，农民才有这种很大的反抗。凡是反抗最力、乱子闹得最大的地方，都是土豪劣绅、不法地主为恶最甚的地方。农民的眼睛，全然没有错的。谁个劣，谁个不劣，谁个最甚，谁个稍次，谁个惩办要严，谁个处罚从轻，农民都有极明白的计算，罚不当罪的极少。第二，革命不是请客吃饭，不是做文章，不是绘画绣花，不能那样雅致，那样从容不迫，文质彬彬，那样温良恭俭让。革命是暴动，是一个阶级推翻一个阶级的暴烈的行动。农村革命是农民阶级推翻封建地主阶级的权力的革命。农民若不用极大的力量，决不能推翻几千年根深蒂固的地主权力。农村中须有一个大的革命热潮，才能鼓动成千成万的群众，形成一个大的力量。上面所述那些所谓“过分”的举动，都是农民在乡村中由大的革命热潮鼓动出来的力量所造成的。这些举动，在农民运动第二时期（革命时期）是非常之需要的。在第二时期内，必须建立农民的绝对权力。必须不准人恶意地批评农会。必须把一切绅权都打倒，把绅士打在地下，甚至用脚踏上。所有一切所谓“过分”的举动，在第二时期都有革命的意义。质言之，每个农村都必须造成一个短时期的恐怖现象，非如此决不能镇压农村反革命派的活动，决不能打倒绅权。矫枉必须过正，不过正不能矫枉⑷。这一派的议论，表面上和前一派不同，但其实质则和前一派同站在一个观点上，依然是拥护特权阶级利益的地主理论。这种理论，阻碍农民运动的兴起，其结果破坏了革命，我们不能不坚决地反对。",0
