# GPT & MBR (分区表类型/磁盘分区方式)

> MBR: Master Boot Record, 主引导记录
>
> GPT: GUID Partition Table, 全局唯一标识分区表
>
> 
>
> MBR+BIOS = MBR+Legacy
>
> GPT+UEFI = GUID+UEFI



磁盘在进行格式化的时候，通常需要选择分区格式，而磁盘有两种分区方式：MBR格式与GPT格式



## **MBR（Master Boot Record）**主引导记录

相对古老的分区方式，自1982年创建，使用至今

MBR又叫做主引导扇区，是计算机开机后访问磁盘时读取的首个扇区，即位于硬盘的0号柱面(Cylinder)、0号磁头(Side)、1号扇区(Sector)。了解柱面、磁头、扇区。

该扇区占 512 字节（bytes）。它由三个部分组成：

- 主引导程序 446 bytes（boot loader，即主引导记录，现在Linux一般由grub2作为boot loader）

- 硬盘分区表 64 bytes （Disk Partition Table，存放磁盘分区数据的表）

- 结束标志位 2 bytes （固定为十六进制的55AA）。

MBR与GPT的区别在于硬盘分区表，这是由于MBR分区方式的缺陷导致的：

硬盘分区表是用来记录硬盘里面有多少个分区以及每一分区的大小，一共占 64 字节，即 16*4 ，所以最多只有4 个分区信息可以写到第一个扇区中，所以就称这4个分区为4个主分区 ( primary partion )，每个分区占16 bytes。在有限的空间内，需要记录分区表的详细情况：

![img](.GPT%20&%20MBR.assets/v2-02971255a86505e1d51ff69b10efc311_720w.webp)

可见分区表只有4个字节存储分区的总扇区数，最大能表示2的32次方的扇区个数，按每扇区512字节计算，每个分区最大不能超过2TB。

随着时代发展，硬盘容量不断扩展，使得之前定义的每个扇区512字节不再是那么的合理，于是将每个扇区512字节改为每个扇区4096 个字节，这意味着MBR的有效容量上限提升到16 TiB，伴随NTFS成为了标准的硬盘文件系统，同时这样的扇区大小也和其文件系统的默认分配单元大小（簇）匹配，提高了系统检索效率。

但是传统硬盘的每个扇区固定是512字节，4K扇区的硬盘，硬盘厂商为了保证与操作系统兼容性，也会将扇区模拟成512B扇区，这样又会造成4k对齐的问题。

有时候四个主分区会不够用，所以会将其中一个分区作为**扩展分区** ( extension partion )。扩展分区相当于一个指针（即只记录分区大小位置信息），用来指向某个有记录信息的分区，所以是不能直接存储数据的。由于操作系统的限制，扩展分区最多只有一个。

其分区表项指定扩展分区的起始位置和长度，在其中*最开始扇区* （EBR）和MBR相同位置（0x1BE）放置另外一个分区表，一般称为扩展分区表。扩展分区表的第一项指定扩展分区目前的逻辑分区信息，如果还有更多的 逻辑分区，扩展分区表的第二项指定下一个EBR的位置，否则为0。最后的两个分区表项总是为0。通过这种方式，一个硬盘上的分区数目就没有限制了。

如果想要更大的分区怎么办？



## **GPT（GUID partition table）**全局唯一标识分区表

作为新一代的磁盘分区形式，GPT磁盘具有分区大小、分区数量等的优势。

GPT是一个实体硬盘的分区表的结构布局的标准。它是可扩展固件接口（UEFI）标准的一部分，被用于替代BIOS系统中使用4字节来存储逻辑块地址和分区大小信息的主引导记录(MBR)分区表。GPT标准使用8字节用于记录逻辑块地址，因此，GPT分区格式在同等逻辑块大小的情况下，比MBR分区格式支持更大的硬盘空间。

出处于兼容性与安全性方面的考虑，GPT分区格式保留传统MBR，位于LBA0（第一个逻辑扇区），用于防止不支持GPT的硬盘管理软件错误识别并破坏硬盘数据。在这个MBR中，只有一个标志为0xEE的分区，以此表示这块硬盘使用GPT分区格式。不支持GPT分区格式的软件，会识别出未知类型的分区；支持GPT分区格式的软件，可正确识别GPT分区磁盘。

![img](.GPT%20&%20MBR.assets/v2-1b4067e55fd707b4156913a5f4477816_720w.webp)

1.GPT分区表，没有扩展分区与逻辑分区的概念，所有分区都是主分区。

2.GPT分区表可以划分出128个分区。

3.GPT分区表的每个分区的最大容量是18EB（1EB = 1024PB = 1,048,576TB），这么大，不用考虑硬盘容量太大的问题了。

4.GPT分区表需要与使用UEFI的电脑配合。





## **MBR和GPT之间的区别**

1. GPT支持大于2TB的分区，而传统的MBR磁盘（512k）不支持。

2. GPT方式支持磁盘划分128个分区，每个分区可达18EB容量

而MBR方式（512k）支持4个主分区（或者也可以是三个主分区加一个扩展分区和无限划分的逻辑卷）。每个分区可达2TB容量

3. GPT磁盘具有更高的性能，这是因为分区表的复制和循环冗余校验（CRC）保护机制来实现的。与MBR磁盘分区不同的是，GPT磁盘将系统相关的重要数据存放于分区中，而不是未分区或隐藏的扇区中。

4. GPT磁盘具有冗余的主分区表和备份分区表，可以优化分区数据结构的完整性。



通常来说，MBR和BIOS（MBR+BIOS）、GPT和UEFI（GPT+UEFI）是相辅相成的。这对于某些操作系统（例如 Windows）是强制性的，但是对于其他操作系统（例如 Linux）来说是可以选择的。


