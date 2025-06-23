# 基于ioctl的接口

**`ioctl()`是应用程序与设备驱动程序交互的最常见方式**。它很灵活，通过添加新命令可轻松扩展，并且可以通过字符设备、块设备以及套接字和其他特殊文件描述符传递。

`ioctl`是设备驱动程序中对设备的I/O通道进行管理的函数。所谓对I/O通道进行管理，就是对设备的一些特性进行控制，例如串口的传输波特率、马达的转速等等。它的调用个数如下：`int ioctl(int fd, ind cmd, …);`或`#include <sys/ioctl.h>; int ioctl(int fd, unsigned long request, ...);`。

其中fd是用户程序打开设备时使用open函数返回的文件标示符，cmd是用户程序对设备的控制命令，至于后面的省略号，那是一些补充参数，一般最多一个，这个参数的有无和cmd的意义相关。

`ioctl`函数是文件结构中的一个属性分量，就是说如果你的驱动程序提供了对ioctl的支持，用户就可以在用户程序中使用ioctl函数来控制设备的I/O通道。

`ioctl`命令定义也很容易出错，而且之后若不破坏现有应用程序就很难修正，因此本文档旨在帮助开发者正确定义。



## `ioctl()`示例

本例中，我们让ioctl传递三个命令，分别是一个无参数、读参数、写参数三个指令。使用字符’a’作为幻数，三个命令的作用分别是用户程序让驱动程序打印一句话（无参数），用户程序从驱动程序读一个int型数（读参数），用户程序向驱动程序写一个int型数（写参数）。


### Kernel Driver

ioctl_test.c
```c
#include <linux/init.h>
#include <linux/module.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/uaccess.h>
#include <linux/ioctl.h>

#define CMD_IOC_MAGIC	'a'
#define CMD_IOC_0		_IO(CMD_IOC_MAGIC, 0)
#define CMD_IOC_1		_IOR(CMD_IOC_MAGIC, 1, int)
#define CMD_IOC_2		_IOW(CMD_IOC_MAGIC, 2, int)

MODULE_LICENSE("GPL");
MODULE_AUTHOR("zz");

static dev_t devno;

static int demo_open(struct inode *ind, struct file *fp)
{
	printk("demo open\n");
	return 0;
}

static int demo_release(struct inode *ind, struct file *fp)
{
	printk("demo release\n");
	return 0;
}

static long demo_ioctl(struct file *fp, unsigned int cmd, unsigned long arg)
{
	int rc = 0;
	int arg_w;
	const int arg_r = 566;
	if (_IOC_TYPE(cmd) != CMD_IOC_MAGIC) {
		pr_err("%s: command type [%c] error.\n", __func__, _IOC_TYPE(cmd));
		return -ENOTTY;
	}

	switch(cmd) {
		case CMD_IOC_0:
			printk("cmd 0: no argument.\n");
			rc = 0;
			break;
		case CMD_IOC_1:
			printk("cmd 1: ioc read, arg = %d.\n", arg_r);
			copy_to_user((int *)arg, &arg_r, sizeof(arg_r));
			rc = 1;
			break;
		case CMD_IOC_2:
			arg_w = arg;
			printk("cmd 2: ioc write, arg = %d.\n", arg_w);
			rc = 2;
			break;
		default:
			pr_err("%s: invalid command.\n", __func__);
			return -ENOTTY;
	}
	return rc;
}

static struct file_operations fops = {
	.open = demo_open,
	.release = demo_release,
	.unlocked_ioctl = demo_ioctl,
};

static struct cdev cd;

static int demo_init(void)
{
	int rc;
	rc = alloc_chrdev_region(&devno, 0, 1, "test");
	if(rc < 0) {
		pr_err("alloc_chrdev_region failed!");
		return rc;
	}
	printk("MAJOR is %d\n", MAJOR(devno));
	printk("MINOR is %d\n", MINOR(devno));

	cdev_init(&cd, &fops);
	rc = cdev_add(&cd, devno, 1);
	if (rc < 0) {
		pr_err("cdev_add failed!");
		return rc;
	}
	return 0;
}

static void demo_exit(void)
{
	cdev_del(&cd);
	unregister_chrdev_region(devno, 1);
	return;
}

module_init(demo_init);
module_exit(demo_exit);

```


### Userspace Ops

user_ioctl.c
```c
#include <sys/ioctl.h>

#define CMD_IOC_MAGIC	'a'
#define CMD_IOC_0		_IO(CMD_IOC_MAGIC, 0)
#define CMD_IOC_1		_IOR(CMD_IOC_MAGIC, 1, int)
#define CMD_IOC_2		_IOW(CMD_IOC_MAGIC, 2, int)

#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include "user_ioctl.h"

int main()
{
	int rc;
	int arg_r;
	const int arg_w = 233;
	int fd = open("/dev/test_chr_dev", O_RDWR);
	if (fd < 0) {
		printf("open file failed!\n");
		return -1;
	}

	rc = ioctl(fd, CMD_IOC_0);
	printf("rc = %d.\n", rc);

	rc = ioctl(fd, CMD_IOC_1, &arg_r);
	printf("ioc read arg = %d, rc = %d.\n", arg_r, rc);

	rc = ioctl(fd, CMD_IOC_2, arg_w);
	printf("ioc write arg = %d, rc = %d.\n", arg_w, rc);

	close(fd);
	return 0;
}

```

### Makefile

```makefile
ifneq ($(KERNELRELEASE),)
	obj-m := ioctl_test.o
else
	KDIR    := /lib/modules/$(shell uname -r)/build
	PWD     := $(shell pwd)
all:
	make -C $(KDIR) M=$(PWD) modules
	gcc user_ioctl.c -o user
clean:
	make -C $(KDIR) M=$(PWD) clean
	rm -rf user
endif
```


### Test

```bash
aiden@Xuanfq:~/temp$ make
make -C /lib/modules/6.6.87.2-microsoft-standard-WSL2+/build M=/home/aiden/temp modules
make[1]: Entering directory '/home/aiden/WSL2-Linux-Kernel'
  CC [M]  /home/aiden/temp/ioctl_test.o
  MODPOST /home/aiden/temp/Module.symvers
  CC [M]  /home/aiden/temp/ioctl_test.mod.o
  LD [M]  /home/aiden/temp/ioctl_test.ko
  BTF [M] /home/aiden/temp/ioctl_test.ko
make[1]: Leaving directory '/home/aiden/WSL2-Linux-Kernel'
gcc user_ioctl.c -o user
aiden@Xuanfq:~/temp$ ls
ioctl_test.c   ioctl_test.mod    ioctl_test.mod.o  Makefile       Module.symvers  user_ioctl.c
ioctl_test.ko  ioctl_test.mod.c  ioctl_test.o      modules.order  user
aiden@Xuanfq:~/temp$ sudo insmod ioctl_test.ko 
aiden@Xuanfq:~/temp$ sudo dmesg -c
...
[ 1189.828472] ioctl_test: loading out-of-tree module taints kernel.
[ 1189.829308] MAJOR is 240
[ 1189.829312] MINOR is 0
aiden@Xuanfq:~/temp$ sudo mknod /dev/test_chr_dev c 240 0
aiden@Xuanfq:~/temp$ sudo ./user
rc = 0.
ioc read arg = 566, rc = 1.
ioc write arg = 233, rc = 2.
aiden@Xuanfq:~/temp$ sudo dmesg -c
[ 1305.582843] demo open
[ 1305.582847] cmd 0: no argument.
[ 1305.582900] cmd 1: ioc read, arg = 566.
[ 1305.582905] cmd 2: ioc write, arg = 233.
[ 1305.582909] demo release
aiden@Xuanfq:~/temp$ 
```







## `ioctl()`命令编号定义

命令编号，或请求编号，是传递给ioctl系统调用的第二个参数。虽然它可以是任何一个能唯一标识特定驱动程序操作的32位数字，但在定义这些数字时存在一些约定。

`include/uapi/asm-generic/ioctl.h` 提供了四个宏，用于定义遵循现代惯例的 `ioctl` 命令：`_IO`、`_IOR`、`_IOW` 和 `_IOWR`。

```c
// include/uapi/asm-generic/ioctl.h
#define _IO(type,nr)		_IOC(_IOC_NONE,(type),(nr),0)
#define _IOR(type,nr,size)	_IOC(_IOC_READ,(type),(nr),(_IOC_TYPECHECK(size)))
#define _IOW(type,nr,size)	_IOC(_IOC_WRITE,(type),(nr),(_IOC_TYPECHECK(size)))
#define _IOWR(type,nr,size)	_IOC(_IOC_READ|_IOC_WRITE,(type),(nr),(_IOC_TYPECHECK(size)))

/* used to decode ioctl numbers.. */
#define _IOC_DIR(nr)		(((nr) >> _IOC_DIRSHIFT) & _IOC_DIRMASK)
#define _IOC_TYPE(nr)		(((nr) >> _IOC_TYPESHIFT) & _IOC_TYPEMASK)
#define _IOC_NR(nr)		(((nr) >> _IOC_NRSHIFT) & _IOC_NRMASK)
#define _IOC_SIZE(nr)		(((nr) >> _IOC_SIZESHIFT) & _IOC_SIZEMASK)
```

所有新命令都应使用这些宏，并带有正确的参数：

- `_IO/_IOR/_IOW/_IOWR`(dir,direction): 宏名称指定了参数将如何使用。它可以是指向要传入内核（_IOW）、传出内核（_IOR）或双向传输（_IOWR）的数据的指针。_IO 可以表示不带参数的命令，或者表示传递整数值而非指针的命令。建议仅对不带参数的命令使用 _IO，而使用指针来传递数据。
- `type`: 一个8位数字，通常是字符文字，特定于子系统或驱动程序，并在控制码编号中列出。即device type，表示设备类型，也可翻译成“幻数”或“魔数”，可以是任意一个char型字符，如’a’、‘b’、‘c’等，其主要作用是使ioctl命令具有唯一的设备标识。不过在内核中’w’、‘y’、'z’三个字符已经被使用了。
- `nr`: 一个8位数字，用于标识特定的命令，对于给定的同一个`type`值是唯一的。也即number，命令编号/序数，取值范围0~255，在定义了多个ioctl命令的时候，通常从0开始顺次往下编号。
- `size`: 涉及到ioctl的参数arg，占据13bit或14bit，这个与体系有关，arm使用14bit。用来传递arg的数据类型的长度，比如如果arg是int型，我们就将这个参数填入int，系统会检查数据类型和长度的正确性。
  - `data_type`: 参数所指向的数据类型的名称，命令编号将 sizeof(data_type) 值编码为一个13位或14位整数，这使得参数的最大大小限制为8191字节。注意：不要将sizeof(data_type)类型传递给 _IOR/_IOW/IOWR，因为这将导致对sizeof(sizeof(data_type))（即sizeof(size_t)）进行编码。_IO 没有 data_type 参数。



## 接口版本

一些子系统在数据结构中*使用版本号*，以便对具有不同参数解释的命令进行重载。

这通常*不是一个好主意*，因为对现有命令的更改往往会破坏现有应用程序。

更好的方法是*添加一个具有新编号的新ioctl命令*。为了兼容性，旧命令仍需要在内核中实现，但这可以是对新实现的一个包装。



## `ioctl()`返回码

正如在 `errno(3)` 中所记录的那样，`ioctl` 命令可以返回负的错误码；这些错误码会在用户空间转换为 `errno` 值。成功时，返回码应为零。也可以返回一个正的 “long” 值，但不推荐这么做。

当使用未知的命令编号调用`ioctl`回调时，处理程序会返回 `-ENOTTY` 或 `-ENOIOCTLCMD`，这也会导致系统调用返回 `-ENOTTY`。由于历史原因，一些子系统在此处返回 `-ENOSYS` 或 `-EINVAL`，但这是错误的。

在`Linux 5.5`之前，兼容的`ioctl`处理程序需要返回 `-ENOIOCTLCMD`，以便使用回退转换为原生命令。由于现在所有子系统都自行负责处理兼容模式，这不再必要，但在将错误修复反向移植到旧内核时，这一点可能仍值得考虑。



## 时间戳

传统上，时间戳和超时值是以`struct timespec`或`struct timeval`的形式传递的，但由于在迁移到64位`time_t`后，用户空间中这些结构的定义不兼容，这就产生了问题。

当需要单独的秒数/纳秒数，或者需要直接传递到用户空间时，可以使用 `struct __kernel_timespec` 类型来嵌入到其他数据结构中。不过，这仍然不太理想，因为该结构与内核的 `timespec64` 或用户空间的 `timespec` 都不完全匹配。可以使用 `get_timespec64()` 和 `put_timespec64()` 辅助函数来确保布局与用户空间保持兼容，并正确处理填充。

由于将秒转换为纳秒成本较低，而反过来则需要进行昂贵的64位除法运算，因此使用一个简单的 `__u64` 纳秒值可能更简单且更高效。

超时值和时间戳理想情况下应使用`CLOCK_MONOTONIC`时间，即由`ktime_get_ns()` 或 `ktime_get_ts64()` 返回的时间。与`CLOCK_REALTIME`不同，这使得时间戳不会因闰秒调整和`clock_settime()`调用而向前或向后跳跃。

`ktime_get_real_ns()` 可用于 `CLOCK_REALTIME` 时间戳，这些时间戳需要在重启或多台机器之间保持持久。



## 32位兼容模式

为了支持在64位机器上运行32位用户空间，实现`ioctl`回调处理程序的每个子系统或驱动程序还必须实现相应的`compat_ioctl`处理程序。

只要遵循数据结构的所有规则，这就像将`.compat_ioctl`指针设置为诸如`compat_ptr_ioctl()`或`blkdev_compat_ptr_ioctl()`之类的辅助函数一样简单。



## compat_ptr()

在s390架构上，31位用户空间的数据指针存在模糊表示，高位会被忽略。当以兼容模式运行这样的进程时，必须使用`compat_ptr()`辅助函数来清除`compat_uptr_t`的高位，并将其转换为有效的64位指针。在其他架构上，这个宏仅执行向`<void __user *>`指针的类型转换。

在`compat_ioctl()`回调函数中，最后一个参数是`unsigned long`类型，根据具体命令，它既可以被解释为指针，也可以被解释为标量。如果它是标量，那么一定不要使用`compat_ptr()`，以确保64位内核在处理高位被置1的参数时，其行为与32位内核一致。

对于仅接受指向兼容数据结构的指针作为参数的驱动程序，`compat_ptr_ioctl()` 辅助函数可用于替代自定义的 `compat_ioctl` 文件操作。



## 结构布局

兼容的数据结构在所有架构上具有相同的布局，避免了所有有问题的成员：

- `long` 和 `unsigned long` 的大小与寄存器相同，因此它们可以是32位或64位宽，并且不能用于可移植的数据结构。固定长度的替代类型是 `__s32`、`__u32`、`__s64` 和 `__u64`。

- 指针也存在同样的问题，此外还需要使用`compat_ptr()`。最好的解决方法是使用`__u64`代替指针，这在用户空间需要转换为`uintptr_t`，在内核中需要使用`u64_to_user_ptr()`将其转换回用户指针。

- 在`x86 - 32（i386）`架构中，64位变量的对齐方式仅为32位，但在包括`x86 - 64`在内的大多数其他架构上，它们是自然对齐的。这意味着类似这样的一个结构体：

```c
struct foo {
    __u32 a;
    __u64 b;
    __u32 c;
};
```

在`x86 - 64`架构上，a和b之间有4个字节的填充，末尾还有另外4个字节的填充，但在i386架构上没有填充，并且它需要一个`compat_ioctl`转换处理程序来在这两种格式之间进行转换。

为避免此问题，**所有结构体的成员都应自然对齐**，或者添加显式保留字段来替代隐式填充。可以使用 pahole 工具检查对齐情况。

- 在`ARM OABI`用户空间中，结构体被填充为32位的倍数，这使得一些结构体如果不以32位边界结尾，就会与现代EABI内核不兼容。

- 在m68k架构上，结构体成员的对齐方式不能保证大于16位，在依赖隐式填充时这会成为一个问题。

- `Bitfields`位域和`enums`枚举通常按预期工作，但它们的某些属性是由实现定义的，因此最好在ioctl接口中完全避免使用它们。

- `char` 成员可以是有符号的，也可以是无符号的，这取决于具体的架构。因此，对于8位整数值，应使用 `__u8` 和 `__s8` 类型，不过对于定长字符串，`char` 数组更为清晰。



## 信息泄露

*未初始化*的数据不得复制回用户空间，因为这可能会导致信息泄露，攻击者可利用这些泄露的信息来*绕过内核地址空间布局随机化（KASLR）*，进而发起攻击。

出于这个原因（以及兼容性支持的考虑），最好*避免数据结构中出现任何隐式填充*。对于现有结构中存在隐式填充的情况，内核驱动程序在将*结构实例*复制到用户空间之前，必须谨慎地对其进行**完全初始化**。这通常是通过在为各个成员赋值之前调用 `memset()` 来实现的。



## 子系统抽象`ioctl()`

虽然有些设备驱动程序实现了自己的`ioctl`函数，但*大多数子系统会为多个驱动程序实现相同的命令*。**理想情况下，子系统有一个`.ioctl()`处理程序**，该处理程序在用户空间与内核空间之间复制参数，并通过普通的内核指针将这些参数传递给子系统特定的回调函数。

这在多个方面有所帮助：

- 如果用户空间应用程序二进制接口（ABI）没有细微差异，那么为一个驱动程序编写的应用程序更有可能在同一子系统中的另一个驱动程序上运行。

- 用户空间访问和数据结构布局的复杂性在一处完成，减少了实现漏洞的可能性。

- 与仅在单个驱动程序中使用ioctl相比，当ioctl在多个驱动程序之间共享时，更有可能由经验丰富的开发人员进行审查，他们能够发现接口中的问题。



## ioctl的替代方案

在很多情况下，`ioctl`并非解决问题的最佳方案。替代方案包括：

- 对于一种*与物理设备无关*且*不受字符设备节点的文件系统权限限制*的系统级功能而言，`系统调用`是更好的选择。

- 通过套接字配置任何网络相关对象时，`netlink`是首选方式。

- `debugfs`用于实现一些专门的调试接口，这些接口无需作为稳定接口向应用程序公开。

- `sysfs`是一种很好的方式，用于公开与文件描述符无关的内核对象的状态。

- 与`sysfs`相比，`configfs`可用于更复杂的配置。

- 自定义文件系统可以通过简单的用户界面提供额外的灵活性，但会给实现增加大量复杂性。
