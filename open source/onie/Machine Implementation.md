# Machine Implementation

## Content


- machine/vendor/
  - machinename
    - rootconf
      - sysroot-bin/            # -> /bin/
      - sysroot-etc/            # -> /etc/
        - passwd-secured        # -> passwd (when secure boot)
        - init-platform                             # 实现：`init_platform_pre_arch` 和 `init_platform_post_arch`
      - sysroot-init/           # -> /etc/init.d/
      - sysroot-lib-onie/       # -> /lib/onie/
        - network-driver-${onie_switch_asic}        # 实现：`network_driver_init`
        - network-driver-platform                   # 实现：`network_driver_platform_pre_init` 和 `network_driver_platform_post_init`
      - sysroot-rcS/            # -> /etc/rcS.d/
      - sysroot-rcK/            # -> /etc/rc0.d/ & /etc/rc6.d/



