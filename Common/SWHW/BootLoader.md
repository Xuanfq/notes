# BootLoader



## BootLoader作用

BootLoader是系统上电或复位启动后，运行的第一段程序，是系统内核之前的引导加载程序，是严重依赖于硬件而实现的。它的作用是在 系统启动时，将操作系统内核从磁盘等存储介质中加载到内存中，并将控制权交给内核，使得操作系统能够正常运行。具体来说， BootLoader主要有以下两个作用： 1. 第一部分stage1的作用：在计算机启动时，BIOS会将控制权交给MBR（Master Boot Record），MBR会读取硬盘的第一个扇区，即 引导扇区，这个扇区就是stage1。stage1的主要作用是加载stage2。 2. 第二部分stage2的作用：stage2是BootLoader的主要部分，它的作用是加载操作系统内核。stage2会读取文件系统中的内核文件， 并将其加载到内存中，然后将控制权交给内核，使得操作系统能够正常运行。 因此，可以说BootLoader是操作系统启动的关键，没有BootLoader，操作系统就无法正常启动。



## 常见BootLoader

1. GRUB（GRand Unified Bootloader）：GRUB 是 Linux 系统中最常用的 bootloader 之一，支持多操作系统启动，包括 Windows 和 macOS。 
2. LILO（Linux Loader）：LILO 是 Linux 系统中另一个常用的 bootloader，但它不支持多操作系统启动。 
3. SYSLINUX：SYSLINUX 是一个轻量级的 bootloader，通常用于启动 Live CD 或 USB 设备上的 Linux 系统。 
4. U-Boot：U-Boot 是一个开源的 bootloader，主要用于嵌入式系统中，如路由器、交换机、智能手机等。支持多种处理器架构和操作系统，具有强大的网络支持和可扩展性。
5. Das U-Boot（Universal Bootloader）：Das U-Boot 是 U-Boot 的变体，也是一款开源的 bootloader，支持多种 CPU 架构和操作系 统。 
6. Windows Boot Manager：Windows Boot Manager 是 Windows 系统中的 bootloader，通常与 UEFI 固件配合使用。 
7. Syslinux
8. rEFIt
9. rEFInd
10. RedBoot：类似于U-Boot的开源bootloader，支持多种处理器架构和操作系统。
11. Barebox：基于U-Boot的开源bootloader，主要针对嵌入式系统的需求，具有更加灵活的配置选项和扩展性； 
12. ROMMON：Cisco设备专用的bootloader，用于在设备启动时进行系统初始化和配置

