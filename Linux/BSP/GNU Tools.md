
# GNU TOOLS

GNU组织不仅给我们带来了许多开源软件工程，还带来了强大的GNU编译工具

常用工具包括:
- 预处理器: cpp
- C编译器: gcc
- C++编译器: g++
- 汇编器: as
- 链接器: ld
- 二进制工具集: objcopy, objdump, ...


## ELF

a.out文件开头包含一段ELF信息



## nm: 符号显示器

- 显示符号: 
    - `$nm -n main_elf`
- 显示内容:
    - 第一列为符号地址
    - 第二列为符号所在段
    - 第三列为符号名称

**例子**
```
@sunplusedu$
@sunplusedu$pwd
/usr/local/arm/4.3.2/arm-none-linux-gnueabi/libc/usr/lib
@sunplusedu$arm-linux-nm -n crtl.o
        U __libc_csu_fini
        U __libc_csu_init
        U __libc_start_main
        U abort
        U main
000000 R _IO_stdin_used
000000 D __data_start
000000 T _start
000000 W data_start
@sunplusedu$
```


段 | 描述
-- | --
b/B | .bss(b静态/B非静态)未初始化变量 
d/D | .data(d静态/D非静态)已初始化变量
r/R | .rodata(r静态/R非静态)只读数据段
t/T | .text(t静态/T非静态)函数
A | 不可改变的绝对值
C | .o中未初始化非静态变量
N | 调试用的符号
U | 表示符号只有声明没有定义


**总结**
- 静态变量和非静态的全局变量，所分配的段只与其是否初始化有关，如果初始化了则被分配 在.data段中，否则在.bss段中
- 函数无论是静态还是非静态的，总是被分配在.text中，小写t表示静态，大写T表示非静态
- 函数内的局部变量由于是分配在栈上的，所以在nm中是看不到他们的



## objdump: 信息查看器

- 查看所有段信息: `$objdump -h main_elf`
- 查看文件头信息: `$objdump -f main_elf`
- 查看反汇编: `$objdump -d main_elf`
- 查看内嵌反汇编: `$objdump -S -d main_elf`


## objcopy: 段剪辑器

- 去除elf格式信息: `$obrjcopy -0 binary main_elf main.bin`



