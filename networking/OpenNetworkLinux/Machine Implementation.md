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
          - lib/
          - python/
          - Makefile        # `include $(ONL)/make/pkg.mk`
          - PKG.yml         # `!include $ONL_TEMPLATES/platform-config-platform.yml ARCH=amd64 VENDOR=kvm BASENAME=x86-64-machinename1 REVISION=r0`
    - machinename2/
      - ...
  - arm/
    - ...


## Details

### Notice

- `ONL`的`platform`应和onie中的`platform-name`保持一致，但字符`_`和`.`应使用`-`代替。$PLATFORM=$BASENAME-$REVISION, 如BASENAME=x86-64-kvm-x86-64-r0, REVISION=r0, platform = `x86-64-kvm-x86-64-r0`, 同onie platform-name `x86_64-kvm_x86_64-r0`。
- `PKG.yml`末行留空？！
- 上述的目录结构不是死的，而是参照kvm/qemu例子实现，理论上只要放在`export ONLPM_OPTION_PACKAGEDIRS="$ONL/packages:$ONL/builds"`目录下都能被扫描到。


### Dependency

- `onl-rootfs`
  - `onlp-%(platform)s` (packages/platforms/$vendor/$arch/$machinename/onlp/)
  - `onl-platform-config-%(platform)s`  (packages/platforms/$vendor/$arch/$machinename/platform-config/r0/)
    - `onl-vendor-config-$VENDOR(:all)` (packages/platforms/$vendor/vendor-config/)
    - `onl-platform-modules-$BASENAME(:$ARCH)` (packages/platforms/$vendor/$arch/$machinename/modules/)
      - `$KERNELS` (onl-kernel-5.4-lts-x86-64-all(:amd64))
      - `onl-vendor-${VENDOR}-modules(:$ARCH)`  (packages/platforms/$vendor/$arch/modules/)
        - `$KERNELS` (onl-kernel-5.4-lts-x86-64-all(:amd64))
 

### Implementation

#### modules

实际上是通过调用`$(ONL)/tools/scripts/kmodbuild.sh "$(KERNELS)" "$(KMODULES)" "$(SUBDIR)" "$(KINCLUDES)"`进行模块编译与安装。

- 参数解析：
  - `KERNELS`: 内核package, 如`onl-kernel-5.4-lts-x86-64-all:amd64`
  - `KMODULES`: 模块文件或其所在目录, 如源码文件`fpga_xcvr.c`或目录`src`
  - `SUBDIR`: 模块安装的目录，不设置则安装在当前`builds`下的`onl/$(VENDOR)/$(BASENAME)/`目录, 即`packages/platforms/kvm/x86-64/$machinename/modules/builds/lib/modules/5.4.40-OpenNetworkLinux/onl/$(VENDOR)/$(BASENAME)/`。
  - `KINCLUDES`: `KMODULES`所需的头文件，需`KMODULES`是**文件**而非目录，将自动拷贝头文件到编译目录。



##### Source

1. PKG.yml

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

2. builds/Makefile

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







