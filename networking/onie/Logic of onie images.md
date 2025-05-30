# Logic of onie images

onie image 包括 onie-updater 和 onie-recovery.iso

## 制作和安装逻辑

### 更新包制作过程

#### 制作原理

1. 压缩 package 成 xz
2. 追加package包到脚本/installer/sharch_body.sh后
3. 更新包onie-updater-x86_64-xxx-r0就是脚本sharch_body.sh


#### 制作命令

images.make

```sh
onie-mk-installer.sh  \  # 调用自`images.make`, 若是`onie-firmware`则自`firmware-update.make`
	onie \  # update_type: onie | firmware
	grub-arch \  # rootfs_arch, arch_dir
	../machine/celestica/cls_xxx \  # machine_dir
	MACHINE_CONF \  # machine_conf
	../installer \  # installer_dir
	../build/images/onie-updater-x86_64-cls_xxx-r0 \  # output_file
	../build/onie-updater-x86_64-cls_xxx-r0/grubx64.efi \  # UPDATER_IMAGE_PARTS, update image parts, which will be packed into onie-update.tar.xz
	../machine/celestica/cls_xxx/rootconf/sysroot-lib-onie/test-install-sharing  # UPDATER_IMAGE_PARTS_PLATFORM, update image parts platform, which will be packed into onie-update.tar.xz

MBUILDDIR=../build/cls_xxx-r0

installer_conf=$machine_dir/installer.conf

update_label="ONIE"  # ONIE | Firmware

UPDATER_IMAGE_PARTS=$(UPDATER_VMLINUZ) $(UPDATER_INITRD) $(UPDATER_ONIE_TOOLS) \
			$(ROOTCONFDIR)/grub-arch/sysroot-lib-onie/onie-blkdev-common \
			$(ROOTCONFDIR)/grub-arch/sysroot-lib-onie/nos-mode-arch \
      # $(UPDATER_VMLINUZ).sig $(UPDATER_INITRD).sig
      # $(GRUB_SECURE_BOOT_IMAGE)  # grubx64.efi  from grub.make
      # $(SHIM_BINS)  # shimx64.efi fbx64.efi mmx64.efi from shim.make
      # $(GRUB_SECURE_BOOT_IMAGE).sig

GRUB_TIMEOUT ?= 5
```


#### 文件内容

```sh
installer/
  *onie-update.tar.xz         # update image parts, params of onie-mk-installer.sh, `UPDATER_IMAGE_PARTS` 和 `UPDATER_IMAGE_PARTS_PLATFORM`都会被压缩到这里
      onie-tools.tar.xz           # UPDATER_IMAGE_PARTS, UPDATER_ONIE_TOOLS
      onie.initrd                 # UPDATER_IMAGE_PARTS
      onie.vmlinuz                # UPDATER_IMAGE_PARTS
      onie-blkdev-common          # UPDATER_IMAGE_PARTS, $(ROOTCONFDIR)/grub-arch/sysroot-lib-onie/onie-blkdev-common
      nos-mode-arch               # UPDATER_IMAGE_PARTS, $(ROOTCONFDIR)/grub-arch/sysroot-lib-onie/nos-mode-arch
  *update-type                # create with content: [update_type=onie\r\nupdate_label=ONIE\r\n]
  *grub/                      # from ../installer/grub-arch/*   # if arm, does not exist this
    ...
    *grub-common.cfg          # from ../installer/grub-arch/*   # if arm, does not exist this
    *grub-variables           # create with content: [## Begin grub-variables......serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1...]
    *grub-machine.cfg         # create 
    *grub-extra.cfg           # create 
  *grub.d/                    # from ../installer/grub-arch/*   # if arm, does not exist this
    *50_onie_grub             # from ../installer/grub-arch/*   # if arm, does not exist this
   #  51_onie_grub_secure_boot  # option, from ../installer/grub-arch/*   # if arm or not secure boot, does not exist this
  *install-arch               # from ../installer/grub-arch/*   # or arm from ../installer/u-boot-arch/*
  *install.sh                 # from ../installer/install.sh
  *installer.conf             # from $machine_dir/installer.conf  # only onie update-type and grub-arch
  *machine-build.conf         # create in images.make with $(MBUILDDIR)/machine-build.conf, or in firmware-update.make with $(MBUILDDIR)/firmware/machine-build.conf
  install-platform            # option, from machine directory: $machine_dir/installer/install-platform
```


#### 制作过程

onie-mk-installer.sh

1. 传入参数准备
   - `update_type`=onie | firmware
   - `rootfs_arch`=`arch_dir`=grub-arch | u-boot-arch
   - `machine_dir`=../machine/xxx/cls_xxx
   - `machine_conf`=MACHINE_CONF | FIRMWARE_CONF, FIRMWARE_CONF用的onie_version是fw_version且比MACHINE_CONF少很多项。
     - create in images.make with $(MBUILDDIR)/machine-build.conf
     - create in firmware-update.make with $(MBUILDDIR)/firmware/machine-build.conf
   - `installer_dir`=../installer
   - `output_file`=$(IMAGEDIR)/onie-updater-$(ARCH)-$(MACHINE_PREFIX) | $(IMAGEDIR)/$(FIRMWARE_UPDATE_BASE)
     - IMAGEDIR=../build/images/
   - `$*`: 其他需要打包的文件, 传入`include_files`
     - 若update_type=onie: include_files=$*, $*实质由 UPDATER_IMAGE_PARTS 和 UPDATER_IMAGE_PARTS_PLATFORM 组成
       - UPDATER_IMAGE_PARTS: 由编译指定, 如x86:
         - UPDATER_VMLINUZ: $(MBUILDDIR)/onie.vmlinuz (from x86_64.make)
         - UPDATER_INITRD: $(MBUILDDIR)/onie.initrd (from x86_64.make)
         - UPDATER_ONIE_TOOLS:  (from x86_64.make)
         - $(ROOTCONFDIR)/grub-arch/sysroot-lib-onie/onie-blkdev-common (from x86_64.make)
         - $(ROOTCONFDIR)/grub-arch/sysroot-lib-onie/nos-mode-arch (from x86_64.make)
         - (option, secure boot) GRUB_SECURE_BOOT_IMAGE: $(MBUILDDIR)/grub$(EFI_ARCH).efi (from grub.make)
         - (option, secure boot) $(SHIM_BINS): shimx64.efi fbx64.efi mmx64.efi (from shim.make)
       - UPDATER_IMAGE_PARTS_PLATFORM: 由平台/机器按需扩展
         - i.e. ../machine/xxx/cls_xxx/rootconf/sysroot-lib-onie/test-install-sharing
     - 若update_type=firmware: include_files=${machine_dir}/firmware
2. 其他参数准备
   - `installer_conf`(当grub-arch时需要)=${machine_dir}/installer.conf
   - `update_label`=ONIE | Firmware
3. 创建临时安装目录: `tmp_dir=$(mktemp --directory)`, `tmp_installdir=$tmp_dir/installer/`
4. `onie-update.tar.xz`: 遍历`include_files`文件归档到`$tmp_installdir/onie-update.tar.xz`, (解压后出现在installer下)
5. `update-type`: 创建该文件并写入`update_type="$update_type"\nupdate_label="$update_label"`, update_label=ONIE or update_label=Firmware
6. `install.sh`: 拷贝安装器通用安装脚本, `cp $installer_dir/install.sh $tmp_installdir`即`cp ../installer/install.sh $tmp_installdir`
7. `install-arch`(`grub/`,`grub.d/`): 拷贝安装器特定架构脚本和配置, `cp -r $installer_dir/$arch_dir/* $tmp_installdir`
   - 若arch_dir=u-boot-arch: `sed -e "s/%%UPDATER_UBOOT_NAME%%/$UPDATER_UBOOT_NAME/" -i $tmp_installdir/install-arch`, UPDATER_UBOOT_NAME=u-boot.bin|u-boot.pbl
   - 若rootfs_arch=grub-arch且update_type=onie时, 修改Grub配置文件:
     - grub/grub-common.cfg: `sed -i -e "s/%%GRUB_TIMEOUT%%/$GRUB_TIMEOUT/" $tmp_installdir/grub/grub-common.cfg`
     - grub/grub-variables: create
     - grub/grub-machine.cfg: create
     - grub/grub-extra.cfg: create
     - grub.d/50_onie_grub: `sed -i -e "s/%%UEFI_BOOT_LOADER%%/$UEFI_BOOT_LOADER/" $tmp_installdir/grub.d/50_onie_grub`
     - 若是安全GRUB, gpg签名: 
       - 运行`$tmp_installdir/grub.d/51_onie_grub_secure_boot`
       - 签名grub_sb.cfg: `$SCRIPT_DIR/gpg-sign.sh $GPG_SIGN_SECRING $tmp_installdir/grub_sb.cfg`
       - 签名grub.cfg: `$SCRIPT_DIR/gpg-sign.sh $GPG_SIGN_SECRING $tmp_installdir/grub.cfg`
8. `install-platform`(若$update_type=onie且文件存在): 拷贝平台特定安装器函数以覆盖/新增某些函数, `cp $machine_dir/installer/install-platform $tmp_installdir`, 覆盖位置处于库加载完后的执行安装前
9. `machine-build.conf`: 将machine-build.conf中的onie_字眼替换成image_, `sed -e 's/onie_/image_/' $machine_conf > $tmp_installdir/machine-build.conf`
10. `installer.conf`(若rootfs_arch=grub-arch且update_type=onie时): 拷贝平台机器特定安装器配置文件, `cp "$installer_conf" $tmp_installdir`, 目的:
     - 获取安装磁盘设备(必须): install_device_platform
     - 前置安装钩子函数: pre_install_hook
     - 后置安装钩子函数: post_install_hook
11. 若update_type=firmware, 更新文件:
    1. `update-type`: 添加firmware安装器安装函数`install_image`和`parse_arg_arch`到update-type, `cat $installer_dir/firmware-update/install >> $tmp_installdir/update-type`
    2. `installer.conf`: 创建必要的installer.conf防止缺少该文件(实际上不影响), `touch $tmp_installdir/installer.conf`, 不影响已经存在installer.conf
12. 打包成可运行的安装脚本, 即image(onie-updater|firmware-xx):
    1. 将`$tmp_installer`的父级`$tmp_dir`压缩成sharch.tar包(保留installer目录): `sharch="$tmp_dir/sharch.tar"; tar -C $tmp_dir -cf $sharch installer`
    2. 准备安装脚本(onie-updater|firmware-xx): `cp $installer_dir/sharch_body.sh $output_file`
    3. 计算sharch.tar的sha1sum值, 并填充到安装脚本作为变量值:
       1. `sha1=$(cat $sharch | sha1sum | awk '{print $1}')`
       2. `sed -i -e "s/%%IMAGE_SHA1%%/$sha1/" $output_file`
    4. 将sharch.tar包追加到安装脚本最后, 安装时再将其解压处理: `cat $sharch >> $output_file`


Notice:
- onieroot/installer/charch_body.sh:
  - ONIE-UPDATER-COOKIE的存在意味着是ONIE Update Installer，否则是NOS!
  - %%VAR%% 形式的字符串在构造过程中被替换，即使用该文件是应替换%%VAR%%成对应的值！如%%IMAGE_SHA1%%



### ISO制作过程

#### 制作原理



#### 制作命令

images.make

```sh
CONSOLE_SPEED=$(CONSOLE_SPEED) \                               # 
CONSOLE_DEV=$(CONSOLE_DEV) \                                   # 
CONSOLE_PORT=$(CONSOLE_PORT) \                                 # 
GRUB_DEFAULT_ENTRY=$(GRUB_DEFAULT_ENTRY) \                     # 
UEFI_ENABLE=$(UEFI_ENABLE) \                                   # 
EXTRA_CMDLINE_LINUX="$(EXTRA_CMDLINE_LINUX)" \                 # 
SERIAL_CONSOLE_ENABLE=$(SERIAL_CONSOLE_ENABLE) \               # 
SECURE_BOOT_ENABLE=$(SECURE_BOOT_ENABLE) \                     # 
SB_SHIM=$(SHIM_SECURE_BOOT_IMAGE) \                            # 
ONIE_VENDOR_SECRET_KEY_PEM=$(ONIE_VENDOR_SECRET_KEY_PEM) \     # 
ONIE_VENDOR_CERT_PEM=$(ONIE_VENDOR_CERT_PEM) \                 # 
onie-mk-iso.sh \ 
      $(ARCH) \                        # x86_64
      $(UPDATER_VMLINUZ) \             # $(MBUILDDIR)/onie.vmlinuz
		$(RECOVERY_INITRD) \             # $(MBUILDDIR)/recovery/$(ARCH)-$(MACHINE_PREFIX).initrd
      $(RECOVERY_DIR) \                # $(MBUILDDIR)/recovery
		$(MACHINE_CONF) \                # $(MBUILDDIR)/machine-build.conf
      $(RECOVERY_CONF_DIR) \           # $(PROJECTDIR)/build-config/recovery = build-config/recovery
		$(GRUB_TARGET_LIB_I386_DIR) \    # $(BUILDDIR)/user/$(XTOOLS_VERSION)/grub/install/grub-i386-pc/usr/lib/grub/i386-pc
      $(GRUB_HOST_BIN_I386_DIR) \      # $(BUILDDIR)/user/$(XTOOLS_VERSION)/grub-host/i386-pc-install/usr/bin
		$(GRUB_TARGET_LIB_UEFI_DIR) \    # $(BUILDDIR)/user/$(XTOOLS_VERSION)/grub/install/grub-$(ARCH)-efi/usr/lib/grub/$(ARCH)-efi
      $(GRUB_HOST_BIN_UEFI_DIR) \      # $(BUILDDIR)/user/$(XTOOLS_VERSION)/grub-host/x86_64-efi-install/usr/bin
		$(FIRMWARE_TYPE) \               # auto | uefi | bios | coreboot, [ $UEFI_ENABLE = "yes" ] && FIRMWARE_TYPE ?= auto, else FIRMWARE_TYPE ?= bios
      $(RECOVERY_ISO_IMAGE)            # $(IMAGEDIR)/onie-recovery-$(ARCH)-$(MACHINE_PREFIX).iso
```


#### 文件内容

- boot/
  - grub/
    - i386-pc/
      - *mod
      - *lst
    - grub.cfg
  - efi.img             # UEFI
  - eltorito.img
- initrd.xz
  - ...
  - lib/
    - ...
    - onie
      - ...
      - onie-updater    # -> $(IMAGEDIR)/onie-updater-$(ARCH)-$(MACHINE_PREFIX)
- vmlinuz


#### 制作过程

onie-mk-iso.sh

1. 传入参数准备
   1. `ARCH`=x86_64
   2. `RECOVERY_KERNEL`=            $(MBUILDDIR)/onie.vmlinuz
   3. `RECOVERY_INITRD`=            $(MBUILDDIR)/recovery/$(ARCH)-$(MACHINE_PREFIX).initrd
   4. `RECOVERY_DIR`=               $(MBUILDDIR)/recovery
   5. `MACHINE_CONF`=               $(MBUILDDIR)/machine-build.conf
   6. `RECOVERY_CONF_DIR`=          $(PROJECTDIR)/build-config/recovery
   7. `GRUB_TARGET_LIB_I386_DIR`=   $(BUILDDIR)/user/$(XTOOLS_VERSION)/grub/install/grub-i386-pc/usr/lib/grub/i386-pc
   8. `GRUB_HOST_BIN_I386_DIR`=     $(BUILDDIR)/user/$(XTOOLS_VERSION)/grub-host/i386-pc-install/usr/bin
   9. `GRUB_TARGET_LIB_UEFI_DIR`=   $(BUILDDIR)/user/$(XTOOLS_VERSION)/grub/install/grub-$(ARCH)-efi/usr/lib/grub/$(ARCH)-efi
   10. `GRUB_HOST_BIN_UEFI_DIR`=    $(BUILDDIR)/user/$(XTOOLS_VERSION)/grub-host/x86_64-efi-install/usr/bin
   11. `FIRMWARE_TYPE`=             auto | bios
   12. `RECOVERY_ISO_IMAGE`=        $(IMAGEDIR)/onie-recovery-$(ARCH)-$(MACHINE_PREFIX).iso
2. 校验参数和环境变量
3. 确保制作使用的工具链可用:
   1. `XORRISO`=`$(which xorriso)`
   2. `MKDOSFS`=`[ -e /sbin/mkdosfs ] && MKDOSFS="/sbin/mkdosfs" || MKDOSFS=$(which mkdosfs); echo -n $MKDOSFS`
   3. `MCOPY`=`$(which mcopy)`
4. 其他变量和文件存放位置准备:
   - `EFI_INFIX`=aa64 | x64
   - `RECOVERY_ISO_SYSROOT`="$RECOVERY_DIR/iso-sysroot"=                            $(MBUILDDIR)/recovery/iso-sysroot
   - `RECOVERY_CORE_IMG`="$RECOVERY_DIR/core.img"=                                  $(MBUILDDIR)/recovery/core.img
   - `RECOVERY_EFI_DIR`="$RECOVERY_DIR/EFI"=                                        $(MBUILDDIR)/recovery/EFI
   - `RECOVERY_EFI_BOOT_DIR`="$RECOVERY_EFI_DIR/BOOT"       =                       $(MBUILDDIR)/recovery/EFI/BOOT
   - `RECOVERY_EFI_BOOTX86_IMG`="$RECOVERY_EFI_BOOT_DIR/boot${EFI_INFIX}.efi"=      $(MBUILDDIR)/recovery/EFI/BOOT/boot${EFI_INFIX}.efi
   - `RECOVERY_GRUBX86_IMG`="$RECOVERY_DIR/grub${EFI_INFIX}.efi"=                   $(MBUILDDIR)/recovery/grub${EFI_INFIX}.efi
   - `RECOVERY_EFI_GRUBX86_IMG`="$RECOVERY_EFI_BOOT_DIR/grub${EFI_INFIX}.efi"=      $(MBUILDDIR)/recovery/EFI/BOOT/grub${EFI_INFIX}.efi
   - `RECOVERY_ELTORITO_IMG`="$RECOVERY_ISO_SYSROOT/boot/eltorito.img"=             $(MBUILDDIR)/recovery/iso-sysroot/boot/eltorito.img
   - `RECOVERY_EMBEDDED_IMG`="$RECOVERY_DIR/embedded.img" =                         $(MBUILDDIR)/recovery/embedded.img
   - `RECOVERY_UEFI_IMG`="$RECOVERY_ISO_SYSROOT/boot/efi.img"=                      $(MBUILDDIR)/recovery/iso-sysroot/boot/efi.img
   - `RECOVERY_XORRISO_OPTIONS`="$RECOVERY_DIR/xorriso-options.cfg"=                $(MBUILDDIR)/recovery/xorriso-options.cfg
5. 清除构建并恢复到为构建ISO之前的状态:
   1. `rm -rf $RECOVERY_ISO_SYSROOT $RECOVERY_ISO_IMAGE`: 删除目录`$(MBUILDDIR)/recovery/iso-sysroot`和`ISO`
   2. `mkdir -p $RECOVERY_ISO_SYSROOT`: 创建目录`$(MBUILDDIR)/recovery/iso-sysroot`
6. 添加内核和文件系统到ISO文件系统目录:
   1. `cp $RECOVERY_KERNEL $RECOVERY_ISO_SYSROOT/vmlinuz`
   2. `cp $RECOVERY_INITRD $RECOVERY_ISO_SYSROOT/initrd.xz`
7. 配置GRUB:
   1. `EXTRA_CMDLINE_LINUX=$(echo $EXTRA_CMDLINE_LINUX | sed -e 's/[\/&]/\\\&/g')`: 处理内核参数的扩展参数的转义字符
   2. `mkdir -p $RECOVERY_ISO_SYSROOT/boot/grub`: 创建GRUB存放目录
   3. 创建GRUB配置文件`grub.cfg`:
      ```sh
      sed -e "s/<CONSOLE_SPEED>/$CONSOLE_SPEED/g"           \
      -e "s/<CONSOLE_DEV>/$CONSOLE_DEV/g"               \
      -e "s/<GRUB_DEFAULT_ENTRY>/$GRUB_DEFAULT_ENTRY/g" \
      -e "s/<CONSOLE_PORT>/$CONSOLE_PORT/g"             \
      -e "s/<EXTRA_CMDLINE_LINUX>/$EXTRA_CMDLINE_LINUX/" \
      -e "s/<SERIAL_CONSOLE_ENABLE>/$SERIAL_CONSOLE_ENABLE/g" \
      "$MACHINE_CONF" $RECOVERY_CONF_DIR/grub-iso.cfg   \
      > $RECOVERY_ISO_SYSROOT/boot/grub/grub.cfg
      ```
   4. 非 UEFI 下 (传统/Legacy BIOS) (`[ "$FIRMWARE_TYPE" != "uefi" ]`):
      1. 用 i386-pc 架构的 GRUB 模块填充 .ISO 系统根目录 (`$RECOVERY_ISO_SYSROOT`):
         1. `mkdir -p $RECOVERY_ISO_SYSROOT/boot/grub/i386-pc`
         2. `(cd $GRUB_TARGET_LIB_I386_DIR && cp *mod *lst $RECOVERY_ISO_SYSROOT/boot/grub/i386-pc)`
      2. 生成传统 BIOS 的 eltorito 格式的 GRUB 镜像:
         ```sh
         $GRUB_HOST_BIN_I386_DIR/grub-mkimage \
         --format=i386-pc \
         --directory=$GRUB_TARGET_LIB_I386_DIR \
         --prefix=/boot/grub \
         --output=$RECOVERY_CORE_IMG \
         part_msdos part_gpt iso9660 biosdisk
         cat $GRUB_TARGET_LIB_I386_DIR/cdboot.img $RECOVERY_CORE_IMG > $RECOVERY_ELTORITO_IMG  # 合并 cdboot.img 和 core.img 成 $RECOVERY_ISO_SYSROOT/boot/eltorito.img
         ```
      3. 生成传统 BIOS 的主引导记录（MBR）格式的 GRUB 镜像: 
         1. `cat $GRUB_TARGET_LIB_I386_DIR/boot.img $RECOVERY_CORE_IMG > $RECOVERY_EMBEDDED_IMG`: 合并 boot.img 和 core.img 成 $RECOVERY_ISO_SYSROOT/../embedded.img
   5. 适配 UEFI (`[ "$UEFI_ENABLE" = "yes" ]`):
      1. 准备好要构建到 GRUB 镜像中的模块列表: `GRUB_MODULES`=...
      2. 生成 UEFI 格式的 GRUB image:
         ```sh
         mkdir -p $RECOVERY_EFI_BOOT_DIR                    # $RECOVERY_ISO_SYSROOT/../EFI/BOOT
         $GRUB_HOST_BIN_UEFI_DIR/grub-mkimage \ 
            --format=${ARCH}-efi \ 
            --directory=$GRUB_TARGET_LIB_UEFI_DIR \         # $(BUILDDIR)/user/$(XTOOLS_VERSION)/grub/install/grub-$(ARCH)-efi/usr/lib/grub/$(ARCH)-efi
            --prefix=/boot/grub \ 
            --config=$RECOVERY_CONF_DIR/grub-uefi.cfg \     # $(PROJECTDIR)/build-config/recovery/grub-uefi.cfg
            --output=$RECOVERY_GRUBX86_IMG \                # $RECOVERY_ISO_SYSROOT/../grub${EFI_INFIX}.efi
            $GRUB_MODULES
         ```
      3. 将 UEFI 引导加载程序镜像复制到 ESP 临时目录 RECOVERY_EFI_BOOT_DIR 中 ($RECOVERY_ISO_SYSROOT/../EFI/BOOT/):
         1. `if [ "$SECURE_BOOT_ENABLE" = "yes" ]`:
            1. sign: `sbsign --key $ONIE_VENDOR_SECRET_KEY_PEM --cert $ONIE_VENDOR_CERT_PEM  --output $RECOVERY_EFI_GRUBX86_IMG $RECOVERY_GRUBX86_IMG`  # -> $RECOVERY_ISO_SYSROOT/../EFI/BOOT/grub${EFI_INFIX}.efi
            2. 将 shim 复制到指定位置作为加载程序: `cp $SB_SHIM $RECOVERY_EFI_BOOTX86_IMG`  # SB_SHIM=shim{EFI_ARCH}$EFI-> $RECOVERY_ISO_SYSROOT/../EFI/BOOT/boot${EFI_INFIX}.efi
         2. `else`直接移动: `mv $RECOVERY_GRUBX86_IMG $RECOVERY_EFI_BOOTX86_IMG`  # -> $RECOVERY_ISO_SYSROOT/../EFI/BOOT/boot${EFI_INFIX}.efi
      4. 创建ESP(EFI system partition)分区镜像，并将 ESP 临时目录的内容复制到其中 (对于 UEFI，GRUB 引导加载程序镜像被嵌入到 UEFI ESP （ESP，采用 fat16 格式 ）磁盘分区镜像中):
         1. 计算EFI引导目录大小​​: `EFI_BOOT_SIZE_BYTES=$(du --bytes $RECOVERY_EFI_BOOT_DIR | awk '{ print $1 }')`
         2. 计算映像所需的扇区数: `BOOTX86_IMG_SECTORS=$(( ( ( $EFI_BOOT_SIZE_BYTES / 512 ) + 31 ) / 32 ))`，扇区数加上31后除以32，确保mcopy（后续命令）所需的32扇区对齐（向上取整）
         3. 加上文件系统开销的扇区: `BOOTX86_IMG_SECTORS=$(( ( $BOOTX86_IMG_SECTORS + 2 ) * 32 ))`，增加2个32扇区的块（共64扇区）以容纳FAT文件系统开销（如FAT表、根目录等）
         4. 创建空白映像文件: `dd if=/dev/zero of=$RECOVERY_UEFI_IMG bs=512 count=$BOOTX86_IMG_SECTORS`
         5. 格式化为FAT文件系统: `$MKDOSFS $RECOVERY_UEFI_IMG`
         6. 复制EFI引导文件到映像​: `$MCOPY -s -i $RECOVERY_UEFI_IMG $RECOVERY_EFI_DIR '::/'`:
            - 使用mcopy（来自mtools）将 $RECOVERY_EFI_DIR 下的文件递归（-s）复制到映像的根目录（::/）
            - -i: 指定目标映像文件
      5. RECOVERY_UEFI_IMG -> $RECOVERY_ISO_SYSROOT/boot/efi.img
8. 将传统 BIOS 和 UEFI 的 GRUB 镜像合并到一个 ISO 文件中:
   1. xorriso打包ISO的引导配置，告诉 xorriso 如何设置 ISO 的引导逻辑 ($RECOVERY_ISO_SYSROOT/../xorriso-options.cfg):
      - $FIRMWARE_TYPE=uefi: `cp ${RECOVERY_CONF_DIR}/xorriso-options-uefi.cfg ${RECOVERY_XORRISO_OPTIONS}`
      - $FIRMWARE_TYPE=auto: 合并`xorriso-options-uefi.cfg`和`xorriso-options-bios.cfg`
         ```sh
         rm -f ${RECOVERY_XORRISO_OPTIONS} && touch ${RECOVERY_XORRISO_OPTIONS}
         git merge-file -p --union ${RECOVERY_CONF_DIR}/xorriso-options-bios.cfg \
                  ${RECOVERY_XORRISO_OPTIONS} \
                  ${RECOVERY_CONF_DIR}/xorriso-options-uefi.cfg \
                  > ${RECOVERY_XORRISO_OPTIONS}
         ```
      - $FIRMWARE_TYPE=其他: `cp ${RECOVERY_CONF_DIR}/xorriso-options-bios.cfg ${RECOVERY_XORRISO_OPTIONS}`
9. 制作镜像:
   ```sh
   cd $RECOVERY_DIR && $XORRISO -outdev $RECOVERY_ISO_IMAGE \  # 目标：$(IMAGEDIR)/onie-recovery-$(ARCH)-$(MACHINE_PREFIX).iso
   -map $RECOVERY_ISO_SYSROOT / \                              # 将 $RECOVERY_ISO_SYSROOT 的内容复制到 ISO 的根目录
   -options_from_file $RECOVERY_XORRISO_OPTIONS                # 告诉 xorriso 如何设置 ISO 的引导逻辑
   ```
10. 兼容 UEFI : 向 ISO 镜像中添加一个 MS-DOS 分区表，其中包含一条针对 EFI 镜像的分区表项，这样它看起来就像一个磁盘镜像。
    1.  为了为 efi.img（ESP）分区创建 MS-DOS 分区表项，我们需要确定光盘中 /boot/efi.img 的 iso9660 扇区（每个扇区 2048 字节），并将其转换为硬盘扇区（每个扇区 512 字节）
        1.  计算 ISO 中的 `$RECOVERY_UEFI_IMG` 的 offset 和 size
            ```sh
            # start
            # The output of the xorriso find command looks like:
            # Report layout: xt , Startlba ,   Blocks , Filesize , ISO image path
            # File data lba:  0 ,      132 ,       80 ,   163840 , '/boot/efi.img'
            EFI_IMG_START_BLOCK=$($XORRISO -indev $RECOVERY_ISO_IMAGE \
               -find /boot/efi.img -name efi.img -exec report_lba -- 2> /dev/null | \
               grep efi.img | awk '{ print $6 }')
            EFI_IMG_START_SECTOR=$(( $EFI_IMG_START_BLOCK * 2048 / 512 ))

            # Determine image size in sectors
            EFI_IMG_SIZE_BYTES=$(stat -c '%s' $RECOVERY_UEFI_IMG)
            EFI_IMG_SIZE_SECTORS=$(( $EFI_IMG_SIZE_BYTES / 512 ))
            ```
    2.  然后我们创建一个类型为 “0xEF” 的可引导 MS-DOS 分区，UEFI 固件会将其识别为一个 UEFI 可引导镜像
        ```sh
        $(dirname $0)/mk-part-table.py $RECOVERY_ISO_IMAGE $EFI_IMG_START_SECTOR $EFI_IMG_SIZE_SECTORS
        ```





### onie-tools.tar.xz制作

`onie-tools.tar.gz`包是静态的

```sh
onie-mk-tools.sh \  # 调用自`images.make`
   $(ROOTFS_ARCH) \  # rootfs_arch = u-boot-arch | grub-arch
   $(ONIE_TOOLS_DIR) \  # tools_dir = onieroot/tools/, 主文件grub-arch/bin/onie-version
   $@ \  # output_file
   $(SYSROOTDIR) \  # sysroot = $(MBUILDDIR)/sysroot = ../build/onie-updater-x86_64-cls_xxx-r0/sysroot/
   $(ONIE_SYSROOT_TOOLS_LIST)  # $*, sysroot目录下的文件和目录，来源onieroot/rootconf/grub-arch/下的, -替换成/

ONIE_SYSROOT_TOOLS_LIST = \
	lib/onie \
	bin/onie-boot-mode \
	bin/onie-nos-mode \
	bin/onie-fwpkg
```

**onie-mk-tools.sh**工具文件内容来源于两个位置：
- CPU架构无关的工具来自ONIE安装程序镜像的目录(ONIE_SYSROOT_TOOLS_LIST): sysroot(SYSROOTDIR), /rootconf/$rootfs_arch/* + /machine/rootconf/*
  - `/rootconf/$rootfs_arch/sysroot-lib-onie`
  - `/machine/$vendor/$machine/rootconf/sysroot-lib-onie`
  - `/rootconf/$rootfs_arch/sysroot-bin/onie-boot-mode` or overwrite with `/machine/$vendor/$machine/rootconf/sysroot-bin/onie-boot-mode`
  - `/rootconf/$rootfs_arch/sysroot-bin/onie-nos-mode` or overwrite with `/machine/$vendor/$machine/rootconf/sysroot-bin/onie-nos-mode`
  - `/rootconf/$rootfs_arch/sysroot-bin/onie-fwpkg` or overwrite with `/machine/$vendor/$machine/rootconf/sysroot-bin/onie-fwpkg`
- CPU架构相关的工具来自ONIE仓库中特定架构的目录(ONIE_TOOLS_DIR): tools_dir(ONIE_TOOLS_DIR), /tools/$rootfs_arch/*
  - `/tools/grub-arch/bin/onie-version`

主要制作过程：
- cpu无关,sysroot: 
   ```sh
   for f in $* ; do
      tdir="${tmp_dir}/$(dirname $f)"
      mkdir -p $tdir || exit 1
      cp -a "${sysroot}/$f" $tdir || exit 1
      echo -n "."
   done
   ```
- cpu有关,tools_dir: `cp -a "${tools_dir}/${arch_dir}"/* $tmp_dir`

制作结果：tools.tar.xz解压后
```
tools/
   lib/
      onie/
         ...
   bin/
      ...
```

实质上`onie-tools.tar.gz`包是静态的！！！


### sysroot/rootfs文件系统制作

交叉编译：xtools.make

- ONIE_ARCH = x86_64
- XTOOLS_CONFIG ?= conf/crosstool/gcc-$(GCC_VERSION)/$(XTOOLS_LIBC)-$(XTOOLS_LIBC_VERSION)/crosstool.$(ONIE_ARCH).config
- XTOOLS_ROOT = build/x-tools
- XTOOLS_VERSION = $(ONIE_ARCH)-g$(GCC_VERSION)-lnx$(LINUX_RELEASE)-$(XTOOLS_LIBC)-$(XTOOLS_LIBC_VERSION)
- XTOOLS_DIR = $(XTOOLS_ROOT)/$(XTOOLS_VERSION)
- XTOOLS_BUILD_DIR	= $(XTOOLS_DIR)/build
- XTOOLS_INSTALL_DIR	= $(XTOOLS_DIR)/install
- ARCH ?= x86_64
- TARGET ?= $(ARCH)-onie-linux-uclibc
- CROSSPREFIX ?= $(TARGET)-
- CROSSBIN ?= $(XTOOLS_INSTALL_DIR)/$(TARGET)/bin
- EFI_ARCH ?= x64


制作过程: images.make

1. 软件包准备与安装(即需要安装到机器上的软件), 需要安装到SYSROOTDIR目录的文件系统上: (SYSROOTDIR = $(MBUILDDIR)/sysroot = ../build/onie-updater-x86_64-cls_xxx-r0/sysroot/): 
   - 安装过程参照: `build-config/make/*.make`, 可能在`DEV_SYSROOT`上build, 然后拷贝到`SYSROOTDIR`
2. sysroot-check:
   1. 准备C标准库依赖库`uClibc/uClibc-ng/glibc` (前两种是嵌入式Linux系统设计的轻量级的库), 拷贝到`$(SYSROOTDIR)/lib/`:
      1. 获取配置的库: `ifeq ($(XTOOLS_LIBC),uClibc-ng?|uClibc?|glibc?) SYSROOT_LIBS=xxx.so.1 ...?`
      2. 添加GCC共享库: `ifeq ($(REQUIRE_CXX_LIBS),yes) ifeq ($(GCC_VERSION),6.3.0) SYSROOT_LIBS += libstdc++.so.6.0.22 ...?`
      3. 查找是否缺少共享库: `for file in $(SYSROOT_LIBS) find $(DEV_SYSROOT)/lib -name $$file | xargs -i cp -av {} $(SYSROOTDIR)/lib/ || exit 1 ;` 
         - DEV_SYSROOT=build/user/$(XTOOLS_VERSION)/dev-sysroot/
   2. 去除 ELF 二进制文件（GRUB 模块和内核）中的无关信息
      1. `find $(SYSROOTDIR) -path */lib/grub/* -prune -o \( -type f -print0 \) | xargs -0 file | grep ELF | awk -F':' '{ print $$1 }' | grep -v "/lib/modules/" | xargs $(CROSSBIN)/$(CROSSPREFIX)strip`: 目的是在 sysroot 目录中查找所有 ELF 文件（除了在 /lib/grub 和 /lib/modules 目录下的），然后对这些文件执行 strip 操作。strip 操作会移除调试符号和其他非必要信息，减小文件大小。这通常用于优化最终的系统镜像大小。
         - $(CROSSBIN)/$(CROSSPREFIX)strip=build/x-tools/$XTOOLS_VERSION/install/x86_64-onie-linux-uclibc-strip
   3. 验证在我们最终的系统根目录（sysroot）中，可执行文件所需的所有共享库是否都已具备:
      1. `$(SCRIPTDIR)/check-libs $(CROSSBIN)/$(CROSSPREFIX)populate $(DEV_SYSROOT) $(SYSROOTDIR) $(CHECKROOT)`
         - check-libs检查$(DEV_SYSROOT) $(SYSROOTDIR)是否有不一样
3. 拷贝CPU无关的程序或脚本`onieroot/rootconf/default/*`到`SYSROOTDIR`(SYSROOTDIR = $(MBUILDDIR)/sysroot = ../build/onie-updater-x86_64-cls_xxx-r0/sysroot/): 
   - `cd $(ROOTCONFDIR) && $(SCRIPTDIR)/install-rootfs.sh default $(SYSROOTDIR)`
4. 拷贝CPU相关的程序或脚本`onieroot/rootconf/$(ROOTFS_ARCH)/*`到`SYSROOTDIR`对应目录下:
   - `cp $(ROOTCONFDIR)/$(ROOTFS_ARCH)/sysroot-lib-onie/* $(SYSROOTDIR)/lib/onie`
   - `cp $(ROOTCONFDIR)/$(ROOTFS_ARCH)/sysroot-bin/* $(SYSROOTDIR)/bin`
5. 拷贝/映射平台机器相关的程序或脚本`machine/rootconf/`到`SYSROOTDIR`对应目录下:
   - `cp $(MACHINEDIR)/rootconf/sysroot-lib-onie/* $(SYSROOTDIR)/lib/onie`
   - `cp $(MACHINEDIR)/rootconf/sysroot-bin/* $(SYSROOTDIR)/bin`
   - `cp $(MACHINEDIR)/rootconf/sysroot-init/* $(SYSROOTDIR)/etc/init.d`
   - `cp -a $(MACHINEDIR)/rootconf/sysroot-rcS/* $(SYSROOTDIR)/etc/rcS.d`
   - `cp -a $(MACHINEDIR)/rootconf/sysroot-rcK/* $(SYSROOTDIR)/etc/rc0.d` & `cp -a $(MACHINEDIR)/rootconf/sysroot-rcK/* $(SYSROOTDIR)/etc/rc6.d`
   - `cp -ar $(MACHINEDIR)/rootconf/sysroot-etc/* $(SYSROOTDIR)/etc/`
6. 其他程序和脚本的修改或覆盖:
   - 安全启动相关:
     - 通用: `cp $(SYSROOTDIR)/bin/onie-console $(SYSROOTDIR)/bin/onie-console-open`
     - 通用: `sed -i 's/exec \/bin\/sh -l/exec \/bin\/login/' $(SYSROOTDIR)/bin/onie-console`
     - 通用: `cp $(SYSROOTDIR)/bin/onie-console $(SYSROOTDIR)/bin/onie-console-secure`
     - 机器相关(登录密码): `cp -a $(MACHINEDIR)/rootconf/sysroot-etc/passwd-secured $(SYSROOTDIR)/etc/passwd`
   - 通用: `cd $(SYSROOTDIR) && ln -fs sbin/init ./init`
7. 构建`$(MBUILDDIR)/lsb-release`并拷贝到`SYSROOTDIR/etc/`
   - `echo "DISTRIB_ID=onie" >> $(LSB_RELEASE_FILE)`
   - `echo "DISTRIB_RELEASE=$(LSB_RELEASE_TAG)" >> $(LSB_RELEASE_FILE)` 
     - LSB_RELEASE_TAG=$(ONIE_RELEASE_TAG)$(VENDOR_VERSION)$(DIRTY)
     - ONIE_RELEASE_TAG=$(cat build-config/conf/onie-release)
   - `echo "DISTRIB_DESCRIPTION=Open Network Install Environment" >> $(LSB_RELEASE_FILE)`
8. 构建`$(MBUILDDIR)/os-release`并拷贝到`SYSROOTDIR/etc/`
   - `echo "NAME=\"onie\"" >> $(OS_RELEASE_FILE)`
   - `echo "VERSION=\"$(LSB_RELEASE_TAG)\"" >> $(OS_RELEASE_FILE)`
   - `echo "ID=linux" >> $(OS_RELEASE_FILE)`
9.  构建`$(MBUILDDIR)/machine-build.conf`并拷贝到`SYSROOTDIR/etc/`
   - `echo "onie_version=$(LSB_RELEASE_TAG)" >> $(MACHINE_CONF)`
   - `echo "onie_build_platform=$(ARCH)-$(ONIE_BUILD_MACHINE)-r$(MACHINE_REV)" >> $(MACHINE_CONF)`
   - `echo "onie_kernel_version=$(LINUX_RELEASE)" >> $(MACHINE_CONF)`
   - ...
10. 创建 cpio 归档并对其进行压缩
   1. CPIO归档: `fakeroot -- $(SCRIPTDIR)/make-sysroot.sh $(SYSROOTDIR) $(SYSROOT_CPIO)`; SYSROOT_CPIO=$(MBUILDDIR)/sysroot.cpio
     - 创建归档文件: `touch "$cpio_archive"` cpio_archive=SYSROOT_CPIO
     - 给rootfs重新创建空/dev目录: `rm -rf ${sysroot}/dev; mkdir -p ${sysroot}/dev` sysroot=SYSROOTDIR
     - `cd $sysroot && find . | cpio --create -H newc > $cpio_archive` -H newc: 指定使用 "new ASCII" 格式创建归档。这是一种常用于 initramfs 的格式。
   2. 压缩: `xz --compress --force --check=crc32 --stdout -8 $(SYSROOT_CPIO) > $@` $@=SYSROOT_CPIO_XZ=$(IMAGEDIR)/$(MACHINE_PREFIX).initrd=../build/images/cls_xxx-r0.initrd
   3. 签名(安全启动相关，option): `fakeroot -- $(SCRIPTDIR)/gpg-sign.sh $(GPG_SIGN_SECRING) $(SYSROOT_CPIO_XZ)`, 得到签名文件SYSROOT_CPIO_XZ_SIG=$(SYSROOT_CPIO_XZ).sig
     - GPG_SIGN_SECRING: 配置到`machine-security.make`(从machine/kvm_x86_64/拷贝)
   4. 链接到`UPDATER_INITRD=$(MBUILDDIR)/onie.initrd`,`UPDATER_INITRD_SIG=$(MBUILDDIR)/onie.initrd.sig`: ln -sf $SYSROOT_CPIO_XZ(.sig) $UPDATER_INITRD(.sig)
11. 制作image
   1. 制作成uboot 多文件 .itb image (arm,onie-mk-itb.sh, need $(IMAGEDIR)/$(MACHINE_PREFIX).dtb) -> $(IMAGEDIR)/$(MACHINE_PREFIX).itb | $(MBUILDDIR)/onie.itb
   2. 制作成uboot image-bin (arm,onie-mk-bin.sh) -> $(IMAGEDIR)/onie-$(MACHINE_PREFIX).bin
   3. 制作成image-updater (onie-mk-installer.sh) -> $(IMAGEDIR)/onie-updater-$(ARCH)-$(MACHINE_PREFIX)
   4. 制作成recovery-initrd (make-sysroot.sh, 带image-updater(/lib/onie/onie-updater)的onie.initrd) -> $(MBUILDDIR)/recovery/initrd.cpio | $(MBUILDDIR)/recovery/$(ARCH)-$(MACHINE_PREFIX).initrd
       - `cp -a $(SYSROOTDIR) $(RECOVERY_SYSROOT)` RECOVERY_SYSROOT=$(MBUILDDIR)/recovery
       - `cp $(UPDATER_IMAGE) $(RECOVERY_SYSROOT)/lib/onie/onie-updater`
   5. 制作成recovery-iso (onie-mk-iso.sh, need recovery-initrd及其相关内容)



### 安装包安装过程

```cfg
menuentry "ONIE: Rescue" --class gnu-linux --class onie {
  echo    "ONIE: Rescue Mode ..."
  onie_entry_start
  linux   /vmlinuz $ONIE_CMDLINE_LINUX boot_reason=rescue
  initrd  /initrd.xz
  onie_entry_end
}

menuentry "ONIE: Embed ONIE" --class gnu-linux --class onie {
  echo    "ONIE: Embedding ONIE ..."
  onie_entry_start
  linux   /vmlinuz $ONIE_CMDLINE_LINUX boot_reason=embed install_url=file:///lib/onie/onie-updater
  initrd  /initrd.xz
  onie_entry_end
}
```

1. 引导进入`Embed`模式, 通过内核参数传参到/proc/cmdline
2. Discover通过`/lib/onie/functions`中的函数`import_cmdline`导入静态链接`onie_install_url`
3. Discover进行 服务发现 和 网络邻居发现 查找 `磁盘分区更新包` 和 `HTTP/TFTP/FTP..服务器IP`
   1. Discover通过`sd_static`服务发现找到`onie_install_url`，存放到`onie_static_url`
4. 执行安装器函数`exec_installer`进行`更新包`的更新



### 更新包更新过程

1. 运行更新包（`sharch_body.sh`），创建临时目录`/tmp/tmp.xxx/`
2. `sharch_body.sh`将安装包`exit_marker`后的内容解压到/tmp/tmp.xxx/目录下，即/tmp/tmp.xxx/installer/
   - 包括onie-update.tar.xz
   - 暂时不解压onie-tools.tar.xz，看后续重新创建onie-boot分区时再解压
3. `sharch_body.sh`执行`/tmp/tmp.xxx/installer/`下的`install.sh`进行安装
4. `install.sh`初始化环境：`. ./installer.conf`, `. ./machine-build.conf`, `. ./update-type`, `. ./install-arch`(update_type=onie), `. ./install-platform`, `. /etc/machine.conf`
   - `. ./install-arch`会初始化: `. ./installer.conf`, `. ./machine-build.conf`, `. /etc/machine.conf`
   - `. ./update-type`: 若(update_type!=onie)即firmware-update, update-type会携带函数`install_image`和`parse_arg_arch`
5. `install.sh`校验image，看跟现在用的onie是否是匹配的平台: function `check_machine_image`
6. `install.sh`调用`install-arch`中的函数`install_image`
7. 函数`install_image`调用`init_onie_install`：
   1. 找安装的磁盘位置(`onie-blkdev-common`)：/dev/sda? /dev/sdb? 
      1. 查找当前onie启动时(ONIE-BOOT)的磁盘设备/分区(默认挂载到`/mnt/onie-boot/`)：`curr_onie_dev`=函数`onie_get_boot_dev` of `onie-blkdev-common`
      2. 获取平台设置的安装设备/分区(一般/dev/sda)：`onie_dev=$(install_device_platform)`，位于 `machine_dir/installer.conf`中的函数
   2. 确定`install_firmware=uefi` or `install_firmware=bios`
   3. 根据`install_firmware`和`image_partition_type(gpt|msdos)`设置`grub-boot(uefi efi system)`分区和`onie-boot`分区的位置和大小，保存变量
      1. `install_firmware=uefi`: UEFI EFI System Partition 分区1，256MB; ONIE-BOOT Paritition 分区2，128MB
      2. `image_partition_type=gpt`: GRUB Boot Partition 分区1，2MB； ONIE-BOOT Paritition 分区2，128MB
      3. `image_partition_type=msdos`: ONIE-BOOT Paritition 分区1，128MB
8. 函数`install_image`执行安装：
   1. 判断是否有钩子函数`pre_install_hook`并执行，配置于(`machine/xxx/platform/installer.conf`)
   2. 取消挂载：
      1. 若是embed模式，取消挂载当前onie启动时的磁盘设备的所有分区(ONIE-BOOT) 和 平台设置的安装设备, 并重新初始化块设备
      2. 若是升级模式，取消挂载当前onie启动时的磁盘设备(ONIE-BOOT)
   3. 保存升级前ONIE-BOOT的珍贵文件（重新挂载，拷贝后取消挂载）：
      1. 重新挂载`onie_boot_dev=`到`onie_boot_mnt=/mnt/onie-boot/`
      2. 保留升级前的珍贵文件到临时目录
         1. `cp $grub_env_file /tmp/grubenv`, `grub_env_file=/mnt/onie-boot/grub/grubenv`
         2. `cp -a $onie_update_dir /tmp/preserve-update`, `onie_update_dir=/mnt/onie-boot/onie/update/`即已经放到`onie-fwpkg`里的待升级软件或固件
         3. 若不是embed模式，若存在则保留onie grub中的diag启动项：`cp $diag_bootcmd_file /tmp/preserve_diag_bootcmd`, `diag_bootcmd_file=/mnt/onie-boot/onie/grub/diag-bootcmd.cfg`
      3. 取消挂载
   4. 重新创建ONIE-BOOT分区
      1. 创建文件系统`onie_boot_dev=${onie_dev}$blk_suffix$onie_boot_part`
      2. 挂载文件系统`$onie_boot_dev`到`$onie_boot_mnt`(/mnt/onie-boot/)
      3. 存放onie-boot的文件：
         1. onie目录
            1. `cp onie.vmlinuz /mnt/onie-boot/onie/vmlinuz-${image_kernel_version}-onie` image_kernel_version来自machine-build.conf
            2. `cp onie.initrd /mnt/onie-boot/onie/initrd.img-${image_kernel_version}-onie` image_kernel_version来自machine-build.conf
            3. 若启用安全启动, 即image_secure_grub=yes, 拷贝签名文件onie.vmlinuz.sig和onie.initrd.sig
            4. tools子目录，内容时onie-tools.tar.xz解压后(这个时候才解压onie-tools.tar.xz)的文件和目录，即源码中/rootconf/grub-arch/*/下的的内容
              ```
               tools/
                  bin/
                     onie-boot-mode
                     onie-fwpkg
                     onie-nos-mode
                     onie-version
                  lib/
                     onie/
                        onie-blkdev-common
                        ...
              ```
            5. grub, grub.d子目录
         2. grub目录，内容来自`grub-install`命令
            1. grubenv
            2. grub.cfg
            3. locale(option)
            4. fonts/
            5. x86_64-efi/
               1. xxx.mod
               2. ......
   5. 安装UEFI加载程序 或 grub
      1. 若使用UEFI("$install_firmware" = "uefi"): `install_uefi_loader $uefi_esp_mnt $onie_dev $onie_boot_mnt`; `uefi_esp_mnt="/boot/efi/"` from `onie-blkdev-common`，实际是分区1 /dev/sda1; 
         1. 预设`uefi_dir=uefi_esp_mnt="/boot/efi/"`, `boot_dev=onie_dev=/dev/sda2`, `boot_dir=onie_boot_mnt=/mnt/onie-boot/`
         2. 安装grub: `install_uefi_grub "$uefi_dir" "$boot_dev" "$boot_dir"`
            - `grub-install --target=${onie_arch}-efi --no-nvram --bootloader-id=onie --efi-directory="$uefi_dir" --boot-directory="$boot_dir" --recheck "$boot_dev"`
         3. 若启用安全启动，安装shim & grub：`install_uefi_shim_grub "$uefi_dir" "$boot_dev" "$boot_dir"`
            - ...
         4. 若为embed模式，创建onie的efi bios启动项：
            - `efibootmgr --quiet --create --label "ONIE: Open Network Install Environment" --disk $boot_dev --part $uefi_esp_part --loader /EFI/onie/${image_uefi_boot_loader}` image_uefi_boot_loader=grubx64.efi来自machine-build.conf
         5. 安装grub初始grub.cfg文件：`install_grub_config $boot_dir`，设置一些将被 50_onie_grub 脚本获取和使用的 GRUB_xxx 环境变量。这类似于操作系统在 /etc/default/grub 中指定的变量。
            1. 将grub配置片段复制到ONIE目录: `/bin/cp -a grub grub.d $boot_dir/onie`
            2. 还原以前的diag_bootcmd.cfg文件: `cp /tmp/preserve_diag_bootcmd $diag_bootcmd_file`
            3. 导入控制台配置和Linux CMDLine环境: `. $boot_dir/onie/grub/grub-variables`
            4. 配置grub.cfg：`install_grub_config $boot_dir`
               1. 若需要构建secure grub：
                  1. ...
               2. 若不需要构建secure grub：`$boot_dir/onie/grub.d/50_onie_grub >> $grub_root_dir/grub.cfg`, grub_root_dir=/mnt/onie-boot/grub/
                  1. ...
         6. 创建默认的EFI加载程序boot/bootx64.efi或bootaa64.efi:
            1. `loader_dir="${uefi_dir}/EFI/onie"`, `BOOT_dir="${uefi_dir}/EFI/BOOT"`
            2. 拷贝onie的efi到BOOT/下：`cp -rf $loader_dir/* ${BOOT_dir}/ `即`cp -rf /boot/efi/EFI/onie/* /boot/efi/EFI/BOOT/`
            3. 制作使用grub作为默认loader：
               1. 安全模式：
                  1. `mv "${BOOT_dir}/shim${image_uefi_arch}.efi" "${BOOT_dir}/BOOT${CSVSuffix}.EFI"`
                  2. `rm $loader_dir/mm${image_uefi_arch}.efi`
                  3. `rm $loader_dir/fb${image_uefi_arch}.efi`
                  4. `mv "$/mnt/onie-boot/onie/grub/BOOT.CSV_${CSVBootArch}_secured" "${loader_dir}/BOOT.CSV"`
                  5. `rm "$/mnt/onie-boot/onie/grub/BOOT.CSV"`
               2. 非安全模式：
                  1. `mv /mnt/onie-boot/onie/grub/grubx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI`
                  2. `rm "/mnt/onie-boot/onie/grub/BOOT.CSV_amd64_secured"`
      2. 若没有UEFI：
         1. embed模式下重新安装grub到MBR块内: `install_grub mbr $onie_dev $onie_boot_mnt`
         2. 同时安装grub到ONIE分区设备下: `install_grub part $onie_boot_dev $onie_boot_mnt`
         3. 清理仅与 UEFI 启动相关的 BOOT.CSV 文件。BOOT.CSV文件包含了启动项的详细信息，如启动项的名称、启动项的路径、启动项的描述等。
            1. `rm "$onie_root_dir/grub/"BOOT.CSV*`
   6. 恢复升级前ONIE-BOOT的珍贵文件
      1. `cp /tmp/grubenv $grub_env_file`
      2. `cp -a /tmp/preserve-update $onie_update_dir` 或创建新的update进度的目录`mkdir -p $onie_update_dir $onie_update_results_dir $onie_update_pending_dir`
   7. 其他设置恢复和修改
      1. 恢复系统默认启动模式: `/mnt/onie-boot/onie/tools/bin/onie-boot-mode -q -o none`
      2. 若是embed模式，清楚NOS模式: `$onie_root_dir/tools/bin/onie-nos-mode -c`. 设置时，NOS 模式表示已安装 NOS。清除NOS模式表示未安装 NOS。
      3. (diag启动项位于安装uefi加载程序处恢复：若不是embed模式，若存在则保留onie grub中的diag启动项, `cp /tmp/preserve_diag_bootcmd $diag_bootcmd_file`)
   8. 判断是否有钩子函数`post_install_hook`并执行，配置于(`machine/xxx/platform/installer.conf`)
   9. 更新syseeprom: `update_syseeprom`. 修改eeprom的0x29的ONIE Version字段：`ONIE Version         0x29  16 2021.03.05.0.0.6`. function update_syseeprom位于install.sh
   10. 若是安全模式，设置密码：`set_default_passwd`, 由`onie/machine/<manufactuer>/<machine>/installer/install-platform`可提供和覆盖函数`set_default_passwd`
       1. 默认是不设的
       2. 可以通过这种方式创建：`cp /etc/passwd-secured $onie_config_dir/etc/passwd; rm -f /etc/passwd; ln -s $onie_config_dir/etc/passwd /etc/passwd;` 

