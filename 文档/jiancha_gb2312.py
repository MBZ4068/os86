#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

def build_gb2312_level1_set():
    """
    构建 GB2312 一级汉字集合 (第16区至第55区)。
    使用 GB2312 编码范围进行判断。
    """
    gb2312_set = set()
    # GB2312 一级汉字范围：首字节 0xB0-0xD7，尾字节 0xA1-0xFE
    for high in range(0xB0, 0xD8):       # 首字节范围
        for low in range(0xA1, 0xFF):    # 尾字节范围
            try:
                # 将字节对转换为 GB2312 字符
                byte_seq = bytes([high, low])
                char = byte_seq.decode('gb2312')
                gb2312_set.add(char)
            except UnicodeDecodeError:
                # 跳过无效的 GB2312 编码点位
                pass
    return gb2312_set

def check_characters_in_file(file_path, gb2312_set):
    """
    检查文件中的每个字符，打印不在 GB2312 一级字集中的汉字。
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"错误：文件 '{file_path}' 未找到。")
        return
    except UnicodeDecodeError:
        print("错误：文件编码可能不是 UTF-8。请尝试其他编码（如 'gbk'）。")
        # 你可以尝试将上面的 encoding='utf-8' 改为 encoding='gbk'
        return

    # 用于记录非 GB2312 一级字符
    non_gb2312_chars = {}

    line_num = 1
    col_num = 1
    for char in content:
        if '\u4e00' <= char <= '\u9fff':  # 基本判断是否为 CJK 统一表意文字（汉字）
            if char not in gb2312_set:
                # 记录字符、行号、列号
                if char not in non_gb2312_chars:
                    non_gb2312_chars[char] = []
                non_gb2312_chars[char].append((line_num, col_num))
        col_num += 1
        if char == '\n':
            line_num += 1
            col_num = 1

    # 输出结果
    if non_gb2312_chars:
        print(f"在文件 '{file_path}' 中发现了以下不在 GB2312 一级汉字集中的字符：\n")
        for char, positions in non_gb2312_chars.items():
            # 将位置信息格式化为更易读的形式
            pos_str = ', '.join([f"第{line}行第{col}列" for line, col in positions[:5]])  # 每个字符最多显示前5个位置
            if len(positions) > 5:
                pos_str += f" ... 等共 {len(positions)} 处"
            print(f"  字符：'{char}' (Unicode: {hex(ord(char))})")
            print(f"  出现位置：{pos_str}\n")
        print(f"总计发现 {len(non_gb2312_chars)} 个非 GB2312 一级汉字字符。")
    else:
        print(f"恭喜！文件 '{file_path}' 中的所有汉字均在 GB2312 一级汉字集中。")

def main():


    file_path = "文档/毛选.txt"  # 你可以修改为你想检查的文件路径
    print("正在构建 GB2312 一级汉字表，请稍候...")
    gb2312_level1_set = build_gb2312_level1_set()
    print(f"GB2312 一级汉字表构建完成，共 {len(gb2312_level1_set)} 个字符。")

    check_characters_in_file(file_path, gb2312_level1_set)

if __name__ == '__main__':
    main()