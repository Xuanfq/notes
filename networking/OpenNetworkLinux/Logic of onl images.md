# Logic of onl images

## 制作和安装逻辑















## 文件来源详解

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
























