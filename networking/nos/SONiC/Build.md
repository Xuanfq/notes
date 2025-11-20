# Build

- [README of sonic-buildimage](https://github.com/sonic-net/sonic-buildimage/blob/master/README.md)


## Structure

- device/               # 设备特定配置相关文件
- files/                # 
- installer/            # 制作基于onie的安装器的相关文件
- src/                  # 通用软件组件源代码及其构建规则，包括子模块、复杂组件
- rules/                # 平台无关、供应商无关的的编译规则
- platform/             # 平台相关、供应商相关代码、配置以及编译规则
- dockers/              # 通用软件组件、各种服务的Dockerfile及配置
- scripts/              # 脚本工具
- sonic-slave-bookworm/ # 不同Debian版本的SONiC从机Docker构建环境
- sonic-slave-bullseye/
- sonic-slave-buster/
- sonic-slave-jessie/
- sonic-slave-stretch/  
- slave.mk              # 实际执行构建逻辑的 Makefile ，所有构建目标都能在这里找到
- Makefile              # Wrapper for `Makefile.work`
- Makefile.work         # Wrapper for all the mainly work and `slave.mk`
- Makefile.cache        # Wrapper cache work for `slave.mk`
- target/               # 编译结果
- build_debian.sh
- build_debug_docker_j2.sh
- build_docker.sh
- build_image.sh
- check_install.py
- functions.sh
- get_docker-base.sh
- install_sonic.py
- onie-image-arm64.conf
- onie-image-armhf.conf
- onie-image.conf
- onie-mk-demo.sh
- push_docker.sh
- update_screen.sh


## Main Steps

```bash
# Ensure the 'overlay' module is loaded on your development system
sudo modprobe overlay

# Enter the source directory
cd sonic-buildimage

# (Optional) Checkout a specific branch. By default, it uses master branch.
# For example, to checkout the branch 201911, use "git checkout 201911"
git checkout [branch_name]

# Execute make init once after cloning the repo,
# or after fetching remote repo with submodule updates
make init

# Execute make configure once to configure ASIC
make configure PLATFORM=[ASIC_VENDOR]
# PLATFORM=barefoot
# PLATFORM=broadcom
# PLATFORM=marvell-prestera
# PLATFORM=marvell-teralynx
# PLATFORM=mellanox
# PLATFORM=centec
# PLATFORM=nephos
# PLATFORM=nvidia-bluefield
# PLATFORM=vs

# Build SONiC image with 4 jobs in parallel.
# Note: You can set this higher, but 4 is a good number for most cases
#       and is well-tested.
make SONIC_BUILD_JOBS=4 all
```





## Makefile


### 通用目标规则

- 使用%::模式规则匹配任意目标
  - 根据版本开关变量决定是否构建对应debian环境下的版本：
    - 默认构建buster、bullseye、bookworm
    - 默认不构建：jessie、stretch
  - 对于设置的debian环境的版本进行逐个构建：
    - 重试次数为0，但pipeline下默认为3
    - 主要命令为`./scripts/run_with_retry $(MAKE) EXTRA_DOCKER_TARGETS=$(notdir $@) BLDENV=$debianname -f Makefile.work $debianname`
      - `EXTRA_DOCKER_TARGETS=$(notdir $@)` 用于传递额外目标到docker编译环境
      - 在`jessie`时不存在参数`BLDENV=$debianname`，且默认不编译`jessie`


### make init

```bash
make init
```

- 实际调用: `$(MAKE) -f Makefile.work init`
- 实际功能: 
  - 克隆所有子模块代码: `$(Q)git submodule update --init --recursive`
  - 修复子模块中的 .git 文件，使其使用相对路径而不是绝对路径指向 Git 目录: `$(Q)git submodule foreach --recursive '[ -f .git ] && echo "gitdir: $$(realpath --relative-to=. $$(cut -d" " -f2 .git))" > .git'`
    - 当项目被克隆到不同的位置时，绝对路径可能会失效，而相对路径则能保持有效。
    - 在某些 CI/CD 环境或容器化部署中，使用相对路径可以避免因路径变化导致的问题。
- 隐藏依赖项：Makefile.work:sonic-build-hooks
  - 执行`sonic-build-hooks`构建`src/sonic-build-hooks`生成`sonic-build-hooks_1.0_all.deb`
  - 存放到`sonic-slave-*/buildinfo/`下用于docker构建时使用


### make configure

```bash
make configure PLATFORM=[ASIC_VENDOR]
```

- 依赖项: 
  - `ASIC_VENDOR` 私有代码克隆
    - `ASIC_VENDOR` 私有代码配置位于`platform/checkout/`目录下的：
      - 文件`$(PLATFORM).ini`
      - 文件`$(PLATFORM)-smartswitch.ini`: 需配置参数`SMARTSWITCH=1`, e.g. `make configure PLATFORM=[ASIC_VENDOR] SMARTSWITCH=1`
    - 当前(202508)仅存在以下`ASIC_VENDOR`存在私有代码：
      - cisco-8000
      - pensando
    - 这些代码一般会被克隆到`platform/$(PLATFORM)`获其子目录
- 对于设置的需要编译的不同的debian版本进行逐个配置：
  - 实际调用`BLDENV=$debianname $(MAKE) -f Makefile.work $@`





## Makefile.work

在 Makefile.work 中，执行顺序如下：


### 支持的参数说明

> Reference `Makefile.work` 头部注释


- **`PLATFORM`**：指定待构建镜像对应的目标平台。
- **`BUILD_NUMBER`**：传递给构建系统的目标版本号。
- **`ENABLE_ZTP`**：启用零接触配置（Zero Touch Provisioning，ZTP）功能。
- **`SHUTDOWN_BGP_ON_START`**：重启后将所有BGP（边界网关协议）对等连接设置为“管理性关闭”状态。
- **`INCLUDE_KUBERNETES`**：允许在构建中集成Kubernetes（容器编排平台）。
- **`INCLUDE_KUBERNETES_MASTER`**：允许在构建中集成Kubernetes主节点组件。
- **`INCLUDE_MUX`**：为TOR交换机（Top of Rack Switch，架顶交换机）集成MUX（多路复用器）功能/服务。
- **`ENABLE_PFCWD_ON_START`**：默认情况下，为TOR交换机的“面向服务器端口”启用PFC监控器（PFC Watchdog，PFCWD）功能。
- **`ENABLE_SYNCD_RPC`**：启用基于RPC（远程过程调用）的syncd构建（syncd是SONiC中负责交换机ASIC配置同步的核心进程）。
- **`INSTALL_DEBUG_TOOLS`**：安装调试工具及调试符号包（含调试信息的软件包，用于问题排查）。
- **`USERNAME`**：目标用户名——默认值在rules/config配置文件中定义。
- **`PASSWORD`**：目标密码——默认值在rules/config配置文件中定义。
- **`KEEP_SLAVE_ON`**：构建流程结束后，保持从容器（slave container）处于启动并活跃状态。  
  注意：rm=true（容器退出后自动删除）仍会生效，因此当用户退出Docker会话后，该容器将被删除。  
  请注意，在当前Stretch版本的构建架构下，使用KEEP_SLAVE_ON功能的用户需注意：构建完成后需明确希望留在哪个Docker容器内。  
  - 若希望留在Jessie版本的Docker容器内，请执行命令：`make KEEP_SLAVE_ON=yes jessie`  
  - 若希望留在Stretch版本的Docker容器内，请执行命令：`make NOJESSIE=1 KEEP_SLAVE_ON=yes <任意目标>`
- **`SOURCE_FOLDER`**：主机（host）上待挂载到容器内`/var/$(USER)/src`路径的目录路径，仅当`KEEP_SLAVE_ON=yes`时生效。
- **`SONIC_BUILD_JOBS`**：指定构建过程中可并发运行的任务数量。
- **`VS_PREPARE_MEM`**：在VS（通常指Virtual Switch，虚拟交换机）构建中预处理内存（释放缓存并压缩内存）。  
  默认值：yes（启用）  
  可选值：yes（启用）、no（禁用）
- **`KERNEL_PROCURE_METHOD`**：指定获取内核Debian包的方式：download（下载）或build（本地构建）。
- **`ENABLE_TRANSLIB_WRITE`**：通过gNMI接口（谷歌网络配置接口）启用translib（SONiC中负责配置转换的库）的写入/配置操作。  
  默认值：unset（未启用）  
  可选值：y（启用）
- **`ENABLE_NATIVE_WRITE`**：通过gNMI接口启用原生（native）写入/配置操作（不依赖translib转换）。  
  默认值：unset（未启用）  
  可选值：y（启用）
- **`ENABLE_DIALOUT`**：在遥测（telemetry）功能中启用dialout客户端（主动推送数据的遥测模式）。  
  默认值：unset（未启用）  
  可选值：y（启用）
- **`SONIC_DPKG_CACHE_METHOD`**：指定从缓存获取Debian包的方式：none（不使用缓存）或cache（使用缓存）。
- **`SONIC_DPKG_CACHE_SOURCE`**：当启用Debian包缓存时，指定缓存文件的存储位置。
- **`BUILD_LOG_TIMESTAMP`**：设置构建日志中是否包含时间戳，可选值：simple（简单时间戳）、none（无时间戳）。
- **`DOCKER_EXTRA_OPTS`**：为在从容器内运行的dockerd（Docker守护进程）指定额外的命令行参数。
- **`ENABLE_AUTO_TECH_SUPPORT`**：启用“事件驱动型技术支持（techsupport）及核心转储（coredump）管理”功能的配置。  
  默认值：y（启用）  
  可选值：y（启用）、n（禁用）
- **`INCLUDE_BOOTCHART`**：安装SONiC bootchart工具（用于记录系统启动过程的性能分析工具）。  
  默认值：y（安装）  
  可选值：y（安装）、n（不安装）
- **`ENABLE_BOOTCHART`**：启用SONiC bootchart工具的运行（记录系统启动流程）。  
  默认值：n（禁用）  
  可选值：y（启用）、n（禁用）
- **`UNATTENDED`**：不等待终端的交互式输入，将此参数设为任意值均可启用该模式。  
  默认值：unset（未启用，即需要交互式输入）  
  可选值：y（启用无交互模式）
- **`SONIC_PTF_ENV_PY_VER`**：指定PTF镜像（Packet Test Framework，数据包测试框架镜像）使用的Python版本。  
  默认值：mixed（混合模式，同时支持Python 2和3）  
  可选值：mixed（混合模式）、py3（仅Python 3）
- **`ENABLE_MULTIDB`**：启用多个Redis数据库实例（Redis是SONiC中用于存储配置和状态的内存数据库）。  
  默认值：unset（未启用，仅单实例）  
  可选值：y（启用多实例）


**补充说明（关键术语背景）**

1. **SONiC相关核心术语**  
   - **syncd**：SONiC（Software for Open Networking in the Cloud，云开放网络软件）的核心进程，负责将上层配置转换为交换机ASIC（专用集成电路）可识别的指令，实现硬件转发规则的同步。  
   - **TOR交换机**：架顶交换机，部署在服务器机柜顶部，直接连接服务器，是数据中心网络的“接入层”设备，MUX功能常用于其端口多路复用场景。  
   - **gNMI接口**：谷歌定义的网络配置接口（gRPC Network Management Interface），基于gRPC协议，用于统一管理网络设备的配置和状态。  

2. **系统/工具相关术语**  
   - **Debian包**：以`.deb`为后缀的软件包格式，用于Debian、Ubuntu及SONiC（基于Debian衍生）等系统，`KERNEL_PROCURE_METHOD`和`SONIC_DPKG_CACHE_METHOD`均围绕Debian包的获取逻辑设计。  
   - **PTF**：数据包测试框架，常用于验证交换机的数据转发功能（如二层转发、VLAN隔离等），`SONIC_PTF_ENV_PY_VER`用于适配不同Python版本的测试脚本。  
   - **Redis多实例（MULTIDB）**：SONiC默认用单个Redis实例存储配置，启用多实例后可将不同类型的数据（如端口配置、路由表、遥测数据）拆分到不同实例，提升稳定性和性能。  

3. **参数设计逻辑**  
   这些参数可分为三类：  
   - **环境配置类**（如`PLATFORM`、`SOURCE_FOLDER`）：定义构建的基础环境；  
   - **功能开关类**（如`ENABLE_ZTP`、`INCLUDE_KUBERNETES`）：控制是否集成特定功能；  
   - **行为控制类**（如`SONIC_BUILD_JOBS`、`UNATTENDED`）：调整构建过程的性能（并发数）或交互模式。  
   所有参数的默认值均在`rules/config`等配置文件中定义，通过命令行赋值（如`make ENABLE_ZTP=y target`）可临时覆盖默认值，满足定制化构建需求。




### 执行流程和阶段

#### 1. 初始化阶段

在 Makefile 执行的最开始，会进行一系列的初始化设置：

1. **环境变量设置**：
   - 设置 SHELL 为 `/bin/bash`
   - 获取当前用户信息 (`USER`, `PWD`, `USER_LC`)
   - 检测系统架构 (DOCKER_MACHINE, COMPILE_HOST_ARCH): arm64(aarch64) armhf(armv7l|armv8l) amd64

2. **依赖检查**：
   - 检查用户是否为 root（如果是则报错）
   - 检查 j2 模板工具是否安装
   - 检查 Docker 版本是否符合要求

3. **构建环境配置**：
   - 设置 `CONFIGURED_ARCH` 和 `CONFIGURED_PLATFORM`
   - 根据 BLDENV 设置 `SLAVE_DIR` = sonic-slave-xxx（从机构建目录）
   - 根据 CONFIGURED_ARCH 设置 `TARGET_BOOTLOADER`: grub(amd64) uboot(arm*)


#### 2. 配置文件处理阶段

1. **包含配置文件**：
   - 包含 `rules/config`、`rules/config.user`(Option, 默认不存在) 和 `rules/sonic-fips.mk`(一种安全模式，美国联邦信息处理标准，默认包含该功能但不激活): 按顺序覆盖
     - 编译配置基本均位于`rules/config`，可通过自定义`rules/config.user`进行覆盖
   - 设置 DEFAULT_CONTAINER_REGISTRY ENABLE_DOCKER_BASE_PULL 等变量
     - DEFAULT_CONTAINER_REGISTRY: 容器仓库地址，默认 publicmirror.azurecr.io
     - ENABLE_DOCKER_BASE_PULL: 是否拉取启用sonic-slave docker的拉取，默认为否

2. **架构相关配置**：
   - 根据 CONFIGURED_ARCH 和 COMPILE_HOST_ARCH 设置:
     - SLAVE_BASE_IMAGE = $(SLAVE_DIR) | $(SLAVE_DIR)-march-$(CONFIGURED_ARCH) (其他未知架构)
     - MULTIARCH_QEMU_ENVIRON = y|n
     - CROSS_BUILD_ENVIRON = y|n
   - 计算 SLAVE_IMAGE 和 DOCKER_ROOT
     - SLAVE_IMAGE = $(SLAVE_BASE_IMAGE)-$(USER_LC)
     - DOCKER_ROOT = $(PWD)/fsroot.docker.$(BLDENV)

3. **FIPS 配置检查**：
   - 检查 INCLUDE_FIPS 和 ENABLE_FIPS 的兼容性

4. **其他**：
   - SONIC_VERSION_CACHE_METHOD ?= none
   - export `SONIC_VERSION_CACHE_SOURCE` ?= $(SONIC_DPKG_CACHE_SOURCE)/vcache
   - export `SONIC_VERSION_CACHE`: 根据SONIC_VERSION_CACHE_METHOD设置，默认为空
   - `SONIC_OVERRIDE_BUILD_VARS`: 包括变量 SONIC_VERSION_CACHE SONIC_VERSION_CACHE_SOURCE
     - *该变量可以传递`自定义参数设定`到`编译命令`中*
     - Makefile中: `override SONIC_OVERRIDE_BUILD_VARS += $(SONIC_BUILD_VARS)`，所以通过编译命令传入的方式应该是`make SONIC_BUILD_VARS=xxxx target`


#### 3. 构建信息生成阶段

1. **版本控制信息生成**：
   - 设置 SONIC_VERSION_CACHE 相关变量 (见上方)
   - 执行 `scripts/generate_buildinfo_config.sh` 生成版本控制构建信息 `sonic-slave-*/buildinfo/config/buildinfo.config`

2. **Dockerfile 生成**：
   - 使用 Dockerfile.j2 模板生成 `$(SLAVE_DIR)/Dockerfile`
   - 使用 Dockerfile.user.j2 模板生成 `$(SLAVE_DIR)/Dockerfile.user`
   - 执行 `scripts/build_mirror_config.sh` 生成镜像配置：
     - 通过以下逐层覆盖的模板生成APT镜像源: `sonic-slave-*/sources.list.$ARCHITECTURE`
       - `files/apt/sources.list.j2`
       - `files/apt/sources.list.$ARCHITECTURE.j2`
       - `sonic-slave-*/sources.list.j2`
       - `sonic-slave-*/sources.list.$ARCHITECTURE.j2`
     - 通过以下逐层覆盖的模板生成APT重试次数配置: `sonic-slave-*/apt-retries-count`
       - `files/apt/apt-retries-count`
     - 若设置`MIRROR_SNAPSHOT=y`(默认为n)：
       - 注释掉所有「不是 packages.trafficmanager.net 域名」的`sources.list.$ARCHITECTURE`软件源
       - 应用或生成`target/versions/default/versions-mirror`软件源
   - 执行 `scripts/prepare_docker_buildinfo.sh` 生成构建信息：
     - 修改 Dockerfile
       - 插入 `buildinfo` 及 `target/vcache` 等文件映射
       - 插入 `sonic-build-hooks_1.0_all.deb` 安装命令 (后续构建，见下方`sonic-build-hooks`)
       - 插入 `sonic-build-hooks_1.0_all.deb` 中的 `post_run_buildinfo` 及 `post_run_cleanup` 钩子到尾部
     - 执行 `scripts/versions_manager.py` 生成版本锁定文件 `sonic-slave-*/buildinfo/versions/versions-*`
     - 生成 `target/vcache/sonic-slave-*/` 及 `sonic-slave-*/vcache/`

    ```
    /* "# *" 为生成文件 */
    sonic-slave-*/
    ├── Dockerfile                        # *
    ├── Dockerfile.j2
    ├── Dockerfile.user                   # *
    ├── Dockerfile.user.j2
    ├── apt-retries-count                 # *
    ├── buildinfo                         # *
    │   ├── config
    │   │   └── buildinfo.config
    │   ├── sonic-build-hooks_1.0_all.deb (from `sonic-build-hooks`)
    │   └── versions
    │       ├── versions-deb
    │       ├── versions-docker
    │       ├── versions-git
    │       ├── versions-mirror
    │       └── versions-web
    ├── no-check-valid-until
    ├── sonic-jenkins-id_rsa.pub
    ├── sources.list.amd64                # *
    └── vcache/                           # *

    target/                               # *
    ├── vcache
    │   └── sonic-slave-*/
    └── versions
        └── default
            └── versions-docker.log
    ```

3. **Docker 镜像标签计算**：
   - 计算 SLAVE_BASE_TAG 和 SLAVE_TAG ，使用 sha1sum 对 SLAVE_DIR 关键文件内容进行计算，以此避免多次构建slave容器
   - 定义 COLLECT_DOCKER 命令 (`scripts/collect_docker_version_files.sh`)


#### 4. Docker 运行环境配置阶段

1. **OVERLAY 模块检查**：
   - 定义 OVERLAY_MODULE_CHECK 命令，检查 overlay 文件系统模块是否加载

2. **Docker 锁文件设置**：
   - 设置 DOCKER_LOCKDIR 和 DOCKER_LOCKFILE_SAVE
   - 创建 DOCKER_ROOT 目录

3. **DOCKER_RUN 命令构建**：
   - 定义基本的 DOCKER_RUN 命令
   - 根据各种条件添加挂载点和环境变量

4. **多架构环境配置**：
   - 如果是多架构或交叉编译环境，设置相关变量和命令
   - 定义 DOCKER_MULTIARCH_CHECK、DOCKER_SERVICE_MULTIARCH_CHECK 等命令


#### 5. 构建命令定义阶段

1. **Docker 构建命令定义**：
   - 定义 DOCKER_SLAVE_BASE_BUILD、DOCKER_BASE_PULL、DOCKER_USER_BUILD 等命令
   - 定义 DOCKER_SLAVE_BASE_INSPECT、DOCKER_SLAVE_BASE_PULL_REGISTRY 等检查命令
   - 定义 SONIC_SLAVE_BASE_BUILD 和 SONIC_SLAVE_USER_BUILD 复合命令

2. **构建指令定义**：
   - 定义 `SONIC_BUILD_INSTRUCTION` ，包含所有构建参数和变量
     - `slave.mk`
       - include:
         - `rules/config`
         - `rules/config.user` (if exist, default is not exist)
         - `rules/functions`
         - `rules/*.mk`
         - `platform/pddf/rules.mk` (PDDF_SUPPORT=y, default is y, else `platform/$PLATFORM/rules.mk`)
         - `Makefile.cache`


#### 6. 目标规则定义阶段

1. **模式规则**：

   - 通过模式规则 `%:: | sonic-build-hooks` 处理任意目标，先执行 `sonic-build-hooks`
   - 执行环境检查 `DOCKER_MULTIARCH_CHECK` `DOCKER_SERVICE_MULTIARCH_CHECK` `OVERLAY_MODULE_CHECK`(检查系统是否支持overlay模块) 等
   - 构建编译容器 `SONIC_SLAVE_BASE_BUILD` 和 `SONIC_SLAVE_USER_BUILD` (检查Docker镜像，不满足时构建)
   - **运行 `DOCKER_RUN` 命令执行构建指令**
     - 实际是切换到Docker环境，使用 `$(MAKE) -f slave.mk ... $@ SONIC_BUILD_TARGET=$@; $(COLLECT_BUILD_VERSION); $(SLAVE_SHELL)` 命令进行构建
   - 最后执行 `docker-image-cleanup`

   ```makefile
   %:: | sonic-build-hooks
   ifneq ($(filter y, $(MULTIARCH_QEMU_ENVIRON) $(CROSS_BUILD_ENVIRON)),)
   	$(Q)$(DOCKER_MULTIARCH_CHECK)
   ifneq ($(BLDENV), )
   	$(Q)$(DOCKER_SERVICE_MULTIARCH_CHECK)
   	$(Q)$(DOCKER_SERVICE_DOCKERFS_CHECK)
   endif
   endif
   	$(Q)$(OVERLAY_MODULE_CHECK)
   	$(Q)$(SONIC_SLAVE_BASE_BUILD)
   	$(Q)$(SONIC_SLAVE_USER_BUILD)
   
   	$(Q)$(DOCKER_RUN) \
   		$(SLAVE_IMAGE):$(SLAVE_TAG) \
   		bash -c "$(SONIC_BUILD_INSTRUCTION) $@ SONIC_BUILD_TARGET=$@; $(COLLECT_BUILD_VERSION); $(SLAVE_SHELL)"
   	$(Q)$(docker-image-cleanup)
   ```


2. **特定目标规则**：

   - `sonic-build-hooks`：构建钩子目标
   - `sonic-slave-base-build`：构建基础从机镜像
   - `sonic-slave-build`：构建用户从机镜像
   - `sonic-slave-bash`：启动从机容器并进入 `bash`
   - `sonic-slave-run`：在从机容器中运行特定命令，命令通过 `SONIC_RUN_CMDS` 参数指定
   - `showtag`：显示镜像标签，包括 `$(SLAVE_IMAGE):$(SLAVE_TAG)` 及 `$(SLAVE_BASE_IMAGE):$(SLAVE_BASE_TAG)`
   - `init`：初始化 Git 子模块
   - `reset`：重置代码库状态
   - 执行特定目标前先执行 `sonic-build-hook`


### 执行流程和阶段总结

当执行一个 make 命令（如 `make configure PLATFORM=broadcom`）时，执行流程如下：

1. **初始化阶段**：设置环境变量，检查依赖
2. **配置文件处理**：加载配置，设置架构相关变量
3. **构建信息生成**：生成版本信息、Dockerfile 和镜像标签
4. **Docker 运行环境配置**：设置 Docker 运行命令和相关检查
5. **构建命令定义**：定义各种构建和检查命令
6. **目标规则匹配**：
   - 首先执行 `sonic-build-hooks` 目标
     - 编译源码`src/sonic-build-hooks`生成`sonic-build-hooks_1.0_all.deb`，并拷贝到`SLAVE_DIR(sonic-slave-$debianname)/buildinfo/`下
   - 然后执行目标
     - 模式规则：执行 `%::` 中的命令序列，然后执行 `docker-image-cleanup` 清理资源
     - 特定规则：执行特定规则中的命令



## slave.mk


**slave.mk**是构建系统的核心组件，位于项目根目录下。根据源码分析，它的主要职责包括：

1. **定义构建环境与变量**：设置Shell环境、版本号、路径等基础变量
2. **实现目标组规则**：为各种构建目标提供通用构建逻辑
3. **管理依赖关系**：处理包间依赖，确保正确的构建顺序
4. **构建Docker镜像**：生成、加载和保存各种Docker镜像
5. **构建安装程序**：生成最终的SONiC系统镜像



### 源码分析

#### 1. 预设设置

主要包含了构建环境的基本设置：

- **设置Makefile规则在单一shell进程中执行**: `.ONESHELL:`
  - 通常Makefile默认会为每个命令行启动新的shell进程
  - 使用.ONESHELL后，同一规则中的所有命令会在同一个shell中执行，共享环境变量和工作目录
  - 这对于需要保持状态（如变量设置、目录切换）的复杂构建步骤非常重要
- **指定使用bash作为shell解释器**: `SHELL = /bin/bash`
  - Make默认使用系统shell（通常是/bin/sh）, 显式指定bash可以利用bash特有的功能（如数组、高级条件判断等）
- **给shell添加-e选项，使脚本遇到错误时立即退出**: `.SHELLFLAGS += -e`

- **设定当前用户的信息**: 
  - `USER = $(shell id -un)`
  - `UID = $(shell id -u)`
  - `GUID = $(shell id -g)`

- **设置镜像版本**: 若镜像版本`SONIC_IMAGE_VERSION`未设置，则通过调用函数生成版本号
  - `override SONIC_IMAGE_VERSION := $(shell export BUILD_TIMESTAMP=$(BUILD_TIMESTAMP) && export BUILD_NUMBER=$(BUILD_NUMBER) && . functions.sh && sonic_get_version)`

- **启用延迟变量展开机制**: `.SECONDEXPANSION:`
  - 允许在规则的依赖部分使用二次展开变量
  - 这对于需要在第一次展开后再次展开的复杂变量引用非常有用
  - 常用于动态生成依赖项的场景

- **定义通用辅助变量**: NULL 和 SPACE
  - `NULL :=`
  - `SPACE := $(NULL) $(NULL)`



#### 2. 通用定义

- **各种目录路径**: 
  - `TARGET_PATH` = target
  - `PROJECT_ROOT` := $(shell pwd)
  - `BLDENV` := $(shell lsb_release -cs)
  - `DEBS_PATH` = $(TARGET_PATH)/debs/$(BLDENV)
  - `FILES_PATH` = $(TARGET_PATH)/files/$(BLDENV)
  - `PYTHON_DEBS_PATH` = $(TARGET_PATH)/python-debs/$(BLDENV)
  - `PYTHON_WHEELS_PATH` = $(TARGET_PATH)/python-wheels/$(BLDENV)
  - `${DEBIAN_VERSION_CODE_NAME}_DEBS_PATH` = $(TARGET_PATH)/debs/${lower_case DEBIAN_VERSION_CODE_NAME}
  - `${DEBIAN_VERSION_CODE_NAME}_FILES_PATH` = $(TARGET_PATH)/files/${lower_case DEBIAN_VERSION_CODE_NAME}
  - `IMAGE_DISTRO` := bookworm
  - `IMAGE_DISTRO_DEBS_PATH` = $(TARGET_PATH)/debs/$(IMAGE_DISTRO)
  - `IMAGE_DISTRO_FILES_PATH` = $(TARGET_PATH)/files/$(IMAGE_DISTRO)
  - `BUILD_WORKDIR` = /sonic
  - `DPKG_ADMINDIR_PATH` = $(BUILD_WORKDIR)/dpkg
  - `SLAVE_DIR` ?= sonic-slave-$(BLDENV)

- **DBG**: 
  - `DBG_IMAGE_MARK` = dbg
  - `DBG_SRC_ARCHIVE_FILE` = $(TARGET_PATH)/sonic_src.tar.gz

- **平台与架构相关**: 
  - `CONFIGURED_PLATFORM` = `$(if $(PLATFORM),$(PLATFORM),$(shell [ -f .platform ] && cat .platform || echo generic))`
  - `PLATFORM_PATH` = platform/$(CONFIGURED_PLATFORM)
  - `CONFIGURED_ARCH` := $(shell [ -f .arch ] && cat .arch || echo amd64)
  - `PLATFORM_ARCH`
    - `ifeq ($(PLATFORM_ARCH),) override PLATFORM_ARCH = $(CONFIGURED_ARCH)`
  - `DOCKER_BASE_ARCH` := $(CONFIGURED_ARCH)
    - `ifeq ($(CONFIGURED_ARCH),armhf) override DOCKER_BASE_ARCH = arm32v7`
    - `ifeq ($(CONFIGURED_ARCH),arm64) override DOCKER_BASE_ARCH = arm64v8`

- **支持Python2与否**: bullseye bookworm 及以上不再支持
  - ENABLE_PY2_MODULES = y | n

- **PTF镜像的Python版本**: rules/config 中配置的是`py3` (PTF即SONiC的Packet Testing Framework)
  - PTF_ENV_PY_VER = `$(if $(SONIC_PTF_ENV_PY_VER),$(SONIC_PTF_ENV_PY_VER),mixed)`
  - 用于 dockers/docker-ptf

- **导出一些环境变量**


#### 3. 规则定义


- **安装钩子deb包**: `sonic-build-hooks_1.0_all.deb`

- **定义`.platform`规则**: 检测是否配置平台 CONFIGURED_PLATFORM

- **定义`configure`规则**: 
  - 创建相关目录
  - 生成平台标志文件 - `echo $(PLATFORM) > .platform`
  - 生成架构标准文件 - `echo $(PLATFORM_ARCH) > .arch`

- **定义`distclean`规则**: 
  - 清理平台标志文件 - `rm -f .platform`
  - 清理架构标志文件 - `rm -f .arch`

- **定义`list`规则**: 列出所有SONiC目标规则
  - `$(Q)$(foreach target,$(SONIC_TARGET_LIST),echo $(target);)`

- **导入默认配置规则**: `$(RULES_PATH)/config`

- **导入用户配置规则**: `$(RULES_PATH)/config.user`


#### 4. 编译配置

- **版本控制相关变量导出**

- **根据`Makefile.work`以及`rules/config`的设定enable一些Feature及include一些Component**

- **导入`rules`目录下的函数`functions`规则**: `include $(RULES_PATH)/functions`

- **导入`rules`目录下的所有`*.mk`规则**: `include $(RULES_PATH)/*.mk`

- **导入`PDDF`框架规则**: `include $(PLATFORM_PDDF_PATH=platfrom/pddf)/rules.mk`

- **导入指定平台`platfrom`规则**: `include $(PLATFORM_PATH=platform/xxx)/rules.mk`
  - **终极目标`SONIC_ALL`**: `SONIC_ALL += $(SONIC_ONE_IMAGE) $(SONIC_ONE_ABOOT_IMAGE) $(DOCKER_FPM)`
  - **通用导入**: Example broadcom
    ```makefile
    include $(PLATFORM_PATH)/sai-modules.mk
    include $(PLATFORM_PATH)/sai.mk
    include $(PLATFORM_PATH)/sswsyncd.mk
    include $(PLATFORM_PATH)/docker-syncd-brcm.mk
    include $(PLATFORM_PATH)/docker-syncd-brcm-rpc.mk
    include $(PLATFORM_PATH)/docker-saiserver-brcm.mk
    include $(PLATFORM_PATH)/one-image.mk
    include $(PLATFORM_PATH)/raw-image.mk
    include $(PLATFORM_PATH)/one-aboot.mk
    include $(PLATFORM_PATH)/libsaithrift-dev.mk
    include $(PLATFORM_PATH)/docker-syncd-brcm-dnx.mk
    include $(PLATFORM_PATH)/docker-syncd-brcm-dnx-rpc.mk
    include $(PLATFORM_PATH)/docker-pde.mk [Option by INCLUDE_PDE]
    include $(PLATFORM_PATH)/sonic-pde-tests.mk [Option by INCLUDE_PDE]
    include $(PLATFORM_PATH)/../components/docker-gbsyncd-credo.mk [Option by INCLUDE_GBSYNCD]
    include $(PLATFORM_PATH)/../components/docker-gbsyncd-broncos.mk [Option by INCLUDE_GBSYNCD]
    include $(PLATFORM_PATH)/../components/docker-gbsyncd-milleniob.mk [Option by INCLUDE_GBSYNCD]
    ```
  - **平台实现导入**:
    ```makefile
    include $(PLATFORM_PATH)/platform-modules-*.mk
    ```

- **设定交叉编译等编译相关环境**

- **输出关键的编译配置属性**

- **定义`SONIC_RFS_TARGETS`相关目标规则**

- **导入`Makefile.cache`**: 通过`$(RULES_PATH)/*.dep`识别依赖和缓存。
  - **导入`rules`目录下的所有依赖**: `include $(RULES_PATH)/*.dep`
  - **导入`PDDF`框架依赖**: `include $(PLATFORM_PDDF_PATH)/rules.dep`
  - **导入指定平台`platfrom`依赖**: `-include $(PLATFORM_PATH)/rules.dep`



#### 5. 构建目标类型与分组

> Reference [README.buildsystem.md](https://github.com/sonic-net/sonic-buildimage/blob/master/README.buildsystem.md)

**关键术语解析**  

- **.deb 包**：Debian 系列操作系统（如 Ubuntu）的标准软件包格式，此处指 SONIC 系统中需构建或安装的软件包。  
- **buildimage**：SONIC 构建流程中的核心镜像，用于提供编译、打包所需的环境和工具链。  
- **Python wheels（.whl）**：Python 的二进制包格式，可直接安装，无需编译源码，此处用于向 Docker 镜像中添加 Python 依赖。  
- **运行时依赖（RDEPENDS）vs 构建依赖（DEPENDS）**：  
  - 构建依赖：仅在软件包**编译构建阶段**需要（如编译器、依赖的源码库）；  
  - 运行时依赖：软件包**安装运行阶段**必须存在的依赖（如依赖的库文件、其他软件）。 


##### **SONIC_DPKG_DEBS**

构建 .deb 软件包的主要目标组。  

定义方式如下：

```makefile
SOME_NEW_DEB = some_new_deb.deb # 你的软件包名称
$(SOME_NEW_DEB)_SRC_PATH = $(SRC_PATH)/project_name # 源代码所在目录的路径
$(SOME_NEW_DEB)_DEPENDS = $(SOME_OTHER_DEB1) $(SOME_OTHER_DEB2) ... # 构建依赖（编译时所需依赖）
$(SOME_NEW_DEB)_RDEPENDS = $(SOME_OTHER_DEB1) $(SOME_OTHER_DEB2) ... # 运行时依赖（软件运行时所需依赖）
SONIC_DPKG_DEBS += $(SOME_NEW_DEB) # 将软件包添加到该目标组
```

构建原理: `slave.mk`
```makefile
# Build project with dpkg-buildpackage
# ...
		$(if $($*_DPKG_TARGET),
			${$*_BUILD_ENV} DEB_BUILD_OPTIONS="${DEB_BUILD_OPTIONS_GENERIC} ${$*_DEB_BUILD_OPTIONS}" DEB_BUILD_PROFILES="${$*_DEB_BUILD_PROFILES}" $(ANT_DEB_CONFIG) $(CROSS_COMPILE_FLAGS) timeout --preserve-status -s 9 -k 10 $(BUILD_PROCESS_TIMEOUT) dpkg-buildpackage -rfakeroot -b $(ANT_DEB_CROSS_OPT) -us -uc -tc -j$(SONIC_CONFIG_MAKE_JOBS) --as-root -T$($*_DPKG_TARGET) --admindir $$mergedir $(LOG),
			${$*_BUILD_ENV} DEB_BUILD_OPTIONS="${DEB_BUILD_OPTIONS_GENERIC} ${$*_DEB_BUILD_OPTIONS}" DEB_BUILD_PROFILES="${$*_DEB_BUILD_PROFILES}" $(ANT_DEB_CONFIG) $(CROSS_COMPILE_FLAGS) timeout --preserve-status -s 9 -k 10 $(BUILD_PROCESS_TIMEOUT) dpkg-buildpackage -rfakeroot -b $(ANT_DEB_CROSS_OPT) -us -uc -tc -j$(SONIC_CONFIG_MAKE_JOBS) --admindir $$mergedir $(LOG)
		)
```



##### **SONIC_PYTHON_STDEB_DEBS**

与上述目标组功能相同，区别在于：它不使用 `dpkg-buildpackage` 工具构建软件包，而是执行 `python setup.py --command-packages=stdeb.command bdist_deb` 命令（适用于 Python 项目的 .deb 包构建）。

定义方式如下：

```makefile
SOME_NEW_DEB = some_new_deb.deb # 你的软件包名称
$(SOME_NEW_DEB)_SRC_PATH = $(SRC_PATH)/project_name # 源代码所在目录的路径
$(SOME_NEW_DEB)_DEPENDS = $(SOME_OTHER_DEB1) $(SOME_OTHER_DEB2) ... # 构建依赖
$(SOME_NEW_DEB)_RDEPENDS = $(SOME_OTHER_DEB1) $(SOME_OTHER_DEB2) ... # 运行时依赖
SONIC_PYTHON_STDEB_DEBS += $(SOME_NEW_DEB) # 将软件包添加到该目标组
```

构建原理: `slave.mk`
```makefile
# Build project with python setup.py --command-packages=stdeb.command
# ...
		python setup.py --command-packages=stdeb.command bdist_deb $(LOG)
```



##### **SONIC_PYTHON_WHEELS**

与上述目标组功能相同，区别在于：它不使用 `--command-packages=stdeb.command bdist_deb` 构建Python包，而是执行 `python setup.py bdist_wheel` 命令（适用于 Python 项目的 .deb 包构建）。

定义方式如下：

```makefile
SOME_NEW_WHL = some_new_whl.whl # 你的软件包名称
$(SOME_NEW_WHL)_SRC_PATH = $(SRC_PATH)/project_name # 源代码所在目录的路径
$(SOME_NEW_WHL)_PYTHON_VERSION = 2 (or 3)
$(SOME_NEW_WHL)_DEPENDS = $(SOME_OTHER_WHL1) $(SOME_OTHER_WHL2) ... # 构建依赖
SONIC_PYTHON_WHEELS += $(SOME_NEW_WHL)
```

构建原理: `slave.mk`
```makefile
# Build project using python setup.py bdist_wheel
# Projects that generate python wheels
# ...
ifneq ($(CROSS_BUILD_ENVIRON),y)
		# Use pip instead of later setup.py to install dependencies into user home, but uninstall self
		{ pip$($*_PYTHON_VERSION) install . && pip$($*_PYTHON_VERSION) uninstall --yes `python$($*_PYTHON_VERSION) setup.py --name`; } $(LOG)
ifeq ($(BLDENV),bookworm)
		if [ ! "$($*_TEST)" = "n" ]; then pip$($*_PYTHON_VERSION) install ".[testing]" && pip$($*_PYTHON_VERSION) uninstall --yes `python$($*_PYTHON_VERSION) setup.py --name` && timeout --preserve-status -s 9 -k 10 $(BUILD_PROCESS_TIMEOUT) python$($*_PYTHON_VERSION) -m pytest; fi $(LOG)
		python$($*_PYTHON_VERSION) -m build -n $(LOG)
else
		if [ ! "$($*_TEST)" = "n" ]; then timeout --preserve-status -s 9 -k 10 $(BUILD_PROCESS_TIMEOUT) python$($*_PYTHON_VERSION) setup.py test $(LOG); fi
		python$($*_PYTHON_VERSION) setup.py bdist_wheel $(LOG)
endif
else
		{
			export PATH=$(VIRTENV_BIN_CROSS_PYTHON$($*_PYTHON_VERSION)):${PATH}
			python$($*_PYTHON_VERSION) setup.py build $(LOG)
			if [ ! "$($*_TEST)" = "n" ]; then timeout --preserve-status -s 9 -k 10 $(BUILD_PROCESS_TIMEOUT) python$($*_PYTHON_VERSION) setup.py test $(LOG); fi
			python$($*_PYTHON_VERSION) setup.py bdist_wheel $(LOG)
		}
endif
```




##### **SONIC_MAKE_DEBS**

此目标组灵活性更高。

若你需要执行特定类型的构建操作，或在构建前对路径进行自定义配置，只需定义自己的 Makefile 并将其添加到 `buildimage`（SONIC 构建镜像流程）中即可。

定义方式如下：

```makefile
SOME_NEW_DEB = some_new_deb.deb # 你的软件包名称
$(SOME_NEW_DEB)_SRC_PATH = $(SRC_PATH)/project_name # 源代码所在目录的路径
$(SOME_NEW_DEB)_DEPENDS = $(SOME_OTHER_DEB1) $(SOME_OTHER_DEB2) ... # 构建依赖
$(SOME_NEW_DEB)_RDEPENDS = $(SOME_OTHER_DEB1) $(SOME_OTHER_DEB2) ... # 运行时依赖
SONIC_MAKE_DEBS += $(SOME_NEW_DEB) # 将软件包添加到该目标组
```

构建原理: `slave.mk`
```makefile
# Build project using build.sh script
# They are essentially a one-time build projects that get sources from some URL
# and compile them
# ...
		DEB_BUILD_OPTIONS="${DEB_BUILD_OPTIONS_GENERIC}" $(ANT_DEB_CONFIG) $(CROSS_COMPILE_FLAGS) make -j$(SONIC_CONFIG_MAKE_JOBS) DEST=$(shell pwd)/$(DEBS_PATH) -C $($*_SRC_PATH) $(shell pwd)/$(DEBS_PATH)/$* $(LOG)
```



##### **SONIC_MAKE_FILES**

此目标组灵活性更高。

若你需要执行特定类型的构建操作，或在构建前对路径进行自定义配置，只需定义自己的 Makefile 并将其添加到 `buildimage`（SONIC 构建镜像流程）中即可。

定义方式如下：

```makefile
SOME_NEW_FILE = some_new_deb.deb
$(SOME_NEW_FILE)_SRC_PATH = $(SRC_PATH)/project_name
$(SOME_NEW_FILE)_DEPENDS = $(SOME_OTHER_DEB1) $(SOME_OTHER_DEB2) ...
SONIC_MAKE_FILES += $(SOME_NEW_FILE)
```

构建原理: `slave.mk`
```makefile
# Build project using build.sh script
# They are essentially a one-time build projects that get sources from some URL
# and compile them
# ...
		make DEST=$(shell pwd)/$(FILES_PATH) -C $($*_SRC_PATH) $(shell pwd)/$(FILES_PATH)/$* $(LOG)
```



##### **SONIC_COPY_DEBS**

此类软件包将直接从你机器上的指定位置复制（无需构建）。

若部分软件包因法律问题需在本地构建，或已预先构建完成且可从网络获取，可使用这种方式。

定义方式如下：

```makefile
SOME_NEW_DEB = some_new_deb.deb # 你的软件包名称
$(SOME_NEW_DEB)_PATH = path/to/some_new_deb.deb # 软件包文件的路径
SONIC_COPY_DEBS += $(SOME_NEW_DEB) # 将软件包添加到该目标组
```

构建原理: `slave.mk`
```makefile
# Copy debian packages from local directory
# ...
		$(foreach deb,$* $($*_DERIVED_DEBS), \
			{ cp $($(deb)_PATH)/$(deb) $(DEBS_PATH)/ $(LOG) || exit 1 ; } ; )
```



##### **SONIC_COPY_FILES**

与上述目标组功能相同，区别在于：它适用于普通文件（非 .deb 包）。当你需要将普通文件复制到 Docker 容器中进行安装时，可使用此目标组。

若部分软件包因法律问题需在本地构建，或已预先构建完成且可从网络获取，可使用这种方式。

定义方式如下：  

```makefile
SOME_NEW_FILE = some_new_file # 你的文件名称
$(SOME_NEW_FILE)_PATH = path/to/some_new_file # 文件的路径
SONIC_COPY_FILES += $(SOME_NEW_FILE) # 将文件添加到该目标组
```

构建原理: `slave.mk`
```makefile
# Copy regular files from local directory
# ...
	cp $($*_PATH)/$* $(FILES_PATH)/ $(LOG) || exit 1
```



##### **SONIC_ONLINE_DEBS**

用于从在线源获取 .deb 软件包的目标组。

若部分软件包因法律问题需在本地构建，或已预先构建完成且可从网络获取，可使用这种方式。

定义方式如下：

```makefile
SOME_NEW_DEB = some_new_deb.deb # 你的软件包名称
$(SOME_NEW_DEB)_URL = https://url/to/this/deb.deb # 软件包的下载链接（URL）
SONIC_ONLINE_DEBS += $(SOME_NEW_DEB) # 将软件包添加到该目标组
```

构建原理: `slave.mk`
```makefile
# Download debian packages from online location
# ...
		$(foreach deb,$* $($*_DERIVED_DEBS), \
			{ SKIP_BUILD_HOOK=$($*_SKIP_VERSION) curl -L -f -o $(DEBS_PATH)/$(deb) $($(deb)_CURL_OPTIONS) $($(deb)_URL) $(LOG) || { exit 1 ; } } ; )
```



##### **SONIC_ONLINE_FILES**

用于从在线源获取普通文件的目标组。

若部分软件包因法律问题需在本地构建，或已预先构建完成且可从网络获取，可使用这种方式。

定义方式如下：

```makefile
SOME_NEW_FILE = some_new_file # 你的文件名称
$(SOME_NEW_FILE)_URL = https://url/to/this/file # 文件的下载链接（URL）
SONIC_ONLINE_FILES += $(SOME_NEW_FILE) # 将文件添加到该目标组
```

构建原理: `slave.mk`
```makefile
# Download regular files from online location
# Files are stored in deb packages directory for convenience
# ...
	SKIP_BUILD_HOOK=$($*_SKIP_VERSION) curl -L -f -o $@ $($*_CURL_OPTIONS) $($*_URL) $(LOG)
```



##### **SONIC_SIMPLE_DOCKER_IMAGES**

从名称可看出，此目标组用于通过常规 Dockerfile 构建 Docker 镜像（流程简单直接）。

定义方式如下：

```makefile
SOME_DOCKER = some_docker.gz # 你的 Docker 镜像名称（通常以 .gz 压缩格式存储）
$(SOME_DOCKER)_PATH = path/to/your/docker # 你的 Dockerfile 所在路径
SONIC_SIMPLE_DOCKER_IMAGES += $(SOME_DOCKER) # 将 Docker 镜像添加到该组
```

构建原理: `slave.mk`
```makefile
# targets for building simple docker images that do not depend on any debian packages
# ...
	# Prepare docker build info
	SONIC_ENFORCE_VERSIONS=$(SONIC_ENFORCE_VERSIONS) \
	TRUSTED_GPG_URLS=$(TRUSTED_GPG_URLS) \
	SONIC_VERSION_CACHE=$(SONIC_VERSION_CACHE) \
	DBGOPT='$(DBGOPT)' \
	scripts/prepare_docker_buildinfo.sh $* $($*.gz_PATH)/Dockerfile $(CONFIGURED_ARCH) $(TARGET_DOCKERFILE)/Dockerfile.buildinfo $(LOG)
	docker info $(LOG)
	docker build --squash --no-cache \
		--build-arg http_proxy=$(HTTP_PROXY) \
		--build-arg https_proxy=$(HTTPS_PROXY) \
		--build-arg no_proxy=$(NO_PROXY) \
		--build-arg user=$(USER) \
		--build-arg uid=$(UID) \
		--build-arg guid=$(GUID) \
		--build-arg docker_container_name=$($*.gz_CONTAINER_NAME) \
		--label Tag=$(SONIC_IMAGE_VERSION) \
		-f $(TARGET_DOCKERFILE)/Dockerfile.buildinfo \
		-t $(DOCKER_IMAGE_REF) $($*.gz_PATH) $(LOG)

	if [ x$(SONIC_CONFIG_USE_NATIVE_DOCKERD_FOR_BUILD) == x"y" ]; then docker tag $(DOCKER_IMAGE_REF) $*; fi
	SONIC_VERSION_CACHE=$(SONIC_VERSION_CACHE) ARCH=${CONFIGURED_ARCH} \
		DBGOPT='$(DBGOPT)' \
		scripts/collect_docker_version_files.sh $* $(TARGET_PATH) $(DOCKER_IMAGE_REF) $($*.gz_PATH) $(LOG)
```



##### **SONIC_DOCKER_IMAGES**

此目标组功能更复杂灵活。你可以指定从 `buildimage` 中获取并安装到当前镜像的 .deb 软件包，且对应的 Dockerfile 会从模板动态生成（适用于需自定义镜像内容的场景）。

定义方式如下：

```makefile
SOME_DOCKER = some_docker.gz # 你的 Docker 镜像名称
$(SOME_DOCKER)_PATH = path/to/your/docker # 你的 Dockerfile 所在路径
$(SOME_DOCKER)_DEPENDS += $(SOME_DEB1) $(SOME_DEB2) # 需安装到镜像中的 .deb 软件包
$(SOME_DOCKER)_PYTHON_WHEELS += $(SOME_WHL1) $(SOME_WHL2) # 需安装到镜像中的 Python 轮包（.whl 格式）
$(SOME_DOCKER)_LOAD_DOCKERS += $(SOME_OTHER_DOCKER) # 构建当前镜像所基于的基础 Docker 镜像
SONIC_DOCKER_IMAGES += $(SOME_DOCKER) # 将 Docker 镜像添加到该组
```

构建原理: `slave.mk`
```makefile
# Targets for building docker images
# ...
		# Prepare docker build info
		PACKAGE_URL_PREFIX=$(PACKAGE_URL_PREFIX) \
		SONIC_ENFORCE_VERSIONS=$(SONIC_ENFORCE_VERSIONS) \
		TRUSTED_GPG_URLS=$(TRUSTED_GPG_URLS) \
		SONIC_VERSION_CACHE=$(SONIC_VERSION_CACHE) \
		DBGOPT='$(DBGOPT)' \
		scripts/prepare_docker_buildinfo.sh $* $($*.gz_PATH)/Dockerfile $(CONFIGURED_ARCH) $(LOG)
		docker info $(LOG)
		docker build --no-cache $$( [[ "$($*.gz_SQUASH)" != n ]] && echo --squash)\
			--build-arg http_proxy=$(HTTP_PROXY) \
			--build-arg https_proxy=$(HTTPS_PROXY) \
			--build-arg no_proxy=$(NO_PROXY) \
			--build-arg user=$(USER) \
			--build-arg uid=$(UID) \
			--build-arg guid=$(GUID) \
			--build-arg docker_container_name=$($*.gz_CONTAINER_NAME) \
			--build-arg frr_user_uid=$(FRR_USER_UID) \
			--build-arg frr_user_gid=$(FRR_USER_GID) \
			--build-arg SONIC_VERSION_CACHE=$(SONIC_VERSION_CACHE) \
			--build-arg SONIC_VERSION_CACHE_SOURCE=$(SONIC_VERSION_CACHE_SOURCE) \
			--build-arg image_version=$(SONIC_IMAGE_VERSION) \
			--label com.azure.sonic.manifest="$$(cat $($*.gz_PATH)/manifest.json)" \
			--label Tag=$(SONIC_IMAGE_VERSION) \
		        $($(subst -,_,$(notdir $($*.gz_PATH)))_labels) \
			-t $(DOCKER_IMAGE_REF) $($*.gz_PATH) $(LOG)

		if [ x$(SONIC_CONFIG_USE_NATIVE_DOCKERD_FOR_BUILD) == x"y" ]; then docker tag $(DOCKER_IMAGE_REF) $*; fi
		SONIC_VERSION_CACHE=$(SONIC_VERSION_CACHE) ARCH=${CONFIGURED_ARCH}\
			DBGOPT='$(DBGOPT)' \
			scripts/collect_docker_version_files.sh $* $(TARGET_PATH) $(DOCKER_IMAGE_REF) $($*.gz_PATH) $($*.gz_PATH)/Dockerfile $(LOG)
		if [ ! -z $(filter $*.gz,$(SONIC_PACKAGES_LOCAL)) ]; then docker tag $(DOCKER_IMAGE_REF) $*:$(SONIC_IMAGE_VERSION); fi
```




#### 6. 安装程序构建

##### 根文件系统构建

./build_debian.sh


##### 安装器构建

./build_debian.sh
./build_image.sh


#### 7. 通用目标

##### all

**目标**:

- `all` (main) : Depend on `$$(SONIC_ALL)`
- bullseye
- buster
- stretch
- jessie

```makefile
all : .platform $$(addprefix $(TARGET_PATH)/,$$(SONIC_ALL))

bullseye : $$(addprefix $(TARGET_PATH)/,$$(BULLSEYE_DOCKER_IMAGES)) \
          $$(addprefix $(TARGET_PATH)/,$$(BULLSEYE_DBG_DOCKER_IMAGES))

buster : $$(addprefix $(TARGET_PATH)/,$$(BUSTER_DOCKER_IMAGES)) \
          $$(addprefix $(TARGET_PATH)/,$$(BUSTER_DBG_DOCKER_IMAGES))

stretch : $$(addprefix $(TARGET_PATH)/,$$(STRETCH_DOCKER_IMAGES)) \
          $$(addprefix $(TARGET_PATH)/,$$(STRETCH_DBG_DOCKER_IMAGES))

jessie : $$(addprefix $(TARGET_PATH)/,$$(JESSIE_DOCKER_IMAGES)) \
         $$(addprefix $(TARGET_PATH)/,$$(JESSIE_DBG_DOCKER_IMAGES))
```


##### clean

**目标**:

- `clean`
  - `clean-logs`
  - `clean-versions`
- `vclean`
- SONIC_CACHE_CLEAN_DEBS: `$(*_DEBS)-clean`
  - SONIC_ONLINE_DEBS
  - SONIC_COPY_DEBS
  - SONIC_MAKE_DEBS
  - SONIC_DPKG_DEBS
  - SONIC_DERIVED_DEBS
  - SONIC_EXTRA_DEBS
- SONIC_CACHE_CLEAN_FILES: `$(*_FILES)-clean`
  - SONIC_ONLINE_FILES
  - SONIC_COPY_FILES
  - SONIC_MAKE_FILES
- SONIC_CACHE_CLEAN_IMAGES: `$(*_FILES)-clean`
  - SONIC_DOCKER_IMAGES
  - SONIC_DOCKER_DBG_IMAGES
  - SONIC_SIMPLE_DOCKER_IMAGES
  - SONIC_RFS_TARGETS
  - SONIC_INSTALLERS
- SONIC_CACHE_CLEAN_STDEB_DEBS: `$(*_DEBS)-clean`
  - SONIC_PYTHON_STDEB_DEBS
- SONIC_CACHE_CLEAN_WHEELS: `$(*_WHEELS)-clean`
  - SONIC_PYTHON_WHEELS


```makefile
# 清理 Debian 包
SONIC_CLEAN_DEBS = $(addsuffix -clean,$(addprefix $(DEBS_PATH)/, \
	   $(SONIC_ONLINE_DEBS) \
	   $(SONIC_COPY_DEBS) \
	   $(SONIC_MAKE_DEBS) \
	   $(SONIC_DPKG_DEBS)))

# 清理文件
SONIC_CLEAN_FILES = $(addsuffix -clean,$(addprefix $(FILES_PATH)/, \
	   $(SONIC_ONLINE_FILES) \
	   $(SONIC_COPY_FILES)))

# 清理目标文件
SONIC_CLEAN_TARGETS += $(addsuffix -clean,$(addprefix $(TARGET_PATH)/, \
		   $(SONIC_DOCKER_IMAGES) \
		   $(SONIC_INSTALLERS)))

# 清理日志和版本文件
clean-logs :: .platform
	$(Q)rm -f $(TARGET_PATH)/*.log $(DEBS_PATH)/*.log

clean-versions :: .platform
	@rm -rf target/versions/*

vclean:: .platform
	@sudo rm -rf target/vcache/* target/baseimage*

# 主清理目标
clean :: .platform clean-logs clean-versions $$(SONIC_CLEAN_DEBS) $$(SONIC_CLEAN_FILES) $$(SONIC_CLEAN_TARGETS) $$(SONIC_CLEAN_STDEB_DEBS) $$(SONIC_CLEAN_WHEELS)
```



##### lib-packages

**目标**:

- `lib-packages` (main)

```makefile
## To build some commonly used libs. Some submodules depend on these libs.
## It is used in component pipelines. For example: swss needs libnl, libyang
lib-packages: $(addprefix $(DEBS_PATH)/,$(LIBNL3) $(LIBYANG) $(PROTOBUF) $(LIB_SONIC_DASH_API))
```



##### listall

**目标**:

- `listall`: 列出所有主要目标及其衍生目标，衍生目标需缩进显示。

```makefile
# Makefile.cache
listall :
	@$(foreach target,$(SONIC_TARGET_LIST),\
        $(eval DPKG:=$(lastword $(subst /, ,$(target)))) \
        $(eval PATH:= $(subst $(DPKG),,$(target))) \
        $(if $($(DPKG)_MAIN_DEB),,
			echo "[$(target)] "; \
            $(foreach pkg,$($(DPKG)_DERIVED_DEBS) $($(DPKG)_EXTRA_DEBS),\
				echo "     $(PATH)$(pkg)"; \
             )\
         )\
      )
```



##### show-*

**目标**:

- `show-*`: 显示主要目标(见listall)的相关信息

```makefile
# Makefile.cache
#$(addprefix show-,$(SONIC_TARGET_LIST)):show-%:
show-%:
	@$(foreach target,$(SONIC_TARGET_LIST),\
        $(eval DPKG:=$(lastword $(subst /, ,$(target)))) \
        $(eval PATH:= $(subst $(DPKG),,$(target))) \
        $(if $(findstring $*,$(target)),
		$(info ) \
		$(eval MDPKG:=$(if $($(DPKG)_MAIN_DEB),$($(DPKG)_MAIN_DEB),$(DPKG))) \
			$(info  [$(PATH)$(MDPKG)]  ) \
            $(foreach pkg,$($(MDPKG)_DERIVED_DEBS) $($(MDPKG)_EXTRA_DEBS),\
				$(info $(SPACE)$(SPACE)$(SPACE)$(SPACE) $(PATH)$(pkg)) \
             )\
         )\
      )
	$(info )
```




### 工作流程

结合Makefile.work和slave.mk的源码分析，构建系统的工作流程可以概括为：

1. **环境准备**：
   - Makefile调用Docker构建sonic-slave容器
   - 设置环境变量和构建参数

2. **依赖解析与构建**：
   - slave.mk解析所有目标的依赖关系
   - 按照依赖顺序构建各种组件（Debian包、Docker镜像等）

3. **镜像生成**：
   - 构建各个功能Docker镜像
   - 组装最终的SONiC安装镜像

4. **输出产物**：
   - 在target目录下生成最终镜像和中间产物



### 关键技术与设计思路

#### 容器化构建环境

slave.mk的核心设计理念是使用容器化环境确保构建的一致性和可重复性：

```makefile
# Docker镜像构建参数
DOCKER_BUILD_OPTS += --build-arg http_proxy=$(http_proxy)
DOCKER_BUILD_OPTS += --build-arg https_proxy=$(https_proxy)
DOCKER_BUILD_OPTS += --build-arg no_proxy=$(no_proxy)
DOCKER_BUILD_OPTS += --build-arg HTTP_PROXY=$(HTTP_PROXY)
DOCKER_BUILD_OPTS += --build-arg HTTPS_PROXY=$(HTTPS_PROXY)
DOCKER_BUILD_OPTS += --build-arg NO_PROXY=$(NO_PROXY)
```

这种设计确保了：
- 构建环境与主机环境隔离
- 构建过程可重现
- 跨平台构建支持


#### 多架构支持

slave.mk实现了对多种架构的支持，特别是通过交叉编译环境和QEMU模拟：

```makefile
# 交叉编译环境配置
ifeq ($(CONFIGURED_ARCH),$(COMPILE_HOST_ARCH))
SLAVE_BASE_IMAGE = $(SLAVE_DIR)
MULTIARCH_QEMU_ENVIRON = n
CROSS_BUILD_ENVIRON = n
else ifneq ($(CONFIGURED_ARCH),)
SLAVE_BASE_IMAGE = $(SLAVE_DIR)-march-$(CONFIGURED_ARCH)
ifneq ($(CROSS_BLDENV),)
MULTIARCH_QEMU_ENVIRON = n
CROSS_BUILD_ENVIRON = y
else
MULTIARCH_QEMU_ENVIRON = y
CROSS_BUILD_ENVIRON = n
endif
endif
```

这种设计支持：
- amd64原生构建
- arm64/armhf交叉编译
- 通过QEMU进行多架构模拟构建


#### 缓存机制

slave.mk实现了多种缓存机制来加速构建过程：

```makefile
# 版本缓存设置
SONIC_VERSION_CACHE := $(filter-out none,$(SONIC_VERSION_CACHE_METHOD))
SONIC_OVERRIDE_BUILD_VARS += SONIC_VERSION_CACHE=$(SONIC_VERSION_CACHE)
SONIC_OVERRIDE_BUILD_VARS += SONIC_VERSION_CACHE_SOURCE=$(SONIC_VERSION_CACHE_SOURCE)
export SONIC_VERSION_CACHE SONIC_VERSION_CACHE_SOURCE
$(shell test -d $(SONIC_VERSION_CACHE_SOURCE) || \
    mkdir -p $(SONIC_VERSION_CACHE_SOURCE) && chmod -f 777 $(SONIC_VERSION_CACHE_SOURCE) 2>/dev/null )
```

这些缓存机制包括：
- 版本缓存
- Docker镜像缓存
- Debian包缓存
- Python wheel缓存















































