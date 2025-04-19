# Machine Implementation

## Content


- machine/vendor/
  - machinename
    - firmware/                 # 固件升级包，将直接被拷贝并打包成 onie-firmware-$(PLATFORM).bin -> firmware-update.make
      - bios/                   # 非必要
      - bmc/                    # 非必要
      - cpld/                   # 非必要
      - fpga/                   # 非必要
      - libs/                   # 非必要
      - tools/                  # 非必要
        - reboot-cmd                                # 更新完成后实现`AC/DC Power cycle`的脚本，需在`fw-install.sh`中需要时拷贝到`/tmp/`目录下
      - fw-install.sh                               # onie-firmware升级时执行的脚本
      - fw-version.make                             # 实现指定固件升级版本`FW_VERSION = VD-Demo-1.0.0`
    - installer/
      - install-platform                              # 实现：安全启动密码`set_default_passwd`，Ref: `installer/install.sh` & `installer/grub-arch/install-arch`
    - rootconf/                 # -> / 文件系统配置，优先级低到高(逐步覆盖): build/sysroot/ -> rootconf/$arch/ -> machinename/rootconf
      - sysroot-bin/            # -> /bin/
      - sysroot-etc/            # -> /etc/
        - passwd-secured        # -> passwd (when secure boot)
        - init-platform                             # 实现：`init_platform_pre_arch` 和 `init_platform_post_arch`
      - sysroot-init/           # -> /etc/init.d/
      - sysroot-lib-onie/       # -> /lib/onie/
        - gen-config-platform                       # 实现：`gen_live_config`, Ref `S05gen-config.sh`
        - init-platform                             # 实现：`init_platform_pre_arch` 和 `init_platform_post_arch`
        - network-driver-${onie_switch_asic}        # 实现：`network_driver_init`
        - network-driver-platform                   # 实现：`network_driver_platform_pre_init` 和 `network_driver_platform_post_init`
        - uninstall-platform                        # 覆写：`uninstall_system`，卸载NOS(默认-DIAG/onie除外) Ref `/rootconf/grub-arch/sysroot-lib-onie/uninstall-arch`
        - support-platform                          # 实现：`support_platform`，用于`onie-support`命令 Ref `/rootconf/default/bin/onie-support`
        - sysinfo-platform                          # 实现：`get_serial_num_platform`, `get_part_num_platform`, `get_ethaddr_platform`
      - sysroot-rcS/            # -> /etc/rcS.d/    # 开机时执行的daemon或脚本，如`S12open-system`
      - sysroot-rcK/            # -> /etc/rc0.d/ & /etc/rc6.d/    # 关机/重启时执行的脚本，如`K25discover.sh`
    - INSTALL                   # 非实现相关：在KVM虚拟机上安装ONIE的README
    - install.ipxe              # 非实现相关：在KVM虚拟机上安装ONIE的附件，通过ipxe安装
    - installer.conf            # 安装配置，可实现: `install_device_platform`, `pre_install_hook`, `post_install_hook`
    - machine-security.make     # 配置影响安全的编译设置/变量，需在machine.make导入：MACHINE_SECURITY_MAKEFILE ?= $(MACHINEDIR)/machine-security.make
    - machine.make              # 配置机器/平台编译
    - mk-vm.sh                  # 非实现相关：在KVM虚拟机上安装ONIE的附件，KVM虚拟机制作和启动
    - post-process.make         # 允许机器可以选择地定义镜像后处理指令。定义用于使 $(MACHINE_IMAGE_COMPLETE_STAMP) 保持最新状态的规则。Ref: `images.make`
    - README.secureboot         # 非实现相关：安全启动相关文档



## installer/

### installer/install-platform





## rootconf/

### rootconf/sysroot-lib-onie/gen-config-platform [Option]

实现`gen_live_config`，在`S05gen-config.sh`中调用。可选。

实现`machine-live.conf`填充，添加扩展的`machine.conf`项。

也可覆写`machine.conf`中来自`machine-build.conf`的某些项，如`onie_machine`, `onie_platform`


**`S05gen-config.sh`主要执行链**：

1. `local build_conf=/etc/machine-build.conf`
2. `local live_conf=/etc/machine-live.conf`
3. `local machine_conf=/etc/machine.conf`
4. `gen_live_config > $live_conf`: 默认是空
5. `cat $build_conf $live_conf > $machine_conf`
6. `sed -i -e '/onie_machine=/d' $machine_conf`
7. `sed -i -e '/onie_platform=/d' $machine_conf`
8. `. $build_conf`
9. `. $live_conf`
10. `local onie_machine=${onie_machine:-$onie_build_machine}`: 若`onie_machine`存在则直接使用，否则使用`onie_build_machine`
11. `local onie_platform=${onie_platform:-${onie_arch}-${onie_machine}-r${onie_machine_rev}}`: 若`onie_platform`存在则直接使用，否则重新设置
12. `echo "onie_machine=$onie_machine" >> $machine_conf`
13. `echo "onie_platform=$onie_platform" >> $machine_conf`

Refer: `rootconf/default/etc/rcS.d/S05gen-config.sh`


**用途举例**：

- 实现`machine-live.conf`填充，添加扩展的`machine.conf`项。
- 覆写`machine.conf`中来自`machine-build.conf`的某些项，如`onie_machine`, `onie_platform`



### rootconf/sysroot-lib-onie/init-platform [Option]

实现`init_platform_pre_arch`和`init_platform_post_arch`，在`S10init-arch.sh`中调用。可选。

开机时进行平台初始化的前后钩子函数。


**`S10init-arch.sh`主要执行链**：

1. `init_platform_pre_arch`
2. `init_arch`: 默认为u-boot才存在实质的用途，来自`/rootconf/u-boot-arch/sysroot-lib-onie/init-arch`
3. `init_platform_post_arch`

Refer: `rootconf/default/etc/rcS.d/S10init-arch.sh`


**用途举例**：

- Led点亮
- 动态波特率(stty -F /dev/ttyS0的波特率和/proc/cmdline不一致时修改grub波特率并重启)。



### rootconf/sysroot-lib-onie/network-driver-${onie_switch_asic} [Option]

实现`network_driver_init`，在`S20network-driver.sh`中调用。可选。

开机时进行ASIC/SDK/Platform特定的网络驱动初始化的函数。

执行网络 ASIC 和 SDK 的​​核心初始化​​（例如加载固件、配置寄存器、初始化数据平面等）。


**`S20network-driver.sh`主要执行链**：

1. `network_driver_platform_pre_init`
2. `network_driver_init`
3. `network_driver_platform_post_init`

Refer: `rootconf/default/etc/rcS.d/S20network-driver.sh`


**用途举例**：

- 初始化ASIC/SDK网络驱动
- 执行网络 ASIC 和 SDK 的​​核心初始化​​（例如加载固件、配置寄存器、初始化数据平面等）



### rootconf/sysroot-lib-onie/network-driver-platform [Option]

实现`network_driver_platform_pre_init`和`network_driver_platform_post_init`，在`S20network-driver.sh`中调用。可选。

开机时进行Platform特定的网络驱动初始化的前后钩子函数。

配置网络交换芯片（ASIC）的端口布局或其他硬件相关设置。


**`S20network-driver.sh`主要执行链**：

1. `network_driver_platform_pre_init`
2. `network_driver_init`
3. `network_driver_platform_post_init`

Refer: `rootconf/default/etc/rcS.d/S20network-driver.sh`


**用途举例**：

- 辅助加载和初始化ASIC网络驱动
- pre: 预初始化硬件（如复位 ASIC、加载固件）。
- pre: 配置平台特定的寄存器或 GPIO
- pre: 检查硬件状态是否就绪
- post: 校准或优化 ASIC 参数（如设置端口速率、启用缓存）
- post: 启动监控进程（如链路状态检测）
- post: 记录初始化完成状态



### rootconf/sysroot-lib-onie/uninstall-platform [Option]

覆写`uninstall_system`，卸载NOS(默认-DIAG/onie除外)，用于`onie-uninstaller`命令。


**`onie-uninstaller`主要执行链**：

1. `uninstall_system`
   - grub-arch
     1. `local blk_dev="$(onie_get_boot_disk | sed -e 's#/dev/##')"`
     2. grub清除和安装:
        - uefi:
          - `uefi_clean_up`: 
            1. 清除`/boot/efi/EFI/`下除`*/onie|*-DIAG|*/BOOT`以外的grubxxx.efi
            2. 用`efibootmgr`移除不存在的BOOT项
          - `bios_boot_onie_install`: 
            1. 重新在MBR和onie分区安装 onie grub 
            2. 设置下次启动为安装模式
     3. `erase_mass_storage $blk_dev`: 擦除并删除所有分区，但像GRUB、ONIE以及可能存在的诊断（DIAG）分区这类重要分区除外。删除的方式是对分区进行随机覆写，并删除分区。所以很慢。
2. `onie-nos-mode -c`: 设置onie环境参数(grubenv)onie_nos_mode为空


Refer: `/rootconf/grub-arch/sysroot-lib-onie/uninstall-arch`


**用途举例**：

- 同时删除DIAG NOS



### rootconf/sysroot-lib-onie/support-platform [Option]

实现函数`support_platform`，用于`onie-support`命令。

制作一个包含“感兴趣的”系统信息的压缩包。安装程序可以使用这个压缩包来收集系统信息，并将其保存下来，以记录安装情况。 

`support_platform`实现收集平台方面的信息。


**`onie-support`主要执行链**：

1. `onie_support_name="onie-support-${onie_machine}.tar.bz2"`
2. `tarfile="$output_dir/$onie_support_name"; output_dir=$1`
3. `save_dir="$tmpdir/$tar_dir"=$tmpdir/onie-support-${onie_machine}`
4. 主信息：
   1. log: `cp -a /var/log $save_dir`
   2. 内核参数: `cat /proc/cmdline > $save_dir/kernel_cmdline.txt`
   3. 环境变量: `export > $save_dir/runtime-export-env.txt`
   4. shell变量值和设置: `set > $save_dir/runtime-set-env.txt`
   5. 当前登录用户正在执行的进程情况: `ps w > $save_dir/runtime-process.txt`
   6. 内核日志: `dmesg > $save_dir/dmesg.txt`
   7. 系统eeprom信息: `[ -x /usr/bin/onie-syseeprom ] && onie-syseeprom > $save_dir/onie-syseeprom.txt`
   8. 系统信息: `onie-sysinfo -a > $save_dir/onie-sysinfo.txt`
   9. 机器配置信息: `cp /etc/machine*.conf $save_dir`
   10. 全部块设备信息: `blkid > $save_dir/blkid.txt`
   11. 全部磁盘分区信息: `fdisk -l > $save_dir/fdisk.txt`
   12. 架构相关信息(实际为空): `support_arch`
   13. 平台相关信息(可通过输出信息到$save_dir/xxx.txt实现): `support_platform`

Refer: `rootconf/default/bin/onie-support`


**用途举例**：

- 扩展`onie-support`以获取平台相关信息，可通过输出信息到`$save_dir/platform-xxx.txt`实现



### rootconf/sysroot-lib-onie/sysinfo-platform [Option]

实现`get_serial_num_platform`(SN), `get_part_num_platform`(PN)和`get_ethaddr_platform`(MAC)，用于`onie-sysinfo`命令。

自定义SN/PN/MAC获取方式和顺序。


**`onie-support`主要执行链**：

1. serial_num 获取顺序:
   1. 环境(GRUB传递内核参数)
   2. get_serial_num_platform
   3. get_serial_num_arch
   4. unknown
2. part_num 获取顺序:
   1. 环境(GRUB传递内核参数)
   2. get_part_num_platform
   3. get_part_num_arch
   4. unknown
3. part_num 获取顺序:
   1. 环境(GRUB传递内核参数)
   2. get_part_num_platform
   3. get_part_num_arch
   4. [ -r /sys/class/net/eth0/address ] && cat /sys/class/net/eth0/address
   5. unknown

Refer: `rootconf/default/bin/onie-sysinfo`


**用途举例**：

- 自定义SN/PN/MAC读取，优先级等

