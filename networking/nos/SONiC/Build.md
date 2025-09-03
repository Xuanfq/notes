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



## Makefile.work

在 Makefile.work 中，执行顺序如下：


### 1. 初始化阶段

在 Makefile 执行的最开始，会进行一系列的初始化设置：

1. **环境变量设置**：
   - 设置 SHELL 为 `/bin/bash`
   - 获取当前用户信息 (USER, PWD, USER_LC)
   - 检测系统架构 (DOCKER_MACHINE, COMPILE_HOST_ARCH)

2. **依赖检查**：
   - 检查用户是否为 root（如果是则报错）
   - 检查 j2 模板工具是否安装
   - 检查 Docker 版本是否符合要求

3. **构建环境配置**：
   - 设置 CONFIGURED_ARCH 和 CONFIGURED_PLATFORM
   - 根据 BLDENV 设置 SLAVE_DIR（从机构建目录）
   - 根据 CONFIGURED_ARCH 设置 TARGET_BOOTLOADER


### 2. 配置文件处理阶段

1. **包含配置文件**：
   - 包含 `rules/config`、`rules/config.user` 和 `rules/sonic-fips.mk`
   - 设置 DEFAULT_CONTAINER_REGISTRY、ENABLE_DOCKER_BASE_PULL 等变量

2. **架构相关配置**：
   - 根据 CONFIGURED_ARCH 和 COMPILE_HOST_ARCH 设置 SLAVE_BASE_IMAGE
   - 设置 MULTIARCH_QEMU_ENVIRON 和 CROSS_BUILD_ENVIRON
   - 计算 SLAVE_IMAGE 和 DOCKER_ROOT

3. **FIPS 配置检查**：
   - 检查 INCLUDE_FIPS 和 ENABLE_FIPS 的兼容性


### 3. 构建信息生成阶段

1. **版本控制信息生成**：
   - 设置 SONIC_VERSION_CACHE 相关变量
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
   - 计算 SLAVE_BASE_TAG 和 SLAVE_TAG
   - 定义 COLLECT_DOCKER 命令


### 4. Docker 运行环境配置阶段

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


### 5. 构建命令定义阶段

1. **Docker 构建命令定义**：
   - 定义 DOCKER_SLAVE_BASE_BUILD、DOCKER_BASE_PULL、DOCKER_USER_BUILD 等命令
   - 定义 DOCKER_SLAVE_BASE_INSPECT、DOCKER_SLAVE_BASE_PULL_REGISTRY 等检查命令
   - 定义 SONIC_SLAVE_BASE_BUILD 和 SONIC_SLAVE_USER_BUILD 复合命令

2. **构建指令定义**：
   - 定义 SONIC_BUILD_INSTRUCTION，包含所有构建参数和变量
     - `slave.mk`
       - include:
         - `rules/config`
         - `rules/config.user` (if exist, default is not exist)
         - `rules/functions`
         - `rules/*.mk`
         - `platform/pddf/rules.mk` (PDDF_SUPPORT=y, default is y, else `platform/$PLATFORM/rules.mk`)
         - `Makefile.cache`


### 6. 目标规则定义阶段

1. **模式规则**：

   - 通过模式规则 `%:: | sonic-build-hooks` 处理任意目标，先执行 sonic-build-hooks
   - 执行环境检查（DOCKER_MULTIARCH_CHECK、DOCKER_SERVICE_MULTIARCH_CHECK 等）
   - 执行 OVERLAY_MODULE_CHECK
   - 构建 SONIC_SLAVE_BASE_BUILD 和 SONIC_SLAVE_USER_BUILD
   - 运行 DOCKER_RUN 命令执行构建指令
   - 最后执行 docker-image-cleanup

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
   - `sonic-slave-bash`：启动从机容器并进入 bash
   - `sonic-slave-run`：在从机容器中运行特定命令
   - `showtag`：显示镜像标签
   - `init`：初始化 Git 子模块
   - `reset`：重置代码库状态
   - 执行特定目标前先执行 sonic-build-hook


### 7. 执行流程总结

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
  - ASIC_VENDOR 私有代码克隆
    - ASIC_VENDOR 私有代码配置位于`platform/checkout/`目录下的：
      - 文件`$(PLATFORM).ini`
      - 文件`$(PLATFORM)-smartswitch.ini`: 需配置参数`SMARTSWITCH=1`, e.g. `make configure PLATFORM=[ASIC_VENDOR] SMARTSWITCH=1`
    - 当前(202508)仅存在以下ASIC_VENDOR存在私有代码：
      - cisco-8000
      - pensando
    - 这些代码一般会被克隆到`platform/$(PLATFORM)`获其子目录
- 对于设置的需要编译的不同的debian版本进行逐个配置：
  - 实际调用`BLDENV=$debianname $(MAKE) -f Makefile.work $@`








































