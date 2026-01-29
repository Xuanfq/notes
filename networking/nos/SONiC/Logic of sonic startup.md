# Logic of sonic startup

SONiC启动逻辑


## 名词说明




## 步骤概述

1. BIOS/UEFI → GRUB2
   ↓
2. GRUB加载内核和initrd到内存
   ↓
3. 内核初始化，挂载initrd为临时根文件系统
   ↓
4. initrd中的init脚本执行：
   ├── 加载必要的驱动
   ├── 扫描存储设备
   ├── 挂载包含fs.squashfs的分区
   ├── 通过loop设备挂载fs.squashfs
   ↓
5. 切换到fs.squashfs作为新根文件系统
   ↓
6. 执行/sbin/init（systemd）
   ↓
7. 系统完全启动



### 1. GRUB阶段

```sh
menuentry '$demo_grub_entry' {      # SONiC-${demo_type}-${image_version}=SONiC-OS/DIAG-202505.1022539-92b55b412
        search --no-floppy --label --set=root $demo_volume_label                # demo_volume_label=SONiC-OS or SONiC-DIAG
        echo    'Loading $demo_volume_label $demo_type kernel ...'              # Loading SONiC-OS OS kernel ...
        insmod gzio
        if [ x$grub_platform = xxen ]; then insmod xzio; insmod lzopio; fi
        insmod part_msdos
        insmod ext2
        # root=/ (SONiC所在分区根目录)
        $GRUB_CFG_LINUX_CMD   /$image_dir/boot/vmlinuz-6.1.0-29-2-${arch} root=$grub_cfg_root rw $GRUB_CMDLINE_LINUX  \
                net.ifnames=0 biosdevname=0 \
                # loop=/image-202505.1022539-92b55b412/fs.squashfs loopfstype=squashfs
                loop=$image_dir/$FILESYSTEM_SQUASHFS loopfstype=squashfs                       \
                systemd.unified_cgroup_hierarchy=0 \
                apparmor=1 security=apparmor varlog_size=$VAR_LOG_SIZE usbcore.autosuspend=-1 $ONIE_PLATFORM_EXTRA_CMDLINE_LINUX
        echo    'Loading $demo_volume_label $demo_type initial ramdisk ...'     # Loading SONiC-OS OS initial ramdisk ...
        $GRUB_CFG_INITRD_CMD  /$image_dir/boot/initrd.img-6.1.0-29-2-${arch}
}
```


1. 通过`search`命令找到`SONiC-OS/DIAG`卷标的*分区*
2. 加载必要的*模块*（gzio、文件系统、分区支持等）
3. 加载*内核*`vmlinuz-6.1.0-29-2-${arch}`
4. 传递*内核启动参数*, loop=/image-xx/fs.squashfs 等
5. 加载`initrd.img-6.1.0-29-2-${arch}`到*内存*



### 2. 内核初始化阶段

1. 内核解压并*初始化硬件*
2. 从内存中加载`initrd`作为**临时根文件系统**
3. 执行`initrd`中的初始化脚本`/init`
   1. 基础环境初始化
      1. 设置PATH: `=/sbin:/usr/sbin:/bin:/usr/bin`
      2. 创建必要的目录结构: `/dev /root /sys /proc /tmp /var/lock`
   2. 挂载虚拟文件系统
      1. 系统信息/sys: `mount -t sysfs -o nodev,noexec,nosuid sysfs /sys`
      2. 进程信息/proc: `mount -t proc -o nodev,noexec,nosuid proc /proc`
   3. 初步解析内核参数
      1. `initramfs.clear`: 清屏参数, 执行`clear`
      2. `quiet`: 静默模式, 设置`quiet=yes`
   4. 设备文件系统准备
      1. /dev: `mount -t devtmpfs -o nosuid,mode=0755 udev /dev`
      2. 创建标准文件描述符符号链接
         - `ln -s /proc/self/fd /dev/fd`
         - `ln -s /proc/self/fd/0 /dev/stdin`
         - `ln -s /proc/self/fd/1 /dev/stdout`
         - `ln -s /proc/self/fd/2 /dev/stderr`
      3. 挂载伪终端设备: `mkdir /dev/pts && mount -t devpts -o noexec,nosuid,gid=5,mode=0620 devpts /dev/pts || true`
   5. 加载配置
      1. 加载架构配置: `. /conf/arch.conf`  # 设置DPKG_ARCH
      2. 设置模块加载选项: `export MODPROBE_OPTIONS="-qb"`
      3. 初始化*环境变量*并*导出* (根文件系统相关)
         - `export ROOT= ROOTDELAY= ROOTFLAGS= ROOTFSTYPE=`
         - `export LOOP= LOOPFLAGS= LOOPFSTYPE= LOOPOFFSET=`
         - `export IP= DEVICE= BOOT= BOOTIF= UBIMTD=`
         - `export break= init=/sbin/init readonly=y rootmnt=/root`
      4. 加载主配置: `. /conf/initramfs.conf` & `for conf in conf/conf.d/*; do [ -f "${conf}" ] && . "${conf}" done`
   6. 加载函数库 (/bin/sh): `. /scripts/functions`
   7. 详细解析内核参数, 重要参数如下:
      - `root`=*           # 根设备/文件系统
      - `rootflags`=*      # 挂载选项
      - `rootfstype`=*     # 文件系统类型
      - `loop`=*           # loop设备文件路径（用于squashfs）
      - `loopfstype`=*     # loop文件系统类型
      - `init`=*           # 指定init程序路径
      - `ro/rw`           # 只读/读写挂载
      - `debug`           # 调试模式
      - `break`=*         # 设置断点
      - `resume`=*        # 休眠恢复设备
   8. 执行初始化脚本
       1. 运行时环境设置
          - 挂载tmpfs: `mount -t tmpfs -o "nodev,noexec,nosuid,size=${RUNSIZE:-10%},mode=0755" tmpfs /run`
          - 创建目录: `mkdir -m 0700 /run/initramfs`
       2. 断点调试支持: `maybe_break top`
       3. 执行init-top脚本: `run_scripts /scripts/init-top`
       4. 加载内核模块: `load_modules`(通过`maybe_break modules`)
       5. 等待根设备延迟: `sleep "$ROOTDELAY"`(如果设置)
       6. 执行init-premount脚本: `run_scripts /scripts/init-premount`
   9.  挂载根文件系统
       1. 加载挂载脚本: `. /scripts/local`, `. /scripts/nfs`, `. /scripts/${BOOT}`
       2. 解析根设备: `parse_numeric "${ROOT}"`
       3. 执行挂载流程: `mount_top`, `mount_premount`, `mountroot`
   10. 挂载/usr分区
       1. 检查fstab: `read_fstab_entry /usr`
       2. 挂载/usr: `mountfs /usr`
   11. 挂载清理: `mount_bottom`, `nfs_bottom`, `local_bottom`
   12. 执行bottom脚本, 执行init-bottom脚本: `run_scripts /scripts/init-bottom`
   13. **切换到真实根文件系统**
       1. 移动/run目录: `mount -n -o move /run ${rootmnt}/run`
       2. 验证init程序: 通过`validate_init`函数检查
       3. 查找备用init: 尝试`/sbin/init`, `/etc/init`, `/bin/init`, `/bin/sh`
       4. 清理环境变量: 保留`init`, `rootmnt`, `drop_caps`
       5. 移动虚拟文件系统: `mount -n -o move /sys ${rootmnt}/sys`, `mount -n -o move /proc ${rootmnt}/proc`
       6. 切换到真实根文件系统: `exec run-init ${drop_caps} "${rootmnt}" "${init}" "$@"` (init=/sbin/init, rootmnt=/root, drop_caps="") (`Usage: run-init [-d CAP,CAP...] [-n] [-c CONSOLE_DEV] NEW_ROOT NEW_INIT [ARGS]`)


**Summary**:
- .




### 3. 真实根文件系统初始化阶段
























