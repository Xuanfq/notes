# 初始化引导-initramfs-tools


`initramfs-tools`是开源项目[initramfs-tools](https://salsa.debian.org/kernel-team/initramfs-tools), initramfs-tools 是 Debian/Ubuntu 系发行版的核心工具, 移植的核心目标是让它能在目标系统上正确生成包含驱动、*挂载*逻辑、启动脚本的 initramfs 镜像，确保系统启动时能完成*真正的根文件系统的挂载*等关键步骤。

`initramfs`是一个临时的内存文件系统，在 kernel 加载后、真正的根文件系统挂载前被执行，负责完成一系列引导准备工作，主要核心是**初始化**和**引导**。

`initramfs-tools`可以简单快速生成轻量级ramfs(rootfs)。



## Usage

[用法介绍](https://manpages.debian.org/buster/initramfs-tools-core/initramfs-tools.7.en.html)


- `initramfs/initrd`生成步骤:
  1. 编译并通过`chroot`模拟安装到制作的真实文件系统根目录下
  2. 添加或修改相关脚本配置
  3. 通过命令`sudo chroot $FILESYSTEM_ROOT update-initramfs -u`生成initramfs/initrd文件

- 相关配置
  - 内核命令行: 传递相关引导配置设定
  - 脚本
    - 配置钩子脚本: 用于在必要时覆盖用户配置，例如强制使用busybox而不是klibc工具
    - 钩子脚本: 用于创建`initramfs`镜像Image时包含其他文件等
    - 启动脚本: 通常在根分区挂载之前，在内核启动期间的早期用户空间中执行



### 内核命令行

内核使用的根文件系统始终由引导加载程序指定。最重要的参数:

- `root`:
  - 方式1: root=/dev/sda1
  - 方式2: root=LABEL=rootPart
  - 方式3: root=UUID=uuidnumber


**SONiC添加了额外4个内核命令行参数及一个函数来引导挂载真实文件系统**(通过patch并编译安装):
- kernel cmdline:
  - `loop`: 真实根文件系统压缩文件
  - `loopflags`: 挂载loop时的自定义拓展参数
  - `loopfstype`: 真实根文件系统类型
  - `loopoffset`: 真实根文件系统offset
- scripts/functions
  - `mount_loop_root`: 引导挂载真实文件系统, 并将原始根分区移动到/host下, 无论是本地FS挂载还是网络FS挂载都支持
    1. /root -> /host: `mount -o move "${rootmnt}" /host` (mount_loop_root)
    2. fs.squashfs -> /root: `mount ${roflag} -o loop -t "${FSTYPE}" "${LOOPFLAGS}" "$loopfile" "${rootmnt}"` (mount_loop_root)
    3. /host -> /root/host: `[ -d "${rootmnt}/host" ] && mount -o move /host "${rootmnt}/host"` (mount_loop_root)

**cmdline e.g.**:
```sh
$GRUB_CFG_LINUX_CMD   /$image_dir/boot/vmlinuz-6.1.0-29-2-${arch} root=$grub_cfg_root rw $GRUB_CMDLINE_LINUX \
loop=/image-202505.1022539-92b55b412/fs.squashfs loopfstype=squashfs
```


**一些重要的cmdline参数**:
- `init`: 真实init的路径，若忘记密码可以通过指定/bin/bash进行密码重置。默认情况下按顺序自动逐一验证以下init, 验证成功则使用:
  - `/sbin/init` (default)
  - `/etc/init`
  - `/bin/init`
  - `/bin/sh`
- `ro`: 以只读方式挂载根文件系统 (SONiC下/dev/sda3)
- `rw`: 以读写方式挂载根文件系统 (SONiC下/dev/sda3)


> 其他参数参阅官网man手册。



### 脚本

#### 配置钩子脚本

用于在必要时覆盖用户配置，例如强制使用busybox而不是klibc工具。

由mkinitramfs在读取/etc中的配置文件之后、运行任何钩子脚本之前加载。

这些脚本可以覆盖initramfs.conf(5)中记录的任何变量，但只有在绝对必要时才应这样做。例如，如果某个软件包的启动脚本需要klibc-utils未提供的命令，它还应安装一个将BUSYBOX设置为y的配置钩子。


配置存放于:
- /usr/share/initramfs-tools/conf.d/
- /etc/initramfs-tools/
  - conf.d/
    - driver-policy
    - `*`                     # custom here
  - initramfs.conf
  - update-initramfs.conf

[配置说明参考](https://manpages.debian.org/buster/initramfs-tools-core/initramfs.conf.5.en.html)



#### 钩子脚本

用于创建`initramfs`镜像Image时包含其他文件，以及其他自定义逻辑。

它们在初始内存文件系统镜像生成期间执行，负责将所有必要的组件包含到镜像中。

除非在脚本中设置了先决条件，否则无法保证不同脚本的执行顺序。请注意，PREREQ 仅在单个目录内有效。因此，首先会根据 PREREQ 值对 /usr/share/initramfs-tools 中的脚本进行排序并执行。然后，再根据 PREREQ 值对 /etc/initramfs-tools 中的所有脚本进行排序并执行。这意味着目前无法让本地脚本（/etc/initramfs-tools 中的）在软件包中的脚本（/usr/share/initramfs-tools 中的）之前执行。

如果钩子脚本需要的配置超出了下面列出的导出变量范围，它应该读取一个独立于/etc/initramfs-tools目录的私有配置文件。它不得直接读取initramfs-tools的配置文件。
  - MODULESDIR: 模块
  - version: 版本
  - CONFDIR: 配置目录
  - DESTDIR: 目标目录
  - DPKG_ARCH: DPKG 架构
  - verbose: 详细输出
  - BUSYBOX: BUSYBOX
  - KEYMAP: 键盘映射
  - MODULES: 模块
  - BUSYBOXDIR: BUSYBOX 目录


钩子脚本存放于:
- /usr/share/initramfs-tools/hooks
  - dmsetup
  - fsck
  - kdump-tools
  - keymap
  - klibc-utils
  - kmod
  - resume
  - thermal
  - udev
  - zz-busybox
  - `*`                       # custom here
- /etc/initramfs-tools/hooks
  - file: 拷贝命令file及其数据库magic.mgc
  - mke2fs: 拷贝磁盘相关工具命令，包括mkfs.ext4/3,fsck.ext4/3等
  - pzstd: 拷贝pzstd命令，并行化的 Zstandard 压缩工具，主要用于数据压缩。
  - setfacl: 拷贝setfacl命令，用于设置和修改文件或目录的访问控制列表
  - union-fsck: 添加更多`fsck.?`
  - `*`                       # custom here




#### 启动脚本

通常在根分区挂载之前，在内核启动期间的早期用户空间中执行，控制着脚本执行的启动阶段。

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


启动脚本存放于:
- /usr/share/initramfs-tools/scripts/
  - init-top/
    - all_generic_ide
    - blacklist
    - keymap
    - udev
    - `*`                     # custom here
  - local-premount/
    - resume
    - `*`                     # custom here
  - local-bottom/
    - kdump-sysctl
    - `*`                     # custom here
  - init-bottom/
    - udev
    - `*`                     # custom here
  - functions
  - local
  - nfs
  - `*`                       # custom here
- /etc/initramfs-tools/scripts/
  - init-top/
    - `*`                     # custom here
  - init-premount/
    - arista-convertfs
    - arista-hook
    - arista-net
    - fsck-rootfs             # 对root磁盘分区设备进行自动修复: `fsck.ext4 -v -p $blkdev 2>&1 | gzip -c > /tmp/fsck.log.gz`
    - resize-rootfs           # 对root磁盘分区设备进行reset (若cmdline里配置了resize-rootfs) : `resize2fs -f $root_dev`
    - ssd-upgrade             # 对ssd firmware进行升级 (若cmdline里配置了ssd-upgrader-part=/dev/sdax,ext4 /dev/sdax中根目录需放可执行升级程序ssd-fw-upgrade): `./ssd-fw-upgrade >> /tmp/ssd-fw-upgrade.log 2>&1; gzip /tmp/ssd-fw-upgrade.log (will be named to ssd-fw-upgrade.log.gz)`
    - `*`                     # custom here
  - local-top/
    - `*`                     # custom here
  - nfs-top/
    - `*`                     # custom here
  - local-premount/
    - `*`                     # custom here
  - nfs-premount/
    - `*`                     # custom here
  - local-bottom/
    - `*`                     # custom here
  - nfs-bottom/
    - `*`                     # custom here
  - init-bottom/
    - union-mount
    - varlog
    - `*`                     # custom here
  - panic/
    - `*`                     # custom here













