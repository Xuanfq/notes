# L2-LLDP

LLDP, Link Layer Discovery Protocol 是IEEE 802.1ab中定义的链路层发现协议。

LLDP是一种标准的二层发现方式，可以将本端设备的管理地址、设备标识、接口标识等信息组织起来，并发布给自己的邻居设备，邻居设备收到这些信息后将其以标准的管理信息库MIB（Management Information Base）的形式保存起来，以供网络管理系统查询及判断链路的通信状况。

LLDP提供了一种标准的链路层发现方式。通过LLDP获取的设备二层信息能够快速获取相连设备的拓扑状态；显示出客户端、交换机、路由器、应用服务器以及网络服务器之间的路径；检测设备间的配置冲突、查询网络失败的原因。企业网用户可以通过使用网管系统，对支持运行LLDP协议的设备进行链路状态监控，在网络发生故障的时候快速进行故障定位。


## 应用场景

### 单邻居组网

单邻居组网应用场景是指交换机设备的接口之间或者交换机与媒体终端ME（Media Endpoint）的接口之间是直接相连，中间没有跨任何的设备，而且接口只有一个邻居设备的情况。单邻居组网如下图所示，SwitchA和SwitchB之间以及SwitchA和ME之间均是直接相连，SwitchA和SwitchB的每一个接口都只有一个邻居。

![单邻居组网应用场景](https://download.huawei.com/mdl/image/download?uuid=ea44990f96a14b70ae41f207da0cfbfd)



### 多邻居组网

多邻居组网应用场景是指交换机设备的接口之间不是直接相连，这时每个接口的邻居不止一个。多邻居组网如下图所示，SwitchA、SwitchB和SwitchC之间通过Switch连接（Switch需要支持LLDP报文透传）。这样SwitchA、SwitchB和SwitchC的接口都不止有一个邻居。

![多邻居组网应用场景](https://download.huawei.com/mdl/image/download?uuid=5006a1cc505742e89194058d4003a60b)



### 链路聚合组网

链路聚合组网应用场景是指交换机设备的接口之间存在链路聚合，接口之间是直接相连，链路聚合之间的每个接口只有一个邻居设备。如下图所示SwitchA和SwitchB之间存在链路聚合，SwitchA和SwitchB的每一个接口都只有一个邻居。

![链路聚合组网应用场景](https://download.huawei.com/mdl/image/download?uuid=6fd4260d9f454ea8b05657523ce9036c)



## 报文格式
















----

> - [Reference Doc 1](https://support.huawei.com/enterprise/zh/doc/EDOC1100174722/9f322d1)
> - [Reference Doc 2](https://info.support.huawei.com/info-finder/encyclopedia/zh/LLDP.html)

