# Machine Implementation

## Reference

### Noun

- `@*-L@`: 小写, lowercase
- `@*-U@`: 大写, uppercase
- `@VENDOR-FULL-L@`: 供应商全称，小写，如 dell
- `@VENDOR-FULL-U@`: 供应商全称，大写，如 DELL
- `@PLATFORM-FULL-L@`: 平台全称，小写，如 x86_64-dellemc_s52xx-r0
- `@SWITCH-CHIP-VENDOR-FULL-L@`: Switch Chip 供应商全称，小写，如 broadcom
- `@MACHINE-NAME-FULL-L@`: 机器/sku名称全称，不带供应商，小写，如 x86_64-dellemc_s52xx-r0 实际为机器或sku名为s52xx的机器


## Content


- device/`@VENDOR-FULL-L@`/   # 将在src/sonic-device-data/处被编译成 `sonic-device-data_${version:-1.0-1}_all.deb` 
  - `@PLATFORM-FULL-L@`/      # platform, e.g. x86_64-dellemc_s52xx-r0
    - 
- platform/`@SWITCH-CHIP-VENDOR-FULL-L@`/
  - sonic-platform-modules-`@VENDOR-FULL-L@`/
    - debian/     # 参照[Debian软件包打包完全指南](./Reference/Debian软件包打包完全指南.md)
      - changelog # 更新日志
      - compat    # debhelper 的兼容级别
      - control   # 包的元数据，版本、架构等
      - rules     # 编译规则，实际`@MACHINE-NAME-FULL-L@`/下的文件内容和结构，都需要与此进行配合!
      - platform-modules-`@MACHINE-NAME-FULL-L@`.init       # 支持 deb service start|stop|restart 的等脚本，在此处进行platform依赖以及模块安装
      - platform-modules-`@MACHINE-NAME-FULL-L@`.install    # 需要安装的文件(与debian同级目录作为base路径) 与 所要安装到的实际文件系统目录 的映射
      - platform-modules-`@MACHINE-NAME-FULL-L@`.postinst   # 包安装后执行，如启动服务、生成配置文件等    
    - `@MACHINE-NAME-FULL-L@`/
      - modules/            # 驱动，可依赖和拓展 `PDDF` 模块: platform/pddf/i2c/modules/include/*.h
        - */
        - *.c
        - *.h
        - Makefile
      - pddf/               # Option
        - sonic_platform/   # PDDF API 的实现，详细参阅 [PDDF笔记](./PDDF.md)
          - *.py
        - setup.py
      - */                  # 自定义需要安装的目录，通过 platform-modules-`@MACHINE-NAME-FULL-L@`.install 配置安装目录
      - *.*                 # 自定义需要安装的文件，通过 platform-modules-`@MACHINE-NAME-FULL-L@`.install 配置安装目录
    - .gitignore
    - LICENSE
    - README.md
  - platform-modules-`@VENDOR-FULL-L@`.dep        # 定义sonic-platform-modules-`@VENDOR-FULL-L@`的依赖
  - platform-modules-`@VENDOR-FULL-L@`.mk         # 定义Vendor及其子Debian包的编译
  - rules.dep   # include platform-modules-`@VENDOR-FULL-L@`.dep
  - rules.mk    # include platform-modules-`@VENDOR-FULL-L@`.mk





## 安装包结构

### sonic-device-data_`1.0-1`_all.deb

- usr/share/
  - doc/sonic-device-data/
    - changelog.Debian.gz
    - copyright
  - sonic/device/
    - pddf/plugins/           # from `device/common/`
      - eeprom.py
      - fanutil.py
      - ledutil.py
      - psuutil.py
      - sfputil.py
      - sysstatutil.py
      - thermalutil.py
    - profiles/               # from `device/common/`
      - td2/
      - th/
      - th2/
      - th4/
      - th5/
    - *`@PLATFORM-FULL-L@`*/  # all platfrom from `device/*/*`
      - *




### platform-modules-`@MACHINE-NAME-FULL-L@`_`1.0`_amd64.deb

- platform-modules-`@MACHINE-NAME-FULL-L@`/      # 不同sku会创建不同的子package目录并存放需要安装的文件，通过 platform-modules-`@MACHINE-NAME-FULL-L@`.install 指定需要安装的文件和对应目录
  - **lib/modules/`$(shell uname -r)`/extra/**   # rules编译时在执行安装时创建: `dh_installdirs -pplatform-modules-$${mod} $(KERNEL_SRC)/$INSTALL_MOD_DIR);`
    - *.ko
  - lib/systemd/system/     # 存放相关服务
    - *.service
  - etc/init.d/             # 存放用于*.service调用的脚本
    - *.sh                 
  - etc/modules-load.d/     # 目录下的*.conf根据名称的字典顺序自动被systemd-modules-load.service获取并自动根据配置加载定义的所需的模块
    - *.conf                # 配置所需的模块列表，一行一个模块
  - etc/udev/rules.d/       # 管理设备节点
    - *.conf
  - usr/local/bin/          # 扩展的bin可执行文件
  - **usr/share/sonic/device/`@PLATFORM-FULL-L@`/**     # 设备文件
    - sonic_platform-1.0-py3-none-any.whl     # pddf api 的实现与python模块适配 sonic_platform






## Details

### platform-modules-`@VENDOR-FULL-L@`.mk

- vendor (first sku)
  - `*.deb`主变量: `@VENDOR-FULL-L@`_`first-@MACHINE-NAME-FULL-L@`_PLATFORM_MODULE = platform-modules-`@MACHINE-NAME-FULL-L@`_`$(XXX_@MACHINE-NAME-FULL-L@_PLATFORM_MODULE_VERSION)`_`$(arch:-amd64)`.deb
  - `*.deb`主源码: $(`@VENDOR-FULL-L@`_`first-@MACHINE-NAME-FULL-L@`_PLATFORM_MODULE)_SRC_PATH
  - `*.deb`主依赖: $(`@VENDOR-FULL-L@`_`first-@MACHINE-NAME-FULL-L@`_PLATFORM_MODULE)_DEPENDS
  - `*.deb`主平台: $(`@VENDOR-FULL-L@`_`first-@MACHINE-NAME-FULL-L@`_PLATFORM_MODULE)_PLATFORM (第一个sku)
  - 添加到构建需求: **SONIC_DPKG_DEBS** += $(`@VENDOR-FULL-L@`_`first-@MACHINE-NAME-FULL-L@`_PLATFORM_MODULE)
- vendor-sku (other sku)
  1. 定义上述处`_DEPENDS`以及`_SRC_PATH`外的相关参数值
  2. 把deb添加到Vendor主变量: `$(eval $(call add_extra_package,$(XXX_MAIN_PLATFORM_MODULE),$(XXX_YYYYY_PLATFORM_MODULE)))`






























