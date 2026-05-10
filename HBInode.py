from ctypes import c_ubyte, c_uint16, c_uint32


class BitMap():
    """位图类，用于管理空闲块/簇的状态"""
    # write_bitmap(bit_index_list:list)->None 将指定位列表设置为已占用
    # erasure_bitmap(bit_index_list)->None 将指定位列表设置为空闲
    # get_free_bit(size)->list 获取指定数量的空闲位索引(非连续)
    # get_consiguous_free_bit(size)-> list 获取连续的空闲位索引
    # stat()->bit_num, work_cluster, free_cluster 统计位图中空闲与已占用的数量
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
    def get_one_free_bit(self):
        
        for n in range(self.bit_num):
            if self.bitmap[n] == 0:
                self.bitmap[n]=1
                return n
        
        return None

    def get_free_bit(self, size):
        """
        获取指定数量的空闲位索引（非连续）
        :param size: 需要获取的空闲位数
        :return: 空闲位索引列表
        """
        all_free=[]
        free_bit_list = []
        for n in range(self.bit_num):
            if self.bitmap[n] == 0:
                all_free.append(n)
        if len(all_free )>= size:
            free_bit_list=all_free[:size]
            self.write_bitmap(free_bit_list)

            return free_bit_list
        else:
            return None

    def get_consiguous_free_bit(self, size):
        """
        获取指定数量的连续空闲位索引
        :param size: 连续空闲位的数量
        :return: 连续空闲位的起始索引列表
        """
        all_free=[]
        free_bit_list = []
        for n in range(self.bit_num):
            if self.bitmap[n] == 0:
                all_free.append(n)
        count=0
        last=None
        for n in all_free:
            if last is not None and n != last+1:
                free_bit_list=[]
                last = n
                count =0
                
            if count < size:
                free_bit_list.append(n)
                last = n        
                count+=1   
            else: break

        if len(free_bit_list) == size:       
            self.write_bitmap(free_bit_list)
            return free_bit_list

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
        self.pointerlist = [c_uint16(0xFFFF) for _ in range(10)]   # 数据块指针数组，0xFFFF 表示空指针


class Dirent():
    """目录项类，表示目录树中的一个节点"""
    def __init__(self,name:str, inode_index:int ):
        """
        :param file_name: 文件或目录名
        :param inode_index: 对应的 inode 索引号
        """
        self.namesize=len(name.encode('gb2312'))
        if self.namesize  <=30:
            self.name = name
            spece_num=31-self.namesize
            self.long_name=' '*spece_num +self.name
        else:
            raise ValueError(f"文件名过长，最大允许 30 个字节，实际为 {self.namesize} ")
            

        self.inode_index =c_uint16(inode_index)


class Dir(Dirent):
    "目录类 这里用列表表示"
    def __init__(self,name,inode_index,parent_dir:Dirent|None,*args: Dirent | Dir):
        super().__init__(name,inode_index)
        self.dot=Dirent('./',inode_index)

        if parent_dir !=None:
            self.dotdot=Dirent('../',parent_dir.inode_index)
        else:
            self.dotdot=Dirent('../',inode_index)
        

        self.dirents:list[Dirent|Dir]=[self.dot,self.dotdot]

        for i in args:
            if i.name not in self.name_list():
                self.dirents.append(i)
            else:
                print(f"目录 {self.name } 中已存在名为 {i.name} 的目录项")

    def name_list(self):
        namelist=[]
        for i in self.dirents:
            namelist.append(i.name)
        return namelist
    def add_dirent(self,*args:Dirent | Dir):
        for i in args:
            if i.name not in self.name_list():
                self.dirents.append(i)
            else:
                print(f"目录 {self.name } 中已存在名为 {i.name} 的目录项,已跳过")
    def del_dirent(self,*args:Dirent | Dir):
        for i in args:
            if i in  self.dirents:
                self.dirents.remove(i)
            else:
                print(f"目录 {self.name } 中不存在名为 {i.name} 的目录项")
    

class Dir_Tree():
    """目录树管理类"""
    def __init__(self):
        self.root_dir=Dir('/',0,None)


    def add_file(self,file:Dirent|Dir,up_dir:Dir):
        up_dir.add_dirent(file)
        
    def find_in_dir(self,this_dir:Dir,
                    file_name:str|None=None,
                    dirent:Dirent|None=None) -> list:
        # 在一个目录中查找文件
        # 可通过文件名和 /Dirent 对象查找
        # this_dir 查询的目录 
        dir_list=[]
        
        dirent_list = this_dir.dirents

        for i in dirent_list:
            if (file_name is not None and i.name == file_name) or dirent == i: 
                dir_list.append([this_dir,i])        

        return dir_list 
    

    def find_in_tree(self,file_name:str|None=None,
                     dirent:Dirent|None=None,
                     first:bool=True,
                     start_dir=None) -> list:
        # 在文件树中查找文件
        # 可通过文件名 或Dirent 对象查找
        # start_dir 开始查找的目录对象
        # first 只返回查找到的第一个
        if start_dir is None:
            start_dir=self.root_dir
        current_level=[start_dir]
        result = [] 
        dir_list=[]
        while current_level :
            for i in current_level:
                rv=self.find_in_dir(i,file_name,dirent)
                if rv !=[]:
                   dir_list+=rv
                   if first:
                       return dir_list[0]

                for n in i.dirents:
                    if isinstance(n,Dir):
                        result.append(n)
            current_level = result.copy()
            result = []

        if dir_list == []:
            return None
        else:
            return dir_list 

            
class HBinode_Filesysteam():

    """基于 inode 的文件系统主类"""
    def __init__(self, blk_size, cluster_size):
        """
        :param blk_size: 总块数
        :param cluster_size: 簇大小（每簇包含的块数）
        """
        self.cluster_size = cluster_size
        self.blk_size = blk_size
        self.blk_bitmap = BitMap(self.blk_size//self.cluster_size)   # 块位图管理
        self.inode_bitmap= BitMap(64)
        self.inodes=[]
        #创建文件树
        self.dir_tree=Dir_Tree()
        


    def creat_dir(self, up_dir:Dir,dir_name:str,*dirent:Dirent):
        """
        创建目录的方法（占位，待实现）
        :param up_dir: 上级目录
        """
        inode_index=self.inode_bitmap.get_one_free_bit()
        new_dir=Dir(dir_name, inode_index,up_dir)
        self.dir_tree.add_file(new_dir,up_dir)
        
        
