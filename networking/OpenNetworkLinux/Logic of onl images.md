# Logic of onl images

## 制作和安装逻辑

### Image制作

Reference: [Build.md](./Build.md)



### Image结构

**解压Image**: `./ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER -x "" ""`

```log
aiden@Xuanfq:/tmp/tmp.t9G9fw3xWe$ ./ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER -x " " ""
ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER: computing checksum of original archive
ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER: checksum is OK
ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER: extracting pad
1+0 records in
1+0 records out
512 bytes copied, 4.73e-05 s, 10.8 MB/s
ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER: copying file before resetting pad
ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER: resetting pad
1+0 records in
1+0 records out
512 bytes copied, 5.0325e-05 s, 10.2 MB/s
ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER: processing with zip
ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER: correcting permissions with autoperms.sh
```


**Structure**:

- config/
  - README
- plugins/
  - sample-preinstall-Mvjcxq.py
  - sample-postinstall-lSta2D.py
- boot-config
- kernel-3.16-lts-x86_64-all
- kernel-4.14-lts-x86_64-all
- kernel-4.19-lts-x86_64-all
- kernel-5.4-lts-x86_64-all
- kernel-4.9-lts-arm64-all.bin.gz (arm64)
- ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64.swi
- onl-loader-initrd-amd64.cpio.gz (x86)
- onl-loader-fit.itb (arm)
- postinstall.sh  <-  sample-postinstall.sh
- preinstall.sh  <-  sample-preinstall.sh
- autoperms.sh
- installer.sh  -> installer-XXXXXX  <-  installer.sh.in



### Image安装

1. 安装器(自解压脚本)校验和分离压缩包后:
   1. 导出环境变量: `export SFX_BLOCKSIZE SFX_BLOCKS SFX_PAD SFX_UNZIP SFX_LOOP SFX_PIPE SFX_LAZY SFX_PERMS`
   2. 将安装脚本`installer.sh`重命名成`install-XXXXXX`后，调用命令进行安装`eval "$tmp_install" $dashx "$_ZIP"`。
      
      实际上不能在`bash -x`/`set -x`的环境下安装，因为这在参数在`eval "$tmp_install" $dashx "$_ZIP"`会将`$dashx`(即-x)作为参数传入安装脚本`installer.py`赋给压缩包变量: `installer_zip=$1`，这将导致使用无效且错误的zip压缩包，导致无法安装。

2. 初始化和架构检查阶段: 
   1. 比对预设的安装器架构`IARCH` 以及 onie环境的架构`uname -m`，根据架构设置其中之一变量`ARCH_PPC=$ARCH;ARCH_X86=$ARCH;ARCH_ARM=$ARCH`
   2. 初始化常用变量: 
      - installer_dir=${0%/*}, `installer.sh/install-XXXXXX`脚本所在目录
3. 环境检测和设置阶段: 
   1. 检查`grub`或`uboot`环境变量是否存在`onl_installer_debug`，若有则设置为debug模式: `set -x`
   2. 根据onie环境设置变量，若已存在于环境变量则跳过，无则通过`onie-sysinfo`获取，最者用onie的`. /etc/machine.conf`设置: 
      1. onie_platform: onie-sysinfo -p
      2. onie_arch: onie-sysinfo -c
   3. 根据上诉设置的onie_platform的值判断检测是否在ONIE环境下，根据不同环境设置 (x86下必须为onie环境否则退出): 
      1. 日志输出方式：`installer_say`, onie为`echo "$@" > /dev/console;`, 其他为`echo "* $@";`
      2. 安装结束后的清理方法: `installer_cleanup`, onie下需要重启
4. 临时文件系统准备阶段: 查找或创建临时文件系统，导出临时文件系统目录`TMPDIR`
5. 安装包解压阶段: 仅提取ram根文件系统
   1. 定义解压函数，根据不同情况选择解压方式，解压的文件到当前目录，同时排除SFX_PAD(pad.bin)的解压: `installer_unzip`
   2. 执行解压，提取ram根文件系统`$initrd_archive`: `installer_unzip $installer_zip $initrd_archive`
   3. 检查`grub`或`uboot`环境变量是否存在`onl_installer_unpack_only`，若有则设置为仅unpack模式，由于已完成解压，直接退出退出 
6. 根文件系统准备阶段: 
   1. 创建根目录(临时文件夹，占用的是RAM内存): `rootdir=$(mktemp -d -t "initrd-XXXXXX")`
   2. 根据uboot/x86中的initrd.cpio.gz/fit.itb差异，即是否存在$initrd_offset，来提取真实根文件系统
   3. 解压根文件系统到到根目录
   4. 加载安装脚本的函数库: `. "${rootdir}/lib/vendor-config/onl/install/lib.sh"`
   5. 在根目录下创建chroot环境: `installer_mkchroot "${rootdir}"`
      1. 初始化变量与检测 devtmpfs
      2. 配置 /dev 目录（设备文件系统），若支持 devtmpfs，暂不操作（后续通过 mount 挂载），不支持 devtmpfs 时，手动复制宿主系统的 /dev 设备
      3. 配置 /run 目录（运行时数据）
         ```sh
          d1=$(stat -c "%D" /run)  # 获取宿主 /run 的设备ID（用于判断是否为同一文件系统）
          for rdir in /run/*; do
            if test -d "$rdir"; then
              mkdir "${rootdir}${rdir}"  # 复制 /run 下的子目录（如 /run/systemd）
              d2=$(stat -c "%D" $rdir)   # 子目录的设备ID
              t2=$(stat -f -c "%T" $rdir)  # 子目录的文件系统类型（如 tmpfs、ext4）
              
              # 跳过 tmpfs/ramfs 类型（这类目录是临时内存文件系统，无需挂载）
              case "$t2" in
                tmpfs|ramfs) : ;;
                *)
                  # 若子目录与 /run 不在同一设备（如独立挂载的分区），则通过 bind 挂载同步内容
                  if test "$d1" != "$d2"; then
                    mount -o bind $rdir "${rootdir}${rdir}"
                  fi
              esac
            fi
          done
         ```
      4. 挂载关键文件系统: 
         1. 挂载 proc 文件系统（提供进程和系统信息的接口，如 /proc/cpuinfo）
         2. 挂载 sysfs 文件系统（提供内核与用户态的交互接口，如 /sys/devices）
         3. 若支持 devtmpfs，挂载它到 chroot 的 /dev（自动生成设备文件），并创建伪终端目录 /dev/pts/ 以及挂载 devpts（伪终端设备，支持终端交互，如 ssh、bash）
         4. 若存在 EFI 固件变量目录，挂载 efivarfs（用于UEFI系统的固件配置）: `modprobe efivarfs || :; mount -t efivarfs efivarfs "${rootdir}/sys/firmware/efi/efivars"`
         5. 复制配置文件（保持环境一致性）: 
            1. 复制临时目录配置: `mkdir -p "${rootdir}${TMPDIR}"`
            2. 复制onie机器配置文件: `cp /etc/machine*.conf "${rootdir}/etc/."`
            3. 复制 ONL（Open Network Linux）相关配置: `cp -a /etc/onl/. "${rootdir}/etc/onl/."`
            4. 复制固件环境配置（用于访问硬件固件的配置，如 flash 分区）: `cp /etc/fw_env.config "${rootdir}/etc/fw_env.config"`
7. 挂载点和配置准备阶段: 
   1. 创建根文件系统安装器目录: `mkdir -p "${rootdir}/mnt/installer"`
   2. 挂载安装器所在目录到根文件系统安装器目录(只读): `mount -o ro,bind "${installer_dir}" "${rootdir}/mnt/installer"`
   3. 确保onie-boot已挂载到宿主机，若未挂载，尝试挂载，失败则跳过。若挂载正常，将其挂载到根文件系统rootdir相对同一位置(只读): `mount -o ro,bind "/mnt/onie-boot" "${rootdir}/mnt/onie-boot"`
   4. 创建安装器环境的相关配置文件: `${rootdir}/etc/onl/installer.conf`
      1. onl_version="$onl_version"
      2. onie_platform=$onie_platform=$(onie-sysinfo -p 2>/dev/null) || . /etc/machine.conf
      3. onie_arch=$onie_arch=$(onie-sysinfo -c 2>/dev/null) || . /etc/machine.conf
      4. installer_md5="$installer_md5"
      5. installer_zip="${installer_zip##*/}"
      6. installer_dir=/mnt/installer
      7. installer_url=\"$installer_url\" (if test -f "$0.url")
      8. initrd_archive=\"$initrd_archive\" (arm)
      9. initrd_offset=\"$initrd_offset\" (arm)
      10. initrd_size=\"$initrd_size\" (arm)
      11. installer_chroot=\"${rootdir}\"
      12. installer_postinst=\"/mnt/installer/$(mktemp -t postinst-XXXXXX)\" (好像没啥用, set -x; . "$postinst"; set +x)
   5. 设置主安装脚本`installer_shell`: `installer_shell=${installer_shell-"/usr/bin/onl-install --force"}`，由此，`可通过环境变量installer_shell进行debug和设置安装脚本`。若为默认主安装脚本`/usr/bin/onl-install --force`，取消挂载`/mnt/*|/boot/*`
8. 预安装阶段: 
   1. 从压缩包中提取前置安装脚本`preinstall.sh`: `installer_unzip $installer_zip preinstall.sh`
   2. 赋予执行权限并传入根文件系统目录$rootdir运行前置安装脚本`preinstall.sh`: `./preinstall.sh $rootdir`
9. 主安装阶段: 
   1. 检测和简单修复 GPT（GUID 分区表）分区表错误，从ESP_DEVICE、GRUB_DEVICE、ONIE_DEVICE依次找出可用的GPT分区，检查是否需要修复，若需要则通过备份和恢复备份的方式简单修复: `installer_fixup_gpt`; `sgdisk -b "$dat" "$dev"; sgdisk -l "$dat" "$dev" || return 1`
   2. 以chroot的方式执行主安装脚本: `chroot "${rootdir}" $installer_shell`, 实际上是`/usr/bin/onl-install --force`, 也即`packages/base/all/vendor-config-onl/src/python/onl/install/App.py`!
10. 后安装阶段:
   1. 执行上诉创建的配置文件的installer_postinst项(无实际内容): `set -x; . "$postinst"; set +x`
   2. 从压缩包中提取后置安装脚本`postinstall.sh`: `installer_unzip $installer_zip postinstall.sh`
   3. 赋予执行权限并传入根文件系统目录$rootdir运行后置安装脚本`postinstall.sh`: `./postinstall.sh $rootdir`
11. 清理和重启阶段: 
   1. 清理资源: `trap - 0 1; installer_umount`
   2. 重启系统: `installer_reboot $installer_wait`, 3秒或30秒(debug)重启，可中断。



#### 主要安装过程 `onl-install --force`

1. 初始化阶段:
   1. 设置log输出到/dev/console
   2. 根据是否存在环境变量onie_verbose设置是否使用debug日志模式
   3. 根据是否存在环境变量installer_debug设置是否安装失败后执行app.post_mortem(): 重新附加到控制台,启动 Python 调试器进行事后分析 `import pdb; pdb.post_mortem(sys.exc_info()[2])`
   4. 创建App实例: `app = cls(url=ops.url, force=ops.force, log=logger)`
2. 安装执行阶段: `app.run()` -> `app.runLocal()`(No ops.url)
   1. 配置加载:
      1. 设置`machineConf`配置获取方法为`onie-sysinfo`，期间若未挂载`ONIE-BOOT`则会重新挂载分区到新创建的临时文件。若onie-sysinfo不生效，使用`/etc/machine.conf`。
      2. 设置`installerConf`配置获取方法为`/etc/onl/installer.conf`
   2. 调用`app.runLocalOrChroot()`
      1. 平台检测: 如果检测失败，返回错误代码
         1. 设置`installerConf.installer_platform` = `machineConf['onie_platform'].replace('_', '-').replace('.', '-')`
         2. 设置`installerConf.installer_arch` = `machineConf['onie_arch']`
      2. 加载平台特定配置器与安装器: 
         1. 导入并创建当前平台专属配置器实例: `onlPlatform = onl.platform.current.OnlPlatform()`。由于`/etc/onl/platform`未生成，使用`/etc/onl/installer.conf`的配置来获取当前平台。
         2. 根据平台配置选择适当的安装器类型 (GRUB 或 U-Boot): `iklass = BaseInstall.GrubInstaller if 'grub' in onlPlatform.platform_config else BaseInstall.UbootInstaller`, `onlPlatform.platform_config`是platform-config-defaults-(x86-64|uboot).yml + $machine/platform-config/r0/src/lib/$platform.yml(e.g.x86-64-machinename-r0.yml), 也即下文的`platformConf`!!!
      3. 配置GRUB/UBOOT开机启动引导环境: 
         1. 配置 GRUB 环境，模式: 默认第一种！至于grub配置所在分区，后续会纠正/重新设置为`ONL-BOOT`分区
            1. native ONIE initrd + chroot GRUB: 直接chroot访问onie initrd，使用onie的grub工具，onie的grubenv（后续会纠正/重新设置为`ONL-BOOT`分区）。`grubEnv = ConfUtils.ChrootGrubEnv(...)`
            2. proxy GRUB: 通过临时根文件系统(chroot host)间接访问，使用的是onl的grub工具，onie的grubenv（后续会纠正/重新设置为`ONL-BOOT`分区）。`grubEnv = ConfUtils.ProxyGrubEnv(...)`
         2. 配置 U-Boot 环境（如果存在/usr/sbin/fw_setenv|/usr/bin/fw_setenv|/bin/false）: `ubootEnv = ConfUtils.UbootEnv`
      4. 运行GRUB/UBOOT特定安装器: 
         1. 实例化安装器: `installer = iklass(...)`
         2. 运行安装入口: `code = installer.run()` (Below is GrubInstaller)
            1. 配置验证: 校验machineConf的grub.label是否是gpt，不是则返回1，安装失败
            2. 加载压缩包: `zf = zipfile.ZipFile(installerConf.installer_dir+installerConf.installer_zip)`
            3. 加载插件: `loadPlugins()`, 加载到列表里，按顺序运行，也是按下方加载的顺序运行，理论上每一个目录里都是按名称顺序进行排序。
               1. 加载安装目录(`installerConf.installer_dir/plugins/*.py`)下的插件: 实际上还没解压出来
               2. 加载压缩包(`zf`)里的插件(`plugins/*.py`): 实际上仅临时读取匹配`plugins/*.py`的文件并尝试加载为插件，此处加载了`sample-preinstall-xxxxxx.py`和`sample-postinstall-xxxxxx.py`两个插件
               3. 加载ram根文件系统(`$pydir/onl/install/plugins/*.py`)下的插件: 位于`packages/base/all/vendor-config-onl/src/python/onl/install/plugins`, 但该文件没有实现任何插件。**可以通过此处为平台添加插件**。
            4. 以`预(前置)安装模式`(Plugin.PLUGIN_PREINSTALL)运行插件: `runPlugins(Plugin.PLUGIN_PREINSTALL)`, 按上方加载的顺序依次运行每个插件。
            5. 查找 GPT 分区表: 
               1. 解析块设备分区信息
               2. 确定目标安装设备: `device`, 根据`platformConf['grub']['device']`进行确定，若是分区标签，目标设备为该标签所在的磁盘，若是磁盘分区名如/dev/sda，则直接为该磁盘。需该磁盘已能正常使用存在分区号。
               3. 若不是UEFI系统，需要保证磁盘设备未挂载，--force模式下能自动卸载。
               4. 备份现有的 ONL-CONFIG 分区（如果存在且与安装设备处于同一磁盘）: `tar -zcf onl-config-xxxxxx.tar.gz .`
               5. 初始化 parted 设备和磁盘对象: `partedDevice = parted.getDevice(device); partedDisk = parted.newDisk(partedDevice)`
               6. 确定最小起始分区号`minpart`: 需跳过隐藏分区、GRUB、ONIE-BOOT、DIAG等分区。
            6. 若是UEFI系统，还需要查找 EFI 系统分区 (ESP): 此处假定GRUB分区所在就是ESP分区
               1. 解析 GPT 分区表
               2. 查找 ESP 分区: `espDevice`
               3. 获取 ESP 分区的文件系统 UUID: `espFsUuid`
               4. 设置 `grubEnv` 里的 `espPart` = `espDevice`
            7. 删除现有的`minpart`所在的分区并计算该分区起始的块`nextBlock`: `deletePartitions()`
            8. 创建新分区: `partitionParted()`, 根据平台配置`platformConf['installer']`中的分区规范创建新分区，并格式化文件系统。
            9. 纠正/重新设置 GRUB BOOT 配置所在分区: 将 `grubEnv` 里的 `bootPart` 设为 `ONL-BOOT`，`bootDir`设为None以防止冲突。
            10. 安装 swi 交换机镜像到`ONL-IMAGES`分区: `installSwi()`
               - 优先从`installerConf.installer_dir`获取.swi, 其次压缩包，实际是压缩包。不允许有多个swi文件。
            11. 安装 kernel & initrd 到`ONL-BOOT`分区: `installLoader()`
                - 查找kernel，即所有带`kernel`关键字的文件名的文件。
                - 查找initrd，匹配`sysconfig.installer.grub`里的`[$PLATFORM.cpio.gz, onl-loader-initrd-amd64.cpio.gz]`注意次序，仅匹配一个。**可以通过此处为平台定制化initrd**。`sysconfig.installer.grub`的文件来源是`/etc/onl/sysconfig`(packages/base/all/vendor-config-onl/src/etc/onl/sysconfig/00-defaults.yml)以及`/mnt/onl/config/sysconfig`(安装时查无此文件)
                - 查找过程中优先从`installerConf.installer_dir`获取kernel或initrd, 其次压缩包，实际是压缩包。
                - 将查找的kernel和initrd拷贝到`ONL-BOOT`分区，initrd拷贝过程中重命名为`$installer_platform.cpio.gz`
            12. 安装 GRUB 配置到`ONL-BOOT`分区下的`grub/grub.cfg`: `installGrubCfg()`
                - kernel: `ctx['kernel'] = kernel['='] if type(kernel) == dict else kernel`, `kernel = platformConf['grub']['kernel']`
                - kernel args: `ctx['args'] = platformConf['grub']['args']`
                - initrd: `ctx['platform'] = installerConf.installer_platform`
                - grub serial: `ctx['serial'] = platformConf['grub']['serial']`
                - grub menu name: `ctx['boot_menu_entry'] = sysconfig.installer.menu_name`, 默认`Open Network Linux`
                - os name (echo Loading $os_name): `ctx['boot_loading_name'] = sysconfig.installer.os_name`, 默认`Open Network Linux`
                - onie boot uuid: `ctx['onie_boot_uuid'] = espFsUuid`
                - 上述`sysconfig`配置可通过修改`/etc/onl/sysconfig`(packages/base/all/vendor-config-onl/src/etc/onl/sysconfig/00-defaults.yml)或添加映射文件到`/mnt/onl/config/sysconfig`来配置。**可以通过此处为平台定制化Grub显示**。
                - 上述`platformConf`相关配置、即内核、grub串口可通过平台配置文件(src/python/`$platform.replace('-','_').replace('.','_')/__init__.py`)进行修改。**可以通过此处为平台定制化内核以及grub串口输出**。
                - 具体的配置内容: `packages/base/all/vendor-config-onl/src/python/onl/install/BaseInstall.py`, GRUB_TPL处
            13. 安装 boot-config 引导配置到`ONL-BOOT`分区: `installBootConfig()`
                - 将`boot-config`拷贝到`ONL-BOOT`分区。查找过程中优先从`installerConf.installer_dir`获取, 其次压缩包，实际是压缩包。
                - 设置`grubenv`(`ONL-BOOT`)中的变量`boot_config_default`为`boot-conifg`内容的base64格式内容。
            14. 安装 config/* 配置到`ONL-CONFIG`分区: `installOnlConfig()`
                - 将压缩包里`config/`开头的文件不带目录地拷贝到`ONL-CONFIG`分区根目录
                - 由于以不带目录的文件名作为目标文件名，所以分区上不会存在目录
                - 注意，若存在重复文件名，以第一次拷贝为准，重复将跳过拷贝到分区的动作
                - 实际上就拷贝了一个README文件！(builds/powerpc/installer/installed/builds/config/README)
            15. 安装 GRUB: `installGrub()`
                1. 若为UFEI且存在`sysconfig.installer.os_name`标签的启动项，通过efibootmgr删除该启动项
                2. 若为UEFI设置grub安装参数选项，如`--bootloader-id=ONL`，即在`/EFI/ONL/`下创建grubx64.efi。`--boot-directory`=`ONL-BOOT`所在分区。
                3. 若以设置`espPart`，挂载该分区，并通过`--efi-directory`安装grub到该分区上。实际上一般都是存在该分区，安装目标为该分区下的`/EFI/ONL/`。
                4. 通过efibootmgr添加启动项，`label`为`sysconfig.installer.os_name`
            16. 以`后(后置)安装模式`(Plugin.PLUGIN_PREINSTALL)运行插件: `runPlugins(Plugin.PLUGIN_POSTINSTALL)`
      5. 更新引导环境:
         1. `GRUB`，获取`installerConf`中的值设置到grub/grubenv里(`ONL-BOOT`所在分区)，若无值则删除变量:
            1. `onl_installer_md5`=`installerConf['installer_md5']`
            2. `onl_installer_version`=`installerConf['onl_version']`
            3. `onl_installer_url`=`installerConf['installer_url']`，该项一般为空值，删除
         2. `UBOOT`，获取`installerConf`中的值设置到onie uboot环境里，若无值则删除变量:
            1. `onl_installer_md5`=`installerConf['installer_md5']`
            2. `onl_installer_version`=`installerConf['onl_version']`
            3. `onl_installer_url`=`installerConf['installer_url']`，该项一般为空值，删除
      6. 清理和退出: `app.shutdown()`





## MISC

### /etc/inittab 来源

1. `builds/any/rootfs/$debian-name/sysvinit/overlay/etc/inittab`
2. 在rootfs制作时，`builds/amd64/rootfs/builds/Makefile`中指定rootfs配置为`$(ONL)/builds/any/rootfs/$(ONL_DEBIAN_SUITE)/standard/standard.yml`，其中包含overlays配置：
```yml
Configure:
  overlays:
    - ${ONL}/builds/any/rootfs/${ONL_DEBIAN_SUITE}/common/overlay
    - ${ONL}/builds/any/rootfs/${ONL_DEBIAN_SUITE}/${INIT}/overlay
```
3. 在rootfs制作时，`builds/amd64/rootfs/builds/Makefile`中导入的`rfs.mk`将调用`tools/onlrfs.py`，这将自动扫描并编译packages目录下的平台所需的包，然后安装编译后的包并联网安装所需的其他包，最后再进行配置并打包成rootfs。配置过程中会自动：
   1. 将`overlays`的目录拷贝到rootfs所在位置，包括`common/overlay/*`和`/etc/inittab`
      ```log
        builds/any/rootfs/buster/common/overlay/etc
        ├── adjtime
        ├── filesystems
        ├── inetd.conf
        ├── mtab.yml
        ├── profile.d
        │   └── onl-platform-current.sh
        ├── rc.local
        ├── rssh.conf
        ├── snmp
        │   └── snmpd.conf
        └── udev
            └── rules.d
                ├── 60-block.rules
                └── 60-net.rules

        5 directories, 10 files
        aiden@Xuanfq:~/workspace/onl/build$ tree builds/any/rootfs/buster/common/overlay/
        builds/any/rootfs/buster/common/overlay/
        ├── etc
        │   ├── adjtime
        │   ├── filesystems
        │   ├── inetd.conf
        │   ├── mtab.yml
        │   ├── profile.d
        │   │   └── onl-platform-current.sh
        │   ├── rc.local
        │   ├── rssh.conf
        │   ├── snmp
        │   │   └── snmpd.conf
        │   └── udev
        │       └── rules.d
        │           ├── 60-block.rules
        │           └── 60-net.rules
        └── sbin
            ├── pgetty
            └── watchdir
        
        builds/any/rootfs/buster/sysvinit/overlay/
        └── etc
            └── inittab
      ```
   2. 修改`inittab`中`ttys`相关配置
   3. 修改`inittab`中`console`相关配置



### boot & 开机自启动 (/etc/boot.d/boot) (串行)

/etc/inittab: `si0::sysinit:/etc/boot.d/boot`: (packages/base/all/boot.d/src/boot)

1. 导出环境变量：`export PATH=/sbin:/usr/sbin:/bin:/usr/bin`
2. 生成所有模块的依赖关系文件`/lib/modules/$(uname -r)/modules.dep(.bin)`，使系统能正确找到/加载模块及其依赖：`depmod -a`
3. 按字典顺序一次执行`/etc/boot.d/`下以数字开头的脚本：`for script in $(ls /etc/boot.d/[0-9]* | sort); do $script done`
4. 在开始执行rc.S脚本之前等待控制台刷新：`sleep 1`



### rc & 开机自启动 (/etc/init.d/rc) (串行/并发)

/etc/inittab: `si1::sysinit:/etc/init.d/rcS` -> link to `/lib/init/rcS`，即: `exec /etc/init.d/rc S` -> link to `/lib/init/rc S`

1. 设置环境变量，捕获错误退出情况
2. 确定当前和前一个运行级别
3. 加载系统配置
4. 检测并发启动能力（依赖于/etc/init.d/.depend.*文件）
5. 根据并发设置选择启动方法，onl中主要用`startpar`进行多并发
   1. startpar 读取 /etc/init.d/.depend.* 文件来了解服务之间的依赖关系
   2. 这些依赖文件由 insserv 工具生成， onlpm.py中生成deb包时存在 依赖项指定 ，安装服务脚本时存在 /usr/sbin/update-rc.d 调用。
6. 执行服务停止脚本（K开头的脚本）（切换运行级别或关机重启时才有用，开机时跳过），避免重复停止已经停止的服务。遍历`/etc/rc{runlevel}.d/K*`脚本，或`/etc/init.d/.depend.stop`。
7. 执行服务启动脚本（S开头的脚本），避免重复启动已经启动的服务。遍历`/etc/rc{runlevel}.d/S*`脚本，或运行级别S`/etc/init.d/.depend.boot`，或普通运行级别（2-5）的服务启动`/etc/init.d/.depend.start`。



### /etc/boot.d/ 来源

- `packages/base/all/boot.d/src/`: 
  - package: 
    - name: onl-bootd
    - path: packages/base/all/boot.d/PKG.yml
    - main: `- src : /etc/boot.d`
- `packages/base/all/vendor-config-onl/src/boot.d`
  - package:
    - name: onl-vendor-config-onl
    - path: packages/base/all/vendor-config-onl/PKG.yml
    - main: `- src/boot.d : /etc/boot.d`



















