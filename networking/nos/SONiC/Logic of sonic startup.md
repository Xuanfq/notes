# Logic of sonic startup

SONiC启动逻辑


## 名词说明




## 分区挂载


| Device Name | Size | Read Only | FS Type  | Mount Point | Origin File                       | Comment           |
| ----------- | ---- | --------- | -------- | ----------- | ----------------------------------| ----------------- |
| /dev/sda3   | 32G  | No        | ext4     | /host       |                                   | SONiC分区                                                    |
| /loop0      | /    | Yes       | squashfs | /           | /host/image-xx-yy/fs.squashfs     | SONiC真实文件系统 (也是下方OverlayFS的只读层,OverlayFS-lowerdir)  |
| root-overlay| /    | Yes       | squashfs | /           | /                                 | SONiC真实文件系统-只读层,OverlayFS-lowerdir                     |
| root-overlay| /    | No        | ext4     | /           | /host/image-xx-yy/rw/             | SONiC真实文件系统-可写层,OverlayFS-upperdir                     |
| root-overlay| /    | No        | ext4     | /           | /host/image-xx-yy/work/           | SONiC真实文件系统-内部工作目录,OverlayFS-workdir                 |
| (bind)      | /    | No        | ext4     | /var/lib/docker/   | /host/image-xx-yy/docker/  | SONiC Docker存储路径                                          |
| (bind)      | /    | No        | ext4     | /boot       | /host/image-xx-yy/boot/           | SONiC Image启动配置存储路径                                    |
| /loop1      | 4G   | No        | ext4     | /var/log    | /host/disk-img/var-log.ext4       | SONiC日志          |
|             |      |           |          |             |                                   |                   |
|             |      |           |          |             |                                   |                   |


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
               #  apparmor=1 security=apparmor varlog_size=4096 usbcore.autosuspend=-1
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


[详细步骤-参阅Reference目录](./Reference/初始化引导-initramfs-tools.md#启动脚本)



**启动流程**: (/usr/share/initramfs-tools/init)
1. sysfs: `mount -t sysfs -o nodev,noexec,nosuid sysfs /sys`
2. procfs: `mount -t proc -o nodev,noexec,nosuid proc /proc`
3. devtmpfs: `mount -t devtmpfs -o nosuid,mode=0755 udev /dev`
   1. /dev/fd -> /proc/self/fd: `ln -s /proc/self/fd /dev/fd`
   2. /dev/stdin -> /proc/self/fd/0: `ln -s /proc/self/fd/0 /dev/stdin`
   3. /dev/stdout -> /proc/self/fd/1: `ln -s /proc/self/fd/1 /dev/stdout`
   4. /dev/stderr -> /proc/self/fd/2: `ln -s /proc/self/fd/2 /dev/stderr`
   5. /dev/pts: `mount -t devpts -o noexec,nosuid,gid=5,mode=0620 devpts /dev/pts || true`
4. . /conf/arch.conf
5. . /conf/initramfs.conf
6. . /conf/conf.d/*
7. . /scripts/functions
8. tmpfs: `mount -t tmpfs -o "nodev,noexec,nosuid,size=${RUNSIZE:-10%},mode=0755" tmpfs /run`
9. `init-top`: 此目录中的脚本是在 sysfs 和 procfs 挂载后首先执行的脚本。它还会运行 udev 钩子来填充 /dev 树（udev 将一直运行到 init-bottom）。
10. `init-premount`: 发生在由钩子和 `/etc/initramfs-tools/modules` 指定的模块加载完成之后。
11. . /scripts/local
12. . /scripts/nfs
13. . /scripts/${BOOT} (BOOT=local/nfs)
14. `local-top`/`nfs-top`: 这些脚本执行后，rootdevice 节点应已存在（本地），或者网络接口应可使用（NFS）。
15. `local-block`: 这些脚本通过本地块设备的名称调用。这些脚本执行后，该设备节点应存在。如果 local-top 或 local-block 脚本未能创建所需的设备节点，将定期调用 local-block 脚本来重试。如，设置根设备为USB设备，这时为异步发现设备，或需要一定时间去发现该设备。
16. `local-premount`/`nfs-premount`: 在根设备的完整性已得到验证（本地）或网络接口已启动（NFS）之后，但在实际的根文件系统被挂载之前运行。
17. local_mount_root: 挂载根分区，如 /dev/sda3 到 root(/)
    1. fsck -> /dev/sda3: `logsave -a -s $FSCK_LOGFILE fsck $spinner $force $fix -T -t "$TYPE" "$DEV"` -> `fsck -a -T -t ext4 /dev/sda3`
    2. /dev/sda3 -> /root: `mount ${roflag} ${FSTYPE:+-t "${FSTYPE}"} ${ROOTFLAGS} "${ROOT}" "${rootmnt?}"`
    3. mount_loop_root: 引导挂载真实文件系统loop文件, 并将原始根分区移动到/host下, 无论是本地FS挂载还是网络FS挂载都支持
       1. /root -> /host: `mount -o move "${rootmnt}" /host` (mount_loop_root)
       2. fs.squashfs -> /root: `mount ${roflag} -o loop -t "${FSTYPE}" "${LOOPFLAGS}" "$loopfile" "${rootmnt}"` (mount_loop_root)
       3. /host -> /root/host: `[ -d "${rootmnt}/host" ] && mount -o move /host "${rootmnt}/host"` (mount_loop_root)
18. `local-bottom`/`nfs-bottom`: 会在 rootfs 已挂载（本地）或 NFS 根共享已挂载后运行。
19. `init-bottom`: 是在procfs和sysfs被移至实际根文件系统之前要执行的最后一批脚本，之后执行权将移交给此时应能在已挂载的根文件系统中找到的init二进制文件。udev会被停止。
    1. /dev -> /root/dev [udev]: `run_scripts /scripts/init-bottom` -> `mount -n -o move /dev "${rootmnt:?}/dev" || mount -n --move /dev "${rootmnt}/dev"`
20. `mount -n -o move /run ${rootmnt}/run`
21. /run -> /root/run: `mount -n -o move /run ${rootmnt}/run`
22. /sys -> /root/sys: `mount -n -o move /sys ${rootmnt}/sys`
23. /proc -> /root/proc: `mount -n -o move /proc ${rootmnt}/proc`
24. 链接/切换 到 真实的文件系统, 以 /root 为 / , 以 /root/sbin/init 为初始程序, 启动初始化: `exec run-init ${drop_caps} "${rootmnt}" "${init}" "$@" <"${rootmnt}/dev/console" >"${rootmnt}/dev/console" 2>&1`



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
 ├─rc-local.service     # `/etc/rc.local start`
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


#### /etc/rc.local

- rc-local.service
  - After: network.target
  - ExecStart: /etc/rc.local start

1. 初始化阶段
   1. 从`/etc/sonic/sonic_version.yml`读取SONiC版本号`SONIC_VERSION`(i.e. 202311.986446-3efdc0000): `SONIC_VERSION=$(cat /etc/sonic/sonic_version.yml | grep "build_version" | sed -e "s/build_version: //g;s/'//g")`
   2. 检查`/host/image-${SONIC_VERSION}/sonic-config/sonic-environment`是否存在, 如果存在, 将其移动到`/etc/sonic/sonic-environment`
2. 主执行流程
   1. 记录启动日志: `logger "SONiC version ${SONIC_VERSION} starting up..."`
   2. 检查`/host/machine.conf`是否存在, 如果 不存在 , 说明从其他 NOS 启动到 SONiC, 并从 ONIE 中提取并生成配置
      1. 查找onie所在分区`onie_dev`: `$(blkid | grep ONIE-BOOT | head -n 1 | awk '{print $1}' |  sed -e 's/:.*$//')`
      2. 挂载onie分区到 `/mnt/onie-boot`
      3. 以库的方式加载配置`onie_grub_cfg=/mnt/onie-boot/onie/grub/grub-machine.cfg`: `. ./$onie_grub_cfg`
      4. 将onie配置(onie_*=xxx)并写入`/host/machine.conf`: `grep = $onie_grub_cfg | sed -e 's/onie_//' -e 's/=.*$//' | while read var; do eval val='$'onie_$var; echo "onie_${var}=${val}" >> /host/machine.conf done`
      5. 设置`grub_installation_needed="TRUE"`标志
      6. 执行`migrate_nos_configuration`函数迁移配置, 迁移旧的核心配置到目录`/host/migration`:
         1. 创建空白迁移目录`/host/migration`: `rm -rf /host/migration; mkdir -p /host/migration`
         2. 提取包含迁移文件的前一个NOS分区:
            1. 提取命令行参数`cmdline`中的核心迁移参数:
               1. NOS所在分区`nos_dev`: `nos-config-part=*`, `nos_dev="${x#nos-config-part=}"`
               2. 是否配置sonic快速重启`sonic_fast_reboot`: `SONIC_BOOT_TYPE=fast*`, `sonic_fast_reboot=true`
            2. 若`cmdline`中没有需要迁移的前一个NOS分区`nos_dev`, 则*跳过接下来的操作*
            3. 移除`/host/grub/grub.cfg`中上述`cmdline`的相关配置:
               1. `nos-config-part=*`: `sed -r -i.bak "s/nos-config-part=[^[:space:]]+//" /host/grub/grub.cfg`
               2. `ssd-upgrader-part=`: `sed -r -i.bak "s/ssd-upgrader-part=[^[:space:]]+//" /host/grub/grub.cfg`
            4. 定义需要迁移的文件的相关参数及其值:
               - `NOS_DIR`=/mnt/nos_migration
               - MG_GZFILE=$NOS_DIR/minigraph.xml.gz.base64.txt
               - MG_FILE=$NOS_DIR/`minigraph.xml`
               - ACL_GZFILE=$NOS_DIR/acl.json.gz.base64.txt
               - ACL_FILE=$NOS_DIR/`acl.json`
               - PORT_CONFIG_GZFILE=$NOS_DIR/port_config.json.gz.base64.txt
               - PORT_CONFIG_FILE=$NOS_DIR/`port_config.json`
               - GOLDEN_CONFIG_DB_GZFILE=$NOS_DIR/golden_config_db.json.gz.base64.txt
               - GOLDEN_CONFIG_DB_FILE=$NOS_DIR/`golden_config_db.json`
               - SNMP_FILE=$NOS_DIR/`snmp.yml`
            5. 挂载前一个需要迁移的NOS分区: `mkdir -p $NOS_DIR && mount $nos_dev $NOS_DIR`
            6. 解码并解压需要迁移的文件:
               - MG_GZFILE: `[ -f $MG_GZFILE ] && /usr/bin/base64 -d $MG_GZFILE | /bin/gunzip > $MG_FILE`
               - ACL_GZFILE: `[ -f $ACL_GZFILE ] && /usr/bin/base64 -d $ACL_GZFILE | /bin/gunzip > $ACL_FILE`
               - PORT_CONFIG_GZFILE: `[ -f $PORT_CONFIG_GZFILE ] && /usr/bin/base64 -d $PORT_CONFIG_GZFILE | /bin/gunzip > $PORT_CONFIG_FILE`
               - GOLDEN_CONFIG_DB_GZFILE: `[ -f $GOLDEN_CONFIG_DB_GZFILE] && /usr/bin/base64 -d $GOLDEN_CONFIG_DB_GZFILE| /bin/gunzip > $GOLDEN_CONFIG_DB_FILE`
            7. 拷贝需要迁移的文件到创建的空白迁移目录`/host/migration`(不存在的文件跳过拷贝):
               - `mgmt_interface.cfg`: nos_migration_import $NOS_DIR/mgmt_interface.cfg /host/migration
               - `minigraph.xml`: nos_migration_import $MG_FILE /host/migration
               - `acl.json`: nos_migration_import $ACL_FILE /host/migration
               - `port_config.json`: nos_migration_import $PORT_CONFIG_FILE /host/migration
               - `golden_config_db.json`: nos_migration_import $GOLDEN_CONFIG_DB_FILE /host/migration
               - `snmp.yml`: nos_migration_import $SNMP_FILE /host/migration
            8. 若配置了sonic快速重启`sonic_fast_reboot`, 则迁移相关配置文件到`/host/fast-reboot`目录: mkdir -p /host/fast-reboot
               - `arp.json`: nos_migration_import $NOS_DIR/arp.json /host/fast-reboot
               - `fdb.json`: nos_migration_import $NOS_DIR/fdb.json /host/fast-reboot
               - `default_routes.json`: nos_migration_import $NOS_DIR/default_routes.json /host/fast-reboot
            9. 取消挂载需要迁移的NOS分区并移除该目录: `umount $NOS_DIR; rmdir $NOS_DIR`
            10. 若存在保留MAC的配置`mgmt_interface.cfg`, 则更新管理网口MAC地址, 使用ethtool更新eth0的MAC地址以及EEPROM, 以便后续重启使用NOS的MAC地址: `[ -f /host/migration/mgmt_interface.cfg ] && update_mgmt_interface_macaddr /host/migration/mgmt_interface.cfg`
            11. 设置迁移标志`migration`, 用于下方流程判断迁移所使用的方法以迁移到新的NOS上: `="TRUE"`
      7. 卸载onie分区
   3. 加载`/host/machine.conf`: `. /host/machine.conf`
   4. 编程控制台串口速度: `program_console_speed`
      1. 从内核命令行提取控制台波特率
         1. 默认`9600`
         2. 或从`console=ttyS0,115200`等参数提取
      2. 修改`/lib/systemd/system/serial-getty@.service`
         1. 首次启动：替换`--keep-baud`参数
         2. 后续启动：更新波特率值
      3. 执行`systemctl daemon-reload`重载配置
   5. 首次启动处理, 检查第一次启动的标志文件`/host/image-${SONIC_VERSION}/platform/firsttime`文件是否存在, 存在则:
      1. 确定平台类型`platform`:
         1. arm: `[ -n "$aboot_platform" ] && platform=$aboot_platform`
         2. x86: `[ -n "$onie_platform" ] && platform=$onie_platform`
         3. 都不存在则*删除标志文件并退出脚本*
      2. 配置文件迁移, 按优先级尝试迁移配置到`/etc/sonic/old_config/`:
         1. 若存在目录`/host/old_config`(配置文件放到了/host/old_config/目录下了):
            1. 移动该目录到`/etc/sonic/`: `mv -f /host/old_config /etc/sonic/`
            2. 移除旧子配置`old_config`: `rm -rf /etc/sonic/old_config/old_config`
            3. 创建迁移标志`/tmp/pending_config_migration`
         2. 若存在文件`/host/minigraph.xml`(配置文件放到了/host/目录下了):
            1. 创建旧配置目录`/etc/sonic/old_config/`: `mkdir -p /etc/sonic/old_config`
            2. 移动配置文件到旧配置目录:
               1. /host/minigraph.xml: `mv /host/minigraph.xml /etc/sonic/old_config/`
               2. /host/acl.json: `[ -f /host/acl.json ] && mv /host/acl.json /etc/sonic/old_config/`
               3. /host/port_config.json: `[ -f /host/port_config.json ] && mv /host/port_config.json /etc/sonic/old_config/`
               4. /host/snmp.yml: `[ -f /host/snmp.yml ] && mv /host/snmp.yml /etc/sonic/old_config/`
               5. /host/golden_config_db.json: `[ -f /host/golden_config_db.json ] && mv /host/golden_config_db.json /etc/sonic/old_config/`
            3. 创建迁移标志`/tmp/pending_config_migration`
         3. 若存在目录`/host/migration`及关键文件`/host/migration/minigraph.xml`(通过上方步骤刚从分区上迁移的, 配置文件放到了/host/migration/目录下了):
            1. 创建旧配置目录`/etc/sonic/old_config/`: `mkdir -p /etc/sonic/old_config`
            2. 移动配置文件到旧配置目录:
               1. /host/migration/minigraph.xml: `mv /host/migration/minigraph.xml /etc/sonic/old_config/`
               2. /host/migration/acl.json: `[ -f /host/migration/acl.json ] && mv /host/acl.json /etc/sonic/old_config/`
               3. /host/migration/port_config.json: `[ -f /host/migration/port_config.json ] && mv /host/port_config.json /etc/sonic/old_config/`
               4. /host/migration/snmp.yml: `[ -f /host/migration/snmp.yml ] && mv /host/snmp.yml /etc/sonic/old_config/`
               5. /host/migration/golden_config_db.json: `[ -f /host/migration/golden_config_db.json ] && mv /host/golden_config_db.json /etc/sonic/old_config/`
            3. 创建迁移标志`/tmp/pending_config_migration`
         4. 以上都不存在, 即不需要迁移, 创建标记文件`/tmp/pending_config_initialization`
      3. 向平台通知首次启动状态, 以便将其用于记录重启原因`reboot-cause`, 通过创建文件`/tmp/notify_firstboot_to_platform`的方式进行通知
      4. 创建`/host/reboot-cause/platform`目录用于记录某些platform的重启原因: `[ ! -d /host/reboot-cause/platform ] && mkdir -p /host/reboot-cause/platform`
      5. 安装`platform-name-device`的`sonic-platform`实现包`*.deb`:
         1. 若存在文件`/host/image-$SONIC_VERSION/platform/common/Packages.gz`, 则仅使用基础软件源与`apt`工具，以支持懒加载式软件包依赖管理
            1. 将原始的apt源移动到临时文件: `mv /etc/apt/sources.list /etc/apt/sources.list.rc-local`
            2. 添加`platform-name-device`的本地目录`/host/image-$SONIC_VERSION/platform/common`作为源: `echo "deb [trusted=yes] file:///host/image-$SONIC_VERSION/platform/common /" > /etc/apt/sources.list.d/sonic_debian_extension.list`
            3. 更新apt: `LANG=C DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::Retries=1 update`
            4. 安装`platform-name-device`的`sonic-platform`deb包: `LANG=C DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Path=$PATH:/usr/local/bin -y install /host/image-$SONIC_VERSION/platform/$platform/*.deb`
            5. 清除刚添加和安装的apt相关配置和临时文件: `rm -f /etc/apt/sources.list.d/sonic_debian_extension.list; rm -f /var/lib/apt/lists/_host_image-${SONIC_VERSION}_platform_common_Packages.lz4`
            6. 恢复原始的apt源: `mv /etc/apt/sources.list.rc-local /etc/apt/sources.list`
         2. 否则通过`dpkg`直接安装: `dpkg -i /host/image-$SONIC_VERSION/platform/$platform/*.deb`
      6. 同步数据到磁盘: `sync`
      7. 若是通过另一个NOS的grub进入的SONiC, 则为此SONiC安装一个grub (`[ -n "$onie_platform" ] && [ -n  "$grub_installation_needed" ]`):
         1. 定义并检查是否存在grub工具包`/host/image-$SONIC_VERSION/platform/grub/grub*.deb`, 不存在则*删除标志文件并退出脚本* (有的)
         2. 安装grub工具包, 失败则*删除标志文件并退出脚本*: `dpkg -i $grub_bin > /dev/null 2>&1`
         3. 安装grub到`/host`(/host/grub): grub-install --boot-directory=/host --recheck $sonic_dev 2>/dev/null`
         4. ...
      8. 创建目录`/var/platform`, 供后续脚本将其输出文件存放于此
      9. 配置`kdump`工具: `[ -f /etc/default/kdump-tools ] && sed -i -e "s/__PLATFORM__/$platform/g" /etc/default/kdump-tools`
      10. *删除标志文件并退出脚本*
   6. 拷贝`fsck`检查日志到syslog: `[ -f /var/log/fsck.log.gz ] && gunzip -d -c /var/log/fsck.log.gz | logger -t "FSCK" rm -f /var/log/fsck.log.gz` 


**特性**:
- 支持从其他NOS迁移到SONiC, Ref: [从其他NOS的GRUB启动到SONiC](./Logic%20of%20sonic%20images.md#从其他NOS的GRUB启动到SONiC)


**主要**
- SONiC实际文件系统版本: /etc/sonic/sonic_version.yml
- SONiC环境变量覆盖: /host/image-${SONIC_VERSION}/sonic-config/sonic-environment -> /etc/sonic/sonic-environment
- ONIE机器配置检查与加载: /host/machine.conf
- 根据cmdline更新串口波特率: program_console_speed()
- 首次启动与配置迁移处理: /host/image-${SONIC_VERSION}/platform/firsttime
- SONiC分区(i.e. /dev/sda3)fsck检查与修复日志的解压处理: /var/log/fsck.log.gz




```log
[   38.125317] rc.local[437]: +
[   38.153643] rc.local[438]: + sed -e s/build_version: //g;s/'//g
[   38.246817] rc.local[435]: + cat /etc/sonic/sonic_version.yml
[   38.299176] rc.local[437]: grep build_version
[   39.365880] rc.local[427]: + SONIC_VERSION=202311.986446-3efdc0000
[   39.379702] rc.local[427]: + FIRST_BOOT_FILE=/host/image-202311.986446-3efdc0000/platform/firsttime
[   39.401847] rc.local[427]: + SONIC_CONFIG_DIR=/host/image-202311.986446-3efdc0000/sonic-config
[   39.454288] rc.local[427]: + SONIC_ENV_FILE=/host/image-202311.986446-3efdc0000/sonic-config/sonic-environment
[   39.480939] rc.local[427]: + [ -d /host/image-202311.986446-3efdc0000/sonic-config -a -f /host/image-202311.986446-3efdc0000/sonic-config/sonic-environment ]
[   39.502284] rc.local[427]: + logger SONiC version 202311.986446-3efdc0000 starting up...
[   39.957296] rc.local[427]: + grub_installation_needed=
[   39.961363] rc.local[427]: + [ ! -e /host/machine.conf ]
[   39.970111] rc.local[427]: + . /host/machine.conf
[   40.061554] rc.local[427]: + onie_arch=x86_64
[   40.077755] rc.local[427]: + onie_bin=
[   40.094306] rc.local[427]: + onie_boot_reason=install
[   40.134360] rc.local[427]: + onie_build_date=2018-11-17T04:18+00:00
[   40.282845] rc.local[427]: + onie_build_machine=kvm_x86_64
[   40.493838] rc.local[427]: + onie_build_platform=x86_64-kvm_x86_64-r0
[   40.498551] rc.local[427]: + onie_config_version=1
[   40.501031] rc.local[427]: + onie_dev=/dev/vda2
[   40.513915] rc.local[427]: + onie_disco_boot_reason=install
[   40.521506] rc.local[427]: + onie_disco_dns=10.0.2.3
[   40.530695] rc.local[427]: + onie_disco_interface=eth0
[   40.554368] rc.local[427]: + onie_disco_ip=10.0.2.15
[   40.567018] rc.local[427]: + onie_disco_lease=86400
[   40.569424] rc.local[427]: + onie_disco_mask=24
[   40.586391] rc.local[427]: + onie_disco_opt53=05
[   40.590692] rc.local[427]: + onie_disco_router=10.0.2.2
[   40.702492] rc.local[427]: + onie_disco_serverid=10.0.2.2
[   40.714090] rc.local[427]: + onie_disco_siaddr=10.0.2.2
[   40.717664] rc.local[427]: + onie_disco_subnet=255.255.255.0
[   40.729154] rc.local[427]: + onie_exec_url=file://dev/vdb/onie-installer.bin
[   40.754928] rc.local[427]: + onie_firmware=auto
[   40.782403] rc.local[427]: + onie_grub_image_name=shimx64.efi
[   40.924045] rc.local[427]: + onie_initrd_tmp=/
[   40.946179] rc.local[427]: + onie_installer=/var/tmp/installer
[   40.961986] rc.local[427]: + onie_kernel_version=4.9.95
[   41.011104] rc.local[427]: + onie_local_parts=
[   41.046745] rc.local[427]: + onie_machine=kvm_x86_64
[   41.059278] rc.local[427]: + onie_machine_rev=0
[   41.087543] rc.local[427]: + onie_neighs=[fe80::2-eth0],
[   41.110856] rc.local[427]: + onie_partition_type=gpt
[   41.139548] rc.local[427]: + onie_platform=x86_64-kvm_x86_64-r0
[   41.143099] rc.local[427]: + onie_root_dir=/mnt/onie-boot/onie
[   41.176589] rc.local[427]: + onie_secure_boot=yes
[   41.211143] rc.local[427]: + onie_skip_ethmgmt_macs=yes
[   41.243050] rc.local[427]: + onie_switch_asic=qemu
[   41.280140] rc.local[427]: + onie_uefi_arch=x64
[   41.324651] rc.local[427]: + onie_uefi_boot_loader=shimx64.efi
[   41.398832] rc.local[427]: + onie_vendor_id=42623
[   41.431361] rc.local[427]: + onie_version=master-201811170418
[   41.469732] rc.local[427]: + program_console_speed
[   41.623797] rc.local[468]: + cat /proc/cmdline
[   41.641620] rc.local[469]: + grep -Eo console=tty(S|AMA)[0-9]+,[0-9]+
[   41.685689] rc.local[473]: + cut -d , -f2
[   41.742686] rc.local[427]: + speed=115200
[   41.781768] rc.local[427]: + [ -z 115200 ]
[   41.803090] rc.local[427]: + CONSOLE_SPEED=115200
[   41.830308] rc.local[478]: +
[   41.883692] rc.local[479]: +
[   41.969023] rc.local[478]: grep agetty /lib/systemd/system/serial-getty@.service
[   41.985871] rc.local[479]: grep keep-baud
[   42.033958] rc.local[427]: + [ 1 = 0 ]
[FAILED] Failed to start OpenBSD Secure Shell server.
[   42.072589] rc.local[427]: + sed -i s|u' .* %I|u' 115200 %I|g /lib/systemd/system/serial-getty@.service
[   42.426969] rc.local[427]: + systemctl daemon-reload
[   42.731629] kdump-tools[423]: Starting kdump-tools:
[   42.923304] kdump-tools[460]: no crashkernel= parameter in the kernel cmdline ...
[   42.935361] kdump-tools[523]:  failed!
[   46.935521] rc.local[427]: + [ -f /host/image-202311.986446-3efdc0000/platform/firsttime ]
[   46.948663] rc.local[427]: + [ -f /var/log/fsck.log.gz ]
[   46.968539] rc.local[580]: + gunzip -d -c /var/log/fsck.log.gz
[FAILED] Failed to start OpenBSD Secure Shell server.
[   47.031898] rc.local[581]: + logger -t FSCK
[   47.249167] rc.local[427]: + rm -f /var/log/fsck.log.gz
[   47.318205] rc.local[427]: + exit 0
```

















