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
      1. `/etc/init.d/rc`说明：
         1. 设置环境变量，捕获错误退出情况
         2. 确定当前和前一个运行级别
         3. 加载系统配置
         4. 检测并发启动能力（依赖于/etc/init.d/.depend.*文件）
         5. 根据并发设置选择启动方法，onl中主要用`startpar`进行多并发
            1. startpar 读取 /etc/init.d/.depend.* 文件来了解服务之间的依赖关系
            2. 这些依赖文件由 insserv 工具生成
         6. 执行服务停止脚本（K开头的脚本）（切换运行级别或关机重启时才有用，开机时跳过），避免重复停止已经停止的服务。遍历`/etc/rc{runlevel}.d/K*`脚本，或`/etc/init.d/.depend.stop`。
         7. 执行服务启动脚本（S开头的脚本），避免重复启动已经启动的服务。遍历`/etc/rc{runlevel}.d/S*`脚本，或运行级别S`/etc/init.d/.depend.boot`，或普通运行级别（2-5）的服务启动`/etc/init.d/.depend.start`。
   4. `~~:S:wait:/sbin/sulogin`: 设置单用户时的登录
   5. `l0:0:wait:/etc/init.d/rc 0 ... l6:6:wait:/etc/init.d/rc 6`: 定义了不同运行级别下系统的行为，每个级别执行对应的rc脚本，rc脚本在切换运行级别时执行，处理特定运行级别的服务启动/停止。运行当前运行级别的相关脚本，即`l2:2:wait:/etc/init.d/rc 2`：
      1. 
   6. `ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now`: 设置CTRL-ALT-DEL时立即关机
   7. `T0:23:respawn:/sbin/pgetty`: 运行级别为2/3时启动pgetty，用于处理登录过程。显示登录提示，接受用户名并启动login程序来验证用户身份。进程终止时自动重启。


























