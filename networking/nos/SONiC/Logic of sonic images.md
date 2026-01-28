# Logic of sonic images


## 制作和安装逻辑

### Image制作

Reference: [Build.md](./Build.md)



### Image结构

**解压Image**: `export extract=1; ./sonic-broadcom.bin`

```sh
aiden@Xuanfq:/tmp/SONiC$ export extract=1
aiden@Xuanfq:/tmp/SONiC$ ./sonic-broadcom.bin
Verifying image checksum ... OK.
Preparing image archive ... OK.
Image extracted to: /tmp/tmp.5Q583jwalp
# check extract logic: `head -n 100 ./sonic-broadcom.bin`
```

Image的类型有多种, e.g. onie (最多), raw, kvm etc.


#### onie

**Structure**:

- installer/
  - platforms/
    - `$platform-name`          # x86_64-xxxx-r0 -> device/@vendor@/@platform-name@/`installer.conf`
  - tests/                      # -> `installer/tests/`, 没有实际引用或调用
    - sample_machine.conf       # -> installer/tests/sample_machine.conf
    - test_read_conf.sh         # -> installer/tests/test_read_conf.sh, 读取和测试配置sample_machine.conf, 没有实际引用或调用
  - fs.zip/                     # 直接解压到installer目录下，无子目录包裹
    - boot/
      - vmlinuz-6.1.0-29-2-amd64        # 内核文件
      - initrd.img-6.1.0-29-2-amd64     # 文件系统
      - config-6.1.0-29-2-amd64         # 内核编译配置
      - System.map-6.1.0-29-2-amd64     # 内核编译时生成, 记录文件内核中的符号列表, 实际上并不是真正的System.map, 真正的在linux-image-<version>-dbg
    - dockerfs.tar.gz           # docker相关
    - fs.squashfs/              # 只读文件系统, 包括device数据
      - usr/share/sonic/device/
        - `$platform-name`/             # -> device/@vendor@/`@platform-name@`/
          - *
      - *
    - platform.tar.gz/          # platform/
      - common/
        - Packages.gz                                                   # debian control file for all the *.deb
        - sonic-platform-`@MACHINE-NAME-FULL-L@`_`1.0`_amd64.deb        # -> platform/sw-chip-name/device-vendor/device-name/
        - platform-modules-`@MACHINE-NAME-FULL-L@`_`1.0`_amd64.deb      # -> platform/sw-chip-name/device-vendor/device-name/
      - grub/
        - grub-pc-bin_2.06-13+deb12u1_amd64.deb                         # 
      - `$platform-name`/
        - sonic-platform-`@MACHINE-NAME-FULL-L@`_`1.0`_amd64.deb        # -> ../common/*.deb
        - platform-modules-`@MACHINE-NAME-FULL-L@`_`1.0`_amd64.deb      # -> ../common/*.deb 同上, 二选一, 或其他自定义deb名
  - sharch_body.sh              # -> `installer/sharch_body.sh`
  - install.sh                  # -> `installer/install.sh`, 替换了一些插值(`%%xxx%%`)
  - machine.conf                # 生成的配置, 包含`machine=@sw-chip-vendor@`和`platform=x86_64-@sw-chip-vendor@-r0`两个字段
  - onie-image.conf             # -> `onie-image.conf`
  - onie-image-*.conf           # -> `onie-image-arm64.conf` or `onie-image-armhf.conf`, 若非此架构则不存在
  - default_platform.conf       # -> `installer/default_platform.conf`
  - platform.conf               # -> platform/@sw-chip-vendor@/`platform-$arch.conf`或`platform.conf`
  - platforms_asic              # 生成的sw-chip相关的所有device的列表, 即platform-name列表, 通过device/@vendor@/@platform-name@/`platform_asic`识别


**配置覆盖顺序**:

1. machine.conf: `read_conf_file "./machine.conf"`
2. onie-image.conf: `. ./onie-image.conf`
3. onie-image-*.conf: `. ./onie-image-*.conf`
4. /etc/machine.conf: `read_conf_file "/etc/machine.conf"`
5. /host/machine.conf: `read_conf_file "/host/machine.conf"`
6. installer.conf: `. platforms/$onie_platform`
7. default_platform.conf: `. ./default_platform.conf`
8. platform.conf: `. ./platform.conf`


**SONiC分区中/host/machine.conf来源顺序**:

1. /etc/machine-build.conf
2. /etc/machine.conf



#### raw


#### kvm


#### aboot


#### dsc


#### bfb



### 磁盘分区结构

- /host/                                # 实际上是 分区的 根目录 /
  - grub/
    - fonts/
    - i386-pc/
    - locale/
    - grub.cfg
    - grubenv
  - image-202505.1022539-92b55b412/     # -> fs.zip
    - boot/
      - vmlinuz-6.1.0-29-2-amd64        # 内核文件
      - initrd.img-6.1.0-29-2-amd64     # 文件系统
      - config-6.1.0-29-2-amd64         # 内核编译配置
      - System.map-6.1.0-29-2-amd64     # 内核编译时生成, 记录文件内核中的符号列表, 实际上并不是真正的System.map, 真正的在linux-image-<version>-dbg
      - mmx64.efi                       # secure boot 时才有
      - shimx64.efi                     # secure boot 时才有
      - grubx64.efi                     # secure boot 时才有
    - docker/                   # -> fs.zip/dockerfs.tar.gz
    - platform/                 # -> fs.zip/platform.tar.gz
      - common/
        - Packages.gz                                                   # debian control file for all the *.deb
        - sonic-platform-`@MACHINE-NAME-FULL-L@`_`1.0`_amd64.deb        # -> platform/sw-chip-name/device-vendor/device-name/
        - platform-modules-`@MACHINE-NAME-FULL-L@`_`1.0`_amd64.deb      # -> platform/sw-chip-name/device-vendor/device-name/
      - grub/
        - grub-pc-bin_2.06-13+deb12u1_amd64.deb                         # 
      - `$platform-name`/
        - sonic-platform-`@MACHINE-NAME-FULL-L@`_`1.0`_amd64.deb        # -> ../common/*.deb 包括 sonic_platform-1.0-py3-none-any.whl
        - platform-modules-`@MACHINE-NAME-FULL-L@`_`1.0`_amd64.deb      # -> ../common/*.deb 同上, 二选一, 或其他自定义deb名
    - fs.squashfs               # 只读文件系统, 包括device数据
    - onie-support*.tar.bz2     # onie环境下安装时, 由`onie-support`命令生成
    - *                         # 其他文件, Option
  - image-202311.xxxxxxx-yyyyyyyyy/
  - machine.conf



### Image安装



1. 自解压image到临时目录`/tmp/tmp.xxx/`
2. 执行解压后的脚本`installer/install.sh`
   1. 检测所在的安装环境: `install_env=sonic|onie|build`
      - sonic: `[ -d "/etc/sonic" ]`
      - onie: `grep -Fxqs "DISTRIB_ID=onie" /etc/lsb-release > /dev/null`
      - build: 上诉都不符合时
   2. 切换工作目录到install.sh所在的目录: `cd $(dirname $0)`
   3. 依次加载配置文件:
      - machine.conf: `[ -r ./machine.conf ] && read_conf_file "./machine.conf"`
      - onie-image.conf: `[ -r ./onie-image.conf ] && . ./onie-image.conf`
      - onie-image-*.conf: `[ -r ./onie-image-*.conf ]; . ./onie-image-*.conf`
   4. 检测运行权限, 需为root用户
   5. 尝试从安装环境的配置中获取机器信息:
      1. 尝试`/etc/machine.conf`(onie): `[ -r /etc/machine.conf ] && read_conf_file "/etc/machine.conf"`
      2. 尝试`/host/machine.conf`(sonic): `[ -r /host/machine.conf ] && read_conf_file "/host/machine.conf"`
      3. build的安装环境则跳过
   6. 预设所需变量:
      1. `ONIE_PLATFORM_EXTRA_CMDLINE_LINUX`=""
      2. `ONIE_IMAGE_PART_SIZE`="%%ONIE_IMAGE_PART_SIZE%%" (Ref: ONIE_IMAGE_PART_SIZE="32768")
      3. `VAR_LOG_SIZE`=4096
   7. 加载设备平台安装配置, 可覆盖上述配置或变量值: `[ -r platforms/$onie_platform ] && . platforms/$onie_platform` (即`installer.conf`)
   8. 若为onie安装环境, 检测onie平台名是否在image所支持的设备列表中, 若不支持则询问是否强制安装: `! grep -Fxq "$onie_platform" platforms_asic`
   9. 若为onie安装环境, 预设所需变量:
      1. `onie_bin`=
      2. `onie_root_dir`=/mnt/onie-boot/onie
      3. `onie_initrd_tmp`=/
   10. 其他参数:
       1. `arch`="%%ARCH%%" (Ref: ="amd64")
       2. `demo_type`="%%DEMO_TYPE%%" (Ref: ="OS", or DIAG)
       3. `demo_part_size`=$ONIE_IMAGE_PART_SIZE (Ref: 见上方)
       4. `image_version`="%%IMAGE_VERSION%%" (Ref: ="202505.1022539-92b55b412")
       5. `timestamp`="$(date -u +%Y%m%d)"
       6. `demo_volume_label`="SONiC-${demo_type}"
       7. `demo_volume_revision_label`="SONiC-${demo_type}-${image_version}"
   11. 加载默认平台配置: `. ./default_platform.conf`
   12. 加载芯片平台配置, 可覆盖默认平台配置: `[ -r ./platform.conf ] && . ./platform.conf`
   13. 预设镜像存放目录名`image_dir`="image-$image_version"
   14. 准备安装环境:
       1. onie:
          1. 创建分区: `create_partition` (default_platform.conf or platform.conf)
             1. 若安装目标盘参数`blk_dev`为空, 查找onie所在磁盘作为SONiC安装目标盘: `blk_dev=$(echo $onie_dev | sed -e 's/[1-9][0-9]*$//' | sed -e 's/\([0-9]\)\(p\)/\1/'; cur_part=$(cat /proc/mounts | awk "{ if(\$2==\"/\") print \$1 }" | grep $blk_dev || true)`
             2. 若为uefi, 删除所有`$demo_volume_label`(SONiC-OS|SONiC-DIAG|ACS-OS(legacy_volume_label))相关分区和efi启动项, 查找第一个可用的分区编号`demo_part`并创建分区: `create_demo_uefi_partition $blk_dev`
             3. 若onie分区类型(`${onie_bin} onie-sysinfo -t`)为gpt分区类型, 删除所有`$demo_volume_label`(SONiC-OS|SONiC-DIAG|ACS-OS(legacy_volume_label))相关分区, 查找第一个可用的分区编号`demo_part`并创建分区: `create_demo_gpt_partition $blk_dev`
             4. 若onie分区类型(`${onie_bin} onie-sysinfo -t`)为msdos分区类型, 删除所有`$demo_volume_label`(SONiC-OS|SONiC-DIAG|ACS-OS(legacy_volume_label))相关分区, 查找第一个可用的分区编号`demo_part`并创建分区: `create_demo_msdos_partition $blk_dev`
          2. 挂载分区: `mount_partition` (default_platform.conf or platform.conf)
             1. 记录分区: `demo_dev=$(echo $blk_dev | sed -e 's/\(mmcblk[0-9]\)/\1p/')$demo_part; echo $blk_dev | grep -q nvme0 && demo_dev=$(echo $blk_dev | sed -e 's/\(nvme[0-9]n[0-9]\)/\1p/')$demo_part`
             2. 制作分区的文件系统ext4: `mkfs.ext4 -L $demo_volume_label $demo_dev`
             3. 创建临时目录`demo_mnt`并挂载该分区`demo_dev`到该目录
       2. sonic:
          1. 预设挂载点为`demo_mnt`: /host
          2. 获取当前SONiC版本`running_sonic_revision`=`"$(cat /proc/cmdline | sed -n 's/^.*loop=\/*image-\(\S\+\)\/.*$/\1/p')"` (i.e. 202505.1022539-92b55b412)
          3. 校验当前SONiC镜像是否损坏: `[ ! -d "$demo_mnt/image-$running_sonic_revision" ] && exit 1`
          4. 校验正在安装的SONiC镜像是否已经安装: `[ "$image_dir" = "image-$running_sonic_revision" ] && exit 0`
          5. 删除其他SONiC镜像, 当前SONiC除外: `for f in $demo_mnt/image-* ; do [ -d $f ] && [ "$f" != "$demo_mnt/image-$running_sonic_revision" ] && [ "$f" != "$demo_mnt/$image_dir" ] && rm -rf $f done`
       3. build:
          1. 预设挂载点为`demo_mnt`: build_raw_image_mnt
          2. 预设目标镜像`demo_dev`: $cur_wd/"target/sonic-broadcom.raw" (cur_wd=$pwd)
          3. 格式化目标镜像: `mkfs.ext4 -L $demo_volume_label $demo_dev`
          4. 创建挂载点并挂载: `mkdir $demo_mnt; mount -t auto -o loop $demo_dev $demo_mnt`
   15. 创建镜像存放目录并确保为空目录: `([ -d $demo_mnt/$image_dir ] && rm -rf $demo_mnt/$image_dir/*) || mkdir $demo_mnt/$image_dir`
   16. 解压文件到镜像存放目录:
       1. 若配置`docker_inram=on`, 则不对`dockerfs.tar.gz`进一步解压, 解压fs.zip: `unzip -o $INSTALLER_PAYLOAD -x "platform.tar.gz" -d $demo_mnt/$image_dir` (fs.zip -> platform.tar.gz)
       2. 否则对`dockerfs.tar.gz`及`platform.tar.gz`进一步解压, 解压fs.zip及dockerfs.tar.gz: `unzip -o $INSTALLER_PAYLOAD -x "$FILESYSTEM_DOCKERFS" "platform.tar.gz" -d $demo_mnt/$image_dir; mkdir -p $demo_mnt/$image_dir/$DOCKERFS_DIR; unzip -op $INSTALLER_PAYLOAD "$FILESYSTEM_DOCKERFS" | tar xz $TAR_EXTRA_OPTION -f - -C $demo_mnt/$image_dir/$DOCKERFS_DIR` (fs.zip -> platform.tar.gz) (fs.zip -> dockerfs.tar.gz) (dockerfs.tar.gz -> docker/)
       3. 解压`platform.tar.gz`: `mkdir -p $demo_mnt/$image_dir/platform; unzip -op $INSTALLER_PAYLOAD "platform.tar.gz" | tar xz $TAR_EXTRA_OPTION -f - -C $demo_mnt/$image_dir/platform` (platform.tar.gz -> platform/)
       4. 差别为是否对`dockerfs.tar.gz`进一步解压, 默认解压
   17. 若在onie环境上安装, 生成机器配置文件machine.conf到磁盘分区根目录:
       1. 如果存在`/etc/machine-build.conf`, 则从当前环境中提取`onie_`开头的变量并写入到目标磁盘根目录`$demo_mnt/machine.conf`: `[ -f /etc/machine-build.conf ] && set | grep ^onie | sed -e "s/='/=/" -e "s/'$//" > $demo_mnt/machine.conf`
       2. 否则，直接复制 /etc/machine.conf 到目标位置: `cp /etc/machine.conf $demo_mnt`
   18. 设置linux内核加载参数`EXTRA_CMDLINE_LINUX`以继承FIPS选项(SONiC升级, 可被ONIE_PLATFORM_EXTRA_CMDLINE_LINUX覆盖): `if grep -q '\bsonic_fips=1\b' /proc/cmdline && echo " $extra_cmdline_linux" | grep -qv '\bsonic_fips=.\b'; then extra_cmdline_linux="$extra_cmdline_linux sonic_fips=1"` (由GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX $extra_cmdline_linux"传递)
   19. 更新启动加载程序菜单: `bootloader_menu_config`
       1. onie
          1. 通过命令`onie-support`生成`$demo_mnt/$image_dir/onie-support*.tar.bz2`
          2. bootloader是UEFI:
             1. 若开启安全启动模式, 则安装`shim`而不是`grub`: `demo_install_uefi_shim "$demo_mnt" "$blk_dev"`
                1. 检查`/boot/efi`挂载情况, 若没挂载则尝试挂载: `! mount | grep -q "/boot/efi" && mount /boot/efi`
                2. 从`$blk_dev`(onie)所在磁盘1-8分区查找EFI系统所在分区, 一般是分区1: `sgdisk -i $p $blk_dev | grep -q C12A7328-F81F-11D2-BA4B-00A0C93EC93B && uefi_part=$p`
                3. 创建存放SONiC EFI的目录: `/boot/efi/EFI/$demo_volume_label`
                4. 检查secure boot所需的相关shim文件, 并将其拷贝到EFI目录下:
                   1. `$demo_mnt/$image_dir/boot/mmx64.efi`: `/boot/efi/EFI/$demo_volume_label/mmx64.efi`
                   2. `$demo_mnt/$image_dir/boot/shimx64.efi`: `/boot/efi/EFI/$demo_volume_label/shimx64.efi`
                   3. `$demo_mnt/$image_dir/boot/grubx64.efi`: `/boot/efi/EFI/$demo_volume_label/grubx64.efi`
                5. 创建UEFI启动项: `efibootmgr --quiet --create --label "$demo_volume_label" --disk $blk_dev --part $uefi_part --loader "/EFI/$demo_volume_label/shimx64.efi"`
             2. 否则安装UEFI`grub`: `demo_install_uefi_grub "$demo_mnt" "$blk_dev"`
                1. 检查`/boot/efi`挂载情况, 若没挂载则尝试挂载: `! mount | grep -q "/boot/efi" && mount /boot/efi`
                2. 从`$blk_dev`(onie)所在磁盘1-8分区查找EFI系统所在分区, 一般是分区1: `sgdisk -i $p $blk_dev | grep -q C12A7328-F81F-11D2-BA4B-00A0C93EC93B && uefi_part=$p`
                3. 安装grub, 用的是onie环境下的grub工具, 可通过`installer.conf`对其进行替换: `grub-install --no-nvram --bootloader-id="$demo_volume_label" --efi-directory="/boot/efi" --boot-directory="$demo_mnt" --recheck "$blk_dev"`
                4. 创建UEFI启动项: `grub=$(find /boot/efi/EFI/$demo_volume_label/ -name grub*.efi -exec basename {} \;); efibootmgr --quiet --create --label "$demo_volume_label" --disk $blk_dev --part $uefi_part --loader "/EFI/$demo_volume_label/$grub"`
          3. 否则安装legacy`grub`: `demo_install_grub "$demo_mnt" "$blk_dev"`
       2. 创建GRUB配置`grub.cfg`:
          1. 创建临时GRUB配置文件`grub_cfg`: `$(mktemp)`
          2. 加载芯片平台配置: `[ -r ./platform.conf ] && . ./platform.conf`
          3. 根据CPU类型预设禁用 c-states 的参数变量 CSTATES 以关闭CPU节能休眠达到最佳性能: (指在计算机的BIOS/UEFI设置中，关闭CPU的节能休眠状态（C-states）。这是一种通过牺牲功耗和发热来换取最高、最稳定性能（尤其是低延迟）的操作)
             - Intel: `CSTATES="processor.max_cstate=1 intel_idle.max_cstate=0"`
             - AMD: `CSTATES="processor.max_cstate=1 amd_idle.max_cstate=0"`
             - Others: `CSTATES=""`
          4. 检查和处理并导出环境变量`GRUB_SERIAL_COMMAND`(onie下50_onie_grub会调用): `${GRUB_SERIAL_COMMAND:-"serial --port=${CONSOLE_PORT} --speed=${CONSOLE_SPEED} --word=8 --parity=no --stop=1"}`
          5. 检查和处理并导出环境变量`GRUB_CMDLINE_LINUX`(onie下50_onie_grub会调用): `${GRUB_CMDLINE_LINUX:-"console=tty0 console=ttyS${CONSOLE_DEV},${CONSOLE_SPEED}n8 quiet $CSTATES"}`
          6. 添加 通用配置项 超时时间 与 串口控制台 的相关设置 到grub_cfg文件: `$GRUB_SERIAL_COMMAND \n terminal_input console serial \n terminal_output console serial \n set timeout=5`
          7. 添加 load_env, default="\${saved_entry}", next_entry, onie_entry 的相关设置 到grub_cfg文件
          8. 若是 DIAG :
             1. 设置默认启动项为 ONIE 到grub_cfg文件 (*即无法自动选择SONiC-DIAG*): `set default=ONIE`
             2. 设置 ONIE BOOT MODE 为 install 模式 以确保*自动引导到NOS安装模式*: `$onie_root_dir/tools/bin/onie-boot-mode -q -o install`
          9. 添加 SONiC OS/DIAG 菜单条目:
             1. 预设sonic菜单条目名`demo_grub_entry`: `=demo_volume_revision_label`
             2. 预设其他`onie_menuentry`/`grub_cfg_root`相关变量: 
                1. sonic env: 
                   1. 查找原有的SONiC菜单条目`old_sonic_menuentry`: `=$(cat /host/grub/grub.cfg | sed "/^menuentry '${demo_volume_label}-${running_sonic_revision}'/,/}/!d")`
                   2. 查找原有的GRUB配置根设备(通常是所在磁盘分区的UUID)`grub_cfg_root`: `=$(echo $old_sonic_menuentry | sed -e "s/.*root\=\(.*\)rw.*/\1/")`
                   3. 查找原有的onie菜单条目配置`onie_menuentry`: `=$(cat /host/grub/grub.cfg | sed "/menuentry ONIE/,/}/!d")`
                2. build env:
                   1. GRUB配置根目录`grub_cfg_root`: `=%%SONIC_ROOT%%` (此处对此进行替换files/image_config/platform/rc.local)
                3. onie env:
                   1. 查找SONiC所在分区的`uuid`: `=$(blkid "$demo_dev" | sed -ne 's/.* UUID=\"\([^"]*\)\".*/\1/p')`
                      1. 查找成功则使用uuid作为grub的root: `grub_cfg_root=UUID=$uuid`
                      2. 查找失败为空则使用所在分区设备名作为grub的root: `grub_cfg_root=$demo_dev`
             3. 在Debian默认路径/boot/efi/EFI/debian/下创建grub.cfg用于调用真正的包含sonic配置的完整grub.cfg文件:
                ```sh
                cat <<EOF > /boot/efi/EFI/debian/grub.cfg
                search --no-floppy --label --set=root $demo_volume_label  # SONiC-OS Label 所在磁盘分区
                set prefix=(\$root)'/grub'
                configfile \$prefix/grub.cfg
                EOF
                ```
             4. 添加 继承的FIPS选项`EXTRA_CMDLINE_LINUX` 到 LINUX命令加载参数`GRUB_CMDLINE_LINUX`: `="$GRUB_CMDLINE_LINUX $extra_cmdline_linux"`
             5. 预设 GRUB中设置linux内核的命令 `GRUB_CFG_LINUX_CMD`:
                1. UEFI && SECURE BOOT: `linuxefi`
                2. Others: `linux`
             6. 预设 GRUB中设置initrd文件系统的命令 `GRUB_CFG_INITRD_CMD`:
                1. UEFI && SECURE BOOT: `initrdefi`
                2. Others: `initrd`
             7. 添加 新的 SONiC OS/DIAG 菜单条目 到grub_cfg:
                ```sh
                menuentry '$demo_grub_entry' {
                        search --no-floppy --label --set=root $demo_volume_label
                        echo    'Loading $demo_volume_label $demo_type kernel ...'
                        insmod gzio
                        if [ x$grub_platform = xxen ]; then insmod xzio; insmod lzopio; fi
                        insmod part_msdos
                        insmod ext2
                        $GRUB_CFG_LINUX_CMD   /$image_dir/boot/vmlinuz-6.1.0-29-2-${arch} root=$grub_cfg_root rw $GRUB_CMDLINE_LINUX  \
                                net.ifnames=0 biosdevname=0 \
                                loop=$image_dir/$FILESYSTEM_SQUASHFS loopfstype=squashfs                       \
                                systemd.unified_cgroup_hierarchy=0 \
                                apparmor=1 security=apparmor varlog_size=$VAR_LOG_SIZE usbcore.autosuspend=-1 $ONIE_PLATFORM_EXTRA_CMDLINE_LINUX
                        echo    'Loading $demo_volume_label $demo_type initial ramdisk ...'
                        $GRUB_CFG_INITRD_CMD  /$image_dir/boot/initrd.img-6.1.0-29-2-${arch}
                }
                ```
             8. 若是 onie 环境, 调用onie下的 `50_onie_grub` 生成 *SONiC中的onie菜单条目到grub_cfg* 并 *更新ONIE中的grub.cfg*: `$onie_root_dir/grub.d/50_onie_grub >> $grub_cfg`
                - ONIE中grub配置被影响的有 GRUB_CMDLINE_LINUX & GRUB_SERIAL_COMMAND :
                  - `if [ -z "$GRUB_ONIE_SERIAL_COMMAND" ] || [ -z "$GRUB_CMDLINE_LINUX" ] ; then . $onie_root_dir/grub/grub-variables fi`
                  - 
                    ```sh
                      if echo -n "$GRUB_CMDLINE_LINUX" | grep -q ttyS ; then
                          cat <<EOF >> $grub_cfg
                      # begin: serial console config

                      $GRUB_ONIE_SERIAL_COMMAND
                      terminal_input serial
                      terminal_output serial

                      # end: serial console config
                      EOF
                    ```
                  - `onie_initargs="$GRUB_CMDLINE_LINUX"`
             9. 若是 sonic | build 环境下安装, 将 原有的sonic和onie的菜单条目 添加回grub_cfg:
                ```sh
                cat <<EOF >> $grub_cfg
                $old_sonic_menuentry
                $onie_menuentry
                EOF
                ``` 
             10. 若是 build 环境, 将 grub_cfg 复制到 `/host/grub.cfg` (分区根目录/下): `cp $grub_cfg $demo_mnt/grub.cfg; umount $demo_mnt`
             11. 若是 sonic | onie 环境:
                 1. 将 grub_cfg 复制到 SONiC下的 `/host/grub/grub.cfg` (分区根目录下/grub/grub.cfg): `cp $grub_cfg $onie_initrd_tmp/$demo_mnt/grub/grub.cfg`
                 2. 生成 grubenv 到 SONiC下的`/host/grub/grubenv` (分区根目录下/grub/grubenv): `[ ! -f "$onie_initrd_tmp/$demo_mnt/grub/grubenv" ] && grub-editenv "$onie_initrd_tmp/$demo_mnt/grub/grubenv" create`
   20. 设置NOS模式, 避免onie再次引导安装nos: `[ -x /bin/onie-nos-mode ] && /bin/onie-nos-mode -s`




**支持三种安装环境**:

- `SONiC` (在已有的 SONiC 系统中安装):
  - 主要是添加**镜像目录**/host/image-202505.1022539-92b55b412/和**启动项**;
  - 有多个SONiC启动项, 最新安装的在最上方, 可用于升级SONiC
- `ONIE` (在 Open Network Install Environment 中安装):
  - 比SONiC环境多一些, 磁盘分区唯一性/创建等管理, /host/machine.conf 生成
- `BUILD` (在构建系统中安装)





## MISC










