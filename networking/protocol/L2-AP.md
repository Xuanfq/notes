# L2-AP

AP为**Authentication Protocol**的个人简称，认证协议。

若**LCP**协商过程中的链路配置时**有协商认证选项Type=0x03**，*则在完成LCP协商进入Opened后进行认证协议的协商*。

主要协议有：
- PAP（Password Authentication Protocol，口令认证协议）
- CHAP（Challenge Handshake Authentication Protocol，基于挑战的握手认证协议）



----

### L2-PAP

PAP（Password Authentication Protocol，口令认证协议）

当**PPP**帧中Protocol字段取值为**0xC023**时，表示Information字段承载的是PAP报文。


PAP提供了一种**简单**的方法，可以使对端（peer）使用**两次握手**建立身份验证，这个方法仅仅在链路初始化时使用。链路建立阶段完成后，对端不停地发送ID/Password对给验证者，一直到验证被响应或连接终止为止。可以做无限次的尝试（**暴力破解**）。

PAP不是一个健全的身份验证方法。密码在线路上时**明文**发送的，并且对回送、重复验证和错误攻击没有保护措施。

目前PPP协议的认证阶段大多使用CHAP认证协议。



#### 使用场景

**1. 封闭可信的专线环境**

- **场景描述**：企业内网通过**物理隔离的串行专线（如T1/E1）** 连接分支路由器。
- **选择理由**：
  - 链路物理安全无嗅探风险（如银行内部金融专网）。
  - 配置简单，避免复杂挑战响应逻辑。

**2. 兼容老旧设备或系统**

- **案例**：
  - 工业控制设备（如PLC）使用**老式调制解调器**拨号到监控中心。
  - 兼容老旧Radius服务器（临时）。
- **原因**：
  - 嵌入式设备可能仅支持PAP（固件不支持CHAP计算）。

**3. 临时调试与快速排障**

- **场景**：网络工程师在**实验室环境**临时测试链路连通性。
- **操作**：临时启用PAP快速验证链路基础功能。

> ⚠️ **禁用场景**：公共互联网、无线网络、VPN隧道（存在中间人攻击风险）。



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


|  功能	 | 报文类型	|  报文代码(Code)  |
| -- | -- | -- |
| 认证请求	| Authenticate-Request	| 1 |
| 认证确认	| Authenticate-Ack	| 2 |
| 认证否认	| Authenticate-Nak	| 3 |


##### Authenticate-Request [code=0x01]

Authenticate-Request时，报文格式中的**Data**字段值为:

| *Field* | Peer-ID Length | Peer-ID | Password Length | Password |
| -- | -- | -- | -- | -- |
| *Value* | -- | -- | -- | -- |
| *Length(byte)* | 1 | Value(Peer-ID Length)-1 | 1 | Value(Password Length)-1 |
| *Part* | Peer-ID Length | Peer-ID | Password Length | Password |
| *Order* | Send First | -- | -- | Send End |


##### Authenticate-Ack [code=0x02]
##### Authenticate-Nak [code=0x03]

Authenticate-Ack/Nak时，报文格式中的**Data**字段值为:

| *Field* | Message Length | Message |
| -- | -- | -- |
| *Value* | -- | -- | -- |
| *Length(byte)* | 1 | Value(Message Length)-1 | 1 |
| *Part* | Message Length | Message |
| *Order* | Send First | -- | Send End |



#### 认证流程


| 认证方       | 交互方向 | 报文/数据类型                          | 被认证方                 |
|----------------------|----------|---------------------------------------|--------------------------------|
| 要求使用PAP验证身份   | →        | LCP Configure-Request(Option-Type=0x3, Data=0xC023?) | -                              |
| -                    | ←        | LCP Configure-Ack    | 同意使用PAP验证身份        |
| -                    | ←        | PAP Authenticate-Request | 主动发送错误Peer-ID及Password  |
| 验证身份失败并回复 | →        | PAP Authenticate-Nak                         | -               |
| - | ←        | PAP Authenticate-Request | 主动发送正确Peer-ID及Password |
| 验证身份成功并回复                    | →        | PAP Authenticate-Ack                         | -               |





----

### L2-CHAP

CHAP（Challenge Handshake Authentication Protocol，基于挑战的握手认证协议）

当**PPP**帧中Protocol字段取值为**0xC223**时，表示Information字段承载的是CHAP报文。


CHAP为三次握手协议，安全性较高，可以在链路建立和数据通信阶段多次使用进行认证，可以在链路建立初始化时进行，也可以在链路建立后的任何时间内重复进行。

在链路建立完成后，验证者向对端发送一个chanllenge信息，对端使用一个one-way-hash函数计算出的值响应这个信息。验证者使用相同的单向函数计算自己这一端对应的hash值校验响应值。如果两个值匹配，则验证通过；否则连接终止。

认证过程中需配合事先协商好的算法，确认被认证方的身份，通常使用MD5（Message Digest Algorithm 5）作为其默认算法。只在网络上传输用户名，而不传输用户口令。


目前PPP协议的认证阶段大多使用CHAP认证协议。



#### 使用场景

**1. 公共网络接入（主流选择）**

- **案例**：
  - **PPPoE宽带拨号**（家庭用户通过ADSL/光纤接入ISP）。
  - **4G/5G物联网终端**（如共享单车锁、智能电表）。
- **安全优势**：
  - 密码**永不传输**，黑客无法截获凭证（使用MD5/SHA哈希响应挑战值）。
  - 周期性挑战（默认2小时）防止会话劫持。

**2. 跨运营商VPN互联**

- **场景**：企业总部与云服务商通过**MPLS VPN**互联。
- **必要性**：避免密码在运营商骨干网中泄露（即便MPLS理论上隔离，仍需防泄密）。

**3. 金融/政务高安全网络**

- **合规要求**：
  - PCI-DSS（支付卡安全）：禁止明文传输认证凭据。
  - 等保三级：要求“双向认证”（CHAP支持双向挑战，PAP仅单向）。



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


|  功能	 | 报文类型	|  报文代码(Code)  |
| -- | -- | -- |
| 主认证方发送认证请求	| Challenge	| 1 |
| 被认证方回复认证请求	| Response	| 2 |
| 主认证方发送认证成功	| Success	| 3 |
| 主认证方发送认证失败	| Failure	| 4 |


##### Challenge [code=0x01]

Challenge时，报文格式中的**Data**字段值为:

| *Field* | Value-Size | Value | Name  |
| -- | -- | -- | -- |
| *Value* | -- | -- | -- | -- |
| *Length(byte)* | 1 | Value(Value-Size) | Value(Length)-1-Value(Value-Size) |
| *Part* | Challenge-Value-Size | Challenge-Value | Name  |
| *Order* | Send First | -- | Send End |

- **Value-Size (1字节)**：挑战随机值的字节长度（通常16-32字节）。

- **Challenge Value (变长)**：服务器生成的随机数（防重放攻击）。

- **Name (变长)**：认证方标识（如服务器域名）。



##### Response [code=0x02]

Response时，报文格式中的**Data**字段值为:

| *Field* | Value-Size | Value | Name  |
| -- | -- | -- | -- |
| *Value* | -- | -- | -- |
| *Length(byte)* | 1 | Value(Value-Size) | Value(Length)-1-Value(Value-Size) |
| *Part* | Response-Value-Size | Response-Value | Name  |
| *Order* | Send First | -- | Send End |

- **Value-Size (1字节)**：响应值的固定长度（MD5为16，SHA-1为20）。

- **Response Value (变长)**：客户端计算的哈希值，公式为：

  `Hash = MD5/SHA(Identifier/ID + 明文密码 + Challenge)`, ID是报文格式中的ID

- **Name (变长)**：被认证方标识（如用户名）。



##### Success [code=0x03]

Success时，报文格式中的**Data**字段值为:

| *Field* | Message |
| -- | -- |
| *Value* | -- |
| *Length(byte)* | Value(Length)-Length(Others) |
| *Part* | Message |
| *Order* | -- |

**Message (变长)**：可选的成功描述（如`"Authentication Succeeded"`），可为空。



##### Failure [code=0x04]

Failure时，报文格式中的**Data**字段值为:

| *Field* | Message |
| -- | -- |
| *Value* | -- |
| *Length(byte)* | Value(Length)-Length(Others) |
| *Part* | Message |
| *Order* | -- |

**Message (变长)**：失败原因（如`"Invalid Credentials"`）。



#### 认证流程


| 认证方       | 交互方向 | 报文/数据类型                          | 被认证方                 |
|----------------------|----------|---------------------------------------|--------------------------------|
| 要求使用CHAP验证身份   | →        | LCP Configure-Request(Option-Type=0x3, Data=0xC223?) | -                              |
| -                    | ←        | LCP Configure-Ack    | 同意使用CHAP验证身份        |
| 发送错误随机数及认证方标识 | →        | CHAP Challenge | -                              |
| -                    | ←        | CHAP Response                         | 使用Challenge ID及随机数以及自己被认证方密码计算hash值并结合自己被认证方的标识进行回应 （假设密码错误）              |
| 发送认证失败 | →        | CHAP Failure | -                              |
| 发送错误随机数及认证方标识 | →        | CHAP Challenge | -                              |
| -                    | ←        | CHAP Response                         | 使用Challenge ID及随机数以及自己被认证方密码计算hash值并结合自己被认证方的标识进行回应 （假设密码正确）              |
| 发送认证成功 | →        | CHAP Success | -                              |

> 协议允许​​有限次自动重试​​（由服务器发起新挑战，默认3次）。



----

### 角色区分: 认证方 vs 被认证方

在 PPP 协议的 LCP（Link Control Protocol）阶段，**协议本身不区分服务端（Server）和客户端（Client）**。这是由 PPP 的 **Peer-to-Peer** 设计决定的。判断角色的核心在于 **后续认证阶段的行为** 或 **实际应用场景的逻辑定义**。


**1. 通过认证阶段行为判断**

- **认证方（服务端）**：
  - 在 LCP 协商中声明认证协议（如 `Authentication-Protocol: CHAP (0xC223)`）。
  - **主动发起认证请求**：
    - PAP 场景：发送 `Authenticate-Request`要求客户端提交密码。
    - CHAP 场景：发送 `Challenge`发起挑战（**首次主动行为**）。
- **被认证方（客户端）**：
  - 被动响应认证请求（如返回密码或哈希值）。


**2. 通过应用场景逻辑定义**

| **场景**       | **服务端（认证方）** | **客户端（被认证方）** |
| :------------- | :------------------- | :--------------------- |
| **PPPoE 拨号** | ISP 的 BRAS 设备     | 用户路由器/PC          |
| **企业专线**   | 总部路由器           | 分支机构路由器         |
| **VPN 接入**   | VPN 网关             | 移动办公终端           |

> **实例**：在 PPPoE 中，BRAS 设备在 LCP 阶段通过 `Configure-Request`携带 `Auth-Protocol=CHAP`，并在认证阶段发送 `CHAP Challenge`→ 明确服务端角色。


**3. 通过PPP相关命令配置认证方法使其成为认证方**

e.g.
```
# Cisco（服务端启用认证）
interface Virtual-Template1
  ppp authentication chap  # 声明服务端角色！
```


**4. 双向认证（Two-Way Authentication）​​**

- ​​定义​​：两端互为主备认证方（如企业分支机构间互信场景）。








----

> [Reference Doc 1](https://blog.csdn.net/HinsCoder/article/details/130454920)
