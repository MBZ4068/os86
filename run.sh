#!/bin/bash

name=""
img=""
dbg=""
dbg_gui=""
bochs_flag=true
create_img=true
#loader_flag=false
gui_flag=false
floppy_size="1.44"
floppy_count=2880
nasm_fat_arg="-DISK_360K"

print_help(){
    echo "此脚本是用来自动化编译引导加载程序并在 Bochs 模拟器中运行的工具。"
    echo "用法: ./run.sh [-i <镜像名>] [-d] [-h] <文件名> /*文件名不包含后缀*/" 
    echo "选项:"
    echo "  -i <镜像名>    指定已有的镜像文件名（不包含后缀），如果不指定则使用文件名作为镜像名。"
    echo "  -d            启用调试模式，在 Bochs 中显示调试信息。"
    echo "  -h            显示帮助信息并退出。"
    echo "  -n            不启动 Bochs，仅编译汇编文件并生成镜像。"
    echo "  -g            启动 bochs 的 debug-gui(在启动之前需要先启动-d)"
    echo "  -f <软盘大小>  指定软盘大小，支持1.44、1.2、720、360（单位：KB），默认1.44M。"
}

jiazai_loader(){
####wsl的加载文件到镜像
    password_r="/mnt/d/os86/password"
    wsl << EOF
    #清理wsl目录文件
    cat "$password_r" | sudo -S mount /mnt/d/os86/disk_images/boot.img ~/tmp_mount -t vfat -o loop > /dev/null 2>&1
    sudo cp ./build/* ~/tmp_mount 
    sync
    sudo umount ~/tmp_mount
    echo "loader文件已加载到镜像中"
    exit

EOF

#####arch的加载文件到镜像
#     ssh arch_root << EOF
#     rm -f ~/win/os/*
#     exit
# EOF

#     scp disk_images/"${img}".img arch_root:~/win/os
#     for file in build/*; do
#         if [[ "$(basename "$file")" == "boot.bin" ]]; then
#             continue
#         fi
#         file_name=$(basename "$file")
#         scp build/"$file_name" arch_root:~/win/os
#     done

#     ssh arch_root << EOF
#     mount ~/win/os/"${img}".img ~/win/tmp_mount -t vfat -o loop
#     cp ~/win/os/loader.bin  ~/win/tmp_mount

#     cp ~/win/os/*.bin  ~/win/tmp_mount
#     sync
#     umount ~/win/tmp_mount
#     exit 
# EOF
#     scp arch_root:~/win/os/"${img}".img disk_images/"${img}".img


}
name_proc(){
    if [[ "$name" == *.asm ]]; then
        name=${name%.asm}
    fi
}

nasm_and_img(){
    rm build/*
    if [[ "$floppy_size" == "1.44" ]]; then
        floppy_count=2880
        nasm_fat_arg="-DDISK_1.44M"
    elif [[ "$floppy_size" == "1.2" ]]; then
        floppy_count=2400
        nasm_fat_arg="-DDISK_1.2M"
    elif [[ "$floppy_size" == "720" ]]; then
        floppy_count=1440
        nasm_fat_arg="-DDISK_720K"
    elif [[ "$floppy_size" == "360" ]]; then
        floppy_count=720
        nasm_fat_arg="-DDISK_360K"
    fi

    if [[ "$img" == "" ]]; then
        img="$name"
    fi
    #echo "当前 "${nasm_fat_arg}""

    nasm -i gb2312 src/kernel/kernel.asm $nasm_fat_arg -o build/kernel.bin -I src/boot -I src/kernel
    kernelsize=$(wc -c < build/kernel.bin)

    nasm -i gb2312 src/kernel/video.asm $nasm_fat_arg -o build/video.bin -I src/boot -I src/kernel
    videosize=$(wc -c < build/video.bin)

    nasm -i gb2312 src/kernel/timer.asm $nasm_fat_arg -o build/timer.bin -I src/boot -I src/kernel
    timersize=$(wc -c < build/timer.bin)

    nasm -i gb2312 src/kernel/test.asm $nasm_fat_arg -o build/test.bin -I src/boot -I src/kernel
    testsize=$(wc -c < build/test.bin)
    rm build/*
    echo "内核大小:${kernelsize} 字节"
    echo "视频大小:${videosize} 字节"
    echo "定时器大小:${timersize} 字节"    
    echo "测试大小:${testsize} 字节"

    nasmFileSize_parameter="-DKERNEL_SIZE=$kernelsize -DVIDEO_SIZE=$videosize -DTIMER_SIZE=$timersize -DTEST_SIZE=$testsize -I src/boot -I src/kernel"
    for file in src/kernel/*.asm; do
        file_name=$(basename "$file" .asm)
        
         nasm  "$file" $nasm_fat_arg $nasmFileSize_parameter -o build/"$file_name".bin 
         nasm -f bin -l lst/"$file_name".lst   "$file" -o lst/"$file_name" $nasm_fat_arg $nasmFileSize_parameter  
    done


    nasm  src/boot/"${name}".asm $nasm_fat_arg -o build/"${name}".bin  $nasmFileSize_parameter
    nasm -f bin -l lst/"${name}".lst   src/boot/"${name}".asm -o lst/"${name}" $nasm_fat_arg $nasmFileSize_parameter  
    output=$(nasm  src/boot/loader.asm $nasm_fat_arg $nasmFileSize_parameter -o build/loader.bin  2>&1 >/dev/null)
    nasm -f bin -l lst/loader.lst   src/boot/loader.asm -o lst/loader $nasm_fat_arg $nasmFileSize_parameter   > /dev/null 2>&1
    read -r _ _ kernel timer video test sysbuf _ <<< "$output"
    find lst/ -type f ! -name "*.lst" -delete
    # 转换为十六进制（可加上 0x 前缀）
    kernel_add=$(printf "0x%X" "$kernel")
    timer_add=$(printf "0x%X" "$timer")
    video_add=$(printf "0x%X" "$video")
    test_add=$(printf "0x%X" "$test")
    sysbuf_add=$(printf "0x%X" "$sysbuf")
    {
    echo "内核大小：.${kernelsize} .字节"
    echo "视频中断大小：.${videosize} .字节"
    echo "定时器中断大小：.${timersize} .字节"    
    echo "测试中断大小：.${testsize} .字节"
    echo "内核地址：.${kernel_add}"
    echo "时钟中断地址：.${timer_add}"
    echo "视频中断地址：.${video_add}"
    echo "测试中断地址：.${test_add}"
    echo "系统缓冲区地址：.${sysbuf_add}"
    }|column -t -s $'.'
    if  $create_img  ; then
        dd if=/dev/zero of=disk_images/"${img}".img bs=512 count=$floppy_count > /dev/null 2>&1
        echo "创建软盘镜像: "${img}".img "
    else 
        echo "跳过生成镜像文件 使用"${img}".img 写入 "${name}".img"  
    fi

    dd if=build/"${name}".bin of=disk_images/"${img}".img bs=512 count=1 conv=notrunc > /dev/null 2>&1
    # if [[ "$loader_flag" == true ]]; then
    #     jiazai_loader
    # fi
    jiazai_loader

}

run_bochs(){
    
    if [[ "$gui_flag" == true ]]; then
        if [[ "$dbg" == "" ]]; then
            echo "请先添加 -d 参数后再添加此参数"
        else 
            dbg_gui="display_library: win32, options="gui_debug,""
        fi
    fi
    
    case $floppy_size in
        "1.44")
            bofloppy_size="1_44"
            ;;
        "1.2")
            bofloppy_size="1_2"
            ;;
        "720")
            bofloppy_size="720K"
            ;;
        "360")
            bofloppy_size="360K"
            ;;
    esac
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
floppya: image="../disk_images/${img}.img", status=inserted,write_protected=0
#加载字库
optromimage1: file="../typehead/MeiJi.bin", address=0xd0000
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
while getopts "i:f:dhng" opt; do
    case $opt in
        i) img="$OPTARG"

        create_img=false
         ;;
        f) floppy_size="$OPTARG";;
        d) dbg="-dbg" ;;
        h) print_help
           exit 0 ;;
        n) bochs_flag=false ;;
        #l) loader_flag=true ;;
        g) gui_flag=true ;;
        ?) echo "无效的选项: -$OPTARG" >&2 
           print_help
           exit 1 ;;
    esac 
done

shift $((OPTIND - 1))

# 处理剩余的参数（文件名）
if [[ $# -eq 0 ]]; then
    echo "默认将以boot.asm进行编译运行"
    name="boot"
fi

case $floppy_size in
    "1.44"|"1.2"|"720"|"360")
        # 合法值，继续执行
        if [[ "$floppy_size" == "1.44" ]]; then
            echo "软盘大小设置为 ${floppy_size} MB"
        elif [[ "$floppy_size" == "1.2" ]]; then
            echo "软盘大小设置为 ${floppy_size} MB"
        elif [[ "$floppy_size" == "720" ]]; then
            echo "软盘大小设置为 ${floppy_size} KB"
        elif [[ "$floppy_size" == "360" ]]; then
            echo "软盘大小设置为 ${floppy_size} KB"
        fi
        ;;
    *)
        echo "错误: 软盘大小只能是 1.44、1.2、720 或 360"
        exit 1
        ;;
esac

complie_and_run(){
    nasm_and_img
    if [[ "$bochs_flag" == true ]]; then
        run_bochs
    else
        echo "编译完成，跳过 Bochs 启动"
    fi
}
if [[ "$@" == "" ]]; then
    complie_and_run
    exit 0
else 
    name=$1
    complie_and_run
    if [[ $# >1 ]]; then
        echo "警告: 只处理第一个参数作为文件名，其他参数将被忽略。"
    fi
fi

