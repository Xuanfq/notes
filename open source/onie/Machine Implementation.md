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
    - kernel/
      - config                  # 实现内核配置项的补充或覆盖
      - serial                  # 实现自定义补丁和补丁顺序
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



## firmware/ [Option]

可以通过`machine.make`设置`FIRMWARE_UPDATE_ENABLE = yes/no`来决定是否编译固件更新包(onie-firmware-$(ARCH)-$(MACHINE_PREFIX))`firmware-update`。若无firmware实现，可设为`no`来防止通过常规命令`make MACHINEDIR=../machine/vendor/ MACHINE=xxx firmware-update`来编译固件更新包。

但无论如何，在制作固件更新包时整个firmware目录都会被打包！


### firmware/fw-install.sh [*]

实现固件(BMC/BIOS/CPLD/FPGA/SSD/...)升级逻辑。被`/installer/firmware-update/install`中函数`install_image`调用。

在`fw-install.sh`中需要时自定义`AC/DC Power cycle`逻辑时，可制作Power Cycle逻辑脚本`reboot-cmd`并将其拷贝到`/tmp/`目录下，更新完成后自动执行该脚本。

若是在`onie-updater`和`onie-firmware.bin`同时升级时(通过`onie-fwpkg add`添加`onie-updater|firmware`)。将在最后都更新完成后才执行`reboot-cmd`。需注意`reboot-cmd`时磁盘同步和数据保存(sync;sync)，取消挂载磁盘以同步文件系统元数据等。


**`install`主要执行链**：

1. 定义函数:
   1. install_image():
      1. `[ -x "./firmware/fw-install.sh" ] || { exit 1 }`
      2. `cd firmware && ./fw-install.sh "$@"`
      3. `[ $? -ne 0 ] && return 1`
      4. `return 0`
   2. parse_arg_arch():
      1. `return 0`

Refer: `installer/firmware-update/install`


**用途举例**：

- 实现固件(BMC/BIOS/CPLD/FPGA/SSD/...)升级逻辑 和 自定义升级完成后的重启方法`reboot-cmd`



### firmware/fw-version.make [*]

实现指定固件升级版本`FW_VERSION = VD-Demo-1.0.0` 和 扩展firmware编译规则。被`firmware-update.make`导入。

**`firmware-update.make`主要执行链**：

1. 准备相关变量和参数:
   1. FIRMWARE_DIR		= $(MBUILDDIR)/firmware
   2. FIRMWARE_CONF		= $(FIRMWARE_DIR)/machine-build.conf
   3. FIRMWARE_UPDATE_BASE	= onie-firmware-$(PLATFORM).bin
   4. FIRMWARE_UPDATE_IMAGE	= $(IMAGEDIR)/$(FIRMWARE_UPDATE_BASE)
   5. FIRMWARE_UPDATE_COMPLETE_STAMP	= $(STAMPDIR)/firmware-update-complete
   6. MACHINE_FW_DIR		= $(MACHINEDIR)/firmware
   7. MACHINE_FW_INSTALLER	= $(MACHINE_FW_DIR)/fw-install.sh
   8. MACHINE_FW_VERSION	= $(MACHINE_FW_DIR)/fw-version.make
2. include $(MACHINE_FW_VERSION): 导入/加载 固件版本
3. 定义固件更新包制作规则: firmware-update-complete
   ```makefile
    PHONY += firmware-update-complete
    firmware-update-complete: $(FIRMWARE_UPDATE_COMPLETE_STAMP)
    $(FIRMWARE_UPDATE_COMPLETE_STAMP): $(IMAGE_UPDATER_SHARCH) $(MACHINE_FW_INSTALLER) $(SCRIPTDIR)/onie-mk-installer.sh
      $(Q) mkdir -p $(FIRMWARE_DIR)
      $(Q) rm -f $(FIRMWARE_CONF)
      $(Q) echo "onie_version=$(FW_VERSION)" >> $(FIRMWARE_CONF)
      $(Q) echo "onie_vendor_id=$(VENDOR_ID)" >> $(FIRMWARE_CONF)
      $(Q) echo "onie_build_machine=$(ONIE_BUILD_MACHINE)" >> $(FIRMWARE_CONF)
      $(Q) echo "onie_machine_rev=$(MACHINE_REV)" >> $(FIRMWARE_CONF)
      $(Q) echo "onie_arch=$(ARCH)" >> $(FIRMWARE_CONF)
      $(Q) echo "onie_config_version=$(ONIE_CONFIG_VERSION)" >> $(FIRMWARE_CONF)
      $(Q) echo "onie_build_date=\"$$(date -Imin)\"" >> $(FIRMWARE_CONF)
      $(Q) echo "==== Create firmware update $(PLATFORM) self-extracting archive ===="
      $(Q) rm -f $(FIRMWARE_UPDATE_IMAGE)
      $(Q) $(SCRIPTDIR)/onie-mk-installer.sh firmware $(ROOTFS_ARCH) $(MACHINEDIR) \
        $(FIRMWARE_CONF) $(INSTALLER_DIR) $(FIRMWARE_UPDATE_IMAGE)
      $(Q) touch $@
    
    PHONY += firmware-update
    firmware-update: $(FIRMWARE_UPDATE_COMPLETE_STAMP)
    $(Q) echo "=== Finished making firmware update package $(FIRMWARE_UPDATE_BASE) ==="
   ```
4. 定义固件更新包清除规则: firmware-update-clean
   ```makefile
    MACHINE_CLEAN += firmware-update-clean
    firmware-update-clean:
      $(Q) rm -f $(FIRMWARE_UPDATE_COMPLETE_STAMP) $(FIRMWARE_UPDATE_IMAGE)
      $(Q) rm -rf $(FIRMWARE_DIR) $(FIRMWARE_UPDATE_IMAGE)
      $(Q) echo "=== Finished making $@ for $(PLATFORM)" 
   ```

Refer: `build-config/make/firmware-update.make`


**用途举例**：

- 指定固件升级版本`FW_VERSION = VD-Demo-1.0.0`



## installer/

### installer/install-platform [Option]

文件`install-platform`将被添加到安装/更新包里，与文件`install.sh`同级，用于添加/覆盖现有的安装脚本函数，在`install.sh`处被调用/加载。

其脚本内容将被添加到现有的安装程序功能(函数)中或覆盖现有的安装程序功能(函数)。

若其实现需要额外的其他脚本或程序，可在`machine.make`中通过`UPDATER_IMAGE_PARTS_PLATFORM += path/to/file`的方式实现。
i.e. `UPDATER_IMAGE_PARTS_PLATFORM = $(MACHINEDIR)/rootconf/sysroot-lib-onie/test-install-sharing`


**`install.sh`主要执行链**：

1. `. ./machine-build.conf`
2. `. ./update-type`
3. `[ "$update_type" = "onie" ] && . ./install-arch`
  1. `. ./installer.conf`
  2. `. ./machine-build.conf`
  3. `[ -r /etc/machine.conf ] && . /etc/machine.conf`
  4. 定义函数:
    - `parse_arg_arch`
    - ...
    - `install_image`
4. `. ./install-platform`
5. `[ -r /etc/machine.conf ] && . /etc/machine.conf`
6. `true ${onie_machine_rev=0}`
7. `true ${onie_config_version=0}`
8. `onie_build_machine=${onie_build_machine:-$onie_machine}`
9. `xz -d -c onie-update.tar.xz | tar -xf -`
10. 定义函数：`check_machine_image`, `update_syseeprom`, `set_default_passwd`
11. `[ -r ./install-platform ] && . ./install-platform` <- 可在此覆写函数实现 部分 或 全部 的安装逻辑
12. `[ $(check_machine_image) = "yes" ] && [ "$force" = "no" ] && exit 1`
13. `install_image "$@"`

Refer: `/installer/installer.sh`


**用途举例**：

- 重写函数`update_syseeprom`实现`0x29 ONIE Version`修改时`打开`或`关闭`eeprom写保护，需注意供应商对该字段的定义是否仅仅是出厂的版本（是否允许修改）
- 重写函数`set_default_passwd`配合`daemon`进程实现根据`安全启动开启状态`设置默认或无密码，需在开启安全启动模式下安装。
- 重写函数`check_machine_image`检查`image`自定义部分(i.e. UPDATER_IMAGE_PARTS_PLATFORM)是否完整



## kernel [*]

Make: `kernel.make`


**`kernel.make`主要执行链**：

1. 准备变量参数:
  - LINUX_CONFIG 		?= conf/kernel/$(LINUX_RELEASE)/linux.$(ONIE_ARCH).config
  - KERNELDIR   		= $(MBUILDDIR)/kernel
  - LINUXDIR   		= $(KERNELDIR)/linux
  - KERNEL_SRCPATCHDIR	= $(PATCHDIR)/kernel/$(LINUX_RELEASE)
  - MACHINE_KERNEL_PATCHDIR	?= $(MACHINEDIR)/kernel
  - KERNEL_PATCHDIR		= $(KERNELDIR)/patch
  - KERNEL_SOURCE_STAMP	= $(STAMPDIR)/kernel-source
  - KERNEL_PATCH_STAMP	= $(STAMPDIR)/kernel-patch
  - KERNEL_BUILD_STAMP	= $(STAMPDIR)/kernel-build
  - KERNEL_DTB_INSTALL_STAMP = $(STAMPDIR)/kernel-dtb-install
  - KERNEL_VMLINUZ_INSTALL_STAMP = $(STAMPDIR)/kernel-vmlinuz-install
  - KERNEL_INSTALL_STAMP	= $(STAMPDIR)/kernel-install
  - KERNEL_STAMP		= $(KERNEL_SOURCE_STAMP) $(KERNEL_PATCH_STAMP) $(KERNEL_BUILD_STAMP) $(KERNEL_INSTALL_STAMP)
  - KERNEL			= $(KERNEL_STAMP)
  - KERNEL_VMLINUZ		= $(IMAGEDIR)/$(MACHINE_PREFIX).vmlinuz
  - KERNEL_VMLINUZ_SIG  = $(KERNEL_VMLINUZ).sig
  - UPDATER_VMLINUZ		= $(MBUILDDIR)/onie.vmlinuz
  - UPDATER_VMLINUZ_SIG = $(UPDATER_VMLINUZ).sig
  - LINUX_BOOTDIR   = $(LINUXDIR)/arch/$(KERNEL_ARCH)/boot
2. 规则定义： `kernel: $(KERNEL_STAMP)`
   1. `kernel: $(KERNEL_STAMP)`
   2. ...ToBeContinue...


Refer: `/build-config/make/kernel.make`


### kernel/config [*]

实现`内核配置项`的`补充`或`覆盖`，被`kernel.make`引用。


**`kernel.make`主要执行链**：

见上方。

Refer: `/build-config/make/kernel.make`


**用途举例**：

- 自定义`enable`模块/功能



### kernel/serial [*]

实现`自定义补丁`和`补丁顺序`指定，被`kernel.make`引用。

一行一个补丁文件，可通过`#`在行尾添加注释，需要在最后留一行空白行！


**`kernel.make`主要执行链**：

见上方。

Refer: `/build-config/make/kernel.make`


**用途举例**：

- 自定义内核修改补丁
- 自定义补丁及其顺序



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



## installer.conf [*]

实现grub-arch架构安装脚本的`install_device_platform`函数，用于`install-arch`获取安装的目标磁盘设备。

实现grub-arch架构安装脚本的`pre_install_hook`和`post_install_hook`钩子函数，用于`install-arch`执行安装时的前置准备和后置收尾工作。


**`install-arch`主要相关执行链**：

1. `. ./installer.conf`
2. `. ./machine-build.conf`
3. `[ -r /etc/machine.conf ] && . /etc/machine.conf`
4. 定义函数:
    - `parse_arg_arch`
    - ...
    - `install_image`:
      1. `init_onie_install`
      2. `[ -n "$pre_install_hook" ] && eval $pre_install_hook || exit 1`
      3. ...
      4. `[ -n "$post_install_hook" ] && eval $post_install_hook || exit 1`
      5. `update_syseeprom`
      6. `[ "$image_secure_boot_ext" = "yes" ]  && [ "$install_firmware" = "uefi" ] && set_default_passwd`

Refer: `installer/grub-arch/install-arch`


**用途举例**：

- ONIE GRUB 升级: 通过`pre_install_hook`前置钩子函数解压`onie.initrd`文件系统，并把文件系统的执行工具链挂载(拷贝)到现成的文件系统，即使用新的updater的工具链进行安装。



## machine-security.make [Option]

配置影响安全的编译设置/变量，需在`machine.make`导入：`MACHINE_SECURITY_MAKEFILE ?= $(MACHINEDIR)/machine-security.make`


**MAKE说明**：

- 


**主要相关执行链**：

1. /

Refer: `/`


**用途举例**：

- /



## machine.make [*]

配置`MACHINE`编译设置和需求，可自行扩展编译需求(`include xxx.make`)。在`Makefile`处导入(`include`)


**MAKE说明**：

- `ONIE_ARCH ?= x86_64`
- `VENDOR_REV ?= 0`
- `MACHINE_REV = 0`
- `SWITCH_ASIC_VENDOR = bcm`
- `VENDOR_VERSION = .3.0.0`
- `VENDOR_ID = 12244`: Vendor ID -- IANA Private Enterprise Number, Ref: http://www.iana.org/assignments/enterprise-numbers
- `I2CTOOLS_ENABLE = yes`
- `I2CTOOLS_SYSEEPROM = no`
- `UEFI_ENABLE = yes`
- `IPMITOOL_ENABLE = yes`
- `FIRMWARE_UPDATE_ENABLE = yes`: 是否编译`firmware-update`
- `SKIP_ETHMGMT_MACS = yes`: 是否修改由其他程序所设置的以太网管理媒体访问控制（MAC）地址，若为no，`S30networking.sh`将自动根据`$(onie-sysinfo -e)`的MAC基地址设置所有网卡的MAC
- `SECURE_BOOT_ENABLE = no`
- `SECURE_BOOT_EXT = no`: ifeq ($(SECURE_GRUB),yes)
- `SECURE_GRUB = no`
- `MACHINE_SECURITY_MAKEFILE ?= $(MACHINEDIR)/machine-security.make`
- `CONSOLE_SPEED = 115200 `
- `CONSOLE_DEV = 0`
- `EXTRA_CMDLINE_LINUX ?= "quiet nomodeset"`
- `UPDATER_IMAGE_PARTS_PLATFORM = $(MACHINEDIR)/rootconf/sysroot-lib-onie/test-install-sharing`
- `LINUX_VERSION           = 4.9`
- `LINUX_MINOR_VERSION     = 95 `
- 


**Makefile主要相关执行链**：

1. `-include local.make`: 允许用户尽早覆盖任何使用 `?=` 定义的变量。 
2. ...
3. `include $(MACHINEDIR)/machine.make`
4. ...
5. `include $(ARCHDIR)/$(ONIE_ARCH).make`
6. ...
7. `include make/kernel-download.make`
8. ...
9. `include make/crosstool-ng.make`
10. `ifneq ($(XTOOLS_LIBC),glibc) include make/uclibc-download.make`
11. `include make/xtools.make`
12. `include make/sysroot.make`
13. `ifeq ($(GNU_EFI_ENABLE),yes) include make/gnu-efi.make`
14. `include make/kernel.make`
15. `ifeq ($(UBOOT_ENABLE),yes) include make/u-boot.make`
16. `include make/compiler.make`
17. `include make/busybox.make`
18. ...
19. `all: $(KERNEL) $(UBOOT) $(SYSROOT) $(IMAGE)`
20. ...

Refer: `build-config/Makefile`


**用途举例**：

- /




## post-process.make [Option]

允许可选择地定义镜像后处理指令。这个 Makefile 片段可以定义用于使 `$(MACHINE_IMAGE_COMPLETE_STAMP)` 保持最新状态的规则，下面的最终目标 `$(IMAGE_COMPLETE_STAMP)` 会引用该规则。 即完成最终目标`$(IMAGE_COMPLETE_STAMP)`后会执行`MACHINE_IMAGE_COMPLETE_STAMP`规则。

可用于恢复编译后的代码。


**MAKE说明**：

- 


**主要相关执行链**：

1. /

Refer: `/`


**用途举例**：

- 可用于恢复编译后的代码。


