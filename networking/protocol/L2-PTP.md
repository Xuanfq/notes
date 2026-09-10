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
2. Master $\rightarrow$ Slave (Follow_Up 报文)：Master 将 $t_1$ 的准确数值打包发送给 Slave（若硬件支持一步模式，则 $t_1$ 会直接写入 Sync 报文中）。
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






















