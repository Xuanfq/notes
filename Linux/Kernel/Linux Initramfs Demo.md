
# Linux Initramfs Demo



## Compile Kernel
make menuconfig
make-j15



## Compile BusyBox

Basic command line tools, sh, cat, echo, etc

### Compile Steps:
make menuconfig
make-j15
make install



## Make initramfs

第一个进程init存储在根文件系统或者内存文件系统

### Make Methods:
- Packaged BusyBox as cpio
- Compile directly into the kernel (make menuconfig)

#### Packaged BusyBox as cpio
find . -print0 | cpio --null -ov --format=newc| gzip - 9 > ../build
/initramfs.img

Command Details:
- Three commands, and finally an output redirect
- `find`: file find
- `cpio`: packaging 
  - `null`: Do not use file names
  - `o`: create
  - `v`: output detail information
  - `format`: The file format can be tar, newc, bin, or odc
  - `newc` 支持超过65536个inode的文件系统
- gzip compress
  - `9`: Compression level, slowest but smallest volume, defaults to -6



## Start QEMU
QEMU is a generic and open source machine emulator and virtualizer.

QEMU can be used in several different ways. The most common is for System Emulation, where it provides a virtual model of an entire machine (CPU, memory and emulated devices) to run a guest OS. In this mode the CPU may be fully emulated, or it may work with a hypervisor such as KVM, Xen or Hypervisor.Framework to allow the guest to run directly on the host CPU.

The second supported way to use QEMU is User Mode Emulation, where QEMU can launch processes compiled for one CPU on another CPU. In this mode the CPU is always emulated.

QEMU also provides a number of standalone command line utilities, such as the qemu-img disk image utility that allows you to create, convert and modify disk images.


### Run the compiled kernel
```sh
qemu-system-x86_64  \
    -kernel bzImage  \
    -initrd initramfs.img  \
    -m 1G  \
    -nographic  \
    -append "earlyprintk=serial,ttyS0 console=ttyS0"

# Quit QEMU
# Ctrl + a, then press x
```
















