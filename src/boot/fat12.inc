    %ifdef DISK_1.44M
    ; 1.44MB 软盘参数
    %DEFINE RooT_DIR_SECTORS           14     ;根文件扇区数  计算得来 (根文件容纳目录树*32+511)/512 511是为了余出来的数值能包含进去
    %DEFINE SECTOR_NUMOF_ROOT_DIR_START  19    ;根文件开始扇区
    %define BYTES_PER_SECTOR    512
    %define SECTORS_PER_CLUSTER 1
    %define RESERVED_SECTORS    1
    %define NUM_FATS            2
    %define ROOT_ENTRIES        224
    %define TOTAL_SECTORS       2880
    %define MEDIA_DESCRIPTOR    0xF0
    %define SECTORS_PER_FAT     9
    %define SECTORS_PER_TRACK   18

%elifdef DISK_1.2M
    ; 1.2MB 软盘参数
    %DEFINE RooT_DIR_SECTORS           14     ;根文件扇区数  计算得来 (根文件容纳目录树*32+511)/512 511是为了余出来的数值能包含进去
    %DEFINE SECTOR_NUMOF_ROOT_DIR_START 15    ;根文件开始扇区
    %define BYTES_PER_SECTOR    512
    %define SECTORS_PER_CLUSTER 1
    %define RESERVED_SECTORS    1
    %define NUM_FATS            2
    %define ROOT_ENTRIES        224
    %define TOTAL_SECTORS       2400
    %define MEDIA_DESCRIPTOR    0xF9
    %define SECTORS_PER_FAT     7
    %define SECTORS_PER_TRACK   15

%elifdef DISK_720K
    ; 720KB 软盘参数
    %DEFINE RooT_DIR_SECTORS           14      ;根文件扇区数  计算得来 (根文件容纳目录树*32+511)/512 511是为了余出来的数值能包含进去
    %DEFINE SECTOR_NUMOF_ROOT_DIR_START  7    ;根文件开始扇区
    %define BYTES_PER_SECTOR    512
    %define SECTORS_PER_CLUSTER 2
    %define RESERVED_SECTORS    1
    %define NUM_FATS            2
    %define ROOT_ENTRIES        224
    %define TOTAL_SECTORS       1440
    %define MEDIA_DESCRIPTOR    0xF0
    %define SECTORS_PER_FAT     3
    %define SECTORS_PER_TRACK   9
%elifdef DISK_360K
    %DEFINE RooT_DIR_SECTORS           7      ;根文件扇区数  计算得来 (根文件容纳目录树*32+511)/512 511是为了余出来的数值能包含进去
    %DEFINE SECTOR_NUMOF_ROOT_DIR_START  5    ;根文件开始扇区
    %define BYTES_PER_SECTOR    512  ;每扇区字节
    %define SECTORS_PER_CLUSTER 2    ;每簇扇区数
    %define RESERVED_SECTORS    1    ;保留扇区   引导文件的扇区
    %define NUM_FATS            2    ;fat表份数
    %define ROOT_ENTRIES        112  ;根文件容纳目录数
    %define TOTAL_SECTORS       720  ;总扇区数
    %define MEDIA_DESCRIPTOR    0xF0 ; 用于向操作系统标识磁盘的类型和格式。xF8 - 硬盘0xF0 - 高密度 软盘 0xF9 - 双密度 软盘
    %define SECTORS_PER_FAT     2    ;每份fat表占的大小
    %define SECTORS_PER_TRACK   9    ;每个磁道的扇区数

%else
    ; 默认使用 360k
    
    %DEFINE RooT_DIR_SECTORS           7      ;根文件扇区数  计算得来 (根文件容纳目录树*32+511)/512 511是为了余出来的数值能包含进去
    %DEFINE SECTOR_NUMOF_ROOT_DIR_START  5    ;根文件开始扇区
    %define BYTES_PER_SECTOR    512  ;每扇区字节
    %define SECTORS_PER_CLUSTER 2    ;每簇扇区数
    %define RESERVED_SECTORS    1    ;保留扇区   引导文件的扇区
    %define NUM_FATS            2    ;fat表份数
    %define ROOT_ENTRIES        112  ;根文件容纳目录数
    %define TOTAL_SECTORS       720  ;总扇区数
    %define MEDIA_DESCRIPTOR    0xF0 ; 用于向操作系统标识磁盘的类型和格式。xF8 - 硬盘0xF0 - 高密度 软盘 0xF9 - 双密度 软盘
    %define SECTORS_PER_FAT     2    ;每份fat表占的大小
    %define SECTORS_PER_TRACK   9    ;每个磁道的扇区数             

%endif

RootDirSectors          equ RooT_DIR_SECTORS            ;根文件扇区数  计算得来 (根文件容纳目录树*32+511)/512 511是为了余出来的数值能包含进去
SectorNumOfRootDirStart equ SECTOR_NUMOF_ROOT_DIR_START ;根文件开始扇区
SectorNumOfFAT1Start    equ 1                           ;fat表开始扇区

    BS_OEMName      db 'COMIBoot'
    BPB_BytesPerSec dw BYTES_PER_SECTOR
    BPB_SecPerClus  db SECTORS_PER_CLUSTER ;每簇扇区数
    BPB_RsvdSecCnt  dw RESERVED_SECTORS    ;保留扇区数
    BPB_NumFATs     db NUM_FATS            ;fat表份数
    BPB_RootEntCnt  dw ROOT_ENTRIES        ;根文件容纳目录数
    BPB_TotSec16    dw TOTAL_SECTORS       ;总扇区数
    BPB_Media       db MEDIA_DESCRIPTOR
    BPB_FATSz16     dw SECTORS_PER_FAT
    BPB_SecPerTrk   dw SECTORS_PER_TRACK   ;每个磁道的扇区数
    BPB_NumHeads    dw 2
    BPB_hiddSec     dd 0
    BPB_TotSec32    dd 0
    BS_DrvNum       db 0                   ;int 13h驱动号 0是软盘
    BS_Reserved1    db 0
    BS_BootSig      db 29h
    BS_VolID        dd 0
    BS_VolLab       db 'boot loader'       ;卷标
    BS_FileSysType  db 'FAT12   '          ;文件类型