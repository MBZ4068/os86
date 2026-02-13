
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

%ifndef KERNEL_SIZE
    %define  KERNEL_SIZE  0x400  ; 默认值
%endif

%ifndef VIDEO_SIZE
    %define  VIDEO_SIZE  0x400   ; 默认值
%endif

%ifndef TIMER_SIZE
    %define  TIMER_SIZE  0x400  ; 默认值
%endif

%ifndef TEST_SIZE
    %define  TEST_SIZE  0x400   ; 默认值
%endif










;fat表储存位置
fat_setoff    equ 0x500
;内核栈顶
fat_bottom      equ fat_setoff + 0x1200                     ;4.5kb 
;内核栈底                   
kernel_stack_bottom   equ fat_bottom  + 0x1000+2            ;4kb
;时钟栈底 1kb
timer_stack_bottom    equ kernel_stack_bottom+0x400 +2
;键盘栈底 512kb
keyboard_stack_bottom equ timer_stack_bottom +0x200 +2
;磁盘栈底            ;2kb
disk_stack_bottom     equ kernel_stack_bottom+0x800 +2
;视频栈底            ;1kb
video_stack_bottom    equ disk_stack_bottom+0x400 +2
;其他中断栈底
otherirq_stack_bottom equ video_stack_bottom+0x400  +2       ;1kb
;应用程序栈底
app_stack_bottom      equ otherirq_stack_bottom+0xc00  +2    ;3kb

;汉显缓存区偏移地址
han_setoff  equ app_stack_bottom+2
;内核加载偏移地址
kernel_setoff   equ han_setoff+0x3000+2
;中断加载偏移地址
video_setoff    equ kernel_setoff + KERNEL_SIZE+2
timer_setoff    equ video_setoff + VIDEO_SIZE+2
test_setoff     equ timer_setoff + TIMER_SIZE+2
;系统缓存区偏移地址
sysbuf_setoff equ test_setoff + TEST_SIZE+2

loader_bottom       equ 0x1000
loader_start_top    equ 0xf7ff
loader_start_bottom equ 0xfffe

timer_int equ 0x8
video_int equ 0x60

%assign _ks kernel_setoff
%assign _vs video_setoff
%assign _ts timer_setoff
%assign _tes test_setoff
%assign _sbs sysbuf_setoff

