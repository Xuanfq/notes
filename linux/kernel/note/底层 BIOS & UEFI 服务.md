# 底层 BIOS & UEFI 服务

在 BIOS/UEFI 引导进入 Linux 内核后，固件服务会被划分为**可释放服务**与**保留服务**。

引导阶段的引导服务（UEFI Boot Services，如文件系统访问、早期显卡输出等）会在内核接管系统时通过调用 `ExitBootServices()` 被彻底释放并回收内存；

而**运行时服务（Runtime Services）**及**底层的硬件固件机制**则会常驻内存或在后台持续运行。


---

## 后台服务与接口 - 服务列表

保留和常驻的 BIOS/UEFI 后台服务与接口主要包括以下几类：

### 1. UEFI 运行时服务 (UEFI Runtime Services)

UEFI 规范明确规定，Runtime Services 代码与数据区在 `ExitBootServices()` 调用后必须保留在系统内存中，并通过虚拟地址映射（`SetVirtualAddressMap`）供 Linux 内核直接调用（对应路径通常为 `/sys/firmware/efi/`）：

* **变量服务 (Variable Services)**
* `GetVariable` / `GetNextVariableName`：读取 NVRAM 中的 EFI 变量（如 BootOrder、Secure Boot 密钥、系统配置）。
* `SetVariable`：修改或写入 EFI 变量。
* `QueryVariableInfo`：查询 EFI 变量存储空间的可用容量与剩余空间。


* **时间服务 (Time Services)**
* `GetTime` / `SetTime`：获取或设置硬件 RTC（实时时钟）的时间与时区。
* `GetWakeupTime` / `SetWakeupTime`：查询与设置定时唤醒（RTC Alarm）功能。


* **系统复位服务 (Reset Services)**
* `ResetSystem`：向固件发送复位指令，处理系统冷重启（Cold Reset）、热重启（Warm Reset）和关机（Shutdown）。


* **胶囊更新服务 (Capsule Services)**
* `UpdateCapsule` / `QueryCapsuleCapabilities`：用于固件在线更新（如通过 `fwupd` 工具将新的固件镜像传递给 UEFI 固件并在重启时刷入）。



### 2. ACPI 服务与数据表 (ACPI Services & Tables)

ACPI（高级配置与电源接口）并非独立运行的可执行程序，而是由 BIOS/UEFI 预先载入内存中的数据表与 AML（ACPI Machine Language）字节码。Linux 内核内置 ACPICA 解析器来执行这些字节码，处理硬件控制与事件：

* **电源与状态管理 (Power Management)**
* 处理系统睡眠与休眠状态（S3/Suspend-to-RAM、S4/Hibernate、S5/Soft Off）。
* 提供处理器 C-states（节能状态）与 P-states/CPPC（性能状态与频率调节）的底层硬件描述。


* **温控与风扇管理 (Thermal & Fan Management)**
* 通过 ACPI Thermal Zone（`_TMP`、`_CRT`、`_PSL`）实时监控温度阈值并触发风扇调速或紧急关机策略。


* **事件与中断处理 (ACPI Event Handling)**
* 处理 SCI（System Control Interrupt）系统控制中断，如笔记本翻盖/合盖、电源键/睡眠键按下、AC 电源拔插及热插拔事件（GPE - General Purpose Events）。


* **设备配置与资源分配**
* 提供 PCI 根总线枚举、中断路由表（`_PRT`）、PNP 设备识别及 GPIO/I2C 控制器配置。



### 3. SMM（系统管理模式 / System Management Mode - x86 架构）

SMM 运行在高于操作系统和 Hypervisor 的特权级（Ring -2），对 Linux 内核完全透明。系统通过硬件或软件触发 SMI（System Management Interrupt）时，CPU 会暂停 OS 执行并进入 SMM 内存区（SMRAM）运行固件后台代码：

* **硬件安全与过热保护**：在 OS 崩溃或失控时，硬件级监控代码强制降频或关机以保护芯片。
* **RAS 与硬件错误处理**：处理内存 ECC 严重错误修正与记录、PCIe 硬件故障检测。
* **固件级 TPM (fTPM / Platform Trust Technology)**：如果系统未配备独立 TPM 芯片，TPM 的加密计算与秘钥存储通常在 SMM 或安全执行环境中运行。
* **OEM 专属硬件逻辑**：某些笔记本固件用于控制电池充电上限、键盘背光模式、某些快捷键响应或风扇曲线（当未暴露标准 ACPI 接口时）。

> **注（ARM64 架构）：** 在 ARM64 架构下，对应的机制为 **TrustZone (EL3/Secure Monitor)**，常驻服务包括 **PSCI（Power State Coordination Interface）**，负责核间唤醒、电源管理和 Secure Monitor Call (SMC) 交互。



### 4. SMBIOS / DMI 数据结构

* **硬件信息表 (SMBIOS Tables)**
* 保留在 UEFI 保留内存（EfiRuntimeServicesData 或 EfiACPINMemoryNVS）中。
* Linux 通过 `/sys/class/dmi/id` 或 `dmidecode` 命令读取主板型号、BIOS 版本、内存条槽位与频率、序列号等静态硬件描述数据。



### 附：传统 Legacy BIOS 模式对比

如果系统是以**传统 Legacy BIOS** 方式引导进入 Linux：

* **实模式中断（Real Mode Interrupts）失效**：所有实模式 BIOS 中断（如 `INT 10h` 显示中断、`INT 13h` 磁盘中断）在内核切换到保护模式/长模式后**均无法直接调用**（已被内核原生驱动接管）。
* **保留的服务**：仅保留 **ACPI 表格** 与 **SMM 后台中断处理**。


---

## 后台服务与接口 - 运行机制

Linux 确实完全管理着系统中的进程和 CPU 时间片分配，**这些 BIOS/UEFI 后台服务绝大多数并不是在 OS 之上运行的“系统进程”**。

它们与 Linux 内核的关系以及运行管理机制，可以划分为 **三种截然不同的模式**：


### 模式一：内核主动调用的“底层函数库”（UEFI Runtime Services）

* **谁来管理**：**Linux 内核**。
* **运行机制**：UEFI 运行时服务在内存中并不是“正在后台运行的进程”，而是一堆已经加载到内存中的**被动代码（只读函数库）**。
* **如何执行**：当 Linux 需要操作 BIOS 变量或 RTC 时间时，Linux 内核会像调用内部 C 语言函数一样，**直接跳转到这段固件代码的地址去执行**。
* **CPU 掌控权**：CPU 依然处于 Linux 内核态（Ring 0），代码执行占用的是当前 Linux 内核线程的 CPU 时间。执行完毕后直接返回 Linux 内核。



### 模式二：OS 内部解释执行的“配置脚本”（ACPI 逻辑）

* **谁来管理**：**Linux 内核（内建 ACPICA 解释器）**。
* **运行机制**：ACPI 不是可执行的操作系统进程，它本质上是 BIOS 预先写好并留在内存里的**硬件描述表和字节码（AML, ACPI Machine Language）**。
* **如何执行**：Linux 内核内部自带了一个 ACPI 解释器。当发生硬件事件（如温度过高、按下电源键）时，Linux 的内核线程（如 `kworker`）会去读取并执行对应的 ACPI 字节码来处理硬件逻辑。
* **CPU 掌控权**：完全由 Linux OS 的进程调度器管理和分配 CPU 资源。



### 模式三：硬件强行抢占的“隐形模式”（SMM / 系统管理模式）

这是唯一一种真正“脱离 Linux 控制”的底层运行机制（主要存在于 x86 架构）：

* **谁来管理**：**CPU 硬件本身**，Linux 无法管理甚至无法干预。
* **运行机制**：SMM 运行在高于 Linux 内核（Ring 0）和 Hypervisor 虚拟机（Ring -1）的硬件特权级——**Ring -2**。
* **如何执行（强行中断/抢占）**：
1. 当硬件触发 **SMI（System Management Interrupt，系统管理中断）** 时，**CPU 硬件直接暂停 Linux**（所有 CPU 核心瞬间“冻结”）。
2. CPU 将当前的寄存器和运行状态保存到一块被硬件隔离的区域（SMRAM）。
3. CPU 跳转到 SMRAM 执行 BIOS 固件预设的代码（如硬件错误记录、关键过热保护等）。
4. 执行完成后，固件发出 `RSM`（Resume）指令，CPU 硬件恢复 Linux 的运行状态，Linux 恢复执行。


* **CPU 掌控权**：在 SMI 发生期间，CPU **暂时脱离 OS 控制**。Linux 对此完全无感知，操作系统甚至不知道刚才发生了什么（只能通过极其微小的 CPU 延迟抖动/SMM Latency 推断出 SMM 曾经触发过）。

> **ARM64 架构对应的机制**：ARM 架构下对应的是 **TrustZone / Secure Monitor (EL3)**，通过 `SMC` (Secure Monitor Call) 指令将 CPU 控制权短暂切换给固件层的安全操作系统或 Monitor 运行。



### 总结对比

| 服务/机制类型 | 执行特权级 | 谁来分配/调度 CPU？ | Linux OS 是否知情？ |
| --- | --- | --- | --- |
| **UEFI Runtime Services** | Ring 0 (内核态) | **Linux 内核**（作为函数被主动调用） | 完全知情，主动控制 |
| **ACPI 表与字节码** | Ring 0 (内核态) | **Linux 内核**（内核线程解释执行） | 完全知情，主动控制 |
| **SMM (系统管理模式)** | **Ring -2 (硬件级)** | **CPU 硬件**（通过 SMI 硬中断强行抢占） | **完全无感**（被硬件暂停） |


---

## 后台服务与接口 - 物理存在方式

### 固件预设代码与数据 - 位于动态RAM地址范围

在现代计算机架构中， BIOS/UEFI 通过 **固件预设代码和数据**（如 UEFI Runtime Services、ACPI、SMM）的方式存在于 **内存** 中，且内存地址范围**绝大多数是动态的**，而不是固定的。

在早期的传统 Legacy BIOS 时代，部分地址是固定的（例如著名的 `0x000F0000` 到 `0x000FFFFF` 的 64KB ROM 映射区）。

但在现代 UEFI 系统中，固件代码变得非常庞大，UEFI 固件会在引导的 DXE（驱动执行环境）阶段扫描系统的物理内存（RAM），并根据当前的硬件配置、固件模块数量动态分配和映射这些空间。

在探讨 **Linux Boot** 流程时，Linux 内核是如何知晓并管理这些动态地址的呢？具体机制和地址区域划分如下：

### Linux 如何知道这些地址范围？

Linux 完全依赖于 UEFI 在引导阶段传递给它的“内存映射表”（UEFI Memory Map）。

在引导阶段（通过 GRUB 等 Bootloader 或 Linux 内核自带的 EFI Stub），在调用 `ExitBootServices()` 彻底接管系统之前，程序会调用 UEFI 的 API 函数 `GetMemoryMap()`。
这个函数会返回一个详尽的清单，把系统所有的物理 RAM 划分成一个个区块，并标注每个区块的**类型（Type）**和**物理起始地址**。Linux 内核解析这个清单后，就会知道哪些内存可以给操作系统的应用使用，哪些必须保留给固件。


### 具体服务在 RAM 中的存储类型与寻址方式

根据 UEFI Memory Map 的分类，不同的固件服务会被放置在不同类型的内存区域中：

#### 1. UEFI Runtime Services (运行时服务)

* **内存类型**：UEFI 会将这些代码和数据标记为 `EfiRuntimeServicesCode`（运行时代码段）和 `EfiRuntimeServicesData`（运行时数据段）。
* **Linux 如何处理**：内核解析内存映射表时看到这两个类型，就会将这些物理页标记为“保留”。在 Linux 内核初始化时，会调用 UEFI 的 `SetVirtualAddressMap()` 函数，将这些动态的物理地址重新映射到内核的虚拟地址空间中，以便内核后续在运行时调用它们（如读写 EFI 变量）。

#### 2. ACPI 数据表 (电源与高级配置)

* **内存类型**：ACPI 数据通常被标记为两种类型：
* `EfiACPIReclaimMemory`：存放静态表（如 DSDT、SSDT），Linux 内核读取并解析完这些表格后，**可以将其回收**变成可用内存。
* `EfiACPIMemoryNVS` (Non-Volatile Sleeping)：用于存放休眠（S3/S4）期间系统恢复所需的关键数据，Linux 必须**永久保留**，绝对不可覆盖。


* **Linux 如何寻址**：除了通过内存映射表保护这些区域，Linux 还需要找到 ACPI 的“入口点”。UEFI 会通过其核心结构体 `EFI_SYSTEM_TABLE`（EFI 系统表）向操作系统传递一个配置表（Configuration Table），其中明确记录了 ACPI RSDP（Root System Description Pointer）的绝对物理首地址。内核通过这个指针就能顺藤摸瓜找到所有 ACPI 表。

#### 3. SMM (系统管理模式 / SMRAM)

* **存储位置**：SMM 的代码存放在 RAM 中一个特殊的隔离区域，通常被称为 **SMRAM**，现代架构中最常见的是分配在系统内存顶部的 **TSEG (Top of System Memory Segment)** 区。
* **Linux 如何知道？—— 答案是：Linux 完全不知道。**
* SMM 是对操作系统**完全隐形**的。
* 在 UEFI 引导操作系统的早期阶段，主板的内存控制器（Memory Controller，如 CPU 内部的北桥）会被配置为将 SMRAM 物理锁定（Lock SMRAM）。
* 当 UEFI 生成上述提到的 `GetMemoryMap()` 内存地图时，**它会直接把 SMRAM 所在的内存区域从物理总内存中“扣除”（直接抹除或标记为完全不可用/保留）。**
* 这就是为什么如果你购买了 16GB 的物理内存，在 Linux 系统里用 `free -m` 往往只能看到 15.6GB 或 15.8GB。那几百兆的“失踪”内存，就是被 SMRAM 和其他硬件底层机制动态划走并对 OS 隐藏了。




















