# Logic of onie startup

onie启动逻辑


## 名词说明

- start-stop-daemon: 启动和停止系统守护程序，通用命令，位于`/usr/sbin/start-stop-daemon`，基本用法：
  - 自定义pid: `-p /var/run/discover.pid `
  - 不创建pidfile: `-m`
  - 后台运行: `-b`
  - 指定程序或命令: `-x xxx`
  - 不要输出警告: `-q`
  - 设置信号: `-s $signal(default TERM)`
  - 启动守护程序：`start-stop-daemon -S -b -m -p /var/run/discover.pid -x /bin/discover`
  - 关闭守护程序：`start-stop-daemon -q -K -s TERM -p /var/run/${daemon}.pid`


## 步骤概述

1. /etc/inittab (rootconf/default/etc/inittab): inittab为系统的PID=1的进程，决定这系统启动调用哪些启动脚本文件
   1. `::shutdown:/etc/init.d/rc 6`: 设置关机时执行的rc脚本，`/etc/rc6.d/`, 与`/etc/rc0.d/`一样
   2. `::restart:/sbin/init`: restart是非标准动作，需要查看busybox文档? `busybox init --help`?
   3. `::sysinit:/etc/init.d/rc S`: 系统初始化时执行命令`/etc/init.d/rc S`, 即优先完成`/etc/rcS.d/`下的脚本
   4. `::wait:/etc/init.d/rc 3`: 等待命令`/etc/init.d/rc 3`执行完成，完成运行级别为3(完整的多用户模式)的`/etc/rc3.d/`下的脚本
      1. `S10dropbear.sh`: 启动sshd服务
      2. `S10telnetd.sh`: 启动telnetd服务
      3. `S50discover.sh`: 启动发现服务
         1. 读取环境变量: `$onie_boot_reason`
         2. `echo "$daemon: xxx mode detected.  (Installer disabled.|Running uninstaller.|Running installer.|Running updater.)" > /dev/console`
         3. `echo "** xxx Mode Enabled **" >> /etc/issue`
         - rescue: 无过多操作，退出0
         - uninstall: `/bin/onie-uninstaller;exit 0`, 启动查找发现服务`start-stop-daemon -S -b -m -p /var/run/discover.pid -x /bin/discover`
         - update|embed: 查找`updater`, 启动查找发现服务`start-stop-daemon -S -b -m -p /var/run/discover.pid -x /bin/discover`
         - install: 查找`installer`, 启动查找发现服务`start-stop-daemon -S -b -m -p /var/run/discover.pid -x /bin/discover`
   5. `::askfirst:-/bin/onie-console`: 进入控制台
      1. `cat /etc/issue`: 输出一些信息
      2. `exec /bin/sh -l`: 进入shell，加载登录环境：
         1. 读取 /etc/profile 和 ~/.profile（或其他 Shell 的配置文件，如 ~/.bash_profile）。
         2. 初始化环境变量（如 PATH, HOME）、别名（alias）和函数。


### Discover

Source: `/bin/discover`

目的：发现并运行安装installer/updater程序


#### 代码逻辑

1. 准备好库函数/变量等：
   1. `. /lib/onie/functions`
   2. 导入内核启动参数: `import_cmdline` of `/lib/onie/functions`
   3. 允许不同架构跳过查找某些分区里的安装器: `. /lib/onie/discover-arch` in `rootconf/grub-arch/sysroot-lib-onie/` to cover function `skip_parts_arch`
      - 如`grub-arch`跳过`/EFI/`分区和`-DIAG`分区















