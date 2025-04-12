# Logic of onie startup

onie启动逻辑


## 名词说明

- start-stop-daemon: 启动和停止系统守护程序，通用命令，位于`/usr/sbin/start-stop-daemon`，基本用法：
  - 自定义pid: `-p /var/run/discover.pid `
  - 不创建pidfile: `-m`
  - 后台运行: `-b`
  - 指定程序或命令: `-x xxx`
  - 不要输出警告: `-q`
  - 设置信号: `-s $signal(default TERM)`
  - 启动守护程序：`start-stop-daemon -S -b -m -p /var/run/discover.pid -x /bin/discover`
  - 关闭守护程序：`start-stop-daemon -q -K -s TERM -p /var/run/${daemon}.pid`


## 步骤概述

1. /etc/inittab (rootconf/default/etc/inittab): inittab为系统的PID=1的进程，决定这系统启动调用哪些启动脚本文件
   1. `::shutdown:/etc/init.d/rc 6`: 设置关机时执行的rc脚本，`/etc/rc6.d/`, 与`/etc/rc0.d/`一样
   2. `::restart:/sbin/init`: restart是非标准动作，需要查看busybox文档? `busybox init --help`?
   3. `::sysinit:/etc/init.d/rc S`: 系统初始化时执行命令`/etc/init.d/rc S`, 即优先完成`/etc/rcS.d/`下的脚本
      1. `S01makedev.sh`: 挂载内核文件系统并创建初始设备
         1. `PATH=/usr/bin:/usr/sbin:/bin:/sbin`: 避免因环境变量未设置导致命令找不到的问题
         2. `mount -t proc -o nodev,noexec,nosuid proc /proc`: 挂载 Linux 的 ​​proc 虚拟文件系统​​，并增加安全限制选项。 默认包含内核和进程的敏感信息（如 /proc/self/mem 可读写内存）。通过 nodev,noexec,nosuid 限制，可减少攻击面。可能出现在`/etc/fstab`: `proc /proc proc nodev,noexec,nosuid 0 0`
            1. `-t proc`: 指定文件系统类型为 proc（进程信息虚拟文件系统）
            2. `-o nodev,noexec,nosuid`: 挂载选项（禁用设备、禁止执行、忽略 SUID 权限）
            3. `proc`: 源设备（内核虚拟的 proc 文件系统）
            4. `/proc`: 挂载目标路径
         3. `mount -t devtmpfs devtmpfs /dev`: 挂载 Linux 的 ​​devtmpfs 虚拟文件系统​​，是内核提供的动态设备管理机制。内核自动在 /dev 下创建设备节点（如 /dev/sda, /dev/ttyS0），无需手动 mknod 或依赖 udev。当设备插入或移除时（如 USB 设备），节点会自动创建/删除。如果系统使用 udev，devtmpfs 会先提供初始设备，再由 udev 进一步管理权限和符号链接。
            1. `-t devtmpfs`: 指定文件系统类型为 devtmpfs
            2. `devtmpfs`: 内核虚拟设备源（无实际设备文件）
            3. `/dev`: 挂载目标目录
         4. `[ -e /dev/console ] || mknod -m 0600 /dev/console c 5 1`: 检查并创建必要的设备节点 /dev/console，确保系统的基本输入输出存在。
            1. `-m 0600`: 设置设备权限为 0600（仅 root 可读写），防止普通用户读取内核日志或注入输入（安全敏感）。
            2. `c`: 创建字符设备（character device）
            3. `5 1`: 主设备号 5（终端设备），次设备号 1（控制台）
         5. `[ -e /dev/null ] || mknod -m 0666 /dev/null c 1 3`: 检查并创建必要的设备节点 /dev/null，确保系统的空设备存在。
            1. `-m 0666`: 所有用户可读写（黑洞设备需广泛访问），允许所有进程写入/读取（如丢弃日志或占位输入）
            2. `1 3`：主设备号 1（内存设备），次设备号 3（/dev/null）
         6. `. /lib/onie/functions`: 导入引导(启动)时的有用函数和变量。
         7. `echo "5 4 1 5" > /proc/sys/kernel/printk`: 修改 Linux 内核的 ​​printk 日志级别​​，控制内核消息（如 dmesg 输出）的打印行为。<console_loglevel> <default_loglevel> <minimum_loglevel> <default_console_loglevel>。
            1. `5`: 控制台仅显示级别 0-5 的消息​​（KERN_EMERG 到 KERN_NOTICE），忽略 INFO 和 DEBUG 信息。
            2. `4`: 未指定级别的 printk 默认使用级别 4（KERN_WARNING）。
            3. `1`: 允许设置的最低级别为 1（防止误设为 0 导致日志完全关闭）。
            4. `5`: 控制台初始级别为 5（与参数 1 一致）。
         8. `mount_kernelfs`: 执行函数挂载内核虚拟文件系统。
            - for [/run, /run/lock]:
              - mounttmpfs $dir "defaults,noatime,size=10M,mode=1777":
                - mount -o "defaults,noatime,size=10M,mode=1777" -t tmpfs tmpfs $dir
                - touch $dir/.ramfs
              - 检查确保/var/run/链接到/run
            - for [/tmp, /var/tmp]:
              - mounttmpfs $dir "defaults,noatime,mode=1777":
                - mount -o "defaults,noatime,mode=1777" -t tmpfs tmpfs $dir
                - touch $dir/.ramfs
            - /sys:
              - mount -o nodev,noexec,nosuid -t sysfs sysfs /sys
            - /run/shm: 处理好 `mountdevsubfs.sh` 脚本所承担的任务。 
              - mkdir --mode=755 $dir
              - mounttmpfs $dir "nosuid,nodev":
                - mount -o "nosuid,nodev" -t tmpfs tmpfs $dir
                - touch $dir/.ramfs
            - /dev/pts:
              - mkdir --mode=755 $dir
              - mount -o "noexec,nosuid,gid=5,mode=620" -t devpts  devpts $dir; TTYGRP=5; TTYMODE=620; 
         9. ​​MTD 设备, 使用在 /proc/mtd 中找到的名称在 /dev 目录下创建符号链接。(MTD（Memory Technology Devices）是 Linux 内核中用于管理 ​​非易失性存储设备（Non-Volatile Memory, NVM）​​ 的子系统，主要针对 ​​NOR Flash、NAND Flash、ROM、RAM 磁盘​​ 等存储介质。它提供统一的接口，使文件系统（如 JFFS2、UBIFS）和 Flash 工具（如 flashcp、mtd-utils）能够操作这些设备。)
            1. mtds=`$(sed -e 's/://' -e 's/"//g' /proc/mtd | tail -n +2 | awk '{ print $1 ":" $4 }')` : 提取mtd0: 00080000 00020000 "bootloader"为mtd0:bootloader
            2. for x in $mtds:
               1. `dev=/dev/${x%:*}`, :前部分
               2. `name=${x#*:}`, :后部分
               3. [ -c $dev ] && `ln -sf $dev /dev/mtd-$name`, 字符设备才可创建链接
         10. 若支持，挂载安全文件系统
            1. if grep -q securityfs /proc/filesystems; then mount -t securityfs securityfs /sys/kernel/security
         11. `mkdir -p ONIE_RUN_DIR(="/var/run/onie")`: 创建ONIE运行目录
         12. `mkdir -p ONIE_USB_DIR(="/mnt/usb")`: 创建USB挂载点目录
      2. `S05gen-config.sh`: 根据`/etc/machine-build.conf`和`/etc/machine-live.conf`(/lib/onie/gen-config-platform)生成onie配置变量/文件`/etc/machine.conf`
         1. cat /etc/machine-build.conf /etc/machine-live.conf > /etc/machine.conf
         2. 删除并更新配置/变量: 
            1. `onie_machine=${onie_machine:-$onie_build_machine}`: 若`onie_machine`未设置则使用`onie_build_machine`
            2. `onie_platform=${onie_platform:-${onie_arch}-${onie_machine}-r${onie_machine_rev}}`: 若`onie_platform`未设置则使用`${onie_arch}-${onie_machine}-r${onie_machine_rev}`
      3. `S10init-arch.sh`: 初始化特定于架构的系统
         1. `. /lib/onie/functions`: 导入引导(启动)时的有用函数和变量。
         2. `[ -r /lib/onie/init-arch ] && . /lib/onie/init-arch`: 来自onieroot/rootconf/xxx-arch/sysroot-lib-onie/init-arch
            - grub-arch: 不提供函数init_arch。在启动时挂载 ONIE 分区。如果磁盘分区不可用（例如，我们通过网络启动且硬盘为空），那么只需在当前的内存盘中创建 $onie_config_dir(/mnt/onie-boot/onie/config/) 目录，然后继续操作。 
              - `. /lib/onie/onie-blkdev-common`
              - `mkdir -p $onie_boot_mnt=/mnt/onie-boot/`
              - `device=$(onie_get_boot_dev)`: 查找ONIE-BOOT设备持续7秒(70次)除非找到
              - `init_onie_boot`: 添加挂载条目onie分区到`/etc/fstab`, 对给定的分区执行文件系统一致性检查（FSCK）并进行重试, 挂载。
              - `mkdir -p $onie_config_dir $onie_update_pending_dir $onie_update_attempts_dir $onie_update_results_dir`=make -p /mnt/onie-boot/onie/config/ /mnt/onie-boot/onie/update/pending/ /mnt/onie-boot/onie/update/attempts/ /mnt/onie-boot/onie/results/
              - `init_uefi`: 若是UEFI模式(存在目录/sys/firmware/efi/efivars)，添加挂载条目EFI分区到`/etc/fstab`, 对给定的分区执行文件系统一致性检查（FSCK）并进行重试, 挂载。
              - 识别和输出BIOS模式bios_mode=UEFI|legacy, UEFI模式时检查或输出安全启动是否激活。
            - u-boot-arch: 提供函数init_arch。该函数旨在查找 U-Boot 环境变量存储设备​​，并生成 `/etc/fw_env.config` 文件，供 `fw_setenv/fw_printenv` 工具使用。
              - `env_file=$(find /proc/device-tree/ -name env_size)`: 在设备树中查找具有属性`env_size`的NOR闪存节点
              - `env_sz="0x$(hd $env_file | awk 'FNR==1 {print $2 $3 $4 $5}')"`: 读取环境变量大小，提取第一行的第 2-5 列（合并为十六进制值，如 00040000）
              - `mtd=$(grep uboot-env /proc/mtd | sed -e 's/:.*$//')`: 识别 uboot-env 的 MTD 设备; (proc/mtd 如 mtd0: 00040000 00020000 "uboot-env")
              - `sect_sz="0x$(grep uboot-env /proc/mtd | awk '{print $3}')"`: 获取闪存扇区大小 (sect_sz)​
              - 生成`cat (EOF\n /dev/$mtd 0x00000000(Device offset) $env_sz $sect_sz\n EOF) > /etc/fw_env.config`
         3. `[ -r /lib/onie/init-platform ] && . /lib/onie/init-platform`: 来自machine的实现
         4. `init_platform_pre_arch`(执行函数): 钩子函数，可在`machine/rootconf/sysroot-lib-onie/init-platform`中实现
         5. `init_arch`(执行函数): 默认为u-boot才存在实质的用途
         6. `init_platform_post_arch`(执行函数): 钩子函数，可在`machine/rootconf/sysroot-lib-onie/init-platform`中实现, 如实现动态波特率(stty -F /dev/ttyS0的波特率和/proc/cmdline不一致时修改grub波特率并重启)等。
      4. `S15boot-mode.sh`: 调整启动模式，依赖不同架构不同实现即/rootconf/xxx-arch/sysroot-lib-onie/boot-mode-arch。若是救援模式，应删除一次性的onie_boot_reason环境变量因为通常我们把救援模式作为一次性操作；而安装NOS模式下具有粘性，即若没安装NOS，则下次仍然会默认进入NOS安装模式，若已安装NOS，则清除当前boot mode（设置为none）。
         1. `. /lib/onie/functions`
         2. `import_cmdline`: 导入Linux内核参数
         3. `. /lib/onie/boot-mode-arch`: 导入架构特定实现，若无则退出！
         4. `onie_boot_reason`:
            1. `onie_boot_reason=rescue`: `rescue_revert_default_arch` 无实际动作
            2. `onie_boot_reason=install`: 
               1. `check_nos_mode_arch && return 0`: 若NOS已安装，后续操作不再执行
                  1. `[ $(onie-nos-mode -g) = "yes" ] && onie-boot-mode -q -o none && return 0`
                  2. `return 1`
               2. `install_remain_sticky_arch`: 
                  1. `[ "$(onie_get_running_firmware)" = "uefi" ] && uefi_boot_onie_install`:
                     1. `uefi_boot_first "ONIE:"`: 设置onie为第一启动项，通过`efibootmgr`命令操作
                     2. `onie-boot-mode -q -o install`: 设置onie默认为install模式
                  2. `[ "$(onie_get_running_firmware)" != "uefi" ] && bios_boot_onie_install`:
                     1. 在主引导记录（MBR）和 ONIE 分区中重新安装 ONIE 的 GRUB（多操作系统启动管理器）。
                     2. `onie-boot-mode -q -o install`: 设置onie默认为install模式
                  3. `sync;sync`
      5. `S20network-driver.sh`: 网络驱动加载和初始化，一般特定于交换机芯片的驱动才需实现
         1. `. /lib/onie/functions`
         2. `network_driver_platform_pre_init`(执行函数): 钩子函数，可在`machine/rootconf/sysroot-lib-onie/network-driver-platform`中实现
         3. `network_driver_init`(执行函数): 可在`network-driver-${onie_switch_asic}`中实现
         4. `network_driver_platform_post_init`(执行函数): 钩子函数，可在`machine/rootconf/sysroot-lib-onie/network-driver-platform`中实现
      6. `S30networking.sh`: 配置以太网管理接口网络
         1. `PATH=/usr/bin:/usr/sbin:/bin:/sbin`
         2. `. /lib/onie/functions`
         3. `import_cmdline`
         4. `ip link set dev lo up`: 启用回环接口
         5. 配置MAC地址,但保持接口处于关闭状态: 可通过在`machine.make`中配置`SKIP_ETHMGMT_MACS = yes`进行跳过
            1. `base_mac=$(onie-sysinfo -e)`: mac基地址，以此递增
            2. `for intf in $(net_intf)`: `md_run ifconfig $intf down; cmd_run ifconfig $intf hw ether $mac down`
         6. `config_ethmgmt`: 配置管理接口IP，逐个配置
            1. check_link_up: `$(cat /sys/class/net/${intf}/operstate) = "up"|"unknown"|"down"`持续10s等待网口link up
            2. static ip: 来自内核命令参数
            3. DHCPv6:
            4. DHCPv4:
            5. 回退到知名的（常用的）IP 地址:
      7. `S40syslogd.sh`: syslogd（System Log Daemon）是Unix/Linux 系统中的 ​​系统日志守护进程​​，负责 ​​收集、记录和管理系统日志​​。它通常与 klogd（内核日志守护进程）配合使用，形成完整的日志记录体系。
         1. `daemon="syslogd"; ARGS="-b 3 -D -L"`
         2. `. /lib/onie/functions`
         3. `ARG_FILE`="${ONIE_RUN_DIR}/syslogd.args"=/var/run/onie/syslogd.args
         4. `[ -r "${ONIE_RUN_DIR}/dhcp.logsrv" ] && LOGSRVS=$(cat "${ONIE_RUN_DIR}/dhcp.logsrv") && for r in $LOGSRVS; do ARGS="$ARGS -R $r" done`
         5. `[ -r "$ARG_FILE" ] && OLD_ARGS=$(cat "$ARG_FILE")`
         6. 若`"$OLD_ARGS" != "$ARGS"`则重新开启syslogd服务
      8. `S50klogd.sh`: klogd，内核日志守护进程，开启该进程
   4. `::wait:/etc/init.d/rc 3`: 等待命令`/etc/init.d/rc 3`执行完成，完成运行级别为3(完整的多用户模式)的`/etc/rc3.d/`下的脚本
      1. `S10dropbear.sh`: 启动sshd服务
      2. `S10telnetd.sh`: 启动telnetd服务
      3. `S50discover.sh`: 启动发现服务
         1. 读取环境变量: `$onie_boot_reason`
         2. `echo "$daemon: xxx mode detected.  (Installer disabled.|Running uninstaller.|Running installer.|Running updater.)" > /dev/console`
         3. `echo "** xxx Mode Enabled **" >> /etc/issue`
         - rescue: 无过多操作，退出0
         - uninstall: `/bin/onie-uninstaller;exit 0`, 启动查找发现服务`start-stop-daemon -S -b -m -p /var/run/discover.pid -x /bin/discover`
         - update|embed: 查找`updater`, 启动查找发现服务`start-stop-daemon -S -b -m -p /var/run/discover.pid -x /bin/discover`
         - install: 查找`installer`, 启动查找发现服务`start-stop-daemon -S -b -m -p /var/run/discover.pid -x /bin/discover`
   5. `::askfirst:-/bin/onie-console`: 进入控制台
      1. `cat /etc/issue`: 输出一些信息
      2. `exec /bin/sh -l`: 进入shell，加载登录环境：
         1. 读取 /etc/profile 和 ~/.profile（或其他 Shell 的配置文件，如 ~/.bash_profile）。
         2. 初始化环境变量（如 PATH, HOME）、别名（alias）和函数。


### Discover

Source: `/bin/discover`

目的：发现并运行安装installer/updater程序


#### 代码逻辑

1. 准备好库函数/变量等：
   1. 导入引导时的有用函数和变量: `. /lib/onie/functions`
      1. machine.conf: `. /etc/machine.conf`
      2. 环境变量`onie_installer`="/var/tmp/installer"
      3. 变量`ONIE_RUN_DIR`="/var/run/onie"
      4. 变量`tee_log_file`=/dev/console
      5. 变量`filename_prefix`="onie-updater"|"onie-installer"
      6. 变量`onie_operation`="onie-update"|"os-install"
      7. 变量`onie_default_filename`="${filename_prefix}-${onie_platform}"=
   2. 导入内核启动参数: `import_cmdline` of `/lib/onie/functions`
   3. 允许不同架构跳过查找某些分区里的安装器: `. /lib/onie/discover-arch` in `rootconf/grub-arch/sysroot-lib-onie/` to cover function `skip_parts_arch`
      - 如`grub-arch`跳过`/EFI/`分区和`-DIAG`分区
   4. 定义用于将参数传递给`exec_installer`的文件:\
      1. onie_neigh_file="${ONIE_RUN_DIR}/onie_neigh_file.txt"=/var/run/onie/onie_neigh_file.txt
      2. onie_parms_file="${ONIE_RUN_DIR}/onie_parms_file.txt"=/var/run/onie/onie_parms_file.txt
   5. 















