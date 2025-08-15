# L2-NCP

NCP（Network Control Protocol，网络控制协议）用于建立、配置网络层协议，进行参数协商。



----

### 概述


**不同的网络层协议会使用不同的NCP协议**:


| 网络层协议                | NCP 协议                          | NCP 全称                  | 说明                                                                 |
| ------------------------- | ---------------------------------------- | ------------------------- | -------------------------------------------------------------------- |
| IP 协议（IPv4）           | IPCP（Internet Protocol Control Protocol） | IP 控制协议               | 最常用的 NCP，协商 IPv4 地址、DNS 服务器地址等 IPv4 相关参数           |
| IPv6 协议                 | IPv6CP（IPv6 Control Protocol）           | IPv6 控制协议             | 针对 IPv6，协商 IPv6 地址、前缀等网络层参数                           |
| AppleTalk 协议            | AppleTalk Control Protocol（ATCP）        | AppleTalk 控制协议        | 用于 AppleTalk 网络，协商节点地址、网络编号等参数                     |
| Novell IPX/SPX 协议       | IPXCP（IPX Control Protocol）              | IPX 控制协议              | 为 IPX/SPX 协议簇服务，协商 IPX 网络地址、帧类型等参数                |
| DECnet 协议               | DECnet Control Protocol（DNCP）            | DECnet 控制协议           | 针对 DECnet 网络，协商节点标识、网络路由等特有参数                    |
| OSI 网络层协议（如 CLNP） | OSI Control Protocol（OSICP）              | OSI 控制协议              | 支持 OSI 模型，协商 CLNP（无连接网络协议）等参数                      |
| XNS（Xerox Network Systems） | XNS Control Protocol（XNSCP）              | XNS 控制协议              | 用于 Xerox 网络系统，协商 XNS 网络地址、传输层关联等参数              |




----

### IPCP协议

IPCP（Internet Protocol Control Protocol），IP控制协议。

当PPP帧中Protocol字段取值0x8021时，表示PPP帧正在使用IPCP协商相关通信参数。

IPCP会完成协商IP地址等工作，其后在该PPP链路上传送IP数据报；

若IP数据报传送完毕，若要关闭IP协议，仍需通过IPCP协商终止；

若要释放链路，则需借助LCP协议。



#### 报文格式

与LCP一样:


| *Field* | Code | Identifier/ID | Length | Data |
| -- | -- | -- | -- | -- |
| *Value* | -- | -- | -- | -- |
| *Length(byte)* | 1 | 1 | 2 | Value(Length)-OtherLength(4); Default max 1500-4=1496 |
| *Part* | Code | Identifier/ID | Length | Data |
| *Order* | Send First | -- | -- | Send End |


- **Code**为代码字段（也称类型字段），长度为1字节，用来标识IPCP中报文的类型。详细类型见下方。

- **Identifier**为标识符字段，长度为1字节，是报文的唯一标识。Identifier字段用于匹配请求和回复。

- **Length**为长度字段，长度为2字节，Length字段指出该报文的长度，包括Code，Identifier，Length和Data。数据包的长度由链路的最大接收单元（Maximum Receive Unit，MRU）决定，MRU指定了PPP链路上可接收的最大帧长度。默认MRU值为1500字节，但可通过LCP协商调整，取两端最小MRU值。

- **Data**为数据字段，长度是零或多个八位字节，由Length字段声明。Data字段的格式由Code字段决定。


#### 报文类型

##### 概述

| 类型	|  功能	 | 报文类型	|  报文代码(Code)  |
| -- | -- | -- | -- |
| 链路配置	| 建立和配置链路	| Configure-Request	| 1 |
| 链路配置	| 建立和配置链路	| Configure-Ack	| 2 |
| 链路配置	| 建立和配置链路	| Configure-Nak	| 3 |
| 链路配置	| 建立和配置链路	| Configure-Reject	| 4 |
| 链路终止	| 终止链路	| Terminate-Request	| 5 |
| 链路终止	| 终止链路	| Terminate-Ack	| 6 |
| 链路维护	| 管理和调试链路	| Code-Reject	| 7 |

与LCP报文格式几乎一样，但少了一些链路维护报文。



##### 链路配置报文


同LCP，链路配置时，IPCP报文格式中的**Data**字段值为一到多个**选项(Options)**列表，选项列表中的参数可同时协商。**选项(Options)**格式如下:

| *Field* | Type | Length | Data |
| -- | -- | -- | -- |
| *Value* | -- | -- | -- |
| *Length(byte)* | 1 | 1 | Value(Length)-Length(Type) |
| *Part* | Code | Length | Data |
| *Order* | Send First | -- | Send End |


- **Type**为类型字段，用于区分协商不同参数。

    | **Type值** | **选项名称**                  | **功能描述**                                    | **数据域格式**                          |
    | ------------ | ----------------------------- | ----------------------------------------------- | --------------------------------------- |
    | **2**        | IP Compression Protocol       | 协商IP包头压缩协议（如Van Jacobson压缩）        | 2字节协议号 + 压缩参数（如Max-Slot-Id） |
    | **3**        | IP Address                    | 协商本地接口的IPv4地址（取代早期有问题的类型1） | 4字节IPv4地址（全0表示请求分配地址）    |
    | **129**      | Primary DNS Server Address    | 协商主DNS服务器地址                             | 4字节IPv4地址（全0表示请求分配）        |
    | **131**      | Secondary DNS Server Address  | 协商备用DNS服务器地址                           | 4字节IPv4地址（全0表示请求分配）        |
    | **130**      | Primary NBNS Server Address   | 协商主NetBIOS名称服务器地址（用于Windows网络）  | 4字节IPv4地址                           |
    | **132**      | Secondary NBNS Server Address | 协商备用NetBIOS名称服务器地址                   | 4字节IPv4地址                           |

    > - **废弃选项**：类型1（IP-Addresses）因实现问题已被RFC1332废弃，由类型3（IP-Address）替代。
    > - **特殊值规则**：若数据域全为0，表示请求对端分配该参数（如IP地址或DNS地址）。
    > - **Van Jacobson压缩**仅适用于TCP流量，非TCP包（如UDP/ICMP）不压缩

- **Length**为长度字段，Length字段指出该配置选项（包括Type、Length和Data字段）的长度。

- **Data**为数据字段，Data字段为零或者多个字节，其中包含配置选项的特定详细信息。


**报文例子**:

   | PPP Field | IPCP Field | Configure Options Field | Bytes | Value | Comment |
   | ---------- | ------ | -------- | ------ | --------------- | --------------- |
   | Flag       | -      | -        | 1      | 0x7E            |     |
   | Address    | -      | -        | 1      | 0xFF            |     |
   | Control    | -      | -        | 1      | 0x03            |     |
   | Protocol   | -      | -        | 2      | 0x8021          |     |
   | Data       | Code   | -        | 1      | 1            |     |
   | Data       | ID     | -        | 1      | 1            |     |
   | Data       | Length | -        | 2      | 16            |     |
   | Data       | Data   | Type     | 1      | 1            |     |
   | Data       | Data | Length   | 1      | 6            |     |
   | Data       | Data    | Data | 4      | 0x002d 0f01    |  TCP/IP报头压缩   |
   | Data       | Data   | Type     | 1      | 3            |     |
   | Data       | Data | Length   | 1     | 6            |     |
   | Data       | Data   | Data | 4      | 0x00 00 00 00          |  发送0.0.0.0, 请求分配IP   |
   | FCS        | -      | -        | 2      | -         |  Frame Checksum   |
   | Flag       | -      | -        | 1      | 0x7E            |     |




###### IP Address [Type=0x03]

- **作用**：动态或静态分配IPv4地址。

- **协商流程**：

  - **动态分配**：客户端发送全0地址 → 服务器回复NAK携带分配的IP → 客户端重新请求该地址 → 服务器回复ACK。
  - **静态分配**：双方直接发送自身IP的Configure-Request，互发ACK确认。

- **示例**：

  ```
  类型: 0x03 | 长度: 0x06 | 数据: 192.168.1.1
  ```



###### IP Compression Protocol [Type=0x02]

- **支持协议**：
  - **Van Jacobson TCP/IP压缩**（协议号`0x002D`）：将TCP/IP包头压缩至3字节，用于低速链路。
- **参数**：
  - `Max-Slot-Id`：最大压缩槽编号（默认0-15）。
  - `Comp-Slot-Id`：槽标记压缩标志位（0=不压缩，1=压缩）。



###### DNS/NBNS服务器地址 [Type=129-132]

- **动态分配**：客户端发送全0请求 → 服务器通过NAK返回实际地址。
- **应用场景**：拨号上网时由ISP自动分配DNS服务器。




#### 协商过程

IPCP在PPP的**Network阶段**启动，使用与LCP相同的协商机制（Configure-Request/Ack/Nak/Reject），但协议号固定为`0x8021`。

**典型交互流程**：

| 发起方动作描述       | 交互方向 | 报文/数据类型                          | 接收方动作描述                 |
|----------------------|----------|---------------------------------------|--------------------------------|
| 发送IP参数配置请求   | →        | Configure-Request(IP=0.0.0.0, DNS=0.0.0.0) | -                              |
| -                    | ←        | Configure-Nak(IP=10.1.1.2, DNS=8.8.8.8)    | 返回需修改的IP和DNS参数        |
| 按修改后参数重发请求 | →        | Configure-Request(IP=10.1.1.2, DNS=8.8.8.8) | -                              |
| -                    | ←        | Configure-Ack                         | 确认参数配置有效               |


**状态迁移条件**：

- **成功**：收到Configure-Ack后状态转为`Opened`，允许传输IP数据（协议号`0x0021`）。
- **失败**：若选项不被支持（如类型1），返回Configure-Reject终止协商。



#### 区别: IPCP的IP vs 常规的IP

|   **特性/能力**   |                **IPCP**                 |                **DHCP**                |
| :----------: | :-------------------------------------: | :------------------------------------: |
| **协议层级** | PPP协议栈的网络控制子协议（数据链路层） |      独立的应用层协议（基于UDP）       |
| **核心作用** |    在PPP链路上协商**单接口**的IP地址，**仅在链路本地端使用**    | 为**整个网络**动态分配IP地址及全局配置 |
| **依赖关系** |       需先建立PPP链路（如PPPoE）        |  直接基于IP/UDP运行，无需底层协议绑定  |
|  **IP地址分配**   | 仅支持单个IPv4地址  |         支持IPv4/IPv6地址池          |
| **DNS服务器配置** | 通过选项129/131传递 | 通过`option domain-name-servers`分配 |
|   **网关配置**    |     不直接支持      |       通过`option routers`指定       |
| **地址冲突检测**  |       无机制        |       客户端主动检测ARP冲突         |
|  **跨网段支持**   |   限于PPP直连链路   |        通过DHCP中继代理实现         |


**Notice**: 在默认情况下，IPCP不分配IP地址。


**应用场景**：

1. **PPPoE拨号上网（用户 → ISP）**

   - **流程**：

     用户PC（PPPoE客户端）通过IPCP从ISP服务器获取公网IP（如`10.0.0.2`）。

   - **作用**：

     - PC可基于该IP访问互联网（作为源地址）。
     - ISP路由表将该IP指向PPP虚拟接口，实现回程路由。

2. **企业专线互联（路由器A ↔ 路由器B）**

   - **需求**：

     通过串行链路/VPN隧道连接两个分支机构。

   - **IPCP操作**：

     协商两端接口IP（如A端`192.168.1.1`，B端`192.168.1.2`）。

   - **作用**：

     - 双方可通过该直连IP互访（如BGP邻居建立）。
     - OSPF等路由协议将其视为直连网络（`192.168.1.0/30`）。

3. **4G/5G物联网设备接入**

   - 蜂窝模块通过IPCP获取运营商分配的私网IP。
   - 设备凭借该IP与云平台通信（上传数据/接收指令）。



**核心作用**

1. **建立网络层通信能力**

   IPCP为PPP链路两端分配的IPv4地址，使点对点直连的两台设备具备**三层互通能力**：

   - **直接通信**：双方可直接使用该地址互访（如`ping`对方IP或建立TCP连接）。
   - **路由可达**：地址可被添加到路由表中，作为路径下一跳或数据包源/目的地址。

2. **作为高层协议传输载体**

   该地址是链路层（PPP）向网络层（IP）提供的**逻辑接口标识**，支持：

   - TCP/UDP应用数据传输（如HTTP、SSH）。
   - ICMP协议操作（如`ping`、`traceroute`）。




----

> [Reference Doc 1](https://blog.csdn.net/HinsCoder/article/details/130454920)
