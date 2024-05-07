
## WSL2 Install Linux Kernel Module

编译内核模块，需要linux-headers文件， Ubuntu, Centos一般会有相应的headers安装包并安装在`/usr/src/linux-header-generic-$(uname -r)`目录下。在WSL2中没有相应的headers文件，需要手动下载`WSL2`的 `linux kernel` 源码。

**Download Link**: https://github.com/microsoft/WSL2-Linux-Kernel/tags 

下载压缩包并解压后，进入kernel目录, 运行下面三个命令：
```sh
cp Microsoft/config-wsl .config
make scripts
make modules
```


### 内核模块示例

**`hello.c`**
```c
#include <linux/module.h>

static int __init lkm_init(void)
{
    printk("Hello, Calvin!\n");
    return 0;
}

static void __exit lkm_exit(void)
{
    printk("Goodbye, Calvin!\n");
}

module_init(lkm_init);
module_exit(lkm_exit);

MODULE_LICENSE("GPL");
```

**`Makefile`**
```Makefile
obj-m:=hello.o
CURRENT_PATH:=$(shell pwd)
LINUX_KERNAL:=$(shell uname -r)
LINUX_KERNAL_PATH:=/usr/src/WSL2-Linux-Kernel-$(LINUX_KERNAL)

all:
	make -C $(LINUX_KERNAL_PATH) M=$(CURRENT_PATH) modules
clean:
	make -C $(LINUX_KERNAL_PATH) M=$(CURRENT_PATH) clean
```

**`Command`**
- sudo insmod hello.ko  //插入模块
- sudo rmmode hello // 卸载模块
- modinfo hello.ko // 查看模块信息
- lsmod //查看系统模块
- dmesg // 查看系统日志信息


















