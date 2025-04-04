# BGP

边界[网关](https://info.support.huawei.com/info-finder/encyclopedia/zh/路由器.html)协议（Border Gateway Protocol，BGP）是一种用来在[路由](https://info.support.huawei.com/info-finder/encyclopedia/zh/IP路由.html)选择域之间交换网络层可达性信息（Network Layer Reachability Information，NLRI）的路由选择协议。由于不同的管理机构分别控制着他们各自的路由选择域，因此，路由选择域经常被称为自治系统AS（Autonomous System）。现在的Internet是一个由多个自治系统相互连接构成的大网络，BGP作为事实上的Internet外部路由协议标准，被广泛应用于ISP（Internet Service Provider）之间。
早期发布的三个版本分别是BGP-1、BGP-2和BGP-3，主要用于交换AS之间的可达路由信息，构建AS域间的传播路径，防止路由环路的产生，并在AS级别应用一些路由策略。当前使用的版本是BGP-4。

**目录**

- [为什么需要BGP？](https://info.support.huawei.com/info-finder/encyclopedia/zh/BGP.html#content1)
- [BGP是怎么工作的？](https://info.support.huawei.com/info-finder/encyclopedia/zh/BGP.html#content2)
- [BGP是如何处理路由的？](https://info.support.huawei.com/info-finder/encyclopedia/zh/BGP.html#content3)
- [BGP支持哪些扩展？](https://info.support.huawei.com/info-finder/encyclopedia/zh/BGP.html#content4)

## 为什么需要BGP？

IGP（Interior Gateway Protocol，内部[网关](https://info.support.huawei.com/info-finder/encyclopedia/zh/路由器.html)协议）被设计用来在单一的[路由](https://info.support.huawei.com/info-finder/encyclopedia/zh/IP路由.html)选择域内提供可达性信息并不适合提供域间路由选择功能，BGP作为优秀的域间路由协议得以产生并发展。

当今的网络通常使用以下类型的IGP：

- 距离矢量协议，例如路由信息协议（Routing Information Protocol, RIP）。
- 链路状态协议，例如开放式最短路径优先（Open Shortest Path First, [OSPF](https://info.support.huawei.com/info-finder/encyclopedia/zh/OSPF.html)）协议和中间系统到中间系统（Intermediate System to Intermediate System, [IS-IS](https://info.support.huawei.com/info-finder/encyclopedia/zh/IS-IS.html)）协议。

虽然这些协议是为不同目的设计的，并且具有不同的行为特征，但是它们的共同目标是解决在一个路由选择域内的路径最优化问题。IGP并不适合提供域间路由选择功能。比如说，一种域间路由选择协议应该能够提供广泛的策略控制，因为不同的域通常需要不同的路由选择策略和管理策略。

从一开始，BGP就被设计成一种域间路由选择协议，其设计目标就是策略控制能力和可扩展性。但是，BGP也不适合替代IGP，因为它们适用的场景不同。

BGP有两种运行方式，如下图所示，当BGP运行于同一AS内部时，被称为IBGP（Internel BGP，内部边界网关协议）；当BGP运行于不同AS之间时，称为EBGP（Externel BGP，外部边界网关协议）。

![BGP的运行方式](https://download.huawei.com/mdl/image/download?uuid=d58e7da08e7140569e374140e6a85c57)
*BGP的运行方式*

## BGP是怎么工作的？

### BGP报文中的角色

Speaker：发送BGP报文的[路由](https://info.support.huawei.com/info-finder/encyclopedia/zh/IP路由.html)设备称为BGP发言者（Speaker），它接收或产生新的路由信息，并发布（Advertise）给其它BGP Speaker。当BGP Speaker收到来自其它AS的新路由时，如果该路由比当前已知路由更优、或者当前还没有该路由，它就把这条路由发布给所有其他BGP Speaker（发布该路由的BGP Speaker除外）。

Peer：相互交换报文的BGP Speaker之间互称对等体（Peer）。

### BGP的报文

BGP的运行是通过报文驱动的，共有Open、Update、Notification、Keepalive、Route-refresh和Capability六种报文类型。

- Open报文：是TCP连接建立后发送的第一个报文，用于建立BGP对等体之间的连接关系。对等体在接收到Open报文并协商成功后，将发送Keepalive报文确认并保持连接的有效性。确认后，对等体间可以进行Update、Notification、Keepalive和Route-refresh报文的交换。
- Update报文：用于在对等体之间交换路由信息。Update报文可以发布多条属性相同的可达路由信息，也可以撤销多条不可达路由信息。
- Notification报文：当BGP检测到错误状态时，就向对等体发出Notification报文，之后BGP连接会立即中断。
- Keepalive报文：BGP会周期性地向对等体发出Keepalive报文，用来保持连接的有效性。
- Route-refresh报文：Route-refresh报文用来请求对等体重新发送所有的可达路由信息。
- Capability报文：用于在一个已经建立的BGP会话基础上动态更新对等体的能力，可保证已有对等体连接不中断。

### BGP处理过程

如下图所示，BGP的传输层协议是TCP协议，所以在BGP对等体建立之前，对等体之间首先进行TCP连接。BGP邻居间会通过Open报文协商相关参数，建立起BGP对等体关系。建立连接后，BGP邻居之间交换整个BGP路由表。BGP会发送Keepalive报文来维持邻居间的BGP连接，BGP协议不会定期更新路由表，但当BGP路由发生变化时，会通过Update报文增量地更新路由表。当BGP检测到网络中的错误状态时（例如收到错误报文时），BGP会发送Notification报文进行报错，BGP连接会随即中断。

![邻居建立过程图](https://download.huawei.com/mdl/image/download?uuid=dcd9fa4bd8e444588386710836ab1d72)
*邻居建立过程图*

### BGP有限状态机

BGP有限状态机共有六种状态，分别是Idle、Connect、Active、Open-Sent、Open-Confirm和Established。

在BGP对等体建立的过程中，通常可见的三个状态是：Idle、Active、Established。

- Idle状态下，BGP拒绝任何进入的连接请求，是BGP初始状态。
- Connect状态下，BGP等待TCP连接的建立完成后再决定后续操作。
- Active状态下，BGP将尝试进行TCP连接的建立，是BGP的中间状态。
- Open-Sent状态下，BGP等待对等体的Open报文。
- Open-Confirm状态下，BGP等待一个Notification报文或Keepalive报文。
- Established状态下，BGP对等体间可以交换Update报文、Route-refresh报文、Keepalive报文和Notification报文。

BGP对等体双方的状态必须都为Established，BGP邻居关系才能成立，双方通过Update报文交换路由信息。

![点击放大](https://download.huawei.com/mdl/image/download?uuid=1d23ec25be7f45a28bdcf66014fcacbd)

### BGP属性

BGP路由属性是一套参数，它对特定的路由进一步的描述，使得BGP能够对路由进行过滤和选择。事实上，所有的BGP路由属性都可以分为以下4类：

- 公认必须遵循的（Well-known mandatory）：所有BGP设备都可以识别，且必须存在于Update报文中。如果缺少这种属性，路由信息就会出错。
- 公认任意（Well-known discretionary）：所有BGP设备都可以识别，但不要求必须存在于Update报文中，可以根据具体情况来选择。
- 可选过渡（Optional transitive）：在AS之间具有可传递性的属性。BGP设备可以不支持此属性，但它仍然会接收这类属性，并通告给其他对等体。
- 可选非过渡（Optional non-transitive）：如果BGP设备不支持此属性，则相应的这类属性会被忽略，且不会通告给其他对等体。

下面介绍几种常用的BGP路由属性：

- Origin属性，属于公认必须遵循属性，用来定义路径信息的来源，标记一条路由是怎么成为BGP路由的，包含IGP、EGP和Incomplete三种类型。
- AS_Path属性，属于公认必须遵循属性，按矢量顺序记录了某条路由从本地到目的地址所要经过的所有AS编号。
- Next_Hop属性，属于公认必须遵循属性。
- MED，属于可选非过渡属性，MED（Multi-Exit-Discriminator）属性仅在相邻两个AS之间传递，收到此属性的AS一方不会再将其通告给任何其他第三方AS。
- Local_Pref属性，属于公认任意属性，仅在IBGP对等体之间有效，不通告给其他AS，用于表明路由设备的BGP优先级。

## BGP是如何处理路由的？

BGP对[路由](https://info.support.huawei.com/info-finder/encyclopedia/zh/IP路由.html)的处理如下图所示。BGP路由来源包括从其他协议引入和从邻居学习两个部分，为了减少路由规模，可以对优选的BGP路由进行聚合。在引入路由、从邻居接收或发送路由的过程中，可以通过路由策略实现对路由的过滤，也可以修改路由的属性。

![BGP对路由的处理过程](https://download.huawei.com/mdl/image/download?uuid=86859d64ef4c40028c52e1894b82ee72)
*BGP对路由的处理过程*

### 路由引入

BGP协议自身不能发现路由，所以需要引入其他协议的路由（如IGP或者静态路由等）注入到BGP路由表中，从而将这些路由在AS之内和AS之间传播。

BGP引入路由时支持Import和Network两种方式：

- Import方式是按协议类型，将RIP路由、[OSPF](https://info.support.huawei.com/info-finder/encyclopedia/zh/OSPF.html)路由、[IS-IS](https://info.support.huawei.com/info-finder/encyclopedia/zh/IS-IS.html)路由、静态路由和直连路由等某一协议的路由注入到BGP路由表中。
- Network方式比Import方式更精确，将指定前缀和掩码的一条路由注入到BGP路由表中。
- Import和Network两种方式均可以通过路由策略实现对路由的过滤及属性的修改，将通过路由策略过滤且修改属性后的路由注入到BGP路由表中。

### 路由选择

当到达同一目的地存在多条路由时，BGP采取路由选择策略进行路由选择，例如优选没有迭代到Graceful Down（该[SRv6](https://info.support.huawei.com/info-finder/encyclopedia/zh/SRv6.html) TE-Policy处于[延迟](https://info.support.huawei.com/info-finder/encyclopedia/zh/低时延.html)删除状态）的SRv6 TE-Policy的路由、在与[RPKI](https://info.support.huawei.com/info-finder/encyclopedia/zh/RPKI.html)（[Resource Public Key Infrastructure](https://info.support.huawei.com/info-finder/encyclopedia/zh/RPKI.html)）服务器进行连接的情景中，应用起源AS验证结果后的BGP路由优先级顺序为Valid > NotFound > Invalid、优选没有误码的路由等。

### 路由聚合

在大规模的网络中，BGP路由表十分庞大，使用路由聚合（Routes Aggregation）可以大大减小路由表的规模。

路由聚合实际上是将多条路由合并的过程。这样BGP在向对等体通告路由时，可以只通告聚合后的路由，而不是通告所有的具体路由。

BGP路由聚合支持两种方式：

- 自动聚合：对BGP引入的路由进行聚合。配置自动聚合后，对参加聚合的具体路由进行抑制。配置自动聚合后，BGP将按照自然网段聚合路由（如10.1.1.1/32和10.2.1.1/32将聚合为A类地址10.0.0.0/8），并且BGP向对等体只发送聚合后的路由。
- 手动聚合：对BGP本地路由进行聚合。手动聚合可以控制聚合路由的属性，以及决定是否发布具体路由。

[IPv4](https://info.support.huawei.com/info-finder/encyclopedia/zh/IPv4.html)支持自动聚合和手动聚合两种方式，而[IPv6](https://info.support.huawei.com/info-finder/encyclopedia/zh/IPv6.html)仅支持手动聚合。

### BGP发布路由

BGP发布路由时采用如下策略：

- 存在多条有效路由时，BGP Speaker只将最优路由发布给对等体。
- BGP Speaker从EBGP获得的路由会向它所有BGP对等体发布（包括EBGP对等体和IBGP对等体）。
- BGP Speaker从IBGP获得的路由不向它的IBGP对等体发布。
- BGP Speaker从IBGP获得的路由是否通告给它的EBGP对等体要依据IGP和BGP同步的情况。
- 连接一旦建立，BGP Speaker将把自己可发布的BGP最优路由发布给新对等体。

## BGP支持哪些扩展？

传统的BGP-4只能管理[IPv4](https://info.support.huawei.com/info-finder/encyclopedia/zh/IPv4.html)[单播路由](https://info.support.huawei.com/info-finder/encyclopedia/zh/IP路由.html)信息，对于使用其它网络层协议（如[IPv6](https://info.support.huawei.com/info-finder/encyclopedia/zh/IPv6.html)、[组播](https://info.support.huawei.com/info-finder/encyclopedia/zh/组播.html)等）的应用就受到一定限制。

为了提供对多种网络层协议的支持，IETF（Internet Engineering Task Force）对BGP-4进行了扩展，形成MP-BGP（Multi-protocol Extensions for Border Gateway Protocol）。MP-BGP向前兼容，即支持BGP扩展的[路由器](https://info.support.huawei.com/info-finder/encyclopedia/zh/路由器.html)与不支持BGP扩展的路由器可以互通。

MP-BGP在现有BGP-4协议的基础上增强功能，使BGP能够为多种[路由](https://info.support.huawei.com/info-finder/encyclopedia/zh/IP路由.html)协议提供路由信息，包括IPv6（即BGP4+）和组播。

- MP-BGP可以同时为单播和组播维护路由信息，将它们储存在不同的路由表中，保持单播和组播之间路由信息相互隔离。
- MP-BGP可以同时支持单播和组播模式，为两种模式构建不同的网络拓扑结构。
- 原BGP-4支持的单播路由策略和配置方法大部分都可应用于组播模式，从而根据路由策略为单播和组播维护不同的路由。

BGP采用地址族（Address Family）来区分不同的网络层协议，关于地址族的一些取值可以参考相关标准。支持多种MP-BGP扩展应用，包括对[VPN](https://info.support.huawei.com/info-finder/encyclopedia/zh/VPN.html)的扩展、对IPv6的扩展等，不同的扩展应在各自的地址族视图下配置。

- BGP-IPv4单播地址族有以下作用：维护公网BGP邻居，并且传递公网IPv4路由信息；传递公网IPv4标签路由，主要用在Option C方式的跨域BGP/MPLS [IP](https://info.support.huawei.com/info-finder/encyclopedia/zh/IPv4.html) VPN或Option C方式的跨域BGP/MPLS IPv6 VPN场景里。
- BGP-IPv6单播地址族有以下作用：维护公网IPv6 BGP邻居，并且传递公网IPv6路由信息；传递IPv6标签路由，主要用于配置[6PE](https://info.support.huawei.com/info-finder/encyclopedia/zh/6PE.html)场景里。
- BGP-IPv4组播地址族视图、BGP-MVPN地址族视图、BGP-IPv6 MVPN地址族视图、BGP-MDT地址族视图等组播相关地址族可以传输跨AS的路由信息，主要应用于MBGP、BIER、NG MVPN、[BIERv6](https://info.support.huawei.com/info-finder/encyclopedia/zh/BIERv6.html)和Rosen MVPN。
- BGP-VPNv4地址族、BGP-VPNv6地址族、BGP-VPN实例视图、BGP多实例VPN实例视图、BGP-L2VPN-AD地址族视图、BGP-L2VPN-AD地址族视图等VPN相关地址族主要应用于BGP/MPLS IP VPN、VPWS以及VPLS。
- BGP-EVPN地址族视图、BGP多实例[EVPN](https://info.support.huawei.com/info-finder/encyclopedia/zh/EVPN.html)地址族视图等EVPN相关地址族主要用于配置BGP EVPN对等体，应用于EVPN VPLS、EVPN VPWS以及EVPN L3VPN。EVPN（Ethernet Virtual Private Network）是一种用于二层网络互联的VPN技术。EVPN技术采用类似于BGP/MPLS IP VPN的机制，在BGP协议的基础上定义了一种新的网络层可达信息NLRI（Network Layer Reachability Information）即EVPN NLRI，EVPN NLRI定义了几种新的BGP EVPN路由类型，用于处在二层网络的不同站点之间的MAC地址学习和发布。
- BGP IPv4 SR-Policy地址族视图和BGP IPv6 SR-Policy地址族视图主要应用于[Segment Routing MPLS](https://info.support.huawei.com/info-finder/encyclopedia/zh/SR-MPLS.html)和[Segment Routing](https://info.support.huawei.com/info-finder/encyclopedia/zh/Segment+Routing.html) IPv6。
- BGP-Flow地址族视图、BGP-Flow IPv6地址族视图、BGP-Flow VPNv4地址族视图、BGP-Flow VPNv6地址族视图、BGP-Flow VPN实例[IPv4地址](https://info.support.huawei.com/info-finder/encyclopedia/zh/IPv4.html)族视图、BGP-Flow VPN实例IPv6地址族视图等Flow相关地址族主要用于防止DoS/DDoS攻击，可以提高网络安全性和可用性。
- BGP-Labeled地址族视图和BGP-Labeled-VPN实例IPv4地址族视图的应用主要在于BGP分标签方案的运营商配置。
- BGP-LS地址族视图主要用于汇总IGP协议收集的拓扑信息上送给上层控制器。
- BGP RPD地址族视图用于传递路由策略信息，完成流量的动态调整，主要用于入方向流量调优场景。而BGP S-UCMP结合该地址族为用户提供了域间流量调整的实现方法，在双核心口字型组网场景和双核心V字型组网场景中解决了跨域场景中链路部分故障或部分路径流量突发导致的流量拥塞问题。
- BGP SAVNET地址族视图主要用于实现分布式的源地址验证功能，分为域内、接入及域间三种场景。
- BGP [SD-WAN](https://info.support.huawei.com/info-finder/encyclopedia/zh/SD-WAN.html)地址族视图主要应用于EVPN场景，[SD-WAN EVPN](https://info.support.huawei.com/info-finder/encyclopedia/zh/SD-WAN+EVPN.html)是一种通过扩展现有EVPN技术来实现Overlay业务网络和Underlay传输网络分离的VPN解决方案。





> Source: https://info.support.huawei.com/info-finder/encyclopedia/zh/BGP.html

