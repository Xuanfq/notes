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




























> Source: https://www.cnblogs.com/f-ck-need-u/p/7094693.html#auto_id_14


