# syncd

## 层级架构

- syncd container
  - syncd
    - sai api
      - asic sdk



## 依赖结构


### 通用

- rules/syncd.dep
- rules/syncd.mk
  - `syncd_1.0.0_$(CONFIGURED_ARCH).deb`  (SYNCD)  # syncd
    - src/sonic-sairedis
      - `libsairedis_$(LIBSAIREDIS_VERSION)_$(CONFIGURED_ARCH).deb`  (LIBSAIREDIS|编译时|运行时)
        - rules/sairedis.mk
        - src/sonic-sairedis
      - `libsaimetadata_$(LIBSAIREDIS_VERSION)_$(CONFIGURED_ARCH).deb`  (LIBSAIMETADATA|运行时)
        - rules/sairedis.mk
        - src/sonic-sairedis
      - `libswsscommon-dev_$(LIBSWSSCOMMON_VERSION)_$(CONFIGURED_ARCH).deb`  (LIBSWSSCOMMON_DEV|编译时)
        - rules/swss-common.mk
        - src/sonic-swss-common
      - `libswsscommon_$(LIBSWSSCOMMON_VERSION)_$(CONFIGURED_ARCH).deb`  (LIBSWSSCOMMON|运行时)
        - rules/swss-common.mk
        - src/sonic-swss-common
  - `syncd-rpc_1.0.0_$(CONFIGURED_ARCH).deb`  (SYNCD_RPC)  # syncd rpc (option, default y)
    - ?
      - `libthrift-dev_$(THRIFT_VERSION_FULL)_$(CONFIGURED_ARCH).deb`  (LIBTHRIFT_DEV|编译时)
        - rules/thrift.mk
        - src/thrift
      - `libswsscommon-dev_$(LIBSWSSCOMMON_VERSION)_$(CONFIGURED_ARCH).deb`  (LIBSWSSCOMMON_DEV|编译时)
        - rules/swss-common.mk
        - src/sonic-swss-common
      - `libsairedis_$(LIBSAIREDIS_VERSION)_$(CONFIGURED_ARCH).deb`  (LIBSAIREDIS|运行时)
        - rules/sairedis.mk
        - src/sonic-sairedis
      - `libsaimetadata_$(LIBSAIREDIS_VERSION)_$(CONFIGURED_ARCH).deb`  (LIBSAIMETADATA|运行时)
        - rules/sairedis.mk
        - src/sonic-sairedis
  - `syncd-dbgsym_1.0.0_$(CONFIGURED_ARCH).deb`  (SYNCD_DBG)  # syncd debug
    - ?
      - `syncd_1.0.0_$(CONFIGURED_ARCH).deb`  (SYNCD|编译时|运行时)
  - `syncd-rpc-dbgsym_1.0.0_$(CONFIGURED_ARCH).deb`  (SYNCD_RPC_DBG)  # syncd rpc debug (option, same with syncd rpc)
    - ?
      - `syncd-rpc_1.0.0_$(CONFIGURED_ARCH).deb`  (SYNCD_RPC|编译时|运行时)


### Broadcom


#### 主要结构

- platform/broadcom/rules.dep
- platform/broadcom/rules.mk
  - sai-modules.mk  (ASIC Driver)
    - `opennsl-modules_$(BRCM_OPENNSL_KERNEL_VERSION)_amd64.deb` (BRCM_OPENNSL_KERNEL) (xgs family) (优先)
      - saibcm-modules/
    - `opennsl-modules-dnx_$(BRCM_DNX_OPENNSL_KERNEL_VERSION)_amd64.deb` (BRCM_DNX_OPENNSL_KERNEL) (dnx family)
      - saibcm-modules-dnx/
  - sai.mk  (ASIC SAI api Implementation lib)
    - `libsaibcm_$(LIBSAIBCM_XGS_VERSION)_amd64.deb` (BRCM_XGS_SAI) (xgs family)
      - binary, no source
    - `libsaibcm-dev_$(LIBSAIBCM_XGS_VERSION)_amd64.deb` (BRCM_XGS_SAI_DEV) (xgs family for dev)
      - binary, no source
    - `libsaibcm_dnx_$(LIBSAIBCM_DNX_VERSION)_amd64.deb` (BRCM_DNX_SAI) (dnx family)
      - binary, no source
  - sswsyncd.mk  (博通交换机状态服务工具, dsserve / bcmcmd)
    - `sswsyncd_1.0.0_$(CONFIGURED_ARCH).deb` (SSWSYNCD)
      - sswsyncd/
        - deserve (编译结果): 终端代理服务器, 主要用于通过 Unix 域套接字远程访问交互式命令行程序, 主要是给 bcm.user 做无感终端启动和远程服务 (dsserve -d -f /var/run/dsserve.sock bcm.user)
        - bcmcmd (编译结果): 调用 deserve 提供的 sock 执行单条BCM命令
  - docker-saiserver-brcm.mk (容器名: saiserver$(SAITHRIFT_VER))
    - `docker-saiserver$(SAITHRIFT_VER)-brcm.gz` (DOCKER_SAISERVER_BRCM) (加载配置及驱动, 启动SAI-server) (saiserver -p sai.profile -f port_config.ini)
      - docker-saiserver-brcm/
        - `$(SAISERVER)`: 见 libsaithrift-dev.mk
        - `$(SSWSYNCD)`
        - `src/sonic-sairedis/syncd/scripts/syncd_init_common.sh`
  - libsaithrift-dev.mk
    - `libsaithrift$(SAITHRIFT_VER)-dev_$(SAI_VER)_amd64.deb` (LIBSAITHRIFT_DEV) (主包)
      - src/sonic-sairedis/SAI/
        - `$(BRCM_XGS_SAI)`
        - `$(BRCM_XGS_SAI_DEV)`
    - `python-saithrift$(SAITHRIFT_VER)_$(SAI_VER)_amd64.deb` (PYTHON_SAITHRIFT) (SAI同时编译出该deb)
    - `saiserver$(SAITHRIFT_VER)_$(SAI_VER)_amd64.deb` (SAISERVER) (SAI同时编译出该deb)
    - `saiserver$(SAITHRIFT_VER)-dbg_$(SAI_VER)_amd64.deb` (SAISERVER_DBG) (SAI同时编译出该deb)
  - docker-syncd-brcm.mk (容器名: syncd)
    - `docker-syncd-brcm.gz` (DOCKER_SYNCD_BASE) (加载配置及驱动, 启动SAI-syncd, 加载bcm-led配置)
      - docker-syncd-brcm/
        - base_image_files/
        - `$(SYNCD)`
        - `$(BRCM_XGS_SAI)`
        - `$(SSWSYNCD)`
        - `$(RDB-CLI)`: `rdb-cli`
          - rules/rdb-cli.mk
            - src/rdb-cli/
  - docker-syncd-brcm-rpc.mk (容器名: syncd)
    - `docker-syncd-brcm-rpc.gz` (DOCKER_SYNCD_BRCM_RPC) (non-rpc的基础上多了ptf模块)
      - docker-syncd-brcm-rpc/
        - `$(PTF_PY3)`: `ptf-0.10.0.post0-py3-none-any.whl`
          - rules/ptf-py3.mk
            - src/ptf-py3/
  - docker-syncd-brcm-dnx.mk (容器名: syncd)
    - `docker-syncd-brcm-dnx.gz` (DOCKER_SYNCD_DNX_BASE) (加载配置及驱动, 启动SAI-syncd, 加载bcm-led配置)
      - docker-syncd-brcm-dnx/
        - base_image_files/
        - `$(SYNCD)`
        - `$(BRCM_DNX_SAI)`
        - `$(SSWSYNCD)`
        - `$(RDB-CLI)`
  - docker-syncd-brcm-dnx-rpc.mk (容器名: syncd)
    - `docker-syncd-brcm-dnx-rpc.gz` (DOCKER_SYNCD_BRCM_DNX_RPC) (non-rpc的基础上多了ptf模块)
      - docker-syncd-brcm-dnx-rpc/
        - `$(PTF_PY3)`: `ptf-0.10.0.post0-py3-none-any.whl`
          - rules/ptf-py3.mk
            - src/ptf-py3/
  - 
  - (INCLUDE_PDE, platform development environment, 平台开发环境)
  - docker-pde.mk (容器名: pde) (默认是不编译的INCLUDE_PDE!=y)
    - `docker-pde.gz` (DOCKER_PDE) (安装ASIC驱动, 配置ASIC的syncd)
      - dockers/docker-pde/
        - `$(PYTHON_NETIFACES)`
        - `$(SONIC_PLATFORM_PDE)`: 见 sonic-pde-tests.mk
        - `$(BRCM_XGS_SAI)`
        - `$(SONIC_UTILS)`
        - `$(SONIC_PLATFORM_COMMON_PY3)`
        - `$(PDDF_PLATFORM_API_BASE_PY3)`  (PDDF_SUPPORT=y)
        - `$(SONIC_DAEMON_BASE_PY3)`
        - /usr/share/sonic/device/x86_64-broadcom_common/
        - /usr/share/sonic/device/pddf/
        - base_image_files/
        - cancun_files/cancun_x.y.z/bcm*.pkg
        - dockers/docker-pde/syncd_init_common.sh  (与 saiserver 中不一样)
  - sonic-pde-tests.mk
    - `sonic-platform-pde_1.0_amd64.deb` (SONIC_PLATFORM_PDE)
      - src/sonic-platform-pde/
        - `$(BRCM_XGS_SAI)`
        - `$(BRCM_XGS_SAI_DEV)`
        - `$(SWIG)`
  - 
  - (INCLUDE_GBSYNCD, gearbox support, 变速器?, 外置 Gearbox/PHY 芯片 配置和状态同步的守护进程 / 容器)
  - ../components/docker-gbsyncd-credo.mk (容器名: gbsyncd)
    - `docker-gbsyncd-credo.gz` (DOCKER_GBSYNCD_BASE) (dsserve -f sswgbsyncd.socket syncd --diag -s -p psai.profile -x context_config.json -g 1)
      - `libsaicredo_0.9.9_amd64.deb` (LIBSAI_CREDO) (网络下载)
      - `libsaicredo-owl_0.9.9_amd64.deb` (LIBSAI_CREDO_OWL) (网络下载)
      - `libsaicredo-blackhawk_0.9.9_amd64.deb` (LIBSAI_CREDO_BLACKHAWK) (网络下载)
      - `$(SYNCD)`
      - ../components/docker-gbsyncd-credo/
  - ../components/docker-gbsyncd-broncos.mk (容器名: gbsyncd)
    - `docker-gbsyncd-broncos.gz` (DOCKER_GBSYNCD_BRONCOS) (dsserve -f sswgbsyncd.socket syncd --diag -s -p psai.profile -x context_config.json -g 1)
      - `libsaibroncos_3.12_amd64.deb` (LIBSAI_BRONCOS) (网络下载)
      - `$(SYNCD)`
      - ../components/docker-gbsyncd-broncos/
  - ../components/docker-gbsyncd-milleniob.mk (容器名: gbsyncd)
    - `docker-gbsyncd-milleniob.gz` (DOCKER_GBSYNCD_MILLENIOB) (由于无链接,暂无实现) (dsserve -f sswgbsyncd.socket syncd --diag -s -p psai.profile -x context_config.json -g 1)
      - `libsaimilleniob_3.14.0_amd64.deb` (LIBSAI_MILLENIOB) (网络下载, 暂无链接)
      - `$(SYNCD)`
      - ../components/docker-gbsyncd-milleniob/



#### xgs/dnx

**为避免冲突会有两个image**:

- `sonic-broadcom.bin`
- `sonic-broadcom-dnx.bin`


**原理如下**:

1. 定义安装列表 (one-image.mk), 定义了两个独立的 MACHINE, 且两个包都被添加到安装列表中
   ```makefile
   SONIC_ONE_IMAGE = sonic-broadcom.bin
   $(SONIC_ONE_IMAGE)_MACHINE = broadcom
   $(SONIC_ONE_IMAGE)_DEPENDENT_MACHINE = broadcom-dnx
   $(SONIC_ONE_IMAGE)_LAZY_BUILD_INSTALLS = $(BRCM_OPENNSL_KERNEL) $(BRCM_DNX_OPENNSL_KERNEL)
   # ...
   SONIC_INSTALLERS += $(SONIC_ONE_IMAGE)
   ```
2. 定义包的目标机器 (saibcm-modules.mk)
   ```makefile
   $(BRCM_OPENNSL_KERNEL)_MACHINE = broadcom
   $(BRCM_DNX_OPENNSL_KERNEL)_MACHINE = broadcom-dnx
   ```
3. 生成条件安装字符串 (slave.mk)
   ```makefile
   export lazy_build_installer_debs="$(foreach deb, $($*_LAZY_BUILD_INSTALLS), $(addprefix $($(deb)_MACHINE)|,$(deb)))"
   # - broadcom|opennsl-modules_13.2.1.0_amd64.deb
   # - broadcom-dnx|opennsl-modules-dnx_13.2.1.1_amd64.deb
   ```
4. 设置当前构建的 TARGET_MACHINE (slave.mk)
   ```makefile
   ## Installers
   $(addprefix $(TARGET_PATH)/, $(SONIC_RFS_TARGETS)) : $(TARGET_PATH)/% : \
        .platform # ...
   # ...
     $(eval machine=$($*_MACHINE))
     # ...
     TARGET_MACHINE=$(machine) ./build_debian.sh $(LOG)
   
   # 对于 SONIC_RFS_TARGETS, define rfs_define_target 中加入了 onie-image 的两个 Machine
   define rfs_define_target
   $(eval rfs_target=$(call rfs_build_target_name,$(1),$($(1)_MACHINE)))
   $(eval $(rfs_target)_INSTALLER=$(1))
   $(eval $(rfs_target)_MACHINE=$($(1)_MACHINE))
   $(eval SONIC_RFS_TARGETS+=$(rfs_target))
    
   $(if $($(1)_DEPENDENT_MACHINE),\
     $(eval dependent_rfs_target=$(call rfs_build_target_name,$(1),$($(1)_DEPENDENT_MACHINE)))
     $(eval $(dependent_rfs_target)_INSTALLER=$(1))
     $(eval $(dependent_rfs_target)_MACHINE=$($(1)_DEPENDENT_MACHINE))
     $(eval SONIC_RFS_TARGETS+=$(dependent_rfs_target))
     $(eval $(rfs_target)_DEPENDENT_RFS=$(dependent_rfs_target)))
   endef
   # 添加到 SONIC_RFS_TARGETS
   $(foreach installer,$(SONIC_INSTALLERS),$(eval $(call rfs_define_target,$(installer))))
   $(foreach installer, $(SONIC_INSTALLERS), $(eval $(installer)_RFS_DEPENDS=$(call rfs_get_installer_dependencies,$(installer))))

   SONIC_TARGET_LIST += $(addprefix $(TARGET_PATH)/, $(SONIC_RFS_TARGETS))

   # target/sonic-broadcom.bin__broadcom-dnx__rfs.squashfs
   # target/sonic-broadcom.bin__broadcom__rfs.squashfs
   ```
5. 条件安装 (sonic_debian_extension.j2), 最终实现对不同的 Machine 安装不一样的包
   ```j2
    {% for machine_debs in lazy_build_installer_debs.strip().split() -%}
    {% set machine, pkgname = machine_debs.split('|') %}
    if [[ -z "{{machine}}" || -n "{{machine}}" && $TARGET_MACHINE == "{{machine}}" ]]; then
        install_deb_package $debs_path/{{pkgname}}
    fi
    {% endfor %}
   ```



#### 服务启动

- syncd.service
  - Link: files/build_templates/per_namespace/syncd.service.j2
  - Desc: syncd service
  - Exec: /usr/local/bin/syncd.sh start; /usr/local/bin/syncd.sh wait
  - Dep : opennsl-modules.service config-setup.service sonic.target config-setup.service database.service swss.service

- opennsl-modules.service
  - Link: platform/broadcom/saibcm-modules(-dnx)/systemd/opennsl-modules.service
  - Desc: Opennsl kernel modules init
  - Exec: -/etc/init.d/opennsl-modules start
  - Dep : local-fs.target

- gbsyncd.service
  - Link: files/build_templates/per_namespace/gbsyncd.service.j2
  - Desc: gbsyncd service
  - Exec: [ /usr/bin/gbsyncd-platform.sh ] && /usr/local/bin/gbsyncd.sh start && /usr/local/bin/gbsyncd.sh wait
  - Dep : sonic.target database.service config-setup.service interfaces-config.service swss.service
  - 注意: 需要 platform-path gbsyncd.ini 配置gbsyncd容器启动(platform=gbsyncd-credo/broncos/milleniob), 若无则不启动




## 源码结构

- src/sonic-sairedis
  - SAI/
  - ...




