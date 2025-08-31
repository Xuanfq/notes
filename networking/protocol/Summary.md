# Summary


## Protocol Standard

- Request For Comments: [Where and how to get new RFCs](https://www.ietf.org/rfc/rfc-retrieval.txt.pdf)
  - https://www.rfc-editor.org/
  - https://www.rfc-editor.org/rfc-index2.html
  - https://www.freesoft.org/CIE/RFC/rfc-ind.cgi




## Network

### Layer 2

- PPP
- LCP
- AP(CHAP/PAP)
- NCP
- STP
- VLAN



### Layer 5

- BGP



## Other



一、 最核心与基础的数据链路层协议（L2）

1.  以太网协议族 (Ethernet Family)
    - IEEE 802.3: 这是以太网技术的绝对核心标准，定义了物理层和数据链路层的MAC子层。包括各种速率（百兆、千兆、万兆等）和介质（铜缆、光纤）的规范。

    - IEEE 802.1Q (VLAN Tagging): 虚拟局域网标签协议。这是现代交换机最重要的协议之一，用于在同一个物理网络上划分多个逻辑上独立的广播域。必须深刻理解VLAN ID、优先级标记（PCP）等。

    - IEEE 802.1ad (Q-in-Q / Stacked VLANs): 运营商网络常用，在用户的802.1Q标签之外再添加一层服务提供商自己的VLAN标签，用于扩展VLAN数量并提供分层服务。

    - IEEE 802.3ad (Link Aggregation / LACP): 链路聚合控制协议。将多个物理端口捆绑成一个逻辑端口，提供高带宽和冗余。LACP是它的实现协议。

    - IEEE 802.1D (STP): 生成树协议。经典版本，用于防止二层环路，但收敛速度慢。

    - IEEE 802.1w (RSTP): 快速生成树协议。STP的优化版本，大大加快了收敛速度，是当前的主流。

    - IEEE 802.1s (MSTP): 多生成树协议。允许在多个VLAN上运行不同的生成树实例，高效利用链路。

    - LLDP (Link Layer Discovery Protocol, IEEE 802.1AB): 链路层发现协议。相当于厂商中立的CDP（思科协议），用于网络设备之间发现并通告自身的身份、能力、邻居信息等，极其有用于网络拓扑发现和管理。

2.  地址解析协议
    - ARP (Address Resolution Protocol): 虽然属于网络层/三层协议，但它是二三层联动的枢纽，用于通过IP地址查找对应的MAC地址。交换机需要处理局域网内大量的ARP广播和应答。

二、 网络层协议（L3）与路由协议

对于三层交换机或需要管理网络路由的工程师，以下协议至关重要。

1. 核心网络协议

   - IPv4 / IPv6: 必须精通两者的报文结构、地址规划、子网划分（CIDR）、特殊地址等。

   - ICMP (Internet Control Message Protocol): 网络控制消息协议，用于传递差错和控制消息（如ping、traceroute）。

   - ICMPv6: IPv6版的ICMP，还包含了重要的邻居发现协议（NDP） 功能，取代了IPv4中的ARP。

2. 路由协议

   - 静态路由: 最基础、最常用的路由方式，必须掌握。

   - 动态路由协议:

     ▪   OSPF (Open Shortest Path First): 开放式最短路径优先，应用最广泛的内部网关协议（IGP），必须精通其区域划分、LSA类型、DR/BDR选举等。

     ▪   IS-IS (Intermediate System to Intermediate System): 大型运营商网络常用的IGP协议，与OSPF类似但基于OSI模型。

     ▪   BGP (Border Gateway Protocol): 边界网关协议，互联网的骨架，用于在不同自治系统（AS）之间交换路由信息。大型企业网和数据中心出口会用到。

3. 冗余网关协议

   - VRRP (Virtual Router Redundancy Protocol) / HSRP (Hot Standby Router Protocol, 思科私有) / GLBP (Gateway Load Balancing Protocol, 思科私有): 这些协议用于实现默认网关的冗余和负载均衡，保证网络的高可用性。

三、 传输层及应用层协议（L4-L7）

1.  传输层协议
    - TCP (Transmission Control Protocol): 理解其三次握手、流量控制、拥塞控制、端口号等，对于分析网络问题和做QoS很有帮助。

    - UDP (User Datagram Protocol): 理解其无连接、不可靠的特性，常用于音视频流量。

2.  管理与运维协议
    - SSH (Secure Shell): 必须使用SSH替代Telnet进行安全的设备管理。

    - SNMP (Simple Network Management Protocol): 简单网络管理协议，用于监控和管理网络设备。了解v2c和v3（加密认证）版本。

    - Syslog: 系统日志协议，用于将设备日志发送到中央服务器进行统一分析和存储。

    - NTP (Network Time Protocol): 网络时间协议，保证所有网络设备时间同步，对于日志分析、安全审计至关重要。

    - DNS (Domain Name System): 域名系统，设备本身需要DNS来解析域名，有时交换机也会承担DNS代理或监听功能。

    - DHCP (Dynamic Host Configuration Protocol) / DHCPv6: 动态主机配置协议，交换机可以作为DHCP中继代理（Relay Agent），将客户端的请求转发到不同网段的DHCP服务器。

    - HTTP/HTTPS: 许多现代交换机提供Web管理界面，基于HTTP/HTTPS。

    - NetFlow / sFlow / IPFIX: 网络流量分析协议，用于对网络流量进行采样、统计和导出，用于流量分析、规划和排障。

3.  安全协议
    - 802.1X: 端口访问控制协议，用于对接入网络的用户和设备进行身份认证，实现“未认证不许入网”。

    - RADIUS / TACACS+: 认证、授权和计费协议，通常与802.1X配合使用，将认证请求发送给中央服务器。

    - ACL (Access Control List): 虽然不是单一协议，但它是基于L2-L4信息（MAC、IP、端口号）进行流量过滤的核心安全技术。

四、 数据中心与Overlay网络协议（进阶）

​	现代数据中心和云网络中，传统二层网络被扩展：

1.  Overlay 技术
    - VXLAN (Virtual Extensible LAN): 虚拟可扩展局域网，是目前主流的Overlay技术。它通过在三层IP网络上构建一个虚拟的二层网络，极大地扩展了VLAN的数量（1600万 vs 4096），解决了大二层网络扩展问题。

    - NVGRE (Network Virtualization using Generic Routing Encapsulation) / GRE: 其他类型的隧道封装协议。

    - EVPN (Ethernet VPN): 以太网VPN，通常作为VXLAN的控制平面，使用BGP来分发MAC地址信息，实现更智能、更高效的二层网络虚拟化。

2.  其他数据中心协议
    - TRILL / SPB: 旨在替代STP的大二层多路径技术，但目前应用不如VXLAN+EVPN广泛。








