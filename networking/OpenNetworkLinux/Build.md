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
         ```makefile
          include $(ONL)/make/config.mk

          # ...
          pkgall:  # 使用第一个目标作为默认编译目标，编译所有架构
	          $(ONL_V_GEN) $(ONLPM_ENVIRONMENT) $(ONLPM) $(ONLPM_OPTS) --build all --arches $(ARCHES)  # ONLPM_OPTS为空
          
          # ...
         ```
         1. 
      3. 编译`swi`: `$(ONL_MAKE) -C builds/$arch/swi/ $(MAKECMDGOALS)` ---实际上--> `include $(ONL)/make/pkg.mk`
      4. 编译`installer`: `$(ONL_MAKE) -C builds/$arch/installer/ $(MAKECMDGOALS)` ---实际上--> `include $(ONL)/make/pkg.mk`





#### onlpm包管理

`onlpm`是`ONL Package Management`的缩写。`Package`实际上为`Debian Package`, 即`.deb`文件。

`onlpm.py`包含了：
- `debian`包脚本：
  - 系统服务启动脚本: `class OnlPackageAfterInstallScript`
  - 系统服务关闭脚本: `class OnlPackageBeforeRemoveScript`
  - 系统服务移除脚本: `class OnlPackageAfterRemoveScript`
- `debian`包构建器：`class OnlPackage`, 这个类从一个包规范(字典)构建一个单独的debian包
    ```
    # 包规范: [*]Option
    name:         The name of the package
    version:      The version of the package
    arch:         The package architecture
    copyright:    The copyright string or path to copyright file
    changelog:    The changelog string or path to changelog file
    maintainer:   The package maintainer address
    summary:      The package summary description
    *desc:        The package description (defaults to summary)
    files:        A dict containing source/dst pairs.
                      A src can be a file or a directory
                      A dst can be a file or a directory
                  A list containing src,dst pairs.
    *depends:     List of package dependencies
    *docs :       List of documentation files
    ```
- `debian`包分组构建器：`class OnlPackageGroup`, 是`OnlPackage`的控制器，具有通用的包设置、多个包声明和公共的构建步骤的`OnlPackage`都归于此分组。
- `debian`包仓库管理器：`class OnlPackageRepoUnlocked`(非线程安全), `class OnlPackageRepo`(线程安全)。仓库位于`REPO/$debianname/*`。
  - 安装package到仓库中。
  - 在仓库中查找package。
  - 从仓库中提取package。
  - 提取package到本地缓存中，其文件内容可以被有依赖关系的其他包使用。
- `debian`包管理器：`class OnlPackageManager`, 管理所有以上定义的。



主要运行过程：
1. 设置仓库：`pm.set_repo(ops.repo, packagedir=ops.repo_package_dir)`
   
   ops.repo = `os.environ.get('ONLPM_OPTION_REPO', None)` (setup.env: `"$ONL/REPO"`)
   
   ops.repo_package_dir = `os.environ.get('ONLPM_OPTION_REPO_PACKAGE_DIR', 'packages')` (no env, use default `"packages"`)
   
   1. 创建仓库管理器：`self.opr = OnlPackageRepo(root="$ONL/REPO", packagedir="packages")`
      1. root = `os.path.join(root, g_dist_codename)`, g_dist_codename = $debianname, e.g. REPO/buster/
      2. deb-package目录：self.repo = `os.path.join(root, packagedir)`, e.g. REPO/buster/packages/
      3. deb-package解压后的缓存目录：self.extracts = `os.path.join(root, 'extracts')`, e.g. REPO/buster/extracts/

2. 加载package目录：
   
   ```python
    for pdir in ops.packagedirs:
      pm.load(basedir=pdir, usecache=not ops.no_pkg_cache, rebuildcache=ops.rebuild_pkg_cache, roCache=ops.ro_cache)
   ```

   ops.packagedirs = `os.environ['ONLPM_OPTION_PACKAGEDIRS'].split(':')` (setup.env: `"$ONL/packages:$ONL/builds"`)
   
   ops.no_pkg_cache = `os.environ.get('ONLPM_OPTION_NO_PKG_CACHE', False)` (no env, use default `False`)
   
   ops.rebuild_pkg_cache = `os.environ.get('ONLPM_OPTION_REBUILD_PKG_CACHE', False)` (no env, use default `False`)
   
   ops.ro_cache = `False` (no setting, use default `False`)
   
   1. 若`usecache=True` && `rebuildcache=False`, 加载缓存：`self.__load_cache(basedir, roCache)`
   2. 若上述条件不成立或加载缓存失败，构建缓存：`self.__build_cache(basedir)`
      1. 递归packagedir目录的所有文件，即 `$ONL/packages` **或** `$ONL/builds` (一次一个packagedir目录的缓存)。若文件为`[ 'PKG.yml', 'pkg.yml' ]`，且不存在`["PKG.yml.disabled", "pkg.yml.disabled"]`，检查并加载为`OnlPackageGroup`。
         1. `pg = OnlPackageGroup()`
         2. `pg.load(pkg=os.path.join(root, f))`, root=`$ONL/packages/...` **或** `$ONL/builds/...`, f=`pkg.yml`/`PKG.yml`
            1. 加载默认package键值字典：`ddict = OnlPackage.package_defaults_get(pkg=pkg)`
               1. 拷贝默认键值对：`ddict = klass.DEFAULTS.copy()`
                  ```
                  {
                    'vendor' : 'Open Network Linux',
                    'url' : 'http://opennetlinux.org',
                    'license' : 'unknown',

                    # Default Python Package Installation
                    'PY_INSTALL' : '/usr/lib/python2.7/dist-packages',

                    # Default Builder build directory name. Must match setup.env
                    'BUILD_DIR' : 'BUILD/%s' % g_dist_codename,

                    # Default Templates Location
                    'ONL_TEMPLATES' : "%s/packages/base/any/templates" % os.getenv("ONL"),

                    # Default Distribution
                    'DISTS' : g_dist_codename,
                  }
                  ```
               2. 从`根目录的下一层`到`pkg所在目录`，寻找以下文件之一并逐个覆盖（层次深的覆盖低的）(实际上没有以下文件)：
                 - `[.]PKG_DEFAULTS` -- 一个生成包含默认Package键生成yaml的可执行文件/脚本。`yaml.load(subprocess.check_output(f, shell=True))`
                 - `[.]PKG_DEFAULTS.yml` -- 一个包含默认Package键的onlyaml文件。`onlyaml.loadf(f)`
            2. 加载pkg.yml、更新键值字典并填充变量: `pkg_data = onlyaml.loadf(pkg, ddict)`
               1. 变量填充与键值字典覆盖顺序：
                  1. `os.environ`
                  2. `'__DIR__'=dirname(pkg.yml)`
                  3. 默认package键值字典
                  4. pkg.yml里的kv: `!include xxx key=value`，加载 `!include` 时填充
                  5. pkg.yml里root键variables: 两次加载pkg.yml, 第一次加载variables并覆盖字典，第二次加载为最终数据
                    ```yml
                    # builds/any/swi/APKG.yml
                    variables:
                      !include $ONL/make/versions/version-onl.yml
                    ```
               2. !include 与 !script 解析器
                  1. !include: `!include $ONL/builds/any/swi/APKG.yml ARCH=amd64 xx=xxx ..`
                     1. filename, kv1, kv2, ... = $(!include后的字符串.strip()).split()
                     2. 用键值字典填充filename里的变量
                     3. k,v=kv.split("="), 更新到键值字典variables
                     4. 递归加载yml文件: `return loadf(filename, variables)`
                  2. !script: `!script  $ONL/tools/onl-init-pkgs.py ${INIT}`
                     1. filename = $(!script后的字符串.strip())
                     2. 用键值字典填充filename里的变量
                     3. 运行filename文件将其输出结果重定向到临时yml文件tf.name：`os.system("%s > %s" % (directive, tf.name))`
                     4. 递归加载临时yml文件: `return loadf(tf.name, variables)`
            3. 对于加载后的pkg.yml数据`pkg_data`, 遍历`packages`并创建`OnlPackage`，若没有`packages`key，报错并跳过该pkg.yml的加载和使用。
                ```python
                self.packages = []
                for p in pkg_data['packages']:
                    self.packages.append(OnlPackage(p, os.path.dirname(pkg),
                                                    pkg_data.get('common', None),
                                                    ddict))  # OnlPackage的键值信息为pkg = p + pkg_data.get('common',{}) + ddict
                ```
            4. 记录pkg.yml信息：
                ```python
                self._pkg_info = pkg_data.copy()  # pkg_data backup
                self._pkgs = pkg_data  # pkg_data
                self._pkgs['__source'] = os.path.abspath(pkg)
                self._pkgs['__directory'] = os.path.dirname(self._pkgs['__source'])
                self._pkgs['__mtime'] = os.path.getmtime(pkg)  # modify time
                ```
         3. `pg.distcheck()`: 检查PackageGroup所设置的`debian发行版名称`(如buster)是否符合当前编译环境，没有设置`dist`则通过。
            ```python 
            def distcheck(self):
              for p in self.packages:
                  if p.pkg.get("dists", None):
                      if g_dist_codename not in p.pkg['dists'].split(','):  # g_dist_codename是全局变量，从编译环境中获取的
                          return False
              return True
            ```
         4. `pg.buildercheck(builder_arches)`: 检查PackageGroup所设置的`arch`(如amd64)是否符合当前编译环境
            builder_arches = [ 'all', 'amd64' ] + subprocess.check_output(['dpkg', '--print-foreign-architectures']).split()
            ```python
            def buildercheck(self, builder_arches):
              for p in self.packages:
                  if p.arch() not in builder_arches:  # p.arch() -> p.pkg['arch']
                      return False
              return True
            ```
         5. `self.package_groups.append(pg)`: 添加到management管理的`package_groups`里。
         6. 若本循环层次上述步骤报错，则跳过该PackageGroup的加载。
   3. 构建缓存后，若`usecache=True`，保存缓存：`self.__write_cache(basedir)`。
      缓存文件为`packagedir`(即`$ONL/packages`或`$ONL/builds`)对应目录下的`'.PKGs.cache.%s' % g_dist_codename`文件。使用`pickle`来保存和加载。
3. 过滤 不被支持的架构的PackageGroup 以及 不在子目录范围内的PackageGroup：`pm.filter(subdir = ops.subdir, arches = ops.arches)`
   
   ops.subdir = os.getcwd()
   
   ops.arches = ['amd64', 'powerpc', 'armel', 'armhf', 'arm64', 'all']
   
   ```python
    def filter(self, subdir=None, arches=None, substr=None):
      for pg in self.package_groups:
          if subdir and not pg.is_child(subdir):
              pg.filtered = True                  # filtered = True 后，自动跳过 build
          if not pg.archcheck(arches):
              pg.filtered = True
   ```
4. 若设置了编译选项，对编译选项的一个或多个(PackageID/all)(pkg)参数进行逐个编译：`for p in ops.build: pm.build(p) if p in pm else raise OnlPackageMissingError(p)`, p为`PackageID`(name:arch)或`all`, 若p不匹配则抛出错误。`build(self, pkg=p, dir_=None, filtered=True, prereqs_only=False)`
   1. 遍历所有存在/支持pkg的PackageGroup: `for pg in [pg for pg in self.package_groups if pkg in pg]`
      1. 跳过被过滤的PackageGroup: `if filtered and pg.filtered: continue`
      2. 若只处理先决条件prereqs_only为False，处理先决条件-子模块拉取/更新需求: `for sub in pg.prerequisite_submodules()`
         
         配置例子：
         ```yml
         prerequisites:
          submodules:
            - { root: "${ONL}", path : packages/base/any/initrds/buildroot/builds/buildroot-mirror, recursive: true }
         ```
         解析代码：
         `def prerequisite_submodules(): return self._pkgs.get('prerequisites', {}).get('submodules', [])`
         处理需求：
         ```python
          manager = submodules.OnlSubmoduleManager(root)
          manager.require(path, depth=depth, recursive=recursive)  # 拉取和更新代码
         ```

         期间会校验参数，若参数不合法、或子模块处理过程中报错将自动停止。

      3. 处理先决条件-packages需求: `for pr in pg.prerequisite_packages():`
         
         配置例子：
         ```yml
         prerequisites:
           broken: true
           packages: [ "onl-rootfs:$ARCH" ]  # or [ "onl-rootfs:$ARCH,onl-rootfs:arm64" ] or use -
         ```
         解析代码：
         ```py
         def prerequisite_packages(self):
            rv = []
            for e in list(onlu.sflatten(self._pkgs.get('prerequisites', {}).get('packages', []))):
              rv += e.split(',')
            return rv
         ```
         处理需求：build_missing=True, 缺失时主动对该package进行build。递归！
         ```python
         self.require(pr, build_missing=True)
         ```
      
      4. 若只处理先决条件prereqs_only为False，构建package并添加到仓库（若仓库存在）（若仓库存在该package的版本则移除；若仓库中存在该package的解压目录，也移除该目录和文件）。
         
         ```py
         if not prereqs_only:
           # Build package
           products = pg.build(dir_=dir_)
           if self.opr:
              # Add results to our repo
              self.opr.add_packages(products)
         ```

         PackageGroup构建过程：`build(self, dir_=None)` (dir_: 软件包组的输出目录, 默认情况下为软件包组的父目录。)
           - 不提供构建单个软件包的选项。这是因为假定组中定义的软件包是相互关联的，应该始终一起构建。
           - 同时还假定组中的所有软件包具有共同的构建步骤。该构建步骤仅执行一次，然后所有软件包会根据软件包规范中定义的工件进行构建。
           - 这可确保同一组中软件包的内容不会出现不匹配的情况，也不会不必要地多次调用构建步骤。
           1. 定义debian包文件路径存放变量：`products = []`
           2. 开启全局锁：`with onlu.Lock(os.path.join(self._pkgs['__directory'], '.lock')):`
           3. 全局锁下进行make编译：`self.gmake_locked(target="", operation='Build')`, target="" !
              1. 检查是否允许编译，需满足：`self._pkgs.get('build', True) and not os.environ.get('NOBUILD', False)`
                 1. `build`: 实际上没有设置该键值，默认为True
                 2. `NOBUILD`: 在`pkg.mk`中，Target `pkg` 有此设置，设置为`NOBUILD=1`，设置为没有编译步骤而仅打包package。
              2. 获取编译目录：
                 1. `pkg.yml`所处的同级目录的`builds`目录: `os.path.join(self._pkgs['__directory'], 'builds')`
                 2. `pkg.yml`所处的同级目录的`BUILDS`目录: `os.path.join(self._pkgs['__directory'], 'BUILDS')`
              3. 遍历编译目录（若存在）进行逐项编译：`make -C /path/to/builds_or_BUILDS/ -j?`, with no target
                 ```py
                  MAKE = os.environ.get('MAKE', "make")
                  V = " V=1 " if logger.level < logging.INFO else ""
                  cmd = MAKE + V + ' -C ' + '/path/to/builds_or_BUILDS/' + " " + os.environ.get('ONLPM_MAKE_OPTIONS', "") + " " + os.environ.get('ONL_MAKE_PARALLEL', "") + " " + target
                  onlu.execute(cmd, ex=OnlPackageError('%s failed.' % operation))
                 ```
           4. 全局锁下打包PackageGroup相关Package：遍历PackageGroup的所有Package(`pkg.yml`里配置的)对其执行`build()`进行构建debian包，构建完返回debian包路径。
              ```py
              for p in self.packages:
                products.append(p.build(dir_=dir_))
              ```

              Package构建过程：`build(self, dir_=None)` (dir_: 软件包的输出目录, 若未指定，软件包文件将存放在其本地目录中。)
              1. 若package配置中存在`external`字段，意味着该package已经由外部编译且已编译完成，该字段的值即为package的路径，检查存在与否并返回路径，若不存在则抛出错误。
              2. 若package配置中存在`files`字段，意味着该package需要这些文件，解析这些(源)文件及其(目标)安装目录并检查这些文件的存在性： `self._validate_files(key='files', required=True)`，更新其`self.pkg['files']`的值为`list[tuple[srcfile, destdir]]`
                 ```py
                  def _validate_files(self, key, required=True):
                     """Validate the existence of the required input files for the current package."""
                     self.pkg[key] = onlu.validate_src_dst_file_tuples(
                        self.dir,      # pkg.yml所在的目录
                        self.pkg[key], # self.pkg['files']
                        dict(PKG=self.pkg['name'], PKG_INSTALL='/usr/share/onl/packages/%s/%s' % (self.pkg['arch'], self.pkg['name'])),
                        OnlPackageError,
                        required=required)
                 ```
                 - 解析数据：
                   - 若`files`是`dict`, 则key为编译结果文件, value为目标安装目录
                   - 若`files`是`list`, 若item为dict, 则key为编译结果文件, value为目标安装目录; 若item为list/tuple, 需长度为2, 则0为编译结果文件, 1为目标安装目录
                 - 填充模板：
                   - 通过模板填充缺失的`$PKG`和`$PKG_INSTALL`数据：`PKG=self.pkg['name'], PKG_INSTALL='/usr/share/onl/packages/%s/%s' % (self.pkg['arch'], self.pkg['name'])`
                 - 若不符合解析规范或文件不存在，则抛出异常
              3. 若package配置中存在`optional-files`字段，意味着该package可选择性地安装这些文件，存在则安装(即存入变量中)，不存在则跳过。过程同`files`字段,但`required=False`
              4. 若参数中`dir_`为`None`, 使用默认的值`dir_ = self.dir`。
              5. 创建临时工作目录`workdir`并在工作目录中创建`root`目录作为目标文件存放的根目录。
              6. 遍历`files`并复制到`root`目录，若package设置了`symlinks`=True，则在拷贝目录时保留符号链接，否则复制链接目标。
              7. 遍历`optional-files`并复制到`root`目录，若是链接这直接拷贝链接的目标。
              8. 若package配置中存在`links`字段，其值的结构为`list[tuple[link, src]]`，遍历`links`在`root`中创建`link`链接到`src`文件。链接必须相对于最终文件系统为相对路径或绝对路径。(查阅源码并没有在pkg.yml里找到实际这样配置的)。
              9. 在`root`目录创建(若不存在)文档存放目录 docpath=`os.path.join(root, "usr/share/doc/%(name)s" % self.pkg)`，遍历package中的`docs`文档目录检查是否存在，不存在则抛出异常 (没有拷贝到`root`文档存放目录下，这是否存在问题? 查阅源码并没有在pkg.yml里找到实际docs配置) 。
                 ```py
                  # FPM doesn't seem to have a doc option so we copy documentation files directly into place.
                  for src in self.pkg.get('docs', []):
                     if not os.path.exists(src):
                        raise OnlPackageError("Documentation source file '%s' does not exist." % src)
                        shutil.copy(src, docpath)  # !!!!!!!!!!!!!!!!!!!!!!!!!!!! never be excuted !!!
                 ```
              10. 拷贝或写入package配置中的`changelog`和`copyright`到`$workdir/changelog`或`$workdir/copyright`，若配置是存在的文件则拷贝，否则作为文本内容写入。
              11. 使用所有必要的选项构造`fpm`命令并调用该命令进行debian包构建：
                  1. 通用：`command = """fpm -p %(__workdir)s -f -C %(__root)s -s dir -t deb -n %(name)s -v %(version)s -a %(arch)s -m %(maintainer)s --description "%(description)s" --url "%(url)s" --license "%(license)s" --vendor "%(vendor)s" """ % self.pkg`
                  2. 设定运行时依赖项`depends`: depends=list[str], str='name' or 'name > version', `for dep in self.pkg.get('depends', []): command = command + "-d %s " % dep`
                  3. 设定构建时依赖项`build-depends`: build-depends=list[str], str='name' or 'name > version', `for dep in self.pkg.get('build-depends', []): command = command + "--deb-build-depends %s " % dep`
                  4. 设定软件包提供的内容(通常为名称)`provides`: provides=list[str], `for provides in onlu.sflatten(self.pkg.get('provides', [])): command = command + "--provides %s " % provides`
                  5. 设定与软件包冲突的其他软件包/版本`conflicts`: conflicts=list[str], `for conflicts in onlu.sflatten(self.pkg.get('conflicts', [])): command = command + "--conflicts %s " % conflicts`
                  6. 设定与软件包所替代的其他软件包/版本`replaces`: replaces=list[str], `for replaces in onlu.sflatten(self.pkg.get('replaces', [])): command = command + "--replaces %s " % replaces`
                  7. 设定虚拟包，一种不包含实际文件的特殊包，主要用于表示功能或服务`virtual`(查阅源码并没有在pkg.yml里找到实际virtual配置): 
                     ```py
                     if 'virtual' in self.pkg:
                        command = command + "--provides %(v)s --conflicts %(v)s --replaces %(v)s " % dict(v=self.pkg['virtual'])
                       
                       # --provides %(v)s：声明这个包提供了虚拟包名称指定的功能
                       # --conflicts %(v)s：声明这个包与同名的虚拟包冲突，防止同时安装多个提供相同虚拟包的实体包
                       # --replaces %(v)s：声明这个包可以替换同名的虚拟包
                     ```
                     - 表示一组功能或能力，而不是具体的软件包
                     - 作为多个提供相同功能的包的抽象
                     - 简化依赖关系管理
                     - 其他包可以依赖于虚拟包，而不需要关心具体是哪个平台的交换机实现。该功能使得软件包系统更加灵活，允许为不同的硬件平台或配置创建可互换的包，同时保持一致的依赖关系结构。
                  8. 设定软件包的优先级类别`priority`(查阅源码并没有在pkg.yml里找到实际virtual配置): priority='required'|'important'|'standard'|'optional'|'extra', `if 'priority' in self.pkg: command = command + "--deb-priority %s " % self.pkg['priority']`
                     - required：系统正常运行所必需的包
                     - important：提供系统基本功能的重要包
                     - standard：标准系统包含的包
                     - optional：可选的、不与标准包冲突的包
                     - extra：可能与其他高优先级包冲突的附加包
                  9. 设定软件包的系统服务管理，用于自动创建和配置与系统服务相关的生命周期脚本，确保服务在包安装、移除过程中被正确处理 (`"init" in self.pkg`):
                     1. 设定安装初始化脚本，即指定将要安装到 /etc/init.d/ 目录下的初始化脚本，这是传统的 SysV 初始化系统的服务脚本：`if 'init' in self.pkg and os.path.exists(self.pkg['init']): command = command + "--deb-init %s " % self.pkg['init']`
                     2. 设定安装后脚本以在包安装后启动服务：`if self.pkg.get('init-after-install', True): command = command + "--after-install %s " % OnlPackageAfterInstallScript(self.pkg['init'], dir=workdir).name`
                     3. 设定移除前脚本以在包移除前停止服务：`if self.pkg.get('init-before-remove', True): command = command + "--before-remove %s " % OnlPackageBeforeRemoveScript(self.pkg['init'], dir=workdir).name`
                     4. 设定移除后脚本以在包完全移除后清理服务配置：`if self.pkg.get('init-after-remove', True): command = command + "--after-remove %s " % OnlPackageAfterRemoveScript(self.pkg['init'], dir=workdir).name`
                  10. 设定软件包的安装、卸载、升级过程中执行特定钩子脚本，配置为`cmd:script_path`，cmd如下: 
                      - 'before-install'
                      - 'after-install'
                      - 'before-upgrade'
                      - 'after-upgrade'
                      - 'before-remove'
                      - 'after-remove'
                      - 'deb-systemd': systemd script, systemd服务脚本, *.service
                  11. 为软件包生成ASR文档`asr`(AIM_SYSLOG_REFERENCE)，存放位置为：`"usr/share/doc/%(name)s/asr.json" % self.pkg`:
                      ```py
                      if self.pkg.get('asr', False):
                            with onlu.Profiler() as profiler:
                               # Generate the ASR documentation for this package.
                               sys.path.append("%s/sm/infra/tools" % os.getenv('ONL'))
                               import asr
                               asro = asr.AimSyslogReference()
                               asro.extract(workdir)
                               asro.format(os.path.join(docpath, asr.AimSyslogReference.ASR_NAME), 'json')
                            profiler.log("ASR generation for %(name)s" % self.pkg)
                      ```
                      - ASR是项目git子模块`infra`的AIM模块。该模块为其他模块提供基本的原始结构。一般来说，每个功能模块都力求做到平台无关，并提供简洁、自包含且灵活的接口，同时尽可能减少对特定环境部署的假设。AIM 模块提供可移植性基础设施、通用良好实践定义以及贯穿代码的基本原语，用于解决常见问题，例如调试和输出虚拟化、配置和日志记录等。AIM 模块不依赖任何其他模块或任何外部软件包。
                      - 待详细确认：若使用了AIM提供的日志记录功能（如onlp中packages/base/any/onlp/src/onlp/module/src/platform_manager.c），且配置了`asr: True`，将存在实际的供详细分析的`asr.json`日志文档。
                  12. 执行`fpm`debian包构建命令，生成deb包。
              12. 检查并拷贝deb包到dir_(OnlPackage().dir)目录下，即`builds`或`BUILDS`：查找工作目录`workdir`下的deb文件，判断是否只有一个文件，若不是则抛出异常，否则拷贝并移除整个工作目录`workdir`。
              13. 返回deb软件包路径`os.path.join(dir_, os.path.basename($PackageName))`















