# Linux File cmdline

`cmdline`是指`/proc/cmdline`, `/proc/cmdline` 是一个特殊的只读的 Linux 虚拟文件，它包含了系统启动时传递给内核的​​引导参数（boot arguments）​​，通常由 bootloader（如 GRUB、syslinux、U-Boot 等）设置。

i.e.

```sh
~# cat /proc/cmdline
BOOT_IMAGE=/boot/vmlinuz-5.15.0-113-generic root=UUID=aecbeedf-6eeb-40f6-b185-03030fc62888 ro net.ifnames=0 consoleblank=600 console=tty0 console=ttyS0,115200n8 noibrs crashkernel=0M-1G:0M,1G-4G:192M,4G-128G:384M,128G-:512M
```

## 常见内核启动参数解析​​

| 参数 | 说明 |
|------|------|
| `root=` | 指定根文件系统设备（如 `root=/dev/sda1` 或 `root=UUID=xxxx`） |
| `ro` / `rw` | 以**只读（ro）**或**读写（rw）**方式挂载根文件系统 |
| `quiet` | 减少启动时的控制台输出 |
| `splash` | 显示启动画面（如 Plymouth 动画） |
| `init=` | 指定替代的初始化程序（如 `init=/bin/bash` 用于救援模式） |
| `console=` | 指定控制台设备（如 `console=ttyS0,115200` 用于串口终端） |
| `panic=` | 设置内核 panic 后自动重启的秒数（如 `panic=10`） |
| `mem=` | 限制内核使用的内存大小（如 `mem=2G`） |
| `ip=` | 设置网络启动参数（常用于 PXE 启动） |
| `vga=` | 设置显示模式（如 `vga=791` 对应 1024x768） |
| `acpi=` | 控制 ACPI 行为（如 `acpi=off` 禁用 ACPI） |
| `mitigations=` | 控制 CPU 漏洞缓解措施（如 `mitigations=off` 提高性能但降低安全性） |


## 永久修改内核启动参数

要永久修改启动参数，需要编辑 bootloader 配置：

• **GRUB (Ubuntu/Debian)**  
  ```bash
  sudo nano /etc/default/grub
  ```
  修改 `GRUB_CMDLINE_LINUX_DEFAULT` 或 `GRUB_CMDLINE_LINUX`，然后更新 GRUB：
  ```bash
  sudo update-grub
  ```

• **Syslinux (LiveCD/Embedded)**  
  修改 `/boot/syslinux/syslinux.cfg` 或 `/boot/extlinux/extlinux.conf`。

• **U-Boot (嵌入式设备)**  
  修改 `bootargs` 环境变量：
  ```bash
  setenv bootargs "console=ttyS0,115200 root=/dev/mmcblk0p2 rw"
  saveenv
  ```



## 临时修改启动参数

在 GRUB 启动菜单界面，按 `e` 编辑当前启动项，修改 `linux` 行的参数后按 `Ctrl+X` 启动。



## 常见用途
• **调试启动问题**：移除 `quiet` 和 `splash` 查看详细日志。
• **救援模式**：添加 `init=/bin/bash` 进入单用户 shell。
• **禁用驱动/功能**：如 `nouveau.modeset=0` 禁用 NVIDIA 驱动。
• **网络启动**：`ip=dhcp` 或 `nfsroot=` 用于无盘系统。



## 注意事项
• 错误的参数可能导致系统无法启动，建议先在 GRUB 临时修改测试。
• `/proc/cmdline` 是只读的，不能直接修改它来改变运行时的内核参数。


