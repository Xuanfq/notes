# PDDF

PDDF, Platform Driver Development Framework.

- platform/pddf/
  - platform-api-pddf-base/sonic_platform_pddf_base/  # python package
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

- 支持 API 1.0 (插件文件管理) 和 2.0 (Python wheel 包管理) 
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


