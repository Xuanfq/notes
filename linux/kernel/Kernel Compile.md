
# Kernel Compile

1. Make Config, such as `make menuconfig`
2. Make Compile to get the `bzImage` file, such as `make -j 4`
3. Make Install to install into os, such as `make install`


## Make Config

delete `.config` file by command `make mrproper`

### make menuconfig

Command: `make  menuconfig`


### make xconfig
Need `Qt5`

Command: `make  xconfig`

```bash
*
* Could not find Qt5 via pkg-config.
* Please install Qt5 and make sure it's in PKG_CONFIG_PATH
*
```


### make gconfig
Need `GTK Package`

Command: `make  gconfig`

```bash
*
* Unable to find the GTK+ installation. Please make sure that
* the GTK+ 2.0 development package is correctly installed.
* You need gtk+-2.0 gmodule-2.0 libglade-2.0
*
```


## Make Compile

Command: `make`

```bash
aiden@Xuanooo:~/kernel/linux-5.19$ make -j12
  ...
  AS      arch/x86/boot/header.o
  LD      arch/x86/boot/setup.elf
  OBJCOPY arch/x86/boot/setup.bin
  BUILD   arch/x86/boot/bzImage
Kernel: arch/x86/boot/bzImage is ready  (#1)
aiden@Xuanooo:~/kernel/linux-5.19$
```

### Make
make build by command: `make`


### Make Qiuckly
make build by command: `make -j 4`, `4` means thead number used to make.



## Make Install

To install into os, use command: `make install`.



## Kernel Driver Compile

### Compile Single Module

```bash
cd linux-x.x.x

make oldconfig && make prepare && make scripts

cd path/to/driver

# config build as module first
# make CONFIG_BRIDGE=m -C /path/to/linux-x.x.x/ M=`pwd` modules
make CONFIG_DRIVER_AS_MODULE=m -C /path/to/linux-x.x.x/ M=`pwd` modules
```

### Compile all Modules


```bash
cd linux-x.x.x

make oldconfig && make prepare && make scripts

# config build as module first

make modules -j12
```














