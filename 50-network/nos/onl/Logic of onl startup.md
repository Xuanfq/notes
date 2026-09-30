# Logic of onl startup


onl启动逻辑


## 名词说明

### Sysstat

`Sysstat` 包包含许多商业单位共有的各种实用程序，用于监控系统性能和使用活动:

- `iostat`：报告设备、分区和网络文件系统的CPU统计和硬盘吞吐效率的数据。 # 核心工具
- `mpstat`：报告单个或组合处理器相关的统计数据。
- `pidstat`：报告Linux任务 (进程) 的统计信息: I/O、CPU、内存等。
- `tapestat`：报告连接到系统的磁带驱动器的统计信息。
- `cifsiostat`：报告CIFS统计。
- `sysstat`：只是sysstat配置文件的手动页面，给出了sysstat命令使用的环境变量的含义。

`Sysstat` 还包含您可以通过 `cron` 或 `systemd` 计划收集和记录性能和活动数据的工具:

- `sar`：收集、报告和保存系统活动信息 (CPU、内存、磁盘、中断、网络接口、TTY、内核表等)，也能显示动态显示。 # 数据统计核心工具
- `sadc`：是系统活动数据收集器，用作sar的后端。日志位于 /var/log/sa/ 。
- `sa1`：在系统活动每日数据文件中收集并存储二进制数据。它是sadc的前端，设计被设计为由cron或systemd自动运行。
- `sa2`：撰写每日活动总结报告，接受sar命令的大多数标志和参数。它被设计为由cron或systemd运行的sar的前端。
- `sadf`：以多种格式 (CSV、XML、JSON等) 显示由sar收集的（二进制文件）数据，并可用于与其他程序的数据交换。该命令还可用于为sar使用SVG (可伸缩矢量图形) 格式收集的各种活动绘制图形。


### start-stop-daemon

用于启动和停止系统守护程序，通用命令，位于`/sbin/start-stop-daemon`，基本用法：
- 自定义pid: `-p /var/run/discover.pid `
- 不创建pidfile: `-m`
- 后台运行: `-b`
- 指定程序或命令: `-x xxx`
- 不要输出警告: `-q`
- 设置信号: `-s $signal(default TERM)`
- 启动守护程序：`start-stop-daemon -S -b -m -p /var/run/discover.pid -x /bin/discover`
- 关闭守护程序：`start-stop-daemon -q -K -s TERM -p /var/run/${daemon}.pid`




## Loader 步骤概述 - 引导进入真实的文件系统环境

1. /etc/inittab (packages/base/all/initrds/loader-initrd-files/src/etc/inittab)
   1. `::sysinit:/bin/sysinit`: 系统初始化 (在运行 /bin/sysinit 这个系统初始化程序时，不给他分配 “控制终端”（controlling tty）。这样一来，用户就无法通过 “作业控制”（比如 Linux 中的Ctrl+Z暂停进程、bg后台运行等操作）来绕过密码验证等安全机制。)
      1. 输出重定向控制及设置**退出后恢复输出及强制重启**:
         1. 将标准输出和错误重定向到/tmp/sysinit.out文件
         2. 设置退出陷阱，确保脚本退出时*恢复输出*并*强制重启*
      2. 文件系统挂载:
         1. mount -t proc proc /proc
         2. mount -t sysfs sysfs /sys
         3. -d /sys/firmware/efi/efivars && (modprobe efivarfs || :) && mount -t efivarfs efivarfs /sys/firmware/efi/efivars
         4. mount -o remount,size=1M /dev
         5. 检查/tmp目录的文件系统类型，如果不是tmpfs或ramfs，就将其重新挂载为tmpfs: mount -t tmpfs tmpfs /tmp
      3. 初始化随机数生成器(RNG): python /bin/initrng.py . 通过收集系统中的熵源信息并将其注入到系统的随机数池中，以提高系统随机数的质量。
      4. 内核命令行参数处理: 提取以`onl_`开头的参数（如onl_param1）并保存到`/etc/onl/`参数目录（如/etc/onl/param1），主要参数是:
         1. /etc/onl/platform(`onl_platform`): machineConf['onie_platform'].replace('_', '-').replace('.', '-')
         2. nopat console=ttyS0,115200n8: from platform-config-defaults-(x86-64|uboot).yml or platform.yml
      5. 平台检测和初始化: `. /lib/platform-detect`
         1. 若没有配置需要运行的平台`/etc/onl/platform`(platform="$(cat /etc/onl/platform)")，启动自动递归检查流程 (实际上已有):
            1. 递归检测`/lib/platform-config/*`下所有`detect0.sh`，依次运行直到运行后存在需要运行的平台的配置`/etc/onl/platform`才不再往下检测。
            2. 递归检测`/lib/platform-config/*`下所有`detect.sh`，同上
            3. 递归检测`/lib/platform-config/*`下所有`detect1.sh`，同上
            4. 上述检查都没有生成`/etc/onl/platform`则配置为未知平台`echo "unknown" > /etc/onl/platform`
         2. 创建空文件`/etc/onl/block`
         3. 检测是否存在`/etc/onl/platform`中配置的平台的配置目录`/lib/platform-config/${platform}`
            1. 若存在，则检测平台的配置目录中是否存在启动配置`/lib/platform-config/${platform}/onl/boot/${platform}`，若有，则以加载库的形式加载: `. /lib/platform-config/${platform}/onl/boot/${platform}`
            2. 不存在，则输出不支持平台的log信息到`/etc/onl/abort`文件。
      6. 若平台检测成功: `if [ ! -f /etc/onl/abort ];`
         1. 初始化设备:
            1. 设置mdev作为热插拔管理器: `echo /sbin/mdev >/proc/sys/kernel/hotplug`
            2. 初始化网络设备: `cd /sys/class/net; for d in *; do initnetdev $d add; done`
               1. 遍历所有`/sys/class/net/`下的设备名`name`或`syspath`，看是否匹配平台配置文件`$platform_name.replace('_','-')...`中的配置:
                  ```yml
                  network:
                    interfaces:
                      ma1:
                        name: eth0
                        syspath: pci0000:00/0000:00:14.0
                  ```
                  若匹配成功且定义的接口名(如`ma1`)不存在，则通过命令`ip link set $oldname name $newname`重命名网络接口
         2. 文件系统检查和挂载: 
            1. 执行文件系统检查并自动修复: `onl-mounts fsck all`
               1. 分区包括`ONL-*`（Label）所有分区, 参照packages/base/all/initrds/loader-initrd-files/src/etc/mtab.yml
               2. 检查修复命令: `fsck.ext4 -p $device`
            2. 挂载所有必要的文件系统: `onl-mounts -q mount all`
               1. 分区包括`EFI`及`ONL-*`（Label）所有分区, 参照packages/base/all/initrds/loader-initrd-files/src/etc/mtab.yml
               2. EFI-BOOT: /boot/efi/, ro
               3. ONL-BOOT: /mnt/onl/boot/, rw
               4. ONL-CONFIG: /mnt/onl/config/, ro
               5. ONL-IMAGES: /mnt/onl/images/, rw
               6. ONL-DATA: /mnt/onl/data/, rw
         3. 若是uboot，初始化uboot环境: `[ -s /proc/device-tree/model ] && initubootenv`
         4. 若是存在`/etc/issue`输出以显示版本信息: `[ -f /etc/issue ] && cat /etc/issue`
         5. `/etc/onl/boot-config`配置文件获取与生成:
            1. (优先)若ONL-BOOT分区存在`boot-config`，使用该配置: `cp /mnt/onl/boot/boot-config /etc/onl/boot-config` (默认并一般存在)
            2. 若存在默认备用`boot-config`，使用该配置并设为首选(默认不存在): `cp /etc/onl/boot-config-default /etc/onl/boot-config`, `cp /etc/onl/boot-config-default /mnt/onl/boot/boot-config`
      7. 初始化PKI(公钥基础设施)key及cert(一般首次启动时生成一次即可): `[ -f "/usr/bin/onl-pki" ] && /usr/bin/onl-pki --init`
         1. 若ONL-CONFIG不存在`/mnt/onl/config/pki/$(sysconfig.pki.key.name)`(即key.pem)，则通过命令生成: `openssl genrsa -out ...`
         2. 若ONL-CONFIG不存在`/mnt/onl/config/pki/$(sysconfig.pki.cert.name)`(即certificate)，则通过命令及key生成证书:
            ```py
                self._execute(('openssl', 'req',
                               '-new', '-batch',
                               '-subj', subject,
                               '-key', self.kpath,
                               '-out', csr.name,),
                              logLevel=logging.INFO)
                self._execute(('openssl', 'x509',
                               '-req',
                               '-days', str(sysconfig.pki.cert.csr.cdays),
                               '-sha256',
                               '-in', csr.name,
                               '-signkey', self.kpath,
                               '-out', self.cpath,),
                              logLevel=logging.INFO)
            ```
         3. 以上`sysconfig`位于packages/base/all/vendor-config-onl/src/etc/onl/sysconfig/00-defaults.yml, 也能通过/mnt/onl/config/sysconfig(默认没有)进行覆盖。
         4. 运行自定义初始化脚本`/etc/sysinit.d/*`(默认没有): `for s in $(ls /etc/sysinit.d/* | sort); do [ -x "$s" ] && "$s" done`
         5. `/etc/onl/boot-config`配置解析和应用，创建空白配置文件并逐行解析`/etc/onl/boot-config`到配置文件:
            1. /etc/onl/SWI
            2. /etc/onl/CONSOLESPEED
            3. /etc/onl/PASSWORD
            4. /etc/onl/NET: `NETDEV=ma1`
            5. /etc/onl/BOOTMODE: `INSTALLED`
            6. /etc/onl/BOOTPARAMS: `SWI=images::latest`
         6. 根据`boot-config`|`/etc/onl/CONSOLESPEED`设置串口控制台波特率: `CONSOLESPEED=$(cat /etc/onl/CONSOLESPEED); [ "${CONSOLESPEED}" ] && stty ${CONSOLESPEED}`
   2. `::wait:-/bin/autoboot`: 进入自动启动，如果用户中断则进入下一步启动shell。 （-表示就算进入失败也能正常运行后续）
      1. 若检测平台失败，即存在`/etc/onl/abort`文件，退出autoboot脚本。
      2. 若ONL-BOOT分区存在自动启动配置文件autoboot，则加载该配置(一般不存在): `[ -f /mnt/onl/boot/autoboot ] && . /mnt/onl/boot/autoboot`
      3. 设置最大运行/bin/autoboot的重试次数（50次）
      4. 输出横幅内容，即版本信息、OS信息等，并检查`boot-config`: `/bin/banner`
         1. 客制化版本信息: `. /lib/customize.sh` -> `. /etc/onl/loader/versions.sh`
            1. 但loader相关是固定的
         2. 输出`/etc/onl/boot-config`内容，若存在且不为空
         3. 若不存在或为空则尝试通过`/bin/boot-config.py configure`进行配置，但实际上没有该python文件。不存在时创建`/etc/onl/abort`以终止autoboot。
      5. 尝试应用网络配置，失败则重新执行/bin/autoboot: `[ ! /bin/ifup ] && tryagain`
         1. 实际上是根据`/etc/onl/boot-config`的解析结果进行配置，以下是参数，但仅配置了NETDEV:
            ```py
            # packages/base/all/initrds/loader-initrd-files/src/bin/ifup
            # NETDEV: device name
            # NETAUTO: autoconfiguration method ("dhcp" or empty)
            # NETRETRIES: autoconfiguration timeout
            # NETIP: IP address (/prefix optional for v4)
            # NETMASK: netmask (if NETIP has no prefix)
            # NETGW: default gateway IP address (optional)
            # NETDOMAIN: DNS default domain (optional)
            # NETDNS: DNS server IP address (optional)
            # NETHW: hardware (MAC) address (optional)
            ```
         2. 禁用ipv6自动配置: `echo 0 >/proc/sys/net/ipv6/conf/${NETDEV}/autoconf`
         3. 清除网口已配置的ip地址: `ip addr  flush dev ${NETDEV}`
         4. 清除网口所有的路由条目: `ip route flush dev ${NETDEV}`
         5. 启用/激活网口: `ip link set ${NETDEV} up`
         6. 若网口非down，启用网口: `grep -q down "/sys/class/net/${NETDEV}/operstate" || ifconfig "${NETDEV}" up`
         7. 等待指定网络接口（${NETDEV}）上的 IPv6 地址完成重复地址检测（DAD），直到所有 IPv6 地址退出 “tentative（暂定）” 状态或超时为止。
      6. 检测`/etc/onl/BOOTMODE`是否存在且不允许为空，并存在对应脚本文件`/bootmodes/$BOOTMODE`，即`/bootmodes/installed`或`/bootmodes/swi`，一般用`installed`
      7. 调用启动模式脚本: `/bootmodes/$BOOTMODE`, 以`/bootmodes/installed`为例。
         1. 加载boot参数(即`SWI=images::latest`): `. /etc/onl/BOOTPARAMS`
         2. 环境检查，检查关键目录/mnt/onl/data及mtab.yml是否存在并正确挂载，这是存储系统镜像数据的重要目录
         3. 根据boot参数`SWI`的不同类型采取不同处理方式获取swi镜像所存放到变量swipath: 首次启动时最终是从以mtab.yml中挂载的目标目录中以images结尾的目录作为镜像所在，即ONL-IMAGES分区
            1. 非首次启动`""|dir:*|nfs://*)`: 本地镜像, 必须位于`/mnt/onl/data/etc/onl/SWI`且非空
            2. 首次启动`*)`: 通过参数值的开头部分进行下载或获取: http/ftp/tftp/ssh/scp/nfs/(/dev/sdx)/(/path/to/swi)/(for mtab.yml's mount)
               1. 文件不存在或为空时，设置需要解压(实际上只有首次启动是需要解压): `[ ! -s /mnt/onl/data/etc/onl/SWI ] && do_unpack=1`
         4. 镜像版本处理:
            1. `*::latest)`(实际上为此处,值为`images:*.swi`): `swistamp=${SWI%:latest}${swipath##*/}`
            2. `*)`: `swistamp=$SWI`
         5. 更新启动参数`/etc/onl/BOOTPARAMS`，将SWI设置为本地目录(查找时会变为`/mnt/onl/data`目录，并挂载到`/`目录): `sed -i -e '/^SWI=/d' /etc/onl/BOOTPARAMS; echo "SWI=dir:data:/" >> /etc/onl/BOOTPARAMS`
         6. 若是首次启动，解压与安装SWI根文件系统: `[ "$do_unpack" ] && swiprep --install "$swipath" --swiref "$swistamp" /mnt/onl/data`
            1. 创建并清空目标目录: `/mnt/onl/data`, 该目录为ONL-DATA分区，在ONIE下安装后没有存放任何东西
            2. 解压 SWI 中 `rootfs-${arch}.sqsh` 为 `rootfs.sqsh`
            3. 使用 unsquashfs 解压/提取 `rootfs.sqsh` 文件到目标目录 `/mnt/onl/data` **(并非挂载！因此可以进行读写该分区)**
            4. 通过是否存在文件`/mnt/onl/data/lib/vendor-config/onl/install/lib.sh`来校验rootfs.sqsh是否合法
            5. 若 SWI 中存在数据包 `swi-data.tar.gz`，解压到 `/mnt/onl/data/boot`
            6. *复制loader中的非sysconfig配置文件到 `/mnt/onl/data/etc/onl/.`*: `for thing in /etc/onl/*; do [ $thing != "/etc/onl/sysconfig" ] && cp -R $thing "$destdir/etc/onl/."`
            7. 复制loader中的fw_env.config配置文件到 `/mnt/onl/data/etc/fw_env.config`(若存在,uboot才有)
            8. 若`/mnt/onl/data/etc/onl/rootfs/version`不存在且 SWI 中存在，解压 SWI 中的 `version` 文件到该处 (实际两处都没有该文件)
            9.  若`/mnt/onl/data/etc/onl/rootfs/manifest.json`不存在且 SWI 中存在，解压 SWI 中的 `manifest.json` 文件到该处 (已存在)
            10. 输出镜像版本信息到`/mnt/onl/data/etc/onl/SWI`
         7. 记录镜像信息: `swiprep --record "$swipath" --swiref "$swistamp" /mnt/onl/data`
            1. 若`/mnt/onl/data/etc/onl/upgrade/swi/version`不存在且 SWI 中存在，解压 SWI 中的 `version` 文件到该处 (实际两处都没有该文件)
            2. 若`/mnt/onl/data/etc/onl/upgrade/swi/manifest.json`不存在且 SWI 中存在，解压 SWI 中的 `manifest.json` 文件到该处 (已存在)
            3. 输出镜像版本信息到`/mnt/onl/data/etc/onl/upgrade/swi/SWI`
         8. 启动swi: `. /bootmodes/swi`, 实际为`for url in $SWI; do timeout -t 180 boot "${url}" && exit 0 done`
            1. 重新挂载`swipath=/mnt/onl/data`为读写: `mount -o rw,remount /mnt/onl/data`
            2. 重新生成配置`/etc/onl/boot-config`(不是/mnt/onl/data/etc...):
               1. SWI=${SWI}
               2. CONSOLESPEED=$(stty speed)
               3. 密码一般没有: `[ ! "${PASSWORD}" ] || echo "PASSWORD=${PASSWORD}" >>/etc/onl/boot-config`
               4. 获取网络配置并写入boot-config: `ifget && cat /etc/onl/NET >>/etc/onl/boot-config`
                  1. NETDEV=$(ip -o link show up | sed -n -e '/LOOPBACK/d' -e 's/^[0-9]\+: \([^:]\+\): .*/\1/p' | head -n 1)
                  2. NETHW...
                  3. ...
            3. **将`/mnt/onl/data`关联到`/newroot`目录**: `mount --bind "${swipath}/${rootfs}" /newroot`
            4. 若loader中存在`/lib/boot-custom`, 加载: `. /lib/boot-custom`
            5. 停止当前`init`进程，触发`/etc/inittab`中的`restart`切换到真实的swi的`root`: `kill -QUIT 1`
   3. `::wait:-/bin/login`: 进入shell登录提示。
   4. `::wait:/bin/umount -a -r`: 卸载所有文件系统（-a选项），卸载失败则尝试以只读方式重新挂载。
   5. `::wait:/sbin/reboot -f`: 强制重启系统
   6. `::restart:/bin/switchroot`: 当init进程收到SIGHUP或SIGQUIT信号时，进入真正的交换机镜像的根文件系统
      1. 卸载文件系统: 
         1. 创建临时文件复制当前挂载信息
         2. 通过拷贝的挂载信息遍历所有挂载点，卸载除了根目录`/`、`/proc`、`/sys`、`/dev` 和 `/newroot` 及其子目录`/newroot/*`之外的所有文件系统，即主要是
            1. `tmpfs`
            2. `onl-*` (因为是bind，所以并不会影响/newroot)
      2. 移动/保留关键文件系统: 将关键的虚拟文件系统（proc、sys、dev）移动到新的临时的`/netroot`下
         1. `mount --move /proc /newroot/proc`
         2. `mount --move /sys /newroot/sys`
         3. `mount --move /dev /newroot/dev`
      3. 处理 EFI 变量: 如果系统使用 UEFI，先卸载 EFI 变量文件系统，然后在新的根目录下`/netroot`重新挂载
      4. 执行根文件系统切换，切换到`/newroot`为根文件系统并初始化: `switch_root`来源于`busybox`
         1. `[ -x /newroot/sbin/init ] && exec switch_root -c /dev/console /newroot /sbin/init`
         2. `[ -x /newroot/lib/systemd/systemd ] && exec switch_root -c /dev/console /newroot /lib/systemd/systemd`
         3. `else exec /init`: re-init




## RealFS 步骤概述 - 真实的文件系统环境

1. /etc/inittab (builds/any/rootfs/$debian-name/sysvinit/overlay/etc/inittab): inittab为系统的PID=1的进程，决定这系统启动调用哪些启动脚本文件
   1. `id:2:initdefault:`: 设置默认运行级别为2，即多用户模式（立即生效）
   2. `si0::sysinit:/etc/boot.d/boot`: 执行系统初始化脚本（阻塞执行，完成后继续） (packages/base/all/boot.d/src/boot/)
      1. `10.upgrade-system`(一般不会触发): 
         - origin: -> packages/base/all/vendor-config-onl/src/sbin/onl-upgrade-system -> packages/base/all/vendor-config-onl/src/python/onl/upgrade/system.py -> SystemUpgrade().main()
         - 步骤:
           1. 比较loader版本兼容是否相等:
             - 当前loader的兼容版本(`SYSTEM_COMPATIBILITY_VERSION` of `/etc/onl/loader/versions.json`)
             - upgrade的loader中的兼容版本(`SYSTEM_COMPATIBILITY_VERSION` of `/etc/onl/upgrade/$PLATFORM_ARCH/manifest.json`)
           2. 不相等则升级(没有设置强制升级), 升级方法: `onl.install.SystemInstall.App(force=True).run()` (手动命令`onl-install-system -F`)
              1. 检查并调整/tmp文件系统大小为1G
              2. 取消挂载`/mnt/onl/*`及`/boot/`
              3. 获取loader根文件系统`path`，再回调`_runInitrd`: -> UpgradeHelper(callback=self._runInitrd).run() [Parent: onl.install.ShellApp] -> `path`=`/etc/onl/upgrade/$PLATFORM_ARCH/($PLATFORM.cpio.gz|onl-loader-initrd-$PARCH.cpio.gz)`, 一般是`onl-loader-initrd-..`, 依赖于`sysconfig/00-default.yml`
                 1. 挂载`loader-initrd`
                 2. `loader-initrd`下创建临时目录`/tmp/installer-xxxxxx.d/`
                 3. 挂载`onie-boot`并获取`etc/machine*.conf`拷贝到`loader-initrd`对应目录
                 4. 若是uboot，拷贝当前系统环境变量配置`/etc/fw_env.config`到`loader-initrd`对应目录
                 5. 拷贝当前系统onl配置`/etc/onl`到`loader-initrd`对应目录
                 6. 安装配置生成: `installerConf = InstallerConf(path="/dev/null")`
                    1. 直接将`loader-initrd`下的`/tmp/installer-xxxxxx.d/`目录作为`installerConf.installer_dir`，用于swi等所需文件查找。
                    2. ...
                 7. `loader-initrd`下制作空压缩包`installer-xxxxxx.zip`
                 8. loader文件处理: 
                    1. 复制upgrade目录下的内核文件`kernel-*`到`loader-initrd`临时目录`/tmp/installer-xxxxxx.d/`
                    2. 复制upgrade目录下的loader-initrd文件`$PLATFORM.cpio.gz|onl-loader-initrd-$PARCH.cpio.gz`到`loader-initrd`临时目录`/tmp/installer-xxxxxx.d/`。或uboot下`$PLATFORM.itb|onl-loader-fit.itb`。
                 9. 再`loader-initrd`环境下使用`chroot /usr/bin/onl-install --force`进行升级。
           3. 升级成功后重启
         - **实际上跟`onie`下安装类似！但缺失文件如`*.swi`！** 可以通过优化此处升级逻辑，拷贝所有upgrade目录下的文件作为installer_dir的内容去查找，这样只要将相关文件放到该目录即可升级。
      2. `15.upgrade-loader`(一般不会触发): 若版本不一样，将upgrade目录下的`kernel-*`及`$PLATFORM.cpio.gz|onl-loader-initrd-$PARCH.cpio.gz`拷贝到`ONL-BOOT`，然后更新grub。依赖于`sysconfig/00-default.yml`。
      3. `50.initmounts`(一般会触发): 
         1. 加载系统中所有已配置的 sysctl 参数，同时抑制输出信息
            1. /etc/sysctl.conf（传统主配置文件）
               1. 空
            2. /etc/sysctl.d/*.conf（按文件名排序的配置文件目录，现代系统更常用）
               1. protect-links.conf: 用于增强文件系统安全性的两个参数，主要用于防止通过硬链接（hardlink）和符号链接（symlink，软链接）进行的权限绕过攻击。
            3. /run/sysctl.d/*.conf（运行时生成的临时配置）
            4. /usr/lib/sysctl.d/*.conf（系统默认提供的配置）
         2. 挂载所有必要的文件系统: `onl-mounts -q mount all`
            1. 分区包括`EFI`及`ONL-*`（Label）所有分区, 参照packages/base/all/initrds/loader-initrd-files/src/etc/mtab.yml
            2. EFI-BOOT: /boot/efi/, ro
            3. ONL-BOOT: /mnt/onl/boot/, rw
            4. ONL-CONFIG: /mnt/onl/config/, ro
            5. ONL-IMAGES: /mnt/onl/images/, rw
            6. ONL-DATA: /mnt/onl/data/, rw
      4. `51.onl-platform-baseconf`(一般会触发): 运行平台自定义的配置，位于`src/python/$platform.replace('-','_').replace('.','_')/__init__.py`
      5. `51.pki`(一般不会触发): 初始化PKI(公钥基础设施)key及cert: `/usr/bin/onl-pki --init`, 实际已经在`loader`阶段已经生成！
         1. 若ONL-CONFIG不存在`/mnt/onl/config/pki/$(sysconfig.pki.key.name)`(即key.pem)，则通过命令生成: `openssl genrsa -out ...`
         2. 若ONL-CONFIG不存在`/mnt/onl/config/pki/$(sysconfig.pki.cert.name)`(即certificate)，则通过命令及key生成证书:
            ```py
                self._execute(('openssl', 'req',
                               '-new', '-batch',
                               '-subj', subject,
                               '-key', self.kpath,
                               '-out', csr.name,),
                              logLevel=logging.INFO)
                self._execute(('openssl', 'x509',
                               '-req',
                               '-days', str(sysconfig.pki.cert.csr.cdays),
                               '-sha256',
                               '-in', csr.name,
                               '-signkey', self.kpath,
                               '-out', self.cpath,),
                              logLevel=logging.INFO)
            ```
      6. `52.rc.boot`(一般不会触发): 若ONL相关分区中(按顺序: `boot config images data`)存在可执行的`rc.boot`，逐项执行，默认无。
         ```sh
         for dir in boot config images data; do
            script=/mnt/onl/$dir/rc.boot
            if [ -x "$script" ]; then
               echo "Executing $script..."
               $script
            fi
         done
         ```
      7. `53.install-debs`(一般不会触发): 若`/mnt/onl/data/install-debs`下存在`list`以及list中每行存在的`deb`包，逐行安装，默认无。
         ```sh
         PACKAGE_DIR=/mnt/onl/data/install-debs
         PACKAGE_LIST="$PACKAGE_DIR/list"

         if [ -e "$PACKAGE_LIST" ]; then
            for package in $(cat $PACKAGE_LIST); do
               echo "Installing packages $package..."
               if ! dpkg -i "$PACKAGE_DIR/$package"; then
                     echo "Failed."
                     exit 1
               fi
            done
         fi
         ``` 
      8. `60.upgrade-onie`(一般不会触发): 若存在平台配置的onie需要更新，重启进入onie进行更新。
      9.  `61.upgrade-firmware`(一般不会触发): 若存在平台配置的onie-firmware需要更新，重启进入onie进行更新。
      10. `64.upgrade-swi`(一般不会触发): 升级ONL swi，该项功能不完善，默认是禁用！
      11. `70.dhclient.conf`: 为网络接口 ma1 配置 DHCP 客户端标识符（DHCP client identifier），并将配置写入 DHCP 客户端配置文件（dhclient.conf）。以此强制 ma1 接口的 DHCP 客户端使用固定格式的标识符（01:+MAC地址）向服务器请求 IP，确保服务器能稳定识别该客户端并分配预期的网络配置（如固定 IP、网关等）。
   3. `si1::sysinit:/etc/init.d/rcS`: -> link to `/lib/init/rcS`，即: `exec /etc/init.d/rc S`: -> link to `/lib/init/rc S` (/etc/init.d/.depend.boot): 
      1. 第1层（并行）: 
         1. `S01hostname.sh`: 设置主机名
         2. `S01mountkernfs.sh`: 挂载内核虚拟文件系统
            1. 在`/run`和`/run/lock`上挂载`tmpfs`文件系统
            2. 在`/proc`上挂载`proc`文件系统
            3. 在`/sys`上挂载`sysfs`文件系统
            4. 在`/sys/fs/pstore`上挂载`pstore`文件系统（如果该目录存在），用于在系统崩溃或重启后保存内核崩溃日志的持久性存储文件系统。存在与否取决于内核。
            5. 在`/sys/kernel/config`上挂载`configfs`文件系统（如果该目录存在），提供用户空间与内核子系统之间的双向配置接口。存在与否取决于内核与驱动。
         3. `S07kmod`: 用于在系统启动时加载内核模块。查找`/etc/modules-load.d /run/modules-load.d /usr/local/lib/modules-load.d /usr/lib/modules-load.d /lib/modules-load.d`目录下的模块配置文件`*.conf`以及`/etc/modules`，并读取这些配置文件、对逐个非注释行的`模块名`及其`参数`使用`modprobe $module $args`命令进行加载。实际上没有实际的需要加载的内核模块，不存在文件*.conf，存在空内容的/etc/modules。
         4. `S10brightness`: 屏幕亮度保存和恢复。串口输出的交换机无用。
         5. `S10resolvconf`: 初始化DNS解析配置管理服务，管理相关目录的创建与更新，尝试启用resolvconf的更新功能：`resolvconf --enable-updates`。
      2. 第2层（依赖于 S01mountkernfs.sh）: 
         1. `S02udev`: 用于启动和管理 systemd-udevd 服务，该服务是 Linux 设备管理系统的核心部分。
            1. 启动 systemd-udevd 守护进程
            2. 管理 /dev 目录（设备文件系统）
            3. 处理热插拔事件，触发初始热插拔事件（先处理子系统，然后处理设备）
            4. 加载设备驱动程序
      3. 第3层（依赖于 S02udev）（并行）: 
         1. `S03mountdevsubfs.sh`: 在系统启动时挂载特殊的虚拟文件系统到 /dev 目录下。
            1. 在 /run/shm 挂载一个 tmpfs 文件系统。/run/shm 目录提供基于内存的临时文件存储，用于进程间通信和临时数据存储。
            2. 在 /dev/pts 挂载 devpts 文件系统，用于伪终端支持。对于终端模拟器、SSH 连接和许多交互式程序至关重要。
         2. `S10procps`: 在系统启动时加载/etc/sysctl.conf文件中指定的内核参数配置。主要用途是在系统启动时自动加载系统管理员在/etc/sysctl.conf和/etc/sysctl.d/目录下配置的内核参数。这些参数可能包括：（实际上没有需要加载的内核参数配置）
            1. 内核输出打印级别设置
            2. 网络配置（如TCP/IP栈的行为）
            3. 内存管理设置
            4. 进程相关参数
            5. 文件系统和I/O调优
            6. 安全相关设置
         3. `S16bootmisc.sh`: 在系统启动过程中执行一些杂项任务。
            1. 登录延迟功能：在系统启动过程中创建 /run/nologin 文件，阻止用户登录，这个文件通常会在启动完成后被其他脚本删除
            2. 创建/重置 /var/run/utmp 文件，该文件记录当前登录的用户，对该文件设置适当的权限，如果系统中存在 utmp 组，则将文件所有权设置为该组
            3. 清理启动标志文件：删除临时目录中的各种清理标志文件，这些文件通常由其他引导脚本（如 bootclean）创建
      4. 第4层（依赖于 S03mountdevsubfs.sh）: 
         1. `S04hwclock.sh`: 管理和同步硬件时钟（CMOS/RTC 时钟）与系统时钟（软件时钟）。启动时（start）：使用 hwclock --rtc=/dev/rtc0 --hctosys 命令将硬件时钟同步到系统时钟。关闭时（stop/restart/reload）：将系统时钟时间保存到硬件时钟。
      5. 第5层（依赖于 S10urandom）: 
         1. `S10urandom`: 管理随机数生成器的熵池种子。该脚本主要负责在系统启动和关闭时保存和恢复随机数种子，以确保系统的随机数发生器具有足够的熵和不可预测性。使用/var/lib/urandom/random-seed文件存储随机数种子。
            1. 启动时初始化：使用当前日期和时间添加初始熵，如果存在旧的种子文件，将其内容写入/dev/urandom，生成并保存新的随机种子到种子文件
            2. 关闭时保存：系统关闭时，从/dev/urandom读取新的随机数据并保存到种子文件，为下次启动准备。
      6.  第6层（依赖于 S11networking）: 
         1. `S11networking`: 管理Linux系统中的网络接口。
            1. 启动时，使用 ifup -a 命令启动所有网络接口，通过 ifquery --list --allow=hotplug 命令查找热插拔网络接口，使用 ifup $ifaces 命令启动热插拔网络接口。
            2. 停止时，先检查是否有网络文件系统或网络swap在使用，使用 ifdown -a 命令停止所有网络接口（除lo外）
   4. `~~:S:wait:/sbin/sulogin`: 设置单用户时的登录
   5. `l0:0:wait:/etc/init.d/rc 0 ... l6:6:wait:/etc/init.d/rc 6`: 定义了不同运行级别下系统的行为，每个级别执行对应的rc脚本，rc脚本在切换运行级别时执行，处理特定运行级别的服务启动/停止。运行当前运行级别的相关脚本，即`l2:2:wait:/etc/init.d/rc 2` (/etc/init.d/.depend.start)：
      1. 第1层（无依赖，可最先启动）
         - `S01rsyslog`: 用于管理 Rsyslog 服务（SysV init 风格）。Rsyslog 是一个增强型的系统日志守护进程，提供了比传统 syslogd 更多的功能。
         - `S01sudo`: 确保sudo权限不会在系统重启后继续存在，防止潜在的安全风险。sudo使用时间戳文件来记录授权状态，通过重置时间戳来清除之前的授权记录。一次性运行服务。
         - `S03bootlogs`: 保存内核消息到 /var/log/dmesg 文件。一次性运行服务。
         <!-- - `S01killprocs`: 在系统进入单用户模式(runlevel 1)时终止所有剩余的进程。runlevel2不需要。 -->
      2. 第2层（只依赖第一层服务）
         - `S02onlp-snmpd`（依赖 S01rsyslog）: 管理ONLP SNMP代理的服务，这是一个基于NET-SNMP AgentX框架的服务，用于通过SNMP协议监控和管理Open Network Linux平台上的设备。
         - `S02snmpd`（依赖 S01rsyslog）: 设置环境变量 MIBDIRS ，确保了 SNMP 代理程序能够找到 MIB 文件，但没有实际启动该snmpd服务。
         - `S02faultd`（依赖 S01rsyslog）: 启动故障代理服务 /usr/bin/faultd。
         - `S02hddtemp`（依赖 S01rsyslog）: 启动 /usr/sbin/hddtemp 的守护进程（若存在），用于监控硬盘温度。
         - `S02onlpd`（依赖 S01rsyslog）: 启动 ONLP Platform Agent (/bin/onlpd) 服务，监控平台、硬件、风控等。
         - `S02netplug`（依赖 S01rsyslog）: 检查并确保启动 netplugd 守护进程。监控网络接口的物理连接状态，当网线插入/拔出时自动激活/关闭网络接口。
         - `S02smartmontools`（依赖 S01rsyslog）: 启动 S.M.A.R.T.(Self-Monitoring, Analysis, and Reporting Technology) 监控守护进程 smartd。用于监控硬盘。会自动读取 /etc/default/smartmontools 中的配置（实际上没有需要加载的配置）。
         - `S02ssh`（依赖 S01rsyslog）: 启动sshd服务。用于ssh远程登录。
         - `S02rmnologin`（依赖 S01sudo）: 移除/run/nologin文件（实际上没有移除，/lib/init/vars.sh中配置了DELAYLOGIN=no以跳过移除），一次性运行服务。/run/nologin文件的存在会阻止普通用户登录，仅允许root用户访问系统。
         - `S02acpid`（依赖 S01rsyslog）: 加载acpi相关驱动并启动ACPI(高级配置与电源接口)守护进程(acpid) (/usr/sbin/acpid)，用于处理电源管理、热管理和硬件事件的关键组件。监听并处理系统电源相关事件，提供接口让应用程序响应电源状态变化等。
         - `S02sysstat`（依赖 S01rsyslog）: 启动配置和管理系统活动数据收集器(sadc)。主要在系统启动时运行一次，用于标记系统重启事件，实际的持续数据收集通常由 cron 作业处理，而不是这个启动脚本。要启用 sysstat 数据收集，需要在 /etc/default/sysstat 文件中将 ENABLED 设置为 "true"，实际上没有配置为true，虽有配置cron，但也无法正常执行收集，因为没有配置为true。
         <!-- - S02single（依赖 S01killprocs）: 将系统切换到单用户模式（也称为维护模式或救援模式），原理：exec init -t1 S，一秒(-t1)后进入单用户模式(S)。runlevel2不需要。  -->
      3. 第3层（依赖第二层服务）
         - `S04watchdog`（依赖 bootlogs, onlp-snmpd, snmpd, faultd, hddtemp, onlpd, netplug, smartmontools, ssh, rmnologin, acpid, sysstat）: 启动看门狗，默认是开启的，只不过没有配置看门狗设备（如编辑/etc/watchdog.conf, 配置watchdog-device=/dev/watchdog\nwatchdog-timeout = 15），导致实际上无用。安装看门狗是通过命令apt install watchdog。
         - `S04rc.local`（依赖 bootlogs, onlp-snmpd, snmpd, faultd, hddtemp, onlpd, netplug, smartmontools, ssh, rmnologin, acpid, sysstat）: 执行local boot scripts `/etc/rc.local`。
   6.  `ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now`: 设置CTRL-ALT-DEL时立即关机
   7.  `T0:23:respawn:/sbin/pgetty`: 运行级别为2/3时启动pgetty，用于处理登录过程。显示登录提示，接受用户名并启动login程序来验证用户身份。进程终止时自动重启。


























