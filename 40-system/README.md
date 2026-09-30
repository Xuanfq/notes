# 40-system — 固件与系统

从固件/引导到内核、再到日常使用。

| 子目录 | 内容 |
|---|---|
| `basics/` | 底层基础：BIOS/UEFI、ACPI、BootLoader、GPT/MBR 分区表、I2C、GPIO、字节序 |
| `bootloader/` | grub、uboot |
| `kernel/` | overview 总览 · build 编译打包 · startup 启动与关机 · driver 驱动与设备模型 · dev 开发与调试 · subsystems 子系统 |
| `knowledge/` | 启动参数、runlevel、printk 等 |
| `usage/` | Linux 日常命令与运维 |
| `vm/` | KVM 等虚拟化 |
| `c/` | C 语言与工具链：define、GDB、GNU Tools、编译链接 |

## 目录内笔记

### basics
- [ACPI S0-S5&G0-G3](basics/ACPI%20S0-S5&G0-G3.md)
- [BIOS UEFI & BootLoader](basics/BIOS%20UEFI%20&%20BootLoader.md)
- [BootLoader](basics/BootLoader.md)
- [GPIO工作模式](basics/GPIO工作模式.md)
- [GPT & MBR](basics/GPT%20&%20MBR.md)
- [GPT分区表](basics/GPT分区表.md)
- [I2C](basics/I2C.md)
- [字节序大端小端](basics/字节序大端小端.md)

### bootloader/grub
- [GRUB Demo](bootloader/grub/GRUB%20Demo.md)
- [GRUB](bootloader/grub/GRUB.md)

### bootloader/uboot
- [Intro](bootloader/uboot/Intro.md)

### c
- [define](c/define.md)
- [GDB](c/GDB.md)
- [GNU Tools](c/GNU%20Tools.md)
- [编译链接](c/编译链接.md)

### kernel/build
- [BusyBox](kernel/build/BusyBox.md)
- [Kernel Compile](kernel/build/Kernel%20Compile.md)
- [Kernel Download](kernel/build/Kernel%20Download.md)
- [Linux Initramfs Demo](kernel/build/Linux%20Initramfs%20Demo.md)

### kernel/dev
- [Kernel Debug - QEMU & GDB](kernel/dev/Kernel%20Debug%20-%20QEMU%20&%20GDB.md)
- [Kernel Dev - Add Syscall](kernel/dev/Kernel%20Dev%20-%20Add%20Syscall.md)
- [Linux Dev - Add Module](kernel/dev/Linux%20Dev%20-%20Add%20Module.md)
- [基于ioctl的接口](kernel/dev/基于ioctl的接口.md)

### kernel/driver
- [驱动模型](kernel/driver/驱动模型.md)
- [驱动认知](kernel/driver/驱动认知.md)
- [设备链接与电源管理](kernel/driver/设备链接与电源管理.md)
- [设备模型-kset kobject ktype](kernel/driver/设备模型-kset%20kobject%20ktype.md)
- [设备模型之kset_kobj_ktype分析](kernel/driver/设备模型之kset_kobj_ktype分析.md)
- [设备资源访问](kernel/driver/设备资源访问.md)

### kernel/driver/i2c
- [I2C Code](kernel/driver/i2c/I2C%20Code.md)
- [I2C MUX](kernel/driver/i2c/I2C%20MUX.md)
- [I2C设备的添加方法](kernel/driver/i2c/I2C设备的添加方法.md)

### kernel/overview
- [API](kernel/overview/API.md)
- [内核目录结构](kernel/overview/内核目录结构.md)

### kernel/startup
- [Linux Startup Procedure](kernel/startup/Linux%20Startup%20Procedure.md)
- [reboot & shutdown 原理 (x86)](kernel/startup/reboot%20&%20shutdown%20原理%20(x86).md)
- [底层 BIOS & UEFI 服务](kernel/startup/底层%20BIOS%20&%20UEFI%20服务.md)

### kernel/subsystems
- [CPU空闲时间管理](kernel/subsystems/CPU空闲时间管理.md)
- [Linux fs](kernel/subsystems/Linux%20fs.md)
- [PCIe](kernel/subsystems/PCIe.md)
- [虚拟文件系统VFS](kernel/subsystems/虚拟文件系统VFS.md)

### knowledge
- [Linux File cmdline](knowledge/Linux%20File%20cmdline.md)
- [Linux File inittab](knowledge/Linux%20File%20inittab.md)
- [Linux Kernel Printk](knowledge/Linux%20Kernel%20Printk.md)
- [Linux rcN.d rcS.d rc.local](knowledge/Linux%20rcN.d%20rcS.d%20rc.local.md)
- [Linux runlevel](knowledge/Linux%20runlevel.md)

### usage
- [Linux apt命令](usage/Linux%20apt命令.md)
- [Linux crontab定时任务](usage/Linux%20crontab定时任务.md)
- [Linux scp传文件](usage/Linux%20scp传文件.md)
- [Linux sed命令](usage/Linux%20sed命令.md)
- [Linux shell](usage/Linux%20shell.md)
- [Linux yum命令](usage/Linux%20yum命令.md)
- [Linux安装ssh](usage/Linux安装ssh.md)
- [Linux串口工具-Minicom](usage/Linux串口工具-Minicom.md)
- [Linux基本结构](usage/Linux基本结构.md)
- [Linux其他笔记-包安装](usage/Linux其他笔记-包安装.md)
- [Linux文件编辑器vi及vim](usage/Linux文件编辑器vi及vim.md)
- [Linux文件基本属性](usage/Linux文件基本属性.md)
- [Linux文件及目录管理](usage/Linux文件及目录管理.md)
- [Linux文件及目录链接](usage/Linux文件及目录链接.md)
- [Linux文件系统和磁盘管理](usage/Linux文件系统和磁盘管理.md)
- [Linux文件压缩](usage/Linux文件压缩.md)
- [Linux系统启动过程](usage/Linux系统启动过程.md)
- [Linux系统诊断](usage/Linux系统诊断.md)
- [Linux用户及用户组管理](usage/Linux用户及用户组管理.md)
- [Linux远程桌面登录](usage/Linux远程桌面登录.md)
- [Ubuntu 20.04 设置root用户并自动登录](usage/Ubuntu%2020.04%20设置root用户并自动登录.md)
- [Ubuntu root桌面登录](usage/Ubuntu%20root桌面登录.md)

### vm
- [Linux KVM Command](vm/Linux%20KVM%20Command.md)
- [Linux VM Introduce](vm/Linux%20VM%20Introduce.md)
