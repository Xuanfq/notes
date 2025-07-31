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
- postinstall.sh
- preinstall.sh
- autoperms.sh
- installer.sh  -> installer-XXXXXX



### Image安装

1. 安装器(自解压脚本)校验和分离压缩包后:
   1. 导出环境变量: `export SFX_BLOCKSIZE SFX_BLOCKS SFX_PAD SFX_UNZIP SFX_LOOP SFX_PIPE SFX_LAZY SFX_PERMS`
   2. 将安装脚本`installer.sh`重命名成`install-XXXXXX`后，调用命令进行安装`eval "$tmp_install" $dashx "$_ZIP"`。
      
      实际上不能在`bash -x`/`set -x`的环境下安装，因为这在参数在`eval "$tmp_install" $dashx "$_ZIP"`会将`$dashx`(即-x)作为参数传入安装脚本`installer.py`赋给压缩包变量: `installer_zip=$1`，这将导致使用无效且错误的zip压缩包，导致无法安装。

2. 初始化和架构检查阶段: 
   1. 比对预设的安装器架构`IARCH` 以及 onie环境的架构`uname -m`，根据架构设置其中之一变量`ARCH_PPC=$ARCH;ARCH_X86=$ARCH;ARCH_ARM=$ARCH`
   2. 初始化常用变量
3. 环境检测和设置阶段: 
   1. 检查`grub`或`uboot`环境变量是否存在`onl_installer_debug`，若有则设置为debug模式: `set -x`
   2. 根据onie环境设置变量，若已存在于环境变量则跳过，无则通过`onie-sysinfo`获取，最者用onie的`. /etc/machine.conf`设置: 
      1. onie_platform: onie-sysinfo -p
      2. onie_arch: onie-sysinfo -c
   3. 根据上诉设置的onie_platform的值判断检测是否在ONIE环境下，根据不同环境设置 (x86下必须为onie环境否则退出): 
      1. 日志输出方式：`installer_say`, onie为`echo "$@" > /dev/console;`, 其他为`echo "* $@";`
      2. 安装结束后的清理方法: `installer_cleanup`, onie下需要重启
4. 临时文件系统准备阶段: 查找或创建临时文件系统，导出临时文件系统目录`TMPDIR`
5. 安装包解压阶段:
   1. 定义解压函数，根据不同情况选择解压方式，解压的文件到当前目录，同时排除SFX_PAD(pad.bin)的解压: `installer_unzip`
   2. 执行解压，提取ram根文件系统`$initrd_archive`: `installer_unzip $installer_zip $installer_list`
   3. 检查`grub`或`uboot`环境变量是否存在`onl_installer_unpack_only`，若有则设置为仅unpack模式，由于已完成解压，直接退出退出 
6. 根文件系统准备阶段: 
   1. 创建根目录: `initrd-XXXXXX`
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
8. 预安装阶段: 
9. 主安装阶段: 
10. 后安装阶段:
11. 清理和重启阶段: 






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



















