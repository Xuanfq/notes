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





## 步骤概述

1. /etc/inittab (builds/any/rootfs/$debian-name/sysvinit/overlay/etc/inittab): inittab为系统的PID=1的进程，决定这系统启动调用哪些启动脚本文件
   1. `id:2:initdefault:`: 设置默认运行级别为2，即多用户模式（立即生效）
   2. `si0::sysinit:/etc/boot.d/boot`: 执行系统初始化脚本（阻塞执行，完成后继续） (packages/base/all/boot.d/src/boot/)
      1. 导出环境变量：`export PATH=/sbin:/usr/sbin:/bin:/usr/bin`
      2. 生成所有模块的依赖关系文件`/lib/modules/$(uname -r)/modules.dep(.bin)`，使系统能正确找到/加载模块及其依赖：`depmod -a`
      3. 按字典顺序一次执行`/etc/boot.d/`下以数字开头的脚本：`for script in $(ls /etc/boot.d/[0-9]* | sort); do $script done`
      4. 在开始执行rc.S脚本之前等待控制台刷新：`sleep 1`
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


























