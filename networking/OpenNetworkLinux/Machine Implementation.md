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
        - builds/
          - lib/
            - Makefile
            - x86_64_machinename1.mk
          - onlpdump/
            - Makefile
          - x86_64_machinename1/
            - auto/
              - make.mk
              - x86_64_machinename1.yml
            - inc/
              - x86_64_machinename1/
                - *
            - src/
              - make.mk
              - Makefile
              - *
          - Makefile        
        - Makefile
        - PKG.yml
      - platform-config/    # 实现package：`onl-platform-config-%(platform)s`
        - r0/
          - src/
            - lib/            # Mapping `src/lib: /lib/platform-config/$PLATFORM/onl/`
              - x86-64-machinename-r0.yml         # `$platform.yml`
            - python/         # Mapping `src/python : ${PY_INSTALL}/onl/platform/`
              - x86_64_machinename_r0\            # `$platform.replace('-','_').replace('.','_')`
                - __init__.py                     # `class OnlPlatform_$platform.replace('-','_').replace('.','_')`
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
  - `onlp-%(platform)s` (packages/platforms/$vendor/$arch/$machinename/onlp/) [standard.yml][onl-platform-pkgs.py $PLATFORM_LIST]
  - `onl-platform-config-%(platform)s`  (packages/platforms/$vendor/$arch/$machinename/platform-config/r0/) [standard.yml][onl-platform-pkgs.py $PLATFORM_LIST]
    - `onl-vendor-config-$VENDOR(:all)` (packages/platforms/$vendor/vendor-config/)
      - `onl-vendor-config-onl(:all)` (packages/base/all/vendor-config-onl/)
        - `onl-bootd(:all)` (packages/base/all/boot.d/)
    - `onl-platform-modules-$BASENAME(:$ARCH)` (packages/platforms/$vendor/$arch/$machinename/modules/)
      - `$KERNELS` (onl-kernel-5.4-lts-x86-64-all(:amd64))
      - `onl-vendor-${VENDOR}-modules(:$ARCH)`  (packages/platforms/$vendor/$arch/modules/)
        - `$KERNELS` (onl-kernel-5.4-lts-x86-64-all(:amd64))
  - `onl-upgrade`(amd64) (packages/base/amd64/upgrade/) [standard.yml][amd64-onl-packages.yml]
    - `onl-kernel-3.16-lts-x86-64-all:amd64` (packages/base/amd64/kernels/kernel-3.16-lts-x86-64-all/)
    - `onl-kernel-4.9-lts-x86-64-all:amd64` (packages/base/amd64/kernels/kernel-4.9-lts-x86-64-all/)
    - `onl-kernel-4.14-lts-x86-64-all:amd64` (packages/base/amd64/kernels/kernel-4.14-lts-x86-64-all/)
    - `onl-kernel-4.19-lts-x86-64-all:amd64` (packages/base/amd64/kernels/kernel-4.19-lts-x86-64-all/)
    - `onl-kernel-5.4-lts-x86-64-all:amd64` (packages/base/amd64/kernels/kernel-5.4-lts-x86-64-all/)
    - `onl-loader-initrd:amd64` (packages/base/amd64/initrds/loader/)
      - `onl-buildroot-initrd:$ARCH` (packages/base/any/initrds/buildroot/)
      - `onl-loader-initrd-files:all` (packages/base/all/initrds/loader-initrd-files/)
      - `onl-platform-config-%(platform)s` (packages/platforms/$vendor/$arch/$machinename/platform-config/r0/)
      - `onl-vendor-config-$VENDOR:all` (packages/platforms/$vendor/vendor-config/)
      - `onl-vendor-config-onl(:all)` (packages/base/all/vendor-config-onl/)
  - `onl-loader-fit`(arm64|armel|armhl|powerpc) (packages/base/$arch/fit/loader/) [standard.yml][$arch-onl-packages.yml]
    - `onl-loader-initrd:$ARCH` (packages/base/$arch/initrds/loader/)
      - `onl-buildroot-initrd:$ARCH` (packages/base/any/initrds/buildroot/)
      - `onl-loader-initrd-files:all` (packages/base/all/initrds/loader-initrd-files/)
  - `onlp` (packages/base/$arch/onlp) [standard.yml][all-base-packages.yml]
  - `onl-faultd` (packages/base/$arch/faultd) [standard.yml][all-base-packages.yml]
  - `onlp-snmpd` (packages/base/$arch/onlp-snmpd) [standard.yml][all-base-packages.yml]
  - `onl-mibs` (packages/base/all/onl-mibs) [standard.yml][all-base-packages.yml]
  - `oom-shim` (packages/base/$arch/oom-shim) [standard.yml][all-base-packages.yml]


**Notice**: 
- 非amd64，即`onl-loader-fit`时，没有依赖于内核，内核依赖将在`onl-platform-config-%(platform)s:all`包里的配置`lib/$platform.yml`以及`onl-vendor-config-onl:all`包里的配置`lib/platform-config-defaults-$(x86-64|uboot).yml`处的`kernel`字段完成指定。在**onl-loader-fit制作阶段**完成内核编译，Ref: `tools/flat-image-tree.py`。
- 非直属的由[standard.yml]引用的Package不会被安装到rootfs上。若platform需要安装一些其他的自定义的Package的文件，可通过以下方法:
  - 通过`onl-platform-config-%(platform)s`的文件映射描述里添加，直接拷贝相关文件到rootfs。
  - 通过`PKG.yml`里的`packages.depends`设置依赖包，安装时会自动安装这些依赖包，可以是网络的，也可以是本地。本地最好通过`prerequisites.packages`引用进行预先编译。



## Implementation


### misc

#### install plugins of platform customization


**插件实现原理**: `${PY_INSTALL}/onl/install/plugins/*.py`

- 核心是把该插件通过ONL Package的规则安装到文件系统initrd的`${PY_INSTALL}/onl/install/plugins/*.py`
- 具体安装逻辑参照: [Logic of onl images](./Logic%20of%20onl%20images.md), 位于"**可以通过此处为平台添加插件**"附近。


**插件内容参考**: `builds/any/installer/sample-(postinstall|preinstall).py`

```py
import onl.install.Plugin

class Plugin(onl.install.Plugin.Plugin):
    def run(self, mode):
        if mode == self.PLUGIN_POSTINSTALL:
            self.log.info("hello from postinstall plugin")
            if self.installer.im.installerConf.installer_platform == 'x86-64-machinename-r0':
              # add your need here!
              pass
            return 0
        elif mode == self.PLUGIN_PREINSTALL:
            self.log.info("hello from preinstall plugin")
            if self.installer.im.installerConf.installer_platform == 'x86-64-machinename-r0':
              # add your need here!
              pass
            return 0
        return 0
```


**插件接口参考**: `packages/base/all/vendor-config-onl/src/python/onl/install/Plugin.py`

```py
class Plugin(object):

    PLUGIN_PREINSTALL = "preinstall"
    PLUGIN_POSTINSTALL = "postinstall"

    def __init__(self, installer):
        # installer is GrubInstaller or UbootInstaller
        # refer to packages/base/all/vendor-config-onl/src/python/onl/install/BaseInstall.py
        self.installer = installer
        self.log = self.installer.log.getChild("plugin")

    def run(self, mode):

        if hasattr(self, mode):
            return getattr(self, mode)()

        if mode == self.PLUGIN_PREINSTALL:
            self.log.warn("pre-install plugin not implemented")
            return 0

        if mode == self.PLUGIN_POSTINSTALL:
            self.log.warn("post-install plugin not implemented")
            return 0

        self.log.warn("invalid plugin mode %s", repr(mode))
        return 1

    def shutdown(self):
        pass
```



**Notice**: 若是平台特定的，应在实现过程中匹配到对应平台再执行。



#### kernel of platform customization


Reference Below: `src/lib/$platform.yml`



#### loader initrd of platform customization


**initrd实现原理**: `packages/base/all/vendor-config-onl/src/etc/onl/sysconfig/00-defaults.yml`中的installer.grub.`$PLATFORM.cpio.gz|.itb`, $PLATFORM=onlPlatform().platform(), e.g. x86-64-machinename-r0

- 该处自定义的平台特定initrd有别于`onl-loader-initrd-files:all`中的initrd，即有别于安装环境的initrd(使用chroot)。安装环境的initrd不能更改，这可能会导致很大区别，这个要特别注意！
- `00-defaults.yml`(initrd上是`/etc/onl/sysconfig/*.yml`)能通过`/mnt/onl/config/sysconfig/*.yml`进行覆盖，该文件没有实现，可以自定义！
- 具体安装逻辑参照: [Logic of onl images](./Logic%20of%20onl%20images.md), 位于"**可以通过此处为平台定制化initrd**"附近。



#### sysconfig of platform customization

packages/base/all/vendor-config-onl/src/python/onl/sysconfig/__init__.py

**配置来源于**:

- /                               # 按以下顺序依次加载
  - /etc/onl/sysconfig/           # 按字典次序依次加载
    - 00-defaults.yml             # 无论是loader还是真实的rootfs都存在，来源: onl-vendor-config-onl:all: packages/base/all/vendor-config-onl/src/etc/onl/sysconfig/00-defaults.yml
    - *.yml                       # 空
  - /mnt/onl/config/sysconfig/    # 按字典次序依次加载
    - *.yml                       # 空


**配置加载时机**:

- 一旦该模块被导入时，则以读取配置且不会再次查找文件和读取配置!
- 调用`onl-install --force`进行安装时已完成配置加载和固定!


**实现方法**:

- **ONL安装阶段**: 使用上述python安装插件`${PY_INSTALL}/onl/install/plugins/*.py`:
  - 通过pre插件**判断平台**后在相关目录下创建配置覆盖默认`00-defaults.yml`配置，此处只放`/etc/onl/sysconfig/`
  - 通过pre插件**判断平台**后重新导入python`onl.sysconfig`模块: `import importlib; importlib.reload(onl.sysconfig)`
  - 通过post插件**判断平台**后在相关目录下创建配置覆盖默认`00-defaults.yml`配置，此处建议放在`/mnt/onl/config/sysconfig/`，其他阶段就不用操作了。但是若要改成随时切换平台则建议每个阶段分别动态加载，由于真实rootfs阶段下是永久保存的，并不适合动态增删该文件。

- ONL-Loader阶段: 使用下方`boot interface during initrd-loader for platform customization`接口实现`/lib/platform-config/${platform}/onl/boot/${platform}`
  - 通过接口在相关目录下创建配置覆盖默认`00-defaults.yml`配置，此处只放`/mnt/onl/config/sysconfig/`

- -ONL-RealFS 真实`swi rootfs/initrd`阶段: 这个阶段若通过平台`baseconfig`接口加载会有一段空白期！可通过Package填充到`boot.d/00.xxx`使其拥有更高执行优先权。在该boot脚本中对配置进行增删操作！




#### self detect platform correct or not of platform customization [Failover]

**目的**: GRUB启动参数中`onl_platform`丢失的故障情况下，实现平台自我检测是否匹配。


**实现原理**: 在平台自己的配置`platform-config`下，即在目录(`/lib/platform-config/$platform/`)创建以下一个或多个可执行脚本文件，文件中写入检测平台的脚本，可以检测自己本身平台，也可以通用地检测所有的平台，检测成功后将其平台名输出到文件`/etc/onl/platform`，建议规范为优雅地检测自己本身即可:

- `detect0.sh`: 优先级为最高
- `detect.sh`: 正常优先级
- `detect1.sh`: 最低优先级


**可行的实现存放位置**:

- packages/platforms/vendor/
  - x86-64/
    - machinename1/
      - platform-config/      # 实现package：`onl-platform-config-%(platform)s`
        - r0/
          - src/
            - lib/            # Mapping `src/lib: /lib/platform-config/$PLATFORM/onl/`
              - x86-64-machinename-r0.yml         # `$platform.yml`
              - detect.sh                         # <- 



#### boot interface during initrd-loader phase for platform customization

**目的**: ONL引导正确的platform和rootfs阶段下，平台检测成功后，提供了平台自定义配置和初始化的接口，此处提供该接口的实现原理和方法。


**接口说明与实现原理**: 

- 平台检测成功后的平台客制化接口(磁盘分区未挂载，网络未初始化): `. /lib/platform-config/${platform}/onl/boot/${platform}`
  - 实现方法: 在平台自己的配置`platform-config`下，即在目录(`/lib/platform-config/$platform/`)创建可执行脚本文件`boot/${platform}`，即可实现脚本`/lib/platform-config/${platform}/onl/boot/${platform}`

- 初始化接口(磁盘分区已挂载，网络未初始化): `for s in $(ls /etc/sysinit.d/* | sort); do [ -x "$s" ] && "$s" done`
  - 实现方法: 由于`/etc/sysinit.d/`下的文件为空且其相关代码处于`onl-loader-initrd-files:all`，虽然可以通过platform-config的`PKG.yml`进行映射文件，但这并不优雅，且会导致真实的SWI的rootfs也会存在该文件且该文件对其无用。建议通过`/lib/platform-config/${platform}/onl/boot/${platform}`脚本的方式生成这些文件。


**存放位置**:

- packages/platforms/vendor/
  - x86-64/
    - machinename1/
      - platform-config/      # 实现package：`onl-platform-config-%(platform)s`
        - r0/
          - src/
            - lib/            # Mapping `src/lib: /lib/platform-config/$PLATFORM/onl/`
              - x86-64-machinename-r0.yml         # `$platform.yml`
              - boot/
                - x86-64-machinename-r0           # <- 



#### onie updater of platform customization in ONL

packages/base/all/vendor-config-onl/src/boot.d/60.upgrade-onie


**`onie-updater`存放目录**: `sysconfig.upgrade.onie.package.dir`, 即`/lib/platform-config/$current/onl/upgrade/onie/`, 参考路径存放位置`packages/base/all/vendor-config-onl/src/etc/onl/sysconfig/00-defaults.yml`

- /lib/platform-config/$current/onl/upgrade/onie/
  - manifest.json       # 配置文件及清单
  - `*`                 # `onie-updater文件名`，也可以是多个在清单上指定，将存放到ONL-IMAGES来自动发现，需注意命名。建议单项且文件名必须是onie-updater，这样升级后重启进入onl时自动删除！


**manifest.json**:
```json
{
  "next_version": "2021.11.1.0.0",  # 需要安装的onie版本, 以此为比对确定是否需要升级
  "updater": "onie-updater"         # onie-updater文件名，也可以是列表，将存放到ONL-IMAGES来自动发现，需注意命名。建议单项且文件名必须是onie-updater，这样升级后重启进入onl时自动删除！

}
```


**实现方式**:

1. 在平台的`platform-config/r0/src/lib/`下创建相关目录和文件`upgrade/onie/`，`PKG.yml`中`src/lib: /lib/platform-config/$PLATFORM/onl`将自动映射到目录`onl/upgrade/onie/`: 

- platform-config/r0/src/lib/upgrade/onie/
  - manifest.json
  - `*`             # onie-updater

2. 也可通过`自定义Package`，然后通过`platform-config`的`PKG.yml`来关联产生依赖。


**升级步骤**:

1. 拷贝到`/mnt/onl/images`, 即`ONL-IMAGES`分区。
2. 通过onie-boot中的`onie/tools/bin/onie-boot-mode -o `修改`默认onie模式`为`update`模式
3. 设置默认第二启动项为`onl`(从0开始索引): `/usr/sbin/grub-set-default --boot-directory=/mnt/onl/boot/  1`
4. 自动重启
5. 进入onie的update模式，自动发现更新



#### onie firmware updater of platform customization in ONL

packages/base/all/vendor-config-onl/src/boot.d/61.upgrade-firmware


**`onie-firmware-updater`存放目录**: `sysconfig.upgrade.onie.package.dir`, 即`/lib/platform-config/$current/onl/upgrade/firmware/`, 参考路径存放位置`packages/base/all/vendor-config-onl/src/etc/onl/sysconfig/00-defaults.yml`

- /lib/platform-config/$current/onl/upgrade/firmware/
  - manifest.json       # 配置文件及清单
  - `*`                 # `onie-updater文件名`，也可以多个并在清单上指定，`fwpkg`为False时将存放到ONL-IMAGES来自动发现，需注意命名。建议单项且文件名必须是onie-updater，这样升级后重启进入onl时自动删除！


**manifest.json**:
```json
{
  "next_version": "2021.11.1.0.0",  # 需要安装的onie版本, 以此为比对确定是否需要升级
  "updater": "onie-updater",        # onie-updater文件名，也可以是列表，`fwpkg`为False时将存放到ONL-IMAGES来自动发现，需注意命名。建议单项且文件名必须是onie-updater，这样升级后重启进入onl时自动删除！
  "fwpkg": true                     # 是否使用`onie-fwpkg`来添加，若使用则不用存放到ONL-IMAGES，建议使用。
}
```


**实现方式**:

1. 在平台的`platform-config/r0/src/lib/`下创建相关目录和文件`upgrade/onl/`，`PKG.yml`中`src/lib: /lib/platform-config/$PLATFORM/onl`将自动映射到目录`onl/upgrade/firmware/`: 

- platform-config/r0/src/lib/upgrade/firmware/
  - manifest.json
  - `*`             # onie-updater

2. 也可通过`自定义Package`，然后通过`platform-config`的`PKG.yml`来关联产生依赖。


**升级步骤**:

1. 通过`onie-fwpgk`添加到onie的`pending`目录或拷贝到`/mnt/onl/images`, 即`ONL-IMAGES`分区。
2. 通过`onie-boot`中的`onie/tools/bin/onie-boot-mode -o `修改`默认onie模式`为`update`模式
3. 设置默认第二启动项为`onl`(从0开始索引): `/usr/sbin/grub-set-default --boot-directory=/mnt/onl/boot/  1`
4. 自动重启
5. 进入onie的update模式，自动发现更新



#### loader upgrade of platform customization

packages/base/all/vendor-config-onl/src/boot.d/15.upgrade-loader

**`loader`存放目录**: `sysconfig.loader.package.dir`, 即`/etc/onl/upgrade/$arch/`, 参考路径存放位置`packages/base/all/vendor-config-onl/src/etc/onl/sysconfig/00-defaults.yml`


**实现方法**:

- 手动拷贝新的loader相关文件到`/etc/onl/upgrade/$arch/`目录，手动重启(然后触发升级后自动再重新启动一次)，或手动执行`onl-upgrade-onie`后自动重启
  - onl-loader-initrd-$arch.cpio.gz
  - manifest.json
  - kernel-*
- 使用下方`boot interface during initrd-loader for platform customization`接口`/lib/platform-config/${platform}/onl/boot/${platform}`实现实现新的initrd-loader文件拷贝，但此处无法输出到控制台，然后手动重启，或在平台`baseconfig`处检测重启


**升级步骤**:

1. 当前版本`/etc/onl/loader/versions.json` (from loader-initrd)
2. 最新版本`/etc/onl/upgrade/$arch/manifest.json` (from real-rootfs)
3. 若版本不一样，将`/etc/onl/upgrade/$arch/`目录下的`kernel-*`及`$PLATFORM.cpio.gz|onl-loader-initrd-$PARCH.cpio.gz`拷贝到`ONL-BOOT`，然后更新grub，升级后自动重启生效。




#### system upgrade of platform customization

packages/base/all/vendor-config-onl/src/boot.d/10.upgrade-system

- 版本升级触发条件, 以下版本不等时:
  - 当前loader的兼容版本(`SYSTEM_COMPATIBILITY_VERSION` of `/etc/onl/loader/versions.json`) (from loader-initrd)
  - upgrade的loader中的兼容版本(`SYSTEM_COMPATIBILITY_VERSION` of `/etc/onl/upgrade/$PLATFORM_ARCH/manifest.json`) (from real-rootfs)
- 实现方法: 
  1. 文件准备，存放新版本相关的文件到系统目录`/etc/onl/upgrade/$PLATFORM_ARCH/`:
    - onl-loader-initrd-$arch.cpio.gz
    - manifest.json
    - kernel-*
  2. 手动重启两次，或手动执行`onl-upgrade-system`后手动重启
  3. 使用下方`boot interface during initrd-loader for platform customization`接口`/lib/platform-config/${platform}/onl/boot/${platform}`实现实现新的initrd-loader文件拷贝，但此处无法输出到控制台，然后手动重启，或在平台`baseconfig`处检测重启
- **升级命令实际上跟`onie`下安装类似！因为执行安装更新时会清除磁盘，缺失文件如`*.swi`！这个需要实践验证一下！** 可以通过优化此处升级逻辑，拷贝所有upgrade目录下的文件作为installer_dir的内容去查找，这样只要将相关文件放到该目录即可升级。



#### swi upgrade of platform customization

packages/base/all/vendor-config-onl/src/boot.d/64.upgrade-swi

- 该项功能默认是禁用的，且启用后功能也不完善，无法适配与升级！
- 升级逻辑: packages/base/all/vendor-config-onl/src/boot.d/64.upgrade-swi
- 实现方向: 
  - 由于已经切换到真实的initrd环境，且已运行一部分启动脚本，若需重新运行，必然需要重启。
  - 由于原始设计`64.upgrade-swi`并不完善可用，因此若是*特定平台*需要实现，可在`baseconfig`时覆盖`64.upgrade-swi`？
  - `loader`根据`/mnt/onl/data/etc/onl/SWI`文件*是否存在或非空*来判断是否是*安装后首次启动*，首次启动需要解压真实的`*swi`中的`rootfs-$arch.sqsh`到`ONL-DATA`分区，并且解压前删除`ONL-DATA`中的数据。
    - 因此可以先替换`ONL-IMAGES`分区中的`*.swi`，然后删除`/etc/onl/SWI`即`/mnt/onl/data/etc/onl/SWI`然后重启来重新解压! 
    - 由于解压前会删除数据，因此需要考虑如何保留数据，此处为难点! 若为首次启动时，数据也无关紧要，平台一开始第一版就适配的话，似乎也可以？这样做的目的是？使用自定义的`rootfs`根文件系统吗？
  - 若直接解压根文件系统来覆盖，似乎有可能会导致不可预测的fail？



#### rc.boot of ONL-* Partition

**SWI真正的initrd启动过程中，即`si0::sysinit:/etc/boot.d/boot`，若ONL相关分区中(按顺序: `boot config images data`)存在可执行的`rc.boot`，逐项执行**: `packages/base/all/boot.d/src/52.rc.boot`

- 可通过插件`${PY_INSTALL}/onl/install/plugins/*.py`来产生这些文件。



#### install-debs of ONL-DATA Partition

**SWI真正的initrd启动过程中，即`si0::sysinit:/etc/boot.d/boot`，若`/mnt/onl/data/install-debs`下存在`list`以及list中每行存在的`deb`包，逐行安装**: `packages/base/all/boot.d/src/53.install-debs`

```md
- /
  - install-debs/
    - list    (each line: xx.deb)
    - *.deb
```

- 可通过插件`src/python/$platform.replace('-','_').replace('.','_')/__init__.py`来产生这些文件。
- 也可通过手动建立文件，每次重启就能自动安装。



### onlp

```markdown
- packages/platforms/vendor/
  - x86-64/
    - machinename1/         # onl的platform应和onie中的platform-name保持一致，但字符`_`和`.`应使用`-`代替。ARCH=amd64 VENDOR=kvm BASENAME=x86-64-machinename1 KERNELS="onl-kernel-5.4-lts-x86-64-all:amd64"`
      - onlp/               # 实现package：`onlp-%(platform)s`
        - builds/
          - lib/
            - Makefile
            - x86_64_machinename1.mk
          - onlpdump/
            - Makefile
          - x86_64_machinename1/
            - auto/
              - make.mk
              - x86_64_machinename1.yml
            - inc/
              - x86_64_machinename1/
                - *
            - src/
              - make.mk
              - Makefile
              - *
          - Makefile        
        - Makefile
        - PKG.yml
```

**实现**:

- 参考代码: 
  - 完整项目: packages/platforms/kvm/x86-64/x86-64-kvm-x86-64/onlp/builds
  - onlp: packages/base/any/onlp/src/onlp_platform_defaults
  - onlp: packages/base/any/onlp/src/onlpie
  - onlp: packages/base/any/onlp/src/onlplib

- 主要实现:
  - 在`x86_64_machinename1/`下实现平台接口`packages/base/any/onlp/src/onlp/module/inc/onlp/platformi/`:
    - fani.h
    - ledi.h
    - psui.h
    - sfpi.h
    - sysi.h
    - thermali.h

- 代码生成:
  - 原理参考:
    - sm/infra/builder/unix/auto.mk
    - sm/infra/sourcegen/sg.py
  - 注意需要生成代码时的起始和结束标志，如: 
    - `<auto.start.cdefs(ONLPSIM_CONFIG_HEADER).header>`
    - `<auto.end.cdefs(ONLPSIM_CONFIG_HEADER).header>`
    - `r'(.*)<auto.start.(?P<expr>.*)>'`
    - `r'(.*)<auto.end.(?P<expr>.*)>'`




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


**用于自定义内核版本**:

1. 修改配置中的`kernel`，根据以下的配置作为参考(platform-config-defaults-x86-64.yml):
```yml
    kernel:
      =: kernel-6.4-lts-x86_64-all
      package: onl-kernel-6.4-lts-x86-64-all:amd64
```
2. 在机器目录下参考onl的kernel实现方式，自定义内核deb包及其编译方式: `onl-kernel-6.4-lts-x86-64-all:amd64`


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
  # 'GiB' : 1024 * 1024 * 1024,
  # 'G' : 1000 * 1000 * 1000,
  # 'MiB' : 1024 * 1024,
  # 'M' : 1000 * 1000,
  # 'KiB' : 1024,
  # 'K' : 1000,
  # 也可以用100%，代表剩下的所有空间

  ##network:
  ##  interfaces:
  ##    ma1:
  ##      name: ~
  ##      syspath: pci0000:00/0000:00:14.0
```


**platform-config-defaults-x86-64.yml**:
```yml
default:

  grub:

    label: gpt
    # default, use a GPT (not msdos) label
    # this is mostly to *reject* invalid disk labels,
    # since we will never create our own

    kernel-3.2: &kernel-3-2
      =: kernel-3.2-lts-x86_64-all
      package: onl-kernel-3.2-lts-x86-64-all:amd64

    kernel-3.16: &kernel-3-16
      =: kernel-3.16-lts-x86_64-all
      package: onl-kernel-3.16-lts-x86-64-all:amd64

    kernel-4.9: &kernel-4-9
      =: kernel-4.9-lts-x86_64-all
      package: onl-kernel-4.9-lts-x86-64-all:amd64


    kernel-4.14: &kernel-4-14
      =: kernel-4.14-lts-x86_64-all
      package: onl-kernel-4.14-lts-x86-64-all:amd64

    kernel-4.19: &kernel-4-19
      =: kernel-4.19-lts-x86_64-all
      package: onl-kernel-4.19-lts-x86-64-all:amd64

    kernel-5.4: &kernel-5-4
      =: kernel-5.4-lts-x86_64-all
      package: onl-kernel-5.4-lts-x86-64-all:amd64

    # pick one of the above kernels
    kernel:
      <<: *kernel-3-16

    # GRUB command line arguments for 'serial' declaration
    # this is equivalent to, but not in the same format as,
    # the linux 'console=' arguments below
    # Default for ttyS1
    serial: >-
      --port=0x2f8
      --speed=115200
      --word=8
      --parity=no
      --stop=1

    # supplemental kernel arguments
    # (not including kernel, initrd and ONL-specific options)
    # Default for ttyS1
    args: >-
      nopat
      console=ttyS1,115200n8

    ### Defaults for ttyS0
    ##serial: >-
    ##  --port=0x3f8
    ##  --speed=115200
    ##  --word=8
    ##  --parity=no
    ##  --stop=1
    ##args: >-
    ##  nopat
    ##  console=ttyS0,115200n8

    ##device: /dev/vda
    ### install to a specific block device

    device: ONIE-BOOT
    # install to the device that contains the ONIE-BOOT partition
    # (query using parted and/or blkid)

  # Default partitioning scheme
  # boot, config --> 128MiB
  # images --> 1GiB
  # data --> rest of disk
  # default format (as shown) is ext4
  # 'GiB' : 1024 * 1024 * 1024,
  # 'G' : 1000 * 1000 * 1000,
  # 'MiB' : 1024 * 1024,
  # 'M' : 1000 * 1000,
  # 'KiB' : 1024,
  # 'K' : 1000,
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
      =: 100%
      format: ext4

  ### Sample partitioning scheme experiencing disk space pressure
  ##installer:
  ##- ONL-BOOT: 128MiB
  ##- ONL-CONFIG: 128MiB
  ##- ONL-IMAGES: 384MiB
  ##- ONL-DATA: 100%

  network:

    # remap interface names on boot (loader only)
    # make sure you have a valid 'ma1' entry in your platform config...

    interfaces:

      # this should work for most systems
      ma1:
        name: eth0

      # for other wierd corner cases
      ##ma1:
      ##  name: ~
      ##  syspath: SOME-PATH
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




### modules (Vendor's or Platform's)

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







