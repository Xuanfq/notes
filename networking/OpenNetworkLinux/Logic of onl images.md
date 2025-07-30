# Logic of onl images

## 制作和安装逻辑

### 制作

Reference: [Build.md](./Build.md)


### Image结构

**解压Image**: `./ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER -x "" ""`

```log
aiden@Xuanfq:/tmp/tmp.t9G9fw3xWe$ ./ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER -x " " ""
ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER: computing checksum of original archive
ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER: checksum is OK
ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER: extracting pad
1+0 records in
1+0 records out
512 bytes copied, 4.73e-05 s, 10.8 MB/s
ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER: copying file before resetting pad
ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER: resetting pad
1+0 records in
1+0 records out
512 bytes copied, 5.0325e-05 s, 10.2 MB/s
ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER: processing with zip
ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64_INSTALLED_INSTALLER: correcting permissions with autoperms.sh
```


**Structure**:

- config/
  - README
- plugins/
  - sample-preinstall-Mvjcxq.py
  - sample-postinstall-lSta2D.py
- boot-config
- kernel-3.16-lts-x86_64-all
- kernel-4.14-lts-x86_64-all
- kernel-4.19-lts-x86_64-all
- kernel-5.4-lts-x86_64-all
- kernel-4.9-lts-arm64-all.bin.gz (arm64)
- ONL-master_ONL-OS10_2025-06-28.1721-28f52e6_AMD64.swi
- onl-loader-initrd-amd64.cpio.gz (x86)
- onl-loader-fit.itb (arm)
- postinstall.sh
- preinstall.sh
- autoperms.sh
- installer.sh




## MISC

### /etc/inittab 来源

1. `builds/any/rootfs/$debian-name/sysvinit/overlay/etc/inittab`
2. 在rootfs制作时，`builds/amd64/rootfs/builds/Makefile`中指定rootfs配置为`$(ONL)/builds/any/rootfs/$(ONL_DEBIAN_SUITE)/standard/standard.yml`，其中包含overlays配置：
```yml
Configure:
  overlays:
    - ${ONL}/builds/any/rootfs/${ONL_DEBIAN_SUITE}/common/overlay
    - ${ONL}/builds/any/rootfs/${ONL_DEBIAN_SUITE}/${INIT}/overlay
```
3. 在rootfs制作时，`builds/amd64/rootfs/builds/Makefile`中导入的`rfs.mk`将调用`tools/onlrfs.py`，这将自动扫描并编译packages目录下的平台所需的包，然后安装编译后的包并联网安装所需的其他包，最后再进行配置并打包成rootfs。配置过程中会自动：
   1. 将`overlays`的目录拷贝到rootfs所在位置，包括`common/overlay/*`和`/etc/inittab`
      ```log
        builds/any/rootfs/buster/common/overlay/etc
        ├── adjtime
        ├── filesystems
        ├── inetd.conf
        ├── mtab.yml
        ├── profile.d
        │   └── onl-platform-current.sh
        ├── rc.local
        ├── rssh.conf
        ├── snmp
        │   └── snmpd.conf
        └── udev
            └── rules.d
                ├── 60-block.rules
                └── 60-net.rules

        5 directories, 10 files
        aiden@Xuanfq:~/workspace/onl/build$ tree builds/any/rootfs/buster/common/overlay/
        builds/any/rootfs/buster/common/overlay/
        ├── etc
        │   ├── adjtime
        │   ├── filesystems
        │   ├── inetd.conf
        │   ├── mtab.yml
        │   ├── profile.d
        │   │   └── onl-platform-current.sh
        │   ├── rc.local
        │   ├── rssh.conf
        │   ├── snmp
        │   │   └── snmpd.conf
        │   └── udev
        │       └── rules.d
        │           ├── 60-block.rules
        │           └── 60-net.rules
        └── sbin
            ├── pgetty
            └── watchdir
        
        builds/any/rootfs/buster/sysvinit/overlay/
        └── etc
            └── inittab
      ```
   2. 修改`inittab`中`ttys`相关配置
   3. 修改`inittab`中`console`相关配置



### boot & 开机自启动 (/etc/boot.d/boot) (串行)

/etc/inittab: `si0::sysinit:/etc/boot.d/boot`: (packages/base/all/boot.d/src/boot)

1. 导出环境变量：`export PATH=/sbin:/usr/sbin:/bin:/usr/bin`
2. 生成所有模块的依赖关系文件`/lib/modules/$(uname -r)/modules.dep(.bin)`，使系统能正确找到/加载模块及其依赖：`depmod -a`
3. 按字典顺序一次执行`/etc/boot.d/`下以数字开头的脚本：`for script in $(ls /etc/boot.d/[0-9]* | sort); do $script done`
4. 在开始执行rc.S脚本之前等待控制台刷新：`sleep 1`



### rc & 开机自启动 (/etc/init.d/rc) (串行/并发)

/etc/inittab: `si1::sysinit:/etc/init.d/rcS` -> link to `/lib/init/rcS`，即: `exec /etc/init.d/rc S` -> link to `/lib/init/rc S`

1. 设置环境变量，捕获错误退出情况
2. 确定当前和前一个运行级别
3. 加载系统配置
4. 检测并发启动能力（依赖于/etc/init.d/.depend.*文件）
5. 根据并发设置选择启动方法，onl中主要用`startpar`进行多并发
   1. startpar 读取 /etc/init.d/.depend.* 文件来了解服务之间的依赖关系
   2. 这些依赖文件由 insserv 工具生成， onlpm.py中生成deb包时存在 依赖项指定 ，安装服务脚本时存在 /usr/sbin/update-rc.d 调用。
6. 执行服务停止脚本（K开头的脚本）（切换运行级别或关机重启时才有用，开机时跳过），避免重复停止已经停止的服务。遍历`/etc/rc{runlevel}.d/K*`脚本，或`/etc/init.d/.depend.stop`。
7. 执行服务启动脚本（S开头的脚本），避免重复启动已经启动的服务。遍历`/etc/rc{runlevel}.d/S*`脚本，或运行级别S`/etc/init.d/.depend.boot`，或普通运行级别（2-5）的服务启动`/etc/init.d/.depend.start`。



### /etc/boot.d/ 来源

- `packages/base/all/boot.d/src/`: 
  - package: 
    - name: onl-bootd
    - path: packages/base/all/boot.d/PKG.yml
    - main: `- src : /etc/boot.d`
- `packages/base/all/vendor-config-onl/src/boot.d`
  - package:
    - name: onl-vendor-config-onl
    - path: packages/base/all/vendor-config-onl/PKG.yml
    - main: `- src/boot.d : /etc/boot.d`



















