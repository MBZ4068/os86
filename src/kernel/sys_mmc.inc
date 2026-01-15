
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





;fat表储存位置
fat_setoff    equ 0x500
;内核加载偏移地址
kernel_setoff equ 0x5002
;汉显缓存区偏移地址
han_setoff    equ 0x7002
;中断加载偏移地址
irq_setoff    equ 0xa002
;系统缓存区偏移地址
sysbuf_setoff equ 0xe002

;内核栈顶
kernel_stack_top      equ fat_setoff + 0x1200              ;4.5kb 
;内核栈底
kernel_stack_bottom   equ kernel_stack_top + 0x1000             ;4kb
;时钟栈底 1kb
clock_stack_bottom    equ kernel_stack_bottom+0x400
;键盘栈底 512kb
keyboard_stack_bottom equ clock_stack_bottom +0x200
;磁盘栈底         ;2kb
disk_stack_bottom     equ kernel_stack_bottom+0x800
;视频栈底            ;1kb
video_stack_bottom    equ disk_stack_bottom+0x400 
;其他中断栈底
otherirq_stack_bottom equ video_stack_bottom+0x400         ;1kb
;应用程序栈底
app_stack_bottom      equ otherirq_stack_bottom+0xc00      ;3kb


