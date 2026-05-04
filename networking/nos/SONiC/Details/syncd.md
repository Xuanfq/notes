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

- platform/broadcom/rules.dep
- platform/broadcom/rules.mk
  - sai-modules.mk  (ASIC Driver)
    - `opennsl-modules_$(BRCM_OPENNSL_KERNEL_VERSION)_amd64.deb`  (xgs family)
      - saibcm-modules/
    - `opennsl-modules-dnx_$(BRCM_DNX_OPENNSL_KERNEL_VERSION)_amd64.deb`  (dnx family)
      - saibcm-modules-dnx/
  - sai.mk  (ASIC SAI api Implementation lib)
    - `libsaibcm_$(LIBSAIBCM_XGS_VERSION)_amd64.deb`  (xgs family)
      - binary, no source
    - `libsaibcm-dev_$(LIBSAIBCM_XGS_VERSION)_amd64.deb`  (xgs family for dev)
      - binary, no source
    - `libsaibcm_dnx_$(LIBSAIBCM_DNX_VERSION)_amd64.deb`  (dnx family)
      - binary, no source
  - sswsyncd.mk  (博通交换机状态服务工具, dsserve / bcmcmd)
    - `sswsyncd_1.0.0_$(CONFIGURED_ARCH).deb`
      - sswsyncd/
        - deserve (编译结果): 终端代理服务器, 主要用于通过 Unix 域套接字远程访问交互式命令行程序, 主要是给 bcm.user 做无感终端启动和远程服务 (dsserve -d -f /var/run/dsserve.sock bcm.user)
        - bcmcmd (编译结果): 调用 deserve 提供的 sock 执行单条BCM命令
  - docker-syncd-brcm.mk
    - `docker-syncd-brcm.gz`
      - docker-syncd-brcm/
        - base_image_files/
        - `$(SYNCD)`
        - `$(BRCM_XGS_SAI)`
        - `$(SSWSYNCD)`
        - `$(RDB-CLI)`: `rdb-cli`
          - rules/rdb-cli.mk
            - src/rdb-cli/
  - docker-syncd-brcm-rpc.mk
    - `docker-syncd-brcm-rpc.gz`
      - docker-syncd-brcm-rpc/
        - `$(PTF_PY3)`: `ptf-0.10.0.post0-py3-none-any.whl`
          - rules/ptf-py3.mk
            - src/ptf-py3/
  - docker-saiserver-brcm.mk
    - `docker-saiserver$(SAITHRIFT_VER)-brcm.gz`
      - docker-saiserver-brcm/
        - `$(SAISERVER)`: 见 libsaithrift-dev.mk
        - `$(SSWSYNCD)`
        - `src/sonic-sairedis/syncd/scripts/syncd_init_common.sh`
  - libsaithrift-dev.mk
    - `libsaithrift$(SAITHRIFT_VER)-dev_$(SAI_VER)_amd64.deb` (主包)
      - src/sonic-sairedis/SAI/
        - `$(BRCM_XGS_SAI)`
        - `$(BRCM_XGS_SAI_DEV)`
    - `python-saithrift$(SAITHRIFT_VER)_$(SAI_VER)_amd64.deb` (SAI同时编译出该deb)
    - `saiserver$(SAITHRIFT_VER)_$(SAI_VER)_amd64.deb` (SAI同时编译出该deb)
    - `saiserver$(SAITHRIFT_VER)-dbg_$(SAI_VER)_amd64.deb` (SAI同时编译出该deb)
  - docker-syncd-brcm-dnx.mk
    - `docker-syncd-brcm-dnx.gz`
      - docker-syncd-brcm-dnx/
        - base_image_files/
        - `$(SYNCD)`
        - `$(BRCM_DNX_SAI)`
        - `$(SSWSYNCD)`
        - `$(RDB-CLI)`
  - docker-syncd-brcm-dnx-rpc.mk
    - `docker-syncd-brcm-dnx-rpc.gz`
      - docker-syncd-brcm-dnx-rpc/
        - `$(PTF_PY3)`: `ptf-0.10.0.post0-py3-none-any.whl`
          - rules/ptf-py3.mk
            - src/ptf-py3/
  - 
  - (INCLUDE_PDE, platform development environment, 平台开发环境)
  - docker-pde.mk
    - `docker-pde.gz`  (DOCKER_PDE)
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
    - `sonic-platform-pde_1.0_amd64.deb`
      - src/sonic-platform-pde/
        - `$(BRCM_XGS_SAI)`
        - `$(BRCM_XGS_SAI_DEV)`
        - `$(SWIG)`
  - 
  - (INCLUDE_GBSYNCD, gearbox support, 变速器?, 外置 Gearbox/PHY 芯片 配置和状态同步的守护进程 / 容器)
  - ../components/docker-gbsyncd-credo.mk
    - `docker-gbsyncd-credo.gz`
      - `libsaicredo_0.9.9_amd64.deb`  (网络下载)
      - `libsaicredo-owl_0.9.9_amd64.deb`  (网络下载)
      - `libsaicredo-blackhawk_0.9.9_amd64.deb`  (网络下载)
      - `$(SYNCD)`
      - ../components/docker-gbsyncd-credo/
  - ../components/docker-gbsyncd-broncos.mk
    - `docker-gbsyncd-broncos.gz`
      - `libsaibroncos_3.12_amd64.deb`  (网络下载)
      - `$(SYNCD)`
      - ../components/docker-gbsyncd-broncos/
  - ../components/docker-gbsyncd-milleniob.mk
    - `docker-gbsyncd-milleniob.gz`  (由于无链接,暂无实现)
      - `libsaimilleniob_3.14.0_amd64.deb`  (网络下载, 暂无链接)
      - `$(SYNCD)`
      - ../components/docker-gbsyncd-milleniob/












## 源码结构

- src/sonic-sairedis
  - SAI/
  - ...


## 依赖

- LIBSAIREDIS
  - src/sonic-sairedis

