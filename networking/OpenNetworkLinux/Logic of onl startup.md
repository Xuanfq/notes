# Logic of onl startup


onl启动逻辑


## 名词说明





## 步骤概述

1. /etc/inittab (builds/any/rootfs/$debian-name/sysvinit/overlay/etc/inittab): inittab为系统的PID=1的进程，决定这系统启动调用哪些启动脚本文件
   1. `id:2:initdefault:`: 设置默认运行级别为2，即多用户模式（立即生效）
   2. `si0::sysinit:/etc/boot.d/boot`: 执行系统初始化脚本（阻塞执行，完成后继续） (packages/base/all/boot.d/src/boot/)
      1. 导出环境变量：`export PATH=/sbin:/usr/sbin:/bin:/usr/bin`
      2. 生成所有模块的依赖关系文件`/lib/modules/$(uname -r)/modules.dep(.bin)`，使系统能正确找到/加载模块及其依赖：`depmod -a`
      3. 按字典顺序一次执行`/etc/boot.d/`下以数字开头的脚本：`for script in $(ls /etc/boot.d/[0-9]* | sort); do $script done`
      4. 在开始执行rc.S脚本之前等待控制台刷新：`sleep 1`
   3. `si1::sysinit:/etc/init.d/rcS`: -> link to `/lib/init/rcS`，即: `exec /etc/init.d/rc S`: -> link to `/lib/init/rc S`: 
      1. 第1层（并行）: 
         1. `S01hostname.sh`: 设置主机名
         2. `S01mountkernfs.sh`: 挂载内核虚拟文件系统
            1. 在`/run`和`/run/lock`上挂载`tmpfs`文件系统
            2. 在`/proc`上挂载`proc`文件系统
            3. 在`/sys`上挂载`sysfs`文件系统
            4. 在`/sys/fs/pstore`上挂载`pstore`文件系统（如果该目录存在），用于在系统崩溃或重启后保存内核崩溃日志的持久性存储文件系统
            5. 在`/sys/kernel/config`上挂载`configfs`文件系统（如果该目录存在），提供用户空间与内核子系统之间的双向配置接口
         3. `S07kmod`: 
         4. `S10brightness`: 
         5. `S10resolvconf`: 
      2. 第2层（依赖于 S01mountkernfs.sh）: 
         1. `S02udev`: 
      3. 第3层（依赖于 S02udev）（并行）: 
         1. `S03mountdevsubfs.sh`: 
         2. `S10procps`: 
         3. `S16bootmisc.sh`: 
      4. 第4层（依赖于 S03mountdevsubfs.sh）: 
         1. `S04hwclock.sh`: 
      5. 第5层（依赖于 S10urandom）: 
         1. `S10urandom`: 
      6.  第6层（依赖于 S11networking）: 
         1. `S11networking`: 
   4. `~~:S:wait:/sbin/sulogin`: 设置单用户时的登录
   5. `l0:0:wait:/etc/init.d/rc 0 ... l6:6:wait:/etc/init.d/rc 6`: 定义了不同运行级别下系统的行为，每个级别执行对应的rc脚本，rc脚本在切换运行级别时执行，处理特定运行级别的服务启动/停止。运行当前运行级别的相关脚本，即`l2:2:wait:/etc/init.d/rc 2`：
      1. 
   6.  `ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now`: 设置CTRL-ALT-DEL时立即关机
   7.  `T0:23:respawn:/sbin/pgetty`: 运行级别为2/3时启动pgetty，用于处理登录过程。显示登录提示，接受用户名并启动login程序来验证用户身份。进程终止时自动重启。


























