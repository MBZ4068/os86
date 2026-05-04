from ctypes import c_ubyte, c_uint16, c_uint32


class BitMap():
    """位图类，用于管理空闲块/簇的状态"""
    def __init__(self, bit_num):
        """
        初始化位图
        :param bit_num: 位图总位数（对应总块数或总簇数）
        """
        self.bit_num = bit_num
        self.bitmap = [0] * bit_num   # 所有位初始化为0（空闲状态）

    def write_bitmap(self, bit_index_list):
        """
        将指定位列表置为已占用（写1）
        :param bit_index_list: 需要标记为占用的位索引列表
        """
        for i in bit_index_list:
            self.bitmap[i] = 1

    def erasure_bitmap(self, bit_index_list):
        """
        将指定位列表置为空闲（写0）
        :param bit_index_list: 需要标记为空闲的位索引列表
        """
        for i in bit_index_list:
            self.bitmap[i] = 0

    def get_free_bit(self, size):
        """
        获取指定数量的空闲位索引（非连续）
        :param size: 需要获取的空闲位数
        :return: 空闲位索引列表
        """
        free_bit_list = []
        for i in range(size):
            for n in range(self.bit_num):
                if self.bitmap[n] == 0:
                    free_bit_list.append(n)
                    break   # 找到一个空闲位后跳出内层循环，继续寻找下一个
        return free_bit_list

    def get_consiguous_free_bit(self, size):
        """
        获取指定数量的连续空闲位索引（未完成实现）
        :param size: 连续空闲位的数量
        :return: 连续空闲位的起始索引列表（当前代码有误，实际应返回连续区间）
        """
        free_bit_list = []
        jmp_index = 0
        for i in range(self.bit_num):
            if jmp_index == 0:
                # 检查从 i 开始的连续 size 个位是否都为空闲
                for n in range(size):
                    if self.bitmap[i + n] == 1:
                        jmp_index = n   # 记录第一个被占用的偏移量
                if jmp_index == 0:
                    # 如果全空闲，填充返回列表
                    for x in range(size):
                        free_bit_list[x] = i + x
                return free_bit_list
            jmp_index -= 1

    def stat(self):
        """
        统计位图中空闲与已占用的数量
        :return: 总簇数（未定义）、已占用簇数、空闲簇数
        """
        free_cluster = 0
        work_cluster = 0
        for i in self.bitmap:
            if i == 1:
                work_cluster += 1
            else:
                free_cluster += 1
        return self.bit_num, work_cluster, free_cluster  


class InNode():
    """索引节点类，模拟类 Unix 文件系统中的 inode"""
    def __init__(self):
        self.user = c_ubyte(0)               # 文件所有者标识
        self.file_mod = c_uint16(0)           # 文件权限/模式
        self.creation_at = c_uint16(0)        # 创建时间戳
        self.update_at = c_uint16(0)          # 最后更新时间戳
        self.retain_field_0 = c_uint16(0)     # 保留字段0
        self.retain_field_1 = c_uint16(0)     # 保留字段1
        self.pointerlist = [c_uint16(0xFFFF)] * 10   # 数据块指针数组，0xFFFF 表示空指针


class Dir():
    """目录项类，表示目录树中的一个节点"""
    def __init__(self, file_name, inode_index, up_dir=None):
        """
        :param file_name: 文件或目录名
        :param inode_index: 对应的 inode 索引号
        :param up_dir: 上级目录对象引用
        """
        self.file_name = file_name
        self.inode_index = inode_index
        self.up_dir = up_dir


class Dir_Tree():
    """目录树管理类"""
    dir_tree = [Dir("/", inode_index=0x80, up_dir=None)]   # 根目录预置

    def add_dir(self, dir_name, inode_index, up_dir):
        """
        在目录树中添加新目录项
        :param dir_name: 新目录名称
        :param inode_index: 新目录的 inode 索引
        :param up_dir: 上级目录对象
        """
        new_dir = [Dir(dir_name, inode_index, up_dir)]   # 注意：将目录项包裹在列表中
        path = self.get_dir_path(up_dir, Dir_Tree.dir_tree)

        file_list = Dir_Tree.dir_tree
        for i in path[:-1]:      # 逐级进入目录直到倒数第二级
            file_list = file_list[i]
        file_list.append(new_dir)   # 在目标位置添加新目录项
    def add_file(self,file_name,inode_index,up_dir):
        
        pass

    def get_dir_path(self, dir_obj, dir_list, path=None):
        """
        递归查找目录对象在目录树中的路径（索引序列）
        :param dir_obj: 目标目录对象
        :param dir_list: 当前搜索的目录列表
        :param path: 当前累积的路径索引列表
        :return: 路径索引列表，若未找到返回 None
        """
        if path is None:
            path = []
        for i in range(len(dir_list)):
            path.append(i)
            if type(dir_list[i]) is list:
                # 递归搜索子目录列表
                repath = self.get_dir_path(dir_obj, dir_list[i], path)
                if repath is not None:
                    return repath
            if dir_list[i] == dir_obj:
                return path   # 找到目标对象，返回路径
            path.pop()        # 回溯
        return None


class HBinode_Filesysteam():
    """基于 inode 的文件系统主类（未完整实现）"""
    def __init__(self, blk_size, cluster_size):
        """
        :param blk_size: 总块数
        :param cluster_size: 簇大小（每簇包含的块数）
        """
        self.cluster_size = cluster_size
        self.blk_size = blk_size
        self.blk_bitmap = BitMap(self.blk_size/self.cluster_size)   # 块位图管理
        dir_tree=Dir_Tree()

    def creat_dir(self, up_dir, ):
        """
        创建目录的方法（占位，待实现）
        :param up_dir: 上级目录
        """
