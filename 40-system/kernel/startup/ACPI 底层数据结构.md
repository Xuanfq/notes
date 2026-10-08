# ACPI 底层数据结构

**ACPI**（Advanced Configuration and Power Interface，高级配置与电源接口），是固件（BIOS/UEFI）向操作系统描述硬件资源、电源管理、设备热插拔的一套标准。

**BIOS/UEFI 在固件阶段生成静态 ACPI 表，加载到内存；Linux 内核的 ACPI 解释器（AML 解释器）读取、解析、执行 AML 字节码，完成硬件枚举、电源控制。**



一些专业名词：

- ASL（ACPI Source Language）：ACPI 高级源码语言，BIOS 工程师写；
- AML（ACPI Machine Language）：ASL 编译后的**栈式虚拟机字节码**，下方 DSDT/SSDT 里存的就是 AML。



## BIOS/UEFI 中的 ACPI 核心数据结构

### 基本结构

ACPI 固件在系统内存地址空间中设置 RSDP（根系统描述指针）以指向 XSDT（扩展系统描述表）。XSDT 总是通过其第一个条目指向 FADT（固定 ACPI 描述表），FADT 中的数据包含描述硬件固定 ACPI 特性的各种固定长度条目。FADT 包含一个指向 DSDT（差分系统描述表）的指针。XSDT 还包含指向可能存在的多个 SSDT（辅助系统描述表）的条目。

DSDT 和 SSDT 的数据组织在称为定义块的数据结构中，其中包含以 AML（ACPI 机器语言）编码的各种对象的定义，包括 ACPI 控制方法。DSDT 的数据块以及 SSDT 的内容共同构成了一个被称为 ACPI 命名空间的层级数据结构，其拓扑结构反映了底层硬件平台的结构。

上述 ACPI 系统定义表之间的关系如下图所示：

```
+---------+    +-------+    +--------+    +------------------------+
|  RSDP   | +->| XSDT  | +->|  FADT  |    |  +-------------------+ |
+---------+ |  +-------+ |  +--------+  +-|->|       DSDT        | |
| Pointer | |  | Entry |-+  | ...... |  | |  +-------------------+ |
+---------+ |  +-------+    | X_DSDT |--+ |  | Definition Blocks | |
| Pointer |-+  | ..... |    | ...... |    |  +-------------------+ |
+---------+    +-------+    +--------+    |  +-------------------+ |
               | Entry |------------------|->|       SSDT        | |
               +- - - -+                  |  +-------------------| |
               | Entry | - - - - - - - -+ |  | Definition Blocks | |
               +- - - -+                | |  +-------------------+ |
                                        | |  +- - - - - - - - - -+ |
               +-------+                +-|->|       SSDT        | |
               | RSDT  |                  |  +-------------------+ |
               +-------+                  |  | Definition Blocks | |
               | Entry |                   |  +- - - - - - - - - -+ |
               +-------+                  +------------------------+
               | ..... |                               |
               +-------+                  OSPM Loading |
                                                      \|/
                                                +----------------+
                                                | ACPI Namespace |
                                                +----------------+

               ACPI Definition Blocks
```

注意：

- **RSDP 还可以包含一个指向 RSDT（根系统描述表）的指针。平台提供 RSDT 是为了保持与 ACPI 1.0 操作系统的兼容性。如果存在 XSDT，预期操作系统会使用 XSDT。**
- **ACPI 规范：系统中可以存在多个 RSDP（Root System Description Pointer），如分别指向 XSDT 和 RSDT，但操作系统只取其中一个有效实例**；现代 UEFI 平台一般只会放 1 份 RSDP，传统 BIOS 平台容易出现多份副本。


#### 根指针结构：RSDP -> RSDT / XSDT

##### RSDP（Root System Description Pointer）

**ACPI 的入口锚点**，放在物理内存低地址区域（EBDA 或 BIOS ROM 保留区），内核最早扫描内存找 RSDP。

- 签名：`"RSD PTR "`（注意末尾空格）
- 作用：存放 RSDT 物理地址（ACPI1.0）或 XSDT（ACPI2.0+，64 位）
- ACPI2.0 RSDP 同时包含 32bit RSDT 和 64bit XSDT 指针，64 位系统优先使用 XSDT。
- 可存在多个 RSDP 指针（见上方）
- RSDP 是内存里的 “指路牌”，单独存在
- 内核扫描内存查找 RSDP：`acpi_find_rsdp()`：内核会扫描规定内存范围，收集**所有匹配 RSD PTR 签名的候选 RSDP**，做 checksum 校验
  1. 收集全部有效 RSDP 实例；收集全部有效 RSDP 实例； 收集全部有效 RSDP 实例；
  2. 优先选择 ACPI 2.0 版本 RSDP；
  3. 拿到 XSDT 物理地址，映射内存，解析 XSDT（带 ACPI_TABLE_HEADER），再遍历 XSDT 里保存的所有 ACPI 子表指针。

##### RSDT / XSDT（Root System Description Table）

- RSDT：32 位，数组存储其他 ACPI 表的**32 位物理地址**
- XSDT：64 位，数组存储其他 ACPI 表的**64 位物理地址**

> RSDT/XSDT 就是一张 “目录表”，里面存所有其他 ACPI 表的物理指针，内核遍历这个表就能找到 FADT、DSDT、SSDT、MADT、HPET 等。

#### 描述表结构：Header(36 Bytes) + Entries(8*n Bytes)

ACPI 所有表都有统一表头：`ACPI_TABLE_HEADER`

```C
struct acpi_table_header {
    char signature[4];         // [0:3] 4字节签名
    u32 length;                 // [4:7] 整张表总长度（包含这个header！）
    u8 revision;                // [8] 表版本号
    u8 checksum;                // [9] 整张表校验和
    char oem_id[6];             // [10:15] OEM厂商ID，比如"DELL  ","LENOVO"
    char oem_table_id[8];      // [16:23] OEM自定义表名字
    u32 oem_revision;           // [24:27] OEM修订号
    char asl_compiler_id[4];   // [28:31] ASL编译器，比如"INTL"、"MSFT"
    u32 asl_compiler_revision; // [32:35] 编译器版本
};
/*
1. **length 是整张表全部字节**：包含 `ACPI_TABLE_HEADER` 本身 + 后面所有表数据。内核校验表时，按这个 length 映射内存。
2. **checksum：整张表（从表头第一个字节到表末尾所有字节）相加，结果必须等于 0**。固件生成表的时候预先填好；内核拿到表，遍历整个表做累加校验，判断表有没有损坏。
3. signature：4 字节 ASCII，用来识别这是哪一张表：`FADT`、`MADT`、`DSDT`、`SSDT`、`XSDT`。

举例子：XSDT 表内存布局
`ACPI_TABLE_HEADER`（36 字节） + 【数组：64 位物理地址，每个条目 8 字节】
整个 XSDT 的 length = 36 + 8 * entry_count
*/
```

RSDT/XSDT/FADT/MADT/DSDT/SSDT 这些都叫 ACPI 描述表，每一张描述表都以 `ACPI_TABLE_HEADER` 作为这张表最开头的结构体，**后面跟着这张表自己专属的数据**。



### 固定描述块：FADT

FADT（Fixed ACPI Description Table）固定 ACPI 描述表

最关键的固定硬件信息表，**不包含 AML 代码，全是静态配置**。
存储全局硬件固定资源：

- PM1a/PM1b 事件寄存器、控制寄存器基地址（IO 端口）
- PM2 控制寄存器、PM 定时器地址
- GPE（通用电源事件）块地址、长度
- 复位寄存器地址、关机寄存器地址
- 支持的睡眠状态 S0/S1/S3/S4/S5
- DSDT 的物理地址
- SCI 中断号（ACPI 事件中断，通知 OS 电源事件）

> S5 = 软关机，FADT 定义 S5 对应的寄存器写值，Linux 关机时就是写这个寄存器触发固件关机。

### AML代码表：DSDT / SSDT

**最重要：ASL 编译后的 AML 字节码存放处，ACPI 解释器的执行对象。**

- DSDT：Differentiated System Description Table，主描述表，差异系统说明表，一个系统只有一张，包含主板根设备、全局控制方法（_INI,_STA,_PRW,_PRL 等）
- SSDT：Secondary System Description Table，辅助描述表，可以多张。用来描述附加设备：CPU、PCI 设备、显卡、热插拔设备，现代 UEFI 大量使用 SSDT，DSDT 只放基础定义。

> ASL（ACPI Source Language）：ACPI 高级源码语言，BIOS 工程师写；
> AML（ACPI Machine Language）：ASL 编译后的**栈式虚拟机字节码**，DSDT/SSDT 里存的就是 AML。
> Linux 的 ACPI 解释器 = AML 虚拟机，专门跑 AML 指令。

DSDT/SSDT 内部不是简单结构体，是**AML 命名空间的序列化二进制流**，里面包含：

- 命名节点（设备、方法、变量、操作域）
- 控制方法（`_STA`获取设备状态、`_INI`设备初始化、`_PRW`唤醒资源、`_ON/_OFF`电源控制）
- OperationRegion：操作域，映射到 IO 端口、PCI 配置空间、MMIO 内存、CMOS 等。

> OperationRegion 是 AML 访问硬件的媒介，AML 代码不能直接访问硬件，只能通过预先定义的操作域读写地址。

### 其他常用静态表（无 AML，只读静态数据）

1. **MADT（Multiple APIC Description Table）**：多核 CPU、APIC/IOAPIC、中断路由，Linux SMP 启动、中断分配依赖 MADT
2. **HPET**：高精度定时器硬件信息
3. **SRAT（System Resource Affinity Table）**：NUMA 架构，内存和 CPU 本地亲和性
4. **SLIT**：NUMA 节点距离矩阵
5. **MPST / PPTT**：CPU 功耗、拓扑信息
6. **BGRT**：UEFI boot logo 信息
7. **FACS**：Firmware ACPI Control Structure，S3 休眠时固件和 OS 交换上下文，存放固件唤醒入口。

> 区分：**静态表（FADT/MADT/SRAT）是纯数据，不需要解释器执行；DSDT/SSDT 是 AML 字节码，必须 AML 解释器解析运行**。

### ACPI 命名空间（Namespace）

DSDT/SSDT 解析后构建出树形命名空间，是 ACPI 核心对象模型。
路径示例：

```
\_SB        // System Bus，根节点，所有设备都挂在这下面
  \_SB.PCI0 // PCI根总线
    \_SB.PCI0.ETH0  // 网卡设备
    \_SB.PCI0._PRW  // 设备的控制方法
\_GPE       // 全局GPE电源事件
\_TZ        // Thermal Zone 温控域
\_PR        // 处理器
```

节点类型：

- Device：设备对象
- Method：AML 控制方法（可执行）
- Field：操作域内的寄存器位域
- Buffer / Integer / Package：数据容器
- OperationRegion：硬件地址映射域
