# L2-PTP

PTP（Precision Time Protocol，精确时间协议，IEEE 1588）可以运行在 L2 层（数据链路层/MAC层），也可以运行在 L4 层。

PTP 的层级特性：
- L2 层（以太网直接封装）： PTP 报文可以直接封装在以太网帧中（使用特定的 EtherType，如标准中的 0x88F7），不经过 IP 和 UDP。这种方式跳过了传输层和网络层处理，驻留时间少，同步精度更高（常用于工业自动化或车载以太网中的 gPTP；及交换芯片）。 
- L4 层（UDP 封装）： PTP 也可以封装在 UDP 报文中（通常使用端口 319 和 320），通过 IPv4 或 IPv6 进行传输，这样可以跨越支持 PTP 的路由器进行广域网或复杂网络同步。

| 特性 | 组播/单播 (L2) | 组播/单播 (L4 / UDP) |
| :--- | :--- | :--- |
| 封装协议 | 直接封装在以太网帧 (EtherType: 0x88F7) | 封装在 UDP 报文中 (IPv4/IPv6, 端口 319/320) |
| 同步精度 | 更高 (通常在几纳秒到十几纳秒级) | 略低 (通常在几十纳秒到微秒级) |
| 协议开销 | 极小 (去掉了 IP 和 UDP 报头) | 较大 (多层报头增加了处理延迟) |
| 网络跨越能力 | 只能在同一个局域网（VLAN）内传输 | 可以跨路由器和三层交换机传输 |
| 应用场景 | 车载以太网 (gPTP)、工业自动化 (Profinet) | 电信基站同步 (1588v2)、数据中心 (PTPv2) |

此文主要记录 L2 层的 PTP 。


## 核心原理

PTP（IEEE 1588）的核心原理是通过双向报文四步握手计算出主从设备间的网络延迟与时间偏差，并通过芯片硬件打戳彻底消除软件栈和排队带来的抖动（见下文）。

### 核心数学原理：双向四步握手

PTP 假设网络往返链路延时是**对称的**（即上行延时等于下行延时）。

主时钟（Master）与从时钟（Slave）通过交换 4 个报文，记录 4 个精准的时间戳：

1. Master $\rightarrow$ Slave (Sync 报文)：Master 在发出瞬间记录时间戳 $t_1$；Slave 在收到瞬间记录时间戳 $t_2$。
2. Master $\rightarrow$ Slave (Follow_Up 报文)：Master 将 $t_1$ 的准确数值打包发送给 Slave（若硬件支持一步模式，则 $t_1$ 会直接写入 Sync 报文中）。（有此步骤的为Two-Step模式，无则为One-Step模式）
3. Slave $\rightarrow$ Master (Delay_Req 报文)：Slave 在发出瞬间记录时间戳 $t_3$；Master 在收到瞬间记录时间戳 $t_4$。
4. Master $\rightarrow$ Slave (Delay_Resp 报文)：Master 将 $t_4$ 的数值发送给 Slave。

此时 Slave 拥有全部 4 个时间戳，根据网络单向延迟 $\text{Delay}$ 和主从时间偏差 $\text{Offset}$，可得出方程：

- 去程测量： $t_2 - t_1 = \text{Delay}_{M \to S} + \text{Offset}$（包含了正的偏差，主从时钟之间存在时间偏差 Offset ，且两组差值各自使用的参考时钟并不相同，所以有 +/- Offset ）
- 回程测量： $t_4 - t_3 = \text{Delay}\_{S \to M} - \text{Offset}$（包含了负的偏差）（上方提及PTP假设网络往返链路延时是**对称相等的**，所以 $\text{Delay}\_{M \to S}$ = $\text{Delay}_{S \to M}$ ）

即：

- $$\text{Offset} + \text{Delay} = t_2 - t_1$$
- $$\text{Delay} - \text{Offset} = t_4 - t_3$$

解方程即可求得主从节点的时钟偏差与网络延时：

- $$\text{Offset} = \frac{(t_2 - t_1) - (t_4 - t_3)}{2}$$
- $$\text{Delay} = \frac{(t_2 - t_1) + (t_4 - t_3)}{2}$$

Slave 拿到 $\text{Offset}$ 后，调整自身本地时钟，调整交换芯片内部一个真实的“物理硬件时钟”，从而实现与 Master 的高精度同步。

> 为什么 $t_2 - t_1$ 不等于 $t_4 - t_3$ ？
>
> 根本原因在于主从时钟之间存在时间偏差（Offset），且两组差值各自使用的参考时钟并不相同，所以有 +/- Offset 。
> 
> 使用的参考时钟不同（核心数学原因）
> 
> - $t_1$ 和 $t_4$ 是用主时钟（Master）量的
> - $t_2$ 和 $t_3$ 是用从时钟（Slave）量的
> 
> 假设从时钟比主时钟快了 $\text{Offset}$（即 $T_{\text{Slave}} = T_{\text{Master}} + \text{Offset}$）：
> 
> - 去程测量： $t_2 - t_1 = \text{Delay}_{M \to S} + \text{Offset}$（包含了正的偏差）
> - 回程测量： $t_4 - t_3 = \text{Delay}_{S \to M} - \text{Offset}$（包含了负的偏差）
> 
> 只要主从时钟尚未完全同步（ $$\text{Offset} \neq 0$$ ）， $$(t_2 - t_1)$$ 就必然不等于 $$(t_4 - t_3)$$ 。
> 
> 双向物理路径的延时不对称（网络原因）
> 
> - 即便假设主从时钟完全同步（ $$\text{Offset} = 0$$ ），去程延迟（ $\text{Delay}\_{M \to S}$ ）与回程延迟（ $\text{Delay}_{S \to M}$ ）在真实硬件中也极少完全相等。
> - 收发双向的光纤长度微小差异、PHY 芯片内部 Tx/Rx 线路处理延时的不同，都会导致去程与回程延时出现纳秒级的偏差。
> 
> 正因为 $(t_2 - t_1)$ 包含了 $+\text{Offset}$，而 $(t_4 - t_3)$ 包含了 $-\text{Offset}$ ，PTP 协议才能够通过将两者相减消去单向网络延迟，从而精准提取出这个时间偏差 $\text{Offset}$ 。


## 报文结构

### Structure

PTP（IEEE 1588v2）报文由传输层封装、34 字节通用报文头（PTP Header） 和 各报文专属载荷（Payload） 三部分组成。

在四步握手中，Sync 和 Delay_Req 属于事件报文（Event），需在 MAC/PHY 打硬件时间戳；Follow_Up 和 Delay_Resp 属于通用报文（General）。

在 IEEE 1588 规范中，PTP 报文的标准封装主要分为两大类：

- L2 纯链路层模式 ( Layer 2 )

  - 结构： [ MAC Header (L2) | EtherType: 0x88F7 | PTP Header | PTP Payload | FCS ]
  - 特点： 报文直接跑在以太网帧上，完全不需要 L3 (IP) 和 L4 (UDP)。这种方式头部开销最小、处理效率最高，常用于局域网或专网。

  | 协议层级 | 字段/结构名称 | 字节长度 (Bytes) | 说明 |
  | --- | --- | --- | --- |
  | **L2 MAC 帧头** | DMAC / SMAC / EtherType | **14** | DMAC(6B) + SMAC(6B) + EtherType(2B: `0x88F7`) |
  | *(可选)* | *VLAN Tag (802.1Q)* | *(4)* | *若带有 VLAN 标签，MAC 帧头增至 18 Bytes* |
  | **PTP Header** | 统一报文头 | **34** | IEEE 1588v2 标准固定报文头 |
  | **PTP Payload** | 消息载荷 | **10 或 20** | Sync / Follow_Up / Delay_Req 为 **10B**；Delay_Resp 为 **20B** |
  | **L2 校验** | FCS (CRC) | **4** | 帧校验序列 |

- L3/L4 跨网段模式 ( IPv4/IPv6 + UDP )

  - 结构： [ MAC Header (L2) | IP Header (L3) | UDP Header (L4) | PTP Header | PTP Payload | FCS ]
  - 特点： 借助 L3 (IP) 实现三层路由跨网段传输，借助 L4 (UDP) 的端口号区分不同类型的 PTP 报文：
    - UDP Port 319 (Event)：用于 Sync 和 Delay_Req，交换芯片通过匹配此 L4 端口号触发硬件打时间戳。
    - UDP Port 320 (General)：用于 Follow_Up 和 Delay_Resp，仅作纯数据传递，不触发打戳。

  | 协议层级 | 字段/结构名称 | 字节长度 (Bytes) | 说明 |
  | --- | --- | --- | --- |
  | **L2 MAC 帧头** | DMAC / SMAC / EtherType | **14** | EtherType 为 `0x0800` (IPv4) |
  | **L3 IP 帧头** | IPv4 Header | **20** | 无 Option 选项时的标准 IP 头部长度 |
  | **L4 UDP 帧头** | UDP Header | **8** | 源端口 + 目的端口(319/320) + 长度 + 校验和 |
  | **PTP Header** | 统一报文头 | **34** | IEEE 1588v2 标准固定报文头 |
  | **PTP Payload** | 消息载荷 | **10 或 20** | Sync / Follow_Up / Delay_Req 为 **10B**；Delay_Resp 为 **20B** |
  | **L2 校验** | FCS (CRC) | **4** | 帧校验序列 |



### PTP Header

四种报文均使用完全一致的 34 字节 Header 结构：

| 字段名称 (Field) | 长度 (Bytes) | 作用与功能解析 |
| --- | --- | --- |
| `messageType` | 0.5 (4 bits) | 报文类型（`0x0`: Sync, `0x1`: Delay_Req, `0x8`: Follow_Up, `0x9`: Delay_Resp） |
| `versionPTP` | 0.5 (4 bits) | PTP 协议版本（主流为 `2`，即 IEEE 1588v2） |
| `messageLength` | 2 | 整个 PTP 报文（Header + Payload）的总字节数 |
| `domainNumber` | 1 | PTP 时域编号（只有相同 Domain 的设备才相互同步） |
| `flagField` | 2 | 标志位（如 `twoStepFlag` 标识是否为两步模式、`unicastFlag` 等） |
| `correctionField` | 8 | 修正字段（纳秒分段/65536），用于透明时钟（TC）累加网络和驻留延时 |
| `sourcePortIdentity` | 10 | 发送方端口标识（8 字节 Clock ID + 2 字节 Port Number） |
| `sequenceId` | 2 | 报文序列号（从 0 递增，用于匹配 Sync 与 Follow_Up、Delay_Req 与 Delay_Resp） |
| `controlField` | 1 | 兼容 v1 版本的控制字段 |
| `logMessageInterval` | 1 | 报文发送周期的 Log2 值（例如 0 代表 $2^0=1$ 秒，-3 代表 $2^{-3}=125$ ms） |



### PTP Payload

- Sync 报文（事件报文，Type: 0x0）

  - **`originTimestamp`（10 字节，6B 秒 + 4B 纳秒）：**
    - **两步模式 (Two-Step)：** 填充为 0。真正的发送时间戳 $t_1$ 由硬件记录并由 Follow_Up 带出。
    - **一步模式 (One-Step)：** 交换芯片硬件在报文飞出 PHY 端口的一瞬间，直接将精准的 $t_1$ 覆盖写入此字段。

- Follow_Up 报文（通用报文，Type: 0x8）

  - **`preciseOriginTimestamp`（10 字节）：** 存放 Master 硬件在发出 Sync 报文瞬间记录的精准时间戳 $t_1$。从机通过 `sequenceId` 将此时间戳与收到的 Sync 报文对齐。

- Delay_Req 报文（事件报文，Type: 0x1）

  - **`originTimestamp`（10 字节）：** 通常填 0 或 Slave 的本地估算时间（无严格要求，因为 Slave 会在硬件发出该报文时，自行在本地寄存器中保存真正的 $t_3$）。

- Delay_Resp 报文（通用报文，Type: 0x9）

  - **`receiveTimestamp`（10 字节）：** 存放 Master 硬件接收到 Slave 的 Delay_Req 报文时记录的精准时间戳 $t_4$。
  - **`requestingPortIdentity`（10 字节）：** 复制 Delay_Req 中的 `sourcePortIdentity`，以便 Slave 认领属于自己的 $t_4$ 时间戳。















