# L3-ARP

ARP, Address Resolution Protocol, 地址解析协议。

用于将IP地址解析为MAC地址的协议。主机或三层网络设备上会维护一张ARP表，用于存储IP地址和MAC地址的映射关系，一般ARP表项包括*动态ARP表项*和*静态ARP表项*。



----

## ARP类型

### 动态ARP

动态ARP表项**由ARP协议通过ARP报文自动生成和维护，可以被老化（过期），可以被新的ARP报文更新，也可以被静态ARP表项覆盖**。

动态ARP适用于*拓扑结构复杂、通信实时性要求高的网络*。



### 静态ARP

静态ARP表项是**由网络管理员手工建立的IP地址和MAC地址之间固定的映射关系。静态ARP表项不会被老化，不会被动态ARP表项覆盖**。

正常情况下网络中设备可以通过ARP协议进行ARP表项的动态学习，生成的动态ARP表项可以被老化，可以被更新。但是当网络中存在**ARP攻击**时，设备中动态ARP表项可能会被更新成错误的ARP表项，或者被老化，造成合法用户通信异常。

静态ARP表项不会被老化，也不会被动态ARP表项覆盖，可以保证网络通信的**安全性**。静态ARP表项可以限制本端设备和指定IP地址的对端设备通信时只使用指定的MAC地址，此时攻击报文无法修改本端设备的ARP表中IP地址和MAC地址的映射关系，从而保护了本端设备和对端设备间的正常通信。**一般在网关设备上配置静态ARP表项。**

静态ARP表项分为短静态ARP表项和长静态ARP表项：

- **短静态ARP表项**：手工建立IP地址和MAC地址之间固定的映射关系，未同时指定VLAN和出接口。

  如果出接口是处于二层模式的以太网接口，短静态ARP表项*不能直接用于报文转发*。当需要发送报文时，设备会*先发送ARP请求报文*，如果收到的ARP应答报文中的源IP地址和源MAC地址与所配置的IP地址和MAC地址相同，则将收到ARP应答报文的VLAN和接口加入该静态ARP表项中，后续设备可直接用该静态ARP表项转发报文。

- **长静态ARP表项**：手工建立IP地址和MAC地址之间固定的映射关系，并同时指定该ARP表项所在VLAN和出接口。

  长静态ARP表项可以直接用于报文转发。*建议用户采用长静态ARP表项*。



### 免费ARP

设备主动**使用自己的IP地址作为目的IP地址**发送ARP请求，此种方式称免费ARP。

免费ARP有如下作用：

- **IP地址冲突检测**：当设备接口的协议状态变为Up时，设备主动对外发送免费ARP报文。正常情况下不会收到ARP应答，如果收到，则表明本网络中存在与自身IP地址重复的地址。如果检测到IP地址冲突，设备会周期性的广播发送免费ARP应答报文，直到冲突解除。

- **通告MAC地址更新**：发送方更换了网卡，MAC地址变化了，为了能够在动态ARP表项老化前通告网络中其他设备，发送方可以发送一个免费ARP。

- **通告VRRP备份组中主备发生变换**：发生主备变换后，MASTER设备会广播发送一个免费ARP报文来通告发生了主备变换。（[VRRP](https://info.support.huawei.com/info-finder/encyclopedia/zh/VRRP.html)，Virtual Router Redundancy Protocol，虚拟路由冗余协议，是一种用于提高网络可靠性的容错协议。通过VRRP，可以在主机的下一跳设备出现故障时，及时将业务切换到备份设备，从而保障网络通信的连续性和可靠性。）



### Proxy ARP

如果ARP请求是**从一个网络的主机发往同一网段但不在同一物理网络上的另一台主机**，那么连接这两个网络的*设备*就可以*回答该ARP请求*，这个过程称作ARP代理(Proxy ARP)。（代理设备回应ARP请求）

Proxy ARP有以下**特点**：

- Proxy ARP部署在网关上，网络中的主机不必做任何改动。
- Proxy ARP可以隐藏物理网络细节，使两个物理网络可以使用同一个网络号。
- Proxy ARP只影响主机的ARP表，对网关的ARP表和路由表没有影响。

Proxy ARP可以**分类**为：

- 路由式 Proxy ARP
- VLAN内 Proxy ARP
- VLAN间 Proxy ARP



| **类型**          | 适用场景核心差异                                       | 关键逻辑对比                        |
| ----------------- | ------------------------------------------------------ | ----------------------------------- |
| 路由式 Proxy ARP  | 同一网段、不同物理网络（广播域），**主机没配缺省网关** | 交换机查**路由表**代答 ARP          |
| VLAN 内 Proxy ARP | 同一 VLAN，但**端口隔离**（二层不通），需要三层互通    | 交换机查**本 VLAN 接口 ARP 表**代答 |
| VLAN 间 Proxy ARP | 同一网段、不同 VLAN（广播域不同），需要三层互通        | 交换机查**跨 VLAN ARP 表**代答      |




#### 路由式 Proxy ARP

路由式Proxy ARP就是使那些在同一网段却不在同一物理网络上的网络设备能够相互通信的一种功能。

**在实际应用中，如果连接设备的主机上没有配置缺省网关地址（即不知道如何到达本网络的中介系统），此时将无法进行数据转发。**

如下图所示，Host_1的IP地址为172.16.1.10/16，Host_2的IP地址为172.16.2.20/16，Host_1与Host_2处于同一网段。Switch通过VLAN10和VLAN20连接两个网络，VLANIF10和VLANIF20的IP地址不在同一个网段。

![路由式Proxy ARP典型组网应用](https://download.huawei.com/mdl/image/download?uuid=7b6a567cee024d4a988b936c899d121e)

当Host_1需要与Host_2通信时，由于目的IP地址与本机的IP地址为同一网段，因此Host_1以广播形式发送ARP请求报文，请求Host_2的MAC地址。但是，由于两台主机处于不同的物理网络（不同广播域）中，Host_2无法收到Host_1的ARP请求报文，因此也就无法应答。

通过在Switch上启用路由式Proxy ARP功能，可以解决此问题。启用路由式Proxy ARP后，Switch收到ARP请求报文后，Switch会查找路由表。由于Host_2与Switch直连，因此Switch上存在到Host_2的路由表项。Switch使用自己的MAC地址给Host_1发送ARP应答报文。Host_1将以Switch的MAC地址进行数据转发。此时，Switch相当于Host_2的代理。如上图所示，Host_1上的ARP表项中到目的地址Host_2的IP地址对应的MAC地址为Switch的VLANIF10接口的MAC地址。

**实际上是三层转发**




#### VLAN内 Proxy ARP

如果**两个用户属于相同的VLAN，但VLAN内配置了端口隔离**。此时用户间需要三层互通，可以在关联了VLAN的接口上启动VLAN内Proxy ARP功能。

如下图所示，Host_1和Host_2是Switch设备下的两个用户。连接Host_1和Host_2的两个接口在Switch属于同一个VLAN10。

![VLAN内Proxy ARP典型组网应用](https://download.huawei.com/mdl/image/download?uuid=9cc1096a29804f638d9c8770816f149b)
*VLAN内Proxy ARP典型组网应用*

由于在Switch上配置了VLAN内不同接口彼此隔离，因此Host_1和Host_2不能直接在二层互通。

若Switch的接口使能了VLAN内Proxy ARP功能，可以使Host_1和Host_2实现三层互通。Switch的接口在接收到目的地址不是自己的ARP请求报文后，Switch并不立即丢弃该报文，而是查找该接口的ARP表项。如果存在Host_2的ARP表项，则将自己的MAC地址发送给Host_1，并将Host_1发送给Host_2的报文代为转发。实际上此时Switch相当于Host_2的代理。

**实际上是三层转发**



#### VLAN间 Proxy ARP

如果两台主机处于相同网段但属于不同的VLAN，用户间要进行三层互通，可以在关联了这些VLAN的接口（例如VLANIF接口或者子接口）上使能VLAN间Proxy ARP功能。

如下图所示，Host_1和Host_2是Switch设备下的两个用户，Host_1和Host_2处于相同网段，但Host_1属于VLAN10，Host_2属于VLAN20。

![VLAN间Proxy ARP典型组网应用](https://download.huawei.com/mdl/image/download?uuid=af138abc98b34cff8982e84236fb15f4)
*VLAN间Proxy ARP典型组网应用*

由于Host_1和Host_2属于不同的[Sub-VLAN](https://info.support.huawei.com/info-finder/encyclopedia/zh/Super+VLAN.html)，Host_1和Host_2不能直接实现二层互通。

如果Switch上使能了VLAN间Proxy ARP功能，可以使Host_1和Host_2实现三层互通。Switch的接口在接收到目的地址不是自己的ARP请求报文后，并不立即丢弃该报文，而是查找ARP表项（包括动态学习的ARP表项和静态配置的ARP表项）。如果存在Host_2的ARP表项，则将自己的MAC地址发送给Host_1，并将Host_1发送给Host_2的报文代为转发。实际上此时Switch相当于Host_2的代理。

**实际上是三层转发**



----

## ARP地址解析过程

动态ARP通过广播ARP请求和单播ARP应答这两个过程完成地址解析：

![ARP地址解析过程](https://download.huawei.com/mdl/image/download?uuid=0c6bb06925f44abb8bf2376f2de9bcd4)
*ARP地址解析过程*

当需要通信的两台主机处于同一网段时，如上图中的Host_1和Host_3，Host_1要向Host_3发送数据。

1. 首先，Host_1会查找自己本地缓存的ARP表，确定是否包含Host_3对应的ARP表项。如果Host_1在ARP表中找到了Host_3对应的MAC地址，则Host_1直接利用ARP表中的MAC地址，对数据报文进行帧封装，并将数据报文发送给Host_3。如果Host_1在ARP表中找不到Host_3对应的MAC地址，则先缓存该数据报文，并以广播方式发送一个ARP请求报文。如上图中所示，OP字段为1表示该报文为ARP请求报文，ARP请求报文中的源MAC地址和源IP地址为Host_1的MAC地址和IP地址，目的MAC地址为全0的MAC地址，目的IP地址为Host_3的IP地址。

2. Switch_1收到ARP请求报文后，将该ARP请求报文在同一广播域内转发。

3. 同一广播域内的主机Host_2和Host_3都能接收到该ARP请求报文，但只有被请求的主机（即Host_3）会对该ARP请求报文进行处理。Host_3比较自己的IP地址和ARP请求报文中的目的IP地址，当两者相同时进行如下处理：将ARP请求报文中的源IP地址和源MAC地址（即Host_1的IP地址和MAC地址）存入自己的ARP表中。之后以单播方式发送ARP应答报文给Host_1，ARP应答报文内容如上图中所示，OP字段为2表示该报文为ARP应答报文，源MAC地址和源IP地址为Host_3的MAC地址和IP地址，目的MAC地址和目的IP地址为Host_1的MAC地址和IP地址。

4. Switch_1收到ARP应答报文后，将该ARP应答报文转发给Host_1。Host_1收到ARP应答报文后，将Host_3的MAC地址加入到自己的ARP表中以用于后续报文的转发，同时将数据报文进行帧封装，并将数据报文发送给Host_3。

当需要通信的**两台主机处于不同网段时**，如上图中的Host_1和Host_4，Host_1上已经配置缺省网关，Host_1首先会发送ARP请求报文，请求网关[Router](https://info.support.huawei.com/info-finder/encyclopedia/zh/路由器.html)的IP地址对应的MAC地址，**即目的MAC为网关MAC，而IP仍然是Host_4的IP**。Host_1收到ARP应答报文后，将数据报文封装并发给网关，再由网关将数据报文发送给目的主机Host_4。Host_1学习网关IP地址对应的ARP表项的过程，以及网关设备学习Host_4的IP地址对应的ARP表项的过程与上述同网段主机Host_1和Host_3之间进行ARP地址解析的过程类似，不再赘述。



----

## ARP老化机制

如上图中所示，如果每次Host_1和Host_3通信前都要发送一个广播的ARP请求报文，会极大的增加网络负担。而且同广播域的所有设备都需要接收和处理这个广播的ARP请求报文，也极大的影响了网络中设备的运行效率。为了解决以上问题，每台主机或设备上都维护着一个高速缓存，这是ARP高效运行的一个关键。在这个高速缓存中，存放主机或设备最近学习到的IP地址到MAC地址的映射关系，即动态ARP表项。

主机或设备每次发送报文时，会先在本地高速缓存中查找目的IP地址所对应的MAC地址。如果高速缓存中有对应的MAC地址，主机或设备不会再发送ARP请求报文，而是直接将报文发至这个MAC地址；如果高速缓存中没有对应的MAC地址，主机或设备才会广播发送ARP请求报文，进行ARP地址解析。

一方面由于高速缓存的容量限制，另一方面为了保证高速缓存中ARP表项的准确性，设备会对动态ARP表项进行老化和更新。

动态ARP表项的老化参数有：老化超时时间、老化探测次数和老化探测模式。**设备上动态ARP表项到达老化超时时间后，设备会发送老化探测报文（即ARP请求报文），如果能收到ARP应答报文，则更新该动态ARP表项，本次老化探测结束；如果超过设置的老化探测次数后仍没有收到ARP应答报文，则删除该动态ARP表项，本次老化探测结束。**

设备发送的老化探测报文**可以是单播报文，也可以是广播报文。缺省网关情况下，设备只在最后一次发送ARP老化探测报文是广播模式，其余均为单播模式发送**（因为一次即可获取MAC）。当对端设备MAC地址不变时，可以配置接口以单播模式发送ARP老化探测报文。

**当接口Down时设备会立即删除相应的动态ARP表项。**



----

## ARP报文格式

报文的**长度是42字节**。前14字节的内容表示**以太网首部**，后28字节的内容表示**ARP请求或应答**报文的内容。报文中相关字段的解释如下图:



| Part       | 字段名(ZH)     | 字段名(EN)                       | 长度(bit) | 值                  | 含义                                                         |
| ---------- | ------------- | ------------------------------- | --------- | ------------------- | ------------------------------------------------------------ |
| 以太网首部 | 以太网目的MAC | Ethernet Address of Destination | 48比特    | 0xFFFF-FFFF-FFFF    | 以太网目的MAC地址。发送ARP请求时，为广播的MAC地址，0xFFFF-FFFF-FFFF。 |
| 以太网首部 | 以太网源MAC   | Ethernet Address of Sender      | 48比特    | ....                | 以太网源MAC地址。                                            |
| 以太网首部 | 帧类型        | Frame Type                      | 16比特    | 0x0806              | 表示后面数据的类型。对于ARP请求或应答来说，该字段的值为0x0806。 |
| ARP报文    | 硬件地址类型  | Hardware Type                   | 16比特    | 1                   | 表示硬件地址的类型。对于以太网，该类型的值为“1”。            |
| ARP报文    | 协议地址类型  | Protocol Type                   | 16比特    | 0x0800              | 表示发送方要映射的协议地址类型。对于IP地址，该值为0x0800。   |
| ARP报文    | 硬件地址长度  | Hardware Length                 | 8比特     |                     | 表示硬件地址的长度，单位是字节。对于ARP请求或应答来说，该值为6。 |
| ARP报文    | 协议地址长度  | Protocol Length                 | 8比特     |                     | 表示协议地址的长度，单位是字节。对于ARP请求或应答来说，该值为4。 |
| ARP报文    | OP            | OP                              | 16比特    |                     | 操作类型:<br />1 ARP请求<br />2 ARP应答<br />3 RARP请求<br />4 RARP应答 |
| ARP报文    | 源MAC         | Ethernet Address of Sender      | 48比特    |                     | 发送方以太网地址。这个字段和ARP报文首部的源以太网地址字段是重复信息。 |
| ARP报文    | 源IP          | IP Address of Sender            | 32比特    |                     | 发送方的IP地址。                                             |
| ARP报文    | 目的MAC       | Ethernet Address of Destination | 48比特    | 0x00.00.00.00.00.00 | 接收方的以太网地址。发送ARP请求时，该处填充为0x00.00.00.00.00.00。回应ARP请求时，该处填充为实际解析的MAC。 |
| ARP报文    | 目的IP        | IP Address of Destination       | 32比特    |                     | 接收方的IP地址。                                             |











----

> - [Reference Doc 1](https://info.support.huawei.com/info-finder/encyclopedia/zh/ARP.html)
> - [Reference Doc 2](https://support.huawei.com/enterprise/zh/doc/EDOC1100174722/d2b66059)

