
# Linux系统7个运行级别


操作系统当前正在运行的功能级别，从0-6，具有不同的功能：

- 系统关机模式（runlevel 0）：系统默认运行级别不能设置为0，否则无法正常启动系统（一开机就自动关机）。
- 单用户模式（emergency.target：runlevel 1）：也称为救援模式，root权限，用于系统维护，禁止远程登陆，类似Windows下的安全模式登录。
- 多用户模式（rescue.target：runlevel 2）：没有NFS网络支持。
- 完整的多用户文本模式（multi-user.target：runlevel 3）：有NFS，登陆后进入控制台命令行模式。
- 系统未使用（runlevel 4）：保留一般不用，在一些特殊情况下可以用它来做一些事情。例如在笔记本电脑的电池用尽时，可以切换到这个模式来做一些设置。
- 图形化模式（graphical.target：runlevel 5）：登陆后进入图形GUI模式或GNOME、KDE图形化界面，如X Window系统。
- 重启模式（runlevel 6）：默认运行级别不能设为6，否则无法正常启动系统。



### 运行级别的原理

在目录/etc/rc.d/init.d下，有许多的服务器脚本程序，一般称为服务（service）；在/etc/rc.d下有7个名为rcN.d（N的取值为0-6）的目录，对应系统的7个运行级别；rcN.d目录下都是一些符号链接文件，这些链接文件都指向init.d目录下的service脚本文件，这些链接文件的命名规则为K+nn+服务名或S+nn+服务名，其中nn为两位数字；**系统会根据指定的运行级别进入对应的rcN.d目录，并按照文件名顺序检索目录下的链接文件：对于以K（Kill）开头的文件，系统将终止对应的服务；对于以S（Start）开头的文件，系统将启动对应的服务**。

与运行级别有关的命令有，查看运行级别：runlevel命令，它的结果是两个数字，先后显示系统上一次和当前的运行级别，如果不存在上一次运行级别则用大写的N表示。

进入其他的运行级别：`init N`（N的取值为0 1 2 3 4 5 6）

> 执行 init 1 进入单用户模式
> init 3 进入多用户模式
> init 5 登录图形界面
> init 0 系统关机
> init 6 系统重启

那么在我们使用的CentOS 7的系统中，查看系统当前运行级别，还可以使用`systemctl get-default`

> 查看运行级别：systemctl get-default
> 设置系统开机时直接进入runlevel 3：systemctl set-default multi-user.target
> 设置系统开机时直接进入runlevel 5：systemctl set-default graphical.target



### **关机命令**

格式：shutdown [选项] 时间 [警告信息]

> init 0 //关机，也就是调用系统的0级别
> halt //关机
> poweroff //关机
> shutdown -h 0 等同于 shutdown -h now //立即关机
> shutdown -h +15 //15分钟后关机



### **重启命令**

> init 6 //立即重启，也就是调用系统的6级别
> reboot //立即重启
> shutdown -r 0 等同于shutdown -r now //立即重启
> shutdown -r +15 //15分钟后重启
> shutdown -r 16：30 //16：30重启，占用前台
> shutdown -r 16：30& //16：30重启，&将重启命令放在后台



### **取消shutdown关机、重启**

shutdown -c




