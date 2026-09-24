# 底层 BIOS & UEFI 服务

在 BIOS/UEFI 引导进入 Linux 内核后，固件服务会被划分为**可释放服务**与**保留服务**。

引导阶段的引导服务（UEFI Boot Services，如文件系统访问、早期显卡输出等）会在内核接管系统时通过调用 `ExitBootServices()` 被彻底释放并回收内存；

而**运行时服务（Runtime Services）**及**底层的硬件固件机制**则会常驻内存或在后台持续运行。


---

## 后台服务与接口列表

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

## 后台服务与接口运行机制

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




















