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
            3. DHCPv6: 未实现
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


### discover

Source: `/bin/discover`

目的：发现并运行安装installer/updater程序

用法：`discover`


#### 代码逻辑

1. 准备好库函数/变量等：
   1. 导入引导时的有用函数和变量: `. /lib/onie/functions`
      1. machine.conf: `. /etc/machine.conf`
      2. 环境变量`onie_installer`="/var/tmp/installer"
      3. 变量`ONIE_RUN_DIR`="/var/run/onie"
      4. 变量`tee_log_file`=/dev/console
      5. 变量`filename_prefix`="onie-updater"(update or embed mode)|"onie-installer"(install mode)
      6. 变量`onie_operation`="onie-update"|"os-install"
      7. 变量`onie_default_filename`="${filename_prefix}-${onie_platform}"=
      8. 哪些文件名会当作默认的image/installer/updater的文件名? 存放在 `onie_default_filenames`, func `get_default_filenames`
         1. `onie-updater/installer-$onie_platform`
         2. `onie-updater/installer-$onie_arch-$onie_machine`=onie-updater-x86_64-$onie_platform
         3. `onie-updater/installer-$onie_machine`=onie-updater-cls_xxx
         4. `onie-updater/installer-${onie_arch}-$onie_switch_asic`=onie-updater-x86_64-bcm
         5. `onie-updater/installer-$onie_switch_asic`=onie-updater-bcm
         6. `onie-updater/installer`
   2. 导入内核启动参数: `import_cmdline` of `/lib/onie/functions`
   3. 允许不同架构跳过查找某些分区里的安装器: `. /lib/onie/discover-arch` in `rootconf/grub-arch/sysroot-lib-onie/` to cover function `skip_parts_arch`
      - 如`grub-arch`跳过`/EFI/`分区和`-DIAG`分区
   4. 定义用于将参数传递给`exec_installer`的文件:\
      1. onie_neigh_file="${ONIE_RUN_DIR}/onie_neigh_file.txt"=/var/run/onie/onie_neigh_file.txt
      2. onie_parms_file="${ONIE_RUN_DIR}/onie_parms_file.txt"=/var/run/onie/onie_parms_file.txt
2. 循环发现installer/updater：
   1. `/etc/init.d/networking.sh discover`: 仅配置IP
   2. `/etc/init.d/syslogd.sh discover`: 开启日志守护进程
   3. `service_discovery`: 服务发现，查找可供安装程序使用的 URL（一个或多个）
      1. `sd_static  && return`: 如果通用引导加载程序（u-boot or embed-mode）传递给我们的是静态网址（onie_install_url），那么就使用该网址。 存放到变量`onie_static_url`
      2. `sd_localfs`: 查找本地文件系统，只查找文件系统根目录（跳过arch指定的分区如EFI和-DIAG），存放在变量`onie_local_parts`
      3. `sd_localubifs`: 查找本地UBI文件系统，只查找文件系统根目录（跳过arch指定的分区如EFI和-DIAG），存放在变量`onie_local_parts`（UBI（​​Unsorted Block Images​​）是 Linux 专为 ​​NAND Flash​​ 设计的文件系统管理层，位于 ​​MTD（Memory Technology Device）​​ 之上）。
         1. `for p in /sys/class/ubi/ubi?/ubi?_?`
         2. `ubiname=$(cat $p/name)`
         3. `mount -t ubifs ubi:$ubiname $mp`
      4. `sd_dhcp6`: 未实现
      5. `sd_dhcp4`: 包括http, tftp, dhcp, pxe, dns等服务器地址和配置，存放到变量`onie_disco`
         1. `udhcpc $(udhcpc_args) -t 2 -T 2 -n  -O 7 -O 43 -O 54 -O 66 -O 67 -O 72 -O 114 -O 125  -i $intf -s /lib/onie/udhcp4_sd`: 在所有网络接口上依次尝试 DHCP 请求，以获取 IP 和配置，包括DNS服务器(7), 厂商特定信息（如 PXE 配置）(43),DHCP 服务器标识(54),TFTP 服务器地址（用于网络启动）(66),启动文件名（如 onie-installer）(67),HTTP 代理(72),自定义选项（ONIE 扩展）(114),厂商识别码(125)
      6. `sd_mdns`: mDNS / DNS-SD，未实现
      7. `sd_fallback`: 未实现
   4. `neigh_discovery`: 网络邻居发现,存放于到文件`onie_neigh_file`=/var/run/onie/onie_neigh_file.txt。后续将存放到`onie_parms_file`=/var/run/onie/onie_parms_file.txt
      1. `ip addr show dev $i | grep tentative`: 等待接口链路本地地址脱离不确定状态。 
      2. `ip -4 neigh show | awk '{print $1}' | tr '\n' ',' >> $onie_neigh_file`: 收集IPv4网络邻居
      3. `ip -6 neigh show | awk '{print "[" $1 "-" $3 "]"}' | tr '\n' ',' >> $onie_neigh_file`: 收集IPv6网络邻居
      4. `cat onie_neigh_file`=: onie_neighs@@xxx,aaa,bbb##
   5. `rm -f /var/run/install.rc`: 强制删除之前的安装结果
   6. 构造`exec_installer`参数文件`onie_parms_file`=/var/run/onie/onie_parms_file.txt:
      1. `cat $onie_neigh_file > $onie_parms_file`: 添加邻居发现
      2. `echo "$onie_disco" >>  $onie_parms_file`: 添加服务发现
      3. `sed -e 's/@@/ = /g' -e 's/##/\n/g' $onie_parms_file | logger -t discover -p ${syslog_onie}.info`: 修改`name1@@val1##name2@@val2##..nameX@@valX##`格式为 `key = value \n key1 = value1`并输出到日志，syslog_onie="local0"
   7. `exec_installer $onie_parms_file 2>&1 | tee $tee_log_file | logger -t onie-exec -p ${syslog_onie}.info`: 执行安装并输出结果到控制台和系统日志，参照下文 ### exec_installer
   8. `[ -r /var/run/install.rc ] && [ "$(cat /var/run/install.rc)" = "0" ] && exit 0`: 若安装成功则退出Discover程序
   9. 等待20s, 避免自身程序的网络发现成为其他服务器的DoS攻击



### exec_installer

Source: `/bin/exec_installer`

目的：运行安装installer/updater程序

用法：`exec_installer $params_file_path`


#### 代码逻辑


1. 变量和环境准备：
   1. `. /lib/onie/functions`
   2. `syslog_tag`=onie-exec
   3. `install_result`="/var/run/install.rc"
   4. `[ -r /lib/onie/exec-installer-arch ] && . /lib/onie/exec-installer-arch`: 允许架构重写覆盖函数`finish_nos_install()`和`finish_update_install()`，主要是grub-arch的finish_update_install，u-boot-arch没有实现
   5. `parm_file`="$1"=onie_parms_file="${ONIE_RUN_DIR}/onie_parms_file.txt"=/var/run/onie/onie_parms_file.txt
   6. `parms`="$(cat $parm_file)"
2. `import_parms "$parms"`: 导入参数,将`name1@@val1##name2@@val2##..nameX@@valX##`字符串转为name=value的环境变量
   1. ...export name=val...
   2. `[ -n "$onie_disco_vivso" ] && import_vivso "$onie_disco_vivso"`: 解析 DHCP Option 125（厂商特定信息）中的 ONIE（Open Network Install Environment）相关配置，用于网络设备自动化安装的引导环境，设置并导出环境变量`onie_disco_onie_url`的值，但由于`onie_disco_vivso`没有设值，一般不会调用。可以通过设置环境变量`onie_disco_vivso`进行协助发现installer/updater！
      - `onie_disco_vivso`: i.e. 0000A67F0C01687474703A2F2F6578616D706C652E636F6D
         - 0000A67F：Open Compute Project onie_iana_enterprise 企业号 42623（0xA67F）
         - 13：长度 19，自动*2 = 38
         - 01687474703A2F2F6578616D706C652E636F6D:
           - 01：类型 1（安装程序 URL installer_url）, 类型 2 时为 （更新程序 URL updater_url），要匹配到对应的onie模式才能有用
           - 687474703A2F2F6578616D706C652E636F6D: ASCII 编码的 "http://example.com"
      - `onie_disco_onie_url`: 解释 687474703A2F2F6578616D706C652E636F6D 为 http://example.com
3. `rm -f $onie_installer`: 移除onie_installer="/var/tmp/installer" form `/lib/onie/functions`
4. `[ -z "$onie_eth_addr" ] && onie_eth_addr="$(onie-sysinfo -e)"`: MAC地址 onie_eth_addr 的值获取顺序如下
   1. is it set in the environment?  highest priority: /proc/cmdline(import_cmdline) or env name = `onie_eth_addr`
   2. platform function provided: function is `get_ethaddr_platform()`
   3. architecture function provided: function is `get_ethaddr_arch()` from `rootconf/grub-arch/sysroot-lib-onie/sysinfo-arch` in grub-arch
   4. use the contents of /sys/class/net/eth0/address: eth_addr=`$(cat /sys/class/net/eth0/address)`
   5. return "unknown"
5. `[ -z "$onie_serial_num" ] && onie_serial_num="$(onie-sysinfo -s)"`: onie_serial_num 来源于 /proc/cmdline(import_cmdline) or onie-sysinfo -s
6. `from_cli`=no; 
7. `onie_installer_parms`=""
8. `if [ -n "$onie_cli_static_url" ]`: 尝试使用静态安装器的URL，来源于`onie-nos-installer nos.bin(i.e. sonic.bin)`
   1. `from_cli`=yes
   2. `tee_log_file`=`/proc/$$/fd/1`: 发送当前stdout输出到当前进程
   3. `onie_installer_parms`="$onie_cli_static_parms": `onie-nos-installer`携带的除 nos image 本身的其他参数
   4. `url_run "$onie_cli_static_url" && exit 0`: 执行通过URL更新
      - `url_run $url`: url 格式为 http:// | ftp:// | tftp:// | file://
         ```
         1. rm -f $onie_installer
         2. http | https | ftp: 
            1. wget -o $onie_installer
            2. run_installer $url && return 0
         3. tftp:
            1. tftp_run -> tftp_wrap -> tftp -o $onie_installer
            2. run_installer $url && return 0
         4. file:
            1. copy $url $onie_installer
            2. run_installer $url && return 0
         5. rm -f $onie_installer
         6. return 1
         ```
      - `run_installer $url`: 
         ```
         1. export onie_exec_url="$1"    # 传递给installer/updater中的 installer.sh (echo "Source URL: $onie_exec_url")
         2. image_type=$(get_image_type $onie_installer)    # update | nos
         3. check_installer $image_type || return 1    # 检查onie的模式和image是否匹配，rescue允许NOS和Updater，update|embed允许Updater，install允许NOS 
         4. chmod +x $onie_installer
         5. $onie_installer $onie_installer_parms; echo "$?" > $install_result;    # 执行安装器/更新器，并将安装/更新结果存放到install_result=/var/run/install.rc上
         6. 处理安装结果：
            1. nos: finish_nos_install "$(cat $install_result)" "$onie_exec_url" "$onie_installer" && return 0    # 若安装成功，则重启reboot
            2. updater: finish_update_install "$(cat $install_result)" "$onie_exec_url" "$onie_installer" && return 0
               - u-boot-arch: 若成功, 有 /tmp/reboot-cmd 则执行，无则 reboot
               - grub-arch:
                  1. 判断 url 是不是 onie_update_pending_dir 从而是否为 fw_update (yes|no)
                  2. 存放install_result,url和image信息到 /mnt/onie-boot/update/results/$(basename $URL)
                  3. 若安装成功：
                     - if [ "$fw_update" = "yes" ] then rm -f $url $attempts_file(/mnt/onie-boot/update/attempts/$(basename $URL))
                     - else ([ -x /tmp/reboot-cmd ] && /tmp/reboot-cmd) || reboot
                  4. 若安装失败：
                     - if [ "$fw_update" = "yes" ] 计算重试次数存放到 $attempts_file(/mnt/onie-boot/update/attempts/$(basename $URL))，超过5次移除更新 rm -f $URL $attempts_file
         7. return 1
         ```
   5. 安装失败则退出1，成功退出0
9. `if [ -n "$onie_cli_static_update_url" ]`: 尝试使用静态更新器的URL，来源于`onie-self-update onie-updater-xxx.bin`
   1. `from_cli`=yes
   2. `tee_log_file`=/proc/$$/fd/1: 发送当前stdout输出到当前进程
   3. `onie_installer_parms`="$onie_cli_static_parms": `onie-self-update`携带的除 update image 本身的其他参数
   4. `url_run "$onie_cli_static_url" && exit 0`: 执行通过URL更新，过程参照上方8.4
   5. 安装失败则退出1，成功退出0
10. `if [ -n "$onie_static_url" ]`: 尝试使用静态内核命令行参数的URL，来源于GRUB加载内核时指定
   1. `url_run "$onie_static_url" && exit 0`: 成功则退出，不成功继续尝试其他方式，过程参照上方8.4
11. `if [ -d "$onie_update_pending_dir" ]`: 查找待处理的固件更新，一般是`grub-arch`架构才有，该变量源于`grub-arch/sysroot-lib-onie/onie-blkdev-common`，若为discover程序，在加载`grub-arch/sysroot-lib-onie/discover-arch`时会加载。
   1. `firmware_update_run && exit 0`: 执行更新，成功则退出
      1. `fw_rc`=1: image更新结果1，默认失败
      2. `for image in $(ls $onie_update_pending_dir)`:
         1. `url_run "$onie_update_pending_dir/$image" && fw_rc=0`: 成功则继续更新其他image
         2. `url_run "$onie_update_pending_dir/$image" || (fw_rc=1 && break)`: 失败即立即停止
      3. `if [ $fw_rc -eq 0 ]`: 
         1. `[ -x /tmp/reboot-cmd ] && /tmp/reboot-cmd`: 使用供应商的重启脚本，可定制power-cycle!
         2. `[ -x /tmp/reboot-cmd ] || (reboot && return 0)`: 软重启
      4. `return 1`
12. `if [ -n "$onie_local_parts" ]`: 尝试安装本地磁盘所有分区文件系统的discover查找的image
   1. `local_fs_run && exit 0`:  执行更新，成功则退出
      1. `mp=$(mktemp -d)`
      2. `while [ ${#onie_local_parts} -gt 0 ]`: 逐个执行安装(run_installer)，安装成功后将 reboot 或 /tmp/reboot-cmd
         1. `p=${onie_local_parts%%,*}`
         2. `mountopts="" && beginswith "ubi:" $p && mountopts="-t ubifs"`
         3. `onie_local_parts=${onie_local_parts#*,}`
         4. `mount $mountopts $p $mp > /dev/null 2>&1 && {...}`: 临时挂载
            1. `for f in $(get_default_filenames)`
               1. `if [ -r $mp/$f ]`: 
                  1. `tmp_copy=$(mktemp -p /tmp)`: 创建临时目录
                  2. `cp $mp/$f $tmp_copy`: 复制安装器/更新器到临时目录
                  3. `sync ; sync`
                  4. `umount $mp`: 取消挂载
                  5. `ln -sf $tmp_copy $onie_installer`: 链接到 /var/tmp/installer 
                  6. `run_installer "file:/$p/$f" && return 0`: 执行安装，安装成功后将 reboot 或 /tmp/reboot-cmd
                  7. `rm -f $tmp_copy $onie_installer`
                  8. `mount $mountopts $p $mp > /dev/null 2>&1` 取消临时挂载
         5. `umount $p`
      3. `rm -rf $mp`
      4. `return 1`
13. `if [ -n "$onie_disco_onie_url" ]`: 尝试安装其他额外发现的URL, 来源于本章节 2.2.(参照上方) 通过环境变量设置`onie_disco_onie_url`的值
   1. `url_run "$onie_disco_onie_url" && exit 0`: 执行通过URL更新，过程参照上方8.4
14. `if [ -n "$onie_disco_url" ]`: 尝试安装其他额外发现的URL, 暂无`onie_disco_url`的其他设值，可通过环境变量进行发现
   1. `url_run "$onie_disco_url" && exit 0`: 执行通过URL更新，过程参照上方8.4
15. `http_download && exit 0`: 尝试使用 HTTP 发现方法去尝试URL
   1. `http_servers`=$list:
      - onie_server_name="onie-server"
      - onie_disco_wwwsrv=""  # HTTP server IP only (DHCP opt 72)
      - onie_disco_siaddr=""  # BOOTP next-server IP
      - onie_disco_serverid=""   # DHCP server IP (DHCP opt 54)
      - onie_disco_tftpsiaddr="" # TFTP server IP (DHCP opt 150)
      - onie_disco_tftp="" # DHCP TFTP server name (DHCP opt 66)  # Requires DNS
      - func $(get_onie_neighs): 将 onie_neighs 环境变量转为列表  # Add link local neighbors
   2. `for server in $http_servers`
      1. `nc -w 10 $server 80 -e /bin/true > /dev/null 2>&1 && {...}`: 检查http服务的端口是否开通，若开通执行下方命令
         1. `for f in $(get_default_filenames); do url_run "http://$server/$f" && return 0 done`: 尝试获取所有相关的http文件链接，获取成功则开始安装
   3. `[ -n "$onie_disco_bootfile" ] && url_run "$onie_disco_bootfile" quiet && return 0`: 尝试将引导文件用作统一资源定位符（URL）进行安装或更新，抑制警告信息
16. `tftp_download && exit 0`: 尝试使用 TFTP 发现方法去尝试URL
   1. `tftp_servers`=$list:
      - onie_disco_siaddr=""  # BOOTP next-server IP
      - onie_disco_serverid=""   # DHCP server IP (DHCP opt 54)
      - onie_disco_tftpsiaddr="" # TFTP server IP (DHCP opt 150)
      - onie_disco_tftp="" # DHCP TFTP server name (DHCP opt 66)  # Requires DNS
   2. `tftp_bootfiles`=$list: Busybox 为 BOOTP 的启动文件设置“boot_file”，并为 DHCP 选项 67 设置“bootfile”（无下划线）。 
      - onie_disco_bootfile=""
      - onie_disco_boot_file=""
   3. `for server in $tftp_servers; do for f in $tftp_bootfiles {...}`: 
      1. `url_run "tftp://$server/$f" && return 0`: 尝试所有相关的tftp文件链接进行安装/更新
17. `waterfall && exit 0`: 尝试使用 HTTP/TFTP 瀑布式方法去尝试URL
   1. `wf_paths`=$list
      - 基于MAC(1个): `[ -n "$onie_eth_addr" ]`: 
        - `wf_paths="$(echo $onie_eth_addr | sed -e 's/:/-/g')/$onie_default_filename"`: 
          - MAC/${filename_prefix}-${onie_platform} = AA-BB-CC-DD-EE-FF/onie-updater-cel_xxx | AA-BB-CC-DD-EE-FF/onie-installer-cel_xxx
      - 基于16进制IPv4(8个): `[ -n "$onie_disco_ip" ]`: 
        - `wf_ip=$(printf %02X%02X%02X%02X $(echo $onie_disco_ip | sed -e 's/\./ /g'))`: 192 168 10 200 -> C0A80AC8
        - `for len in seq(1 8); do wf_paths="$wf_paths $(echo $wf_ip | head -c $len)/$onie_default_filename"`
          - C0A80AC8/${filename_prefix}-${onie_platform} = C0A80AC8/onie-updater-cel_xxx | C0A80AC8/onie-installer-cel_xxx
          - C0A80AC/${filename_prefix}-${onie_platform} = C0A80AC/onie-updater-cel_xxx | C0A80AC/onie-installer-cel_xxx
          - C0A80A/${filename_prefix}-${onie_platform} = C0A80A/onie-updater-cel_xxx | C0A80A/onie-installer-cel_xxx
          - ...
          - C/${filename_prefix}-${onie_platform} = C/onie-updater-cel_xxx | C/onie-installer-cel_xxx
      - 基于服务器根目录($(get_default_filenames)=6个): 
          - `onie-updater/installer-$onie_platform`
          - `onie-updater/installer-$onie_arch-$onie_machine`=onie-updater-x86_64-$onie_platform
          - `onie-updater/installer-$onie_machine`=onie-updater-cls_xxx
          - `onie-updater/installer-${onie_arch}-$onie_switch_asic`=onie-updater-x86_64-bcm
          - `onie-updater/installer-$onie_switch_asic`=onie-updater-bcm
          - `onie-updater/installer`
   2. `tftp_servers`=$list
      - onie_server_name="onie-server"
      - onie_disco_siaddr=""  # BOOTP next-server IP
      - onie_disco_tftpsiaddr="" # TFTP server IP (DHCP opt 150)
      - onie_disco_tftp="" # DHCP TFTP server name (DHCP opt 66)  # Requires DNS
   3. `for s in $tftp_servers; do for p in $wf_paths; do`:
      1. `url_run "tftp://$s/$p" && return 0`: 尝试 TFTP URL 安装
      2. `[ "$tftp_timeout" = "yes" ] && break`: 超时则停止 TFTP waterfall
18. `exit 1`









