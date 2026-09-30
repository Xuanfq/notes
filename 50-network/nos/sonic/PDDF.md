# PDDF

PDDF, Platform Driver Development Framework.

- platform/pddf/
  - platform-api-pddf-base/sonic_platform_pddf_base/  # platform-api python package
  - i2c/  # driver module
    - modules/
      - pddf_client_module
      - pddf_cpld_driver
      - pddf_cpld_module
      - pddf_cpldmux_driver
      - pddf_cpldmux_module
      - pddf_fan_driver
      - pddf_fan_module
      - pddf_fpgai2c_driver
      - pddf_fpgai2c_module
      - pddf_xilinx_device_7021_algo
      - pddf_fpgapci_driver
      - pddf_fpgapci_module
      - pddf_gpio_module
      - pddf_led_module
      - pddf_mux_module
      - pddf_psu_driver_module
      - pddf_psu_module
      - pddf_sysstatus_module
      - pddf_xcvr_driver_module
      - pddf_xcvr_module
    - 



## Driver Module

### sonic-platform-pddf-sym

- sonic-platform-pddf-sym_$(PDDF_PLATFORM_MODULE_VERSION)_amd64.deb

- 安装: 安装`Module.symvers.PDDF`(即`Module.symvers`)到`sonic/platform/pddf/i2c`目录。安装后会通过postinst脚本设置该文件的权限为777，并确保所有者与目录一致。

- 用途: 
  - 提供PDDF内核模块的符号信息，供其他平台模块在编译时使用
  - 允许其他自定义模块能够正确链接到PDDF模块提供的函数



### sonic-platform-pddf

- sonic-platform-pddf_$(PDDF_PLATFORM_MODULE_VERSION)_amd64.deb

- **驱动**: 安装驱动`*.ko`到`/lib/modules/$(KVERSION)/extra/`

- **Python工具和工具库**: (`utils/`目录) 
  - 安装路径:`/usr/local/bin/`
  - Python脚本: (`utils/`)
    - `pddf_util.py`: 核心工具脚本，负责模块安装和清理
    - `pddfparse.py`: 配置解析工具
    - `pddf_s3ip.py`: Simplified Switch System Integration Program 接口实现
  - 配置模式文件: (`utils/schema`)
    - CPLD.schema , CPU.schema , EEPROM.schema
    - FAN.schema , FAN_BMC.schema
    - LED.schema
    - MUX.schema
    - PSU.schema , PSU-PMBUS.schema , PSU_BMC.schema
    - QSFP.schema , SMBUS.schema
    - SYSSTAT.schema
    - TEMP_SENSOR.schema , TEMP_SENSOR_BMC.schema

- **系统服务**: (`service/`目录)
  - `pddf-platform-init.service`
    - 功能: PDDF模块和设备初始化服务
    - 需求: 在`pmon.service`之前启动, `ExecStartPre=-/usr/local/bin/pre_pddf_init.sh`
    - 开始时运行 `/usr/local/bin/pddf_util.py install` 进行初始化
    - 停止时运行 `/usr/local/bin/pddf_util.py clean` 进行清理
  - `pddf-s3ip-init.service`
    - 功能: S3IP接口初始化服务，基于 PDDF 的平台中的 S3IP sysfs 创建
    - 需求: 在`pddf-platform-init.service`之后启动, `ExecStartPre=-/usr/local/bin/pre_pddf_s3ip.sh`
    - 开始时运行 `/usr/local/bin/pddf_util.py install` 进行初始化
    - 停止时运行 `/usr/local/bin/pddf_util.py clean` 进行清理


#### pddf_s3ip.py

S3IP项目(Simplified Switch System Integration Program)，旨在通过软硬件规范和开源，简化**交换机上层OS和底层硬件**集成，降低使用白盒交换机门槛，让更多的企业具备自研能力，促进开源白盒生态发展。

##### 命令行接口

- create : 创建所有 S3IP sysfs 节点
- clean : 清理所有 S3IP sysfs 节点
- 选项 :
  - -h/--help : 显示帮助信息
  - -d/--debug : 启用调试模式，显示详细日志
  - -f/--force : 强制模式，忽略创建或清理过程中的错误


##### 系统检查

- 检查平台配置中是否启用了 S3IP (通过 enable_s3ip 配置项)
- 检查 PDDF 平台服务 pddf-platform-init.service 是否处于活动状态


##### Sysfs 节点创建

- 温度传感器 (temp_sensor)

  - 路径: /sys_switch/temp_sensor/
  - 功能: 创建设备温度监控相关的 sysfs 节点
  - 主要属性:
    - number: 温度传感器总数
    - 每个传感器的子目录 (temp1, temp2 等)
    - 每个传感器属性: alias, type, max, min, value

- 电压传感器 (volt_sensor)

  - 路径: /sys_switch/volt_sensor/
  - 注: 目前在 PDDF 中不支持，仅创建基本目录结构

  - 电流传感器 (curr_sensor)

  - 路径: /sys_switch/curr_sensor/
  - 注: 目前在 PDDF 中不支持，仅创建基本目录结构

- 系统 EEPROM (syseeprom)

  - 路径: /sys_switch/syseeprom
  - 功能: 通过符号链接连接到系统 EEPROM 设备
- 风扇 (fan)

  - 路径: /sys_switch/fan/
  - 功能: 创建风扇托盘和电机相关的 sysfs 节点
  - 主要属性:
    - number: 风扇托盘总数
    - 每个风扇的子目录 (fan1, fan2 等)
    - 风扇属性: model_name, serial_number, part_number, hardware_version, motor_number, direction, ratio, status, led_status
    - 电机属性: speed
- 电源模块 (psu)

  - 路径: /sys_switch/psu/
  - 功能: 创建电源模块相关的 sysfs 节点
  - 主要属性:
    - number: 电源模块总数
    - 每个电源的子目录 (psu1, psu2 等)
    - 电源属性: model_name, hardware_version, serial_number, part_number, type, 输入/输出电流/电压/功率, present, out_status, in_status, fan_speed, led_status

- 收发器 (transceiver)

  - 路径: /sys_switch/transceiver/
  - 功能: 创建网络收发器相关的 sysfs 节点
  - 主要属性:
    - number: 端口总数
    - 每个端口的子目录 (eth1, eth2 等)
    - 端口属性: power_on, tx_fault, tx_disable, present, rx_los, reset, low_power_mode, interrupt, eeprom

- 系统 LED (sysled)

  - 路径: /sys_switch/sysled/
  - 功能: 创建系统指示灯相关的 sysfs 节点
  - 主要属性: sys_led_status, bmc_led_status, fan_led_status, psu_led_status, id_led_status

- FPGA

  - 路径: /sys_switch/fpga/
  - 功能: 创建 FPGA 相关的 sysfs 节点
  - 主要属性:
    - number: FPGA 设备总数
    - 每个 FPGA 的子目录 (fpga1, fpga2 等)
    - FPGA 属性: alias, type, firmware_version, board_version

- CPLD

  - 路径: /sys_switch/cpld/
  - 功能: 创建 CPLD 相关的 sysfs 节点
  - 主要属性:
    - number: CPLD 设备总数
    - 每个 CPLD 的子目录 (cpld1, cpld2 等)
    - CPLD 属性: alias, type, firmware_version, board_version

- 其他模块

  - 看门狗 (watchdog): 目前不支持
  - 插槽 (slot): 目前不支持
  - 电源管理 (power): 目前不支持


##### 核心实现机制

1. PDDF API 交互

   - 脚本通过 `sonic_platform_pddf_base.pddfapi.PddfApi()` 获取平台设备信息
   - 使用 API 获取设备属性路径、LED 状态等
   - 支持两种属性获取方式:
     - BMC 基础属性: 通过 `check_bmc_based_attr()` 和 `bmc_get_cmd()` 获取
     - I2C 基础属性: 通过 `get_path()` 获取对应的 sysfs 路径

2. Sysfs 节点创建方式

   - 目录创建: 使用 `mkdir -p -m 777` 命令创建目录结构
   - 属性设置:
     - 直接写入值: `echo "value" > /sys_switch//path/to/attribute`
     - 符号链接: `ln -s /source/path /sys_switch/path` (链接到现有 sysfs 节点)

3. 日志和错误处理

   - log_os_system() 函数执行系统命令并记录结果
   - 在属性无法获取时设置默认值 "NA"
   - 提供调试模式，显示详细的执行过程和结




#### pddf_util.py

`pddf_util.py` 是 SONiC 网络操作系统中用于管理平台设备驱动框架 (PDDF) 的核心工具脚本，主要负责驱动安装卸载、设备管理以及模式切换功能。

##### 依赖说明

- 需要调用 `pddfparse.py` 解析 `pddf-device.json` 数据。


##### 命令行接口

- `install`: 安装 PDDF 驱动并生成相关 sysfs 节点
- `clean`: 卸载驱动并移除相关 sysfs 节点
- `switch-pddf`: 切换到 PDDF 模式
- `switch-nonpddf`: 切换回平台特定模式 (非 PDDF) 

- 非PDDF模式: 也称为"平台特定模式"，是传统的、每个硬件平台有自己独立驱动和实现的模式
  - 使用平台专属的驱动和API实现
  - 驱动加载方式各平台不同
  - 没有统一的设备创建和管理流程
  - 文件相关
    - 使用平台原始的 `sonic_platform-1.0-py3-none-any.whl` 包
    - 使用平台原始的 `fancontrol` 配置文件
    - 不使用PDDF插件目录
- PDDF模式: 平台驱动开发框架(Platform Driver Development Framework)，提供统一的接口和实现方式
  - 使用标准化的PDDF驱动模块 ( pddf_kos 、 std_kos 等) 
  - 采用统一的设备创建和管理流程
  - 依赖JSON配置文件定义设备结构
  - 文件相关
    - 使用PDDF版本的 `sonic_platform-1.0-py3-none-any.whl` 包
    - 使用PDDF版本的 `fancontrol` 配置文件
    - 使用PDDF通用插件



##### 驱动管理

- 从 `JSON` 配置读取并加载所需内核模块
- 区分永久模块(perm_kos)和普通模块
- 支持驱动**预安装**和**后安装**脚本执行，脚本执行时会检查是否存在，不存在则跳过。执行失败时会输出错误信息，并根据 FORCE 标志决定是否继续执行。
  - 预安装脚本:
    - 驱动预安装: `/usr/local/bin/pddf_pre_driver_install.sh`
  - 后安装脚本:
    - 驱动后安装: `/usr/local/bin/pddf_post_driver_install.sh`



##### 设备管理

- 通过 `pddf_obj` 创建和删除设备节点 (风扇、电源、CPLD、MUX 等) 
- 支持设备**预安装**和**后安装**脚本执行
  - 预安装脚本:
    - 设备预创建: `/usr/local/bin/pddf_pre_device_create.sh`
  - 后安装脚本:
    - 设备后创建: `/usr/local/bin/pddf_post_device_create.sh`



##### Platform API管理

- 支持 API 1.0 (插件文件管理) 和 2.0 (Python wheel 包管理) 同时管理
  - 基于wheel包的实现 (API 2.0) :
    - 文件位置: `device_path/pddf/sonic_platform-1.0-py3-none-any.whl`
    - 实现特点: 完全封装的Python包，基于PDDF 2.0参考API类
  - 基于插件的实现 (API 1.5) :
    - 文件位置: PDDF通用插件目录`device/common/pddf/plugins` (运行时`/usr/share/sonic/platform/plugins`) 和 `pddfparse.py`
      - `pddf-device.json`
        - 定义了设备的拓扑结构（如I2C总线、MUX、设备地址等）
        - 包含每个设备的属性列表及其访问方式
        - 不同平台有各自特定的配置文件，位于设备目录下
      - `pd-plugin.json`
        - 定义了属性值的映射关系（valmap）
        - 规定了如何将原始硬件值转换为有意义的逻辑值
        - 提供了插件行为的配置信息
    - 实现特点: 模块化设计，通过插件扩展基础功能
- 在不同 API 版本间自动切换和适配
- 备份和恢复原始平台组件



##### 模式切换机制

- 通过 `/usr/share/sonic/platform/pddf_support` 文件标记模式状态
- 管理 `Docker pmon`中的相关包
- 协调服务启停以确保平滑切换



##### 核心工作流程

- 安装流程

  1. 检查 PDDF 模式是否启用
  2. 创建日志目录和文件: `/var/log/pddf/*.txt`
  3. 安装驱动模块
  4. 配置 PDDF 工具
  5. 创建设备节点
  6. 启动相关服务 (如 S3IP) 

- 卸载流程

  1. 删除日志文件
  2. 删除设备节点
  3. 卸载驱动模块
  4. 清理 PDDF 配置

- 模式切换流程

  1. 检查平台支持性
  2. 停止相关服务
  3. 切换平台组件
  4. 创建/删除模式标记文件
  5. 重启相关服务



#### pddfparse.py

`pddfparse.py` 是 SONiC 平台上的 PDDF (Platform Device Discovery Framework) 核心工具，负责设备的发现、创建、管理和验证。该脚本主要通过操作 Linux sysfs 接口与内核交互，实现对各种硬件设备的统一管理。


##### 主要实际用途

1. 由`pddf_util.py`调用, 用于解析`pddf-device.json`
2. 由`device/common/pddf/plugins/*.py`(*util.py & eeprom.py)调用, 用于解析`pddf-device.json`


##### 设备配置格式 pddf-device.json

`platform/pddf/i2c/utils/schema`
├── CPLD.schema
├── CPU.schema
├── EEPROM.schema
├── FAN.schema
├── FAN_BMC.schema
├── LED.schema
├── MUX.schema
├── PSU-PMBUS.schema
├── PSU.schema
├── PSU_BMC.schema
├── QSFP.schema
├── SMBUS.schema
├── SYSSTAT.schema
├── TEMP_SENSOR.schema
└── TEMP_SENSOR_BMC.schema


##### 命令行接口

- `--create`: 创建 I2C 拓扑
  - python pddfparse.py --create
- `--delete`: 删除所有创建的 I2C 客户端
  - python pddfparse.py --delete
- `--sysfs`: 显示访问属性 sysfs
  - python pddfparse.py --sysfs all
  - python pddfparse.py --sysfs print psu
  - python pddfparse.py --sysfs validate fan
  - python pddfparse.py --sysfs verify temp_sensor
- `--dsysfs`: 显示数据属性 sysfs
  - python pddfparse.py --dsysfs all
  - python pddfparse.py --dsysfs validate system
  - python pddfparse.py --dsysfs print sysstatus
  - python pddfparse.py --dsysfs psu1 status
- `--validate`: 验证设备特定属性
  - python pddfparse.py --validate all [设备类型...]
- `--schema`: 模式验证
  - python pddfparse.py --schema <all|mismatch|missing|empty|$device_type>
- `--modules`: 加载模块验证
  - python pddfparse.py --modules <bmc|$pddf_kos|pddf...>


##### 核心功能模块

**初始化与配置加载**

- 初始化时创建平台符号链接
- 从 `/usr/share/sonic/platform/pddf/pddf-device.json` 加载设备配置 (`pddf-device.json`)
- 初始化内部数据结构用于存储设备信息


**设备创建功能**

- 创建设备的入口函数
- 首先创建 LED 设备
- 然后通过 dev_parse 递归创建系统中所有设备
- 最后创建系统状态设备（如果存在）


**设备类型处理**


**设备解析系统**

- 设备解析的核心分发函数
- 根据设备类型调用对应的处理方法
- 支持递归处理设备拓扑结构
- 对删除操作有特殊的反向处理逻辑


**BMC接口功能**

- 支持 raw 和 non-raw 类型的 IPMI 请求
- 实现了命令缓存机制提高性能
- 支持各种数据格式转换（ASCII、掩码、原始值等）


**验证和调试功能**

- schema_validation() : 验证设备 JSON 配置是否符合模式
- modules_validation() : 验证所需内核模块是否已加载
- validate_pddf_devices() : 验证设备属性
- dump_sysfs_obj() : 显示 sysfs 对象信息


##### 核心工作流程

1. 配置加载: 从 JSON 文件加载设备拓扑和属性信息
2. 命令解析: 通过命令行参数确定要执行的操作
3. 设备处理: 根据命令类型执行相应的设备操作
   - 创建：按拓扑顺序创建所有设备
   - 删除：按反向拓扑顺序删除所有设备
   - 查询：获取设备属性和状态
   - 验证：检查设备配置和功能




## Platform API


- sonic_platform_pddf_common-$(PDDF_PLATFORM_API_BASE_VERSION)-py3-none-any.whl
- sonic_platform_pddf_common-$(PDDF_PLATFORM_API_BASE_VERSION)-py2-none-any.whl (ENABLE_PY2_MODULES=y)

- 用途: 
  - 提供设备抽象层: 实现了SONiC平台设备的抽象类，为不同硬件平台提供统一的API接口
    - 平台设备可以**继承该API/Class**进行定制化实现 (一般pddfapi.py除外)
  - JSON配置驱动(**`pddfapi.py`**): 基于JSON配置文件（ `pddf-device.json` 和 `pd-plugin.json` ）动态发现和管理平台设备，避免硬编码

- 模块:
  - pddfapi.py: 核心API实现，负责读取PDDF配置文件、提供路径查找、命令执行等基础功能
  - pddf_platform.py: 实现平台抽象，继承自PlatformBase
  - pddf_chassis.py: 实现机箱抽象，继承自ChassisBase，管理所有平台组件
  - pddf_psu.py: 电源管理实现，支持读取PSU状态、功率、温度等属性
  - pddf_fan.py: 风扇管理实现，支持读取风扇状态、速度、方向等属性
  - pddf_thermal.py: 温度传感器实现，支持读取温度值和阈值设置
  - pddf_eeprom.py: 系统EEPROM解析，继承自TlvInfoDecoder


### 模块结构 sonic_platform_pddf_base

`sonic_platform_pddf_base`

- `__init__.py`
- `pddf_chassis.py`
- `pddf_eeprom.py`
- `pddf_fan.py`
- `pddf_fan_drawer.py`
- `pddf_platform.py`
- `pddf_psu.py`
- `pddf_sfp.py`
- `pddf_thermal.py`
- `pddfapi.py`


### 通用依赖

#### sonic-platform-common (sonic_platform_base pkg)

- 源码位置: src/sonic-platform-common

src/sonic-platform-common
├── `sonic_eeprom` -> sonic_platform_base/sonic_eeprom
├── `sonic_fan`
├── `sonic_led`
├── `sonic_platform_base`
│   ├── sonic_eeprom
│   ├── sonic_pcie
│   ├── sonic_sfp
│   ├── sonic_storage
│   ├── sonic_thermal_control
│   └── sonic_xcvr
├── `sonic_psu`
├── `sonic_sfp` -> ./sonic_platform_base/sonic_sfp/
├── `sonic_thermal`
├── `sonic_y_cable`
│   ├── broadcom
│   ├── credo
│   └── microsoft

#### sonic-py-common (sonic_py_common pkg)

- 源码位置: src/sonic-py-common

sonic-py-common/`sonic_py_common`
├── __init__.py
├── daemon_base.py
├── device_info.py
├── general.py
├── interface.py
├── logger.py
├── multi_asic.py
├── port_util.py
├── sonic_db_dump_load.py
├── syslogger.py
├── task_base.py
└── util.py


### 模块详解

> 带 `*` 号表示会调用具体Platform实现类: sonic_platform package


#### pddf_chassis.py *

PddfChassis 是 SONiC 平台中实现的机架（Chassis）基础 API 的具体实现，基于平台设备驱动框架（PDDF）构建，负责管理和提供整个设备机架的信息。该类继承自 ChassisBase ，提供了标准化的接口来访问和管理设备的各个组件。

- 主类: `class PddfChassis(ChassisBase)`

- 依赖: 
  - `sonic_platform_base`: 通用Platform基础类 - src/sonic-platform-common
    - chassis_base.py:
      - `class ChassisBase`
  - `sonic_platform`: **具体Platform实现类**
    - sfp.py:
      - `class Sfp`
    - psu.py:
      - `class Psu`
    - fan_drawer.py:
      - `class FanDrawer`
    - thermal.py:
      - `class Thermal`
    - eeprom.py:
      - `class Eeprom`

- 类成员:
  - `pddf_data`: class PddfApi
  - `pddf_plugin_data`: {}

- 初始化:
  - 父类初始化: ChassisBase.__init__(self)
  - 若无传入参数, 加载API及Plugin数据 (见pddf_platform.py)
    - 加载PDDF API: self.pddf_data = `pddfapi.PddfApi()`
    - 加载Plugin数据: self.pddf_plugin_data = json.load(open("`/usr/share/sonic/platform/pddf/pd-plugin.json`"))
  - 获取平台清单`platform_inventory`: `pddfapi.get_platform()['PLATFORM']`
  - 实例化EEPROM(TLV): `self._eeprom = Eeprom(self.pddf_obj, self.plugin_data)`
  - 实例化所有FanDrawer(不包括PSU的Fan): 
    ```py
        for i in range(self.platform_inventory['num_fantrays']):
            fandrawer = FanDrawer(i, self.pddf_obj, self.plugin_data)
            self._fan_drawer_list.append(fandrawer)
            self._fan_list.extend(fandrawer._fan_list)
    ```
  - 实例化所有PSU: 
    ```py
        for i in range(self.platform_inventory['num_psus']):
            psu = Psu(i, self.pddf_obj, self.plugin_data)
            self._psu_list.append(psu)
    ```
  - 实例化所有SFP(光模块设备): 
    ```py
        for index in range(self.platform_inventory['num_ports']):
            sfp = Sfp(index, self.pddf_obj, self.plugin_data)
            self._sfp_list.append(sfp)
    ```
  - 实例化所有Thermal(温度传感器抽象实例): 
    ```py
        for i in range(self.platform_inventory['num_temps']):
            thermal = Thermal(i, self.pddf_obj, self.plugin_data)
            self._thermal_list.append(thermal)
    ```

- 功能概述:
  1. 初始化与资源管理
    - 配置加载 ：加载 PDDF 设备配置和插件数据
    - EEPROM 初始化 ：初始化系统 EEPROM，用于获取设备基本信息
    - 组件枚举 ：自动根据平台配置初始化所有硬件组件，包括：
      - 风扇抽屉（FanDrawer）和风扇（Fan）
      - 电源模块（PSU）
      - 光纤模块（SFP）
      - 温度传感器（Thermal）
  2. 基本信息获取
    - 名称与型号 ：通过 get_name() 和 get_model() 获取机架名称和型号
    - 存在性与状态 ：通过 get_presence() 和 get_status() 确认机架存在性和运行状态
    - 标识信息 ：通过 get_service_tag() 、 get_serial() 获取服务标签和序列号
    - 网络信息 ：通过 get_base_mac() 获取基础 MAC 地址
    - EEPROM 信息 ：通过 get_system_eeprom_info() 获取完整的系统 EEPROM 信息
  3. 组件管理接口
    - 风扇系统 ：管理风扇抽屉和风扇，提供标准化访问方法
    - 电源系统 ：管理电源模块，监控其状态和参数
    - 光纤模块 ：管理所有 SFP/QSFP 等光模块
    - 温度监控 ：管理所有温度传感器，监控系统温度
  4. LED 控制功能
    - LED 颜色设置 ：通过 set_system_led() 设置指定 LED 设备的颜色
    - LED 状态获取 ：通过 get_system_led() 获取指定 LED 设备的当前颜色
    - 底层集成 ：与 PDDF API 集成，支持不同类型 LED 设备的控制
  5. 平台集成
    - PDDF 集成 ：利用 PddfApi 访问底层硬件信息和操作
    - 插件支持 ：通过插件数据扩展功能
    - 配置驱动 ：基于 JSON 配置文件动态适应不同平台



#### pddf_eeprom.py

PddfEeprom 是 SONiC 平台中实现的系统 EEPROM 管理类，继承自 TlvInfoDecoder ，负责读取、解析和提供系统 EEPROM 中的信息。该类基于平台设备驱动框架（PDDF）构建，为上层应用提供标准化的硬件信息访问接口。

- 主类: `class PddfEeprom(eeprom_tlvinfo.TlvInfoDecoder)`

- 依赖: 
  - `sonic_eeprom`: 通用Platform基础类 - src/sonic-platform-common
    - eeprom_tlvinfo.py:
      - `class TlvInfoDecoder`

- 类成员:
  - `pddf_data`: class PddfApi
  - `pddf_plugin_data`: {}
  - `_TLV_INFO_MAX_LEN`: 256

- 初始化:
  - 父类初始化: PddfEeprom.__init__(self, pddf_data, pddf_plugin_data)
    - 创建缓存目录(读取EEPROM数据成功后设置缓存文件):
      - CACHE_ROOT = '/var/cache/sonic/decode-syseeprom'
      - CACHE_FILE = 'syseeprom_cache'
    - 尝试读取EEPROM数据: `self.eeprom_data = self.read_eeprom()`
    - 解析EEPROM字段TLV: `self.eeprom_tlv_dict[code] = value`

- 功能概述:
  1. 初始化与配置
    - 参数验证 ：验证 PDDF JSON 数据的有效性
    - 路径获取 ：通过 PDDF API 获取系统 EEPROM 设备路径
    - 父类初始化 ：初始化 TlvInfoDecoder 父类，设置 EEPROM 路径和相关参数
    - 缓存管理 ：创建缓存目录，设置缓存文件路径，提高读取性能
  2. EEPROM 数据读取与解析
    - 数据读取 ：从硬件 EEPROM 中读取原始数据
    - 数据缓存 ：将读取的数据更新到缓存中，减少重复读取
    - TLV 解析 ：解析符合 ONIE（Open Network Install Environment）标准的 TLV（Type-Length-Value）格式数据
    - 字典构建 ：将解析后的数据构建成字典，方便快速访问
  3. 标准化信息获取
    - 序列号 ：通过 serial_number_str() 获取设备序列号
    - MAC 地址 ：通过 base_mac_addr() 获取基础 MAC 地址
    - 型号信息 ：通过 modelstr() 获取设备型号
    - 部件号 ：通过 part_number_str() 获取部件号
    - 服务标签 ：通过 serial_str() 获取服务标签
    - 版本信息 ：通过 revision_str() 获取设备版本
    - 完整信息 ：通过 system_eeprom_info() 获取完整的 EEPROM 信息字典



#### pddf_fan.py

PddfFan 是 SONiC 平台中实现的风扇管理类，继承自 FanBase ，负责管理和监控设备中的风扇。该类基于平台设备驱动框架（PDDF）构建，支持管理两种类型的风扇：普通风扇（位于风扇抽屉中）和 PSU 风扇（位于电源模块中），为上层应用提供标准化的风扇管理接口。

- 主类: `class PddfFan(FanBase)`
  - 管理每一个带转速的风扇设备。一个风扇整体模块中可能包含多个风扇转子，每一个转子都抽象成一个风扇设备PddfFan类。

- 依赖: 
  - `sonic_platform_base`: 通用Platform基础类 - src/sonic-platform-common
    - fan_base.py:
      - `class FanBase`

- 类成员:
  - `pddf_data`: class PddfApi
  - `pddf_plugin_data`: {}

- 初始化:
  - 父类初始化: FanBase.__init__(self)
  - 加载Platfrom设备的设置(pddf-device.json): `self.platform = self.pddf_obj.get_platform()`
  - 判断当前风扇的 tray_idx (风扇托盘) 是否超出设置设定的数量 num_fantrays
  - 判断当前风扇的 fan_idx (风扇托盘中的风扇索引, 一个风扇托盘可能有多个风扇, 如前后rear/front) 是否超出设置设定的数量 num_fans_pertray
  - 是否是PSU Fan, 所在哪个索引的PSU等

- 功能概述:
  1. 初始化与配置
    - 参数验证 ：验证 PDDF JSON 数据有效性，确保必要参数存在
    - 索引检查 ：检查风扇抽屉和风扇索引是否在有效范围内
    - 类型识别 ：区分普通风扇和 PSU 风扇，应用不同管理策略
  2. 基本信息获取
    - 名称获取 ：根据风扇类型和配置生成风扇名称 get_name()
    - 存在性检测 ：检查风扇是否存在 get_presence()
    - 状态检查 ：基于风扇速度判断风扇运行状态 get_status()
    - 方向获取 ：获取风扇气流方向（进气/排气） get_direction()
    - 位置信息 ：获取风扇在父设备中的物理位置 get_position_in_parent()
    - 可更换性 ：指示风扇是否可单独更换 is_replaceable()
  3. 风扇速度管理
    - 速度百分比 ：获取风扇当前速度占最大速度的百分比 get_speed()
    - 速度 RPM ：获取风扇当前速度的实际 RPM 值 get_speed_rpm()
    - 目标速度 ：获取风扇的目标速度设置 get_target_speed()
    - 速度容差 ：获取风扇速度的允许偏差范围 get_speed_tolerance()
    - 速度设置 ：设置风扇速度为指定百分比 set_speed()
  4. LED 控制功能
    - 状态 LED 获取 ：获取风扇状态 LED 颜色 get_status_led()
    - 状态 LED 设置 ：设置风扇状态 LED 颜色 set_status_led()
  5. 系统文件操作
    - 系统文件转储 ：获取风扇相关的系统文件系统信息 dump_sysfs()



#### pddf_fan_drawer.py *

PddfFanDrawer 是 SONiC 平台中实现的风扇抽屉、风扇托盘（Fan Drawer）管理类，继承自 FanDrawerBase ，负责管理和监控设备中的风扇抽屉及其包含的风扇。该类基于平台设备驱动框架（PDDF）构建，为上层应用提供标准化的风扇抽屉管理接口。

- 主类: `class PddfFanDrawer(FanDrawerBase)`
  - 风扇抽屉，即一个风扇整体模块或FRU设备，也即上方所述的“风扇托盘”的抽象。管理多个风扇设备class PddfFan。

- 依赖: 
  - `sonic_platform_base`: 通用Platform基础类 - src/sonic-platform-common
    - fan_drawer_base.py:
      - `class FanDrawerBase`
  - `sonic_platform`: **具体Platform实现类**
    - fan.py:
      - `class Fan`

- 类成员:
  - `pddf_data`: class PddfApi
  - `pddf_plugin_data`: {}

- 初始化:
  - 父类初始化: FanDrawerBase.__init__(self)
  - 加载Platfrom设备的设置(pddf-device.json): `self.platform = self.pddf_obj.get_platform()`
  - 判断当前风扇的 tray_idx (风扇托盘) 是否超出设置设定的数量 num_fantrays
  - 根据设置设定的每个风扇托盘里的风扇数量 num_fans_pertray 创建其应管理的风扇设备Fan

- 功能概述:
  1. 初始化与配置
    - 参数验证 ：验证 PDDF JSON 数据的有效性
    - 平台信息获取 ：从 PDDF API 获取平台配置信息
    - 风扇抽屉索引验证 ：检查风扇抽屉索引是否在有效范围内
    - 风扇初始化 ：根据平台配置，为每个风扇抽屉初始化相应数量的风扇对象
  2. 基本信息获取
    - 名称获取 ：通过 get_name() 获取风扇抽屉名称，格式为 "Fantray{索引}"
    - 存在性检测 ：通过 get_presence() 检查风扇抽屉是否存在，基于第一个风扇的存在状态
    - 状态检查 ：通过 get_status() 检查风扇抽屉整体状态，基于所有风扇的状态
    - 可更换性 ：通过 is_replaceable() 指示风扇抽屉是否可更换
    - 位置信息 ：通过 get_position_in_parent() 获取风扇抽屉在父设备中的物理位置
  3. LED 控制功能
    - 状态 LED 获取 ：通过 get_status_led() 获取风扇抽屉状态 LED 颜色
      - 支持从 PDDF 配置的 LED 设备获取实际状态
      - 当没有配置 LED 设备时，提供基于状态的默认颜色方案
    - 状态 LED 设置 ：通过 set_status_led() 设置风扇抽屉状态 LED 颜色
  4. 风扇管理
    - 风扇列表维护 ：维护风扇抽屉内的所有风扇对象列表
    - 风扇状态聚合 ：通过聚合所有风扇的状态来推断风扇抽屉的整体状态
    - 层次化管理 ：实现了从风扇到风扇抽屉的层次化管理结构



#### pddf_platform.py *

平台PDDF抽象类, 主要提供平台`Chassis`实例的获取。


- 主类: `class PddfPlatform(PlatformBase)`

- 依赖: 
  - `sonic_platform_base`: 通用Platform基础类 - src/sonic-platform-common
    - platform_base.py:
      - `class PlatformBase`
  - `sonic_platform`: **具体Platform实现类**
    - chassis.py:
      - `class Chassis`

- 类成员:
  - `pddf_data`: class PddfApi
  - `pddf_plugin_data`: {}

- 初始化:
  - 加载PDDF API: self.pddf_data = `pddfapi.PddfApi()`
  - 加载Plugin数据: self.pddf_plugin_data = json.load(open("`/usr/share/sonic/platform/pddf/pd-plugin.json`"))
  - PlatformBase.__init__(self)
  - 初始化机箱: self._chassis = `Chassis(self.pddf_data, self.pddf_plugin_data)`

- 功能概述:
  1. 获取机箱抽象实例 get_chassis()



#### pddf_psu.py *

PddfPsu 是 SONiC 平台中实现的电源模块（PSU）管理类，继承自 PsuBase ，负责管理和监控设备中的电源模块。该类基于平台设备驱动框架（PDDF）构建，为上层应用提供标准化的电源模块管理接口。

- 主类: `class PddfPsu(PsuBase)`

- 依赖: 
  - `sonic_platform_base`: 通用Platform基础类 - src/sonic-platform-common
    - psu_base.py:
      - `class PsuBase`
  - `sonic_platform`: **具体Platform实现类**
    - fan.py:
      - `class Fan`
    - thermal.py:
      - `class Thermal`

- 类成员:
  - `pddf_data`: class PddfApi
  - `pddf_plugin_data`: {}

- 初始化:
  - 父类初始化: PsuBase.__init__(self)
  - 加载Platfrom设备的设置(pddf-device.json): `self.platform = self.pddf_obj.get_platform()`
  - 获取PSU风扇数量: `self.num_psu_fans = int(self.pddf_obj.get_num_psu_fans('PSU{}'.format(index+1)))`
  - 根据PSU风扇数量逐个创建其所带的所有风扇实例: `self._fan_list.append(Fan(0, psu_fan_idx, pddf_data, pddf_plugin_data, True, self.psu_index))`
  - 根据设定的Thermal数量创建所有Thermal实例(实际固定为1个, 实际上是温度TEMP): `self._thermal_list.append(Thermal(psu_thermal_idx, pddf_data, pddf_plugin_data, True, self.psu_index))`

- 功能概述:
  1. 初始化与配置
    - 参数验证 ：验证 PDDF JSON 数据的有效性
    - 平台信息获取 ：从 PDDF API 获取平台配置信息
    - PSU 索引设置 ：设置 PSU 索引（从 1 开始）
    - 风扇初始化 ：根据平台配置，为每个 PSU 初始化相应数量的风扇对象
    - 温度传感器初始化 ：为每个 PSU 初始化温度传感器对象
  2. 基本信息获取
    - 名称获取 ：通过 get_name() 获取 PSU 名称，支持从插件配置或默认格式生成
    - 存在性检测 ：通过 get_presence() 检查 PSU 是否存在，基于系统文件中的 psu_present 属性
    - 状态检查 ：通过 get_status() 检查 PSU 运行状态，基于系统文件中的 psu_power_good 属性
    - 型号获取 ：通过 get_model() 获取 PSU 型号，从系统文件中的 psu_model_name 属性读取
    - 序列号获取 ：通过 get_serial() 获取 PSU 序列号，从系统文件中的 psu_serial_num 属性读取
    - 制造商 ID 获取 ：通过 get_mfr_id() 获取 PSU 制造商 ID，从系统文件中的 psu_mfr_id 属性读取
    - 位置信息 ：通过 get_position_in_parent() 获取 PSU 在父设备中的物理位置
    - 可更换性 ：通过 is_replaceable() 指示 PSU 是否可更换
  3. 电气参数监控
    - 输出电压 ：通过 get_voltage() 获取 PSU 输出电压
    - 输出电流 ：通过 get_current() 获取 PSU 输出电流
    - 输出功率 ：通过 get_power() 获取 PSU 输出功率
    - 输入电压 ：通过 get_input_voltage() 获取 PSU 输入电压
    - 输入电流 ：通过 get_input_current() 获取 PSU 输入电流
    - 输入功率 ：通过 get_input_power() 获取 PSU 输入功率
    - 电压阈值 ：通过 get_voltage_high_threshold() 和 get_voltage_low_threshold() 获取电压阈值
    - 最大功率 ：通过 get_maximum_supplied_power() 获取 PSU 最大输出功率
  4. 温度监控
    - 温度获取 ：通过 get_temperature() 获取 PSU 温度
    - 温度阈值 ：通过 get_temperature_high_threshold() 获取 PSU 温度高阈值
  5. LED 控制功能
    - 状态 LED 获取 ：通过 get_status_led() 获取 PSU 状态 LED 颜色
      - 支持从 PDDF 配置的 LED 设备获取实际状态
      - 当没有配置 LED 设备时，提供基于状态的默认颜色方案
    - 状态 LED 设置 ：通过 set_status_led() 设置 PSU 状态 LED 颜色
      - 支持颜色映射转换，确保使用正确的颜色值
  6. 风扇管理
    - 风扇数量获取 ：通过 get_num_fans() 获取 PSU 风扇数量
    - 风扇对象管理 ：维护 PSU 风扇对象列表，支持访问每个风扇的详细信息
    - 温度传感器管理 ：维护 PSU 温度传感器对象列表，支持访问每个温度传感器的详细信息
  7. 系统文件操作
    - 系统文件转储 ：通过 dump_sysfs() 方法获取 PSU 相关的系统文件系统信息



#### pddf_sfp.py

PddfSfp 是 SONiC 平台中实现的光纤模块（SFP）管理类，继承自 SfpOptoeBase ，负责管理和监控设备中的光纤模块。该类基于平台设备驱动框架（PDDF）构建，为上层应用提供标准化的光纤模块管理接口。

- 主类: `class PddfSfp(SfpOptoeBase)`

- 依赖: 
  - `sonic_platform_base`: 通用Platform基础类 - src/sonic-platform-common
    - sonic_xcvr/sfp_optoe_base.py:
      - `class SfpOptoeBase`

- 类成员:
  - `pddf_data`: class PddfApi
  - `pddf_plugin_data`: {}
  - `_port_start`:
  - `_port_end`:

- 初始化:
  - 加载Platfrom设备的设置(pddf-device.json): `self.platform = self.pddf_obj.get_platform()`
  - 判断当前的实例是否超过端口设定范围(`[0,num_ports)`): `self._port_end = int(self.platform['num_ports']); if index < self._port_start or index >= self._port_end`
  - 初始化设备名(从1开始): `self.device = 'PORT{}'.format(self.port_index)`
  - 获取SFP设备类型(如QSFP-DD等): `self.sfp_type = self.pddf_obj.get_device_type(self.device)`
  - 获取SFP设备EEPROM映射文件所在路径: `self.eeprom_path = self.pddf_obj.get_path(self.device, 'eeprom')`
  - 父类初始化: SfpOptoeBase.__init__(self)

- 功能概述:
  1. 初始化与配置
    - 参数验证 ：验证 PDDF JSON 数据的有效性
    - 平台信息获取 ：从 PDDF API 获取平台配置信息
    - 端口索引验证 ：检查端口索引是否在有效范围内
    - 设备初始化 ：设置设备名称、类型和 EEPROM 路径
  2. 基本信息获取
    - 名称获取 ：通过 get_name() 获取光纤模块名称，格式为 "PORT{索引}"
    - 存在性检测 ：通过 get_presence() 检查光纤模块是否存在，基于系统文件中的 xcvr_present 属性
    - 位置信息 ：通过 get_position_in_parent() 获取光纤模块在父设备中的物理位置
    - 可更换性 ：通过 is_replaceable() 指示光纤模块是否可更换
    - EEPROM 路径 ：通过 get_eeprom_path() 获取光纤模块 EEPROM 路径
  3. 状态监控功能
    - 复位状态 ：通过 get_reset_status() 获取光纤模块复位状态
    - 接收信号丢失 ：通过 get_rx_los() 获取光纤模块接收信号丢失状态
    - 发送故障 ：通过 get_tx_fault() 获取光纤模块发送故障状态
    - 发送禁用 ：通过 get_tx_disable() 获取光纤模块发送禁用状态
    - 低功耗模式 ：通过 get_lpmode() 获取光纤模块低功耗模式状态
    - 中断状态 ：通过 get_intr_status() 获取光纤模块中断状态
  4. 控制功能
    - 复位操作 ：通过 reset() 复位光纤模块，恢复默认设置
    - 发送禁用控制 ：通过 tx_disable() 控制光纤模块发送禁用状态
    - 低功耗模式控制 ：通过 set_lpmode() 设置光纤模块低功耗模式状态
  5. 系统文件操作
    - 系统文件转储 ：通过 dump_sysfs() 方法获取光纤模块相关的系统文件系统信息



#### pddf_thermal.py

PddfThermal 是 SONiC 平台中实现的温度传感器管理类，继承自 ThermalBase ，负责管理和监控设备中的温度传感器。该类基于平台设备驱动框架（PDDF）构建，为上层应用提供标准化的温度传感器管理接口。

- 主类: `class PddfThermal(ThermalBase)`

- 依赖: 
  - `sonic_platform_base`: 通用Platform基础类 - src/sonic-platform-common
    - thermal_base.py:
      - `class ThermalBase`

- 类成员:
  - `pddf_data`: class PddfApi
  - `pddf_plugin_data`: {}

- 初始化:
  - 加载Platfrom设备的设置(pddf-device.json): `self.platform = self.pddf_obj.get_platform()`
  - 设置对象名(从1开始): `self.thermal_obj_name = "TEMP{}".format(self.thermal_index)`
  - 获取对象属性: `self.thermal_obj = self.pddf_obj.data[self.thermal_obj_name]`
  - 设置是否是PSU的Thermal, 若是则继续设置其所属的PSU索引(从1开始)

- 功能概述:
  1. 初始化与配置
    - 参数验证 ：验证 PDDF JSON 数据的有效性
    - 平台信息获取 ：从 PDDF API 获取平台配置信息
    - 温度传感器索引设置 ：设置温度传感器索引（从 1 开始）
    - 对象初始化 ：初始化温度传感器对象，区分主板温度传感器和 PSU 温度传感器
  2. 基本信息获取
    - 名称获取 ：通过 get_name() 获取温度传感器名称，PSU 温度传感器和主板温度传感器有不同的命名规则
    - 存在性检测 ：通过 get_presence() 检查温度传感器是否存在，PSU 温度传感器基于 PSU 的存在状态
    - 位置信息 ：通过 get_position_in_parent() 获取温度传感器在父设备中的物理位置
    - 可更换性 ：通过 is_replaceable() 指示温度传感器是否可更换（通常不可更换）
    - 温度标签 ：通过 get_temp_label() 获取温度传感器的标签信息
  3. 温度监控功能
    - 当前温度 ：通过 get_temperature() 获取温度传感器的当前温度值
      - 支持从不同类型的设备（主板和 PSU）获取温度
      - 处理不同单位的温度值转换（毫摄氏度转摄氏度）
  4. 阈值管理功能
    - 高温阈值 ：通过 get_high_threshold() 获取温度传感器的高温阈值
    - 低温阈值 ：通过 get_low_threshold() 获取温度传感器的低温阈值
    - 高温临界阈值 ：通过 get_high_critical_threshold() 获取温度传感器的高温临界阈值
    - 低温临界阈值 ：通过 get_low_critical_threshold() 获取温度传感器的低温临界阈值
    - 设置高温阈值 ：通过 set_high_threshold() 设置温度传感器的高温阈值
    - 设置低温阈值 ：通过 set_low_threshold() 设置温度传感器的低温阈值
    - PSU 温度传感器特殊处理 ：PSU 温度传感器通常不支持阈值设置，会抛出 NotImplementedError
  5. 系统文件操作
    - 系统文件转储 ：通过 dump_sysfs() 方法获取温度传感器相关的系统文件系统信息



#### pddfapi.py

PddfApi 是一个平台设备驱动框架（Platform Device Driver Framework，PDDF）的核心 API 实现类，提供了一套完整的设备管理和监控功能。该类位于 SONiC 网络操作系统的平台抽象层，负责与硬件设备进行交互。

- 主类: `class PddfApi`

- 依赖: 
  - `sonic_py_common`: 通用Python基础类 - src/sonic-py-common
    - device_info.py:
      - `def get_platform_and_hwsku()`
        - platform: device's platform identifier, e.g. x84_64-cls_dsxxx-r0
          1. 优先从环境变量中获取: `os.getenv("PLATFORM")`
          2. 其次从机器配置中获取: `/host/machine.conf`, 字段为`onie_platform`/`aboot_platform`
          3. Docker环境中的ConfigDB获取: `ConfigDBConnector().get_table('DEVICE_METADATA')['localhost']['platform']`
        - hwsku: device's hardware SKU identifier, e.g. "DS2000 t1" in device/$platform/default_sku
          1. Docker环境中的ConfigDB获取: `ConfigDBConnector().get_table('DEVICE_METADATA')['localhost']['hwsku']`
  - `/usr/share/sonic/platform/pddf/pddf-device.json`
  - 与pddfparse.py并不直接交互

- 初始化:
  - 检查是否存在平台设备数据路径`/usr/share/sonic/platform`, 若无, 创建链接`"/usr/share/sonic/device/"+self.platform`到`/usr/share/sonic/platform`
  - 从平台设备数据路径中加载`pddf-device.json`PDDF设备数据: `/usr/share/sonic/platform/pddf/pddf-device.json`

- 功能概述:
  1. 初始化与配置管理
    - 加载 pddf-device.json 配置文件，构建设备信息数据库
    - 处理平台链接和设备路径设置
    - 维护系统文件系统对象缓存
  2. 通用设备操作
    - 命令执行 ：通过 runcmd 执行系统命令
    - 设备索引 ：通过 get_dev_idx 获取设备索引
    - 路径管理 ：通过 get_paths / get_path 获取设备属性路径
    - 设备类型识别 ：通过 get_device_type 确定设备类型
    - 平台信息 ：通过 get_platform 获取平台基本信息
  3. LED 设备管理
    - 颜色获取 ：支持从 GPIO、CPLD 和 BMC 等不同类型设备获取 LED 颜色
    - 颜色设置 ：提供 LED 颜色设置功能
    - 系统 LED 控制 ：封装了系统级 LED 操作接口
  4. 设备属性访问
    - 属性路径解析 ：为不同类型设备（PSU、FAN、温度传感器等）提供属性路径解析
    - 设备特定属性 ：支持访问各种设备的特定属性，如风扇转速、温度值等
    - GPIO 操作 ：提供 GPIO 属性路径计算和访问
  5. 系统验证与测试
    - 设备验证 ：通过 verify_attr / verify_device 验证设备属性值
    - Sysfs 验证 ：检查系统文件系统节点创建情况
    - 模块验证 ：验证必要内核模块加载状态
  6. 设备解析系统
    - 类型化解析 ：为不同设备类型（CPU、MUX、EEPROM、光纤模块等）提供专门的解析方法
    - 层次化处理 ：支持设备树层次结构的解析
    - 动态操作 ：根据命令类型动态调用相应处理方法
  7. BMC集成 (Baseboard Management Controller) 
    - BMC 命令执行 ：通过 IPMI 工具与 BMC 交互
    - 缓存机制 ：维护 BMC 响应缓存，提高性能
    - 属性转换 ：将 BMC 原始数据转换为系统可用格式
  8. 属性读写接口
    - 统一属性访问 ：封装了不同类型设备的属性读写操作
    - 多模式支持 ：同时支持 I2C 和 BMC 两种访问模式
    - 错误处理 ：提供属性访问错误处理机制



### 模块关系

```
python package: `sonic_platform` (Platform Implementation: `class ***()`) (can --call--> `sonic_py_common`)
    |
    |
    | 1. `sonic_platform` 继承自 `sonic_platform_pddf_base`, 并重命名所有类, 即使其类名不再包含`Pddf`关键字
    | 2. `sonic_platform_pddf_base` 会导入 `sonic_platform`  的具体实现类进行机器设备管理
    |
    ↓
python package: `sonic_platform_pddf_base` (Generic Base Class: `class Pddf***()`) (--call--> `sonic_py_common`)
    |
    |
    | 1. `sonic_platform_pddf_base` 继承自 `sonic_platform_base` 中的某个基类
    |
    ↓
python package: `sonic_platform_base` (位于sonic-platform-common) (--call--> `sonic_py_common`)
```


- **实际上`sonic_platform`必须直接或间接继承自`sonic_platform_base`!**


