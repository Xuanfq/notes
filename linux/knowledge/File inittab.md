# File inittab

`inittab`, 位于`/etc/inittab`, 是Linux初始化系统使用的配置文件，在不同发行版Linux的位置不同。

`inittab`控制着系统boot和更改runlevel时所执行的代码。在我们按下电源键时，此文件就会指导系统工作。

该文件定义了默认运行等级、每个运行等级下的操作，以及进程启动、监视、重启。

一旦inittab文件中关于运行等级的所有操作执行完成，便代表了boot完成，之后就引导进入登录界面，用户可以使用账户密码登陆进入系统！


## Linux初始化步骤

1. Linux内核启动：
   - 初始化信号处理的基础框架/机制和默认行为
2. Linux内核加载init进程(/sbin/init)：第一个用户进程，用于启动其他用户记的进程或服务，init进程是Linux系统中所有进程的父进程
3. init进程初始化：
   1. 设置，主动设置​​自身的信号处理函数​​，以支持系统管理（如进程回收、配置重载、关机等）
   2. 初始化控制台
4. init进程解析inittab文件，运行操作系统的配置脚本，对Linux系统进行初始化：
   1. 解析inittab文件
   2. 执行inittab的sysinit命令
   3. 执行inittab的wait命令
   4. 执行inittab的once命令
   5. 执行inittab的respawn命令
   6. 执行inittab的askfirst命令
   7. 监测respawn/askfirst命令是否有退出，退出则重新执行
      1. askfirst​​：仅启动一次 Shell，需用户手动触发。
      2. ​​respawn​​：若 Shell 退出，自动重新启动（无需用户交互）。



## 文件内容

配置文件中的各项操作以id:runlevel:action:process构成：

- id: 识别功能
- runlevel: 适用的运行等级
- action: 指挥init如何处理操作，可选initdefault, sysinit, boot, bootwait, wait, respawn
- process: 定义了要执行的命令或脚本，表示所要执行的shell命令。任何合法的shell语法均适用于该字段。


runlevel:
- 系统关机模式（runlevel 0）：系统默认运行级别不能设置为0，否则无法正常启动系统（一开机就自动关机）。
- 单用户模式（emergency.target：runlevel 1）：也称为救援模式，root权限，用于系统维护，禁止远程登陆，类似Windows下的安全模式登录。
- 多用户模式（rescue.target：runlevel 2）：没有NFS网络支持。
- 完整的多用户文本模式（multi-user.target：runlevel 3）：有NFS，登陆后进入控制台命令行模式。
- 系统未使用（runlevel 4）：保留一般不用，在一些特殊情况下可以用它来做一些事情。例如在笔记本电脑的电池用尽时，可以切换到这个模式来做一些设置。
- 图形化模式（graphical.target：runlevel 5）：登陆后进入图形GUI模式或GNOME、KDE图形化界面，如X Window系统。
- 重启模式（runlevel 6）：默认运行级别不能设为6，否则无法正常启动系统。


actions:
- sysinit: 在运行boot或bootwait进程之前运行。无论哪个等级启动，初始化系统都会执行。
- wait: init应该运行这个进程一次，并等待其结束后再进行下一步操作。
- once: init只运行一次该进程。
- boot: 系统启动时运行该进程。
- respawn: init应该监视这个进程，即使其结束/失败后也应该被重新启动。
- bootwait: 在系统启动时运行，init等待进程完成。
- ctrlaltdel: 当Ctrl+Alt+Del三个键同时按下时运行，把SIGINT信号发送给init。
- powerfail: 当init收到SIGPWR信号时运行。可处理电源故障。
- powerokwait: 当收到SIGPWD信号且/etc/文件中的电源状态包含OK时运行。可处理电源故障。
- powerwait: 当收到SIGPWD信号，并且init等待进程结束时运行。可处理电源故障。
- askfirst​​：仅启动一次 Shell，需用户手动触发。


在Terminal可以使用init 0与init 6来关机和重启，二者的效果与shutdown now、reboot是相同的。




