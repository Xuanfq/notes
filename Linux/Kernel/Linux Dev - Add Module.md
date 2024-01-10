

# Module

## Command About
- lsmod
  - 展示内核中 Module 的状态
  - cat /proc/modules
  - lsmod | grep xxx
- insmod/rmmod
  - 插入/卸载 Module
- modprobe xxx
  - 添加 Module 到内核
  - 删除 Module (modeprobe -r)
  - 推荐使用 modprobe 加载卸载 Module，可以维护依赖关系    
- modinfo
  - 展示 Module 的信息
- depmod
  - 生成 modules.dep 文件
  - 描述 Module 之间的依赖关系


## Module Demo

- 对应内核版本的头文件
  - sudo pacman -S core/linux515-headers(5.15为本机的内核版本)
  - 位置:/ib/modules/S(uname-r)/build
- 编译
  - make
- 加载
  - sudo insmod hello.ko
- 查看
  - lsmod | grep hello
  - modinfo hello.ko
  - sudo dmesg
- 卸载
  - sudo rmmod hello


### Demo Code

**hello.c**
```c
#include <linux/init.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Aiden Qiu");
MODULE_DESCRIPTION("hello module");
MODULE_VERSION("0.1");

static int __init hello_start(void)
{
  printk(KERN_INFO "Loading hello module\n");
  printk(KERN_INFO "Hello World!\n");
  return 0;
}

static void __exit hello_end(void)
{
  printk(KERN_INFO "exit hello module\n");
}

module_init(hello_start);
module_exit(hello_end);
```

**Makefile**
```Makefile
.PHONY: all clean

obj-m=hello.o

all:
  make -C /lib/modules/${shell uname -r}/build/ M=${PWD} modules
clean:
  make -C /lib/modules/${shell uname -r}/build/ M=${PWD} clean
```




























