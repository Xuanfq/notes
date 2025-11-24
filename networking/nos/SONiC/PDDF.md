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

- 驱动安装: 安装`*.ko`到`/lib/modules/$(KVERSION)/extra/`

- Python工具和工具库: (`utils/`目录) 
  - 安装路径：`/usr/local/bin/`
  - Python脚本: (`utils/`)
    - `pddf_util.py`: 核心工具脚本，负责模块安装和清理
    - `pddfparse.py`: 配置解析工具
    - `pddf_s3ip.py`: S3IP接口实现
  - 配置模式文件: (`utils/schema`)
    - CPLD.schema 、 CPU.schema 、 EEPROM.schema
    - FAN.schema 、 FAN_BMC.schema
    - LED.schema
    - MUX.schema
    - PSU.schema 、 PSU-PMBUS.schema 、 PSU_BMC.schema
    - QSFP.schema 、 SMBUS.schema
    - SYSSTAT.schema
    - TEMP_SENSOR.schema 、 TEMP_SENSOR_BMC.schema

- 系统服务: (`service/`目录)
  - `pddf-platform-init.service`
    - 功能: PDDF模块和设备初始化服务
    - 需求: 在`pmon.service`之前启动, `ExecStartPre=-/usr/local/bin/pre_pddf_init.sh`
    - 开始时运行 `/usr/local/bin/pddf_util.py install` 进行初始化
    - 停止时运行 `/usr/local/bin/pddf_util.py clean` 进行清理
  - `pddf-s3ip-init.service`
    - S3IP接口初始化服务














