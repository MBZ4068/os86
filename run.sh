#!/bin/bash
name=""
img=""
dbg=""
dbg_gui=""
bochs_flag=true
create_img=true
loader_flag=false
gui_flag=false

print_help(){
    echo "此脚本是用来自动化编译引导加载程序并在 Bochs 模拟器中运行的工具。"
    echo "用法: ./run.sh [-i <镜像名>] [-d] [-h] <文件名> /*文件名不包含后缀*/" 
    echo "选项:"
    echo "  -i <镜像名>   指定已有的镜像文件名（不包含后缀），如果不指定则使用文件名作为镜像名。"
    echo "  -d            启用调试模式，在 Bochs 中显示调试信息。"
    echo "  -h            显示帮助信息并退出。"
    echo "  -n            不启动 Bochs，仅编译汇编文件并生成镜像。"
    echo "  -l            将loader.bin文件添加到镜像文件中"
    echo "  -g            启动 bochs 的 debug-gui(在启动之前需要先启动-d)"
}

jiazai_loader(){
    nasm -i gb2312 src/boot/loader.asm -o build/loader.bin
    nasm -i gb2312 src/boot/kernel.asm -o build/kernel.bin
    scp disk_images/"${img}".img arch_root:~/win/os
    scp build/loader.bin arch_root:~/win/os
    scp build/kernel.bin arch_root:~/win/os
    ssh arch_root << EOF
    mkdir -p ~/win/tmp_mount
    mount ~/win/os/"${img}".img ~/win/tmp_mount -t vfat -o loop
    cp ~/win/os/loader.bin  ~/win/tmp_mount
    cp ~/win/os/kernel.bin  ~/win/tmp_mount
    sync
    umount ~/win/tmp_mount
    exit 
EOF
    scp arch_root:~/win/os/"${img}".img disk_images/"${img}".img

}
name_proc(){
    if [[ "$name" == *.asm ]]; then
        name=${name%.asm}
    fi
}

nasm_and_img(){
    if [[ "$img" == "" ]]; then
        img="$name"
    fi

    nasm -i gb2312 src/boot/"${name}".asm -o build/"${name}".bin

    if  $create_img  ; then
        dd if=/dev/zero of=disk_images/"${img}".img bs=512 count=720
    else 
        echo "跳过生成镜像文件 使用"${img}".img 写入 "${name}".img"  
    fi

    dd if=build/"${name}".bin of=disk_images/"${img}".img bs=512 count=1 conv=notrunc
    if [[ "$loader_flag" == true ]]; then
        jiazai_loader
    fi

}

run_bochs(){
    
    if [[ "$gui_flag" == true ]]; then
        if [[ "$dbg" == "" ]]; then
            echo "请先添加 -d 参数后再添加此参数"
        else 
            dbg_gui="display_library: win32, options="gui_debug,""
        fi
    fi

    cd out_put/
    # 创建配置文件
    cat > "${img}.bxrc" << EOF
###############################################
# Bochs 的配置文件
###############################################

# 设置内存大小为 32MB
megs: 32

# 设置 BIOS 和 VGA BIOS
romimage: file=C:/bochs/BIOS-bochs-latest
vgaromimage: file=C:/bochs/VGABIOS-lgpl-latest.bin

#软盘启动
floppya: 360k="../disk_images/${img}.img", status=inserted,write_protected=0

# 设置启动设备为软盘
boot: a
#开启调试
debug: action=ignore
debugger_log: debugger.log
#魔法断点
magic_break: enabled=1
# 设置日志文件
log: ${name}_log.txt
${dbg_gui}
# 输入设备配置：禁用鼠标，启用键盘映射
mouse: enabled=0
keyboard: keymap=c:\bochs\keymaps\x11-pc-us.map
EOF

    # 运行 Bochs
    if [[ -n "$dbg" ]]; then
        echo "调试模式启动 Bochs..."
        bochs -f "${img}.bxrc" -q -dbg
    else
        echo "正常模式启动 Bochs..."
        bochs -f "${img}.bxrc" -q
    fi
}

# 解析选项
while getopts "i:dhnlg" opt; do
    case $opt in
        i) img="$OPTARG"

        create_img=false
         ;;
        d) dbg="-dbg" ;;
        h) print_help
           exit 0 ;;
        n) bochs_flag=false ;;
        l) loader_flag=true ;;
        g) gui_flag=true ;;
        ?) echo "无效的选项: -$OPTARG" >&2 
           print_help
           exit 1 ;;
    esac 
done

shift $((OPTIND - 1))

# 处理剩余的参数（文件名）
if [[ $# -eq 0 ]]; then
    echo "错误: 必须指定文件名"
    print_help
    exit 1
fi

for arg in "$@"; do
    name="$arg"
    name_proc
    nasm_and_img
    if [[ "$bochs_flag" == true ]]; then
        run_bochs
    else
        echo "编译完成，跳过 Bochs 启动"
    fi
done
