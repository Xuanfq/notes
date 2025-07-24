# Logic of onl images

## 制作和安装逻辑















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



### rc & 开机自启动 (并发) (/etc/init.d/rc)

`/etc/init.d/rcS` -> link to `/lib/init/rcS`，即: `exec /etc/init.d/rc S` -> link to `/lib/init/rc S`

1. 设置环境变量，捕获错误退出情况
2. 确定当前和前一个运行级别
3. 加载系统配置
4. 检测并发启动能力（依赖于/etc/init.d/.depend.*文件）
5. 根据并发设置选择启动方法，onl中主要用`startpar`进行多并发
   1. startpar 读取 /etc/init.d/.depend.* 文件来了解服务之间的依赖关系
   2. 这些依赖文件由 insserv 工具生成， onlpm.py中生成deb包时存在 依赖项指定 ，安装服务脚本时存在 /usr/sbin/update-rc.d 调用。
6. 执行服务停止脚本（K开头的脚本）（切换运行级别或关机重启时才有用，开机时跳过），避免重复停止已经停止的服务。遍历`/etc/rc{runlevel}.d/K*`脚本，或`/etc/init.d/.depend.stop`。
7. 执行服务启动脚本（S开头的脚本），避免重复启动已经启动的服务。遍历`/etc/rc{runlevel}.d/S*`脚本，或运行级别S`/etc/init.d/.depend.boot`，或普通运行级别（2-5）的服务启动`/etc/init.d/.depend.start`。




















