
操作系统当前正在运行的功能级别，从0-6，具有不同的功能：

- 系统关机模式（runlevel 0）：系统默认运行级别不能设置为0，否则无法正常启动系统（一开机就自动关机）。
- 单用户模式（emergency.target：runlevel 1）：也称为救援模式，root权限，用于系统维护，禁止远程登陆，类似Windows下的安全模式登录。
- 多用户模式（rescue.target：runlevel 2）：没有NFS网络支持。
- 完整的多用户文本模式（multi-user.target：runlevel 3）：有NFS，登陆后进入控制台命令行模式。
- 系统未使用（runlevel 4）：保留一般不用，在一些特殊情况下可以用它来做一些事情。例如在笔记本电脑的电池用尽时，可以切换到这个模式来做一些设置。
- 图形化模式（graphical.target：runlevel 5）：登陆后进入图形GUI模式或GNOME、KDE图形化界面，如X Window系统。
- 重启模式（runlevel 6）：默认运行级别不能设为6，否则无法正常启动系统。

主要记住运行级别0, 6和3!

`/etc/rc*.d`文件夹中的脚本文件的链接目标为：`/etc/init.d`文件夹下的脚本(`*`为系统运行级别‘数字’和字母：S，系统**优先运行**rcS.d目录下的脚本，**然后运行**rcN.d下的脚本)

**/etc/inittab:** inittab为系统的PID=1的进程，决定这系统启动调用哪些启动脚本文件



## 1.Linux系统主要通过以下步骤启动

1. 启动Boot Manager
2. 加载系统内核，启动init进程， init进程是Linux的根进程，所有的系统进程都是它的子进程。
3. init进程读取“/etc/inittab”文件中的信进入inittab中预设的运行级别，**按顺序运行**该运行级别对应文件夹(init*.d)下的脚本。脚本通常**以“start”参数**启动，并指向一个系统中的程序。通常情况下，“/etc/rcS.d/”目录下的启动脚本首先被执行，然后是“/etc/rcN.d/”目录。例如您设定的运行级别为3,那么它对应的启动目录为“/etc/rc3.d/”。
4. 根据“/etc/rcS.d/”文件夹中对应的脚本启动Xwindow服务“xorg”   Xwindow为Linux下的图形用户界面系统。
5. 启动登录管理器，等待用户登录

### **1.1.系统服务**

在运行级别对应的文件夹中，您可以看到许多文件名以“S##”和“K##”起始的启动脚本链接

init 进程将以“start”为参数，按文件名顺序执行所有以“S##”起始的脚本。脚本名称中的数字越小，它将被越早执行。

例如在 “/etc/rc2.d/”文件夹中，“S13gdm”文件名中的数字小于“S23xinetd”,“S13gdm”将比“S23xinetd”先执行。

如果一个脚本链接，以“K##”起始，表示它将以“stop”参数被执行。如果相应服务没有启动，则不执行该脚本。

### **1.2.手动控制服务**

你可以手动运行带有以下参数的启动脚本，来控制系统服务。
start 启动
stop 停止
restart 重启

例如：
/etc/rc2.d/K20powernowd start
有 时您并不清楚当前运行级别，该运行级别下未必有相应脚本；而且此类脚本的前三位字符并不固定，不便于记忆。

这时，您可以**直接使用 “/etc/init.d/”文件夹**中的启动脚本**（因为“/etc/rcX.d/”中的启动脚本都是链接到“/etc/init.d/”文件夹下相应脚本）**



## **2.Ubuntu系统架构关于启动项大致分为四类，每一类都分为系统级和用户级**

- 第一类upstart，或者叫job，由init管理，配置文件目录/etc/init，~/.init
- 第二类叫service，由rc.d管理，配置文件目录/etc/init.d，以及/etc/rc.local文件
- 第三类叫cron，由contab管理，使用crontab进行配置
- 第四类叫startup，由xdg管理，配置文件目录/etc/xdg/autostart，以及~/.config/autostart

upstart任务适用于runlevel<5的脚本和程序，service任务适用于runlevel<=5的任务，cron任务则不一定，而startup一般工作在runlevel=5，也就是桌面级。

对于普通用户而言，你的桌面级应用应该使用startup，服务级应用（比如某些功能性的软件脚本）应该使用service，常规性配置可以使用cron，而与启动顺序有关的最好使用upstart。

### **2.1. 开机启动时自动运行程序**

Linux加载后, 它将初始化硬件和设备驱动, 然后运行第一个进程init。init根据配置文件继续引导过程，启动其它进程。通常情况下，修改放置在

- /etc/rcN.d
- /etc/rcS.d

目录下的脚本文件，可以使init自动启动其它程序。例如：编辑/etc/rcS.d/rc.local(也就是/etc/rc.local，因为rcS.d链接目标为/etc) 文件(该文件通常是系统最后启动的脚本)，

在文件最末加上一行“xinit”或“startx”，可以在开机启动后直接进入X－Window。

### **2.2. 登录时自动运行程序**

用户登录时，bash先自动执行系统管理员建立的**全局登录script** ：

/ect/profile（大多在此文件中设置环境变量，它是整个桌面环境使用的一个shell进程，也就是**登录shell**）

\>>>在linux中的shell可以分为：登录shell，非登录交互式shell，非登录非交互式shell(执行shell脚本)

然后bash在用户起始目录下按顺序查找三个特殊文件中的一个：

- /.bash_profile、
- /.bash_login、
- /.profile，

**但只执行最先找到的一个**。因此，只需根据实际需要在上述文件中加入命令就可以实现用户登录时自动运行某些程序（类似于DOS下的Autoexec.bat）。

### **2.3. 退出登录时自动运行程序**

退出登录时，bash自动执行个人的退出登录脚本

- /.bash_logout。

例如，在/.bash_logout中加入命令“tar －cvzf c.source.tgz ＊.c”，则在每次退出登录时自动执行 “tar” 命令备份 ＊.c 文件。

### **2.4. 定期自动运行程序**

Linux有一个称为**crond**的守护程序，主要功能是周期性地检查 /var/spool/cron目录下的一组命令文件的内容，并在设定的时间执行这些文件中的命令。用户可以通过crontab 命令来建立、修改、删除这些命令文件。

例如，建立文件crondFile，内容为“00 9 23 Jan ＊ HappyBirthday”，运行“crontabcronFile”命令后，每当元月23日上午9:00系统自动执行“HappyBirthday”的程序（“＊”表示不管当天是星期几）。

### **2.5. 定时自动运行程序一次**

定时执行命令at 与crond 类似（但它只执行一次）：命令在给定的时间执行，但不自动重复。at命令的一般格式为：at [ －f file ] time ，在指定的时间执行file文件中所给出的所有命令。也可直接从键盘输入命令：

```
＄ at 12:00
at>mailto Roger －s ″Have a lunch″ < plan.txt
at>Ctr－D
Job 1 at 2000－11－09 12:00
```

 

2000－11－09 12:00时候自动发一标题为“Have a lunch”，内容为plan.txt文件内容的邮件给Roger.



### 3.Ubuntu下添加开机启动脚本

**方式1：rc.local**

Ubuntu**开机之后**会执行/etc/rc.local文件中的脚本，所以我们可以直接在/etc/rc.local中添加启动脚本。

**当然要添加到语句：exit 0 前面才行。**

**方式2：rcN.d**

如果要添加为开机启动执行的脚本文件，可先将脚本复制或者软连接到/etc/init.d/目录下，然后用：update-rc.d xxx defaults NN命令(NN为启动顺序)，将脚本添加到初始化执行的队列中去。

注意如果脚本需要用到网络，则NN需设置一个比较大的数字，如98 。

- 将脚本设为可执行权限，并拷贝至/etc/init.d
- 在/etc/init.d路径下执行update-rc.d script-name start 98 5 . 注：98为顺序，5为rc5.d，符号.不要忘记
- 这样会在会在/etc/rc5.d/下面创建1个符号链接，有必要在脚本的前段加一些provider/start-default等说明，否则报警，在Ubuntu上测试成功
- 在am4378上没有测试成功 T_T.

另外一种是

- 将脚本设为可执行
- 在rcN.d下执行ln ../init.d/script-name S99script
- 在Ubuntu上没有成功，不知为何

**方式3：systemd**