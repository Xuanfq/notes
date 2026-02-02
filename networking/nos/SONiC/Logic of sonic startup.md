# Logic of sonic startup

SONiC启动逻辑


## 名词说明




## 分区挂载


| Device Name | Size | Read Only | FS Type  | Mount Point | Origin File                   | Comment           |
| ----------- | ---- | --------- | -------- | ----------- | ----------------------------- | ----------------- |
| /dev/sda3   | 32G  | No        | ext4     | /host       |                               | SONiC分区         |
| /loop1      | 4G   | No        | ext4     | /var/log    | /host/disk-img/var-log.ext4   | SONiC日志         |
| /loop0      | /    | No        | squashfs | /           | /host/image-xx-yy/fs.squashfs | SONiC真实文件系统 |
|             |      |           |          |             |                               |                   |
|             |      |           |          |             |                               |                   |
|             |      |           |          |             |                               |                   |
|             |      |           |          |             |                               |                   |
|             |      |           |          |             |                               |                   |
|             |      |           |          |             |                               |                   |


**RAW LOG**:

```sh
root@sonic:/host# df -h
Filesystem      Size  Used Avail Use% Mounted on
udev            965M     0  965M   0% /dev
tmpfs           197M  7.5M  190M   4% /run
root-overlay     16G  1.9G   14G  13% /
/dev/sda3        16G  1.9G   14G  13% /host
/dev/loop1      3.9G   34M  3.7G   1% /var/log
tmpfs           984M     0  984M   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           4.0M     0  4.0M   0% /sys/fs/cgroup
overlay          16G  1.9G   14G  13% /var/lib/docker/overlay2/765684947a5593553b7fca42dddb3c9ee19710a222aa4218a99b341d368629d6/merged
overlay          16G  1.9G   14G  13% /var/lib/docker/overlay2/91689ac8699c73aae741052f0277de55a67e293dcf280d1c997c63a8e6276116/merged
overlay          16G  1.9G   14G  13% /var/lib/docker/overlay2/dc902a0ace15682ceb34b7da488febcf7da58cba7040d951f212dd53ae99bb41/merged
overlay          16G  1.9G   14G  13% /var/lib/docker/overlay2/d311491fb952d3c78cf75ebe289123a6cf03779975113e8c0ad6b8ff35dcb4e5/merged
overlay          16G  1.9G   14G  13% /var/lib/docker/overlay2/9f89174573d212b54c6e9f4be30e02695792c882236650d26b2910517a934ea1/merged
overlay          16G  1.9G   14G  13% /var/lib/docker/overlay2/817764598eed7f2795d11c5ed206579dccc78333d97343bf2a8639047bc62d55/merged
overlay          16G  1.9G   14G  13% /var/lib/docker/overlay2/5cbe0b2cb772765db19fa7c40cefa167674b8b5e5106c50d2b3a31a29c26b55d/merged
overlay          16G  1.9G   14G  13% /var/lib/docker/overlay2/05cb4a774c22b53771dd6d3bd4c6e8aba9ee1cc9be7c478ffa22d8934c2fc920/merged
overlay          16G  1.9G   14G  13% /var/lib/docker/overlay2/51b8d4cda74003cf1fbfed8af78ce1530edc2cc376315260f84b5bd587e1eb06/merged
overlay          16G  1.9G   14G  13% /var/lib/docker/overlay2/253615db841e86d331b20a872e6b9e3831b019b9379e509c747bef9bf09340cd/merged
root@sonic:/host# lsblk 
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
fd0      2:0    1     4K  0 disk 
loop0    7:0    0 347.9M  0 loop 
loop1    7:1    0     4G  0 loop /var/log
sda      8:0    0    16G  0 disk 
├─sda1   8:1    0     2M  0 part 
├─sda2   8:2    0   128M  0 part 
└─sda3   8:3    0  15.9G  0 part /host
sr0     11:0    1  1024M  0 rom 
```



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
2. 加载必要的*模块*（gzio,文件系统,分区支持等）
3. 加载*内核*`vmlinuz-6.1.0-29-2-${arch}`
4. 传递*内核启动参数*, loop=/image-xx/fs.squashfs 等
5. 加载`initrd.img-6.1.0-29-2-${arch}`到*内存*



### 2. 内核初始化阶段

1. 内核解压并*初始化硬件*
2. 从内存中加载`initrd`作为**临时根文件系统**
3. 执行`initrd`中的初始化脚本`/init`



### 3. 引导真实根文件系统阶段

通过执行`initrd`中的初始化脚本`/init`引导进入真实文件系统


1. 基础环境初始化
   1. 设置PATH: `=/sbin:/usr/sbin:/bin:/usr/bin`
   2. 创建必要的目录结构: `/dev /root /sys /proc /tmp /var/lock`
2. 挂载虚拟文件系统
   1. 挂载`sys`系统信息到`/sys`: `mount -t sysfs -o nodev,noexec,nosuid sysfs /sys`
   2. 挂载`proc`进程信息`/proc`: `mount -t proc -o nodev,noexec,nosuid proc /proc`
3. 初步解析内核参数
   1. `initramfs.clear`: 清屏参数, 执行`clear`
   2. `quiet`: 静默模式, 设置`quiet=yes`
4. 设备文件系统准备
   1. 挂载`dev`设备信息到`/dev`: `mount -t devtmpfs -o nosuid,mode=0755 udev /dev`
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
       - 挂载`tmpfs`到`/run`: `mount -t tmpfs -o "nodev,noexec,nosuid,size=${RUNSIZE:-10%},mode=0755" tmpfs /run`
       - 创建目录: `mkdir -m 0700 /run/initramfs`
    2. 断点调试支持: `maybe_break top`
    3. 执行init-top脚本: `run_scripts /scripts/init-top`
    4. 加载内核模块: `load_modules`(通过`maybe_break modules`)
    5. 等待根设备延迟: `sleep "$ROOTDELAY"`(如果设置)
    6. 执行init-premount脚本: `run_scripts /scripts/init-premount`
9. 挂载SONiC根磁盘与真实根文件系统
   1. 加载挂载脚本: `. /scripts/local`, `. /scripts/nfs`, `. /scripts/${BOOT:-local}`
   2. 解析根设备: `parse_numeric "${ROOT}"`
   3. 执行挂载流程: 
      1. `mount_top`
      2. `mount_premount`
      3. `mountroot`
         1. fsck检查和修复SONiC分区: `checkfs "${ROOT}" root "${FSTYPE}"` -> `logsave -a -s $FSCK_LOGFILE fsck $spinner $force $fix -T -t "$TYPE" "$DEV"` -> `fsck -a -T -t ext4 /dev/sda3`
         2. 挂载SONiC分区到`/root`: `mount ${roflag} ${FSTYPE:+-t "${FSTYPE}"} ${ROOTFLAGS} "${ROOT}" "${rootmnt?}"`, 即`mount -w -t ext4 "/dev/sda3" "/root"`
         3. 挂载loop根文件系统设备(`fs.squashfs`)到`/root`, 并移动`sonic`分区挂载到`/root/host`: `mount_loop_root`
            1. 创建`/host`目录, 并将SONiC分区挂载移动到`/host`: `mkdir -p /host && mount -o move "${rootmnt}" /host`
            2. 添加必要的模块以支持挂载fs.squashfs的loop设备, 并检查是否有loopoffset需要设置: `modprobe loop; modprobe "${FSTYPE:-squashfs}"; [ -n "${LOOPOFFSET}" ] && losetup -o "${LOOPOFFSET:-0}" "$(losetup -f)" "${loopfile}"`
            3. 挂载`fs.squashfs`到`/root`: `mount ${roflag} -o loop -t "${FSTYPE}" "${LOOPFLAGS}" "$loopfile" "${rootmnt}"`, 即`mount -w -o loop -t squashfs /host/image-xx-yy/fs.squashfs /root`
            4. 移动`sonic`分区挂载到`/root/host`: `[ -d "${rootmnt}/host" ] && mount -o move /host "${rootmnt}/host"`
10. 挂载真实文件系统/usr分区, 实际上无需挂载:
    1. 检查/root/etc/fstab(fs.squashfs)是否有需要挂载到/usf的条目: `read_fstab_entry /usr`
    2. 挂载/usr: `mountfs /usr`
11. 挂载清理: `mount_bottom`, `nfs_bottom`, `local_bottom`
12. 执行bottom脚本, 执行init-bottom脚本: `run_scripts /scripts/init-bottom`
13. **切换到真实根文件系统**
    1. 移动`/run`挂载到`/root/run`: `mount -n -o move /run ${rootmnt}/run`
    2. 验证init程序`/root/sbin/init`或查找备用init: 
       1. 通过`validate_init`函数检查init程序`/sbin/init`
       2. 失败则查找备用init: 尝试`/root/sbin/init`, `/root/etc/init`, `/root/bin/init`, `/root/bin/sh`
    3. 清理环境变量: 保留`init`, `rootmnt`, `drop_caps`
    4. 移动`/sys`挂载到`/root/sys`: `mount -n -o move /sys ${rootmnt}/sys`
    5. 移动`/proc`挂载到`/root/proc`: `mount -n -o move /proc ${rootmnt}/proc`
    6. 切换到真实根文件系统并初始化: `exec run-init ${drop_caps} "${rootmnt}" "${init}" "$@" <"${rootmnt}/dev/console" >"${rootmnt}/dev/console" 2>&1` (init=/sbin/init, rootmnt=/root, drop_caps="") (`Usage: run-init [-d CAP,CAP...] [-n] [-c CONSOLE_DEV] NEW_ROOT NEW_INIT [ARGS]`)



**核心步骤**:
1. 挂载 必要的系统运行设备与文件:
   1. /sys: `mount -t sysfs -o nodev,noexec,nosuid sysfs /sys`
   2. /proc: `mount -t proc -o nodev,noexec,nosuid proc /proc`
   3. /dev: `mount -t devtmpfs -o nosuid,mode=0755 udev /dev`
      - `ln -s /proc/self/fd /dev/fd`
      - `ln -s /proc/self/fd/0 /dev/stdin`
      - `ln -s /proc/self/fd/1 /dev/stdout`
      - `ln -s /proc/self/fd/2 /dev/stderr`
      - /dev/pts: `mkdir /dev/pts && mount -t devpts -o noexec,nosuid,gid=5,mode=0620 devpts /dev/pts || true`
   4. /run: `mount -t tmpfs -o "nodev,noexec,nosuid,size=${RUNSIZE:-10%},mode=0755" tmpfs /run`
2. 挂载 真实的核心分区设备与文件系统
   1. fsck -> /dev/sda3: `logsave -a -s $FSCK_LOGFILE fsck $spinner $force $fix -T -t "$TYPE" "$DEV"` -> `fsck -a -T -t ext4 /dev/sda3`
   2. /dev/sda3 -> /root: `mount ${roflag} ${FSTYPE:+-t "${FSTYPE}"} ${ROOTFLAGS} "${ROOT}" "${rootmnt?}"`
   3. /root -> /host: `mount -o move "${rootmnt}" /host`
   4. fs.squashfs -> /root: `mount ${roflag} -o loop -t "${FSTYPE}" "${LOOPFLAGS}" "$loopfile" "${rootmnt}"`
   5. /host -> /root/host: `[ -d "${rootmnt}/host" ] && mount -o move /host "${rootmnt}/host"`
3. 移动 挂载的必要的系统运行设备与文件 到 真实的核心文件系统:
   1. /dev -> /root/dev: `run_scripts /scripts/init-bottom` -> `mount -n -o move /dev "${rootmnt:?}/dev" || mount -n --move /dev "${rootmnt}/dev"`
   2. /run -> /root/run: `mount -n -o move /run ${rootmnt}/run`
   3. /sys -> /root/sys: `mount -n -o move /sys ${rootmnt}/sys`
   4. /proc -> /root/proc: `mount -n -o move /proc ${rootmnt}/proc`
4. 链接/切换 到 真实的文件系统, 以 /root 为 / , 以 /root/sbin/init 为初始程序, 启动初始化: `exec run-init ${drop_caps} "${rootmnt}" "${init}" "$@" <"${rootmnt}/dev/console" >"${rootmnt}/dev/console" 2>&1`



**核心代码**:
- 基于核心开源项目`initramfs-tools`修改以适配SONiC引导: `https://salsa.debian.org/kernel-team/initramfs-tools.git`
- 本质上是一个`RAMFS`, 用于引导进入真实的根文件系统
- 主要基于开源项目的基础上, 添加`loop`相关参数到cmdline的解析支持, 以及作为真实文件系统的`fs.squashfs`的`loop`设备挂载函数`mount_loop_root`



**关键初始化步骤**:
- 环境搭建: 创建 /dev , /sys , /proc 等必要目录，挂载 sysfs , proc , udev 等虚拟文件系统
- 命令行参数解析: 处理内核启动参数（如 root= , ro/rw , debug 等），设置对应环境变量控制启动行为
- 模块加载: 加载必要的驱动模块，确保硬件设备可用
- 根文件系统挂载: 根据配置挂载根文件系统（支持本地,NFS 等多种方式），并处理 /usr 等额外文件系统的挂载/
- 系统引导: 验证目标 init 程序存在后，切换到实际根文件系统并启动 init 进程



**关键流程节点**:
- 早期初始化: 运行 /scripts/init-top 脚本，准备启动环境。
- 预挂载阶段: 运行 /scripts/init-premount 脚本，处理挂载前的准备工作。
- 根文件系统挂载: 执行 mountroot 等函数挂载根文件系统。
- 后期初始化: 运行 /scripts/init-bottom 脚本，完成最终准备工作。
- 切换根文件系统: 通过 run-init 切换到实际根文件系统并启动 init 进程。




### 3. 真实根文件系统初始化阶段

真实根文件系统由`fs.squashfs`中的二进制程序`/sbin/init`引导初始化

`/sbin/init` --link--> `/lib/systemd/systemd`, 即 /sbin/init (PID 1)


```sh
root@sonic:~# systemctl list-dependencies multi-user.target
multi-user.target
 ├─auditd.service
 ├─config-chassisdb.service
 ├─config-setup.service
 ├─config-topology.service
 ├─containerd.service
 ├─cron.service
 ├─database-chassis.service
 ├─database.service
 ├─dbus.service
 ├─determine-reboot-cause.service
 ├─docker.service
 ├─fstrim.timer
 ├─kdump-tools.service  # `/etc/init.d/kdump-tools start`
 ├─kexec-load.service
 ├─kexec.service
 ├─logrotate-config.service
 ├─monit.service
 ├─netfilter-persistent.service
 ├─ntp.service
 ├─pcie-check.service
 ├─ras-mc-ctl.service
 ├─rasdaemon.timer
 ├─rc-local.service
 ├─rsyslog.service
 ├─smartmontools.service
 ├─ssh.service
 ├─sysfsutils.service
 ├─sysstat.service
 ├─system-health.service
 ├─systemd-ask-password-wall.path
 ├─systemd-logind.service
 ├─systemd-update-utmp-runlevel.service
 ├─systemd-user-sessions.service
 ├─updategraph.service
 ├─warmboot-finalizer.service
 ├─watchdog-control.service
 ├─basic.target            # ! Importance Point
 │ ├─networking.service       # `/usr/share/ifupdown2/sbin/start-networking start`
 │ ├─tmp.mount
 │ ├─paths.target
 │ ├─sysinit.target        # ! Importance Point
 │ │ ├─apparmor.service
 │ │ ├─dev-hugepages.mount
 │ │ ├─dev-mqueue.mount
 │ │ ├─haveged.service
 │ │ ├─kmod-static-nodes.service
 │ │ ├─proc-sys-fs-binfmt_misc.automount
 │ │ ├─sys-fs-fuse-connections.mount
 │ │ ├─sys-kernel-config.mount
 │ │ ├─sys-kernel-debug.mount
 │ │ ├─sys-kernel-tracing.mount
 │ │ ├─systemd-ask-password-console.path
 │ │ ├─systemd-binfmt.service
 │ │ ├─systemd-boot-system-token.service
 │ │ ├─systemd-hwdb-update.service
 │ │ ├─systemd-journal-flush.service
 │ │ ├─systemd-journald.service
 │ │ ├─systemd-machine-id-commit.service
 │ │ ├─systemd-modules-load.service
 │ │ ├─systemd-pstore.service
 │ │ ├─systemd-random-seed.service
 │ │ ├─systemd-sysctl.service
 │ │ ├─systemd-sysusers.service
 │ │ ├─systemd-tmpfiles-setup-dev.service
 │ │ ├─systemd-tmpfiles-setup.service
 │ │ ├─systemd-udev-trigger.service
 │ │ ├─systemd-udevd.service
 │ │ ├─systemd-update-utmp.service
 │ │ ├─cryptsetup.target
 │ │ ├─local-fs.target
 │ │ │ └─systemd-remount-fs.service
 │ │ └─swap.target
 │ ├─slices.target
 │ │ ├─-.slice
 │ │ └─system.slice
 │ ├─sockets.target
 │ │ ├─dbus.socket
 │ │ ├─docker.socket
 │ │ ├─systemd-initctl.socket
 │ │ ├─systemd-journald-audit.socket
 │ │ ├─systemd-journald-dev-log.socket
 │ │ ├─systemd-journald.socket
 │ │ ├─systemd-udevd-control.socket
 │ │ └─systemd-udevd-kernel.socket
 │ └─timers.target
 │   ├─aaastatsd.timer
 │   ├─apt-daily-upgrade.timer
 │   ├─apt-daily.timer
 │   ├─e2scrub_all.timer
 │   ├─featured.timer
 │   ├─fstrim.timer
 │   ├─hostcfgd.timer
 │   ├─logrotate.timer
 │   ├─process-reboot-cause.timer
 │   ├─systemd-tmpfiles-clean.timer
 │   └─tacacs-config.timer
 ├─getty.target
 │ ├─getty-static.service
 │ ├─getty@tty1.service
 │ └─serial-getty@ttyS0.service
 ├─remote-fs.target
 └─sonic.target            # ! Importance Point
   ├─aaastatsd.timer
   ├─backend-acl.service
   ├─bgp.service
   ├─caclmgrd.service
   ├─copp-config.service
   ├─dhcp_relay.service
   ├─eventd.service
   ├─featured.timer
   ├─gbsyncd.service
   ├─hostcfgd.timer
   ├─hostname-config.service
   ├─interfaces-config.service
   ├─macsec.service
   ├─mux.service
   ├─nat.service
   ├─ntp-config.service
   ├─procdockerstatsd.service
   ├─radv.service
   ├─rsyslog-config.service
   ├─swss.service
   ├─syncd.service
   ├─tacacs-config.timer
   └─teamd.service
```


























