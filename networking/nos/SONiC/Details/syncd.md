# syncd

## 层级架构

- syncd container
  - syncd
    - sai api
      - asic sdk



## 依赖结构

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









## 源码结构

- src/sonic-sairedis
  - SAI/
  - ...


## 依赖

- LIBSAIREDIS
  - src/sonic-sairedis

