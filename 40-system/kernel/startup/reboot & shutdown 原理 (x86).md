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

| 命令                   | 角色与定位                                       | ACPI 电源状态                                   | systemd Target                               | 内核系统调用参数 (`reboot()`) |
| ---------------------- | ------------------------------------------------ | ----------------------------------------------- | -------------------------------------------- | ------------------------------- |
| **`shutdown`** | 高级调度管理工具（广播通知、阻止登录、定时排期） | 视参数而定（`-h` 关机, `-r` 重启）          | 调度`poweroff.target` 或 `reboot.target` | 间接触发下述其他命令对应的参数  |
| **`reboot`**   | 停止系统并重新启动硬件                           | S0$\rightarrow$ 硬件 Reset $\rightarrow$ S0 | `reboot.target`                            | `LINUX_REBOOT_CMD_RESTART`    |
| **`halt`**     | 停止系统并挂起 CPU（不断电）                     | S0（CPU 进入低功耗`HLT` 死循环）              | `halt.target`                              | `LINUX_REBOOT_CMD_HALT`       |
| **`poweroff`** | 停止系统并切断主板主电源                         | S5（Soft Off，仅保留待机电源供电）              | `poweroff.target`                          | `LINUX_REBOOT_CMD_POWER_OFF`  |

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

* **Reboot 硬件复位逻辑：**

  - 首先告知BIOS是想 Cold / Warm / Hard / Soft / GPIO Reboot：

    - 原理：`0x472` 写入 `0x1234`(WarmReboot) 或 `0`(Other Reboot)。 `*((unsigned short *)__va(0x472)) = reboot_mode == REBOOT_WARM ? 0x1234 : 0;`
    - 修改：通过 cmdline `reboot=` 参数设置。Cold(reboot=c) / Warm(reboot=w) / Hard(reboot=h) / Soft(reboot=s) / GPIO(reboot=g)
  - 默认重启逻辑为 `BOOT_ACPI` ，见`kernel/reboot.c`(`enum reboot_type reboot_type = BOOT_ACPI;`)。
  - 当检测到存在待执行的 UEFI 固件更新胶囊（EFI capsule）时，会忽略用户设置的 cmdline `reboot=` 参数，强制使用固件所需的重启类型，即使用 **EFI Runtime Service** 方式重启，保证固件升级流程正常执行。`if (efi_capsule_pending(NULL)) reboot_type = BOOT_EFI;`
  - 当用户设置了 cmdline `reboot=` 参数，则优先使用对应的重启方法进行重启。
  - DMI 异常适配表优先级最高，笔记本/桌面电脑的一些型号的机器重启方法已内置到kernel dmi table里，没有通过cmdline进行覆写时，优先执行匹配DMI条目进行设置重启的方法，参阅代码中的`reboot_dmi_table`。常见的重启方法：

    - 苹果笔记本（可能是一部分）：BOOT_CF9_SAFE, PCI Reset
    - Acer / Dell ...
  - 如果没有匹配的DMI适配条目，且 ACPI 硬件精简位已置位（平台是 ACPI 硬件精简模式）、同时 EFI 运行时服务已启用，则强制采用 EFI 重启。（对于大多数现代平台，优先采用 ACPI 方式关机。但部分已知平台必须使用 EFI 运行时服务，ACPI 在这类平台上完全无法生效(ACPI 硬件精简)；EFI 方式仅作为兜底方案，只有在没有其他可选方案时才使用。）
  - 默认的回退执行链（按顺序尝试，直到硬件复位成功）

    - BOOT_ACPI(reboot=a) **ACPI Reboot Register**（第 1 次）：写入 ACPI FADT 表声明的重置寄存器。失败则进入 KBD 重启逻辑。
    - BOOT_KBD(reboot=k) **8042 Keyboard Controller**（第 1 次）：向 `0x64` 端口写入 `0xFE` 脉冲拉低 CPU RESET 引脚。（现8042 Keyboard Controller基本消失）。若为第一次从 ACPI 重启逻辑 进入 KBD 重启逻辑，则再次跳转到 ACPI 重启逻辑，见下方；否则进入 EFI 重启逻辑。
    - BOOT_ACPI(reboot=a) **ACPI Reboot Register**（第 2 次）：防止某些芯片组响应延迟。失败则进入 KBD 重启逻辑。
    - BOOT_KBD(reboot=k) **8042 Keyboard Controller**（第 2 次）：再次触发脉冲。失败则进入 EFI 重启逻辑。
    - BOOT_EFI(reboot=e) **EFI Runtime Service**：若上述传统硬件端口均未生效，调用 UEFI 固件的 `efi.reset_system(...)`。失败则进入 BIOS 重启逻辑。
    - BOOT_BIOS(reboot=b) **Legacy BIOS Call**：若为非 EFI 引导，尝试切回实模式调用 BIOS 中断。（向 CMOS 寄存器 0x0f 写入 0 `CMOS_WRITE(0x00, 0x8f)`；BIOS 的 POST（加电自检）例程会将其识别为执行正常重启的指令）。失败将进入下方 BOOT_CF9_SAFE **PCI Reset** 重启逻辑。
    - BOOT_CF9_SAFE(reboot=q) & BOOT_CF9_FORCE(reboot=p) **PCI Reset (`0xCF9`)**：直接向 PCI 配置空间 `0xCF9` 端口写入 `0x06`(WarmReboot) / `0x0E`(ColdReboot) 触发芯片组 Hard Reset。失败将进入下方 BOOT_TRIPLE **Triple Fault（三重故障）** 重启逻辑。

      ```
      u8 reboot_code = reboot_mode == REBOOT_WARM ?  0x06 : 0x0E;
      u8 cf9 = inb(0xcf9) & ~reboot_code;  
      outb(cf9|2, 0xcf9); /* Request hard reset */
      udelay(50);
      outb(cf9|reboot_code, 0xcf9); /* Actually do the reset */
      ```
    - BOOT_TRIPLE(reboot=t) **Triple Fault（三重故障）**：加载基址和限长均为 0 的 IDTR（Interrupt Descriptor Table Register，中断描述符表寄存器）使其触发异常，即利用 CPU 的硬件保护机制强行引发物理 Reset。失败将进入 **8042 Keyboard Controller** 重启逻辑。
      ``idt_invalidate(NULL); // load_idt(&{ .address = (unsigned long) 0, .size = 0 });``
  - 注意：涉及到 command line (cmdline) 的参数 `reboot=` ，多参数通过 `,` 分隔。默认设置的重启逻辑是reboot命令，若需要设置内核崩溃的重启逻辑，可通过`reboot=panic_`进行设置。强制重启为 `reboot=f`。



* **Halt 停机实现：**

  1. 关闭机器(`machine_shutdown()`) - 停止其他CPU和APIC，依次：关闭 IO APIC, 禁用 Local IRQ，停止 其他CPU 核心，关闭 Local APIC，恢复 Boot IRQ 模式，禁用 HPET，关闭 IOMMU。
  2. 停止 本CPU 核心：禁用 Local IRQ，下线 CPU, 进入死循环并反复执行汇编指令 `hlt`（`native_halt()`），让 CPU 暂停指令运行并进入低功耗状态，电源维持供电（ACPI S0 状态）。



* **Poweroff 切断电源实现：**

  1. 全局`pm_power_off()`函数需要有具体实现，即需要注册电源管理回调
  2. 若为非强制reboot，关闭机器(`machine_shutdown()`) - 停止其他CPU和APIC （同上）
  3. 调用 `pm_power_off()` 进行电源管理关机（如 ACPI 子系统接口 `acpi_power_off()`，EFI 的 `efi_power_off()`，BMC 的 `ipmi_poweroff_function()`）。
     * 优先级顺序如下：
       * SYS_OFF_PRIO_FIRMWARE: **ACPI**  (若 ACPI 支持 S5 状态则设置为ACPI关机逻辑)
       * SYS_OFF_PRIO_FIRMWARE + 1: **EFI**（当 ACPI 不支持 S5 时设置）（优先级更高，但需要ACPI不支持S5）
       * `SYS_OFF_PRIO_DEFAULT`: `ipmi_poweroff_function` （默认优先级，见下方，一般不会执行）
     * 原理与机制：
       * **全局确实只有一个 `pm_power_off` 指针** ，但现代内核通过引入**通知链 (Notifier Chain)** 机制，巧妙地实现了多个处理程序的注册与调用。
       * 核心机制：从单一指针到通知链
         * 为了解决单一指针带来的竞态和冲突问题，内核引入了  **`power_off_handler_list`** ，这是一个 **原子通知链** 。所有想要执行电源关闭的函数，都通过 `register_sys_off_handler()` 将自己的 `notifier_block` 注册到这个链表中，而不是直接去抢占那个唯一的 `pm_power_off` 指针。
         * 当需要关机时，内核最终会调用 `atomic_notifier_call_chain()`，这个函数会**遍历整个链表，并按照优先级顺序依次调用**注册的处理程序，直到系统成功断电。
       * 优先级：决定谁先执行的规则
         * 多个处理程序共存的关键在于 **优先级** 。注册时需要指定一个优先级，内核会据此对链表进行排序。主要优先级定义如下：
           * **`SYS_OFF_PRIO_PLATFORM`** (`-256`)：平台级处理程序（通过 `register_platform_power_off` 注册）。这是最底层的保障，**同一时间只允许一个**平台级回调注册，防止冲突。
           * **`SYS_OFF_PRIO_FIRMWARE`** (`224`)：固件级处理程序，如  **ACPI** 。
           * **`SYS_OFF_PRIO_FIRMWARE + 1`** ：比固件更高的优先级，例如  **EFI** ，用于在 ACPI 不可用时优先执行。
           * **`SYS_OFF_PRIO_DEFAULT`** (`0`)：默认优先级，大多数驱动使用此级别，也包括为兼容旧式 `pm_power_off` 而注册的包装器。
           * **`SYS_OFF_PRIO_LOW`** (`-128`)：低优先级，用于那些仅作为“最后手段”的处理程序。
           * `SYS_OFF_PRIO_HIGH`(`192`)：高优先级，但低于 固件级 `SYS_OFF_PRIO_FIRMWARE`
       * 关键兼容层：
         * **旧驱动** ：仍然直接设置 `pm_power_off` 指针。
         * **新内核的兼容** ：在 `do_kernel_power_off()` 函数中，如果检测到 `pm_power_off` 被赋值，内核会**临时**将其包装成一个 `sys_off_handler`，并以 **`SYS_OFF_PRIO_DEFAULT`** 的优先级注册到通知链中，然后立刻执行整个链。
         * **执行顺序** ：这意味着，即使是通过旧式 `pm_power_off` 设置的处理程序，也会在通知链的框架内，以默认优先级被调用，从而保证了新旧机制的平滑过渡。
  4. 内核向 ACPI `PM1a_CNT` / `PM1b_CNT` 控制寄存器写入 `SLP_TYPx`（睡眠类型）和 `SLP_EN`（睡眠使能）标志位。
  5. 主板电源管理芯片切断主电源（+12V、+5V、+3.3V），硬件进入 **ACPI S5 (Soft Off)** 状态，仅留 +5VSB 线路供电。



* **Shutdown 关机原理实现：**
  * 通 **Poweroff** 中的`machine_shutdown`
