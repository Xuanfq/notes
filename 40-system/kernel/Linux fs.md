
# Summary

ramfs, tmpfs, rootfs, initramfs and romfs

1. ramfs
    1.1. ramfs
    1.2. ramfs & ramdisk
    1.3. tmpfs
    1.4. rootfs
    1.5. initramfs
1. romfs



## 1. ramfs

tmpfs, rootfs, initramfs are all a kind of ramfs, they are either some special applications for it, or they are the improvement and enhancement of some aspects of its capabilities.

### 1.1. ramfs是什么

- ramfs是一个非常简单的文件系统，它输出Linux的磁盘缓存机制(页缓存和目录缓存)作为一个大小动态的基于内存的文件系统。

- 通常，所有的文件由Linux被缓存在内存中。页的数据从保持在周围以防再次需要的后备存储(一般被挂载的是块设备文件系统)中读取，并标记为可用(空闲)以防虚拟内存系统(Virtual Memory System)需要这些内存作为别用。类似的，在数据写回后备存储时，数据一写回文件就立即被标记为可用，但周围的缓存被保留着直至VM(虚拟机)重新分配内存。一个类似的机制(目录缓存)极大的加快了对目录的访问。

- ramfs并没有后备存储。文件写入ramfs象往常一样，来分配目录和页的缓存，但这里并没有地方可写回它们。这意味着页的数据不再标记为可用，因此当希望回收内存时，内存不能通过VM来释放。

- 实现ramfs所需的代码总量是极少的，因为所有的工作由现有的Linux缓存结构来完成。实际上，你现正在挂载磁盘缓存作为一个文件系统。据此，ramfs并不是一个可通过菜单配置项来卸载的可选组件，它可节省的空间是微不足道的。

### 1.2. ramfs和ramdisk

- 旧的ramdisk("内存磁盘")机制在一个内存空间中创建一个合成块设备并使用它作为一个文件系统的后备存储。这个块设备是固定大小的以至于挂载在它上面的文件系统也是固定大小的。除创建和销毁目录外，使用一个ramdisk(内存磁盘)并不需要从假的块设备到页缓存拷贝内存数据(和拷贝更改回退)。另外，它需要一个文件系统驱动 (如，ext2)来格式和解释这些数据。

- 与ramfs相比较，这些废弃的内存(和内存总线带宽)为CPU造成了不必要的工作并污染了CPU缓存。(这里有个技巧通过使用页表单来避免这个拷贝，但是它们难以理解并且代价反而变的与拷贝一样昂贵。)更为重要的是，由于所有的文件都通过页和目录缓存进行访问，全部的工作ramfs都要执行。ramdisk(内存磁盘)是简单且多余的，ramfs在内部更为简单。

- 另一个理由是：ramdisks是半过时的，它引进的回环设备提供一个更灵活和方便的方式从文件而不是从大块的内存中来创建一个合成块设备。



### 1.3. tmpfs

- ramfs的一个不利之处是你将保留写回到ramfs的数据直至你填补所有的内存，并且VM不能释放它，因为VM考虑到文件将写回后备存储(而不是交换空间)，但是ramfs并不能获得任何的后备存储。据此，只有root(或者一个受信任的用户)可允许回写到一个ramfs挂载中。

- tmpfs是从ramfs派生出的,添加了大小的限制以及回写数据到交换空间能力的特殊ramfs。普通用户可以允许回写到tmpfs挂载中。

- 使用tmpfs
    - `$ mount tmpfs /dev/shm -t tmpfs -o size=32m`

### 1.4. rootfs

- rootfs是一个特定的ramfs(或tmpfs，如果那被启用)的实例，它始终存在于2.6的系统。
- 你不能卸载rootfs，这个理由近似于你不能杀死init进程。它小巧且简单的为内核确保某些列表不能为空，而不是拥有特定的代码来检查和处理一个空列表。
- 大多数的系统挂载另一个文件系统到rootfs并忽略它。一个空白ramfs实例的空间总量占用是极小的。

### 1.5. initramfs

#### 1.5.1. initramfs是什么

- 所有的2.6 Linux内核包含了一个gzip压缩过的"cpio"格式存档，当内核启动时它将被提取到rootfs。
- 在提取之后，内核检测rootfs是否包含了一个"init"文件，如果包含就来执行它并设置PID为1。
- 这个init进程将负责引导系统的其余内容，包含了要寻找和挂载的真正根设备(若有的话)。
- 如果rootfs在提取cpio存档以后并不包含一个init程序，内核将失败并通过旧的代码来寻找和挂载一个根分区，接着执行一些/sbin /init的变种。

#### 1.5.2. 与旧的initrd不同点

- 旧的initrd通常是一个独立的文件，而initramfs存档是连接到linux内核映像的。(Linux系统目录-*/usr 在构建时就是为了生成这个存档)

- 旧的initrd文件是一个gzip压缩过的文件系统映像(在一些文件格式，如ext2,需要构建一个驱动到内核)，而这个新的initramfs存档是一个gzip压缩过的cpio存档(象tar一样简单，参见cpio(1) and Documentation/early-userspace/buffer-format.txt)。内核的cpio提取代码不仅极少，而且init文本和数据可以在启动过程中被丢弃。

- 程序通过旧的initrd(叫做/initrd，而不是/init)运行一些设定并接着返回内核，而init程序从initramfs并不预计返回内核。(如果/init需要手工关闭并控制它，可以与一个新的根设备一起覆盖挂载 / 并执行另一个init程序。参见switch_root utility的后部分)

  - 当切换到另一个根设备，initrd会pivot_root并且接着卸载内存磁盘。但是initramfs是rootfs：你可以不用 pivot_root rootfs和卸载它。而是删除除rootfs之外的所有东西来释放空间(`find -xdev / -exec rm '{}' ';'`),与新的根(cd /newmount; mount --move . /; chroot .)一起覆盖挂载rootfs,附加stdin/stdout/stderr到新的/dev/console并执行新的init。

- 由于这是一个非常谨慎的进程(以及在你运行它们之前涉及到删除命令)，klibc包为你引进了一个帮助程序(utils/run_init.c)来做这些。大部分其他软件包(如，busybox)已命名在此命令"switch_root"中。

#### 1.5.3. 提供 initramfs

- v2.6 内核构建进程总是创建一个gzip压缩过的cpio格式的initramfs存档并连接它到生成的内核二进制文件。默认的，这些存储是空的(在x86上占用134 bytes)

- 配置选项CONFIG_INITRAMFS_SOURCE(存在于menuconfig的General Setup选项和usr/Kconfig中)可为initramfs存档使用特定的一个源文件，它自动合并到生成的二进制文件中。这个选项可以指定一个现有的gzip压缩的cpio存档，这个存档可以包含一个目录文件到或者是一个文本文件详述，如下面的示例:
    ```sh
    dir /dev 755 0 0
    nod /dev/console 644 0 0 c 5 1
    nod /dev/loop0 644 0 0 b 7 0
    dir /bin 755 1000 1000
    slink /bin/sh busybox 777 0 0
    file /bin/busybox initramfs/busybox 755 0 0
    dir /proc 755 0 0
    dir /sys 755 0 0
    dir /mnt 755 0 0
    file /init initramfs/init.sh 755 0 0
    ```

- 在文件格式之上运行"usr/gen_init_cpio"(在构建内核之后)来获得一个用法文档。

- 一个高级的配置文件是root访问不需要在新的存档上设置权限或者创建设备节点。(注意示例的那两个"file"期望在linux-2.6.*目录下，在"initramfs"目录中找到名为"init.sh"和"busybox"的文件。参见Documentation/early- userspace/README 以获得更多细节。)

- 内核并不依赖外部的cpio工具。如果你指定一个目录而不是一个配置文件，内核的构建结构将从那个目录(usr/Makefile 调用

scripts/gen_initramfs_list.sh)创建一个配置文件，并封装该目录来使用配置文件(通过释放它到从 usr/gen_init_cpio.c 创建的 usr/gen_init_cpio)。在内核构建时cpio创建的代码是完全独立的，在内核开启时提取器也是(完全)独立的。

- 你唯一可能需要为创建或提取你自己的cpio文件以提供给内核构建(而不是一个配置文件或目录)而安装外部的cpio工具。

- 以下的命令行可提取一个cpio映像(不管是通过以上脚本或是通过内核构建成的)回退到它的组成文件：
    ```sh
        cpio -i -d -H newc -F initramfs_data.cpio --no-absolute-filenames
    ```

- 以下的shell脚本可创建一个预制的cpio存档，你可以使用在上述的配置文件中：
    
    ```sh
    #!/bin/sh
    
    # Copyright 2006 Rob Landley <rob@landley.net> and TimeSys Corporation.
    # Licensed under GPL version 2

    if [ $# -ne 2 ]
    then
        echo "usage: mkinitramfs directory imagename.cpio.gz"
        exit 1
    fi
    
    if [ -d "$1" ]
    then
        echo "creating $2 from $1"
        (cd "$1"; find . | cpio -o -H newc | gzip) > "$2"
    else
        echo "First argument must be a directory"
        exit 1
    fi
    ```

- 注意：如果你是按照cpio的man页做的，那么它包含的一些不良建议将会破坏你的initramfs存档。它说"生成文件名列表的一个典型方式是使用 find命令，你应该提供-depth选项来搜索"。而在创建initramfs.cpio.gz映像时不要这么做，因为它并不可行。Linux内核的 cpio提取器不会在一个不存在的目录中创建文件，因此目录项必须在文件被提取到该目录之前被提取。以上脚本保证了它们的顺序正确性。

#### 1.5.4. 外部initramfs映像

- 如果内核有启用initrd支持，一个外部的cpio.gz存档也可替换一个2.6 内核的initrd。既然这样，内核将自动检测文件类型(initramfs, 而不是initrd)并在尝试运行/init前，提取外部的cpio存档到rootfs。

- initramfs有内存效率的优势(没有内存磁盘块设备)，而initrd可单独封装(如果你有非GPL许可协议的代码，而你想从initramfs运行，这还是不错的。不要与GPL许可的二进制的Linux内核混为一谈)。

- 外部initramfs映像也可以用来补充内核内建的initramfs映像。外部存档文件将覆盖与内建initramfs存档中任意不一致的文件。一些发行商也偏爱定制一个单一内核映像和特定initramfs映像，而不用重编译。

#### 1.5.5. initramfs的内容

- 一个initramfs存档是一个完整独立的Linux根文件系统。如果你还不能理解共享库、设备和路径，你需要获得一个小的根文件系统来启动和运行，这里有一些参考资料：
    - [http://www.tldp.org/HOWTO/Bootdisk-HOWTO/](http://www.tldp.org/HOWTO/Bootdisk-HOWTO/)
    - [http://www.tldp.org/HOWTO/From-PowerUp-To-Bash-Prompt-HOWTO.html](http://www.tldp.org/HOWTO/From-PowerUp-To-Bash-Prompt-HOWTO.html)
    - [http://www.linuxfromscratch.org/lfs/view/stable/](http://www.linuxfromscratch.org/lfs/view/stable/)

- 软件包"klibc"([http://www.kernel.org/pub/linux/libs/klibc)被设计为一个极小的C库来静态连接早期的用户空间代码，以及一些相关的工具。它是BSD授权。](http://www.kernel.org/pub/linux/libs/klibc)%E8%A2%AB%E8%AE%BE%E8%AE%A1%E4%B8%BA%E4%B8%80%E4%B8%AA%E6%9E%81%E5%B0%8F%E7%9A%84C%E5%BA%93%E6%9D%A5%E9%9D%99%E6%80%81%E8%BF%9E%E6%8E%A5%E6%97%A9%E6%9C%9F%E7%9A%84%E7%94%A8%E6%88%B7%E7%A9%BA%E9%97%B4%E4%BB%A3%E7%A0%81%EF%BC%8C%E4%BB%A5%E5%8F%8A%E4%B8%80%E4%BA%9B%E7%9B%B8%E5%85%B3%E7%9A%84%E5%B7%A5%E5%85%B7%E3%80%82%E5%AE%83%E6%98%AFBSD%E6%8E%88%E6%9D%83%E3%80%82)

- 我使用uClibc ([http://www.uclibc.org)和busybox](http://www.uclibc.xn--org)busybox-b14s/) ([http://www.busybox.net)。这些分别是LGPL和GPL授权。(一个独立的initramfs软件包被计划在busybox](http://www.busybox.net).xn--lgplgpl-ku4k67wukan7tkp4c7ghx0dqv5s.xn--(initramfsbusybox-qs50a2w47jvpvz2e7x2ayj6mf1saonzq86folr6gz/) 1.3 release。)

- 从理论上说你可以使用glibc，但是对于小型嵌入式系统象这样使用并适合。(一个"hello world"程序静态连接glibc将近400k。用uClibc的话它是7k。还要注意，glibc dlopens libnss作为名称查找，即使是使用静态连接。)

- 一个好的开头是获得initramfs来运行一个静态连接的"hello world"程序作为init，并在一个类似qemu(www.qemu.org)的仿真器或用户模式的Linux中测试它，象这样：
    ```sh
    cat > hello.c << EOF
    #include <stdio.h>
    #include <unistd.h>
    
    int main(int argc, char *argv[])
    {
        printf("Hello world!/n");
        sleep(999999999);
    }
    EOF
    gcc -static hello.c -o init
    echo init | cpio -o -H newc | gzip > test.cpio.gz
    # Testing external initramfs using the initrd loading mechanism.
    qemu -kernel /boot/vmlinuz -initrd test.cpio.gz /dev/zero
    ```
- 当调试一个普通根文件系统时，能够用"init=/bin/sh"来启动将是不错的。与initramfs等价的是"rdinit=/bin/sh"，而且它很有用。

#### 1.5.6. 为什么是cpio而不是tar?

- 这个决定的发布是在2001年12月。讨论浏览在这里:
    - [http://www.uwsg.iu.edu/hypermail/linux/kernel/0112.2/1538.html](http://www.uwsg.iu.edu/hypermail/linux/kernel/0112.2/1538.html)

- 并且催生了第二件事情(tar与cpio的比较)，浏览这里
    - [http://www.uwsg.iu.edu/hypermail/linux/kernel/0112.2/1587.html](http://www.uwsg.iu.edu/hypermail/linux/kernel/0112.2/1587.html)

- 快速且直接的总结版本(这些是无法替代上述内容的阅读的)：
    - cpio是一个标准。它十来岁了(从 AT&T起)，并已被广泛应用在Linux上(在RPM中，Red Hat的设备驱动磁盘上)。这里有从1996年起有关它的Linux日志：
        - [http://www.linuxjournal.com/article/1213](http://www.linuxjournal.com/article/1213)

- 它并没有象tar一样流行，因为传统的cpio命令行工具要求使用极可怕的命令行。同时没有其他有关存档格式的方式，并有可选的工具。如:
    - [http://freshmeat.net/projects/afio/](http://freshmeat.net/projects/afio/)

- cpio存档格式是由内核选择的，它比(许多国家的)任意的tar存档格式都简单且干净(并极容易来创建和解析)。完整的initramfs存档格式说明在buffer-format.txt，创建在usr/gen_init_cpio.c，并提取在init/initramfs.c。所有三个可阅读的文本一起不到26k。

- GNU项目使用tar标准似乎是与Windows使用zip的标准相关。Linux并不是它们中任一一个，并自由的作出了自己的技术决策。

- 由于这是一个内核的内部格式，它可以很容易做一些更新。内核提供它自己的工具来创建和提取这个格式。使用现有的标准是可取的，但不是必要的。

- Al Viro 作出决定(引用: "tar is ugly as hell and not going to be supported on the kernel side"):
    - [http://www.uwsg.iu.edu/hypermail/linux/kernel/0112.2/1540.html](http://www.uwsg.iu.edu/hypermail/linux/kernel/0112.2/1540.html)

- 解释它的理由：
    - [http://www.uwsg.iu.edu/hypermail/linux/kernel/0112.2/1550.html](http://www.uwsg.iu.edu/hypermail/linux/kernel/0112.2/1550.html)
    - [http://www.uwsg.iu.edu/hypermail/linux/kernel/0112.2/1638.html](http://www.uwsg.iu.edu/hypermail/linux/kernel/0112.2/1638.html)

- 最重要的是，设计和实现initramfs的代码。

#### 1.5.7. 发展的方向

- 当前(2.6.16), initramfs总被编译进，但并没总被使用。内核做到回退到原来的启动代码只需initramfs中不包含一个/init程序。回退

是原来的代码，以此确保一个平滑的过渡并允许尽早的开启功能逐步移动到"前期用户空间"(即initramfs)。

- 移动到前期用户空间是必要的，因为寻找和挂载真正的根设备是复杂的。根分区可以跨多个设备。它们可在网络上进行(要求dhcp，设定一个特定MAC地址，登录到一台服务器等)。它们可用在可移动媒体，动态分配主/次号以及要求udev执行清理的持续命名的问题。它们可被压缩、加密、写时拷贝，回环挂载、异常分区等。

- 这种复杂性(必将包含的策略)是在用户空间的处理的正确性。klibc和busybox/uClibc两者一起在简单的initramfs软件包中工作以组成一个内核构建。

- 软件包klibc现在已被Andrew Morton's 2.6.17-mm 接受到树中。内核当前的提前启动代码(分区检测等)可能会迁移到默认的initramfs中，由内核构建自动创建并使用。

## 2. romfs

- romfs 是只读的文件系统,本文不讨论它,由于它与ramfs写法很相近,所以在此列出它,可以参考外部链接:
    - [http://wxpjiujiang.blog.163.com/blog/static/203994030201222295944637/](http://wxpjiujiang.blog.163.com/blog/static/203994030201222295944637/)



