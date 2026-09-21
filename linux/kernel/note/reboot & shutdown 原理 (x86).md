# reboot & shutdown 原理 (x86)

`shutdown`、`reboot`、`halt` 与 `poweroff` 在 x86/x64 Linux 系统中的本质区别在于**应用层管理权限与调度机制、系统与硬件电源状态（ACPI）的变化，以及传递给内核 `sys_reboot` 系统调用的指令**。

reboot / shutdown 命令用法:
```sh
~# reboot --help
reboot [OPTIONS...] [ARG]

Reboot the system.

     --help      Show this help
     --halt      Halt the machine
  -p --poweroff  Switch off the machine
     --reboot    Reboot the machine
  -f --force     Force immediate halt/power-off/reboot
  -w --wtmp-only Don't halt/power-off/reboot, just write wtmp record
  -d --no-wtmp   Don't write wtmp record
     --no-wall   Don't send wall message before halt/power-off/reboot

See the halt(8) man page for details.

~# shutdown --help
shutdown [OPTIONS...] [TIME] [WALL...]

Shut down the system.

     --help      Show this help
  -H --halt      Halt the machine
  -P --poweroff  Power-off the machine
  -r --reboot    Reboot the machine
  -h             Equivalent to --poweroff, overridden by --halt
  -k             Don't halt/power-off/reboot, just send warnings
     --no-wall   Don't send wall message before halt/power-off/reboot
  -c             Cancel a pending shutdown

See the shutdown(8) man page for details.
```


## 总体对比

| 命令 | 角色与定位 | ACPI 电源状态 | systemd Target | 内核系统调用参数 (`reboot()`) |
| --- | --- | --- | --- | --- |
| **`shutdown`** | 高级调度管理工具（广播通知、阻止登录、定时排期） | 视参数而定（`-h` 关机, `-r` 重启） | 调度 `poweroff.target` 或 `reboot.target` | 间接触发下述其他命令对应的参数 |
| **`reboot`** | 停止系统并重新启动硬件 | S0 $\rightarrow$ 硬件 Reset $\rightarrow$ S0 | `reboot.target` | `LINUX_REBOOT_CMD_RESTART` |
| **`halt`** | 停止系统并挂起 CPU（不断电） | S0（CPU 进入低功耗 `HLT` 死循环） | `halt.target` | `LINUX_REBOOT_CMD_HALT` |
| **`poweroff`** | 停止系统并切断主板主电源 | S5（Soft Off，仅保留待机电源供电） | `poweroff.target` | `LINUX_REBOOT_CMD_POWER_OFF` |

---

## 四个命令的功能与行为区别

1. **`shutdown`（高级调度管理）**
* 不直接下发硬件级别的关机指令，而是向 PID 1（`systemd`）下发排期任务。
* **独有功能**：向所有在线用户广播关机通知（`wall`），创建 `/etc/nologin` 文件阻止新用户登录，支持延迟执行（例如 `shutdown -h +10` 表示 10 分钟后关机）。
* 通过参数转译行为：`-h`（关机断电）、`-H`（仅 halt）、`-r`（重启）。


2. **`reboot`（重新启动）**
* 终止所有用户态进程、同步磁盘缓存并卸载文件系统后，向底层硬件发送复位信号，使机器重新经历 BIOS/UEFI POST 过程并启动系统。


3. **`halt`（停机不断电）**
* 完成操作系统层面的关闭（终止进程、刷盘、卸载磁盘）后，执行 CPU 级别的 `HLT` 汇编指令，使 CPU 停止执行新指令，但**保持电源通电**（主板指示灯保持亮起，风扇可能继续旋转）。


4. **`poweroff`（软关机断电）**
* 完成操作系统层面的关闭后，通过电源管理接口（ACPI）向主板 PMIC（电源管理芯片）下发切断主电源指令，将机器拉入 ACPI S5 状态。




## 底层原理与执行流程

整个过程分为 **用户态服务清理 $\rightarrow$ 内核系统调用 $\rightarrow$ x86/x64 硬件控制** 三个阶段：

### 1. 用户态阶段（PID 1 / systemd）

无论是哪个命令，最终都会调度 systemd 对应的 Target 执行清理：

* 向所有运行进程发送 `SIGTERM` 信号，超时后发送 `SIGKILL` 强制终止。
* 执行 `sync` 操作，将内存 Page Cache 中的脏数据强行写入物理存储。
* 将挂载的文件系统重新挂载为只读（Read-Only）或彻底卸载，防止元数据损坏。


### 2. 内核系统调用阶段（`sys_reboot`）

用户态清理完毕后，调用系统调用 `sys_reboot()`（需传入特定魔数 LINUX_REBOOT_MAGIC1 `0xfee1dead` 及 LINUX_REBOOT_MAGIC2* 进行安全校验）：

* **系统调用号**：x86 (32位) 为 `88`；x64 (64位) 为 `169`。
* 内核根据用户态传入的 command 参数分发分支：
* `LINUX_REBOOT_CMD_RESTART` $\rightarrow$ 执行 `kernel_restart()`
* `LINUX_REBOOT_CMD_HALT` $\rightarrow$ 执行 `kernel_halt()`
* `LINUX_REBOOT_CMD_POWER_OFF` $\rightarrow$ 执行 `kernel_power_off()`


### 3. x86/x64 硬件控制阶段（位于内核 `arch/x86/kernel/reboot.c`）

`kernel_restart/halt/power_off()` 最终调用 `machine_restart/halt/power_off()` (linux/arch/x86/kernel/reboot.c):

* **Reboot 硬件复位实现：**

  - 默认的回退执行链（按顺序尝试，直到硬件复位成功）
    - **ACPI Reboot Register**（第 1 次）：写入 ACPI FADT 表声明的重置寄存器。
    - **8042 Keyboard Controller**（第 1 次）：向 `0x64` 端口写入 `0xFE` 脉冲拉低 CPU RESET 引脚。（现8042 Keyboard Controller基本消失）
    - **ACPI Reboot Register**（第 2 次）：防止某些芯片组响应延迟。
    - **8042 Keyboard Controller**（第 2 次）：再次触发脉冲。
    - **EFI Runtime Service**：若上述传统硬件端口均未生效，调用 UEFI 固件的 `efi.reset_system(...)`。
    - **Legacy BIOS Call**：若为非 EFI 引导，尝试切回实模式调用 BIOS 中断。（向 CMOS 寄存器 0x​​0f 写入 0 `CMOS_WRITE(0x00, 0x8f)`；BIOS 的 POST（加电自检）例程会将其识别为执行正常重启的指令）
  
  - 特殊机制（仅通过 `reboot=` 参数或 DMI Quirks 触发）
    - **PCI Reset (`0xCF9`)**：直接向 PCI 配置空间 `0xCF9` 端口写入 `0x06`(WarmReboot) / `0x0E`(ColdReboot) 触发芯片组 Hard Reset。
      ```
      u8 reboot_code = reboot_mode == REBOOT_WARM ?  0x06 : 0x0E;
      u8 cf9 = inb(0xcf9) & ~reboot_code;      
      outb(cf9|2, 0xcf9); /* Request hard reset */
      udelay(50);
      outb(cf9|reboot_code, 0xcf9); /* Actually do the reset */
      ```
    - **Triple Fault（三重故障）**：加载基址和限长均为 0 的 IDTR（Interrupt Descriptor Table Register，中断描述符表寄存器）使其触发异常，即利用 CPU 的硬件保护机制强行引发物理 Reset。
      ```idt_invalidate(NULL); // load_idt(&{ .address = (unsigned long) 0, .size = 0 });```


* **Halt 停机实现：**
  1. 关闭机器(`machine_shutdown()`) - 停止其他CPU和APIC，依次：关闭 IO APIC, 禁用 Local IRQ，停止 其他CPU 核心，关闭 Local APIC，恢复 Boot IRQ 模式，禁用 HPET，关闭 IOMMU。
  3. 停止 本CPU 核心：禁用 Local IRQ，下线 CPU, 进入死循环并反复执行汇编指令 `hlt`（`native_halt()`），让 CPU 暂停指令运行并进入低功耗状态，电源维持供电（ACPI S0 状态）。


* **Poweroff 切断电源实现：**
  1. 全局`pm_power_off()`函数需要有具体实现，即需要注册电源管理回调
  2. 若为非强制reboot，关闭机器(`machine_shutdown()`) - 停止其他CPU和APIC （同上）
  3. 调用 `pm_power_off()` 进行电源管理关机（如 ACPI 子系统接口 `acpi_power_off()`，EFI 的 `pm_power_off()`，BMC 的 `ipmi_poweroff_function()`）
  4. 内核向 ACPI `PM1a_CNT` / `PM1b_CNT` 控制寄存器写入 `SLP_TYPx`（睡眠类型）和 `SLP_EN`（睡眠使能）标志位。
  5. 主板电源管理芯片切断主电源（+12V、+5V、+3.3V），硬件进入 **ACPI S5 (Soft Off)** 状态，仅留 +5VSB 线路供电。






























