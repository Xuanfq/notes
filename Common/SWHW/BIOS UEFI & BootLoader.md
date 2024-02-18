# BIOS UEFI & BootLoader



## 什么是BIOS

> `Basic Input Output System`（基本输入输出系统）
> 其实就是一组保存着计算机最重要的**基本输入输出的程序**、**开机后自检程序**、**系统自启动程序**，**并固化到计算机内主板上的一个ROM芯片上的程序**。

### **基本的输入输出是什么**

**BIOS的终极目标：**

> “BIOS的最主要的功能：初始化硬件平台和提供硬件的软件抽象，引导操作系统启动。”

所以：

输入的是：硬件平台的信息

输出的是：硬件的软件抽象

然后**将引导文件加载至内存引导操作系统启动**

### **自检程序“检”了什么**

![img](.BIOS%20UEFI%20&%20BootLoader.assets/v2-6de821d8b3f4afc990ca4aed6b3d452d_720w.webp)

每个硬件平台都需要发现IO总线，因为数据的传输离不开总线。

所谓的系统自检，就是`Power On Self Test`，也就是图中的`POST`过程。在传统`BIOS`的上电阶段，通过`IO`枚举发现总线，进入到标准描述的平台接口部分。

### **系统自启动了什么**

![img](.BIOS%20UEFI%20&%20BootLoader.assets/v2-1dd1aad2b0053668b30c31bf610199e2_720w.webp)

自启动了操作系统呀~毕竟按下电源只是启动了`BIOS`程序。

此外，在传统`BIOS`程序中，还不支持文件系统，不像上图的`Dell`主板，可以手动的添加引导文件，在传统`BIOS`启动之后，`BIOS`会自动加载`MBR`的主引导记录，使操作系统“自行启动”

**所以我们再看什么是`BIOS`？**

![img](.BIOS%20UEFI%20&%20BootLoader.assets/v2-6de821d8b3f4afc990ca4aed6b3d452d_720w.webp)

**输入**:围绕上图进行展开，左边部分刚好是硬件的初始化：`CPU`初始化、内存初始化……相当于是上面说的，输入的硬件平台信息。

**自检**:再经过中间部分的系统自检，控制台初始化、设备初始化、通过枚举发现总线并初始化。

**输出&自启动**:选择引导设备之后，通过`BIOS`将硬件平台的软件接口提供给`OS Loader`，以供操作系统运行使用。

`BIOS`的脉络就稍微有一些清楚了吧。

## **什么是UEFI BIOS**

> Unified Extensible Firmware Interface（统一可扩展固件接口）
> 由于安藤处理器芯片组的创新，64位架构的处理器已经不再适用传统BIOS的16位运行模式，英特尔将系统固件和操作系统之间的接口完全重新定义为一个可扩展的，标准化的固件接口规范。

`UEFI`名字听起来和`BIOS`相差较大，但是作为业界的新`BIOS`——`UEFI BIOS`，毕竟还是`BIOS`，所以它的主要目标就还是——**初始化硬件，提供硬件的软件抽象，并引导操作系统启动**

### **UEFI和BIOS的区别**

![img](.BIOS%20UEFI%20&%20BootLoader.assets/v2-147bbb5b3816276552e821241fa384ab_720w.webp)

**效率方面：**`BIOS`正是因为其闭源、接口混乱才导致其最终不适用于新架构的芯片，那时候刚好赶上开源的浪潮，`UEFI`开源且使用规定的标准接口，通过提供接口，也将大部分代码移步到了`C`代码，大大降低了开发难度，这也是其快速发展的根本原因。

**性能方面：**`UEFI`舍弃了硬件外部中断的低效方式，只保留了时钟中断，通过异步+事件来实现对外部设备的操作，性能因此得到极大的释放。

**扩展性和兼容性**:由于规范的模块化设计，在扩展功能时只需要动态链接其模块即可，扩展十分方便。而且传统`BIOS`必须运行在`16`位的指令模式下，寻址范围也十分有限，而`UEFI BIOS`支持64位的程序，兼容`32`位，这也是为什么`Windows XP`这么久了，稍微改改还可以安装在新设备上。

**安全性：**`UEFI`安装的驱动设备需要经过签名验证才可以，通过一定的加密机制进行验证，其安全性也非常的高。

**其他**：传统`BIOS`只支持容量不超过`2TB`的驱动器，原因是：按照常见的`512Byte`扇区，其分区表的单个分区的第`13-16`字节用来进行`LBA`寻址，也就是以扇区为单位进行寻址。

![img](.BIOS%20UEFI%20&%20BootLoader.assets/v2-62313843d3df17a6e80993cf580ce4e2_720w.webp)

`13-16`总共`4`个字节，`1Byte=8bit`，这样也就是`4*8=32`位，总共就是`2^32`个单位空间，以扇区为单位进行寻址，也就是每次`512Byte`，也就是：

![image-20240218220209532](.BIOS%20UEFI%20&%20BootLoader.assets/image-20240218220209532.png)

所以传统`BIOS`支持的最大容量的驱动器，不超过`2TB`。以硬件厂商`1000：1024`的计算方式，也就是`2.2TB`：

![image-20240218220225972](.BIOS%20UEFI%20&%20BootLoader.assets/image-20240218220225972.png)

那么`UEFI`支持多大的呢？

![img](.BIOS%20UEFI%20&%20BootLoader.assets/v2-7201f7cfca128c1dd2b2fa64fdfd2862_720w.webp)

采用类似的分区表，具体可以看[参考文章]。

`UEFI`支持`64`位的地址空间，所以其寻址偏移恰好为一个机器长度——`64`位，即`8Byte`，还是按照`LBA`寻址方式，按照上述计算：

![image-20240218220238780](.BIOS%20UEFI%20&%20BootLoader.assets/image-20240218220238780.png)

但是微软关方和一些其他资料都显示是`18EB`(按照硬件厂商`1000：1024`计算)：

![image-20240218220247541](.BIOS%20UEFI%20&%20BootLoader.assets/image-20240218220247541.png)

![img](.BIOS%20UEFI%20&%20BootLoader.assets/v2-d52baaa402ee52bb6d141d8e0db7de3a_720w.webp)

![img](.BIOS%20UEFI%20&%20BootLoader.assets/v2-10ac58ab959d5dba650ea40d21a810f4_720w.webp)

![img](.BIOS%20UEFI%20&%20BootLoader.assets/v2-4c7b2a0b4ab88f6677291719479953c4_720w.webp)

所以可以对微软官网的数据**证伪**。

> 由于现在又由`8`个`512Byte`扇区伪装一下，发展成了`4k`大小的扇区，所以上述计算还可以再乘`8`，即`GPT`最大分区容量可以是`64ZB`，而当前整个万维网的大小也不过`1ZB`

### **GPT分区的结构**

既然说到了`GPT`分区的大小问题，那就顺便稍微说一说它的结构吧，如上图：

![img](.BIOS%20UEFI%20&%20BootLoader.assets/v2-3f10e65bc8d8ee6db969f7aae3297bcf_720w.webp)

`PMBR`是`Protective MBR`，就是当作`MBR`用，位置在`LBA0`，如果是传统引导，就从这个地方寻找引导文件，如果是`UEFI`引导，再从后面的`GPT HDR`寻找，`GPT HDR`是**`GPT`表头**，位置在`LBA1`，记录其他表项的位置；

`LBA2-LBA33`总共`32`个分区表，记录对应分区的信息，比如起始地址和结束地址等，每个分区的信息用`128Byte`记录，也叫做**分区表项**，比较有意思的一点是，由于`Windows`只允许最多`128`个分区，所以`GPT`**一般**也就只设`32`个分区表。那这是为什么呢？

前面介绍，一个扇区一般是`512Byte`，按照微软的设定来，`128`个分区，也就需要`128`个分区表项来记录，一个分区表项`128Byte`，也就是总共

128∗128=2^7∗2^7=2^14

`32`个`512Byte`大小的扇区，是不是刚好：

32∗512=2^5∗2^9=2^14

这里可能只做了解即可。

至于后面的蓝色区域，对应之后，`LBA-1`是`GPT HDR`的备份表，`LBA-2 - LBA-33`是分区表的备份表，如果前面的数据发生错误，就从后面恢复就好啦~

中间的`LBA34-LBA-34`也就是除去表头、表项和备份表等信息的**分区**内容啦

### **UEFI与硬件初始化**

> `UEFI`纯粹地是一个接口规范
> 它不会具体涉及平台固件是如何实现的
> `UEFI`建立在被称为平台初始化（`Platform Initialization`，简称`PI`）标准的框架之上。
> **`PI`是关于`UEFI`具体如何实现的规范**

![img](.BIOS%20UEFI%20&%20BootLoader.assets/v2-67dff82a2d2d0fb821e4170abee9d504_720w.webp)

在`SEC`安全验证，初始化`cpu`和`cpu`内部资源，使`cache`作为`ram`提供堆栈运行C代码（`CAR`——`Cache As Ram`）

```
PEI`阶段初始化内存，并将需要传递的信息传递给`DXE
```

`DXE`驱动执行环境，内存已经可以完全被使用，初始化核心芯片，并将控制权转交给`UEFI`接口

`BDS`引导设备选择，负责初始化所有启动`OS`所需的设备，负责执行所有符合`UEFI`驱动模型的驱动。

选择完引导设备，就加载`OS loader`运行`OS`

`OS`启动后，系统的控制权从UEFI转交给`OS loader`，`UEFI`占用的资源被回收到`OS loader`，只保留`UEFI`运行是服务。

其实再统观一下上面的流程，是不是就变成了：**基本输入>>>`PI`>>>`UEFI`>>>基本输出**

这个过程是不是又像`BIOS`了？毕竟`UEFI`还是用作`BIOS`的。

![img](.BIOS%20UEFI%20&%20BootLoader.assets/v2-8c33e969a09d6bd35607a683e4e3a5fa_720w.webp)

如果还是觉得`UEFI`和`BIOS`是两回事，那么可以换种解读：

`Rom Stage`：一开始运行在`Rom`中，初始化`Cache`作为`Ram`运行，从而有了初步的`C`环境，运行`C`代码。

`Ram Stage`：初始化一定的硬件之后，`BIOS`程序进入到`Ram`中，继续初始化芯片组、主板等硬件。

`Find something to boot`：最后找到启动设备，把控制权交给操作系统内核，开始操作系统的时代。

## **什么是Boot Loader**

> **`Boot Loader`是在操作系统内核运行前执行的一小段程序**，执行的工作听起来和`BIOS`很像：初始化硬件，和引导系统，相当于`UEFI`启动过程中的`PEI`初始化硬件、`DXE`识别启动设备，`BDS`把权限交给启动加载器，引导内核。

对比一下`UEFI`和`Boot Loader`的启动方式：

![img](.BIOS%20UEFI%20&%20BootLoader.assets/v2-67dff82a2d2d0fb821e4170abee9d504_720w.webp)

![img](.BIOS%20UEFI%20&%20BootLoader.assets/v2-7ec4387787dd2d804073b0b42928430a_720w.webp)

再分析`Boot Loader`的启动过程：

首先硬件设备初始化。为加载 `Boot Loader` 的 `stage2` 准备 `RAM` 空间。拷贝 `Boot Loader` 的 `stage2` 到 `RAM` 空间中。设置好堆栈。跳转到 `stage2` 的 `C` 入口点。

初始化本阶段要使用到的硬件设备。检测系统内存映射(`memory map`)。将`kernel` 映像和根文件系统映像从 `flash` 上读到 `RAM` 空间中。为内核设置启动参数。调用内核。

> PS:有的Boot Loader可能只有一个过程，上述为两个阶段的类型。

**几个问题：**

1. `BIOS`为什么固化到`ROM`芯片上？
   因为掉电不丢失
2. 只读存储器的话，又不能作修改，还有界面干什么？
   要作修改，修改内容在`CMOS`中
3. 现在的`BIOS`固化到哪了？
   `ROM`->`PROM`->`EPROM`->`EEPROM`->`FLASH`。

- 一开始是在`ROM`上，但是只能检验，不能修改，十分的不方便，所以就转到了`PROM`
- `PROM`可编程`ROM`，但是写入后也不能改，
- 然后就是`EPROM`，可擦除可编程`ROM`，但是人们又觉得不方便，
- 于是又有了`EEPROM`，电可擦除可编程`ROM`，而且双电压可防毒。
- `Flash`闪存，更方便，只要用专用程序即可修改，



## 参考文章

> **[bios](https://link.zhihu.com/?target=https%3A//baike.baidu.com/item/bios/91424)**
>
> **[为什么要有BIOS？BIOS那些恼人的小问题集锦（一）](https://zhuanlan.zhihu.com/p/45352657)**
>
> **[UEFI与硬件初始化](https://zhuanlan.zhihu.com/p/25941340)**
>
> **[统一可扩展固件接口](https://link.zhihu.com/?target=https%3A//baike.baidu.com/item/%E7%BB%9F%E4%B8%80%E5%8F%AF%E6%89%A9%E5%B1%95%E5%9B%BA%E4%BB%B6%E6%8E%A5%E5%8F%A3/22786233%3Ffromtitle%3DUEFI%26fromid%3D3556240)**
>
> **[UEFI背后的历史](https://zhuanlan.zhihu.com/p/25281151)**
>
> **[UEFI和BIOS的区别优缺点详解](https://link.zhihu.com/?target=http%3A//www.dnxtc.net/zixun/yingyongjiqiao/2018-06-13/2605.html)**
>
> **[MBR分区表为什么最大只能识别2TB硬盘容量](https://link.zhihu.com/?target=https%3A//www.cnblogs.com/harrymore/p/13782261.html)**
>
> **[MBR为什么最大只能用2TB](https://link.zhihu.com/?target=https%3A//blog.csdn.net/hyy5801965/article/details/51136395)**
>
> **[UEFI和UEFI论坛](https://zhuanlan.zhihu.com/p/25676417)**
>
> **[笔记三（UEFI详解）](https://link.zhihu.com/?target=https%3A//www.cnblogs.com/ScvQ/p/9224963.html)**
>
> **[UEFI 引导与 传统BIOS 引导在原理上有什么区别？芯片公司在其中扮演什么角色？](https://zhuanlan.zhihu.com/p/81960137)**
>
> **[一个UEFI引导程序的实现](https://link.zhihu.com/?target=https%3A//www.ituring.com.cn/book/tupubarticle/26793)**
>
> **[ROM、PROM、EPROM、EEPROM、RAM、SRAM、DRAM的区别](https://link.zhihu.com/?target=https%3A//wenku.baidu.com/view/d5ec5fe4ad51f01dc281f1cd.html)**
>
> **[Windows and GPT FAQ](https://link.zhihu.com/?target=https%3A//docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-and-gpt-faq)**
>
> **[GUID Partition Table (GPT)](https://link.zhihu.com/?target=http%3A//www.ntfs.com/guid-part-table.htm)**
>
> **[GPT磁盘分区的结构原理](https://link.zhihu.com/?target=https%3A//www.dgxue.com/huifu/124.html)**