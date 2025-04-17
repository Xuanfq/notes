# GRUB

GRUB, GRand Unified Bootloader, 大统一引导加载程序.

GRUB 是 Linux 系统中最常用的 bootloader 之一，支持多操作系统启动，包括 Windows 和 macOS。 

**本文主讲GRUB2**


## 基础内容

### grub2和grub的区别

1. 配置文件名称：在grub中，配置文件为grub.conf或menu.lst(grub.conf的一个软链接)，在grub2中改名为`grub.cfg`。
2. 语法：grub2增添了许多语法，更接近于脚本语言了，例如支持变量、条件判断、循环。
3. 设备分区：grub2中，设备分区名称从1开始，而在grub中是从0开始的。
4. 引导文件：grub2使用img文件，不再使用grub中的stage1、stage1.5和stage2。
5. 支持图形界面配置grub：但要安装grub-customizer包，epel源提供该包。
6. 操作系统无法进入grub交互：在已进入操作系统环境下，不再提供grub命令，也就是不能进入grub交互式界面，只有在开机时才能进入，算是一大缺憾。
7. find命令缺陷：在grub2中没有了好用的find命令，算是另一大缺憾。


### grub2命名习惯和文件路径

- (fd0)           ：表示第一块软盘；GRUB 要求设备名称用单引号括起来。“fd” 部分表示它是一个软盘。数字 “0” 是驱动器编号，从零开始计数。这个表达式意味着 GRUB 将使用整个软盘。
- (hd0,msdos2)    ：表示第一块硬盘的第二个mbr分区；grub2中分区从1开始编号，传统的grub是从0开始编号的
- (hd0,msdos5)    ：表示第一个硬盘的第一个扩展分区。请注意，扩展分区的分区编号从`5`开始计数，而与硬盘上实际的主分区数量无关
- (hd0,gpt1)      ：表示第一块硬盘的第一个gpt分区
- /boot/vmlinuz   ：相对路径，基于根目录，表示根目录下的boot目录下的vmlinuz，
-                 ：如果设置了根目录变量root为(hd0,msdos1)，则表示(hd0,msdos1)/boot/vmlinuz
- (hd0,msdos1)/boot/vmlinuz：绝对路径，表示第一硬盘第一分区的boot目录下的vmlinuz文件


### grub2引导操作系统的方式

支持两种方式引导操作系统：

- 直接引导：(direct-load)直接通过默认的grub2 boot loader来引导写在默认配置文件中的操作系统
- 链式引导：(chain-load)使用默认grub2 boot loader链式引导另一个boot loader，该boot loader将引导对应的操作系统

一般只使用第一种方式，只有想引导grub默认不支持的操作系统时才会使用第二种方式。


### grub2程序和传统grub程序安装后的文件分布

- 在传统grub软件安装完后，在/usr/share/grub/RELEASE/目录下会生成一些stage文件

```sh
[root@server ~]# ls /usr/share/grub/x86_64-redhat/
e2fs_stage1_5      ffs_stage1_5       jfs_stage1_5       reiserfs_stage1_5  stage2             ufs2_stage1_5      xfs_stage1_5
fat_stage1_5       iso9660_stage1_5   minix_stage1_5     stage1             stage2_eltorito    vstafs_stage1_5
```

- 在grub2软件安装完后，会在/usr/lib/grub/i386-pc/目录下生成很多模块文件和img文件，还包括一些lst列表文件

```sh
[root@server ~]# ls /usr/lib/grub/i386-pc/*.mod | wc -l
257

[root@server ~]# ls -lh /usr/lib/grub/i386-pc/*.lst   
-rw-r--r--. 1 root root 3.7K Nov 24  2015 /usr/lib/grub/i386-pc/command.lst
-rw-r--r--. 1 root root  936 Nov 24  2015 /usr/lib/grub/i386-pc/crypto.lst
-rw-r--r--. 1 root root  214 Nov 24  2015 /usr/lib/grub/i386-pc/fs.lst
-rw-r--r--. 1 root root 5.1K Nov 24  2015 /usr/lib/grub/i386-pc/moddep.lst
-rw-r--r--. 1 root root  111 Nov 24  2015 /usr/lib/grub/i386-pc/partmap.lst
-rw-r--r--. 1 root root   17 Nov 24  2015 /usr/lib/grub/i386-pc/parttool.lst
-rw-r--r--. 1 root root  202 Nov 24  2015 /usr/lib/grub/i386-pc/terminal.lst
-rw-r--r--. 1 root root   33 Nov 24  2015 /usr/lib/grub/i386-pc/video.lst

[root@server ~]# ls -lh /usr/lib/grub/i386-pc/*.img
-rw-r--r--. 1 root root  512 Nov 24  2015 /usr/lib/grub/i386-pc/boot_hybrid.img
-rw-r--r--. 1 root root  512 Nov 24  2015 /usr/lib/grub/i386-pc/boot.img
-rw-r--r--. 1 root root 2.0K Nov 24  2015 /usr/lib/grub/i386-pc/cdboot.img
-rw-r--r--. 1 root root  512 Nov 24  2015 /usr/lib/grub/i386-pc/diskboot.img
-rw-r--r--. 1 root root  28K Nov 24  2015 /usr/lib/grub/i386-pc/kernel.img
-rw-r--r--. 1 root root 1.0K Nov 24  2015 /usr/lib/grub/i386-pc/lnxboot.img
-rw-r--r--. 1 root root 2.9K Nov 24  2015 /usr/lib/grub/i386-pc/lzma_decompress.img
-rw-r--r--. 1 root root 1.0K Nov 24  2015 /usr/lib/grub/i386-pc/pxeboot.img
```


### Boot Loader和GRUB的关系

当使用grub来管理启动菜单时，那么boot loader都是grub程序安装的。

传统grub：将stage1转换后的内容安装到MBR(VBR或EBR)中的boot loader部分，将stage1_5转换后的内容安装在紧跟在MBR后的扇区中，将stage2转换后的内容安装在/boot分区中。

grub2：将boot.img转换后的内容安装到MBR(VBR或EBR)中的boot loader部分，将diskboot.img和kernel.img结合成为core.img，同时还会嵌入一些模块或加载模块的代码到core.img中，然后将core.img转换后的内容安装到磁盘的指定位置处。boot.img的位置是固定在MBR或VBR或EBR上的。


### grub2的安装位置

严格地说是core.img的安装位置，因为boot.img的位置是固定在MBR或VBR或EBR上的。

#### MBR

MBR格式的分区表用于PC BIOS平台，这种格式允许四个主分区和额外的逻辑分区。使用这种格式的分区表，有两种方式安装GURB：

1. 嵌入到MBR和第一个分区中间的空间，这部分就是大众所称的"boot track","MBR gap"或"embedding area"，它们大致需要31kB的空间。（推荐）
   - 缺陷：没有保留的空闲空间来保证安全性，例如有些专门的软件就是使用这段空间来实现许可限制的；另外分区的时候，虽然会在MBR和第一个分区中间留下空闲空间，但可能留下的空间会比这更小。
2. 将core.img安装到某个文件系统中，然后使用分区的第一个扇区(严格地说不是第一个扇区，而是第一个block)存储启动它的代码。
   - 缺陷：这样的grub是脆弱的。例如，文件系统的某些特性需要做尾部包装，甚至某些fsck检测，它们可能会移动这些block。


**GRUB开发团队建议将GRUB嵌入到MBR和第一个分区之间，除非有特殊需求，但仍必须要保证第一个分区至少是从第31kB(第63个扇区)之后才开始创建的。**

现在的磁盘设备，一般都会有分区边界对齐的性能优化提醒，所以第一个分区可能会自动从第1MB处开始创建。


#### GPT

一些新的系统使用GUID分区表(GPT)格式，这种格式是EFI固件所指定的一部分。但如果操作系统支持的话，GPT也可以用于BIOS平台(即MBR风格结合GPT格式的磁盘)，使用这种格式，需要使用**独立的BIOS boot分区**来保存GRUB，GRUB被嵌入到此分区，不会有任何风险。

当在gpt磁盘上创建一个BIOS boot分区时，需要保证两件事：
- 它最小是31kB大小，但一般都会为此分区划分1MB的空间用于可扩展性；
- 必须要有合理的分区类型标识(flag type)。

例如使用gun parted工具时，可以设置为bios_grub标识：

```sh
# parted /dev/sda toggle partition_num bios_grub
# parted /dev/sda set partiton_num bios_grub on
```

如果使用gdisk分区工具时，则分类类型设置为"EF02"。

如果使用其他的分区工具，可能需要指定guid，则可以指定其guid为"21686148-6449-6e6f-744e656564454649"。

某个bios/gpt格式的bios boot分区信息，从中可见，它大小为1M，没有文件系统，分区表示为bios_grub：
```sh
[~]# parted /dev/sda p
Model: VMware, VMware Virtual S (scsi)
Disk /dev/sda: 64.4GB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags: pmbr_boot

Number  Start   End     Size    File system     Name    Flags
1       1049kB  2097kB  1049kB                          bios_grub
...
```


### 进入grub2命令行

在grub界面，按下e见可以编辑所选菜单对应的grub菜单配置项，按下c键可以进入grub命令行交互模式



## GRUB安装

这里的安装指的不是安装grub程序，而是安装Boot Loader，但一般都称之为安装grub，且后文也是这个意思。


### 安装命令

安装工具是`grub-install`或`grub2-install`, 看版本编译结果。

安装方式非常简单，只需调用grub-install，然后给定安装到的设备名即可：
```sh
shell> grub-install /dev/sda
```

这样的安装方式，默认会将img文件放入到/boot目录下，如果想自定义放置位置，则使用--boot-directory选项指定，可用于测试练习grub的时候使用，但在真实的grub环境下不建议做任何改动：
```sh
shell> grub-install --boot-director=/mnt/boot /dev/fd0
```

如果是EFI固件平台，则必须挂载好efi系统分区，一般会挂在/boot/efi下，这是默认的，此时可直接使用grub-install安装：
```sh
shell> grub-install
```

如果不是挂载在/boot/efi下，则使用--efi-directory指定efi系统分区路径：
```sh
shell> grub-install --efi-directory=/mnt/efi
```

grub-install实际上是一个shell脚本，用于调用其他工具，真正的功能都是其他工具去完成的，所以如果非常熟悉grub内部命令和机制，完全可以不用grub-install。

对应传统的grub安装命令也是grub-install，用法和grub2-install一样。


### img和stage

img文件是grub2生成的，stage文件是传统grub生成的。


#### grub2中的img文件

grub2生成了好几个img文件，有些分布在/usr/lib/grub/i386-pc目录下，有些分布在/boot/grub2/i386-pc目录下：

```sh
[root@xxx ~]# find /boot/grub2 -name "*.img" | xargs ls
/boot/grub2/i386-pc/boot.img
/boot/grub2/i386-pc/core.img
...
[root@xxx ~]# ls /usr/lib/grub/i386-pc/*.img
/usr/lib/grub/i386-pc/boot_hybrid.img
/usr/lib/grub/i386-pc/boot.img
/usr/lib/grub/i386-pc/cdboot.img
/usr/lib/grub/i386-pc/diskboot.img
/usr/lib/grub/i386-pc/kernel.img
/usr/lib/grub/i386-pc/lnxboot.img
/usr/lib/grub/i386-pc/lzma_decompress.img
/usr/lib/grub/i386-pc/pxeboot.img
```

各img之间的关系：

- boot.img
- core.img
  - diskboot.img | cdboot.img | pxeboot.img: core.img第一扇区, 512B
  - kernel.img
  - modules
  - ...

1. boot.img

在BIOS平台下，boot.img是grub启动的第一个img文件，它被写入到MBR中或分区的boot sector中，因为boot sector的大小是512字节，所以该img文件的大小也是512字节。

boot.img唯一的作用是读取属于core.img的第一个扇区并跳转到它身上，将控制权交给该扇区的img。由于体积大小的限制，boot.img无法理解文件系统的结构，因此grub2-install将会把core.img的位置硬编码到boot.img中，这样就一定能找到core.img的位置。

2. core.img

core.img根据diskboot.img、kernel.img和一系列的模块被grub2-mkimage程序动态创建。core.img中嵌入了足够多的功能模块以保证grub能访问/boot/grub，并且可以加载相关的模块实现相关的功能，例如加载启动菜单、加载目标操作系统的信息等，由于grub2大量使用了动态功能模块，使得core.img体积变得足够小。

core.img中包含了多个img文件的内容，包括diskboot.img/kernel.img等。

core.img的安装位置随MBR磁盘和GPT磁盘而不同，这在上文中已经说明过了。

3. diskboot.img

如果启动设备是硬盘，即从硬盘启动时，core.img中的第一个扇区的内容就是diskboot.img。diskboot.img的作用是读取core.img中剩余的部分到内存中，并将控制权交给kernel.img，由于此时还不识别文件系统，所以将core.img的全部位置以block列表的方式编码，使得diskboot.img能够找到剩余的内容。

该img文件因为占用一个扇区，所以体积为512字节。

4. cdboot.img

如果启动设备是光驱(cd-rom)，即从光驱启动时，core.img中的第一个扇区的的内容就是cdboot.img。它的作用和diskboot.img是一样的。

5. pexboot.img

如果是从网络的PXE环境启动，core.img中的第一个扇区的内容就是pxeboot.img。

6. kernel.img

kernel.img文件包含了grub的基本运行时环境：设备框架、文件句柄、环境变量、救援模式下的命令行解析器等等。很少直接使用它，因为它们已经整个嵌入到了core.img中了。注意，kernel.img是grub的kernel，和操作系统的内核无关。

如果细心的话，会发现kernel.img本身就占用28KB空间，但嵌入到了core.img中后，core.img文件才只有26KB大小。这是因为core.img中的kernel.img是被压缩过的。

7. lnxboot.img

该img文件放在core.img的最前部位，使得grub像是linux的内核一样，这样core.img就可以被LILO的"image="识别。当然，这是配合LILO来使用的，但现在谁还适用LILO呢？

8. *.mod

各种功能模块，部分模块已经嵌入到core.img中，或者会被grub自动加载，但有时也需要使用insmod命令手动加载。


#### grub(传统)中的stage文件

stage文件也分布在两个地方：/usr/share/grub/RELEASE目录下和/boot/grub目录下，/boot/grub目录下的stage文件是安装grub时从/usr/share/grub/RELEASE目录下拷贝过来的:
```sh
[root@xxx]# ls /usr/share/grub/x86_64-redhat/
e2fs_stage1_5
fat_stage1_5
ffs_stage1_5
iso9660_stage1_5
jfs_stage1_5
minix_stage1_5
reiserfs_stage1_5
stage1
stage2
stage2_eltorito
ufs2_stage1_5
ufs_stage1_5
vstafs_stage1_5
[root@xxx]# find /boot/grub -name "*stage*" | xargs ls
/boot/grub/efi_fat_stage1_5
/boot/grub/fat_stage1_5
/boot/grub/ffs_stage1_5
/boot/grub/iso9660_stage1_5
/boot/grub/jfs_stage1_5
/boot/grub/minix_stage1_5
/boot/grub/reiserfs_stage1_5
/boot/grub/stage1
/boot/grub/stage2
/boot/grub/sunfat_stage1_5
/boot/grub/ufs_stage1_5
/boot/grub/vstafs_stage1_5
```

1. stage1

stage1文件在功能上等价于boot.img文件。目的是跳转到stage1_5或stage2的第一个扇区上。

2. *_stage1_5

*stage1_5文件包含了各种识别文件系统的代码，使得grub可以从文件系统中读取体积更大功能更复杂的stage2文件。从这一方面考虑，它类似于core.img中加载对应文件系统模块的代码部分，但是core.img的功能远比stage1_5多。

stage1_5一般安装在MBR后、第一个分区前的那段空闲空间中，也就是MBR gap空间，它的作用是跳转到stage2的第一个扇区。

其实传统的grub在某些环境下是可以不用stage1_5文件就能正常运行的，但是grub2则不能缺少core.img。

3. stage2

stage2的作用是加载各种环境和加载内核，在grub2中没有完全与之相对应的img文件，但是core.img中包含了stage2的所有功能。

当跳转到stage2的第一个扇区后，该扇区的代码负责加载stage2剩余的内容。

注意，stage2是存放在磁盘上的，并没有像core.img一样嵌入到磁盘上。

4. stage2_eltorito

功能上等价于grub2中的core.img中的cdboot.img部分。一般在制作救援模式的grub时才会使用到cd-rom相关文件。

5. pxegrub

功能上等价于grub2中的core.img中的pxeboot.img部分。


### 安装过程

#### grub2

安装grub2的过程大体分两步：

1. 根据/usr/lib/grub/i386-pc/目录下的文件生成core.img，并拷贝boot.img和core.img涉及的某些模块文件(*.mod)到/boot/grub2/i386-pc/目录下；
2. 根据/boot/grub2/i386-pc目录下的文件向磁盘上写boot loader:
   1. ​​写入 boot.img​: 将 boot.img（512 字节）写入磁盘的 ​​MBR 或分区引导扇区​​。boot.img 的唯一任务是加载 core.img 的剩余部分。
   2. ​​写入 core.img: core.img 被写入 ​​MBR 后的保留扇区​​（通常为 1~63 扇区），或分区的连续扇区。写入时使用 ​​块列表编码​​（block list），直接记录 core.img 的物理扇区位置，绕过文件系统依赖。
   3. 安装工具（如 grub2-install）会读取 /boot/grub2/i386-pc/ 下的文件，确保引导代码与模块路径一致。

其他：

1. ​​配置文件生成​​: 安装后需通过 grub2-mkconfig 生成 /boot/grub2/grub.cfg，该步骤通常由 update-grub 触发，属于安装后的配置阶段。
2. ​​UEFI 与 BIOS 差异: 
   - ​​BIOS 模式​​：依赖 boot.img 和 core.img 的分阶段加载。
   - ​​UEFI 模式​​：直接生成 .efi 文件到 EFI 系统分区(一般/boot/efi/xxx(onie)/grubx64.efi)，无需 boot.img。
3. ​​动态模块加载​: core.img 仅嵌入必要模块，其他模块（如网络驱动）在运行时按需从 /boot/grub2/i386-pc/ 加载。


#### 传统grub

对于传统的grub而言，拷贝的不是img文件，而是stage文件。

以下是安装传统grub时，grub做的工作。很不幸，grub2上没有该命令，也没有与之等价的命令:
```sh
grub> setup (hd0)
 Checking if "/boot/grub/stage1" exists... yes
 Checking if "/boot/grub/stage2" exists... yes
 Checking if "/boot/grub/e2fs_stage1_5" exists... yes
 Running "embed /boot/grub/e2fs_stage1_5 (hd0)"...  15 sectors are embedded.
succeeded
 Running "install /boot/grub/stage1 (hd0) (hd0)1+15 p (hd0,0)/boot/grub/stage2 /boot/grub/menu.lst"... succeeded
Done.
```

首先检测各stage文件是否存在于/boot/grub目录下，随后嵌入stage1_5到磁盘上，该文件系统类型的stage1_5占用了15个扇区，最后安装stage1，并告知stage1 stage1_5的位置是第1到第15个扇区，之所以先嵌入stage1_5再嵌入stage1就是为了让stage1知道stage1_5的位置，最后还告知了stage1 stage2和配置文件menu.lst的路径。



## 配置文件

grub2的默认配置文件为`/boot/grub2/grub.cfg`。

该配置文件的写法弹性非常大，但绝大多数需要修改该配置文件时，都只需修改其中一小部分内容就可以达成目标。

`grub2-mkconfig`程序可用来生成符合绝大多数情况的grub.cfg文件，默认它会自动尝试探测有效的操作系统内核，并生成对应的操作系统菜单项。使用方法非常简单，只需一个选项"-o"指定输出文件即可。

```sh
shell> grub2-mkconfig -o /boot/grub2/grub.cfg
```


### 手写grub.cfg

```cfg
# 设置一些全局环境变量
set default=0
set fallback=1
set timeout=3

# 将可能使用到的模块一次性装载完
# 支持msdos的模块
insmod part_msdos
# 支持各种文件系统的模块
insmod exfat
insmod ext2
insmod xfs
insmod fat
insmod iso9660

# 定义菜单
menuentry 'CentOS 7' --unrestricted {
        search --no-floppy --fs-uuid --set=root 367d6a77-033b-4037-bbcb-416705ead095
        linux16 /vmlinuz-3.10.0-327.el7.x86_64 root=UUID=b2a70faf-aea4-4d8e-8be8-c7109ac9c8b8 ro biosdevname=0 net.ifnames=0 quiet
        initrd16 /initramfs-3.10.0-327.el7.x86_64.img
}
menuentry 'CentOS 6' --unrestricted {
        search --no-floppy --fs-uuid --set=root f5d8939c-4a04-4f47-a1bc-1b8cbabc4d32
        linux16 /vmlinuz-2.6.32-504.el6.x86_64 root=UUID=edb1bf15-9590-4195-aa11-6dac45c7f6f3 ro quiet
        initrd16 /initramfs-2.6.32-504.el6.x86_64.img
}
```


### 通过/etc/default/grub文件生成grub.cfg

grub2-mkconfig是根据/etc/default/grub文件来创建配置文件的。该文件中定义的是grub的全局宏，修改内置的宏可以快速生成grub配置文件。实际上在/etc/grub.d/目录下还有一些grub配置脚本，这些shell脚本读取一些脚本配置文件(如/etc/default/grub)，根据指定的逻辑生成grub配置文件：

```sh
[root@xxx ~]# ls /etc/grub.d/
00_header  00_tuned  01_users  10_linux  20_linux_xen  20_ppc_terminfo  30_os-prober  40_custom  41_custom  README
```

在/etc/default/grub中，使用"key=vaule"的格式，key全部为大小字母，如果vaule部分包含了空格或其他特殊字符，则需要使用引号包围。

例如，下面是一个/etc/default/grub文件的示例：
```conf
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="crashkernel=auto biosdevname=0 net.ifnames=0 rhgb quiet"
GRUB_DISABLE_RECOVERY="true"
```

虽然可用的宏较多，但可能用的上的就几个：GRUB_DEFAULT、GRUB_TIMEOUT、GRUB_CMDLINE_LINUX和GRUB_CMDLINE_LINUX_DEFAULT。


#### 常用的配置KEY

1. GRUB_DEFAULT

默认的菜单项，默认值为0。其值可为数值N，表示从0开始计算的第N项是默认菜单，也可以指定对应的title表示该项为默认的菜单项。使用数值比较好，因为使用的title可能包含了容易改变的设备名。例如有如下菜单项：

```conf
menuentry 'Example GNU/Linux distribution' --class gnu-linux --id example-gnu-linux {
    ...
}
```

如果想将此菜单设为默认菜单，则可设置"GRUB_DEFAULT=example-gnu-linux"。

如果GRUB_DEFAULT的值设置为"saved"，则表示默认的菜单项是"GRUB_SAVEDEFAULT"或"grub-set-default"所指定的菜单项。


2. GRUB_SAVEDEFAULT

默认该key的值未设置。如果该key的值设置为true时，如果选定了某菜单项，则该菜单项将被认为是新的默认菜单项。该key只有在设置了"GRUB_DEFAULT=saved"时才有效。

不建议使用该key，因为GRUB_DEFAULT配合grub-set-default更方便。


3. GRUB_TIMEOUT

在开机选择菜单项的超时时间，超过该时间将使用默认的菜单项来引导对应的操作系统。默认值为5秒。等待过程中，按下任意按键都可以中断等待。

设置为0时，将不列出菜单直接使用默认的菜单项引导与之对应的操作系统，设置为"-1"时将永久等待选择。

是否显示菜单，和"GRUB_TIMEOUT_STYLE"的设置有关。


4. GRUB_TIMEOUT_STYLE

如果该key未设置值或者设置的值为"menu"，则列出启动菜单项，并等待"GRUB_TIMEOUT"指定的超时时间。

如果设置为"countdown"和"hidden"，则不显示启动菜单项，而是直接等待"GRUB_TIMEOUT"指定的超时时间，如果超时了则启动默认菜单项并引导对应的操作系统。在等待过程中，按下"ESC"键可以列出启动菜单。设置为countdown和hidden的区别是countdown会显示超时时间的剩余时间，而hidden则完全隐藏超时时间。


5. GRUB_DISTRIBUTOR

设置发行版的标识名称，一般该名称用来作为菜单的一部分，以便区分不同的操作系统。


6. GRUB_CMDLINE_LINUX

添加到菜单中的内核启动参数。例如：
```sh
GRUB_CMDLINE_LINUX="crashkernel=ro root=/dev/sda3 biosdevname=0 net.ifnames=0 rhgb quiet"
```


7. GRUB_CMDLINE_LINUX_DEFAULT

除非"GRUB_DISABLE_RECOVERY"设置为"true"，否则该key指定的默认内核启动参数将生成两份，一份是用于默认启动参数，一份用于恢复模式(recovery mode)的启动参数。

该key生成的默认内核启动参数将添加在"GRUB_CMDLINE_LINUX"所指定的启动参数之后。



8. GRUB_DISABLE_RECOVERY

该项设置为true时，将不会生成恢复模式的菜单项。


9. GRUB_DISABLE_LINUX_UUID

默认情况下，grub2-mkconfig在生产菜单项的时候将使用uuid来标识Linux 内核的根文件系统，即"root=UUID=..."。

例如，下面是/boot/grub2/grub.cfg中某菜单项的部分内容。
```sh
menuentry 'CentOS Linux (3.10.0-327.el7.x86_64) 7 (Core)' --class centos --class gnu-linux --class gnu --class os --unrestricted $menuentry_id_option 'gnulinux-3.10.0-327.el7.x86_64-advanced-b2a70faf-aea4-4d8e-8be8-c7109ac9c8b8' {

        #......

        linux16 /vmlinuz-3.10.0-327.el7.x86_64 root=UUID=b2a70faf-aea4-4d8e-8be8-c7109ac9c8b8 ro crashkernel=auto biosdevname=0 net.ifnames=0 quiet LANG=en_US.UTF-8

        initrd16 /initramfs-3.10.0-327.el7.x86_64.img

}
```
虽然使用UUID的方式更可靠，但有时候不太方便，所以可以设置该key为true来禁用。


10. GRUB_BACKGROUND

设置背景图片，背景图片必须是grub可读的，图片文件名后缀必须是".png"、".tga"、".jpg"、".jpeg"，在需要的时候，grub会按比例缩小图片的大小以适配屏幕大小。


11. GRUB_THEME

设置grub菜单的主题。


12. GRUB_GFXPAYLOAD_LINUX

设置为"text"时，将强制使用文本模式启动Linux。在某些情况下，可能不支持图形模式。


13. GRUB_DISABLE_OS_PROBER

默认情况下，grub2-mkconfig会尝试使用os-prober程序(如果已经安装的话，默认应该都装了)探测其他可用的操作系统内核，并为其生成对应的启动菜单项。设置为"true"将禁用自动探测功能。


14. GRUB_DISABLE_SUBMENU

默认情况下，grub2-mkconfig如果发现有多个同版本的或低版本的内核时，将只为最高版本的内核生成顶级菜单，其他所有的低版本内核菜单都放入子菜单中，设置为"y"将全部生成为顶级菜单。


15. GRUB_HIDDEN_TIMEOUT(已废弃，但为了向后兼容，仍有效)

使用"GRUB_TIMEOUT_STYLE={countdown|hidden}"替代该项


16. GRUB_HIDDEN_TIMEOUT_QUIET(已废弃，但为了向后兼容，仍有效)

配合GRUB_HIDDEN_TIMEOUT使用，可以使用GRUB_TIMEOUT_STYLE=countdown来替代这两项。



### 通过脚本方式直接编写grub.cfg


- 注释符：从#开始的字符都被认为是注释，所以grub支持行中注释
- 连接操作符：{ } | & $ ; < >
- 保留关键字和符号：! [[ ]] { } case do done elif else esac fi for function if in menuentry select then time until while。并非所有的关键字都有用，只是为了日后的功能扩展而提前提供的。
- 引号和转义符
  - 对于特殊的字符需要转义。有三种方式转义：使用反斜线、使用单引号、使用双引号。
  - 反斜线转义方式和shell一样。
  - 单引号中的所有字符串都是字面意思，没有任何特殊意义，即使单引号中的转义符也被认为是纯粹的字符。所以'\''是无法保留单引号的。单引号需要使用双引号来转移，所以应该写"'"。
  - 双引号和单引号作用一样，但它不能转义某几个特殊字符，包括"$"和"\"。对于双引号中的"$"符号，它任何时候都保留本意。对于"\"，只有反斜线后的字符是'$'、'"'、'\'时才表示转义的意思，另外 ，某行若以反斜线结尾，则表示续行，但官方不建议在grub.cfg中使用续行符。
- 变量扩展
  - 使用$符号引用变量，也可以使用${var}的方式引用var变量。
  - 支持位置变量，例如$1引用的是第一个参数。
  - 还支持特殊的变量，如$?表示上一次命令的退出状态码。如果使用了位置变量，则还支持$*、$@和$#，$*代表的所有参数整体，各参数之间是不可分割的，$@也代表所有变量，但$@的各参数是可以被分割的，$#表示参数的个数。
- 简单的命令
  - 可以在grub.cfg中使用简单的命令。各命令之间使用换行符或分号表示该命令结束。
  - 如果在命令前使用了"!"，则表示逻辑取反。
- 循环结构：for name in word …; do list; done
- 循环结构：while cond; do list; done
- 循环结构：until cond; do list; done
- 条件判断结构：if list; then list; [elif list; then list;] … [else list;] fi
- 函数结构：function name { command; … }
- 菜单项命令：menuentry title [--class=class …] [--users=users] [--unrestricted] [--hotkey=key] [--id=id] { command; … }
  - 这是grub.cfg中最重要的项，官方原文：https://www.gnu.org/software/grub/manual/html_node/menuentry.html#menuentry

  - 该命令定义了一个名为title的grub菜单项。当开机时选中该菜单项时，grub会将chosen环境变量的值赋给"--id"(如果给定了"--id"的话)，执行大括号中的命令列表，如果直到最后一个命令都全部执行成功，且成功加载了对应的内核后，将执行boot命令。随后grub就将控制权交给了操作系统内核。
   ```text
      --class：该选项用于将菜单分组，从而使得grub可以通过主题样式为不同组的菜单显示不同的样式风格。一个menuentry中，可以使用多次class表示将该菜单分到多个组中去。

      --users：该选项限定只有此处列出的用户才能访问该菜单项，不指定该选项时将表示所有用户都能访问该菜单。

      --unrestricted：该选项表示所有用户都有权访问该菜单项。

      --hotkey：该选项为该菜单项关联一个热键，也就是快捷键，关联热键后只要按下该键就会选中该菜单。热键只能是字母键、backspace键、tab键或del键。

      --id：该选项为该菜单关联一个唯一的数值。id的值可以由ASCII字母、数字//下划线组成，且不得以数字开头。

      所有其他的参数包括title都被当作位置参数传递给大括号中的命令，但title总是$1，除title外的其余参数，位置值从前向后类推。
   ```
- break [n]：强制退出for/while/until循环
- continue [n]：跳到下一次迭代，即进入下一次循环
- return [n]：指定返回状态码
- setparams [arg] …：从$1开始替换位置参数
- shift [n]：踢掉前n个参数，使得第n+1个参数变为$1，但和shell中不一样的是，踢掉了前n个参数后，从$#-n+1到$#这些参数的位置不变


## 命令行和菜单项中的命令

grub2支持很多命令，有些命令只能在交互式命令行下使用，有些命令可用在配置文件中。在救援模式下，只有insmod、ls、set和unset命令可用。


### help

```sh
help [pattern]
```

显示能匹配到pattern的所有命令的说明信息和usage信息


### boot

```sh
boot
```

用于启动已加载的操作系统。只在交互式命令行下可用。其实在menuentry命令的结尾就隐含了boot命令。


### set & unset

```sh
set [envvar=value]
unset envvar
```

`set [envvar=value]` 设置环境变量envvar的值为value，如果不给定参数，则列出当前环境变量。

`unset envvar` 释放环境变量envvar。


### lsmod & insmod & rmmod

```sh
lsmod
insmod xxx.mod
```

`lsmod` 用于列出已加载的模块

`insmod xxx.mod` 用于加载指定的模块

注意，若要导入支持ext文件系统的模块时，只需导入ext2.mod即可，实际上也没有ext3和ext4对应的模块。


### linux & linux16

```sh
linux kernel_file [kernel_args]      # 32bit
linux16 kernel_file [kernel_args]    # 16bit
```

都表示装载指定的内核文件，并传递内核启动参数。

- linux16表示以传统的16位启动协议启动内核，linux表示以32位启动协议启动内核，但linux命令比linux16有一些限制。但绝大多数时候，它们是可以通用的。
- 在linux或linux16命令之后，必须紧跟着使用init或init16命令装载init ramdisk文件。


- 一般为/boot分区下的vmlinuz-RELEASE_NUM文件，但在grub环境下，boot分区被当作root分区，即根分区，假如boot分区为第一块磁盘的第一个分区，则应该写成：
   ```sh
   linux (hd0,msdos1)/vmlinuz-XXX
   ```
   或
   ```sh
   set root='hd0,msdos1'
   linux /vmlinuz-XXX
   ```

- 在grub阶段可以传递内核的启动参数，内核的参数包括3类：
  - 编译内核时参数
  - 启动时参数
  - 运行时参数
- 完整的启动参数列表见：http://redsymbol.net/linux-kernel-boot-parameters
- 常用的启动参数：
   ```sh
   init=   ：指定Linux启动的第一个进程 init 的替代程序。
   root=   ：指定根文件系统所在分区，在grub中，该选项必须给定。root=UUID=edb1bf15-9590-4195-aa11-6dac45c7f6f3 or root=/dev/sda2
   ro,rw   ：启动时，根分区以只读还是可读写方式挂载。不指定时默认为ro。
   initrd  ：指定 init ramdisk 的路径。在grub中因为使用了 initrd 或 initrd16 命令，所以不需要指定该启动参数。
   rhgb    ：以图形界面方式启动系统。
   quiet   ：以文本方式启动系统，且禁止输出大多数的log message。
   net.ifnames=0：用于CentOS 7，禁止网络设备使用一致性命名方式。
   biosdevname=0：用于CentOS 7，也是禁止网络设备采用一致性命名方式。
                ：只有 net.ifnames 和 biosdevname 同时设置为 0 时，才能完全禁止一致性命名，得到 eth0-N 的设备名。
   ```


### initrd & initrd16

```sh
initrd filesystempath/ramdisk/initramfs
```

只能紧跟在linux或linux16命令之后使用，用于为即将启动的内核传递init ramdisk路径。

同样，基于根分区，可以使用绝对路径，也可以使用相对路径。路径的表示方法和linux或linux16命令相同。

i.e.
```sh
linux16 /vmlinuz-0-rescue-d13bce5e247540a5b5886f2bf8aabb35 root=UUID=b2a70faf-aea4-4d8e-8be8-c7109ac9c8b8 ro crashkernel=auto quiet

initrd16 /initramfs-0-rescue-d13bce5e247540a5b5886f2bf8aabb35.img
```


### search

```sh
search [--file|--label|--fs-uuid] [--set [var]] [--no-floppy] [--hint args] name
```

通过文件`[--file]`、卷标`[--label]`、文件系统UUID`[--fs-uuid]`来搜索设备。

如果使用了`[--set [var]]`选项，则会将第一个找到的设备设置为环境变量`var`的值，默认的变量`var`为`root`。

可使用`--no-floppy`选项来禁止搜索软盘，因为软盘速度非常慢，已经被淘汰了。

可指定`--hint=XXX`选项来优先选择满足提示条件的设备，若指定了多个`hint`条件，则优先匹配第一个`hint`，然后匹配第二个，依次类推。

**i.e.**
下方if语句中的第一个search中搜索uuid为"367d6a77-033b-4037-bbcb-416705ead095"的设备，但使用了多个hint选项，表示先匹配bios平台下/boot分区为(hd0,msdos1)的设备，之后还指定了几个hint，但因为search使用的是uuid搜索方式，所以这些hint选项是多余的，因为单磁盘上分区的uuid是唯一的：
```sh
if [ x$feature_platform_search_hint = xy ]; then

  search --no-floppy --fs-uuid --set=root --hint-bios=hd0,msdos1 --hint-efi=hd0,msdos1 --hint-baremetal=ahci0,msdos1 --hint='hd0,msdos1'  367d6a77-033b-4037-bbcb-416705ead095

else

  search --no-floppy --fs-uuid --set=root 367d6a77-033b-4037-bbcb-416705ead095

fi

linux16 /vmlinuz-3.10.0-327.el7.x86_64 root=UUID=b2a70faf-aea4-4d8e-8be8-c7109ac9c8b8 ro crashkernel=auto quiet LANG=en_US.UTF-8

initrd16 /initramfs-3.10.0-327.el7.x86_64.img
```


**i.e.**
如果某启动设备上有两个boot分区(如多系统共存时)，分别是(hd0,msdos1)和(hd0,msdos5)，如果此时不使用uuid搜索，而是使用label方式搜索。则此时将会选中(hd0,msdos5)这个boot分区，若不使用hint，将选中(hd0,msdos1)这个boot分区：
```sh
search --no-floppy --fs-label=boot --set=root --hint=hd0,msdos5
```

- 常见的搜索方法：
  - UUID:
  - Lable: `search --no-floppy --label --set=root ONL-BOOT`, `search --no-floppy --label --set=root ONIE-BOOT`


### true & false

直接返回true或false布尔值。


### test expression & [ expression ]

计算`expression`的结果是否为真，为真时返回`0`，否则返回`非0`，主要用于`if`、`while`或`until`结构中。

|表达式|含义|
|--|--|
|`string1 == string2`|`string1`与`string2`相同|
|`string1 != string2`|`string1`与`string2`不相同|
|`string1 < string2`|`string1`在字母顺序上小于`string2`|
|`string1 <= string2`|`string1`在字母顺序上小于等于`string2`|
|`string1 > string2`|`string1`在字母顺序上大于`string2`|
|`string1 >= string2`|`string1`在字母顺序上大于等于`string2`|
|`integer1 -eq integer2`|`integer1`等于`integer2`|
|`integer1 -ge integer2`|`integer1`大于或等于`integer2`|
|`integer1 -gt integer2`|`integer1`大于`integer2`|
|`integer1 -le integer2`|`integer1`小于或等于`integer2`|
|`integer1 -lt integer2`|`integer1`小于`integer2`|
|`integer1 -ne integer2`|`integer1`不等于`integer2`|
|`prefixinteger1 -pgt prefixinteger2`|剔除非数字字符串`prefix`部分之后，`integer1`大于`integer2`|
|`prefixinteger1 -plt prefixinteger2`|剔除非数字字符串`prefix`部分之后，`integer1`小于`integer2`|
|`file1 -nt file2`|`file1`的修改时间比`file2`新|
|`file1 -ot file2`|`file1`的修改时间比`file2`旧|
|`-d file`|`file`存在且是目录|
|`-e file`|`file`存在|
|`-f file`|`file`存在并且不是一个目录|
|`-s file`|`file`存在并且文件占用空间大于零|
|`-n string`|`string`的长度大于零|
|`string`|`string`的长度大于零，等价于`-n string`|
|`-z string`|`string`的长度等于零|
|`( expression )`|将`expression`作为一个整体|
|`! expression`|非(NOT)|
|`expression1 -a expression2`|与(AND)，也可以使用`expression1 expression2`，但不推荐|
|`expression1 -o expression2`|或(OR)|


### cat

```sh
cat path/to/file
```

读取文件内容


### clear

清屏


### configfile

```sh
configfile $grub_cfg_file
```

立即加载一个指定的文件作为`grub`的配置文件。但注意，导入的文件中的环境变量不在当前生效。

在`grub.cfg`丢失时，该命令将排上用场。


### echo

```sh
echo [-n] [-e] string
```

- 输出字符串 `string`

- `-n`和`-e`用法同shell中echo。

- 如果要引用变量，使用`${var}` 或 `$var`的方式。


### ls

```sh
ls [args]
```

- 如果不给定任何参数，则列出`grub`可见的设备。
   ```sh
   grub> ls                                                                                                                                                                                     
   (hd0) (hd0,gpt6) (hd0,gpt5) (hd0,gpt4) (hd0,gpt3) (hd0,gpt2) (hd0,gpt1)                                                                                                                      
   grub> 
   ```

- 如果给定的参数是一个分区，则显示该分区的文件系统信息。
   ```sh
   grub> ls (hd0,gpt6)                                                                                                                                                                          
   (hd0,gpt6): Filesystem is ext2.                                                                                                                                                              
   grub>  
   ```

- 如果给定的参数是一个绝对路径表示的目录，则显示该目录下的所有文件。
   ```sh
   grub> ls (hd0,gpt6)/                                                                                                                                                                         
   ./ ../ lost+found/ bin/ boot/ dev/ etc/ home/ lib/ lib64/ media/ mnt/ opt/                                                                                                                   
   proc/ root/ run/ sbin/ srv/ sys/ tmp/ usr/ var/                                                                                                                                              
   grub>  
   ```


### probe

```sh
probe [--set var] --partmap|--fs|--fs-uuid|--label device
```

探测分区或磁盘的属性信息。如果未指定`--set`，则显示指定设备对应的信息。如果指定了`--set`，则将对应信息的值赋给变量`var`。

`--partmap`：显示是`gpt`还是`mbr`格式的磁盘。

`--fs`：显示分区的文件系统。

`--fs-uuid`：显示分区的uuid值。

`--label`：显示分区的label值。


### save_env & list_env & load_env

- `save_env`: 将环境变量保存到环境变量块中，保存在与grub.cfg同级的grubenv文件中
- `list_env`: 列出当前的环境变量块中的变量
- `load_env`: 加载由save_env保存在grubenv的变量

i.e.
```sh
grub> a=1
grub> save_env a
grub> list_env
boot_config_default=TkVUREVWPW1hMQpCT09UTU9ERT1JTlNUQUxMRUQKU1dJPWltYWdlczo6bGF0ZXN0Cg==                                                                     saved_entry=0                                                                                                                                                a=1                                                                                                                                                          
grub> 
``` 


### loopback

```sh
loopback [-d] device file
```

将`file`映射为回环设备。使用`-d`选项则是删除映射。


i.e.

```sh
loopback loop0 /path/to/image
ls (loop0)/
```


### normal & normal_exit

进入和退出normal模式，normal是相对于救援模式而言的，只要不是在救援模式下，就是在normal模式下。

救援模式下，只能使用非常少的命令，而normal模式下则可以使用非常多的命令。


### password & password_pbkdf2

```sh
password user clear-password
password_pbkdf2 user hashed-password
```

- `password user clear-password`: 使用明文密码定义一个名为`user`的用户。不建议使用此命令。

- `password_pbkdf2 user hashed-password`: 使用哈希加密后的密码定义一个名为`user`的用户，加密的密码通过`grub-mkpasswd-pbkdf2`工具生成。建议使用该命令。



## 内置变量


### chosen

当开机时选中某个菜单项启动时，该菜单的title将被赋值给chosen变量。该变量一般只用于引用，而不用于修改。


### cmdpath

`grub2`加载的`core.img`的目录路径，是绝对路径，即包括了设备名的路径，如`(hd0,gpt1)/boot/grub2/`。该变量值不应该修改。


### default

指定默认的菜单项，一般其后都会跟随`timeout`变量。

`default`指定默认菜单时，可使用菜单的`title`，也可以使用菜单的`id`，或者数值顺序，当使用数值顺序指定`default`时，从`0`开始计算。


### timeout

设置菜单等待超时时间，设置为`0`时将直接启动默认菜单项而不显示菜单，设置为`-1`时将永久等待手动选择。


### fallback

当默认菜单项启动失败，则使用该变量指定的菜单项启动，指定方式同`default`，可使用数值(从`0`开始计算)、`title`或`id`指定。


### grub_platform

指定该平台是`pc`还是`efi`，`pc`表示的是传统的`bios`平台，`efi`表示`uefi`。

该变量不应该被修改，而应该被引用，例如用于if判断语句中。


### prefix

在`grub`启动的时候，`grub`自动将`/boot/grub`目录的绝对路径赋值给该变量，使得以后可以直接从该变量所代表的目录下加载各文件或模块。

例如，可能自动设置为：

```
set prefix = (hd0,gpt1)/boot/grub/
```

所以可以使用`$prefix/grubN.cfg`来引用`/boot/grub/grubN.cfg`文件。

该变量不应该修改，且若手动设置，则必须设置正确，否则牵一发而动全身。


### root

该变量指定根设备的名称，使得后续使用从`/`开始的相对路径引用文件时将从该`root`变量指定的路径开始。一般该变量是grub启动的时候由grub根据`prefix`变量设置而来的。

例如`prefix=(hd0,gpt1)/boot/grub`，则`root=(hd0,gpt1)`，后续就可以使用相对路径/vmlinuz-XXX表示(hd0,gpt1)/vmlinuz-XXX文件。

注意：在Linux中，从根"/"开始的路径表示绝对路径，如/etc/fstab。但grub中，从"/"开始的表示相对路径，其相对的基准是root变量设置的值，而使用`(dev_name)/`开始的路径才表示**绝对路径**。

一般root变量都表示`/boot`所在的分区，但这不是绝对的，如果设置为根文件系统所在分区，如root=(hd0,gpt2)，则后续可以使用/etc/fstab来引用"(hd0,gpt2)/etc/fstab"文件。

该变量在grub中一般不用修改，但若修改则必须指定正确。

另外，root变量还应该于linux或linux16命令所指定的内核启动参数"root="区分开来，内核启动参数中的"root="的意义是固定的，其指定的是根文件系统所在分区。例如：
```sh
set root='hd0,msdos1'
linux16 /vmlinuz-3.10.0-327.el7.x86_64 root=UUID=b2a70faf-aea4-4d8e-8be8-c7109ac9c8b8 ro crashkernel=auto quiet LANG=en_US.UTF-8
initrd16 /initramfs-3.10.0-327.el7.x86_64.img
```

一般情况下，/boot都会单独分区，所以root变量指定的根设备和root启动参数所指定的根分区不是同一个分区，除非/boot不是单独的分区，而是在根分区下的一个目录。



























> Source: https://www.cnblogs.com/f-ck-need-u/p/7094693.html#auto_id_14


