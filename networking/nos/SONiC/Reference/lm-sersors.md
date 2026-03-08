# lm-sensors

`lm_sensors` - Linux hardware monitoring. 是一款免费开源应用程序，提供用于监控温度、电压和风扇的工具和驱动程序。

- [Release](https://deb.debian.org/debian/pool/main/l/lm-sensors/)
- [Github](https://github.com/lm-sensors/lm-sensors)
- [Wiki](https://archive.kernel.org/oldwiki/hwmon.wiki.kernel.org/lm_sensors.html)

# Linux 风扇控制工具笔记

## 核心工具介绍

### lm-sensors：硬件传感器检测核心

lm-sensors（Linux Monitoring Sensors）是基础工具，用于检测主板、CPU、GPU 等硬件的温度传感器和风扇转速。它提供 `sensors` 命令查看实时数据，并为上层控制工具（如 `fancontrol`）提供数据支持。

#### sensors

- 显示sensors配置: `sensors`
- 应用sensors配置: `sensors -s`
- 应用指定的sensors配置: `sensors -s -c /etc/sensors.d/sensors.conf`

#### sensors-detect

- 用于检测并生成内核模块列表。
- 它会询问是否探测各种硬件。“安全”的回答就是默认选项，所以只需对所有问题按 `Enter` 通常不会引起任何问题。这将创建 `/etc/conf.d/lm_sensors` 配置文件，该文件由 `lm_sensors.service` 用于在启动时自动加载内核模块。
- 也可以通过命令 `sensors-detect --auto`跳过询问。

#### sensord

Sensord 是一个守护进程，可用于定期将硬件健康监控芯片的传感器读数记录到 [syslog(3)](https://man.archlinux.org/man/syslog.3.en) 或循环数据库（RRD）中，并在传感器发出警报时发出提醒，例如风扇发生故障、温度超过限制等情况。

### fancontrol：通用风扇控制服务

fancontrol（由 `lm-sensors` 套件提供）是一款轻量级风扇控制服务，通过读取传感器数据动态调整 PWM 风扇转速。支持自定义温度阈值、转速曲线，适合台式机和服务器。

### thinkfan：面向笔记本的智能控制

thinkfan 专为笔记本设计（尤其 ThinkPad），支持多温度源联动（如 CPU、硬盘、GPU）和阶梯式转速调节，平衡散热与续航。配置简单，兼容性好。

### others:

- **psensor**：图形化传感器监控工具，支持实时温度/转速显示，可联动 `fancontrol`调整策略。
- **DE 集成工具**：如 GNOME 的 `gnome-fan-control` 扩展、KDE 的 `kdeplasma-addons`，适合桌面用户快速调整。

## 工具安装指南

以下是主流 Linux 发行版的安装命令：

### Debian/Ubuntu 系列

```bash
# 安装 lm-sensors 和 fancontrol
sudo apt update && sudo apt install lm-sensors fancontrol
# 安装 thinkfan（若需）
sudo apt install thinkfan
# 安装图形化工具 psensor（可选）
sudo apt install psensor
```

### Fedora/RHEL 系列

```bash
# 安装 lm-sensors 和 fancontrol
sudo dnf install lm-sensors fancontrol
# 安装 thinkfan
sudo dnf install thinkfan
# 安装 psensor
sudo dnf install psensor
```

### Arch Linux 系列

```bash
# 安装 lm-sensors 和 fancontrol
sudo pacman -S lm-sensors fancontrol
# 安装 thinkfan
sudo pacman -S thinkfan
# 安装 psensor
sudo pacman -S psensor
```

## 核心配置流程与示例

### 基础：使用 lm-sensors 检测硬件

lm-sensors 需先识别硬件传感器，步骤如下：

1. **启动传感器检测**：

   ```
   sudo sensors-detect
   ```

   按提示操作，默认选项（回车）即可。过程中会询问是否加载内核模块（如 `coretemp` 用于 CPU 温度，`it87` 用于主板传感器），建议全部同意。
2. **验证传感器状态**：

   ```
   sensors
   ```

   输出示例（不同硬件差异大）：

   ```
   coretemp-isa-0000
   Adapter: ISA adapter
   Package id 0:  +42.0°C  (high = +100.0°C, crit = +100.0°C)
   Core 0:        +40.0°C  (high = +100.0°C, crit = +100.0°C)
   Core 1:        +42.0°C  (high = +100.0°C, crit = +100.0°C)

   it8792-isa-0a40
   Adapter: ISA adapter
   in0:          1.02 V  (min =  +0.00 V, max =  +2.78 V)
   fan1:        1800 RPM  (min =    0 RPM)
   temp1:        +38.0°C  (low  = +127.0°C, high = +127.0°C)  sensor = thermistor
   ```

   若未显示风扇转速（如 `fan1`）或温度，可能是硬件不支持或内核模块未加载（需重新运行 `sensors-detect`）。

### sensors 配置

#### 配置手册

- 参阅-配置例子: [lm-sensors/etc/sensors.conf.eg at master · lm-sensors/lm-sensors](https://github.com/lm-sensors/lm-sensors/blob/master/etc/sensors.conf.eg)
- 参阅-默认配置: [lm-sensors/etc/sensors.conf.default at master · lm-sensors/lm-sensors](https://github.com/lm-sensors/lm-sensors/blob/master/etc/sensors.conf.default)

#### 生成配置

- 检测并生成内核模块列表: `sensors-detect`

```
# sensors-detect
This program will help you determine which kernel modules you need
to load to use lm_sensors most effectively. It is generally safe
and recommended to accept the default answers to all questions,
unless you know what you're doing.

Some south bridges, CPUs or memory controllers contain embedded sensors.
Do you want to scan for them? This is totally safe. (YES/no): 
Module cpuid loaded successfully.
Silicon Integrated Systems SIS5595...                       No
VIA VT82C686 Integrated Sensors...                          No
VIA VT8231 Integrated Sensors...                            No
AMD K8 thermal sensors...                                   No
AMD Family 10h thermal sensors...                           No

...

Now follows a summary of the probes I have just done.
Just press ENTER to continue: 

Driver `coretemp':
  * Chip `Intel digital thermal sensor' (confidence: 9)

Driver `lm90':
  * Bus `SMBus nForce2 adapter at 4d00'
    Busdriver `i2c_nforce2', I2C address 0x4c
    Chip `Winbond W83L771AWG/ASG' (confidence: 6)

Do you want to overwrite /etc/conf.d/lm_sensors? (YES/no): 
ln -s '/usr/lib/systemd/system/lm_sensors.service' '/etc/systemd/system/multi-user.target.wants/lm_sensors.service'
Unloading i2c-dev... OK
Unloading cpuid... OK
```

- 显示sensors

```
$ sensors 
coretemp-isa-0000
Adapter: ISA adapter
Core 0:       +35.0°C  (crit = +105.0°C)
Core 1:       +32.0°C  (crit = +105.0°C)

w83l771-i2c-0-4c
Adapter: SMBus nForce2 adapter at 4d00
temp1:        +28.0°C  (low  = -40.0°C, high = +70.0°C)
                       (crit = +85.0°C, hyst = +75.0°C)
temp2:        +37.4°C  (low  = -40.0°C, high = +70.0°C)
                       (crit = +110.0°C, hyst = +100.0°C)
```

#### 调整数值

**在某些情况下，显示的数据可能不正确，或者用户可能希望重命名输出。用例包括**

* **由于错误的偏移量导致温度值不正确（例如，报告的温度比实际高 20 °C）。**
* **用户希望重命名某些传感器的输出。**
* **核心可能以不正确的顺序显示。**

以上所有（以及更多）都可以通过在 `/etc/sensors3.conf` 中创建 `/etc/sensors.d/*foo*` 来覆盖软件包提供的设置，其中任意数量的调整都可以覆盖默认值。建议将“foo”重命名为声卡品牌和型号，但此命名约定是可选的。

lm_sensors 包的 `configs` 目录中包含许多主板的自定义配置文件，可用作模板。

**注意**请勿直接编辑 `/etc/sensors3.conf`，因为软件包更新会覆盖任何更改，从而导致丢失。

要应用配置，请运行带 `-s, --set` 标志的 `sensors`。

```
 # sensors -s
```

##### 示例 1. 调整温度偏移

**这是 Zotac ION-ITX-A-U 主板上的一个实际示例。coretemp 值偏移 20 °C（过高），并根据 Intel 规范进行了调整。**

```
 $ sensors
 coretemp-isa-0000
 Adapter: ISA adapter
 Core 0:       +57.0°C  (crit = +125.0°C)
 Core 1:       +55.0°C  (crit = +125.0°C)
 ...
```

运行带 `-u` 开关的 `sensors` 以查看每个物理芯片可用的选项（原始模式）。如果您看到的某些原始标签似乎无法配置，请查看 `/sys/class/hwmon` 目录树。那里提到的每个设备都有一个 `name` 文件，可用于匹配它所引用的设备。然后尝试该目录引用的标签。

```
 $ sensors -u
 coretemp-isa-0000
 Adapter: ISA adapter
 Core 0:
   temp2_input: 57.000
   temp2_crit: 125.000
   temp2_crit_alarm: 0.000
 Core 1:
   temp3_input: 55.000
   temp3_crit: 125.000
   temp3_crit_alarm: 0.000
 ...
```

创建以下文件来覆盖默认值

```
 /etc/sensors.d/Zotac-IONITX-A-U
 chip "coretemp-isa-0000"
   label temp2 "Core 0"
   compute temp2 @-20,@-20
 
   label temp3 "Core 1"
   compute temp3 @-20,@-20
```

现在调用 `sensors` 将显示调整后的值

```
 $ sensors
 coretemp-isa-0000
 Adapter: ISA adapter
 Core 0:       +37.0°C  (crit = +105.0°C)
 Core 1:       +35.0°C  (crit = +105.0°C)
 ...
```

##### 示例 2. 重命名标签

**这是 Asus A7M266 上的一个实际示例。用户希望为温度标签 **`temp1` 和 `temp2` 提供更详细的名称。

```
 $ sensors
 as99127f-i2c-0-2d
 Adapter: SMBus Via Pro adapter at e800
 ...
 temp1:        +35.0°C  (high =  +0.0°C, hyst = -128.0°C)
 temp2:        +47.5°C  (high = +100.0°C, hyst = +75.0°C)
 ...
```

**创建以下文件以覆盖默认值**

```
 /etc/sensors.d/Asus_A7M266
 chip "as99127f-*"
   label temp1 "Mobo Temp"
   label temp2 "CPU0 Temp"
```

**现在调用** `sensors` 将显示调整后的值

```
 $ sensors
 as99127f-i2c-0-2d
 Adapter: SMBus Via Pro adapter at e800
 ...
 Mobo Temp:        +35.0°C  (high =  +0.0°C, hyst = -128.0°C)
 CPU0 Temp:        +47.5°C  (high = +100.0°C, hyst = +75.0°C)
 ...
```

##### 示例 3. 为多 CPU 系统重编号核心

**这是 HP Z600 工作站（带双 Xeon）上的一个实际示例。物理核心的实际编号不正确：编号为 0、1、9、10，这在第二台 CPU 中是重复的。大多数用户期望核心温度按顺序报告，即 0、1、2、3、4、5、6、7。**

```
 $ sensors
 coretemp-isa-0000
 Adapter: ISA adapter
 Core 0:       +65.0°C  (high = +85.0°C, crit = +95.0°C)
 Core 1:       +65.0°C  (high = +85.0°C, crit = +95.0°C)
 Core 9:       +66.0°C  (high = +85.0°C, crit = +95.0°C)
 Core 10:      +66.0°C  (high = +85.0°C, crit = +95.0°C)
 
 coretemp-isa-0004
 Adapter: ISA adapter
 Core 0:       +54.0°C  (high = +85.0°C, crit = +95.0°C)
 Core 1:       +56.0°C  (high = +85.0°C, crit = +95.0°C)
 Core 9:       +60.0°C  (high = +85.0°C, crit = +95.0°C)
 Core 10:      +61.0°C  (high = +85.0°C, crit = +95.0°C)
 ...
```

再次运行带 `-u` 开关的 `sensors` 以查看每个物理芯片可用的选项。

```
 $ sensors -u coretemp-isa-0000
 coretemp-isa-0000
 Adapter: ISA adapter
 Core 0:
   temp2_input: 61.000
   temp2_max: 85.000
   temp2_crit: 95.000
   temp2_crit_alarm: 0.000
 Core 1:
   temp3_input: 61.000
   temp3_max: 85.000
   temp3_crit: 95.000
   temp3_crit_alarm: 0.000
 Core 9:
   temp11_input: 62.000
   temp11_max: 85.000
   temp11_crit: 95.000
 Core 10:
   temp12_input: 63.000
   temp12_max: 85.000
   temp12_crit: 95.000
 $ sensors -u coretemp-isa-0004
 coretemp-isa-0004
 Adapter: ISA adapter
 Core 0:
   temp2_input: 53.000
   temp2_max: 85.000
   temp2_crit: 95.000
   temp2_crit_alarm: 0.000
 Core 1:
   temp3_input: 54.000
   temp3_max: 85.000
   temp3_crit: 95.000
   temp3_crit_alarm: 0.000
 Core 9:
   temp11_input: 59.000
   temp11_max: 85.000
   temp11_crit: 95.000
 Core 10:
   temp12_input: 59.000
   temp12_max: 85.000
   temp12_crit: 95.000
 ...
```

创建以下文件来覆盖默认值

```
 /etc/sensors.d/HP_Z600
 chip "coretemp-isa-0000"
   label temp2 "Core 0"
   label temp3 "Core 1"
   label temp11 "Core 2"
   label temp12 "Core 3"
 
 chip "coretemp-isa-0004"
   label temp2 "Core 4"
   label temp3 "Core 5"
   label temp11 "Core 6"
   label temp12 "Core 7"
```

现在调用 `sensors` 将显示调整后的值

```
 $ sensors
 coretemp-isa-0000
 Adapter: ISA adapter
 Core0:        +64.0°C  (high = +85.0°C, crit = +95.0°C)
 Core1:        +63.0°C  (high = +85.0°C, crit = +95.0°C)
 Core2:        +65.0°C  (high = +85.0°C, crit = +95.0°C)
 Core3:        +66.0°C  (high = +85.0°C, crit = +95.0°C)
 
 coretemp-isa-0004
 Adapter: ISA adapter
 Core4:        +53.0°C  (high = +85.0°C, crit = +95.0°C)
 Core5:        +54.0°C  (high = +85.0°C, crit = +95.0°C)
 Core6:        +59.0°C  (high = +85.0°C, crit = +95.0°C)
 Core7:        +60.0°C  (high = +85.0°C, crit = +95.0°C)
 ...
```



#### 添加 DIMM 温度传感器

要查找 DIMM 的温度传感器，请[安装](https://wiki.archlinux.org.cn/title/Install "Install") [i2c-tools](https://archlinux.org.cn/packages/?name=i2c-tools) 包。安装完成后，加载 `i2c-dev` [内核模块](https://wiki.archlinux.org.cn/title/Kernel_module "Kernel module")。

```
# modprobe i2c_dev
#mod探测i2c_dev
```

要显示所有列，请[以 root 用户身份](https://wiki.archlinux.org.cn/title/General_recommendations#Security "General recommendations")使用 *i2cdetect*

```
# i2cdetect -l
```

```
i2c-2	smbus     	SMBus PIIX4 adapter port 2 at 0b00	SMBus adapter
i2c-2	smbus     	SMBus PIIX4 adapter port 1 at 0b20	SMBus adapter
i2c-0	smbus     	SMBus PIIX4 adapter port 0 at 0b00	SMBus adapteri2c-2  系统管理总线  PIIX4 适配器端口 2，位于 0b00  系统管理总线适配器
i2c-2  系统管理总线  PIIX4 适配器端口 1，位于 0b20  系统管理总线适配器
i2c-0  系统管理总线  PIIX4 适配器端口 0，位于 0b00  系统管理总线适配器
```

否则，其输出将显示如下

```
i2c-2	unknown    	SMBus PIIX4 adapter port 2 at 0b00	N/A
i2c-2	unknown    	SMBus PIIX4 adapter port 1 at 0b20	N/A
i2c-0	unknown    	SMBus PIIX4 adapter port 0 at 0b00	N/A
i2c-2 未知 SMBus PIIX4 适配器端口 2，位于 0b00 不可用
i2c-2 未知 SMBus PIIX4 适配器端口 1，位于 0b20 不可用
i2c-0 未知 SMBus PIIX4 适配器端口 0，位于 0b00 不可用
```

在以下示例中，RAM 条连接到总线 `SMBus 0`。*i2cdetect* 命令将显示连接到该总线的设备。`-y<span> </span><b>0</b>` 参数使用 `i2c-<b>0</b>` smbus。如果需要，请检查其他总线。

```
# i2cdetect -y 0
```

```
___  0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:                         -- -- -- -- 0c -- -- -- 
10: 10 -- -- -- -- -- -- -- 18 19 -- -- -- -- -- -- 
20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
30: -- -- -- -- -- -- 36 -- -- -- -- -- -- -- -- -- 
40: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 4f 
50: 50 51 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
60: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
70: -- -- -- -- -- -- -- 77
```

RAM 的 SPD（*s*erial *p*resence *d*etect）从地址 `0x50` 开始，RAM 温度传感器从同一总线上的 `0x18` 开始。在此示例中，有 2 个 DIMM 可用。地址 `0x18` 和 `0x19` 是 DIMM 的温度传感器。

要读取 RAM 条的温度，我们需要加载 `jc42` [内核模块](https://wiki.archlinux.org.cn/title/Kernel_module "Kernel module")。您需要告诉模块使用哪些地址。此过程包括将 `<i>module_name</i>` 和 `<i>address</i>` 写入 `<i>smbus_path</i>`。例如

```
# modprobe jc42
# echo jc42 0x18 > /sys/bus/i2c/devices/i2c-0/new_device
# echo jc42 0x19 > /sys/bus/i2c/devices/i2c-0/new_device
```

之后，您的 RAM 条温度将可见

```
$ sensors
```

```
jc42-i2c-0-19
Adapter: SMBus PIIX4 adapter port 0 at 0b00
temp1:        +50.7°C  (low  =  +0.0°C)                  ALARM (HIGH, CRIT)
                       (high =  +0.0°C, hyst =  +0.0°C)
                       (crit =  +0.0°C, hyst =  +0.0°C)

jc42-i2c-0-18
Adapter: SMBus PIIX4 adapter port 0 at 0b00
temp1:        +51.8°C  (low  =  +0.0°C)                  ALARM (HIGH, CRIT)
                       (high =  +0.0°C, hyst =  +0.0°C)
                       (crit =  +0.0°C, hyst =  +0.0°C)
```

#### 添加 S.M.A.R.T. 硬盘温度

自内核 5.6[[1]](https://patchwork.kernel.org/project/linux-hwmon/patch/20191215174509.1847-2-linux@roeck-us.net/) 以来，`drivetemp` 模块将通过 hwmon 报告 SATA/SAS 温度，但 `sensors-detect` 不会自动检测到此，因此必须[手动加载](https://wiki.archlinux.org.cn/title/Kernel_module#Manual_module_handling "Kernel module")该模块。

```
# modprobe drivetemp
```

您现在应该会在 `sensors` 输出中看到类似以下的条目

```
sensors
```

```
drivetemp-scsi-1-0
Adapter: SCSI adapter
temp1:        +33.0°C 

drivetemp-scsi-2-0
Adapter: SCSI adapter
temp1:        +32.0°C  (low  =  +0.0°C, high = +70.0°C)
                       (crit low =  +0.0°C, crit = +70.0°C)
                       (lowest = +29.0°C, highest = +41.0°C)
```

您现在可以[在启动时加载模块](https://wiki.archlinux.org.cn/title/Load_the_module_at_boot "Load the module at boot")。或者，手动将其添加到 `/etc/conf.d/lm_sensors` 的 `HWMON_MODULES` 行。请注意，当 `sensors-detect` 再次允许写入此文件时，它不会自动添加。

### fancontrol 配置 (台式机风扇)

fancontrol 通过配置文件定义“温度-转速”映射，步骤如下：

#### 配置手册

- 参阅-配置说明: [lm-sensors/doc/fancontrol.txt at master · lm-sensors/lm-sensors](https://github.com/lm-sensors/lm-sensors/blob/master/doc/fancontrol.txt)

#### 生成配置

运行 `pwmconfig`（`fancontrol` 配套工具）生成配置：

```bash
sudo pwmconfig
```

工具会自动检测 PWM 可控风扇（标有 `pwm` 的设备），并提示测试各风扇。按提示操作，最终生成 `/etc/fancontrol` 配置文件。

#### 理解配置

打开 `/etc/fancontrol`，关键参数如下（以示例说明）：

```bash
# 温度传感器与风扇对应关系（格式：风扇PWM设备=温度传感器）
FCTEMPS=hwmon2/pwm1=hwmon0/temp1_input
# 风扇PWM设备与转速传感器对应（可选）
FCFANS=hwmon2/pwm1=hwmon2/fan1_input
# 温度阈值：低于 40°C 时风扇最低转速（20%）
MINTEMP=hwmon2/pwm1=40
# 温度阈值：高于 80°C 时风扇最高转速（100%）
MAXTEMP=hwmon2/pwm1=80
# 风扇最低转速（PWM值，0-255，20%对应 51）
MINSTART=hwmon2/pwm1=51
MINSTOP=hwmon2/pwm1=30  # 低于此转速时停转（防卡顿）
```

#### 测试与启动服务

1. 手动测试风扇控制：

   ```
   sudo fancontrol
   ```

   观察风扇是否随温度变化（可通过 `sensors` 或 `stress` 工具模拟负载）。
2. 设置开机自启（以 `systemd` 为例）：

   ```
   sudo systemctl enable --now fancontrol
   ```

### thinkfan 配置 (笔记本风扇)

thinkfan 配置更简洁，适合笔记本多传感器场景：

#### 配置温度源与风扇设备

1. 查看温度传感器路径（以 `/sys/class/thermal` 为例）：

   ```sh
    ~# ls /sys/class/thermal/thermal_zone*/temp
    /sys/class/thermal/thermal_zone0/temp  # CPU 温度（单位：m°C，如 42000 = 42°C）
    /sys/class/thermal/thermal_zone1/temp  # 硬盘温度
   ```
2. 创建配置文件 `/etc/thinkfan.conf`：

   ```sh
   # 温度源（可多个，空格分隔）
   sensor /sys/class/thermal/thermal_zone0/temp
   sensor /sys/class/thermal/thermal_zone1/temp

   # 风扇设备（PWM路径）
   fan /sys/class/hwmon/hwmon2/pwm1

   # 转速规则：(风扇PWM值, 最低温度°C, 最高温度°C)
   # 温度低于 40°C 时停转（PWM=0）
   level 0   0  40
   # 40-50°C 时低速（PWM=50）
   level 50  40 50
   # 50-60°C 时中速（PWM=100）
   level 100 50 60
   # 60°C 以上全速（PWM=255）
   level 255 60 100
   ```

#### 启动与测试

1. 启动 `thinkfan` 服务：`sudo systemctl enable --now thinkfan`
2. 验证状态：

   ```sh
   sudo systemctl status thinkfan  # 查看服务是否运行
   thinkfan -n  # 前台运行并输出日志（按 Ctrl+C 退出）
   ```

## 最佳实践与注意事项

### 持久化设备名称

许多软件期望传感器设备固定在 `/sys/class/hwmon/hwmonX` 中，但在拥有超过 1-2 个提供 hwmon 接口的设备时，情况并非如此。软件可能应该解析 `hwmon?/name` 或使用 lmsensors 库，但遗憾的是，它们通常不会这样做。一些软件（例如：[Monitorix](https://wiki.archlinux.org.cn/title/Monitorix) 或其某些模块，特别是 amdgpu）需要其他位置的持久化名称。

因此，以下类型的 udev 规则可能很有用。并非所有软件都能使用它们（例如，KDE 系统监视器 - 可悲的是，这使得这些软件在许多系统上几乎无用）。在许多情况下，仅匹配 hwmon 子系统和 udev 规则中的合适名称就足够了 - 但并非总是如此！有关编写规则的更多信息，请参阅 [Udev](https://wiki.archlinux.org.cn/title/Udev) 页面。

不能在 `/sys` 层级结构下重命名或创建符号链接。`SYMLINK+=` 语句也不会起作用。因此，我们需要使用 `RUN+=` 语句（请注意，符号链接不需要像此示例一样位于 `/dev` 下 - 它们没有标准的位置，也没有好的位置）。

```
 /etc/udev/rules.d/99-persistent-hwmon-names.rules
 # my motherboard sensor chip:
 ACTION=="add", SUBSYSTEM=="hwmon", ATTRS{name}=="nct6687", RUN+="/bin/sh -c 'ln -s /sys$devpath /dev/nct6678'"
 # a USB device providing sensors:
 ACTION=="add", SUBSYSTEM=="hwmon", ATTRS{name}=="corsaircpro", RUN+="/bin/sh -c 'ln -s /sys$devpath /dev/corsaircpro'"
 # my GPU:
 ACTION=="add", SUBSYSTEM=="hwmon", ATTRS{vendor}=="0x1002", ATTRS{device}=="0x73bf", RUN+="/bin/sh -c 'ln -s /sys$devpath /dev/rx6900xt'"
```

### 避免过热

- **设置合理阈值**：CPU 安全温度通常 < 90°C（临界温度 ~100°C），建议 `MAXTEMP` 设为 80-85°C。
- **负载测试**：配置后用 `stress -c 4`（4核满载）或游戏测试 30 分钟，确保温度不超过 90°C。

### 配置管理

- **备份配置文件**：修改前备份 `/etc/fancontrol` 或 `/etc/thinkfan.conf`。
- **逐步调整**：从保守策略（如默认转速）开始，逐步降低转速测试稳定性。

### 避免冲突

- 禁用固件自带的风扇控制（部分主板需在 BIOS 中关闭“智能风扇”）。
- 同一设备仅使用一种控制工具（如 `fancontrol` 与 `thinkfan` 不可共存）。

## 常见问题排查

### 传感器未检测到

- **内核模块缺失**：运行 `sensors-detect` 时确保加载推荐模块（如 `coretemp`、`nct6775`）。
- **硬件不支持**：部分品牌机（如 Dell、HP）可能限制传感器访问，需刷写 BIOS 或使用第三方内核模块。

### 风扇无响应

- **PWM 支持**：确认风扇为 PWM 类型（DC 风扇不可控），可通过 `cat /sys/class/hwmon/hwmon*/pwm*_mode` 查看（1=PWM，0=DC）。
- **权限问题**：确保 `fancontrol` 或 `thinkfan` 以 root 权限运行。

### 配置无效

- 检查配置文件路径（`/etc/fancontrol` 或 `/etc/thinkfan.conf`）是否正确。
- 查看日志排查错误： `sudo journalctl -u fancontrol  # fancontrol 日志 ``sudo journalctl -u thinkfan    # thinkfan 日志`

> https://wiki.archlinux.org.cn/title/Lm_sensors#Adding_DIMM_temperature_sensors
> https://geek-blogs.com/blog/fanny-app-fan-control-linux/
