# Machine Implementation


## Content

- packages/platforms/vendor/
  - vendor-config/          # 实现package：`onl-vendor-config-$VENDOR(:all)`，适用于所有不同架构的不同machine。
    - src/
      - python/
        - vendor/
          - __init__.py     # Vendor专属的python模块，主要是实现`OnlPlatformCelestica`
          - ...             # 其他自定义python模块
    - Makefile              # `include $(ONL)/make/pkg.mk`
    - PKG.yml               # `!include $ONL_TEMPLATES/platform-config-vendor.yml VENDOR=kvm Vendor=KVM`
  - x86-64/
    - modules/              # 实现package：`onl-vendor-${VENDOR}-modules(:$ARCH)`，适用于所有同一架构的不同machine。
      - Makefile            # `include $(ONL)/make/pkg.mk`
      - PKG.yml             # `!include $ONL_TEMPLATES/no-arch-vendor-modules.yml ARCH=amd64 VENDOR=kvm`
    - machinename1/         # onl的platform应和onie中的platform-name保持一致，但字符`_`和`.`应使用`-`代替。
      - modules/            # 实现package：`onl-platform-modules-$BASENAME(:$ARCH)`
        - builds/
          - src/            # or other name. 
            - Makefile      # `obj-m := fpga_xcvr.o fpga_device.o ...`
          - Makefile        # `KERNELS := onl-kernel-5.4-lts-x86-64-all:amd64; KMODULES := src; ...; include $(ONL)/make/kmodule.mk`
        - Makefile          # `include $(ONL)/make/pkg.mk`
        - PKG.yml           # `!include $ONL_TEMPLATES/platform-modules.yml ARCH=amd64 VENDOR=kvm BASENAME=x86-64-machinename1 KERNELS="onl-kernel-5.4-lts-x86-64-all:amd64"`
      - onlp/               # 实现package：`onlp-%(platform)s`
      - platform-config/    # 实现package：`onl-platform-config-%(platform)s`
        - r0/
          - src/
            - lib/
            - python/
            - Makefile        # `include $(ONL)/make/pkg.mk`
            - PKG.yml         # `!include $ONL_TEMPLATES/platform-config-platform.yml ARCH=amd64 VENDOR=kvm BASENAME=x86-64-machinename1 REVISION=r0`
          - Makefile        # `include $(ONL)/make/pkg.mk`
    - machinename2/
      - ...
  - arm/
    - ...




## Notice

- `ONL`的`platform`应和onie中的`platform-name`保持一致，但字符`_`和`.`应使用`-`代替。$PLATFORM=$BASENAME-$REVISION, 如BASENAME=x86-64-kvm-x86-64-r0, REVISION=r0, platform = `x86-64-kvm-x86-64-r0`, 同onie platform-name `x86_64-kvm_x86_64-r0`。
- `PKG.yml`末行留空？！
- 上述的目录结构不是死的，而是参照kvm/qemu例子实现，理论上只要放在`export ONLPM_OPTION_PACKAGEDIRS="$ONL/packages:$ONL/builds"`目录下都能被扫描到。




## Dependency

- `onl-rootfs`
  - `onlp-%(platform)s` (packages/platforms/$vendor/$arch/$machinename/onlp/) [onl-platform-pkgs.py $PLATFORM_LIST]
  - `onl-platform-config-%(platform)s`  (packages/platforms/$vendor/$arch/$machinename/platform-config/r0/) [onl-platform-pkgs.py $PLATFORM_LIST]
    - `onl-vendor-config-$VENDOR(:all)` (packages/platforms/$vendor/vendor-config/)
      - `onl-vendor-config-onl(:all)` (packages/base/all/vendor-config-onl/)
        - `onl-bootd(:all)` (packages/base/all/boot.d/)
    - `onl-platform-modules-$BASENAME(:$ARCH)` (packages/platforms/$vendor/$arch/$machinename/modules/)
      - `$KERNELS` (onl-kernel-5.4-lts-x86-64-all(:amd64))
      - `onl-vendor-${VENDOR}-modules(:$ARCH)`  (packages/platforms/$vendor/$arch/modules/)
        - `$KERNELS` (onl-kernel-5.4-lts-x86-64-all(:amd64))
  - `onl-upgrade`(amd64) (packages/base/amd64/upgrade/) [amd64-onl-packages.yml]
    - `onl-kernel-3.16-lts-x86-64-all:amd64` (packages/base/amd64/kernels/kernel-3.16-lts-x86-64-all/)
    - `onl-kernel-4.9-lts-x86-64-all:amd64` (packages/base/amd64/kernels/kernel-4.9-lts-x86-64-all/)
    - `onl-kernel-4.14-lts-x86-64-all:amd64` (packages/base/amd64/kernels/kernel-4.14-lts-x86-64-all/)
    - `onl-kernel-4.19-lts-x86-64-all:amd64` (packages/base/amd64/kernels/kernel-4.19-lts-x86-64-all/)
    - `onl-kernel-5.4-lts-x86-64-all:amd64` (packages/base/amd64/kernels/kernel-5.4-lts-x86-64-all/)
    - `onl-loader-initrd:amd64` (packages/base/amd64/initrds/loader/)
      - `onl-buildroot-initrd:$ARCH` (packages/base/any/initrds/buildroot/)
      - `onl-loader-initrd-files:all` (packages/base/all/initrds/loader-initrd-files/)
  - `onl-loader-fit`(arm64|armel|armhl|powerpc) (packages/base/$arch/fit/loader/) [$arch-onl-packages.yml]
    - `onl-loader-initrd:$ARCH` (packages/base/$arch/initrds/loader/)
      - `onl-buildroot-initrd:$ARCH` (packages/base/any/initrds/buildroot/)
      - `onl-loader-initrd-files:all` (packages/base/all/initrds/loader-initrd-files/)
  - `onlp` (packages/base/$arch/onlp) [all-base-packages.yml]
  - `onl-faultd` (packages/base/$arch/faultd) [all-base-packages.yml]
  - `onlp-snmpd` (packages/base/$arch/onlp-snmpd) [all-base-packages.yml]
  - `onl-mibs` (packages/base/all/onl-mibs) [all-base-packages.yml]
  - `oom-shim` (packages/base/$arch/oom-shim) [all-base-packages.yml]


**Notice**: 
- 非amd64，即`onl-loader-fit`时，没有依赖于内核，内核依赖将在`onl-platform-config-%(platform)s:all`包里的配置`lib/$platform.yml`以及`onl-vendor-config-onl:all`包里的配置`lib/platform-config-defaults-$(x86-64|uboot).yml`处的`kernel`字段完成指定。在**onl-loader-fit制作阶段**完成内核编译，Ref: `tools/flat-image-tree.py`。



## Implementation



### platform-config

```markdown
- packages/platforms/vendor/
  - x86-64/
    - machinename1/
      - platform-config/      # 实现package：`onl-platform-config-%(platform)s`
        - r0/
          - src/
            - lib/            # Mapping `src/lib: /lib/platform-config/$PLATFORM/onl/`
              - x86-64-machinename-r0.yml         # `$platform.yml`
            - python/         # Mapping `src/python : ${PY_INSTALL}/onl/platform/`
              - x86_64_machinename_r0\            # `$platform.replace('-','_').replace('.','_')`
                - __init__.py                     # `class OnlPlatform_$platform.replace('-','_').replace('.','_')`
            - Makefile        # `include $(ONL)/make/pkg.mk`
            - PKG.yml         # `!include $ONL_TEMPLATES/platform-config-platform.yml ARCH=amd64 VENDOR=kvm BASENAME=x86-64-machinename1 REVISION=r0`
          - Makefile          # `include $(ONL)/make/pkg.mk`
```

Notice: 目录`r0`只是为了便于区分硬件版本，实际还是根据`PKG.yml`所在目录作为编译或Package工作目录。同时这也是根据官方例子的设计规范。






#### src/PKG.yml

```yml
# !include $ONL_TEMPLATES/platform-config-platform.yml ARCH=amd64 VENDOR=kvm BASENAME=x86-64-machinename REVISION=r0  # Below

# PKG template for all platform-config packages.

variables:
  PLATFORM : $BASENAME-$REVISION

prerequisites:
  packages:
    - "onl-vendor-config-$VENDOR:all"
    - "onl-platform-modules-$BASENAME:$ARCH"

common:
  version: 1.0.0
  arch: $ARCH
  copyright: Copyright 2013, 2014, 2015 Big Switch Networks
  maintainer: support@bigswitch.com
  support: opennetworklinux@googlegroups.com
  changelog: None
  dists: $DISTS

packages:
  - name: onl-platform-config-$PLATFORM
    depends: onl-vendor-config-$VENDOR,onl-platform-modules-$BASENAME
    summary: ONL Platform Configuration Package for the $PLATFORM

    files:
      src/lib: /lib/platform-config/$PLATFORM/onl
      src/python : ${PY_INSTALL}/onl/platform/

  - name: onl-platform-build-$PLATFORM
    summary: ONL Platform Build Package for the $PLATFORM
    optional-files:
      builds: $$PKG_INSTALL

```



#### src/lib/$platform.yml

**用于覆盖以下配置**:

- `packages/base/all/vendor-config-onl/src/lib/platform-config-defaults-x86-64.yml`: x86-64
- `packages/base/all/vendor-config-onl/src/lib/platform-config-defaults-uboot.yml`: powerpc, arm


**加载方式**:

```python
# packages/base/all/vendor-config-onl/src/python/onl/platform/base.py
y2 = os.path.join(self.basedir_onl(), "%s.yml" % self.platform())
if os.path.exists(y1) and os.path.exists(y2):
    self.platform_config = onl.YamlUtils.merge(y1, y2)
    if self.platform() in self.platform_config:
        self.platform_config = self.platform_config[self.platform()]
elif os.path.exists(y2):
    with open(y2) as fd:
        self.platform_config = yaml.load(fd)
    if self.platform() in self.platform_config:
        self.platform_config = self.platform_config[self.platform()]
elif os.path.exists(y1):
    with open(y1) as fd:
        self.platform_config = yaml.load(fd)
    if 'default' in self.platform_config:
        self.platform_config = self.platform_config['default']
else:
    self.platform_config = {}
```


**覆盖方式**:

- 使用`$platform`或其他非`default`键作为顶级key覆写默认`default`的数据，只能有一个顶级key
- 遍历新配置(y2)的每个键值对：
  - 如果 y2 中的值是 nil（'~'），则从原始配置 y1 中删除对应的键。
  - 如果 y2 中的值是字典，而 y1 中对应的值不是字典，则将 y1 中的值提升为字典，并在字典里用key '=' 作为旧的不是字典的配置值作为key '='的值。
  - 否则，直接用 y2 中的值覆盖 y1 中的值。


**Example**:
```yml
x86-64-machinename-r0:

  grub:

    serial: >-
      --port=0x3f8
      --speed=115200
      --word=8
      --parity=no
      --stop=1

    kernel:
      <<: *kernel-4-14  # 将自动将 &kernel-4-14 中的内容覆盖在此行，如platform-config-defaults-x86-64.yml中的kernel-4.14: &kernel-4-14下的内容

    args: >-
      nopat
      console=ttyS0,115200n8

  installer:
  - ONL-BOOT:
      =: 128MiB
      format: ext4
  - ONL-CONFIG:
      =: 128MiB
      format: ext4
  - ONL-IMAGES:
      =: 1GiB
      format: ext4
  - ONL-DATA:
      =: 3GiB
      format: ext4

  ##network:
  ##  interfaces:
  ##    ma1:
  ##      name: ~
  ##      syspath: pci0000:00/0000:00:14.0
```



#### src/python/`$platform.replace('-','_').replace('.','_')/__init__.py`

**目的**:

- 用于实现平台及供应商等信息的配置
- 自定义平台开机启动脚本以配置平台所需

开机时通过`packages/base/all/vendor-config-onl/src/boot.d/51.onl-platform-baseconf`调用。在`rc S`之前执行。


**Example**:

```py
from onl.platform.base import * # packages/base/all/vendor-config-onl/src/python/onl/platform/base.py
from onl.platform.kvm import *  # vendor config


class OnlPlatform_x86_64_machinename_r0(
    OnlPlatformKVM, OnlPlatformPortConfig_32x400_2x10
):
    PLATFORM = "x86-64-machinename-r0"
    MODEL = "machinename"
    SYS_OBJECT_ID = ".2060.1"
    
    # Below Implementation by Super Object OnlPlatformPortConfig_32x400_2x10
    # PORT_COUNT = 34
    # PORT_CONFIG = "32x400G + 2x10"

    def baseconfig(self):
      """
      开机时自动执行的平台机器配置，如：
      1. 根据硬件配置（如是否存在BMC板）加载驱动
      2. 执行特定于该机器的自定义配置
      3. 启动监控服务
      4. ...
      """
      pass
```



### vendor-config

```markdown
- packages/platforms/vendor/
  - vendor-config/          # 实现package：`onl-vendor-config-$VENDOR(:all)`，适用于所有不同架构的不同machine。
    - src/
      - python/
        - vendor/
          - __init__.py     # Vendor专属的python模块，主要是实现`OnlPlatformCelestica`
          - ...             # 其他自定义python模块
    - Makefile              # `include $(ONL)/make/pkg.mk`
    - PKG.yml               # `!include $ONL_TEMPLATES/platform-config-vendor.yml VENDOR=kvm Vendor=KVM`
```

实际上是实现python模块`onl.platform.$vendor`，并在该python模块中通过继承`onl.platform.base`模块(packages/base/all/vendor-config-onl/src/python/onl/platform/base.py)中的`class OnlPlatformBase`类实现供应商专属平台配置类`class OnlPlatform$Vendor(OnlPlatformBase)`。主要是定义供应商的`MANUFACTURER`和`PRIVATE_ENTERPRISE_NUMBER`，使该供应商的机器都可以通过导入该模块`onl.platform.$vendor`并继承`OnlPlatform$Vendor`的方式实现机器专属平台机器配置类。

- `MANUFACTURER`: 主要是用于生成模块目录，如：
  - /lib/modules/<kernel>/onl/<vendor>/<platform-name>
  - /lib/modules/<kernel>/onl/<vendor>/<basename>, basename = "-".join(self.PLATFORM.split('-')[:-1])
  - /lib/modules/<kernel>/onl/<vendor>/common
  - /lib/modules/<kernel>/onl/onl/common
  - /lib/modules/<kernel>/onl
  - /lib/modules/<kernel>
- `PRIVATE_ENTERPRISE_NUMBER`: Vendor ID -- IANA Private Enterprise Number, http://www.iana.org/assignments/enterprise-numbers, 主要用于生成类__str__




#### PKG.yml

- platform-config-vendor.yml

```yml
# !include $ONL_TEMPLATES/platform-config-vendor.yml VENDOR=kvm Vendor=KVM

prerequisites:
  packages: [ "onl-vendor-config-onl:all" ]

packages:
  - name: onl-vendor-config-${VENDOR}
    depends: onl-vendor-config-onl
    version: 1.0.0
    arch: all
    copyright: Copyright 2013, 2014, 2015 Big Switch Networks
    maintainer: support@bigswitch.com
    support: opennetworklinux@googlegroups.com
    summary: ONL Configuration Package for ${Vendor} Platforms

    files:
      src/python/${VENDOR} : ${PY_INSTALL}/onl/platform/${VENDOR}

    changelog: Changes
```


#### __init__.py

- `onl.platform.base`: packages/base/all/vendor-config-onl/python/onl/platform/base.py

```py
#!/usr/bin/python

from onl.platform.base import *

class OnlPlatformKVM(OnlPlatformBase):
    MANUFACTURER='KVM'
    PRIVATE_ENTERPRISE_NUMBER=42623
    # Vendor ID -- IANA Private Enterprise Number:
    # http://www.iana.org/assignments/enterprise-numbers
```




### modules

```markdown
- modules/            # 实现package：`onl-platform-modules-$BASENAME(:$ARCH)`
  - builds/
    - src/            # or other name. 
      - Makefile      # `obj-m := fpga_xcvr.o fpga_device.o ...`
    - Makefile        # `KERNELS := onl-kernel-5.4-lts-x86-64-all:amd64; KMODULES := src; ...; include $(ONL)/make/kmodule.mk`
  - Makefile          # `include $(ONL)/make/pkg.mk`
  - PKG.yml           # `!include $ONL_TEMPLATES/platform-modules.yml ARCH=amd64 VENDOR=kvm BASENAME=x86-64-machinename1 KERNELS="onl-kernel-5.4-lts-x86-64-all:amd64"`
```


实际上是通过调用`$(ONL)/tools/scripts/kmodbuild.sh "$(KERNELS)" "$(KMODULES)" "$(SUBDIR)" "$(KINCLUDES)"`进行模块编译与安装。

- 参数解析：
  - `KERNELS`: 内核package，如`onl-kernel-5.4-lts-x86-64-all:amd64`，可提供多个内核，用空格隔开。
  - `KMODULES`: 模块文件或其所在目录, 如源码文件`fpga_xcvr.c`或目录`src`，可提供多个内核，用空格隔开。
  - `SUBDIR`: 模块安装的目录，不设置则安装在当前`builds`下的`onl/$(VENDOR)/$(BASENAME)/`目录, 即`packages/platforms/kvm/x86-64/$machinename/modules/builds/lib/modules/5.4.40-OpenNetworkLinux/onl/$(VENDOR)/$(BASENAME)/`。
  - `KINCLUDES`: `KMODULES`所需的头文件/附加文件，需`KMODULES`是**文件**而非目录，将自动拷贝头文件/附加文件到编译目录。
- 编译原理：
  - 同时组合遍历`$KERNELS`和`$KMODULES`，根据不同的内核和模块目录(文件)分别进行编译和安装：
    - 创建临时构建目录`$BUILD_DIR`：
      - 对模块目录：复制整个模块目录内容到临时目录，编译和安装
      - 对模块源文件：复制源文件（和可选的附加文件/头文件）到临时目录，创建Kbuild文件(`obj=${module_driver%.c}.o; echo "obj-m := $obj" >> $BUILD_DIR/Kbuild`)，指定要编译的对象，编译和安装
    - 通过命令`onlpm --find-dir $KERNEL mbuilds`查找内核package`$KERNEL`所在目录，若是`$KERNEL`是目录则无需查找。
    - 编译模块：`make -C $KERNEL M=$BUILD_DIR modules`。
    - 安装模块：`make -C $KERNEL M=$BUILD_DIR INSTALL_MOD_PATH=$(pwd) INSTALL_MOD_DIR="$SUBDIR" modules_install`，`INSTALL_MOD_PATH`是设置模块安装的基础路径为当前目录， `INSTALL_MOD_DIR`设置模块安装的子目录。




#### PKG.yml

- platform-modules.yml

```yml
# !include $ONL_TEMPLATES/platform-modules.yml ARCH=amd64 VENDOR=kvm BASENAME=x86-64-machinename KERNELS="onl-kernel-5.4-lts-x86-64-all:amd64"

prerequisites:
  packages:
    - $KERNELS
    - onl-vendor-${VENDOR}-modules:$ARCH

packages:
  - name: onl-platform-modules-${BASENAME}
    version: 1.0.0
    arch: $ARCH
    copyright: Copyright 2013, 2014, 2015 Big Switch Networks
    maintainer: support@bigswitch.com
    support: opennetworklinux@googlegroups.com
    summary: ONL Platform Modules Package for the ${BASENAME}
    depends: onl-vendor-${VENDOR}-modules       # Depend on vendor modules

    files:
      builds/lib: /lib              # copy -r builds/lib to /lib

    changelog: Changes
```

#### builds/Makefile

- builds/Makefile

```makefile
KERNELS := onl-kernel-5.4-lts-x86-64-all:amd64
KMODULES := src
VENDOR := kvm
BASENAME := x86-64-machinename
ARCH := x86_64
# include $(ONL)/make/kmodule.mk  # below !!!!!!!!!!

ifndef KERNELS
$(error $$KERNELS must be set)
endif

ifndef KMODULES
$(error $$KMODULES must be set)
endif

ifndef ARCH
$(error $$ARCH must be set)
endif

ifndef SUBDIR

ifndef VENDOR
$(error $$VENDOR must be set.)
endif

ifndef BASENAME
$(error $$BASENAME must be set.)
endif

SUBDIR := "onl/$(VENDOR)/$(BASENAME)"  # will use this as modules install dir, finally would be ↓

# `modules/builds/lib/modules/5.4.40-OpenNetworkLinux/onl/kvm/x86-64-machinename`

endif

modules:
	rm -rf lib
	ARCH=$(ARCH) $(ONL)/tools/scripts/kmodbuild.sh "$(KERNELS)" "$(KMODULES)" "$(SUBDIR)" "$(KINCLUDES)"
```







