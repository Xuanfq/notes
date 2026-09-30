# L2-LCP

LCP（Link Control Protocol，链路控制协议）：用于建立、配置、维护和终止PPP链路。链路从Dead遮状态通过物理接线后链路转为UP，进入Establish，进行LCP协商建立LCP连接，成功则进入Opened进入下一步，否则切换为Dead状态。

LCP负责PPP的链路管理，和上层（网络层）协议无关。

当PPP帧中Protocol字段为0xC021时，表示Information字段数据为LCP报文。


----

### 报文格式

| *Field* | Code | Identifier/ID | Length | Data |
| -- | -- | -- | -- | -- |
| *Value* | -- | -- | -- | -- |
| *Length(byte)* | 1 | 1 | 2 | Value(Length)-OtherLength(4); Default max 1500-4=1496 |
| *Part* | Code | Identifier/ID | Length | Data |
| *Order* | Send First | -- | -- | Send End |


- **Code**为代码字段（也称类型字段），长度为1字节，用来标识LCP中链路控制报文的类型。详细类型见下方。

- **Identifier**为标识符字段，长度为1字节，是报文的唯一标识。Identifier字段用于匹配请求和回复。

- **Length**为长度字段，长度为2字节，Length字段指出该报文的长度，包括Code，Identifier，Length和Data。LCP数据包的长度由链路的最大接收单元（Maximum Receive Unit，MRU）决定，MRU指定了PPP链路上可接收的最大帧长度。默认MRU值为1500字节，但可通过LCP协商调整，取两端最小MRU值。

- **Data**为数据字段，长度是零或多个八位字节，由Length字段声明。Data字段的格式由Code字段决定。



----

### 报文类型

#### 概述

| 类型	|  功能	 | 报文类型	|  报文代码(Code)  |
| -- | -- | -- | -- |
| 链路配置	| 建立和配置链路	| Configure-Request	| 1 |
| 链路配置	| 建立和配置链路	| Configure-Ack	| 2 |
| 链路配置	| 建立和配置链路	| Configure-Nak	| 3 |
| 链路配置	| 建立和配置链路	| Configure-Reject	| 4 |
| 链路终止	| 终止链路	| Terminate-Request	| 5 |
| 链路终止	| 终止链路	| Terminate-Ack	| 6 |
| 链路维护	| 管理和调试链路	| Code-Reject	| 7 |
| 链路维护	| 管理和调试链路	| Protocol-Reject	| 8 |
| 链路维护	| 管理和调试链路	| Echo-Request	| 9 |
| 链路维护	| 管理和调试链路	| Echo-Reply	| 10 |
| 链路维护	| 管理和调试链路	| Discard-Request	| 11 |



#### 链路配置报文

链路配置时，LCP报文格式中的**Data**字段值为一到多个**选项(Options)**列表，选项列表中的参数可同时协商。**选项(Options)**格式如下:

| *Field* | Type | Length | Data |
| -- | -- | -- | -- |
| *Value* | -- | -- | -- |
| *Length(byte)* | 1 | 1 | Value(Length)-Length(Type) |
| *Part* | Code | Length | Data |
| *Order* | Send First | -- | Send End |


- **Type**为类型字段，用于区分协商不同参数。

    | Type值 | 对应参数 | 功能 |
    | ------ | ------ | ------ |
    | 0x00 | Reserved | 保留 |
    | 0x01 | Maximum Receive Unit | 最大接收单元 |
    | 0x02 | Asynchronous Control Character Map | 异步控制字符映射 |
    | 0x03 | Authentication Protocol | 认证协议 |
    | 0x04 | Quality Protocol | 质量协议 |
    | 0x05 | Magic Number | 幻数 |
    | 0x07 | Protocol Field Compression | 协议域压缩 |
    | 0x08 | Address and Control Field Compression | 地址及控制域压缩 |

- **Length**为长度字段，Length字段指出该配置选项（包括Type、Length和Data字段）的长度。

- **Data**为数据字段，Data字段为零或者多个字节，其中包含配置选项的特定详细信息。



##### Configure-Request [Code=0x01]

链路配置时，LCP报文格式中的**Data**字段值为一到多个**选项(Options)**列表，选项列表中的参数可同时协商。报文格式同上。

**报文例子**:

   | PPP Field | LCP Field | Configure Options Field | Bytes | Value | Comment |
   | ---------- | ------ | -------- | ------ | --------------- | --------------- |
   | Flag       | -      | -        | 1      | 0x7E            |     |
   | Address    | -      | -        | 1      | 0xFF            |     |
   | Control    | -      | -        | 1      | 0x03            |     |
   | Protocol   | -      | -        | 2      | 0xC021          |     |
   | Data       | Code   | -        | 1      | 1            |     |
   | Data       | ID     | -        | 1      | 1            |     |
   | Data       | Length | -        | 2      | 24            |     |
   | Data       | Data   | Type     | 1      | 1            |     |
   | Data       | Data | Length   | 1      | 4            |     |
   | Data       | Data    | Data | 2      | 1500            |  MRU   |
   | Data       | Data   | Type     | 1      | 3            |     |
   | Data       | Data | Length   | 1     | 4            |     |
   | Data       | Data   | Data | 2      | 0xC023          |  认证协议   |
   | Data       | Data   | Type     | 1      | 4            |     |
   | Data       | Data | Length   | 1      | 4            |     |
   | Data       | Data   | Data | 2      | 0xC025          |  质量协议   |
   | Data       | Data   | Type     | 1      | 5            |     |
   | Data       | Data | Length   | 1      | 6            |     |
   | Data       | Data     | Data | 4 | -              |  幻数   |
   | Data       | Data   | Type     | 1      | 7            |     |
   | Data       | Data | Length   | 1      | 2            |  Len(Type+Length)=2, No Data   |
   | FCS        | -      | -        | 2      | -         |  Frame Checksum   |
   | Flag       | -      | -        | 1      | 0x7E            |     |



##### Configure-Ack [Code=0x02]



若接收的Configure-Request中的**每一个配置选项的值都可识别且接受**，则回送Configure-Ack（配置确认）报文，回送的*Configure-Ack中的Identifier字段必须与最后接收的Configure-Request相匹配*。此外，Configure-Ack中的**配置选项必须完全与接收的Configure-Request一致**。报文格式同上。

   - **Options均识别但部分接受**: 若收到的每个配置选项都可以识别，但是配置选项的值不能接受，接收方必须回送Configure-Nak（配置否认）。配置选项部分仅用不能接受的配置选项进行填充，回送的Configure-Nak中的Identifier字段必须与最后接收的Configure-Request相匹配。

   - **Options存在不可识别**: 若收到的部分配置选项是不可识别或不能接受，则回送Configure-Reject（配置拒绝确认）。配置选项部分仅用不可识别或不能接受的配置选项进行填充，回送的Configure- Reject中的Identifier字段必须与最后接收的Configure-Request相匹配。

   - 上述报文除Code字段值不同，配置选项的格式与Configure-Request均相同。




##### Configure-Nak [Code=0x03]

若收到的**每个配置选项都可以识别，但是配置选项的值不能接受**，接收方必须回送Configure-Nak（配置否认）。配置选项部分**仅填充不能接受的未经重新排序的配置选项**，回送的Configure-Nak中的Identifier字段必须与最后接收的Configure-Request相匹配。报文格式同上。

  - 当特定类型的 Option 出现多次并具有不同的值时，Configure-Nak 必须同样出现多次并包含该 Option 的所有值，这些值是 Configure-Nak 发送方可接受的。 这包括 Configure-Request 中存在的可接受值。

  - 当需要某种协商需求而 Configure-Request LCP 包未列出该 Option ，则可以将该 Option 附加到 Configure-Nak 的 Option 中，以提示对等方将该 Option 包含在其下一个 Configure-Request LCP 包中。 Option 的 Value 应当是 Configure-Nak 发送方可接受的值。在接收 Configure-Nak 包时，Identifier 字段必须与上次传输的 Configure-Request LCP 包匹配。无效数据包将被静默丢弃。

  - 对端收到有效的 Configure-Nak LCP 包而在发送新的 Configure-Request LCP 包时，可以按照 Configure-Nak 包中的指示修改 Option。当存在 Option 的多个实例时，对等方应选择一个值以包含在其下一个 Configure-Request 包数据包中。某些 Option 具有可变长度。由于 Nak’d Option 已被 Configure-Nak 包发送方修改，因此重新发送 Configure-Request LCP 包的一方必须具有能够处理与原始 Configure-Request 不同的 Option 长度的能力。



##### Configure-Reject [Code=0x04]

若收到的部分配置选项是**不可识别**，则回送Configure-Reject（配置拒绝确认）。**配置选项部分仅填充不可识别的配置选项，并且不得以任何方式重新排序或修改配置选项**，回送的Configure-Reject中的Identifier字段必须与最后接收的Configure-Request相匹配。

发送方收到后，需重新发送Configure-Request，并剔除相关无法识别的参数来继续协商。

Configure-Nak LCP 包和 Configure-Reject LCP 包区别在于：Configure-Nak LCP 包表示双方可以重新协商需求值，而 Configure-Reject LCP 包表示双方明确不可针对某一需求进行交互。



#### 链路终止报文

##### Terminate-Request [Code=0x05]

Terminate-Request时，LCP报文格式中的**Data**字段值为空值或链路终止的原因描述。

当链路节点希望关闭连接时，应当**持续**发送 Terminate-Request LCP 包直到收到 Terminate-Ack LCP 包。而未经 Request 而收到 Terminate-Ack LCP 包时，通常也意味着对等体处于 Closed/Stopped 状态，或者需要重新协商。



##### Terminate-Ack [Code=0x06]

当收到 Terminate-Request LCP 包时，必须发送 Terminate-Ack LCP 包。




#### 链路维护报文

##### Code-Reject [Code=0x07]

Code-Reject（代码拒绝）报文表示**无法识别报文的Code字段**。

发送该报文时，**Data**字段应填充*无法识别的LCP报文*。

若收到该类错误，**应立即终止链路**。



##### Protocol-Reject [Code=0x08]

Protocol-Reject（协议拒绝）报文表示**无法识别报文的Protocol字段**。

发送该报文时，**Data**字段应填充*2字节无法识别的PPP报文的Protocol字段值，以及不定长度的拒绝信息*。

若收到该类错误，**应停止发送该类型的协议报文**。



##### Echo-Request [Code=0x09]

Echo-Request（回波请求）**用于链路质量和性能测试，以及定期（默认10秒/次）检测链路连通性、检测双向链路上的自环问题**。

发送该报文时，**Data**字段应填充*4字节魔术字（与协商成功的魔术字一致），以及不定长度的其他数据*



##### Echo-Reply [Code=0x0a]

Echo-Reply（回波应答）用于**响应Echo-Request，确认链路正常**。



##### Discard-Request [Code=0x0b]

Discard-Request（丢弃请求）是**一个辅助的错误调试和实验报文，无实质用途**。

这种报文收到即会丢弃。



----

### 协商过程

#### 链路建立及配置流程


| 发起方动作描述          | 交互方向 | LCP 报文类型       | 接收方动作描述          |
|-------------------------|----------|--------------------|-------------------------|
| 发起方要求进行协商      | →        | Configure-Request  | -                       |
| -                       | ←        | Configure-Nak      | 部分参数不能接受        |
| 发起方要求再次进行协商  | →        | Configure-Request  | -                       |
| -                       | ←        | Configure-Reject   | 参数不可识别或不可接受  |
| 发起方要求再次进行协商  | →        | Configure-Request  | -                       |
| -                       | ←        | Configure-Ack      | 同意发起方要求协商      |


- 当需要建立逻辑链路时，发起方发送Configure-Request（配置请求）报文，用于协商参数；

- 若接收方收到的每一个配置选项的值都可接受，则回送Configure-Ack（配置确认）报文；

- 若收到的配置选项是可以识别，但部分配置选项参数不能接受，则回送Configure-Nak（配置否认）报文，并标示出需要重新协商的配置选项；

- 若配置选项不可识别或不可接受，则回送Configure-Reject（配置拒绝）报文。



#### 链路终止流程

| 发起方动作描述 | 交互方向 | LCP 报文类型       | 接收方动作描述     |
| -------------- | -------- | ------------------ | ------------------ |
| 要求释放链路   | →        | Terminate-Request  | -                  |
| -              | →        | Terminate-Request  | -                  |
| -              | ←        | Terminate-Ack      | 同意释放请求       |



#### 链路维护流程

| 发起方动作描述       | 交互方向 | 报文/数据类型       | 接收方动作描述                 |
|----------------------|----------|---------------------|--------------------------------|
| 发起环回测试         | →        | Echo-Request        | -                              |
| -                    | ←        | Echo-Reply          | 应答环回测试                   |
| -                    | →        | Discard-Request     | 确认链路运行状态               |
| 发送和接收数据       | →        | 数据                | -                              |
| -                    | ←        | 数据                | -                              |
| -                    | ←        | LCP数据             | -                              |
| -                    | →        | Code-Reject         | -                              |
| -                    | →        | 数据                | -                              |
| -                    | ←        | 数据                | -                              | 



----

> - [Reference Doc 1](https://blog.csdn.net/HinsCoder/article/details/130454920)
> - [Reference Doc 2](https://blog.51cto.com/wljslmz/2561068)
