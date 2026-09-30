# Linux KVM Command

## Check if CPU virtualization is enabled

check if the CPU supports virtualization:

```shell
lscpu
# ... VT-x（ vmx）Intel处理器或 AMD-V（svm）AMD处理器
Virtualization features:  
  Virtualization:         VT-x
# ...
```

Check if CPU virtualization is enabled:

```shell
egrep -c '(vmx|svm)' /proc/cpuinfo
# ... If the output value is greater than 0, virtualization is enabled. Otherwise, virtualization will be disabled
24
# ...
```





## Install KVM tools on Ubuntu

```shell
sudo apt install qemu qemu-kvm libvirt-clients libvirt-daemon-system virtinst bridge-utils
```

- **qemu** - 通用机器模拟器和虚拟器
- **qemu-kvm** - 用于 KVM 支持的 QEMU 元包（即 x86 硬件上的 QEMU 完全虚拟化）
- **libvirt-clients** - libvirt 库的程序，一组客户端的库和API，用于从命令行管理和控制虚拟机和管理程序
- **libvirt-daemon-system** - libvirt 守护进程配置文件
- **virtinst** - 创建和克隆虚拟机的程序
- **bridge-utils** - 用于配置 Linux 以太网桥的实用程序

安装 KVM 后，启动 libvertd 服务（如果尚未启动）：

```shell
sudo systemctl enable libvirtd
sudo systemctl start libvirtd
```

使用命令检查 libvirtd 服务的状态：

```shell
systemctl status libvirtd
```





## KVM Network

### KVM Bridge Network

桥接网络与其他虚拟机共享主机的真实网络接口以连接到外部网络。因此，每个虚拟机都可以直接绑定到任何可用的 IPv4 或 IPv6 地址，就像物理计算机一样。

默认情况下，KVM 设置一个私有虚拟桥，以便所有虚拟机都可以在主机内相互通信。它提供自己的子网和 DHCP 来配置访客网络，并使用 NAT 访问主机网络。

使用“ip”命令查看 KVM 默认虚拟接口的 IP 地址：

```shell
ip a
# ...
5: virbr0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default qlen 1000
    link/ether 52:54:00:f1:98:9e brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.1/24 brd 192.168.122.255 scope global virbr0
       valid_lft forever preferred_lft forever
# ...
```

KVM默认虚拟接口 **virbr0** 使用 192.168.122.1/24 IP 地址。所有虚拟机都将使用 192.168.122.0/24 IP 范围内的 IP 地址，并且可以通过 192.168.122.1 访问主机操作系统。您应该能够从来宾操作系统内部通过 ssh 进入主机操作系统（位于 192.168.122.1），并使用 scp 来回复制文件。

如果您只从主机本身访问内部的虚拟机，那就没问题了。但是，我们无法从网络中的其他远程系统访问虚拟机。

为了从其他远程主机访问虚拟机，我们必须设置一个在主机网络上运行的公共网桥，并使用主机网络上的任何外部 DHCP 服务器。

移除`/etc/netplay`下的网络配置，新建网桥的网络配置（`vim /etc/netplay/01-network-bridge-br0.yaml`）：

```yaml
network:
  ethernets:
    enp4s0:
      dhcp4: false
      dhcp6: false
  # add configuration for bridge interface
  bridges:
    br0:
      interfaces: [enp4s0]
      dhcp4: false
      addresses: [192.168.1.2/24]
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8,8.8.4.4,4.2.2.2]
      parameters:
        stp: false
      dhcp6: false
  version: 2
```

应用新的网络配置：

```shell
sudo netplan apply
```

查看ip：

```shell
dev@dev-server:~$ ip r
default via 192.168.1.1 dev br0 proto static 
10.42.0.0/24 dev wlp3s0 proto kernel scope link src 10.42.0.1 metric 600 
169.254.0.0/16 dev virbr1 scope link metric 1000 
172.16.238.0/24 dev br-85ef752d251a proto kernel scope link src 172.16.238.1 linkdown 
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
172.18.0.0/16 dev br-7208511f60ef proto kernel scope link src 172.18.0.1 linkdown 
172.19.0.0/16 dev br-18665e6ed00f proto kernel scope link src 172.19.0.1 linkdown 
172.20.0.0/16 dev br-56385deb1736 proto kernel scope link src 172.20.0.1 linkdown 
192.168.1.0/24 dev br0 proto kernel scope link src 192.168.1.2 
192.168.100.0/24 dev virbr1 proto kernel scope link src 192.168.100.1 
192.168.122.0/24 dev virbr0 proto kernel scope link src 192.168.122.1 
192.168.196.0/24 dev br-5b0abe69822f proto kernel scope link src 192.168.196.1 linkdown 
```

在virt-manager中直接使用device name为br0的Bridge Device即可。



### `brctl`

```shell
[root@Tang ~]# brctl --help
Usage: brctl [commands]
commands:
	addbr     	<bridge>		add bridge
	delbr     	<bridge>		delete bridge
	addif     	<bridge> <device>	add interface to bridge
	delif     	<bridge> <device>	delete interface from bridge
	hairpin   	<bridge> <port> {on|off}	turn hairpin on/off
	setageing 	<bridge> <time>		set ageing time
	setbridgeprio	<bridge> <prio>		set bridge priority
	setfd     	<bridge> <time>		set bridge forward delay
	sethello  	<bridge> <time>		set hello time
	setmaxage 	<bridge> <time>		set max message age
	setpathcost	<bridge> <port> <cost>	set path cost
	setportprio	<bridge> <port> <prio>	set port priority
	show      	[ <bridge> ]		show a list of bridges
	showmacs  	<bridge>		show a list of mac addrs
	showstp   	<bridge>		show bridge stp info
	stp       	<bridge> {on|off}	turn stp on/off
```

常用命令：

```shell
# brctl addbr <name>     ## 创建一个名为 name 的桥接网络接口

# brctl delbr <name>     ## 删除一个名为 name 的桥接网络接口，桥接网络接口必须先 down 掉后才能删除

# brctl show             ## 显示目前所有的桥接接口

# brctl addif <brname> <ifname>  
	## 把一个物理接口 ifname 加入桥接接口 brname 中，所有从 ifname 收到的帧都将被 brname 处理
	## 就像网桥处理的一样。所有发往 brname 的帧，ifname 就像输出接口一样。当物理以太网接口加入网桥后，处于混杂模式了，所以不需要配置IP

# brctl delif <brname> <ifname>    ## 从 brname 中脱离一个ifname接口

# brctl show <brname>              ## 显示一些网桥的信息

# brctl stp <bridge> <state>
	## STP 多个以太网桥可以工作在一起组成一个更大的网络，利用 802.1d 协议在两个网络之间寻找最短路径
	## STP 的作用是防止以太网桥之间形成回路，如果确定只有一个网桥，则可以关闭 STP
	## 控制网桥是否加入 STP 树中
	## <state> 可以是'on'或者'yes'表示加入 stp 树中，这样当 lan 中有多个网桥时可以防止回环
		##'off'表示关闭stp。

# brctl setbridgeprio <bridge> <priority>
	## 设置网桥的优先级，<priority> 的值为0-65535，值小的优先级高，优先级最高的是根网桥。

# brctl setfd <bridge> <time> 
	## 设置网桥的'bridge forward delay'转发延迟时间，时间以秒为单位

# brctl sethello <bridge> <time> 
	## 设置网桥的'bridge hello time'存活检测时间

# brctl setmaxage <bridge> <time>
	## 设置网桥的'maximum message age'时间

# brctl setpathcost <bridge> <port> <cost>
	## 设置网桥中某个端口的链路花费值

# brctl  setportprio  <bridge>  <port> <priority>
	## 设置网桥中某个端口的优先级

# brctl addbr brneo           ## 创建新网桥 brneo
# brctl delbr brneo           ## 删除网桥 brneo
# brctl addif brneo eth0      ## 将接口 eth0 加入网桥 brneo
# brctl delif brneo eth0      ## 将接口 eth0 从网桥 brneo 中删除
# brctl show                  ## 查看网桥信息
# brctl show brneo            ## 查看网桥 brneo 的信息  
# brctl stp brneo on          ## 开启网桥 brneo 的 STP，避免成环
```





## KVM Command

### `qemu-img`

- `qemu-img create -f qcow2 /var/lib/libvirt/images/test-disk.qcow2 15G`: 创建磁盘大小15G的qcow2格式的镜像
- `info [-f fmt] filename`: 展示filename镜像文件的信息
- `resize filename [+ | -]size`: 改变镜像文件的大小，使其不同于创建之时的大小，其中size单位可以是K、M、G、T。缩小镜像的大小之前，需要在客户机中保证里面的文件系统有空余空间，否则会数据丢失，另外，qcow2格式文件不支持缩小镜像的操作。在增加了镜像文件大小后，也需启动客户机到里面去应用“fdisk”、“parted”等分区工具进行相应的操作才能真正让客户机使用到增加后的镜像空间。不过使用resize命令时需要小心（最好做好备份），如果失败的话，可能会导致镜像文件无法正常使用而造成数据丢失。
- `convert [-c] [-f fmt] [-O output_fmt] [-o options] filename [filename2 [...]] output_filename`: 将fmt格式的filename镜像文件根据options选项转换为格式为output_fmt的名为output_filename的镜像文件。它支持不同格式的镜像文件之间的转换，比如可以用VMware用的vmdk格式文件转换为qcow2文件，这对从其他虚拟化方案转移到KVM上的用户非常有用。一般来说，输入文件格式fmt由qemu-img工具自动检测到，而输出文件格式output_fmt根据自己需要来指定，默认会被转换为与raw文件格式（且默认使用稀疏文件的方式存储以节省存储空间）。



### `virt-install`

```shell
virt-install --name=centos7 --vcpus=4 --memory=1024 --location=/data/iso/CentOS-7-x86_64-Minimal-2009.iso --disk path=/var/lib/libvirt/images/centos7.qcow2,size=30,format=qcow2 --network bridge=virbr0 --graphics none  --extra-args='console=ttyS0'  # or --network bridge=br0
```

- --name: 虚拟机名称
- --vcpus: CPU核心数
- --memory: 内存大小
- --location: ISO镜像位置
- --disk: 虚拟机硬盘类型大小(G)及位置
- --network: 网络网卡
- --graphics: 图形界面，可以是vnc，websocket等
- --noautoconsole: 不自动进入vm的串口，若需要进入串口，可以通过`virsh console vm-name`连接串口
- 详细命令查看: `man virt-install`



### `virt-clone`

- `virt-clone -o vm01 -n vm02 -f /data/kvm-img/vm02.img`: 克隆虚拟机（虚拟机需要先关闭），克隆vm01到vm02.img并命名为vm02虚拟机



### `virsh`

- `virsh list --all `: 列出所有导入的虚拟机
- `virsh start vm-name`: 启动虚拟机
- `virsh reboot vm-name`: 重启虚拟机
- `virsh suspend vm-name`: 暂停/挂起虚拟机
- `virsh resume vm-name`: 恢复（暂停/挂起后的）虚拟机
- `virsh shutdown vm-name`: 优雅地关闭虚拟机（关机）
- `virsh reset vm-name`: 强制重启，有点类似按机箱上的重置按钮
- `virsh destroy vm-name`: 强制关闭虚拟机
- `virsh undefine vm-name`: 删除虚拟机机器配置文件，彻底销毁虚拟机，会删除虚拟机配置文件，但不会删除虚拟磁盘
- `virsh define vm-config.xml`: 从虚拟机xml配置文件导入虚拟机
- `virsh dumpxml vm-name`: 以xml格式输出指定虚拟机的详细配置
- `virsh autostart vm-name`: 宿主机重启后跟随自动启动，及开机自启
- `virsh console vm-name`: 连接串口
- `virsh attach-disk vm-name /opt/vm-name-add.qcow2 vdb`: 临时添加磁盘，若需永久则加上`--config`。将`/opt/vm-name-add.qcow2`磁盘添加到虚拟机的`/dev/vdb`上
- `virsh snapshot-create-as centos centos-snapshot1 "First snapshot"`: 创建快照，`centos-snapshot1`为快照名称，`"First snapshot"`为快照描述
- `virsh snapshot-info --domain centos --snapshotname centos-snapshot1`: 查看快照信息
- `virsh snapshot-revert centos centos-snapshot1`: 还原快照
- `virsh snapshot-delete --domain centos --snapshotname centos-snapshot1`: 删除快照
- 详细命令查看: `man virsh`

```shell
[root@node1 ~]# virsh help
分组的命令：
 
 Domain Management (help keyword 'domain'):
    attach-device                  从一个XML文件附加装置
    attach-disk                    附加磁盘设备
    attach-interface               获得网络界面
    autostart                      自动开始一个域
    blkdeviotune                   设定或者查询块设备 I/O 调节参数。
    blkiotune                      获取或者数值 blkio 参数
    blockcommit                    启动块提交操作。
    blockcopy                      启动块复制操作。
    blockjob                       管理活跃块操作
    blockpull                      使用其后端映像填充磁盘。
    blockresize                    创新定义域块设备大小
    change-media                   更改 CD 介质或者软盘驱动器
    console                        连接到客户会话
    cpu-stats                      显示域 cpu 统计数据
    create                         从一个 XML 文件创建一个域
    define                         从一个 XML 文件定义（但不开始）一个域
    desc                           显示或者设定域描述或者标题
    destroy                        销毁（停止）域
    detach-device                  从一个 XML 文件分离设备
    detach-device-alias            detach device from an alias
    detach-disk                    分离磁盘设备
    detach-interface               分离网络界面
    domdisplay                     域显示连接 URI
    domfsfreeze                    Freeze domain's mounted filesystems.
    domfsthaw                      Thaw domain's mounted filesystems.
    domfsinfo                      Get information of domain's mounted filesystems.
    domfstrim                      在域挂载的文件系统中调用 fstrim。
    domhostname                    输出域主机名
    domid                          把一个域名或 UUID 转换为域 id
    domif-setlink                  设定虚拟接口的链接状态
    domiftune                      获取/设定虚拟接口参数
    domjobabort                    忽略活跃域任务
    domjobinfo                     域任务信息
    domname                        将域 id 或 UUID 转换为域名
    domrename                      rename a domain
    dompmsuspend                   使用电源管理功能挂起域
    dompmwakeup                    从 pmsuspended 状态唤醒域
    domuuid                        把一个域名或 id 转换为域 UUID
    domxml-from-native             将原始配置转换为域 XML
    domxml-to-native               将域 XML 转换为原始配置
    dump                           把一个域的内核 dump 到一个文件中以方便分析
    dumpxml                        XML 中的域信息
    edit                           编辑某个域的 XML 配置
    event                          Domain Events
    inject-nmi                     在虚拟机中输入 NMI
    iothreadinfo                   view domain IOThreads
    iothreadpin                    control domain IOThread affinity
    iothreadadd                    add an IOThread to the guest domain
    iothreaddel                    delete an IOThread from the guest domain
    send-key                       向虚拟机发送序列号
    send-process-signal            向进程发送信号
    lxc-enter-namespace            LXC 虚拟机进入名称空间
    managedsave                    管理域状态的保存
    managedsave-remove             删除域的管理保存
    managedsave-edit               edit XML for a domain's managed save state file
    managedsave-dumpxml            Domain information of managed save state file in XML
    managedsave-define             redefine the XML for a domain's managed save state file
    memtune                        获取或者数值内存参数
    perf                           Get or set perf event
    metadata                       show or set domain's custom XML metadata
    migrate                        将域迁移到另一个主机中
    migrate-setmaxdowntime         设定最大可耐受故障时间
    migrate-getmaxdowntime         get maximum tolerable downtime
    migrate-compcache              获取/设定压缩缓存大小
    migrate-setspeed               设定迁移带宽的最大值
    migrate-getspeed               获取最长迁移带宽
    migrate-postcopy               Switch running migration from pre-copy to post-copy
    numatune                       获取或者数值 numa 参数
    qemu-attach                    QEMU 附加
    qemu-monitor-command           QEMU 监控程序命令
    qemu-monitor-event             QEMU Monitor Events
    qemu-agent-command             QEMU 虚拟机代理命令
    reboot                         重新启动一个域
    reset                          重新设定域
    restore                        从一个存在一个文件中的状态恢复一个域
    resume                         重新恢复一个域
    save                           把一个域的状态保存到一个文件
    save-image-define              为域的保存状态文件重新定义 XML
    save-image-dumpxml             在 XML 中保存状态域信息
    save-image-edit                为域保存状态文件编辑 XML
    schedinfo                      显示/设置日程安排变量
    screenshot                     提取当前域控制台快照并保存到文件中
    set-lifecycle-action           change lifecycle actions
    set-user-password              set the user password inside the domain
    setmaxmem                      改变最大内存限制值
    setmem                         改变内存的分配
    setvcpus                       改变虚拟 CPU 的号
    shutdown                       关闭一个域
    start                          开始一个（以前定义的）非活跃的域
    suspend                        挂起一个域
    ttyconsole                     tty 控制台
    undefine                       取消定义一个域
    update-device                  从 XML 文件中关系设备
    vcpucount                      域 vcpu 计数
    vcpuinfo                       详细的域 vcpu 信息
    vcpupin                        控制或者查询域 vcpu 亲和性
    emulatorpin                    控制火车查询域模拟器亲和性
    vncdisplay                     vnc 显示
    guestvcpus                     query or modify state of vcpu in the guest (via agent)
    setvcpu                        attach/detach vcpu or groups of threads
    domblkthreshold                set the threshold for block-threshold event for a given block device or it's backing chain element
 
 Domain Monitoring (help keyword 'monitor'):
    domblkerror                    在块设备中显示错误
    domblkinfo                     域块设备大小信息
    domblklist                     列出所有域块
    domblkstat                     获得域设备块状态
    domcontrol                     域控制接口状态
    domif-getlink                  获取虚拟接口链接状态
    domifaddr                      Get network interfaces' addresses for a running domain
    domiflist                      列出所有域虚拟接口
    domifstat                      获得域网络接口状态
    dominfo                        域信息
    dommemstat                     获取域的内存统计
    domstate                       域状态
    domstats                       get statistics about one or multiple domains
    domtime                        domain time
    list                           列出域
 
 Host and Hypervisor (help keyword 'host'):
    allocpages                     Manipulate pages pool size
    capabilities                   性能
    cpu-baseline                   计算基线 CPU
    cpu-compare                    使用 XML 文件中描述的 CPU 与主机 CPU 进行对比
    cpu-models                     CPU models
    domcapabilities                domain capabilities
    freecell                       NUMA可用内存
    freepages                      NUMA free pages
    hostname                       打印管理程序主机名
    hypervisor-cpu-baseline        compute baseline CPU usable by a specific hypervisor
    hypervisor-cpu-compare         compare a CPU with the CPU created by a hypervisor on the host
    maxvcpus                       连接 vcpu 最大值
    node-memory-tune               获取或者设定节点内存参数
    nodecpumap                     节点 cpu 映射
    nodecpustats                   输出节点的 cpu 状统计数据。
    nodeinfo                       节点信息
    nodememstats                   输出节点的内存状统计数据。
    nodesuspend                    在给定时间段挂起主机节点
    sysinfo                        输出 hypervisor sysinfo
    uri                            打印管理程序典型的URI
    version                        显示版本
 
 Interface (help keyword 'interface'):
    iface-begin                    生成当前接口设置快照，可在今后用于提交 (iface-commit) 或者恢复 (iface-rollback)
    iface-bridge                   生成桥接设备并为其附加一个现有网络设备
    iface-commit                   提交 iface-begin 后的更改并释放恢复点
    iface-define                   define an inactive persistent physical host interface or modify an existing persistent one from an XML file
    iface-destroy                  删除物理主机接口（启用它请执行 "if-down"）
    iface-dumpxml                  XML 中的接口信息
    iface-edit                     为物理主机界面编辑 XML 配置
    iface-list                     物理主机接口列表
    iface-mac                      将接口名称转换为接口 MAC 地址
    iface-name                     将接口 MAC 地址转换为接口名称
    iface-rollback                 恢复到之前保存的使用 iface-begin 生成的更改
    iface-start                    启动物理主机接口（启用它请执行 "if-up"）
    iface-unbridge                 分离其辅助设备后取消定义桥接设备
    iface-undefine                 取消定义物理主机接口（从配置中删除）
 
 Network Filter (help keyword 'filter'):
    nwfilter-define                使用 XML 文件定义或者更新网络过滤器
    nwfilter-dumpxml               XML 中的网络过滤器信息
    nwfilter-edit                  为网络过滤器编辑 XML 配置
    nwfilter-list                  列出网络过滤器
    nwfilter-undefine              取消定义网络过滤器
    nwfilter-binding-create        create a network filter binding from an XML file
    nwfilter-binding-delete        delete a network filter binding
    nwfilter-binding-dumpxml       XML 中的网络过滤器信息
    nwfilter-binding-list          list network filter bindings
 
 Networking (help keyword 'network'):
    net-autostart                  自动开始网络
    net-create                     从一个 XML 文件创建一个网络
    net-define                     define an inactive persistent virtual network or modify an existing persistent one from an XML file
    net-destroy                    销毁（停止）网络
    net-dhcp-leases                print lease info for a given network
    net-dumpxml                    XML 中的网络信息
    net-edit                       为网络编辑 XML 配置
    net-event                      Network Events
    net-info                       网络信息
    net-list                       列出网络
    net-name                       把一个网络UUID 转换为网络名
    net-start                      开始一个(以前定义的)不活跃的网络
    net-undefine                   undefine a persistent network
    net-update                     更新现有网络配置的部分
    net-uuid                       把一个网络名转换为网络UUID
 
 Node Device (help keyword 'nodedev'):
    nodedev-create                 根据节点中的 XML 文件定义生成设备
    nodedev-destroy                销毁（停止）节点中的设备
    nodedev-detach                 将节点设备与其设备驱动程序分离
    nodedev-dumpxml                XML 中的节点设备详情
    nodedev-list                   这台主机中中的枚举设备
    nodedev-reattach               重新将节点设备附加到他的设备驱动程序中
    nodedev-reset                  重置节点设备
    nodedev-event                  Node Device Events
 
 Secret (help keyword 'secret'):
    secret-define                  定义或者修改 XML 中的 secret
    secret-dumpxml                 XML 中的 secret 属性
    secret-event                   Secret Events
    secret-get-value               secret 值输出
    secret-list                    列出 secret
    secret-set-value               设定 secret 值
    secret-undefine                取消定义 secret
 
 Snapshot (help keyword 'snapshot'):
    snapshot-create                使用 XML 生成快照
    snapshot-create-as             使用一组参数生成快照
    snapshot-current               获取或者设定当前快照
    snapshot-delete                删除域快照
    snapshot-dumpxml               为域快照转储 XML
    snapshot-edit                  编辑快照 XML
    snapshot-info                  快照信息
    snapshot-list                  为域列出快照
    snapshot-parent                获取快照的上级快照名称
    snapshot-revert                将域转换为快照
 
 Storage Pool (help keyword 'pool'):
    find-storage-pool-sources-as   找到潜在存储池源
    find-storage-pool-sources      发现潜在存储池源
    pool-autostart                 自动启动某个池
    pool-build                     建立池
    pool-create-as                 从一组变量中创建一个池
    pool-create                    从一个 XML 文件中创建一个池
    pool-define-as                 在一组变量中定义池
    pool-define                    define an inactive persistent storage pool or modify an existing persistent one from an XML file
    pool-delete                    删除池
    pool-destroy                   销毁（删除）池
    pool-dumpxml                   XML 中的池信息
    pool-edit                      为存储池编辑 XML 配置
    pool-info                      存储池信息
    pool-list                      列出池
    pool-name                      将池 UUID 转换为池名称
    pool-refresh                   刷新池
    pool-start                     启动一个（以前定义的）非活跃的池
    pool-undefine                  取消定义一个不活跃的池
    pool-uuid                      把一个池名称转换为池 UUID
    pool-event                     Storage Pool Events
 
 Storage Volume (help keyword 'volume'):
    vol-clone                      克隆卷。
    vol-create-as                  从一组变量中创建卷
    vol-create                     从一个 XML 文件创建一个卷
    vol-create-from                生成卷，使用另一个卷作为输入。
    vol-delete                     删除卷
    vol-download                   将卷内容下载到文件中
    vol-dumpxml                    XML 中的卷信息
    vol-info                       存储卷信息
    vol-key                        为给定密钥或者路径返回卷密钥
    vol-list                       列出卷
    vol-name                       为给定密钥或者路径返回卷名
    vol-path                       为给定密钥或者路径返回卷路径
    vol-pool                       为给定密钥或者路径返回存储池
    vol-resize                     创新定义卷大小
    vol-upload                     将文件内容上传到卷中
    vol-wipe                       擦除卷
 
 Virsh itself (help keyword 'virsh'):
    cd                             更改当前目录
    echo                           echo 参数
    exit                           退出这个非交互式终端
    help                           打印帮助
    pwd                            输出当前目录
    quit                           退出这个非交互式终端
    connect                        连接（重新连接）到 hypervisor
 

```



### 











