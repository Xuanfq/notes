# 开源网络操作系统SONiC

## 0. 引言

网络设备管理的一大烦恼来自于不同厂商的设备使用不同的操作系统,，这些系统命令格式不统一， 对协议的支持程度不一致,甚至在系统逻辑上也不一致. 笔者所管理的网络有十几个品牌的系统,，在系统升级，版本管理， 漏洞与安全管理上都要花费较多的时间和精力。

SONiC 的出现，较好地缓解了这些痛苦, 它的统一系统、不宕机升级、高度定制化等等特性, 帮助笔者节约了大量的时间和精力 。

正文开始前， 请允许我介绍一下开源、开放网络和 SDN。后续的文章中会对其概念有较多的引用，掌握这些概念， 我们上手 SONiC 的速度就快了很多。

## 1.开源、开放网络和 SDN 概念

什么是开源，什么是开放型网络，什么是软件定义网络，他们又有如何的关系，有哪些不同呢？我们先来看一下下面的这个图：

![img](https://www.21vbluecloud.com/wp-content/uploads/2020/01/SDN01-300x287.png)

可以看出，它们三者互为关系，但是又有很多相同和不同点。我们先来了解一下概念吧。

### 1.1.SDN (SoftWare-Defined Networking, 软件定义网络) [1]

SDN (软件定义网络, SoftWare-Defined Networking )通常被认为是一种将控制平面与网络内的包转发(数据)平面解耦的体系结构。在这种情况下，可以从中心位置进行网络配置和管理，而不是通过网络连接每个特定的交换机或服务器。这使得企业和服务提供商能够快速响应业务需求的变化。

SDN 的主要组成部分之一是SDN控制器。它通过应用程序编程接口 (api) 与应用程序通信。与此同时，它还使用OpenFlow 等接口与交换机或路由器通信。因为 OpenFlow 协议是网络中普遍存在的开源组件的一个例子，所以有些人认为 SDN 和开源软件是一样的。实际上，大多数 SDN 架构仍然在第三方或商业硬件上使用闭源软件或开源软件。

### 1.2.开源 (Open Sources) [2]

“开源”这个术语指的是人们可以修改和共享的东西，因为它的设计是公开可访问的。这个术语起源于软件开发中，指创建计算机程序的特定方法。然而今天，“开源”代表了更广泛的价值，我们称之为“开源方式”。开源方式可以是项目、产品或计划，具备以下原则，开放的交流、协作参与、快速的原型设计、透明的、可被管理的和面向社区的开发过程。

### 1.3.开源软件 (Open Source Software) [3]

开源软件即是开放源代码的软件，是任何人都可以检查、修改和增强源代码的软件。“源代码”是大多数计算机用户从未见过的软件的组成；它是计算机程序员可以操纵的代码，以改变软件(程序或应用程序)的工作方式。可以访问计算机程序源代码的程序员可以通过添加特性或修复不能正常工作的部分来改进程序。“开源软件”是相对于“闭源软件”而言的，有些软件的源代码只有创建它的个人、团队或组织才能修改，并且保持对它的独占控制。人们称这种软件为“专有的”或“闭源的”软件。

但是现在我们在互联网领域听到的大多数 Open Source 多指开源软件，其实已经远远缩小了 Open Source 的概念了。

在了解开放型网络之前，需要了解一下开放型网络是如何来的，起源来自于一个开放计算项目。

### 1.4. 开放计算项目 (Open Compute Project) [4]

开放计算项目 (OCP，Open Compute Project)，开放计算项目 (OCP) 是一个协作社区，专注于重新设计硬件技术，以有效地支持对计算型基础设施不断增长的需求。 故事源于2009年，Facebook 为数百万人提供一种新的服务，这种服务是一个分享照片和视频的社交平台，平台呈指数级增长。展望未来，该公司意识到，它必须重新考虑其基础设施的成本，通过控制成本和能源消耗来承载大量涌入的新用户和数据。就在那时，Facebook 启动了一个项目，设计世界上最节能的数据中心，以尽可能低的成本处理前所未有规模的数据。一个由工程师组成的小团队花了两年时间从头开始设计和建造数据中心，涉及内容包含：软件、服务器、机架、电源和冷却系统。目前这个数据中心着落在俄勒冈州的普林维尔。与该公司之前的设施相比，这个全新的数据中心节能率提高了38%，运营成本降低了24%，与此同时带来了更大的创新。 2011年，Facebook 与 Intel 和 Rackspace、高盛和 Andy Bechtolsheim 共同发起了开放计算项目，并成立了开放计算项目基金会。五名成员希望在硬件领域发起一场运动，就像我们在开源软件中看到的那种创造力和协作，这就是正在发生的事情。

### 1.5.开放型网络 (Open Networking) [5]

#### 1.5.1.什么是开放型网络?

开放型网络的根基需要几个条件，首先是建立在开放标准之上，通常我们常听到的开放标准例如 OpenFlow 协议等，再有就是能够支持开放网络的硬件，我们称之为“裸设备”，再其次就是可以自由选择自主安装的网络操作系统，只有具备这些才能打破软件和硬件在网络层面的固有特性，使我们能够拿到一个可交付的、灵活的、可伸缩的、可编程的以及适应各种需求的网络。

#### 1.5.2.开放型网络简史 [6]

我们把开放型网络定义为从2013年开始，为什么开放型网络定义为从2013开始？在互联网上一直存在着某种程度的开放型网络，这次我们可以把重点放在，什么时候开放型网络硬件和软件成为主流和易于使用，什么时候开放型网络安装环境的定义和发布。首先我们来看一下开放型网络中比较重点的定义：

#### 1.5.3. 开放性网络安装环境 (ONIE) [7]

开放性网络安装环境, ONIE – Open Network Install Environment
轻量级 Linux 环境，允许安装、卸载、调试的网络操作系统，开放性网络安装环境使得开放型网络成为可能。
我们通过一个例子来对比一下开放性网络安装环境在定义前后我们的使用上有何不同。
开放性网络安装环境未定义前，我们对网络设备安装调试可能的步骤：
1) 开打交换机移除 CF/SD卡
2) 在 CF/SD 卡上制作镜像文件
3) 把 CF/SD 卡放回交换机
4) 启动交换机进入对话模式
5) 挂载 CF/SD卡
6) 拷贝/解压镜像在 CF/SD/卡上
7) 设置启动参数
8) 保存和重置新的镜像

开放性网络安装环境定义后，我们对网络设备安装调试可能的步骤：
1) 通过 USB 安装开放性网络安装环境 (如果预先未安装开放性网络安装环境的情况)
2) 启动交换机并在开放网络安装环境中选择需要的操作
a) 安装操作系统
b) 打开命令行模式
c) 卸载操作系统
3) 升级开放网络安装环境
4) 完成

可以看出，通过开放性网络安装环境，可更为方便地管理网络设备，省去了频繁的硬件操作，从开放性网络安装环境层面实现了网络操作系统的变更。

当然，要组成开放型网络，除了解决了安装环境，还需要硬件支持，当然开放型网络需要包含开放的计算硬件/开放的网络硬件 (Switches)。

#### 1.5.4. 开放的网络硬件(Open Switches) [8]

##### 1.5.4.1.怎么理解硬件开放?

开放可以代表很多东西，从安装不同的网络操作系统到向公众提供完整的设计包，最具代表的是“源于开放计算项目网络组”，对，就是我们前面提到的那个组织 Open Compute Project (OCP)，网络组建立于2013年，硬件设计贡献者包含 Edge-Core, Quanta, Facebook, Mellanox 等。其中所有提交的设计都是开放的，包括构建网络设备所需的数据。

##### 1.5.4.2.常见的开放硬件

我们常见的开放硬件有以下两种：
1) Brite-BOX
Dell ON Series, HPE Altoline, Arista, Broadcom
由戴尔和 HPE 等知名厂商销售的品牌支持交换机
通常带有厂商的网络操作系统，但也可以运行其他网络操作系统, 很多这类型交换机是由白牌交换机改造而来。

2) White-Box
Mellanox, Edge-Core, Quanta 通用的交换机和硬件支持通常具备开放型网络安装环境。

#### 1.5.5. 开放的网络软件 (Open Networking Software) [9]

##### 1.5.5.1. 开源网络操作系统

前面我们讲了开放性网络安装环境，它是给开放网络操作系统准备的，现在我们来了解一下它。
开放网络 Linux (ONL, Open Networking Linux), 即交换机平台支持的网络操作系统。
ONL 由于良好的表现出现了跨多平台传播现象，NTT, Facebook, Google, Cord, Stratum 等多家公司的平台都提供了支持，而且不同的网络设备都开始支持 ONL。

##### 1.5.5.2. 什么使得网络软件开放？

网络操作系统 Linux化，使得 Linux 为基础的网络，其提供了硬件和网络的抽象的逻辑，并使用开源的网络栈。
例如: FRR, BIRD
虽然大多数厂商都有一些非开放的依赖，如硬件指令集，转发 ASIC API/SDK，以及一些抽象的网络控制集，一般普遍基于 Debian Linux,
例如: OPX, SONIC, ONL, 等等。
OpenSwitch(OPX), Dell OS10 Open Edition (Debian + CPS) + Quagga/FRR, focused on Dell Open Networking switches
CoRD, ONOS Controller with Indigo agent on switchesFRR, Routing suite used by most open networking software
这里特别提出 SAI 是第一个跨平台的开源交换机抽象。(后面我们会解释什么是 SAI)

### 1.6.开源网络操作系统分析 [10]

我们先来看一个架构逻辑来理解一下开源网络操作系统原理：

![img](https://www.21vbluecloud.com/wp-content/uploads/2020/01/openflow01-300x165.png)

这里，我们可以看出绿色部分属于开源部分，紫色部分使闭源部分，青色部分 Linux，浅蓝色为硬件层，大致分为硬件，平台，应用层三个层面，而平台层面的驱动和硬件控制接口是闭源的，但是应用层面已经把传感器进程，网络管理，网络控制协议层抽象出来。

### 1.7.开放的网络操作系统 (Network Operating System) [11]

虽然网络操作系统组件并不是完全开源，虽然很多芯片厂商对于交换机的抽象接口还是只支持二进制，但是随着SAI和P4的出现，我们发现了一些变化，我们也有理由相信未来会越来越好，下面给大家做一个对比：

| OpenNSL             | 非开源  | 仅开放API            |
| ------------------- | ------- | -------------------- |
| OF-DPA              | 非开源  | 兼容OpenFlow vX 标准 |
| SAI                 | 非开源  | 兼容SAI vX 标准      |
| P4 Runtime          | 非开源  | 兼容P4 vX 标准       |
| SDKLT               | 开源SDK |                      |
| OtherCavium OpenXPS | 开源    | 兼容 SAI 标准        |

说到开放的网络操作系统，不得不提到以下几个例子：Microsoft Azure SonicOpen Network Linux, Network API (SAI, OpenNSL), OpenSwitch (OPX).
这个我们发现很多支持SAI标准，那么什么是 SAI?

### 1.8.SAI (Switch Abstraction Interface) [12]

交换机抽象接口 (SAI) , 他是跨平台的交换机平台接口，可以看成是一个用户级的驱动，交换机抽象接口 (SAI) 是一种标准化的 API，API 涵盖多种功能，使用者不需要担心硬件厂商的约束，不用关心其交换专用集成电路、网络处理单元或其是一个软件交换机，都可采用统一的方式管理。其目的都是围绕简化厂商 SDK。
交换机抽象接口 (SAI) 在所有硬件上运行相同的应用程序堆栈，这使得 SAI 接口具备简单性，一致性。使用者不需要关心网络硬件供应商的硬件体系结构的开发和革新，通过始终一致性的编程接口可以很容易的应用最新最好的硬件，而且新的应用程序可移植性更强，bug 更低。这其中以 Microsoft, Dell, Facebook, Broadcom, Intel, Mellanox为代表。

#### 1.8.1.SAI 发展迅速

![img](https://www.21vbluecloud.com/wp-content/uploads/2020/01/SAI01-300x120.png)

#### 1.8.2.SAI 抽象的交换机系统的系统架构

![img](https://www.21vbluecloud.com/wp-content/uploads/2020/01/SAI02-300x270.png)

我们可以看到 SAI 是建立在开放的 ASIC 抽象之上的，API 通过 C 语言接口与网络专用芯片通信，接口大致分为几类功能：
必要功能，选配功能，自定义功能

#### 1.8.3.SAI 支持的功能摘要

我们来看一下 SAI 支持的功能摘要：

| 必要功能                              | 描述                    |
| ------------------------------------- | ----------------------- |
| sai_switch_api_t                      | Top-level switch object |
| sai_port_api_t                        | Port management         |
| sai_fdb_api_t                         | Forwarding database     |
| sai_vlan_api_t                        | VLAN management         |
| sai_vr_api_t                          | Virtual router          |
| sai_route_interface_api_t             | Routing interface       |
| sai_route_api_t                       | Routing table           |
| sai_neighbor_api_t                    | Neighbor table          |
| sai_next_hop_t                        | Next hop table          |
| sai_next_hop_api_t                    | Next hop group          |
| sai_qos_api_t                         | Quality of service      |
| sai_acl_api_t                         | ACL management          |
| LAG, STP, Control packet send/recevie |                         |



## 2. SONIC

有了 SAI, 这让网络操作系统不再关心底层怎么与专有硬件通信，操作系统厂商可以专注于网络操作系统的开发，其中以 SONIC 最为突出，他是 Microsoft/Azure 网络操作系统，由微软和多家厂商一起开发，并且开源。

### 2.1. 什么是SONIC?

SONiC 是一个基于 Linux 的开源网络操作系统，运行在多个供应商和 ASICs 的交换机上。SONiC 提供一整套网络功能，如 BGP 和 RDMA，这些功能在一些最大的云服务提供商的数据中心经过生产验证。它为团队提供了创建所需网络解决方案的灵活性，同时利用大型生态系统和社区的集体力量。

### 2.2. SONIC 系统架构[13]

SONIC 系统的体系结构由各种模块组成，这些模块通过一个集中的、可伸缩的基础设施彼此交互。这个基础结构依赖于 redis-database 引擎的使用: 键值数据库提供独立于语言的接口、数据持久性、复制和所有声音子系统之间的多进程通信的方法。

SONIC 通过依赖 redis-engine 基础结构提供的发布者/订阅者消息传递范式，应用程序可以只订阅它们所需的数据视图，并避免与其功能无关的实现细节。

SONIC 将每个模块放在独立的docker容器中，以保持语义仿射组件之间的高内聚性，同时减少脱节组件之间的耦合。每个组件都被编写为完全独立于平台特定的细节，而这些细节是与低层抽象交互所必需的。

SONIC 将其主要功能组件分解为以下 docker 容器：

- Dhcp-relay
- Pmon
- Snmp
- Lldp
- Bgp
- Teamd
- Database
- Swss
- Syncd

![img](https://www.21vbluecloud.com/wp-content/uploads/2020/01/userspace01-300x222.png)

### 2.3. SONIC 的功能发展

我们来看一下 SONIC 的功能发展 (来源于 SONIC 官网) [14]

| Release      | Release Date | SAI version | Features Included                                            |
| ------------ | ------------ | ----------- | ------------------------------------------------------------ |
| SONiC.201705 | 5/15/2017    | 0.9.4       | BGP                                                          |
|              |              |             | ECMP                                                         |
|              |              |             | LAG                                                          |
|              |              |             | LLDP                                                         |
|              |              |             | QoS – ECN                                                    |
|              |              |             | QoS – RDMA                                                   |
|              |              |             | Priority Flow Control                                        |
|              |              |             | WRED                                                         |
|              |              |             | COS                                                          |
|              |              |             | SNMP                                                         |
|              |              |             | Syslog                                                       |
|              |              |             | Sysdump                                                      |
|              |              |             | NTP                                                          |
|              |              |             | COPP                                                         |
|              |              |             | DHCP Relay Agent                                             |
|              |              |             | SONiC to SONiC upgrade                                       |
|              |              |             | Multiple Images support                                      |
|              |              |             | One Image                                                    |
| SONiC.201709 | 9/15/2017    | 0.9.4       | VLAN                                                         |
|              |              |             | ACL permit/deny                                              |
|              |              |             | IPv6                                                         |
|              |              |             | Tunnel Decap                                                 |
|              |              |             | Mirroring                                                    |
|              |              |             | Post Speed Setting                                           |
|              |              |             | BGP Graceful restart helper                                  |
|              |              |             | BGP MP                                                       |
| SONiC.201712 | 12/15/2017   | 1           | Fast Reload                                                  |
|              |              |             | SONiC Support SAI 1.0                                        |
|              |              |             | TACACS+                                                      |
|              |              |             | LACP Fallback                                                |
|              |              |             | MTU Setting                                                  |
|              |              |             | Vlan Trunk                                                   |
|              |              |             | Static Port breakout1                                        |
|              |              |             | Dynamic ACL Upgrade                                          |
|              |              |             | SWSS Unit Test Framework                                     |
|              |              |             | CobfigDB framework                                           |
| SONiC.201803 | 3/15/2018    | 1.2         |                                                              |
|              |              |             | [Critical Resource Monitoring](https://github.com/Azure/SONiC/wiki/Critical-Resource-Monitoring-High-Level-Design) |
|              |              |             | MAC Aging                                                    |
|              |              |             | [IPv6 ACL](https://github.com/Azure/SONiC/blob/gh-pages/doc/ACL-enhancements-on-SONIC.docx) |
|              |              |             | [BGP/Neighbor-down fib-accelerate](https://github.com/Azure/SONiC/blob/gh-pages/doc/sonic-ecmp-acceleration.docx) |
|              |              |             | [PFC WD](https://github.com/Azure/SONiC/wiki/PFC-Watchdog-Design) |
| SONiC.201807 | 7/30/2018    | 1.3         |                                                              |
|              |              |             | [gRPC](https://github.com/Azure/SONiC/pull/207)              |
|              |              |             | [Dtel support](https://github.com/Azure/SONiC/pull/182)      |
|              |              |             | SONiC Architecture and User Manual (Documentation)           |
|              |              |             | [Sensor transceiver monitoring](https://github.com/Azure/SONiC/pull/202) |
|              |              |             | LLDP extended MIB: lldpremtable, lldplocporttable, lldpremmanaddrtable, lldplocmanaddrtable, lldplocporttable, lldpLocalSystemData |
| SONiC.201811 | 11/30/2018   | 1.3         | Release Note                                                 |
|              |              |             | [Debian Kernel Upgrade to 4.9](https://github.com/Azure/SONiC/wiki/Upgrading-SONiC-kernel-to-3.16.0‐5-or-later-versions) |
|              |              |             | [Warm Reboot](https://github.com/Azure/SONiC/pull/187)       |
|              |              |             | [Incremental Config (IP, LAG, Port shut/unshut)](https://github.com/Azure/SONiC/blob/7ae7106fd3106cfc9a6a60a81d3b8f5ebd9ebab5/doc/Incremental IP LAG Update.md) |
|              |              |             | [Asymmetric PFC](https://github.com/Azure/SONiC/wiki/Asymmetric-PFC-High-Level-Design) |
|              |              |             | [PFC Watermark](https://github.com/Azure/SONiC/blob/master/doc/watermarks_HLD.md) |
|              |              |             | [Routing Stack Graceful Restart](https://github.com/Azure/SONiC/blob/dcac72377f23521a394694214678ea4450f6f70a/doc/routing-warm-reboot/Routing_Warm_Reboot.md) |
|              |              |             | [Basic VRF and L3 VXLAN](https://github.com/Azure/SONiC/blob/master/doc/vxlan/Vxlan_hld.md) |
| SONiC.201904 | 4/30/2019    | 1.4         | [Release Note](https://github.com/Azure/SONiC/blob/master/doc/SONiC 201904 Release Notes.md) |
|              |              |             | FRR as default routing stack                                 |
|              |              |             | Upgrade each docker to stretch version                       |
|              |              |             | Upgrade docker engine to 18.09                               |
|              |              |             | [Everflow enhancement](https://github.com/Azure/SONiC/blob/bb4f4a3a85935a38ec7f9625ef62cbe58c0998b4/doc/SONiC_EVERFLOW_IPv6.pdf) |
|              |              |             | [Egress ACL bug fix and ACL CLI enhancement](https://github.com/Azure/SONiC/blob/dfa7e58292deb4d7b10d1e0ca73f296cd206e9d2/doc/acl/egress-acl-bug-fix-description.md) |
|              |              |             | [L3 RIF counter support](https://github.com/Azure/SONiC/pull/310) |
|              |              |             | [PMon Refactoring](https://github.com/Azure/SONiC/tree/master/doc/pmon) |
|              |              |             | BGP-EVPN support(type 5), (related HLD Fpmsyncd,Vxlanmgr,template) |
|              |              |             | [Transceiver parameter tuning PR pending on CR sign off](https://github.com/Azure/SONiC/pull/328/files) |
| SONiC.201910 | 10/30/2019   | 1.5         | [Progress Tracking](https://github.com/Azure/SONiC/wiki/Release-Progress-Tracking-201911) |
|              |              |             | [ZTP – design review in progress](https://github.com/Azure/SONiC/blob/master/doc/ztp/ztp.md) |
|              |              |             | [BFD – SW – 100ms interval from FRR](https://github.com/Azure/SONiC/pull/383) |
|              |              |             | [NAT](https://github.com/Azure/SONiC/pull/390)               |
|              |              |             | [STP/PVST](https://github.com/Azure/SONiC/pull/386)          |
|              |              |             | [Mgmt VRF](https://github.com/Azure/sonic-utilities/pull/463/commits/d6d14929ef1f1d27f92e4bb5db30fba8b39dcfd4) |
|              |              |             | [Multi-DB optimization](https://github.com/Azure/SONiC/blob/ed69d427dcf358299b2c1b812e59a1e26a4ef4a5/doc/database/multi_database_instances.md) |
|              |              |             | Test to Pytest                                               |
|              |              |             | [sFlow](https://github.com/Azure/SONiC/pull/389)             |
|              |              |             | Management Framework (Tentative )                            |
|              |              |             | Platform Driver Development Framework                        |
|              |              |             | Build Improvements                                           |
|              |              |             | Error handling enhancements                                  |
|              |              |             | [L2 functional and performance enhancements](https://github.com/Azure/SONiC/pull/379) |
|              |              |             | [L3 perf enhancement](https://github.com/Azure/SONiC/pull/399) |
|              |              |             | BroadView BST                                                |
|              |              |             | [VRF](https://github.com/Azure/SONiC/pull/392)               |
|              |              |             | Configuration Validation                                     |
|              |              |             | Dynamic Break Out                                            |
|              |              |             | Platform APIs move to new APIs *                             |
|              |              |             | Sub-port support                                             |
| Backlog      |              |             |                                                              |
|              |              |             | [CLI framework](https://github.com/Azure/SONiC/pull/205)     |
|              |              |             | VRF (Taken)                                                  |
|              |              |             | L3 MLAG (Taken)                                              |
|              |              |             | EVPN                                                         |
|              |              |             | RDMA CLI enhancement                                         |
|              |              |             | Virtual path for streaming telemetry (pushed off)            |
|              |              |             | Management VRF (pushed off)                                  |
|              |              |             | Port and Vlan configuration and validation (TBD)             |

## 3. 其他

开放型网络中还包含以下组件：

- 网络功能虚拟化
- 云计算
- 自动化
- 敏捷型开发方法和处理过程



参考文献：

[1] https://en.wikipedia.org/wiki/Software-defined_networking
[2] https://en.wikipedia.org/wiki/Open_source
[3] https://en.wikipedia.org/wiki/Open-source_software
[4] https://www.opencompute.org/about
[5] https://aptira.com/what-is-open-networking/
[6] https://events19.linuxfoundation.org/wp-content/uploads/2017/11/Open-Hardware-and-Open-Networking-Software-How-We-Got-Here-and-Where-We-are-Going-Steven-Noble-Big-Switch-Networks-_-NetDEF.pdf
[7] https://www.opencompute.org/wiki/Networking/ONIE
[8] https://www.openswitch.net/about/
[9] http://opennetlinux.org/
[10] https://events19.linuxfoundation.org/wp-content/uploads/2017/11/Open-Hardware-and-Open-Networking-Software-How-We-Got-Here-and-Where-We-are-Going-Steven-Noble-Big-Switch-Networks-_-NetDEF.pdf
[11] https://events19.linuxfoundation.org/wp-content/uploads/2017/11/Open-Hardware-and-Open-Networking-Software-How-We-Got-Here-and-Where-We-are-Going-Steven-Noble-Big-Switch-Networks-_-NetDEF.pdf
[12] https://www.opencompute.org/documents/switch-abstraction-interface
[13] https://github.com/Azure/SONiC/wiki/Architecture
[14] https://github.com/Azure/SONiC/wiki/Sonic-Roadmap-Planning



> Source: 
>
> - https://www.21vbluecloud.com/sonic_part1/
>
> - https://www.21vbluecloud.com/sonic_part2/

