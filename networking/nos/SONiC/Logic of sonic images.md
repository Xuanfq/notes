# Logic of sonic images


## 制作和安装逻辑

### Image制作

Reference: [Build.md](./Build.md)



### Image结构

**解压Image**: `export extract=1; ./sonic-broadcom.bin`

```sh
aiden@Xuanfq:/tmp/SONiC$ export extract=1
aiden@Xuanfq:/tmp/SONiC$ ./sonic-broadcom.bin
Verifying image checksum ... OK.
Preparing image archive ... OK.
Image extracted to: /tmp/tmp.5Q583jwalp
# check extract logic: `head -n 100 ./sonic-broadcom.bin`
```

Image的类型有多种, e.g. onie (最多), raw, kvm etc.


#### onie

**Structure**:

- installer/
  - platforms/
    - `$platform-name`          # x86_64-xxxx-r0 -> device/@vendor@/@platform-name@/`installer.conf`
  - tests/                      # -> `installer/tests/`, 没有实际引用或调用
    - sample_machine.conf       # -> installer/tests/sample_machine.conf
    - test_read_conf.sh         # -> installer/tests/test_read_conf.sh, 读取和测试配置sample_machine.conf, 没有实际引用或调用
  - fs.zip/                     # 直接解压到installer目录下，无子目录包裹
    - boot/
      - vmlinuz-6.1.0-29-2-amd64        # 内核文件
      - initrd.img-6.1.0-29-2-amd64     # 文件系统
      - config-6.1.0-29-2-amd64         # 内核编译配置
      - System.map-6.1.0-29-2-amd64     # 内核编译时生成, 记录文件内核中的符号列表, 实际上并不是真正的System.map, 真正的在linux-image-<version>-dbg
    - dockerfs.tar.gz           # docker相关
    - fs.squashfs/              # 只读文件系统, 包括device数据
      - usr/share/sonic/device/
        - `$platform-name`/             # -> device/@vendor@/`@platform-name@`/
          - *
      - *
    - platform.tar.gz/          # platform/
      - common/
        - Packages.gz                                                   # debian control file for all the *.deb
        - sonic-platform-`@MACHINE-NAME-FULL-L@`_`1.0`_amd64.deb        # -> platform/sw-chip-name/device-vendor/device-name/
        - platform-modules-`@MACHINE-NAME-FULL-L@`_`1.0`_amd64.deb      # -> platform/sw-chip-name/device-vendor/device-name/
      - grub/
        - grub-pc-bin_2.06-13+deb12u1_amd64.deb                         # 
      - `$platform-name`/
        - sonic-platform-`@MACHINE-NAME-FULL-L@`_`1.0`_amd64.deb        # -> ../common/*.deb
        - platform-modules-`@MACHINE-NAME-FULL-L@`_`1.0`_amd64.deb      # -> ../common/*.deb 同上, 二选一, 或其他自定义deb名
  - sharch_body.sh              # -> `installer/sharch_body.sh`
  - install.sh                  # -> `installer/install.sh`, 替换了一些插值(`%%xxx%%`)
  - machine.conf                # 生成的配置, 包含`machine=@sw-chip-vendor@`和`platform=x86_64-@sw-chip-vendor@-r0`两个字段
  - onie-image.conf             # -> `onie-image.conf`
  - onie-image-*.conf           # -> `onie-image-arm64.conf` or `onie-image-armhf.conf`, 若非此架构则不存在
  - default_platform.conf       # -> `installer/default_platform.conf`
  - platform.conf               # -> platform/@sw-chip-vendor@/`platform-$arch.conf`或`platform.conf`
  - platforms_asic              # 生成的sw-chip相关的所有device的列表, 即platform-name列表, 通过device/@vendor@/@platform-name@/`platform_asic`识别


**配置覆盖顺序**:

1. machine.conf
2. onie-image.conf
3. onie-image-*.conf
4. /etc/machine.conf
5. /host/machine.conf
6. default_platform.conf
7. platform.conf


**SONiC分区中/host/machine.conf来源顺序**:

1. /etc/machine-build.conf
2. /etc/machine.conf



#### raw


#### kvm


#### aboot


#### dsc


#### bfb



### 磁盘分区结构




### Image安装





## MISC










