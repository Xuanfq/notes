# U-boot

## 1. 简介

U-boot是一种开源bootloader, 作用是用来引导操作，以及给开发人员提供测试调试工具。本身算是个精简的Linux系统，主要是负责硬件的初始化和引导，本身带有一些工具，作为引导程序，常作为嵌入式设备的引导。当真正的系统开始运行的时候U-boot就把管理权限交了出去。

**选择U-Boot的理由：**
① 开放源码；
② 支持多种嵌入式操作系统内核，如Linux、NetBSD, VxWorks, QNX, RTEMS, ARTOS, LynxOS, android；
③ 支持多个处理器系列，如PowerPC、ARM、x86、MIPS；
④ 较高的可靠性和稳定性；
⑤ 高度灵活的功能设置，适合U-Boot调试、操作系统不同引导要求、产品发布等；
⑥ 丰富的设备驱动源码，如串口、以太网、SDRAM、FLASH、LCD、NVRAM、EEPROM、RTC、键盘等；
⑦ 较为丰富的开发调试文档与强大的网络技术支持；

**U-BOOT工作模式**

U-Boot的工作模式有启动加载模式和下载模式。启动加载模式是Bootloader的正常工作模式，嵌入式产品发布时，Bootloader必须工作在这种模式下，Bootloader将嵌入式操作系统从FLASH中加载到SDRAM中运行，整个过程是自动的。下载模式就是Bootloader通过某些通信手段将内核映像或根文件系统映像等从PC机中下载到目标板的FLASH中。用户可以利用Bootloader提供的一些命令接口来完成自己想要的操作。



## 2. UBOOT命令介绍

### 2.1 帮助命令–help

查看当前的UBOOT支持那些命令。

```bash
TINY4412 # help
?       - alias for 'help'
base    - 打印一组地址偏移量
bdinfo  - 开发板的信息结构
boot    - boot default, i.e., run 'bootcmd'
bootd   - boot default, i.e., run 'bootcmd'
bootelf - Boot from an ELF image in memory
bootm   - 从内存启动应用程序
bootp   - 通过使用BOOTP / TFTP协议的网络引导映像
bootvx  - Boot vxWorks from an ELF image
chpart  - 更改活动分区 
cmp     - memory compare
coninfo - print console devices and information
cp      - 内存拷贝
crc32   - 检验和的计算 
dcache  - 启用或禁用数据缓存
dnw     - dnw     - USB设备进行初始化并准备好接受Windows server(特定的)

echo    - echo args to console
editenv - 修改环境变量
emmc    - 打开/关闭eMMC引导分区
env     - 环境处理命令
exit    - 退出脚本
ext2format- ext2 ext2format——磁盘格式

ext2load- 从Ext2文件系统加载二进制文件
ext2ls  - 在一个目录列表文件(默认/)
ext3format- ext3 ext3format——磁盘格式

false   - 什么也不做,但没有成功
fastboot- fastboot——使用USB fastboot协议

fatformat- FAT32 fatformat——磁盘格式

fatinfo - fatinfo——打印文件系统的信息
fatload - fatload——从dos加载二进制文件的文件系统

fatls   - 一个目录列表文件(默认/)
fdisk   - fdisk for sd/mmc.

go      - 在“addr”启动应用程序
help    - 打印命令描述/使用帮助
icache  - enable or disable instruction cache
iminfo  - print header information for application image
imxtract- extract a part of a multi-image
itest   - return true/false on integer compare
loadb   - load binary file over serial line (kermit mode)
loads   - load S-Record file over serial line
loady   - load binary file over serial line (ymodem mode)
loop    - infinite loop on address range
md      - memory display
mm      - memory modify (auto-incrementing address)
mmc     - MMC子系统
mmcinfo - mmcinfo <dev num>-- display MMC info
movi    - movi  - sd/mmc r/w sub system for SMDK board
mtdparts- define flash/nand partitions
mtest   - simple RAM read/write test
mw      - memory write (fill)
nfs     - boot image via network using NFS protocol
nm      - memory modify (constant address)
ping    - send ICMP ECHO_REQUEST to network host
printenv- print environment variables
reginfo - print register information
reset   - Perform RESET of the CPU
run     - run commands in an environment variable
saveenv - save environment variables to persistent storage
setenv  - set environment variables
showvar - print local hushshell variables
sleep   - delay execution for some time
source  - run script from memory
test    - minimal test like /bin/sh
tftpboot- boot image via network using TFTP protocol
true    - do nothing, successfully
usb     - USB sub-system
version - print monitor version
```

### 2.2 查看具体命令的使用方法–help

**格式：**
help <你想要查的指令>
或者 ? <你想要查的指令> ，
甚至 h <你想要查的指令缩写>。

```bash
TINY4412 # help sleep
sleep - 延迟执行一段时间

Usage:
sleep N
    - 延迟执行N秒(N是_decimal_ ! ! !)
```

![image-20220124130542141](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124130542141.png)

### 2.3 打印环境变量–printenv

```bash
TINY4412 # printenv
baudrate=115200
bootargs=root=/dev/nfs nfsroot=192.168.18.3:/work/rootfs ip=192.168.18.123:192.168.18.3:192.168.18.1:255.255.255.0::eth0:off init=/linuxrc console=ttySAC0,115200
bootcmd=movi read kernel 0 40008000;movi read rootfs 0 41000000 400000;bootm 40008000 41000000
bootdelay=3
ethaddr=00:40:5c:26:0a:5b
gatewayip=192.168.0.1
ipaddr=192.168.0.20
netmask=255.255.255.0
serverip=192.168.0.10

Environment size: 416/16380 bytes
```

baudrate： 当前的波特率。 一般不修改。
bootcmd： 启动命令。
bootdelay：启动命令 bootcmd 延时执行的时间。
ethaddr： 网卡 MAC 地址。
gatewayip：网关 IP 地址。
ipaddr： 开发板 IP 地址。
netmask： 子网掩码。
serverip： 服务器 IP(一般是 PC 的 IP,给开发板提供各种网络服务的主机的 IP)
bootargs: u-boot 传递给操作系统内核的启动参数。（很重要）

**使用示例**
打印指定的环境变量

**格式：** printenv 打印的环境变量名称

```bash
TINY4412 # printenv bootargs
bootargs=root=/dev/nfs nfsroot=192.168.18.3:/work/rootfs ip=192.168.18.123:192.168.18.3:192.168.18.1:255.255.255.0::eth0:off init=/linuxrc console=ttySAC0,115200
```

### 2.4 设置环境变量–setenv

```bash
查看帮助：
TINY4412 # help setenv
setenv - set environment variables -->作用是设置环境变量

Usage:  //命令使用方法
setenv name value ...  //使用格式
    - set environment variable 'name' to 'value ...'
    //设置环境变量“名称”“数值……格式
setenv name
    - delete environment variable 'name'
//删除环境变量
```

**使用示例**

```bash
设置上电的延时时间：
TINY4412 # setenv bootdelay 10     //设置上电延时时间为10秒
TINY4412 # saveenv               //保存设置
Saving Environment to SMDK bootable device...
done

设置波特率示例：
TINY4412 # setenv baudrate 115200    //设置波特率为115200
## Switch baudrate to 115200 bps and press ENTER ...  //设置完需要重启开发板，自动生效

删除环境变量示例：
setenv baudrate   //删除baudrate环境变量
```

**引用环境变量示例：**

```bash
TINY4412 # setenv timer 10     //随便设置一个环境变量
TINY4412 # setenv bootdelay ${timer}   //引用环境变量
TINY4412 # save                    //保存环境变量
Saving Environment to SMDK bootable device...
done
TINY4412 # print
baudrate=115200
bootargs=root=/dev/nfs nfsroot=192.168.18.3:/work/rootfs ip=192.168.18.123:192.168.18.3:192.168.18.1:255.255.255.0::eth0:off init=/linuxrc console=ttySAC0,115200
bootcmd=movi read kernel 0 40007fc0;bootm 40007fc0
bootdelay=10    //设置成功
ethaddr=00:40:5c:26:0a:5b
gatewayip=192.168.18.1
ipaddr=192.168.18.123
netmask=255.255.255.0
serverip=192.168.18.124
timer=10   //设置的新环境变量

Environment size: 389/16380 bytes
TINY4412 # 
```

### 2.5 设置bootargs参数

bootargs是环境变量中的重中之重，甚至可以说整个环境变量都是围绕着bootargs来设置的。

**coherent_pool参数：**

```bash
设置DMA的大小
示例： coherent_pool=2M
```

**本地挂载示例**

```bash
set bootargs root=/dev/mmcblk0p2 rootfstype=ext3 init=/linuxrc console=ttySAC0,115200

set bootargs root=/dev/mmcblk0p2 rw rootfstype=ext3 init=/linuxrc console=ttySAC0,115200
```

**NFS网络挂载示例：**

```bash
set bootargs root=/dev/nfs nfsroot=192.168.18.3:/work/nfs_root ip=192.168.18.123:192.168.18.3:192.168.18.1:255.255.255.0::eth0:off init=/linuxrc console=ttySAC0,115200
```

root参数用来指定根文件系统挂载的位置。

nfsroot参数是NFS网络文件系统挂载才需要设置，后面跟着服务器的NFS地址，挂载目录

ip参数是设置开发板的网卡IP地址，NFS网络挂载时必须设置。

init 是指定挂载文件系统之后运行的脚本，用来做一些系统初始化。

### 2.6 查看开发板的配置信息–bdinfo

```bash
TINY4412 # bdinfo
arch_number = 0x00001200 ->开发板的机器码， 用来引导操作系统的内核
boot_params = 0x40000100 ->启动参数存储的内存位置
DRAM bank = 0x00000000 -> DRAM 编号，这里表示是第 0 个 DDR
-> start = 0x40000000    -->DRAM 的起始地址
-> size = 0x10000000     -->DRAM 的大小 ( 0x10000000 /1024 /1024 = 256M)
DRAM bank = 0x00000001 -> DRAM 编号，这里表示是第 1 个 DDR
-> start = 0x50000000    -->DRAM 的起始地址
-> size = 0x10000000     -->DRAM 的大小( 0x10000000 /1024 /1024 = 256M)
DRAM bank = 0x00000002-> DRAM 编号，这里表示是第 2 个 DDR
-> start = 0x60000000    -->DRAM 的起始地址
-> size = 0x10000000     ->DRAM 的大小( 0x10000000 /1024 /1024 = 256M)
DRAM bank = 0x00000003-> DRAM 编号，这里表示是第 3 个 DDR
-> start = 0x70000000    ->DRAM 的起始地址
-> size = 0x0FF00000     ->DRAM 的大小( 0x10000000 /1024 /1024 = 256M)
ethaddr = 00:40:5c:26:0a:5b  ->网卡 MAC 地址(DM9600)
ip_addr = 192.168.0.20      ->开发板的 IP
baudrate = 0           bps ->波特率，这里是代码有问题，应该 115200
TLB addr = 0x3FFF0000      ->MMU(CPU) 映射表存储位置
relocaddr = 0xC3E00000     ->代码重新定位的地址
reloc off = 0x00000000      ->重定位地址
irq_sp = 0xC3CFBF58       ->irq堆栈指针
sp start = 0xC3CFBF50     ->开始地址堆栈指针 
FB base = 0x00000000      ->framebuffer基地址
```

### 2.7 内存数据显示->md

**查看帮助：**

```bash
TINY4412 # ? md
md - memory display 内存数据显示---只能显示内存中的数据，就是说只能在DDR地址中操作

Usage:
md [.b, .w, .l] address [# of objects]  
```

Md.b : 以字节方式显示数据
Md.w : 以字（2 个字节）
Md.l : 以双字（4 个字节）
以上表示以字节、字（2 个字节）、双字（4 个字节）为单位进行显示

**格式：**Md.b <要显示的地址> [显示的数据个数]

```bash
TINY4412 # md.b 1000000 10    //将起始地址1000000处的10个数据显示到终端
01000000: 06 00 00 ea fe ff ff ea fe ff ff ea fe ff ff ea    ................
```

**示例：**

```bash
TINY4412 # md.b 1000000 10                一个字节显示：
01000000: 06 00 00 ea fe ff ff ea fe ff ff ea fe ff ff ea    ................
TINY4412 # md.w 1000000 10               两个字节显示
01000000: 0006 ea00 fffe eaff fffe eaff fffe eaff    ................
01000010: fffe eaff fffe eaff 301a ea00 301b ea00    .........0...0..
TINY4412 # md.l 1000000 10                四个字节显示
01000000: ea000006 eafffffe eafffffe eafffffe    ................
01000010: eafffffe eafffffe ea00301a ea00301b    .........0...0..
01000020: e59f01a4 e3a01000 e5801000 e59f019c    ................
01000030: e5900000 e200003e e330003e 1a00000d    ....>...>.0.....
```

### 2.8 复制内存命令 cp

**查看帮助：**

```bash
TINY4412 # help cp
cp - memory copy  内存拷贝 --只能在内存中拷贝，就是说只能在DDR地址中操作

Usage:
cp [.b, .w, .l] source target count 源地址 目标地址 数量个数
```

**示例1：**

```bash
TINY4412 # cp 100000 4000000 10
从起始地址100000开始拷贝10个数据到4000000的地址处
```

**示例2：**

```bash
TINY4412 # md.b 46000000
46000000: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
TINY4412 # md.b 10000000          
10000000: 11 20 41 e4 08 00 05 08 05 00 00 00 10 00 00 00    . A.............
TINY4412 # cp 10000000 46000000 10    从起始地址10000000开始拷贝10个数据到46000000的地址处
TINY4412 # md.b 46000000          
46000000: 11 20 41 e4 08 00 05 08 05 00 00 00 10 00 00 00    . A.............
```

![image-20220124132620277](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124132620277.png)

### 2.9 查看EMMC的信息->mmcinfo

**查看帮助：**

```bash
TINY4412 # help mmcinfo
mmcinfo - mmcinfo <dev num>-- display MMC info  >输出指定编号 mmc 的信息， <dev num>是要指定的编号

Usage:
mmcinfo 
```

**编号说明：**
mmc 的编号是会变化的， Tiny4412 板上有 EMMC，有SD卡。这两个都归类为 MMC。 编号是0，1。 但是谁是0，谁是 1，是不确定的， 和启动方式有关。 在哪个存储器启动，哪个就是编号就是0。

![image-20220124132744606](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124132744606.png)

**查看SD卡信息：**

```bash
TINY4412 # mmcinfo 0
Device: S3C_HSMMC2          设备名称
Manufacturer ID: 2             制造商标识 ID
OEM: 544d                   设备制造商
Name: SE08G                  名称
Tran Speed: 0     
Rd Block Len: 512              每一块的大小，字节为单位
SD version 2.0                 SD卡的版本
High Capacity: Yes              是否是大容量卡
Size: 7460MB (block: 15278080)   容量大小，(总共有多少个块)
Bus Width: 4-bit                总线宽度，SD卡接口是4条线
Boot Partition Size: 0 KB          引导分区大小
```

**查看EMMC的信息：**

```bash
TINY4412 # mmcinfo 1
Device: S5P_MSHC4           设备
Manufacturer ID: 15         制造商ID
OEM: 100                    原始设备制造商
Name: 4YMD3                 名称
Tran Speed: 0               Tran速度
Rd Block Len: 512           每一块的大小，字节为单位
MMC version 4.0             MMC版本
High Capacity: Yes          是否是大容量卡
Size: 3728MB (block: 7634944) 卡的容量和总共的块大小
Bus Width: 8-bit             总线宽度 
Boot Partition Size: 4096 KB 引导分区大小
```

### 2.10 mmc命令子系统

mmc不是单独的命令，他是一个子系统，支持多个命令。

查看mmc子系统的帮助信息

```bash
TINY4412 # help mmc
mmc - MMC sub system          MMC子系统

Usage:
mmc read <device num> addr blk# cnt         --从 mmc 指定扇区读取数据到 ddr 中
mmc write <device num> addr blk# cnt        --写 ddr 中的数据到指定 mmc 扇区中
mmc rescan <device num>                     --重新扫描指定设备， 相当于重新初始化
mmc erase <boot | user> <device num> <start block> <block count> --擦除指定扇区
mmc list - lists available devices          --列出有效的 mmc 设备
```

**参数说明：**

```bash
<device num>： mmc 编号，编号原则同前面说的，就是对哪一个设备操作。
addr： DDR3 内存地址；
blk#： 要读/写的 mmc 扇区地址起始地址；
cnt：  要读/写的 mmc 扇区数量；
boot： 引用分区，一般是操作 bl1,bl2,u-boot 的 mmc 扇区范围。
user:  用户分区， 一般是操作内核，文件系统的 mmc 扇区范围。
<start block>：要擦除的 mmc 扇区起始地址；
<block count>：要擦除的 mmc 扇区数量；
```

**mmc 命令中的参数都是 16 进制表示，不是 10 进制表示**

**（1）从MMC扇区读数据到DDR内存中->mmc read**

```bash
格式：mmc read <device num> addr blk# cnt
blk#：要读/写的 mmc 扇区的起始地址 (十六进制表示)
Cnt ：要读/写的 mmc 扇区数量(十六进制表示)
addr： DDR3 内存地址；
TINY4412 # mmc read 0 45000000 1 1

MMC read: dev # 0, block # 1, count 1 ... 1 blocks read: OK

这里是从SD卡的第1个扇区开始，读取一个扇区的数据到DDR的45000000地址处！

示例：
TINY4412 # md.b 48000000 10
48000000: ff ff ff ff ff ff ff ff ff ff ff ff bf ff ff ff    ................

//从SD卡第一个扇区开始，读取一个扇区的数据到DDR的48000000地址处
TINY4412 # mmc read 0 48000000 1 1

MMC read: dev # 0, block # 1, count 1 ... 1 blocks read: OK
TINY4412 # md.b 48000000 10       
48000000: a3 69 d3 18 e9 7d b9 66 d1 6b d5 6e d4 79 a6 79    .i...}.f.k.n.y.y
```

![image-20220124133040383](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124133040383.png)

**（2）mmc write --写 ddr 中的数据到指定 mmc 扇区中**

```bash
格式：mmc write <device num> addr blk# cnt  --将 ddr 中的数据到写到指定mmc 扇区中
blk#：要读/写的 mmc 扇区的起始地址(十六进制表示)
Cnt ：要读/写的 mmc 扇区数量(十六进制表示)
addr：DDR3 内存地址；
示例：
TINY4412 # mmc write 0 48000000 1 1  从DDR 48000000地址处，写1个扇区的数据到SD的第1个扇区

MMC write: dev # 0, block # 1, count 1 ... 1 blocks written: OK
```

**（3）擦除指定扇区**

```bash
格式：
mmc erase <boot | user> <device num> <start block> <block count> --擦除指定扇区
参数说明：
<start block>：要擦除的 mmc 扇区起始地址
<block count>：要擦除的 mmc 扇区数量
boot： 引用分区
User： 用户分区
为了方便比较，先将SD卡的第1个扇区内容读到DDR中。

读出第10个扇区的数据
TINY4412 # mmc read 0 48000000 1 1

MMC read: dev # 0, block # 1, count 1 ... 1 blocks read: OK

显示第1个扇区的数据
TINY4412 # md.b 48000000 30       
48000000: a3 69 d3 18 e9 7d b9 66 d1 6b d5 6e d4 79 a6 79    .i...}.f.k.n.y.y
48000010: 07 00 00 ea fe ff ff ea fe ff ff ea fe ff ff ea    ................
48000020: fe ff ff ea fe ff ff ea fe ff ff ea fe ff ff ea    ................
擦除SD卡的第一个扇区
TINY4412 # mmc erase user 0 1 1   
START: 1 BLOCK: 1        开始1扇区，擦除1扇区
high_capacity: 1         高容量
Capacity: 15278080       容量

Erase                    擦除

 512 B erase Done        512字节
MMC erase Success.!! MMC擦除成功。! !
再读再显示
TINY4412 # mmc read 0 40000000 1 1

MMC read: dev # 0, block # 1, count 1 ... 1 blocks read: OK
TINY4412 # md.b 40000000 30       
40000000: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
40000010: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
40000020: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
恢复数据，再读再显示
TINY4412 # mmc write 0 48000000 1 1   将DDR里的数据写入SD卡中

MMC write: dev # 0, block # 1, count 1 ... 1 blocks written: OK
TINY4412 # mmc read 0 40000000 1 1   再次读出数据

MMC read: dev # 0, block # 1, count 1 ... 1 blocks read: OK
TINY4412 # md.b 40000000 30         显示---数据已经恢复
40000000: a3 69 d3 18 e9 7d b9 66 d1 6b d5 6e d4 79 a6 79    .i...}.f.k.n.y.y
40000010: 07 00 00 ea fe ff ff ea fe ff ff ea fe ff ff ea    ................
40000020: fe ff ff ea fe ff ff ea fe ff ff ea fe ff ff ea    ................
```

**（4）列出MMC设备–mmc list**

```bash
TINY4412 # mmc list
S3C_HSMMC2: 0 --- 0 编号的 mmc 设备，这里接 SD 卡
S5P_MSHC4: 1  --- 1 编号的 mmc 设备，这里接 开发板板载的EMMC
```

### 2.11 查看MMC分区信息–fatinfo

```bash
TINY4412 # help fatinfo
fatinfo - fatinfo - print information about filesystem 
                    打印文件系统信息

Usage:
fatinfo <interface> <dev[:part]>   格式说明
    - print information about filesystem from 'dev' on 'interface'

参数说明：
<interface>： mmc 或 usb；
dev： 设备编号；
part： 设备分区号
查看第0个设备信息---这里是SD卡：
TINY4412 # fatinfo mmc 0   
-----Partition 1-----
Partition1: Start Address(0x2e2e2e2e), Size(0x2e2e2e2e)
分区1	        起始地址                 大小
------------------------
-----Partition 2-----
Partition1: Start Address(0x2e2e2e2e), Size(0x2e2e2e2e)
------------------------
-----Partition 3-----
Partition1: Start Address(0x2e2e2e2e), Size(0x2e2e2e2e)
------------------------
-----Partition 4-----
Partition1: Start Address(0x2e2e2e2e), Size(0x2e2e2e2e)
------------------------
Interface:  SD/MMC
接口
        
  Device 0: Vendor: Man 02544d Snr c9226e33 Rev: 2.1 Prod: SE08G
            Type: Removable Hard Disk  
            类型：可移动硬盘
            
            Capacity: 14.5 MB = 0.0 GB (29840 x 512)
Partition 1: Filesystem: FAT32 "NO NAME    "
```



### 2.12 fatls –列出指定目录下的文件

**查看帮助：**

```bash
TINY4412 # ? fatls
fatls - list files in a directory (default /)
         列出一个目录文件

Usage:
fatls <interface> <dev[:part]> [directory]

   - list files from 'dev' on 'interface' in a 'directory'
```

**参数说明：**

```bash
<interface>： mmc 或 usb；
dev： 设备编号；
part： 设备分区号；
[directory]： 目录， 是可选， 可以不写，不写默认 / 目录
```

查看SD卡中的文件列表（查看之前SD需要有完好的分区才行，可以通过fdisk进行分区，从U-BOOT和内核地址之后开始分区，防止将U-BOOT和内核清除）

```bash
TINY4412 # fatls mmc 0 /
Partition1: Start Address(0x71c53a), Size(0x2025c6)
            system volume information/
            12345/

0 file(s), 2 dir(s)    共用两个目录，0个文件----进过确认正确的
```

**查看子目录下的文件：**

```bash
TINY4412 # fatls mmc 0 /12345 
Partition1: Start Address(0x71c53a), Size(0x2025c6)
            ./
            ../
            5567/

0 file(s), 3 dir(s)
```

![image-20220124134543267](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124134543267.png)

### 2.13 从一个MMC文件系统(fat)中加载一个二进制文件到DDR

查看帮助：

```bash
TINY4412 # help fatload
fatload - fatload - load binary file from a dos filesystem
Usage:
fatload <interface> <dev[:part]>  <addr> <filename> [bytes]
    - load binary file 'filename' from 'dev' on 'interface'
      to address 'addr' from dos filesystem
```

参数说明：

```bash
<interface>： mmc 或 usb；
dev：       设备编号(可以通过启动时查看或者列出存储器)；
part：       设备分区号；
<addr>：     DDR 内存地址
<filename>： 要加载二进制文件（ 包含完整路径）
[bytes]：要加载数据大小，字节为单位。可选的，可以不写， 不写时候默认等于文件大小。
加载文件需要SD或者EMMC有完好的文件系统。
```

![image-20220124134658482](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124134658482.png)

先将SD卡从开发板取出(开发板不要断电)，通过读卡器插入 PC，复制一些文件到卡里,然后再重新插入开发板中
(SD卡拔出来时开发板不要断电，目的想测试一下 mmc rescan 命令作用)。SD卡拔掉之后，UBOOT一样可以运行，因为程序已经拷贝到DDR中运行了，只要不断电U-BOOT就可以正常运行。

![image-20220124134724136](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124134724136.png)

文件拷贝完将SD卡再放回开发板，先不要重新扫描 mmc 设备，直接输入 fatls 就会出错：

```bash
TINY4412 # fatls mmc 0
 /* 打印错误信息，因为开发板没有断电，设备0是SD卡*/
count: 1
# Tx: Inverter delay / Rx: Inverter delay

count: 2
## Tx: Basic delay / Rx: Inverter delay

count: 3
## Tx: Inverter delay / Rx: Basic delay

count: 4
### Tx: Basic delay / Rx: Basic delay

count: 5
# Tx: Disable / Rx: Basic delay

count: 6
## Tx: Disable / Rx: Inverter delay

count: 7
### Tx: Basic delay / Rx: Disable

count: 8
### Tx: Inverter delay / Rx: Disable
mmc read failed ERROR: -19
data.dest: 0xc3cfbbdc
data.blocks: 1
data.blocksize: 512
MMC_DATA_READ
** Can't read from device 0 **

** Unable to use mmc 0:1 for fatls **
TINY4412 # 
```

**扫描设备0，再读出信息:**

```bash
TINY4412 # mmc rescan 0  扫描设备
TINY4412 # fatls mmc 0    列出设备的文件目录

/* 成功列出了SD卡文件目录信息*/
Partition1: Start Address(0xa203d2), Size(0x2037b2)
            system volume information/
  4783928   zimage 
   277108   u-boot.bin 
   127245   纇/u-boot.pdf 
     5268   2015-12-30txt 
   731729   shell,
                   - a.pdf 

5 file(s), 1 dir(s)
```

![image-20220124134820305](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124134820305.png)

**开始测试 fatload 命令:**

```bash
TINY4412 #  fatload mmc 0 48000000 zimage      将 zimage文件加载到DDR的48000000地址处   
Partition1: Start Address(0xa203d2), Size(0x2037b2)
reading zimage

4783928 bytes read  成功加载文件的大小(字节单位)
TINY4412 # md.b 48000000      打印出DDR 48000000地址处的数据
48000000: 00 00 a0 e1 00 00 a0 e1 00 00 a0 e1 00 00 a0 e1    ................
48000010: 00 00 a0 e1 00 00 a0 e1 00 00 a0 e1 00 00 a0 e1    ................
48000020: 02 00 00 ea 18 28 6f 01 00 00 00 00 38 ff 48 00    .....(o.....8.H.
48000030: 01 70 a0 e1 02 80 a0 e1 00 20 0f e1 03 00 12 e3    .p....... ......
```

![image-20220124134903661](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124134903661.png)

### 2.14 cmp --比较内存数据是否相同

```bash
查看帮助
TINY4412 # ? cmp                     
cmp - memory compare   内存比较

Usage:
cmp [.b, .w, .l] addr1 addr2 count  格式         注意：count 是用十六进制表示
cmp .b :以1个字节方式
cmp .w :以2 个字节方式
cmp .l :以4 个字节方式

格式：
Cmp.b 地址1 地址2 比较数据的数量

①　比较DRR两个地址数据是否相等
TINY4412 # cmp.b 48000000 49000000 10     比较两个地址数据---数量是10个
byte at 0x48000000 (0x00) != byte at 0x49000000 (0xff)
Total of 0 bytes were the same  共有0字节是相同的
TINY4412 # 
②　从MMC读取1个扇区的数据到DDR的两个地址
TINY4412 #  mmc read 0 48000000 1 1

MMC read: dev # 0, block # 1, count 1 ... 1 blocks read: OK
TINY4412 #  mmc read 0 49000000 1 1

MMC read: dev # 0, block # 1, count 1 ... 1 blocks read: OK
 
③　再次比较两个地址的数据
TINY4412 # cmp.b 48000000 49000000 10   ( 注意：这里的10是十六进制的10 ，转成十进制就是16)
Total of 16 bytes were the same  共有16个字节都是一样的。
```

### 2.15 mm --地址以自动增加的方式修改内存数据

```bash
查看帮助：
TINY4412 # ? mm
mm - memory modify (auto-incrementing address)  修改内存(增加的地址)

Usage:
mm [.b, .w, .l] address   格式： address要修改的地址

①　先将DDR某处数据打印出来，方便修改完比较
TINY4412 # md.b 48000000 10
48000000: a3 69 d3 18 e9 7d b9 66 d1 6b d5 6e d4 79 a6 79    .i...}.f.k.n.y.y

②　修改数据
TINY4412 # mm.b 48000000             
48000000: a3 ? 5   //把a3 修改为5
48000001: 69 ? 6   //把69 修改为6
48000002: d3 ? 7
48000003: 18 ? 8
48000004: e9 ?       不想修改直接按下<回车键>跳过
48000005: 7d ? 9
48000006: b9 ? TINY4412 # <INTERRUPT>   修改完直接按ctrl+c 结束

③　再次查看数据
TINY4412 # md.b 48000000 10
48000000: 05 06 07 08 e9 09 b9 66 d1 6b d5 6e d4 79 a6 79    .......f.k.n.y.y  修改之后的数据

将修改之前的数据与修改之后的比较，发现已经修改成功！
其他类似命令：
mm.w：一次修改 2 字节
mm.l：一次修改 4 字节
```

### 2.16 cp –内存拷贝

```bash
查看帮助：
TINY4412 # ? cp
cp - memory copy   内存复制

Usage:  用法格式
cp [.b, .w, .l] source target count   注意这里的数量是用16进制表示的
格式：cp.b 源地址 目标地址 数量
①　读出DDR两个地址的数据，方便后面比较
TINY4412 # md.b 45000000 10   显示数据
45000000: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff     ................
TINY4412 # md.b 49000000 10   显示数据
49000000: a3 69 d3 18 e9 7d b9 66 d1 6b d5 6e d4 79 a6 79    .i...}.f.k.n.y.y
②　将DDR的4900000地址前10个字节拷贝到45000000地址处
TINY4412 # cp 49000000 45000000 10

③　将两处地址的数据再显示出来
TINY4412 # md.b 45000000 10         
45000000: a3 69 d3 18 e9 7d b9 66 d1 6b d5 6e d4 79 a6 79    .i...}.f.k.n.y.y
TINY4412 # md.b 49000000 10
49000000: a3 69 d3 18 e9 7d b9 66 d1 6b d5 6e d4 79 a6 79    .i...}.f.k.n.y.y
拷贝之后，将两处地址数据再次比较，两边数据是一样的。
```

### 2.17 loady - 使用串口下载二进制数据到内存中

U-BOOT支持的串口传输模式：

```bash
loadb   - load binary file over serial line (kermit mode)
loads   - load S-Record file over serial line
loady   - load binary file over serial line (ymodem mode)
```

串口下载文件到DDR，上面是U-BOOT支持串口的3种传输模式。

CRT串口终端支持的协议：

![image-20220124135202201](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124135202201.png)

```bash
查看帮助：
TINY4412 # ? loady
Unknown command '' - try 'help' without arguments for list of all known commands

loady - load binary file over serial line (ymodem mode)
用在串行线加载二进制文件(ymodem模式)

Usage:
loady [ off ] [ baud ]
    - load binary file over serial line with offset 'off' and baudrate 'baud'
参数说明：
[ off ]： DDR 内存地址， 可选。
[ baud ]：使用多快的波特率下载， 可选，不填就表示默认的115200波特率。
示例：
loady 0x40000000 115200
```

**测试loady命令：**

（1）下载文件到内存

```bash
TINY4412 # loady 40000000	下载文件到DDR 40000000地址
## Ready for binary (ymodem) download to 0x40000000 at 0 bps...
```

![image-20220124135312187](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124135312187.png)

![image-20220124135330283](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124135330283.png)

（2）对比数据内容

![image-20220124135349614](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124135349614.png)

（3）执行代码

上面下载的bin文件是一个按键的裸机程序，可以用go命令跳转到指定地址去执行下载的代码。

```bash
TINY4412 # go 40000000
## Starting application at 0x40000000 ...
跳转过去之后，按下按键测试！ 测试结果正常，按键程序可以正常执行。
```

### 2.18 go–CPU 跳转到指定的地址执行代码

一旦 go 指令执行后， CPU 就会去执行指定地址处的代码。

**查看帮助：**

```bash
TINY4412 # ? go
go - start application at address 'addr'
     在addr处启动应用程序

Usage:
go addr [arg ...]
    - start application at address 'addr'
      passing 'arg' as arguments 作为参数传递的参数
```

**测试go命令**

```bash
将SD卡第一个扇区数据读到DDR内存中等待执行。读8个扇区
TINY4412 # mmc read 0 45000000 1 8   

MMC read: dev # 0, block # 1, count 8 ... 8 blocks read: OK

跳转到45000000地址去执行程序
TINY4412 # go 45000000 
## Starting application at 0x45000000 ...   开始执行地址处的代码，因为扇区1开始存放的是BL1代码，重新执行启动了UBOOT
OK

U-Boot 2010.12 (Jan 01 2016 - 02:37:55) for TINY4412

CPU:    S5PC220 [Samsung SOC on SMP Platform Base on ARM CortexA9]
        APLL = 1400MHz, MPLL = 800MHz

Board:  TINY4412
DRAM:   1023 MiB
...........................................................................................................
```

![image-20220124135654581](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124135654581.png)

### 2.19 打开关闭emmc设备引导分区

```bash
查看帮助：
TINY4412 # ? emmc
emmc - Open/Close eMMC boot Partition  打开/关闭emmc引导分区

Usage:
emmc open <device num> 
emmc close <device num> 

对设备读写操作，需要先打开，读写完毕，再关闭。
示例： 
emmc close 1    打开设备1
emmc open 1    关闭设备1

emmc close 0    打开设备0
emmc open 0    关闭设备0
```

### 2.20 movi 子系统----从MMC向DDR读写数据

该指令在产品发布时需要用到，用来固化内核和UBOOT。

**查看帮助：**

```bash
TINY4412 # ? movi
movi - movi     - sd/mmc r/w sub system for SMDK board

Usage:
movi init - Initialize moviNAND and show card info
movi read zero {fwbl1 | u-boot} {device_number} {addr} - Read data from sd/mmc  读取数据从sd / mmc
movi write zero {fwbl1 | u-boot} {device_number} {addr} - Read data from sd/mmc  读取数据从sd / mmc
movi read {u-boot | kernel} {device_number} {addr} - Read data from sd/mmc      读取数据从sd / mmc
movi write {fwbl1 | u-boot | kernel} {device_number} {addr} - Write data to sd/mmc 写入数据到sd / mmc
movi read rootfs {device_number} {addr} [bytes(hex)] - Read rootfs data from sd/mmc by size       从sd/mmc读取rootfs数据大小
movi write rootfs {device_number} {addr} [bytes(hex)] - Write rootfs data to sd/mmc by size        写rootfs sd/mmc的数据大小
movi read {sector#} {device_number} {bytes(hex)} {addr} - instead of this, you can use "mmc read"
movi write {sector#} {device_number} {bytes(hex)} {addr} - instead of this, you can use "mmc write"
```

**（1）把 sd 卡中 u-boot 的第一阶段的 bl1 数据复制到内存，然后再写入 emmc 对应位置**

```bash
movi read fwbl1 0 40000000;       //从SD(设备编号为)拷贝bl1到DDR内存地址
emmc open 1;                   //打开EMMC设备
movi write zero fwbl1 1 40000000;   //将DDR地址处数据写入到EMMC对应位置
emmc close 1;                    //关闭EMMC设备
```

**用法示例：**

```bash
TINY4412 # movi read fwbl1 0 40000000;
reading FWBL1 ..device 0 Start 1, Count 16 
MMC read: dev # 0, block # 1, count 16 ... 16 blocks read: OK  从SD卡第1个扇区开始读，连续读16个扇区
completed
TINY4412 # emmc open 1;
eMMC OPEN Success.!!
                        !!!Notice!!!
!You must close eMMC boot Partition after all image writing!
!eMMC boot partition has continuity at image writing time.!
!So, Do not close boot partition, Before, all images is written.!
TINY4412 # movi write zero fwbl1 1 40000000; 
writing FWBL1 ..device 1 Start 0, Count 16 
MMC write: dev # 1, block # 0, count 16 ... 16 blocks written: OK 从EMMC第0个扇区写，连续写16个扇区
completed
TINY4412 # emmc close 1; 
eMMC CLOSE Success.!!

因为SD卡的特性，第0个扇区不能使用，数据只能从第1个扇区开始存放。
EMMC可以直接从第0个扇区存放数据。
所以-----EMMC的第0个扇区相当于SD卡的第1个扇区
```

![image-20220124140004454](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124140004454.png)

**（2）把sd卡中u-boot的BL2 数据复制到内存，然后再写入 emmc 对应位置**

```bash
movi read bl2 0 40000000;     //从SD(设备编号为0)拷贝bl2到DDR内存地址
emmc open 1;                 //打开EMMC设备
movi write zero bl2 1 40000000; //将DDR地址处数据写入到EMMC对应位置
emmc close 1;                 //关闭EMMC设备
```

**示例：**

```bash
TINY4412 # movi read bl2 0 40000000
reading BL2 ..device 0 Start 17, Count 32 
MMC read: dev # 0, block # 17, count 32 ... 32 blocks read: OK  //从SD卡的第17个扇区开始读，连续读32个扇区。
                                                    //查看UBOOT烧写脚本可知，BL2是从SD卡第17扇区开始烧写的
completed
TINY4412 # emmc open 1          
eMMC OPEN Success.!!
                        !!!Notice!!!
!You must close eMMC boot Partition after all image writing!
!eMMC boot partition has continuity at image writing time.!
!So, Do not close boot partition, Before, all images is written.!
TINY4412 # movi write zero bl2 1 40000000    
writing BL2 ..device 1 Start 16, Count 32 
MMC write: dev # 1, block # 16, count 32 ... 32 blocks written: OK   //向EMMC的第17个扇区开始写，连续写32个扇区。
completed
TINY4412 # emmc close 1
eMMC CLOSE Success.!!
```

![image-20220124140109626](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124140109626.png)

**（3）把 sd 卡中 u-boot 复制到内存，然后再写入 emmc 对应位置**

```bash
movi read u-boot 0 40000000;      将SD卡的U-BOOT.Bin读到DDR内存空间
emmc open 1;                   打开EMMC设备
movi write zero u-boot 1 40000000;  将DDR的数据写入EMMC设备
emmc close 1;                    关闭EMMC
```

**示例：**

```bash
TINY4412 # movi read u-boot 0 40000000
reading bootloader..device 0 Start 49, Count 656 
MMC read: dev # 0, block # 49, count 656 ... 656 blocks read: OK  从SD卡第49个扇区开始，读取656个扇区到DDR内存
completed
TINY4412 # emmc open 1
eMMC OPEN Success.!!
                        !!!Notice!!!
!You must close eMMC boot Partition after all image writing!
!eMMC boot partition has continuity at image writing time.!
!So, Do not close boot partition, Before, all images is written.!
TINY4412 # movi write zero u-boot 1 40000000
writing bootloader..device 1 Start 48, Count 656       
MMC write: dev # 1, block # 48, count 656 ... 656 blocks written: OK 向EMMC的第49个扇区，连续写入656个扇区到DDR内存
completed
TINY4412 # emmc close 1
eMMC CLOSE Success.!!
```

![image-20220124140204306](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124140204306.png)

**（4）把 sd 卡中 u-boot 安全加密数据复制到内存，然后再写入 emmc 对应位置**

```bash
movi read tzsw 0 40000000;      将安全加密数据拷贝到DDR
emmc open  1;                打开EMMC设备
movi write zero tzsw 1 40000000;  将DDR数据写入EMMC
emmc close 1;                  关闭EMMC设备
```

**示例：**

```bash
TINY4412 # movi read tzsw 0 40000000
reading 0 TrustZone S/W.. Start 705, Count 320 
MMC read: dev # 0, block # 705, count 320 ... 320 blocks read: OK  从SD卡的第705个扇区开始，连续读取320个扇区到DDR
Completed                                              安全加密数据是从SD的705个扇区存放的
TINY4412 # emmc open  1
eMMC OPEN Success.!!
                        !!!Notice!!!
!You must close eMMC boot Partition after all image writing!
!eMMC boot partition has continuity at image writing time.!
!So, Do not close boot partition, Before, all images is written.!
TINY4412 # movi write zero tzsw 1 40000000;
writing 1 TrustZone S/W.. Start 704, Count 320 
MMC write: dev # 1, block # 704, count 320 ... 320 blocks written: OK  写入EMMC
completed
TINY4412 # emmc close 1
eMMC CLOSE Success.!!
```

![image-20220124140305180](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124140305180.png)

![image-20220124140317064](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124140317064.png)

**（5）把 sd 卡中内核数据复制到内存，然后再写入 emmc 对应位置**

```bash
movi read kernel 0 40000000;     将SD卡的内核数据读到DDR内存中
movi write kernel 1 40000000;     将DDR的数据写入EMMC中
```

**示例：**

```bash
TINY4412 # movi read kernel 0 40000000
reading kernel..device 0 Start 1057, Count 12288 
MMC read: dev # 0, block # 1057, count 12288 ... 12288 blocks read: OK  从SD卡1057扇区开始，连续读12288个扇区到DDR
completed
TINY4412 # movi write kernel 1 40000000
writing kernel..device 1 Start 1057, Count 12288 
MMC write: dev # 1, block # 1057, count 12288 ... 12288 blocks written: OK将DDR的数据写入EMMC，从1057开始写，连续写12288个扇区
completed
```

![image-20220124140413623](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124140413623.png)

### 2.21 movi 精简命令-一键拷贝

将UBOOT和内核数据固化到EMMC精简命令：

```bash
movi r f 0 40008000;emmc open 1;movi w z f 1 40008000;emmc close 1;
movi r b 0 40008000;emmc open 1;movi w z b 1 40008000;emmc close 1;
movi r u 0 40008000;emmc open 1;movi w z u 1 40008000;emmc close 1;
movi r t 0 40008000;emmc open 1;movi w z t 1 40008000;emmc close 1;
movi r k 0 40008000;movi w k 1 40008000;
```

### 2.22 bootcmd命令的使用

**bootcmd**命令是设置U-BOOT启动成功后执行的命令代码。

**示例：**

```bash
set bootcmd 'mmc read 0 40000000 421 1;md.b 40000000'

格式：setenv  ‘ 需要执行的命令’
      Save  //保存设置
```

### 2.23 执行二进制文件–>bootm命令

bootm命令是用来引导经过U-Boot的工具mkimage打包后的kernel image的。

**查看帮助：**

```bash
TINY4412 # ? bootm
bootm - boot application image from memory  //bootm从内存中启动应用程序

Usage:
bootm [addr [arg ...]]
    - boot application image stored in memory
        passing arguments 'arg ...'; when booting a Linux kernel,
        'arg' can be the address of an initrd image
//传递参数的参数…”;当引导Linux内核,“参数”可以是映像文件的地址

Sub-commands to do part of the bootm sequence.  The sub-commands must be
issued in the order below (it's ok to not issue all sub-commands):
        start [addr [arg ...]]
        loados  - load OS image  加载操作系统映像
        cmdline - OS specific command line processing/setup 操作系统特定的命令行处理/设置
        bdt     - OS specific bd_t processing 操作系统特定bd_t处理
        prep    - OS specific prep before relocation or go 
        go      - start OS 启动操作系统
```

**示例：**

（1）直接引导内核

```bash
TINY4412 # mmc read 0 40007fc0 421 3000  
将SD卡内核读到DDR内存空间----内核映像是从SD卡1057扇区开始存放的，连续占用了12288个扇区 
(注意： 421是0x421  3000是0x3000)
MMC read: dev # 0, block # 1057, count 12288 ... 12288 blocks read: OK

TINY4412 # bootm 40007fc0   执行DDR--40007fc0地址处的二进制文件
Boot with zImage

Starting kernel ...

Uncompressing Linux... done, booting the kernel.    
```

![image-20220124140814996](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124140814996.png)

（2）设置UBOOT启动成功自动引导内核

```bash
TINY4412 # setenv bootcmd 'mmc read 0 40007fc0 421 3000;bootm 40007fc0' U-BOOT启动成功之后自动执行
TINY4412 # save 保存设置
或者使用bootcmd=movi read kernel 0 40008000;movi read rootfs 0 41000000 100000;bootm 40008000 41000000
```

![image-20220124140849754](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124140849754.png)

### 2.24 分区命令-fdisk

**查看帮助:**

```bash
TINY4412 # ? fdisk
fdisk - fdisk for sd/mmc. //硬盘分区工具
Usage:
fdisk -p <device_num>   - print partition information    //打印分区信息
fdisk -c <device_num> [<sys. part size(MB)> <user data part size> <cache part size>]
        - create partition  //创建分区(分区单位是M)
```

（1）查看分区信息示例

```bash
TINY4412 # fdisk -p 0   //查看SD卡分区信息

分区          大小        扇区开始地址        扇区数量(512字节一个扇区)         分区ID名称
partion #    size(MB)        block start #             block count                        partition_Id 
   1          1028          7456058              2106822                           0x06 
   4             0         28049408               441                              0x00 
```

![image-20220124141021889](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124141021889.png)

（2）给SD卡分区示例

(分区时–会自行在SD卡开头大约66M后的空间开始分区，因为开头部分需要用来存放内核与U-BOOT)

```bash
TINY4412 # fdisk -c 0 320 2057 520    //给SD卡分区， -c 表示分区
fdisk is completed     //提示分区完成

分区          大小        扇区开始地址        扇区数量(512字节一个扇区)         分区ID名称
partion #    size(MB)     block start #               block count                     partition_Id 
   1          4416          6090216              9045762                        0x0C 
   2           320           134343              656788                         0x83 
   3          2062           791131              4224341                        0x83 
   4           524          5015472              1074744                        0x83 
```

![image-20220124141108289](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124141108289.png)

### 2.25 指定EMMC的分区文件系统格式

U-BOOT支持格式化的文件系统格式：

```bash
fatformat- fatformat - disk format by FAT32
ext3format- ext3format - disk format by ext3
ext2format- ext2format - disk format by ext2
```

查看 fatformat命令使用帮助：

```bash
TINY4412 # ? fatformat
fatformat - fatformat - disk format by FAT32
            指定磁盘的格式位FAT32

Usage:
fatformat <interface(only support mmc)> <dev:partition num>  用法格式
        - format by FAT32 on 'interface'      

其他两个命令，用法一样！
```

**（1）指定分区命令-用法示例**

```bash
fatformat  mmc 0:1 	    //表示将第0个盘的第一个分区初始化为 fat
ext3format mmc 0:2 	    //表示将第0个盘的第二个分区初始化为 ext3
ext2format mmc 0:3       //表示将第0个盘的第三个分区初始化为  ext2
ext3format mmc 0:4	    //表示将第0个盘的第四个分区初始化为  ext3
```

![image-20220124141306110](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124141306110.png)

**（2）SD卡分区文件系统格式化完毕，将SD卡插入电脑，查看SD卡的分区信息**

![image-20220124141338477](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124141338477.png)

**（3）将SD卡挂载进虚拟机，查看设备节点。**

![image-20220124141411181](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124141411181.png)

![image-20220124141436392](https://gitee.com/dsxiaolong/blog-drawing-bed/raw/master/img/image-20220124141436392.png)


> 
> Source: 华为云社区-DS小龙哥
> 
> Link: https://bbs.huaweicloud.com/community/usersnew/id_1637904384607931
> 