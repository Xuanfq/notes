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
2. 生成版本文件：`make/versions/*`, 包括`version-onl.json  version-onl.mk  version-onl.sh  version-onl.yml`, (实际上make的时候会重新生成`make/config.mk`)
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





















