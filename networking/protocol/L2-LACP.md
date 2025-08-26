# L2-LACP

LACP, Link Aggregation Control Protocol, 链路汇聚控制协议。是一种实现链路动态汇聚与解汇聚的协议。

LACP 协议通过LACPDU（Link Aggregation Control Protocol Data Unit，链路汇聚控制协议数据单元）与对端交互信息。

LACPDU帧为慢协议（平均每秒发送的协议报文不超过5个），如果接口板收到报文的DMAC是特殊的组播地址0x01-80-c2-00-00-02，二层协议类型字段为0x8809，协议子类型为0x01，则说明此数据报文为LACPDU帧。

随着网络规模不断扩大，用户对骨干链路的带宽和可靠性提出了越来越高的要求。在传统技术中，常用更换高速率的接口板或更换支持高速率接口板的设备的方式来增加带宽，但这种方案需要付出高额的费用，而且不够灵活。采用链路聚合技术（LACP）可以在不进行硬件升级的条件下，通过将多个物理接口捆绑为一个逻辑接口，来达到增加链路带宽的目的。在实现增大带宽目的的同时，链路聚合采用备份链路的机制，可以有效的提高设备之间链路的可靠性。



----

## 链路聚合原理

链路聚合是**把两台设备之间的多条物理链路聚合在一起，当做一条逻辑链路来使用**。这两台设备可以是一对路由器，一对交换机，或者是一台路由器和一台交换机。一条聚合链路可以包含多条成员链路；链路聚合能够提高链路带宽。理论上，通过聚合几条链路，一个聚合口的带宽可以扩展为所有成员口带宽的总和，这样就有效地增加了逻辑链路的带宽。

链路聚合为网络提供了高可靠性。配置了链路聚合之后，如果一个成员接口发生故障，该成员口的物理链路会把流量切换到另一条成员链路上。

链路聚合还可以在一个聚合口上实现**负载均衡**，一个聚合口可以把流量分散到多个不同的成员口上，通过成员链路把流量发送到同一个目的地，将网络产生拥塞的可能性降到最低。

|         |        | Eth-Trunk1 |        |         |
| ------- | ------ | ---------- | ------ | ------- |
|         | G0/0/1 | ←→         | G0/0/1 |         |
| SwitchA | G0/0/2 | ←→         | G0/0/2 | SwitchB |
|         | G0/0/3 | ←→         | G0/0/3 |         |



----

## 链路聚合模式

链路聚合包含两种模式：

- 手动负载均衡模式
- LACP（Link Aggregation Control Protocol）模式



### 手工负载分担模式

Eth-Trunk的建立、成员接口的加入由手工配置，**没有链路聚合控制协议的参与。该模式下所有活动链路都参与数据的转发，平均分担流量，因此称为负载分担模式**。如果某条活动链路故障，链路聚合组自动*在剩余的活动链路中平均分担流量*。当需要在两个直连设备间提供一个较大的链路带宽而设备又不支持LACP协议时，可以使用手工负载分担模式。



### LACP模式链路聚合

LACP模式又分为：

- 静态LACP模式
- 动态LACP模式

**静态LACP模式**和**动态LACP模式**在LACP协议交互方面没有区别，链路两端的设备相互发送LACP报文，协商聚合参数。协商完成后，两台设备确定活动接口和非活动接口。需要手动创建一个Eth-Trunk口，并添加成员口。LACP协商选举活动接口和非活动接口。LACP模式也叫M:N模式。M代表**活动成员链路**，用于在**负载均衡**模式中转发数据。N代表**非活动成员链路**，用于**冗余备份**。如果一条活动链路发生故障，该链路传输的数据被切换到一条优先级最高的备份链路上，这条*备份链路转变为活动状态*。

**静态LACP模式**和**动态LACP模式**区别在于：两种模式在LACP协商失败后的处理不一致

- 静态LACP模式下，LACP协商失败后Eth-Trunk变为Down，不能转发数据。

- 动态LACP模式下，LACP协商失败后Eth-Trunk变为Down，但其成员接口继承Eth-Trunk的VLAN属性状态变为Indep，可独立进行二层数据转发。



#### 基本概念

- 系统LACP优先级

  LACP模式下，两端设备所选择的活动接口必须保持一致，否则链路聚合组就无法建立。而要想使两端活动接口保持一致，可以使其中一端具有更高的优先级，另一端根据高优先级的一端来选择活动接口即可。系统LACP优先级就是为了区分两端设备优先级的高低而配置的参数，系统LACP优先级值越小优先级越高。

- 接口LACP优先级

  接口LACP优先级是为了区别同一个Eth-Trunk中的不同接口被选为活动接口的优先程度，优先级高的接口将优先被选为活动接口。接口LACP优先级值越小，优先级越高。



#### LACP模式实现原理

基于IEEE802.3ad标准的LACP是一种实现链路动态聚合与解聚合的协议。LACP通过链路聚合控制协议数据单元LACPDU（Link Aggregation Control Protocol Data Unit）与对端交互信息。

在LACP模式的Eth-Trunk中加入成员接口后，这些接口将通过发送LACPDU向对端通告自己的系统优先级、MAC地址、接口优先级、接口号和操作Key（用来判断各接口相连对端是否在同一聚合组以及各接口带宽是否一致等）等信息。对端接收到这些信息后，将这些信息与自身接口所保存的信息比较，用以选择能够聚合的接口，双方对哪些接口能够成为活动接口达成一致，确定活动链路。

- LACP模式Eth-Trunk建立的过程如下：

  1. 两端互相发送LACPDU报文：

     DeviceA和DeviceB上创建Eth-Trunk并配置为LACP模式，然后向Eth-Trunk中手工加入成员接口。此时成员接口上便启用了LACP协议，两端互发LACPDU报文。

     Actor_State中的LACP_Activity标准可以设置主动模式或被动模式，必须有一方为主动模式，各主动模式端口开始周期性发送​​LACPDU报文，被动模式仅回复而不主动发送LACPDU​​。

  2. 确定主动端和活动链路：

     两端设备均会收到对端发来的LACPDU报文。以DeviceB为例，当DeviceB收到DeviceA发送的报文时，DeviceB会查看并记录对端信息，然后比较**系统优先级**字段，如果DeviceA的系统优先级高于本端的系统优先级，则确定DeviceA为LACP主动端。如果DeviceA和DeviceB的系统优先级相同，比较两端设备的MAC地址，确定MAC地址小的一端为LACP主动端。

     选出主动端后，两端都会以**主动端的接口优先级**来选择活动接口，两端设备选择了一致的活动接口，活动链路组便可以建立起来，从活动链路中转发数据。

- LACP抢占

  使能LACP抢占功能后，聚合组会始终**保持高优先级的接口作为活动接口**的状态。

  接口Port1、Port2和Port3为Eth-Trunk的成员接口，DeviceA为主动端，活动接口数上限阈值为2，三个接口的LACP优先级分别为10、20、30。当通过LACP协议协商完毕后，接口Port1和Port2因为优先级较高被选作活动接口，Port3成为备份接口。

  以下两种情况需要**使能LACP的抢占功能**：

  - Port1接口出现故障而后又恢复了正常。当接口Port1出现故障时被Port3所取代，缺省情况下，故障恢复时Port1将处于备份状态；如果使能了LACP抢占功能，当Port1故障恢复时，由于接口优先级比Port3高，将重新成为活动接口，Port3再次成为备份接口。
  - 如果希望Port3接口替换Port1、Port2中的一个接口成为活动接口，可以使能了LACP抢占功能，并配置Port3的接口LACP优先级较高。如果没有使能LACP抢占功能，即使将备份接口的优先级调整为高于当前活动接口的优先级，系统也不会进行重新选择活动接口的过程，不切换活动接口。

- LACP抢占延时

  配置抢占延时是为了避免由于某些**链路状态频繁变化**而导致Eth-Trunk数据传输不稳定的情况。抢占延时是LACP抢占发生时，处于备用状态的链路将会等待一段时间后再切换到转发状态。

- 活动链路与非活动链路切换

  LACP模式链路聚合组两端设备中任何一端检测到以下事件，都会触发聚合组的链路切换：

  - 链路Down事件。
  - LACP协议发现链路故障。
  - 接口不可用。
  - 在使能了LACP抢占功能的前提下，更改备份接口的优先级高于当前活动接口的优先级。

  当满足上述切换条件其中之一时，按照如下步骤进行切换：

  1. 关闭故障链路。
  2. 从N条备份链路中选择优先级最高的链路接替活动链路中的故障链路。
  3. 优先级最高的备份链路转为活动状态并转发数据，完成切换。




#### LACP帧

基于**IEEE802.3ad**标准的LACP（Link Aggregation Control Protocol），链路汇聚控制协议是一种实现链路动态聚合与解聚合的协议。LACP协议通过**LACPDU（Link Aggregation Control Protocol Data Unit）**与对端交互信息。LACPDU帧为慢协议（平均每秒发送的协议报文不超过5个），如果接口板收到报文的DMAC是特殊的组播地址0x01-80-c2-00-00-02，二层协议类型字段为0x8809，协议子类型为0x01，则说明此数据报文为LACPDU帧。

##### 帧格式

```
   +-------------------------------+
   |     Destination Address       |
   +-------------------------------+
   |        Source Address         |
   +-------------------------------+
   |         Length/Type           |
   +-------------------------------+
   |        Subtype = LACP         |
   +-------------------------------+
   |       Version Number          |
   +-------------------------------+
   | TLV_type = Actor Information  |
   +-------------------------------+
   | Actor_Information_Length = 20 |
   +-------------------------------+
   |    Actor_System_Priority      |
   +-------------------------------+
   |        Actor_System           |
   +-------------------------------+
   |        Actor_key              |
   +-------------------------------+
   |      Actor_Port_Priority      |
   +-------------------------------+
   |         Actor_Port            |
   +-------------------------------+
   |         Actor_State           |
   +-------------------------------+
   |          Reserved             |
   +-------------------------------+
   | TLV_Type=Partner Information  |
   +-------------------------------+
   | Partner_Information_length=20 |
   +-------------------------------+
   |    Partner_System_Priority    |
   +-------------------------------+
   |       Partner_System          |
   +-------------------------------+
   |        Partner_Key            |
   +-------------------------------+
   |     Partner_Port_Priority     |
   +-------------------------------+
   |         Partner_Port          |
   +-------------------------------+
   |         Partner_State         |
   +-------------------------------+
   |           Reserved            |
   +-------------------------------+
   | TLV_type=Collector Information|
   +-------------------------------+
   |Collector_Information_Length=16|
   +-------------------------------+
   |      CollectorMaxDelay        |
   +-------------------------------+
   |            Reserved           |
   +-------------------------------+
   |      TLV_type = Terminator    |
   +-------------------------------+
   |     Terminator_Length=0       |
   +-------------------------------+
   |            Reserved           |
   +-------------------------------+
   |               FCS             |
   +-------------------------------+
```

##### 字段解释

| 字段                              | 长度   | 说明                                                         |
| --------------------------------- | ------ | ------------------------------------------------------------ |
| Destination Address               | 6字节  | 目的MAC地址，是一个组播地址（01-80-C2-00-00-02）。           |
| Source Address                    | 6字节  | 源MAC地址，发送端口的MAC地址。                               |
| Length/Type                       | 2字节  | 协议类型：0x8809。                                           |
| Subtype                           | 1字节  | 报文子类型：0x01，说明是LACP报文。                           |
| Version Number                    | 1字节  | 协议版本号：0x01。                                           |
| TLV_type = Actor Information      | 1字节  | 标识TLV的类型，值为0x01代表Actor字段。                       |
| Actor_Information_Length          | 1字节  | actor信息字段长度，取值为20（即0x14），以字节为单位。        |
| Actor_System_Priority             | 2字节  | 本端系统优先级，可以设置，默认情况下为32768(即0x8000)。      |
| Actor_System                      | 6字节  | 系统ID，本端系统的MAC地址。                                  |
| Actor_key                         | 2字节  | 端口KEY值，系统根据端口的配置生成，是端口能否成为聚合组中的一员的关键因素，影响Key值的因素有trunk ID、接口的速率和双工模式。 |
| Actor_Port_Priority               | 2字节  | 接口优先级，可以配置，默认为0x8000。                         |
| Actor_Port                        | 2字节  | 端口号，根据算法生成，由接口所在的槽位号、子卡号和端口号决定。 |
| Actor_State                       | 1字节  | 本端状态信息，比特0~7的含义分别为：<br/>- LACP_Activity：代表链路所在的聚合组参与LACP协商的方式。主动的LACP被编码为1，主动方式下会主动发送LACPDU报文给对方，被动方式不会主动发送协商报文，除非收到协商报文才会参与。<br/>- LACP_Timeout：代表链路接收LACPDU报文的周期，有两种，快周期1s和慢周期30s，超时时间为周期的3倍。短超时被编码为1，长超时被编码为0。<br/>- Aggregation：标识该链路能否被聚合组聚合。如果编码为0，该链路被认为是独立的，不能被聚合，即，这个链路只能作为一个个体链路运行。<br/>- Synchronization：代表该链路是否已被分配到一个正确的链路聚合组，如果该链路已经关联了一个兼容的聚合器，那么该链路聚合组的识别与系统ID和被发送的运行Key信息是一致的。编码为0，代表链路当前不在正确的聚合里。<br/>- Collecting：帧的收集使能位，假如编码为1，表示在这个链路上进来的帧的收集是明确使能的；即收集当前被使能，并且不期望在没有管理变化或接收协议信息变化的情况下被禁止。其它情况下这个值编码为0。<br/>- Distributing：帧的分配使能位，假如编码为0，意味着在这个链路上的外出帧的分配被明确禁止，并且不期望在没有管理变化或接收协议信息变化的情况下被使能。其它情况下这个值编码为1。<br/>- Default：诊断调试时使用，编码为1，代表接收到的对端的信息是管理配置的。假如编码为0，正在使用的运行伙伴信息在接收到的LACPDU里。该值不被正常LACP协议使用，仅用于诊断协议问题。<br/>- Expired：诊断调试时使用，编码为1，代表本端的接收机是处于EXPIRED超时状态；假如编码为0，本端接收状态机处于正常状态。该值不被正常LACP协议使用，仅用于诊断协议问题。 |
| Reserved                          | 3字节  | 保留字段，可用于功能调试以及扩展。                           |
| TLV_type = Partner Information    | 1字节  | 标识TLV的类型，值为0x02代表Partner字段。                     |
| Partner_Information_Length        | 1字节  | Partner信息字段长度，取值为20（即0x14），以字节为单位。Partner字段代表了链路接口接收到对端的系统信息、接口信息和状态信息，与actor字段含义一致。在协商最开始未收到对端信息时，partner字段填充0，接收到对端信息后会把收到的对端信息补充到partner字段当中。 |
| Partner_System_Priority           | 2字节  | 对端系统优先级。                                             |
| Partner_System                    | 6字节  | 对端系统ID，对端系统的MAC地址。                              |
| Partner_key                       | 2字节  | 对端端口KEY值。                                              |
| Partner_Port_Priority             | 2字节  | 对端接口优先级。                                             |
| Partner_Port                      | 2字节  | 对端端口号。                                                 |
| Partner_State                     | 1字节  | 对端状态信息。                                               |
| Reserved                          | 3字节  | 保留字段，可用于功能调试以及扩展。                           |
| TLV_type = Collector Information  | 1字节  | 标识TLV的类型，值为0x03代表Collector字段。                   |
| Collector_Information_Length      | 1字节  | Collector信息字段长度，取值为16（即0x10），以字节为单位。    |
| CollectorMaxDelay                 | 2字节  | 最大延时，以10微秒为单位。                                   |
| Reserved                          | 12字节 | 保留字段，可用于功能调试以及扩展。                           |
| TLV_type = Terminator Information | 1字节  | 标识TLV的类型，值为0x00代表Terminator字段。                  |
| Terminator_Length                 | 1字节  | Terminator信息字段长度，取值为0（即0x00）。                  |
| Reserved                          | 50字节 | 保留字段，全置0，接收端忽略此字段。                          |
| FCS                               | 4字节  | 用于帧内后续字节差错的循环冗余检验（也称为FCS或帧检验序列）。 |

##### 报文示例

```
Frame 1: 128 bytes on wire (1024 bits), 128 bytes captured (1024 bits)
    Arrival Time: Jul  6, 2011 15:51:27.199195000
    Epoch Time: 1309938687.199195000 seconds
    [Time delta from previous captured frame: 0.000000000 seconds]
    [Time delta from previous displayed frame: 0.000000000 seconds]
    [Time since reference or first frame: 0.000000000 seconds]
    Frame Number: 1
    Frame Length: 128 bytes (1024 bits)
    Capture Length: 128 bytes (1024 bits)
    [Frame is marked: False]
    [Frame is ignored: False]
    [Protocols in frame: eth:slow]
    [Coloring Rule Name: Broadcast]
    [Coloring Rule String: eth[0] & 1]
Ethernet II, Src: HuaweiTe_3f:17:8f (00:18:82:3f:17:8f), Dst: Slow-Protocols (01:80:c2:00:00:02)
    Destination: Slow-Protocols (01:80:c2:00:00:02)
        Address: Slow-Protocols (01:80:c2:00:00:02)
        .... ...1 .... .... .... .... = IG bit: Group address (multicast/broadcast)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
    Source: HuaweiTe_3f:17:8f (00:18:82:3f:17:8f)
        Address: HuaweiTe_3f:17:8f (00:18:82:3f:17:8f)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
    Type: Slow Protocols (0x8809)
Link Aggregation Control Protocol
    Slow Protocols subtype: LACP (0x01)
    LACP Version Number: 0x01
    Actor Information: 0x01
    Actor Information Length: 0x14
    Actor System Priority: 100
    Actor System: HuaweiTe_3f:17:8f (00:18:82:3f:17:8f)
    Actor Key: 6449
    Actor Port Priority: 100
    Actor Port: 1811
    Actor State: 0x3d (Activity, Aggregation, Synchronization, Collecting, Distributing)
        .... ...1 = LACP Activity: Yes
        .... ..0. = LACP Timeout: No
        .... .1.. = Aggregation: Yes
        .... 1... = Synchronization: Yes
        ...1 .... = Collecting: Yes
        ..1. .... = Distributing: Yes
        .0.. .... = Defaulted: No
        0... .... = Expired: No
    Reserved: 000000
    Partner Information: 0x02
    Partner Information Length: 0x14
    Partner System Priority: 1
    Partner System: HuaweiTe_93:e1:98 (28:6e:d4:93:e1:98)
    Partner Key: 6449
    Partner Port Priority: 100
    Partner Port: 260
    Partner State: 0x0f (Activity, Timeout, Aggregation, Synchronization)
        .... ...1 = LACP Activity: Yes
        .... ..1. = LACP Timeout: Yes
        .... .1.. = Aggregation: Yes
        .... 1... = Synchronization: Yes
        ...0 .... = Collecting: No
        ..0. .... = Distributing: No
        .0.. .... = Defaulted: No
        0... .... = Expired: No
    Reserved: 000000
    Collector Information: 0x03
    Collector Information Length: 0x10
    Collector Max Delay: 65535
    Reserved: 000000000000000000000000
    Terminator Information: 0x00
    Terminator Length: 0x00
    Reserved: 000000000000000000000000000000000000000000000000...
```




----

## 链路聚合负载分担类型

- 根据报文的**源MAC**地址进行负载分担

- 根据报文的**目的MAC**地址进行负载分担

- 根据报文的**源IP地址**进行负载分担

- 根据报文的**目的IP地址**进行负载分担

- 根据报文的**源MAC地址和目的MAC地址**进行负载分担

- 根据报文的**源IP地址和目的IP地址**进行负载分担

- 根据报文的**VLAN、源物理端口等对L2、IPv4、IPv6和MPLS报文**进行增强型负载分担




---- 

## LACP vs PAgP

LACP和**PAgP（Port Aggregation Protocol，端口汇聚协议）**是链路聚合中使用最广泛的两种协商协议。LACP和PAgP的功能类似，都是通过捆绑链路并协商成员链路之间的流量提高网络的可用性和稳定性。LACP和PAgP数据包在交换机之间通过支持以太网通道的端口交换。

它们之间最大的区别是支持的供应商不同，LACP是开放标准，可以在大多数交换机上运行，如华为S5700系列交换机，而PAgP是Cisco专有协议，只能在Cisco或支持PAgP的第三方交换机上运行。


|对比项|LACP|PAgP|
| ---- | ---- | ---- |
|协议标准|开放标准|Cisco专有|
|支持设备|大多数交换机|Cisco或支持PAgP的第三方交换机|
|工作模式|Active：主动协商模式，接口通过发送LACP数据包发起与其他接口的协商。<br><br>Passive：（默认模式）被动协商模式，接口响应收到的LACP数据包，但不发起LACP协商。|Desirable：主动协商模式，接口通过发送PAgP数据包发起与其他接口的协商。<br><br>Auto：（默认模式）被动协商模式，接口响应收到的PAgP数据包，但不发起PAgP协商。|









----

> - [Reference Doc 1](https://support.huawei.com/enterprise/zh/doc/EDOC1100174722/daca9171)
> - [Reference Doc 2](https://zhuanlan.zhihu.com/p/19033070064)
> - [Reference Doc 3](https://support.huawei.com/enterprise/zh/doc/EDOC1100420453/b1d8b5a3)

