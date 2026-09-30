# Memory


## Diagnosis

### Preparation

- Linux Tool: `dmidecode`
- Usage: 

```sh
~# dmidecode -t memory
# dmidecode 3.1
Getting SMBIOS data from sysfs.
SMBIOS 3.0.0 present.

Handle 0x0027, DMI type 16, 23 bytes
Physical Memory Array
        Location: System Board Or Motherboard
        Use: System Memory
        Error Correction Type: Single-bit ECC
        Maximum Capacity: 128 GB
        Error Information Handle: Not Provided
        Number Of Devices: 4

Handle 0x0029, DMI type 17, 40 bytes
Memory Device
        Array Handle: 0x0027
        Error Information Handle: Not Provided
        Total Width: 72 bits
        Data Width: 72 bits
        Size: 8192 MB
        Form Factor: DIMM
        Set: None
        Locator: DIMM0
        Bank Locator: BANK 0
        Type: DDR4
        Type Detail: Synchronous Unbuffered (Unregistered)
        Speed: 3200 MT/s
        Manufacturer: Samsung
        Serial Number: 0467F560
        Asset Tag: BANK 0 DIMM0 AssetTag
        Part Number: M474A1K43DB1-CWE    
        Rank: 1
        Configured Clock Speed: 2400 MT/s
        Minimum Voltage: 1.2 V
        Maximum Voltage: 1.2 V
        Configured Voltage: 1.2 V

Handle 0x002B, DMI type 17, 40 bytes
Memory Device
        Array Handle: 0x0027
        Error Information Handle: Not Provided
        Total Width: Unknown
        Data Width: Unknown
        Size: No Module Installed
        Form Factor: DIMM
        Set: None
        Locator: DIMM0
        Bank Locator: BANK 1
        Type: Unknown
        Type Detail: Unknown
        Speed: Unknown
        Manufacturer: NO DIMM
        Serial Number: NO DIMM
        Asset Tag: NO DIMM
        Part Number: NO DIMM
        Rank: Unknown
        Configured Clock Speed: Unknown
        Minimum Voltage: Unknown
        Maximum Voltage: Unknown
        Configured Voltage: Unknown

Handle 0x002C, DMI type 17, 40 bytes
Memory Device
        Array Handle: 0x0027
        Error Information Handle: Not Provided
        Total Width: Unknown
        Data Width: Unknown
        Size: No Module Installed
        Form Factor: DIMM
        Set: None
        Locator: DIMM1
        Bank Locator: BANK 0
        Type: Unknown
        Type Detail: Unknown
        Speed: Unknown
        Manufacturer: NO DIMM
        Serial Number: NO DIMM
        Asset Tag: NO DIMM
        Part Number: NO DIMM
        Rank: Unknown
        Configured Clock Speed: Unknown
        Minimum Voltage: Unknown
        Maximum Voltage: Unknown
        Configured Voltage: Unknown

Handle 0x002D, DMI type 17, 40 bytes
Memory Device
        Array Handle: 0x0027
        Error Information Handle: Not Provided
        Total Width: Unknown
        Data Width: Unknown
        Size: No Module Installed
        Form Factor: DIMM
        Set: None
        Locator: DIMM1
        Bank Locator: BANK 1
        Type: Unknown
        Type Detail: Unknown
        Speed: Unknown
        Manufacturer: NO DIMM
        Serial Number: NO DIMM
        Asset Tag: NO DIMM
        Part Number: NO DIMM
        Rank: Unknown
        Configured Clock Speed: Unknown
        Minimum Voltage: Unknown
        Maximum Voltage: Unknown
        Configured Voltage: Unknown
```

```log
~# cat /proc/meminfo
MemTotal:        8064732 kB
MemFree:         7968036 kB
MemAvailable:    7903936 kB
Buffers:            1492 kB
Cached:            52496 kB
SwapCached:            0 kB
Active:            50804 kB
Inactive:           3672 kB
Active(anon):      50512 kB
Inactive(anon):     2456 kB
Active(file):        292 kB
Inactive(file):     1216 kB
Unevictable:           0 kB
Mlocked:               0 kB
SwapTotal:             0 kB
SwapFree:              0 kB
Dirty:                 0 kB
Writeback:             0 kB
AnonPages:           524 kB
Mapped:             1184 kB
Shmem:             52480 kB
Slab:              21996 kB
SReclaimable:       4856 kB
SUnreclaim:        17140 kB
KernelStack:        2144 kB
PageTables:          168 kB
NFS_Unstable:          0 kB
Bounce:                0 kB
WritebackTmp:          0 kB
CommitLimit:     4032364 kB
Committed_AS:      61044 kB
VmallocTotal:   34359738367 kB
VmallocUsed:           0 kB
VmallocChunk:          0 kB
DirectMap4k:       10736 kB
DirectMap2M:     1982464 kB
DirectMap1G:     8388608 kB
```




### 检查内存信息

1. 检查物理内存阵列属性是否正确：
  1. `Maximum Capacity`
  2. `Number of Devices`
  3. `Error Correction Type: Single-bit ECC`
2. 检查内存搭配是否匹配：
  1. `n*m GB`?
  2. 插的DIMM/Slot 1,2,3还是4?
3. 检查每根内存的配置是否正确：
  1. `Data Width`：
  2. `Size`：※ 注意是MB还是GB
  3. `Form Factor`
  4. `Type`：※ 
  5. `Speed`：※ 最大支持频率
  6. `Manufacturer`
  7. `Serial Number`
  8. `Part Number`
  9. `Rank`
  10. `Configured Clock Speed`：※ 实际speed，取决于CPU，小于等于Speed
  11. `Minimum Voltage`
  12. `Maximum Voltage`
  13. `Configured Voltage`


### 检查SPD(通过I2C)


### 内存测试

1. 数据完整性验证 - 可靠地存储和读取数据
  1. 写入-读取-比较循环：向内存写入已知的数据模式，然后读取并验证数据是否与写入的一致
  2. 双缓冲区验证：使用两个相同大小的缓冲区，写入相同数据，然后比较两个缓冲区内容是否一致
2. 内存故障类型检测
  1. 位故障：某些位永远卡在0或1
  2. 地址线故障：地址译码错误
  3. 数据线故障：数据传输错误
  4. 耦合故障：相邻单元互相影响
  5. 刷新故障：动态内存刷新失败



内存测试是确保内存硬件可靠性的关键环节，其测试方法和原理均有扎实的计算机体系结构与数字电路理论支撑，具备充分的科学依据和工程实践验证。以下从**数据完整性验证**和**内存故障类型检测**两方面原理依据进行内存测试。

基于内存硬件的物理特性和工作原理设计，通过“数据一致性验证”和“故障模式针对性检测”，能够有效发现存储单元、地址/数据总线、控制器等组件的缺陷。这些方法经过数十年计算机工程实践的验证，是保障内存可靠性的核心技术手段，具备充分的科学依据和工程实用性。

- 消费级场景：新电脑装机时通过MemTest86等工具检测内存兼容性问题。
- 工业级场景：服务器内存通过ECC校验和双端口冗余机制，结合周期性全容量测试，确保长时间稳定运行。


#### **数据完整性验证**
内存的核心功能是**可靠地存储和读取数据**，因此验证“写入数据与读取数据的一致性”是最基础的测试逻辑。其理论依据源于计算机系统的**存储一致性模型**和**数字信号传输理论**。


##### **写入-读取-比较循环**
- **原理**：  
  向内存指定地址写入已知数据（如全0、全1、交替模式“1010...”等），等待一段时间后读取并与原始数据对比。  
- **理论依据**：  
  - **数字电路的确定性**：正常工作的内存单元在无故障时，写入的数据应能被稳定读取。若读取结果与写入不一致，说明存在物理故障（如晶体管漏电、电容失效）或逻辑错误（如地址译码错误）。  
  - **故障覆盖率**：通过**不同数据模式**（如边界值、随机数据）覆盖多种位组合，可检测不同类型的故障。例如：  
    - **全0/全1模式**：检测位固定故障（ stuck-at-0/1 ）。  
    - **交替模式**：检测相邻单元的耦合干扰（如电容耦合导致数据串扰）。  
    - **随机数据模式**：覆盖更复杂的信号组合，提高故障检测概率。  
- **工程实践**：  
  该方法是内存测试的行业标准（如MemTest86等工具的核心逻辑），广泛应用于计算机出厂测试和故障排查。


##### **双缓冲区验证**
- **原理**：  
  创建两个相同大小的缓冲区A和B，向两者写入相同数据，分别读取并比较内容是否一致。  
- **理论依据**：  
  - **冗余校验思想**：利用“相同输入应产生相同输出”的逻辑，通过冗余存储检测非确定性故障。若两个缓冲区数据不一致，可能存在以下问题：  
    - 某一缓冲区所在的内存区域存在故障（如位翻转）。  
    - 内存控制器或总线在数据传输中引入错误（如信号噪声导致数据失真）。  
  - **并行验证优势**：相比单次写入-读取，双缓冲区可排除“单次操作偶然正确”的误判，提高测试可靠性。  
- **工程实践**：  
  常见于需要高可靠性的场景（如服务器、嵌入式系统），例如操作系统内核的内存管理模块可能通过类似机制验证关键数据区域。


#### **内存故障类型检测**
内存故障的分类源于**数字电路的物理特性**和**存储单元的工作机制**，每种故障类型对应明确的硬件缺陷，测试方法直接针对这些缺陷设计。


##### **位故障（Stuck-at Fault）**
- **现象**：某一位始终为0或1，无法随写入操作改变。  
- **物理原因**：  
  - 存储单元晶体管短路或断路（如DRAM电容漏电、SRAM触发器失效）。  
  - 制造工艺缺陷导致线路固定连接（如金属连线短路）。  
- **检测方法**：  
  通过写入0和1分别验证该位是否可翻转，例如：  
  - 先写入0，读取是否为0；再写入1，读取是否为1。若两次结果相同，则存在位固定故障。


##### **地址线故障（Address Decoding Fault）**
- **现象**：访问地址A时，实际操作的是地址B（地址译码错误）。  
- **物理原因**：  
  - 地址总线线路短路或断路（如PCB布线缺陷、芯片引脚接触不良）。  
  - 地址译码器逻辑错误（如门电路失效导致译码结果错误）。  
- **检测方法**：  
  - 向地址A写入数据X，从地址B读取数据，若读取到X，则说明地址A和B存在映射错误。  
  - 通过遍历连续地址空间，验证“写入地址与读取地址的一一对应性”。


##### **数据线故障（Data Line Fault）**
- **现象**：数据在写入或读取时发生位翻转（如写入0x55，读取为0x57）。  
- **物理原因**：  
  - 数据总线信号干扰（如高频噪声导致电平误判）。  
  - 存储单元与数据总线之间的连接故障（如焊点虚接）。  
- **检测方法**：  
  - 利用**奇偶校验**或**CRC校验**：写入带校验位的数据，读取后重新计算校验值并对比，若不一致则说明数据传输有误。  
  - 直接对比写入值与读取值（同“写入-读取-比较循环”）。


##### **耦合故障（Coupling Fault）**
- **现象**：对单元A的操作影响相邻单元B的数据（如写入A导致B的值翻转）。  
- **物理原因**：  
  - 存储单元之间的电容耦合（尤其是DRAM，相邻电容易因电场干扰互相影响）。  
  - 版图设计缺陷导致信号串扰（如金属线间距过近）。  
- **检测方法**：  
  - **March测试算法**：按特定顺序（如先写入全0，再对每个单元依次写入1并检测相邻单元是否变化）遍历内存，检测相邻单元的干扰效应。  
  - 典型算法如March C-：`{WRITE 0; READ 0; WRITE 1; READ 1; INVERT; READ 0/1}`，通过翻转操作检测耦合导致的位变化。


##### **刷新故障（Refresh Fault）**
- **现象**：动态内存（DRAM）因刷新操作失败导致数据丢失。  
- **物理原因**：  
  - DRAM电容电荷泄漏速度超过刷新周期（如温度升高导致漏电加剧）。  
  - 刷新控制器故障（如定时器失效、刷新地址生成错误）。  
- **检测方法**：  
  - 延长内存空闲时间（超过刷新周期），再读取数据验证是否丢失。  
  - 调整刷新间隔（如缩短或延长默认周期），观察数据稳定性。



#### 代码实现 - memtester

> 专业的内存测试一部分用的是**数据模式测试**，根据CPU架构，关掉CPU缓存，直接对内存进行读写。读写的数据称为**Pattern**(如读写01等)，不同的Data Pattern可以测不同的内存故障。

- 参考`memtester`开源程序，memtester是Simon Kirby在1999年编写的测试程序（v1版），后来由Charles Cazabon一直维护更新（v2及之后版本），主要面向Unix-like系统，官方主页上介绍的是“A userspace utility for testing the memory subsystem for faults.”，其实就是为了测试内存（主要DDR）的读写访问可靠性（仅正确性，与速度性能无关），这是验证板级硬件设备必不可少的一项测试。
- 整个`memtester`测试的视角就是从用户的角度来看的，从用户角度设立不同的测试场景即测试用例，然后针对性地进行功能测试，注意是从系统级来测试，也就是说关注的不单单是内存颗粒了，还有系统板级的连线、IO性能、PCB等等相关的因素，在这些因素的影响下，内存是否还能正常工作。


| 测试函数名                   | 测试作用                                                     |
| ---------------------------- | ------------------------------------------------------------ |
| test_stuck_address           | 先全部把地址值交替取反放入对应存储位置，然后再读出比较，重复n次 |
| test_random_value            | 等效test_random_comparison(bufa, bufb, count)：数据敏感型测试用例 |
| test_xor_comparison          | 与test_random_value比多了个异或操作                          |
| test_sub_comparison          | 与test_random_value比多了个减法操作                          |
| test_mul_comparisone         | 与test_random_value比多了个乘法操作                          |
| test_div_comparison          | 与test_random_value比多了个除法操作                          |
| test_or_comparison           | 在test_random_comparison()里面合并了                         |
| test_and_comparison          | 在test_random_comparison()里面合并了                         |
| test_seqinc_comparison       | 是 test_blockseq_comparison的一个子集；模拟客户压力测试场景  |
| test_solidbits_comparison    | 固定全1后写入两个buffer，然后读出比较，然后全0写入读出比较；这就是Zero-One算法 |
| test_blockseq_comparison     | 一次写一个count大小的块，写的值是拿byte级的数填充32bit，然后取出对比，接着重复256次；也是压力用例，只是次数变多了； |
| test_checkerboard_comparison | 把设定好的几组Data BackGround，依次写入，然后读出比较        |
| test_bitspread_comparison    | 还是在32bit里面移动，只是这次移动的不是单单的一个0或者1，而是两个1，这两个1之间隔着两个空位 |
| test_bitflip_comparison      | 也是32bit里面的一个bit=1不断移动生成data pattern然后，每个pattern均执行 |
| test_walkbits1_comparison    | 与test_walkbits0_comparison同理                              |
| test_walkbits0_comparison    | 就是bit=1的位置在32bit里面移动，每移动一次就全部填满buffer，先是从低位往高位移，再是从高位往低位移动 |
| test_8bit_wide_random        | 以char指针存值，也就是每次存8bit，粒度更细；                 |
| test_16bit_wide_random       | 以unsigned short指针存值，也就是每次存16bit，不同粒度检测；  |



