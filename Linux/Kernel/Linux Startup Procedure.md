

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


















