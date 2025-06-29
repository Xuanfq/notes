# Build

## Environment

### Docker

```shell
aiden@Xuanfq:~/workspace/onl/OpenNetworkLinux$ tree docker/
docker/
├── images
│   ├── builder7
│   │   ├── 1.0
│   │   │   ├── Dockerfile
│   │   │   └── Makefile
│   │   ├── 1.1
│   │   │   ├── Dockerfile
│   │   │   └── Makefile
│   │   └── 1.2
│   │       ├── README
│   │       └── history
│   ├── builder8
│   │   ├── 1.0
│   │   │   ├── Dockerfile
│   │   │   └── Makefile
│   │   ├── 1.1
│   │   │   ├── Dockerfile
│   │   │   └── Makefile
│   │   ├── ...
│   │   ├── 1.11
│   │   │   ├── Dockerfile
│   │   │   └── Makefile
│   ├── builder9
│   │   ├── 1.0
│   │   │   ├── Dockerfile
│   │   │   └── Makefile
│   │   ├── ...
│   │   └── 1.6
│   │       ├── Dockerfile
│   │       └── Makefile
│   ├── builder10
│   │   ├── 1.0
│   │   │   ├── Dockerfile
│   │   │   └── Makefile
│   │   ├── 1.1
│   │   │   ├── Dockerfile
│   │   │   ├── Makefile
│   │   │   └── multistrap-insecure-fix.patch
│   │   └── 1.2
│   │       ├── Dockerfile
│   │       └── Makefile
└── tools
    ├── Makefile
    ├── PKG.yml
    ├── container-id
    ├── docker_shell
    └── onlbuilder

32 directories, 56 files
aiden@Xuanfq:~/workspace/onl/OpenNetworkLinux$ 
```

用到了两个脚本：
- `docker/tools/docker_shell` -> `docker|/bin/docker_shell`: 用于初始化docker容器用户，使其与本地用户一致。
- `docker/tools/container-id` -> `docker|/bin/container-id`: 没有实际使用。


### Usage

Notice: 低版本的可能无法编译，如`debian7`, `debian8`, 需要修改镜像源等。


**Build OpenNetworkLinux Docker**:

```bash
#> cd OpenNetworkLinux/
#> export VERSION=8
#> make docker  # 通过命令 `@docker/tools/onlbuilder -$(VERSION) --isolate --hostname onlbuilder$(VERSION) --pull --autobuild --non-interactive` 拉取docker
#> Pulling opennetworklinux/builder7:1.0…
```

Notice: 也可以进入`docker/images/builder(debian version 7-10)/(docker version)`进行`make build`构建image，但构建高版本的docker version, 需要从低版本开始编译!

List: 
- 7  : ('wheezy', 'opennetworklinux/builder7:1.2'),
- 8  : ('jessie',  'opennetworklinux/builder8:1.11'),
- 9  : ('stretch', 'dentproject/builder9:1.8' ),
- 10 : ('buster',  'opennetworklinux/builder10:1.2'),


**Enter Docker Container**:

```bash
#> docker/tools/onlbuilder -9  # or -7/-8/-9/-10, default is -8
#> source setup.env
#> apt-cacher-ng  # 当局域网内某台主机通过 APT 安装或更新软件时，apt-cacher-ng 会将下载的软件包、索引文件（如 .deb 文件、Packages.gz 等）缓存到本地。
#> cd packages/platforms; mv xxx Makefile /tmp/; rm -rf *; mv /tmp/xxx /tmp/Makefile .  # 移除不需要编译的platform
#> make amd64 arm64
```

Try in Podman (TODO):
由于`docker/tools/docker_shell`需要`sudo`权限(PowerPC编译需要)，若无此需求，可以试着移除：

```python2
# docker/tools/onlbuilder

# 重写并覆盖/bin/docker_shell
# g_docker_arguments += " -v %s/docker_shell:/bin/docker_shell " % os.path.dirname(os.path.abspath(__file__))

# user
g_docker_arguments += " --user $(id -u):$(id -g)  "

# g_docker_arguments += " %(image)s /bin/docker_shell --user %(user)s %(cacher)s -c %(commands)s" % g_arg_d
g_docker_arguments += " %(image)s  %(commands)s" % g_arg_d
```
但编译时还是有问题(项目文件属性都变成了root:root)：
```
aiden@Xuanfq:~/workspace/onl/build$ source setup.env 
bash: /home/aiden/workspace/onl/build/tools/make-versions.py: Permission denied
bash: /home/aiden/workspace/onl/build/tools/submodules.py: Permission denied
bash: /home/aiden/workspace/onl/build/tools/submodules.py: Permission denied
bash: /home/aiden/workspace/onl/build/tools/submodules.py: Permission denied
cp: failed to access '/home/aiden/workspace/onl/build/REPO': Permission denied
aiden@Xuanfq:~/workspace/onl/build$ 
```


**Auto Build**:

- 方式1：设置运行命令
```bash
#> docker/tools/onlbuilder -9 --command "make amd64"
```

- 方式2：设置隔离环境和自动编译(`make all`，根据docker环境的`lsb_release -c -s`结构构建多个架构)
```bash
#> docker/tools/onlbuilder -9 --isolates --hostname "autobuild"  --autobuild (--non-interactive)
```
实际上会将当前项目目录作为Home目录，通过项目`.bashrc`自动触发Build。



**More**:

Ref: `docs/Building.md`



## 构建逻辑与过程

### 设置环境

Command: `source setup.env`

1. 设置环境变量：
   1. `ONL`:
   2. `ONLPM_OPTION_PACKAGEDIRS`: ONL package dir, `$ONL/packages` and `$ONL/builds`
   3. `ONLPM_OPTION_REPO`: ONL repo dir, `$ONL/REPO`
   4. `ONLPM_OPTION_RELEASE_DIR`: default RELEASE dir, `$ONL/RELEASE`
   5. `PATH`: add tools and scripts, `$ONL/tools/scripts` and `$ONL/tools`
   6. `ONL_MAKE_PARALLEL`: parallel build settings, `$(nproc) * 2`
   7. `BUILDROOTMIRROR`: buildroot download mirror, `http://buildroot.opennetlinux.org/dl`, invalid!
   8. `ONL_DEBIAN_SUITE`: current debian suite, `$(lsb_release -c -s)`
   9. `ONL_SUBMODULE_UPDATED_SCRIPTS`: submodule post update scripts, `$ONL/tools/scripts/submodule-updated.sh`
2. 生成版本文件（若还没生成）：`make/versions/*`, 包括`version-onl.json  version-onl.mk  version-onl.sh  version-onl.yml`, (可以通过`make version`重新生成)
   ```yml
    # cat version-onl.yml 
    BUILD_ID: 2025-06-28.11:14-28f52e6                              # build timestamp + short latest commit id
    BUILD_SHA1: 28f52e623a5f820598fda549f5c86c670081a48b            # latest commit id
    BUILD_SHORT_SHA1: 28f52e6
    BUILD_TIMESTAMP: 2025-06-28.11:14
    FNAME_BUILD_ID: 2025-06-28.1114-28f52e6
    FNAME_BUILD_TIMESTAMP: 2025-06-28.1114
    FNAME_PRODUCT_VERSION: ONL-master
    FNAME_RELEASE_ID: ONL-master-2025-06-28.1114-28f52e6
    FNAME_VERSION_ID: ONL-master
    ISSUE: Open Network Linux OS ONL-master, 2025-06-28.11:14-28f52e6
    OS_NAME: Open Network Linux OS      # Fix value
    PRODUCT_ID_VERSION: master          # branch [can be a tag branch]
    PRODUCT_VERSION: ONL-master         # ONL- + branch($PRODUCT_ID_VERSION)
    RELEASE_ID: ONL-master,2025-06-28.11:14-28f52e6     # $VERSION_ID + $BUILD_ID
    SYSTEM_COMPATIBILITY_VERSION: '2'   # Fix value
    VERSION_ID: ONL-master              # ONL- + branch($PRODUCT_ID_VERSION)
    VERSION_STRING: Open Network Linux OS ONL-master, 2025-06-28.11:14-28f52e6      # $OS_NAME $VERSION_ID, $BUILD_ID
    ```
3. 子模块代码克隆与更新：
   1. `sm/infra`
   2. `sm/bigcode`
   3. `sm/build-artifacts`: 
      ```log
        aiden@Xuanfq:~/workspace/onl/build/sm/build-artifacts/REPO$ tree
        .
        ├── buster
        │   └── packages
        │       ├── binary-amd64
        │       │   └── onl-buildroot-initrd_1.0.0_amd64.deb
        │       ├── binary-arm64
        │       │   └── onl-buildroot-initrd_1.0.0_arm64.deb
        │       ├── binary-armel
        │       │   └── onl-buildroot-initrd_1.0.0_armel.deb
        │       └── binary-armhf
        │           └── onl-buildroot-initrd_1.0.0_armhf.deb
        ├── jessie
        │   └── packages
        │       ├── binary-amd64
        │       │   └── onl-buildroot-initrd_1.0.0_amd64.deb
        │       ├── binary-arm64
        │       │   └── onl-buildroot-initrd_1.0.0_arm64.deb
        │       ├── binary-armel
        │       │   └── onl-buildroot-initrd_1.0.0_armel.deb
        │       └── binary-powerpc
        │           └── onl-buildroot-initrd_1.0.0_powerpc.deb
        └── stretch
            └── packages
                ├── binary-amd64
                │   └── onl-buildroot-initrd_1.0.0_amd64.deb
                ├── binary-arm64
                │   └── onl-buildroot-initrd_1.0.0_arm64.deb
                ├── binary-armel
                │   └── onl-buildroot-initrd_1.0.0_armel.deb
                └── binary-armhf
                    └── onl-buildroot-initrd_1.0.0_armhf.deb

        19 directories, 12 files
      ```
4. `setup.env`详细内容：
    ```bash
    # The root of the ONL build tree is here
    export ONL=$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)

    # The ONL package dir is here:
    export ONLPM_OPTION_PACKAGEDIRS="$ONL/packages:$ONL/builds"

    # The ONL repo dir is here:
    export ONLPM_OPTION_REPO="$ONL/REPO"

    # The default RELEASE dir is here:
    export ONLPM_OPTION_RELEASE_DIR="$ONL/RELEASE"

    # The ONL build tools should be included in the local path:
    export PATH="$ONL/tools/scripts:$ONL/tools:$PATH"

    # Parallel Make Jobs
    # Default parallel build settings
    export ONL_MAKE_PARALLEL=-j$(echo "$(nproc) * 2" | bc)

    # Version files
    $ONL/tools/make-versions.py --import-file=$ONL/tools/onlvi --class-name=OnlVersionImplementation --output-dir $ONL/make/versions

    #
    # buildroot download mirror. We suggest you setup a local repository containing these contents for faster local builds.
    #
    export BUILDROOTMIRROR=${BUILDROOTMIRROR:-"http://buildroot.opennetlinux.org/dl"}

    # These submodules are required for almost everything.
    $ONL/tools/submodules.py $ONL sm/infra
    $ONL/tools/submodules.py $ONL sm/bigcode
    $ONL/tools/submodules.py $ONL sm/build-artifacts

    # Prepopulate local REPO with build-artifacts.
    # 复制并填充本地仓库（通过子模块build-artifacts）
    cp -R $ONL/sm/build-artifacts/REPO/* $ONL/REPO

    # Export the current debian suite
    export ONL_DEBIAN_SUITE=$(lsb_release -c -s)

    # Enable local post-merge githook
    # 清理模块清单(make modclean in $ONL)
    if [ ! -f $ONL/.git/hooks/post-merge ] && [ -d $ONL/.git ]; then
        cp $ONL/tools/scripts/post-merge.hook $ONL/.git/hooks/post-merge
    fi

    # submodule post update scripts.
    # 子模块一旦更新，应执行下方指定的脚本，以：1. 清理模块清单(make modclean in $ONL) 2. 重新生成程序包(pkg)缓存(make rebuild in $ONL)
    export ONL_SUBMODULE_UPDATED_SCRIPTS="$ONL/tools/scripts/submodule-updated.sh"
    ```



### 开启APT局域网缓存加速

Command: `apt-cacher-ng`, Option



### 编译预优化

#### 移除不必要的编译平台

在`packages/platforms`中有其他供应商平台和机器的代码实现，可移除他们。

1. cd packages/platforms
2. mkdir ../tmp
3. mv your-platform-name Makefile ../tmp/
4. rm -rf *
5. mv ../tmp/* .
6. rm -r ../tmp


#### 移除失效的镜像源

rootfs源：
- `OpenNetworkLinux/builds/any/rootfs/$debianname/standard/standard.yml`
- `OpenNetworkLinux/tools/onlrfs.py`

1. Dibian7-9均使用了失效域名`apt.opennetlinux.org`，在起配置中取消使用，如：

```yml
# OpenNetworkLinux/builds/any/rootfs/jessie/standard/standard.yml
Multistrap:
  General:
    arch: ${ARCH}
    cleanup: true
    noauth: true
    explicitsuite: false
    unpack: true
    debootstrap: Debian-Local Local-All Local-Arch #ONL-Local  # comment the ONL-Local
    aptsources: Debian #ONL  # comment the ONL
```

2. 使用国内APT镜像源，将`archive.debian.org`替换为其他国内源，如：

```yml
Multistrap:
  General:
    arch: ${ARCH}
    cleanup: true
    noauth: true
    explicitsuite: false
    unpack: true
    debootstrap: Debian-Local Local-All Local-Arch ONL-Local
    aptsources: Debian ONL

  Debian:
    packages: *Packages
    source: http://mirrors.aliyun.com/debian/  # 替换为 mirrors.aliyun.com
    suite: ${ONL_DEBIAN_SUITE}
    #keyring: debian-archive-keyring
    omitdebsrc: true

  Debian-Local:
    packages: *Packages
    source: http://${APT_CACHE}mirrors.aliyun.com/debian/  # 替换为 mirrors.aliyun.com
    suite: ${ONL_DEBIAN_SUITE}
    keyring: debian-archive-keyring
    omitdebsrc: true
```

3. 其他**内置镜像源**和**APT缓存**`OpenNetworkLinux/tools/onlrfs.py`, 用于替换`buster`(`debian10`)的`rootfs/standard`配置：

```python
# OpenNetworkLinux/tools/onlrfs.py
class OnlRfsBuilder(object):

    DEFAULTS = dict(
        DEBIAN_SUITE='wheezy',                        # <- 注意：无论debian7-10，这里的debian suite一直用的都是wheezy，谨慎
        DEBIAN_MIRROR='mirrors.kernel.org/debian/',   # <- 替换源
        APT_CACHE='127.0.0.1:3142/'                   # <- 可以移除
        )

    MULTISTRAP='/usr/sbin/multistrap'
    QEMU_PPC='/usr/bin/qemu-ppc-static'
    QEMU_ARM='/usr/bin/qemu-arm-static'
    QEMU_ARM64='/usr/bin/qemu-aarch64-static'
    BINFMT_PPC='/proc/sys/fs/binfmt_misc/qemu-ppc'

    def __init__(self, config, arch, **kwargs):
        self.kwargs = kwargs
        self.arch = arch
        self.kwargs['ARCH'] = arch

        # Hack -- we have to pull powerpc from the archive
        # This will need a cleaner fix.
        if arch == 'powerpc':
            self.DEFAULTS['DEBIAN_MIRROR'] = 'archive.debian.org/debian/'

        self.kwargs.update(self.DEFAULTS)
        self.__load(config)
        self.__validate()
```
and
```yml
# OpenNetworkLinux/builds/any/rootfs/buster/standard/standard.yml
Multistrap:
  Debian:
    packages: *Packages
    source: http://${DEBIAN_MIRROR}
    suite: ${ONL_DEBIAN_SUITE}
#    keyring: debian-archive-keyring
    omitdebsrc: true

  Debian-Local:
    packages: *Packages
    source: http://${APT_CACHE}${DEBIAN_MIRROR}
    suite: ${ONL_DEBIAN_SUITE}
 #   keyring: debian-archive-keyring
    omitdebsrc: true

```

Notice: 这部分也可以通过`OpenNetworkLinux/builds/any/rootfs/$debianname/standard/standard.yml`进行修改，无需改代码。



### 编译选项

#### make all

自动构建所在环境`ONL_DEBIAN_SUITE`的所有能构建的架构包：

```makefile
# Available build architectures based on the current suite
BUILD_ARCHES_wheezy := amd64 powerpc
BUILD_ARCHES_jessie := amd64 powerpc armel
BUILD_ARCHES_stretch := arm64 amd64 armel armhf

# Build available architectures by default.
.DEFAULT_GOAL := all
all: $(BUILD_ARCHES_$(ONL_DEBIAN_SUITE))      # `source setup.env` 中设置的环境变量
```

- `onlbuilder -10, DEBIAN-10, buster`不能自动编译。


#### make $arch

arch = amd64 powerpc armel arm64 armhf

```makefile
ifndef ONL
$(error Please source the setup.env script at the root of the ONL tree)
endif

include $(ONL)/make/config.mk

# All available architectures.
ALL_ARCHES := amd64 powerpc armel arm64 armhf

# Build rule for each architecture.
define build_arch_template
$(1) :
	$(MAKE) -C builds/$(1)
endef
$(foreach a,$(ALL_ARCHES),$(eval $(call build_arch_template,$(a))))
```

Notice: 通过`include $(ONL)/make/config.mk`导入配置，实际编译还是通过`make -C builds/$arch`。



#### make rebuild

清理并重新构建包缓存，通过此操作，可以重新进行`make all/$arch`构建。

```makefile
rebuild:
	$(ONLPM) --rebuild-pkg-cache      # tools/onlpm.py --rebuild-pkg-cache
```

#### make modclean

清理构建时生成的模块数据库文件。

```makefile
modclean:
	rm -rf $(ONL)/make/modules/modules.*
```


#### make docker(-debug)

docker: 拉取docker编译环境并运行自动构建
docker-debug: 拉取docker编译环境并进入docker交互模式

```makefile
.PHONY: docker

ifndef VERSION
VERSION := 9
endif

docker_check:
	@which docker > /dev/null || (echo "*** Docker appears to be missing. Please install docker.io in order to build OpenNetworkLinux." && exit 1)

docker: docker_check
	@docker/tools/onlbuilder -$(VERSION) --isolate --hostname onlbuilder$(VERSION) --pull --autobuild --non-interactive

# create an interative docker shell, for debugging builds
docker-debug: docker_check
	@docker/tools/onlbuilder -$(VERSION) --isolate --hostname onlbuilder$(VERSION) --pull
```


#### make version

强制生成Version文件，位于`$(ONL)/make/versions/`下。包括`version-onl.json  version-onl.mk  version-onl.sh  version-onl.yml`这些不同格式的文件。

```makefile
versions:
	$(ONL)/tools/make-versions.py --import-file=$(ONL)/tools/onlvi --class-name=OnlVersionImplementation --output-dir $(ONL)/make/versions --force
```


```yml
# cat version-onl.yml 
BUILD_ID: 2025-06-28.11:14-28f52e6                              # build timestamp + short latest commit id
BUILD_SHA1: 28f52e623a5f820598fda549f5c86c670081a48b            # latest commit id
BUILD_SHORT_SHA1: 28f52e6
BUILD_TIMESTAMP: 2025-06-28.11:14
FNAME_BUILD_ID: 2025-06-28.1114-28f52e6
FNAME_BUILD_TIMESTAMP: 2025-06-28.1114
FNAME_PRODUCT_VERSION: ONL-master
FNAME_RELEASE_ID: ONL-master-2025-06-28.1114-28f52e6
FNAME_VERSION_ID: ONL-master
ISSUE: Open Network Linux OS ONL-master, 2025-06-28.11:14-28f52e6
OS_NAME: Open Network Linux OS      # Fix value
PRODUCT_ID_VERSION: master          # branch [can be a tag branch]
PRODUCT_VERSION: ONL-master         # ONL- + branch($PRODUCT_ID_VERSION)
RELEASE_ID: ONL-master,2025-06-28.11:14-28f52e6     # $VERSION_ID + $BUILD_ID
SYSTEM_COMPATIBILITY_VERSION: '2'   # Fix value
VERSION_ID: ONL-master              # ONL- + branch($PRODUCT_ID_VERSION)
VERSION_STRING: Open Network Linux OS ONL-master, 2025-06-28.11:14-28f52e6      # $OS_NAME $VERSION_ID, $BUILD_ID
```


#### make relclean

清理编译的Image结果。

```makefile
relclean:
	@find $(ONL)/RELEASE -name "ONL-*" -delete
```



### 编译结果

Location: `RELEASE/*`

```log
aiden@Xuanfq:~/workspace/onl/build$ tree RELEASE/
RELEASE/
└── buster
    └── amd64
        ├── ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64.swi
        ├── ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64.swi.md5sum
        ├── ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER
        ├── ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER.md5sum
        ├── ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_SWI_INSTALLER
        └── ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_SWI_INSTALLER.md5sum

3 directories, 6 files
aiden@Xuanfq:~/workspace/onl/build$ 
```



### 编译过程

#### Makefile链路

`Makefile`:
1. `include make/config.mk`: 完成一些基本的配置
   1. 包管理脚本路径：`ONLPM := $(ONL)/tools/onlpm.py`
   2. Builder目录（用于构建module）：`export BUILDER := $(ONL)/sm/infra/builder/unix`
   3. 指定要使用的初始化系统方式：`export INIT := sysvinit`, 可选['sysvinit', 'systemd'], 初始化流程：`builds/any/rootfs/$debianname/sysvinit/overlay/etc/inittab`
   4. 指定存放模块清单数据的文件：`export BUILDER_MODULE_DATABASE := $(ONL)/make/modules/modules.json`
   5. 指定查找模块的路径：`BUILDER_MODULE_DATABASE_ROOT := $(ONL)`
   6. 指定生成模块清单的makefile文件路径：`BUILDER_MODULE_MANIFEST := $(ONL)/make/modules/modules.mk`
   7. 生成模块清单并导出模块清单makefile路径：`export MODULEMANIFEST := $(shell $(BUILDER)/tools/modtool.py --db $(BUILDER_MODULE_DATABASE) --dbroot $(BUILDER_MODULE_DATABASE_ROOT) --make-manifest $(BUILDER_MODULE_MANIFEST))`
   8. 生成版本信息并存放到make/versions/目录（若已生成则不会继续生成和保存）：`$(shell $(ONL)/tools/make-versions.py --import-file=$(ONL)/tools/onlvi --class-name=OnlVersionImplementation --output-dir $(ONL)/make/versions)`
   9. 导出子模块infra目录：`export SUBMODULE_INFRA := $(ONL)/sm/infra`
   10. 导出子模块bigcode目录：`export SUBMODULE_BIGCODE := $(ONL)/sm/bigcode`
   11. `include make/templates.mk`: 配置查找文件、目录的makefile命令/函数
      - 查找文件并赋值给变量：`onlpm_find_file $store_var $package $file_to_be_found`
      - 查找目录并赋值给变量：`onlpm_find_dir $store_var $package $dir_to_be_found`
      - 查找文件并赋值给变量和追加到变量：`onlpm_find_file_add $store_var $package $file_to_be_found $added_store_var`
      - 查找目录并赋值给变量和追加到变量：`onlpm_find_dir_add $store_var $package $dir_to_be_found $added_store_var`
2. `$(MAKE) -C builds/$arch`: -> `include $(ONL)/make/arch-build.mk`
   1. 定义需要make的子目录：`DIRECTORIES := rootfs swi installer`
   2. 对子目录逐个执行make(目标为命令行中的传入的目标)：`include $(ONL)/make/subdirs.mk`
      `include $(ONL)/make/subdirs.mk`:
         1. 插入通用配置：`include $(ONL)/make/config.mk`
         2. 若没定义目录，列出目录：`ifndef DIRECTORIES DIRECTORIES := $(notdir $(wildcard $(CURDIR)/*))`
         3. 过滤特殊目录：`FILTER := make Makefile Makefile~ $(FILTER)`; `DIRECTORIES := $(filter-out $(FILTER),$(DIRECTORIES))`
         4. 定义编译规则：
           ```makefile
           all $(MAKECMDGOALS):
             +$(ONL_V_at) $(foreach d,$(DIRECTORIES),$(ONL_MAKE) -C $(d) $(MAKECMDGOALS) || exit 1;)
           ```
      1. 编译`rootfs`: `$(ONL_MAKE) -C builds/$arch/rootfs/ $(MAKECMDGOALS)` ---实际上--> `include $(ONL)/make/pkg.mk`
         1. 
      2. 编译`swi`: `$(ONL_MAKE) -C builds/$arch/swi/ $(MAKECMDGOALS)` ---实际上--> `include $(ONL)/make/pkg.mk`
      3. 编译`installer`: `$(ONL_MAKE) -C builds/$arch/installer/ $(MAKECMDGOALS)` ---实际上--> `include $(ONL)/make/pkg.mk`







