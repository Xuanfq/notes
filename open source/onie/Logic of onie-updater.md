# Logic of onie-updater

### 更新包制作和安装逻辑

#### 制作命令
```sh
onie-mk-installer.sh 
	onie \  # update_type: onie | firmware
	grub-arch \  # rootfs_arch, arch_dir
	../machine/celestica/cls_xxx \  # machine_dir
	MACHINE_CONF \  # machine_conf
	../installer \  # installer_dir
	../build/images/onie-updater-x86_64-cls_xxx-r0 \  # output_file
	../build/onie-updater-x86_64-cls_xxx-r0/grubx64.efi \  # UPDATER_IMAGE_PARTS, update image parts, which will be packed into onie-update.tar.xz
	../machine/celestica/cls_xxx/rootconf/sysroot-lib-onie/test-install-sharing  # UPDATER_IMAGE_PARTS_PLATFORM, update image parts platform, which will be packed into onie-update.tar.xz

MBUILDDIR=../build/onie-updater-x86_64-cls_xxx-r0

installer_conf=$machine_dir/installer.conf

update_label="ONIE"  # ONIE | Firmware

UPDATER_IMAGE_PARTS=$(UPDATER_VMLINUZ) $(UPDATER_INITRD) $(UPDATER_ONIE_TOOLS) \
			$(ROOTCONFDIR)/grub-arch/sysroot-lib-onie/onie-blkdev-common \
			$(ROOTCONFDIR)/grub-arch/sysroot-lib-onie/nos-mode-arch \
      # $(UPDATER_VMLINUZ).sig $(UPDATER_INITRD).sig
      # $(GRUB_SECURE_BOOT_IMAGE).sig

GRUB_TIMEOUT ?= 5
```


#### 安装包/更新包文件内容Package

```sh
installer/
  *onie-update.tar.xz         # update image parts, params of onie-mk-installer.sh
  *update-type                # create with content: [update_type=onie\r\nupdate_label=ONIE\r\n]
  *grub/                      # from ../installer/grub-arch/*   # if arm, does not exist this
    ...
    *grub-variables           # create with content: [## Begin grub-variables......serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1...]
    *grub-machine.cfg         # create 
    *grub-extra.cfg           # create 
  *grub.d/                    # from ../installer/grub-arch/*   # if arm, does not exist this
  *install-arch               # from ../installer/grub-arch/*   # or arm from ../installer/u-boot-arch/*
  *install.sh                 # from ../installer/install.sh
  *installer.conf             # from $machine_dir/installer.conf  # only onie update-type and grub-arch
  *machine-build.conf         # create
  install-platform            # option, from machine directory: $machine_dir/installer/install-platform
  onie-tools.tar.xz           # UPDATER_IMAGE_PARTS
  onie.initrd                 # UPDATER_IMAGE_PARTS
  onie.vmlinuz                # UPDATER_IMAGE_PARTS
  onie-blkdev-common          # UPDATER_IMAGE_PARTS, $(ROOTCONFDIR)/grub-arch/sysroot-lib-onie/onie-blkdev-common
  nos-mode-arch               # UPDATER_IMAGE_PARTS, $(ROOTCONFDIR)/grub-arch/sysroot-lib-onie/nos-mode-arch
```

#### 安装包/更新包制作原理

1. 压缩 package 成 xz
2. 追加package包到脚本/installer/sharch_body.sh后
3. 更新包onie-updater-x86_64-xxx-r0就是脚本sharch_body.sh


#### 安装/更新过程

1. 运行安装包（`sharch_body.sh`），创建临时目录`/tmp/tmp.xxx/`
2. `sharch_body.sh`将安装包`exit_marker`后的内容解压到/tmp/tmp.xxx/目录下，即/tmp/tmp.xxx/installer/
3. `sharch_body.sh`执行`/tmp/tmp.xxx/installer/`下的`install.sh`进行安装
4. `install.sh`初始化环境：`. ./installer.conf`, `. ./machine-build.conf`, `. ./update-type`, `. ./install-arch`
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
      1. 若是embed模式，取消挂载当前onie启动时的磁盘设备(ONIE-BOOT) 和 平台设置的安装设备
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
            4. tools子目录，内容时onie-tools.tar.xz解压后的文件和目录，即源码中/rootconf/grub-arch/*/下的的内容
              ```
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
         3. 若启用安全启动，安装shim grub：`install_uefi_shim_grub "$uefi_dir" "$boot_dev" "$boot_dir"`
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

