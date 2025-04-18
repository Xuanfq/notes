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
        - network-driver-${onie_switch_asic}        # 实现：`network_driver_init`
        - network-driver-platform                   # 实现：`network_driver_platform_pre_init` 和 `network_driver_platform_post_init`
        - uninstall-platform                        # 实现：`uninstall_system`，卸载NOS(-DIAG/onie除外) Ref `/rootconf/grub-arch/sysroot-lib-onie/uninstall-arch`
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



