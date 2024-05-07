

# Linux Startup Procedure

- Power up the motherboard
- CPU Reset
- BIOS/UEFI
- Bootloader
  - Decompressing `kernel` image: `bzlmage`
  - Load the `kernel` into memory
  - Load `initramfs` into memory
- Kernel
  - mount ramfs/tmpfs (File system on memory)
    - Source Code `fs/ramfs/inode.c`
    - View the registered file system:`cat /proc/filesystems | grep ramfs`
  - Extract `initramfs` to `rootfs`
  - Find the `init` program and transfer control to `init`
- The `init` process does other things and mounts the real `rootfs`


## ramdisk & ramfs & tmpfs & rootfs

### ramdisk
内存上划出一块区域`/dev/initrd`
块设备是固定大小的
需要文件系统去识别数据=>内核中要有对应驱动


### ramfs
据说是Linus Torvalds实现
在内存上挂载文件系统


### tmpfs
ramfs的升级版
可以使用交换空间,内存满的时候仍然可以正常运行


### rootfs
是ramfs和tmpfs的一个实例
区别于/root是root 用户的家目录


## initrd

- initial RAM Disk
  - 块设备:`/dev/initrd`
  - 已经被`initramfs`取代
  - 要求内核有对应的文件系统驱动
  - 大小是固定的，不可动态调整
- 手册
  - `man initrd`
- 目的
  - 内核中保留少量的启动代码，将要加载的模块等放在`initrd`中,实现精简内核代码
- 不足
  - 基于块设备，大小固定
    - 小了会导致init脚本放不下
    - 大了会浪费内存空间


## initramfs

- initial RAM Filesystem
- 2.6及之后的内核`/boot/initramfs.img`
- 格式:gzip压缩的cpio包
- 创建方式
  - 使用cpio打包
  - 使用gzip压缩cpio包
- 使用方式
  - 在系统引导时，cpio包会被解压，里面的文件会被加载进内存
  - 文件系统在使用前必须挂载
- 生成方式
  - cpio && gzip
    - `ls | cpio -ov -H newc | gzip > ./initramfs.img`
  - dracut
    - 生成的文件为initrd(实际上为initramfs)
  - 编译进内核
    - 如果内核中initramfs和外部的initramfs都存在，则外部的会覆盖内核中的
- 拆解
  - /boot/initramfs.img
    - 本质:经过gzip压缩的cpio包
  - 拆解
    - 解压
    - `mv initramfs.img initramfs.img.gz`
    - `gunzip initramfs.img.gz`
    - 解包
      - `mkdir -p initramfs`
      - `cpio -i -D initramfs < initramfs.img`
    - init
      - `modprob` 挂载模块
      - `switch_root [options] <newrootdir> <init> <args to init>  # switch_root /new_root /sbin/init` 切换到真实的rootfs


## initramfs & initrd

- 相同点
  - 目标:在引导阶段，加载真实的根文件系统
  - 将一些内核不方便做的事情放到用户态(init进程)
- 不同基础
  - initrd基于块设备(block device),需要内核有文件系统驱动，大小固定
  - initramfs基于文件(file),多个文件打包，大小可伸缩
- 创建方式不同
  - initrd
    - 需要内核有文件系统驱动
  - initramfs
    - 压缩包
  
**小结**
- initramfs是initrd的继承者
- 现在虽然还有叫做initrd的文件，但是可能是一个initramfs
- initramfs是多个文件通过cpio打包和gzip压缩的一个文件
- initramfs做一些内核不容易做的事情，比如挂载文件系统、加载模块等




