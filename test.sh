#!/bin/bash
password_r="/mnt/d/os86/password"
wsl << EOF
#清理wsl目录文件
cat "$password_r" | sudo -S mount /mnt/d/os86/disk_images/boot.img ~/tmp_mount -t vfat -o loop
cp ./build/* ~/tmp_mount
sync
sudo umount ~/tmp_mount
exit
EOF