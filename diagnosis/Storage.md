# Storage

- 块设备
  - SSD
    - SATA设备 (/dev/sda)
    - NVMe设备 (/dev/nvme0n0, PCIe)
  - eMMC存储 (/dev/mmcblk0p0)
  - USB存储设备 (/dev/sdb)
- MTD，Memory Technology Device
  - NOR闪存 (/dev/mtd0)
  - NAND闪存 (/dev/mtd0)

MTD (Memory Technology Device) → 内存技术设备 （既非块设备也不是字符设备，但可以同时提供字符设备和块设备接口来操作它）
JFFS2 (Journaling Flash File System 2) → 日志闪存文件系统2 （基于 MTD 设备）
UBI (Unsorted Block Images) → 无序块镜像 （基于 MTD 设备）
NOR/NAND flash → NOR/NAND闪存 （非易失性存储, MTD 设备）


## 类型分类

### 按存储介质分类

根据数据存储的物理介质不同，可分为**半导体存储**、**磁存储**和**光存储**三大类。



#### 1. 半导体存储（Solid State Storage）

利用半导体器件（如晶体管）存储数据，无机械运动部件，速度快、抗震性强。

- 类型
  - 随机存取存储器（RAM）
    - 特点：临时存储，断电数据丢失。
    - 常见类型：
      - DDR（Double Data Rate）：如 DDR4、DDR5，用于计算机内存。
      - SRAM（静态随机存储器）：速度更快，成本更高，用于 CPU 缓存。
  - 只读存储器（ROM）
    - 特点：数据固化，一般不可修改（或需特殊方式修改），断电后数据保留。
    - 常见类型：
      - EPROM、EEPROM：用于嵌入式系统固件（如主板 BIOS）。
  - 固态硬盘（SSD，Solid State Drive）
    - 特点：使用 NAND 闪存芯片存储数据，替代传统机械硬盘（HDD）。
    - 分类：
      - NAND 闪存类型
        - SLC（单层单元）：速度快、寿命长，成本高，多用于企业级场景。
        - MLC（双层单元）：性价比平衡，早期消费级 SSD 常用。
        - TLC（三层单元）/ QLC（四层单元）：成本低、容量大，寿命较短，主流消费级 SSD。
      - **接口类型**：SATA、PCIe（NVMe 协议）、M.2、U.2 等。
  - 嵌入式存储（eMMC/eMCP、UFS）
    - 特点：集成控制器和闪存芯片，体积小，用于智能手机、平板等移动设备。
    - 常见标准：UFS（Universal Flash Storage），支持更快的读写速度。



#### 2. 磁存储（Magnetic Storage）

通过磁介质（如磁盘、磁带）的磁化状态存储数据，依赖机械运动部件。

- 类型
  - 机械硬盘（HDD，Hard Disk Drive）
    - 特点：由旋转磁盘和磁头臂组成，容量大、成本低，但速度较慢、易受物理冲击。
    - 应用场景：计算机存储、数据中心海量存储。
  - 磁带存储（Tape Storage）
    - 特点：基于磁带介质，容量极大（单盘可达 TB 级）、成本极低，但访问速度慢（顺序读写）。
    - 应用场景：企业级数据备份、归档存储。



#### 3. 光存储（Optical Storage）

利用激光读取和写入数据，通过介质表面的光学特征（如凹坑）存储信息。

- 类型
  - CD/DVD/ 蓝光光盘（BD）
    - 特点：容量较低（CD 约 700MB，蓝光光盘最高约 100GB），适合长期存档（寿命可达数十年）。
    - 分类：只读型（如 CD-ROM）、可写型（如 CD-R/W）。



### 按存储设备接口分类

接口决定了存储设备与主机的连接方式和数据传输速度。

- 类型
  - 并行接口
    - IDE（PATA）：早期硬盘、光驱接口，已淘汰。
    - SCSI：服务器和高端存储设备，支持多设备连接。
  - 串行接口
    - SATA（Serial ATA）：主流机械硬盘和部分 SSD 接口，最高速度 6 Gbps。
    - SAS（Serial Attached SCSI）：服务器硬盘接口，速度更高（12 Gbps+），支持热插拔。
    - PCIe（Peripheral Component Interconnect Express）：
      - 用于高性能 SSD（NVMe 协议），速度可达数 GB/s（如 PCIe 4.0 x4 接口带宽约 8 GB/s）。
  - 外部接口
    - USB（Universal Serial Bus）：U 盘、移动硬盘、USB 光驱等，接口类型包括 USB 2.0（480 Mbps）、USB 3.2（20 Gbps+）。
    - Thunderbolt（雷电接口）：苹果设备及高端 PC，速度高达 40 Gbps（Thunderbolt 3/4），支持外接显卡坞、高速存储阵列。
    - eSATA：用于外部硬盘，传输速度与 SATA 相同（6 Gbps），抗干扰性更强。


### 按硬件接口与驱动模型分类

Linux 通过 **设备驱动模型** 管理存储设备，核心分类如下：

#### 块设备（Block Devices）

- **特性**：以固定大小的 “块”（Block，通常为 512B 或 4KB）为单位读写数据，支持随机访问，适用于存储文件系统。

- **驱动模型**：通过 **块设备子系统（Block Subsystem）** 管理，驱动需实现块设备注册、请求处理等接口。

- 常见类型
  - 磁盘类
    - **SCSI/ATA/SSD**：包括传统机械硬盘（HDD）、固态硬盘（SSD），通过 SCSI、SATA、NVMe 等接口连接，驱动对应 `scsi` 子系统（如 `sd` 驱动）或 `nvme` 驱动。
    - **USB 存储设备**：U 盘、移动硬盘等，基于 USB-SCSI 协议，由 `usb-storage` 驱动支持。

  - 内存映射类
    - **RAM 盘（RAM Disk）**：基于内存的虚拟块设备，由 `ramfs`/`tmpfs` 驱动管理。
    - **Loop 设备**：将文件模拟为块设备（如 ISO 镜像），由 `loop` 驱动支持。

  - 网络类
    - **iSCSI 设备**：通过网络访问的块存储（如 NAS），由 `iscsi` 驱动支持。
    - **NBD（Network Block Device）**：网络块设备，驱动为 `nbd`。

- **设备文件**：通常位于 `/dev/` 下，如 `/dev/sda`（SCSI 磁盘）、`/dev/nvme0n1`（NVMe 磁盘）、`/dev/loop0`（Loop 设备）。



#### 字符设备（Character Devices）

- **特性**：以字节流形式顺序读写数据，不支持随机访问，常用于原始设备访问或特殊功能设备。
- **驱动模型**：通过 **字符设备子系统（Character Subsystem）** 管理，驱动需实现 `read`/`write`/`ioctl` 等接口。
- 常见类型
  - **原始存储访问**：如闪存设备的原始分区（MTD 设备，见下文），通过字符接口直接操作硬件。
  - **特殊功能设备**：如 `/dev/sg`（SCSI 通用接口设备），用于直接发送 SCSI 命令。
- **设备文件**：如 `/dev/mtd0`（MTD 设备）、`/dev/sg0`（SCSI 通用设备）。



#### 内存技术设备（MTD，Memory Technology Device）

- **特性**：专为 **闪存（Flash）** 设计的抽象层，屏蔽 NOR/NAND 闪存的硬件差异，提供统一的读写、擦除接口。
- **驱动模型**：通过 **MTD 子系统** 管理，驱动需实现 `mtd_info` 结构体（定义擦除块大小、读写函数等）。
- **应用场景**：嵌入式系统中常见（如路由器、机顶盒），用于管理 NOR Flash（支持随机访问）和 NAND Flash（需磨损均衡）。
- 相关工具
  - `mtdinfo`：查看 MTD 设备信息。
  - `flash_eraseall`：擦除 MTD 设备。
  - `nandwrite`/`flashcp`：写入数据到 NAND/NOR 闪存。



### 按存储介质特性分类

Linux 驱动会针对不同存储介质的物理特性优化，主要分为两类：

#### 易失性存储（Volatile Storage）

- **特性**：依赖电源维持数据，断电后数据丢失。
- 驱动支持
  - **RAM**：通过内存管理子系统（MMU）直接管理，无需独立驱动（除特殊硬件如 DMA 映射）。
  - **SWAP 空间**：基于块设备的虚拟内存，由 `swapon` 命令和块驱动支持。

#### 非易失性存储（Non-Volatile Storage）

- **特性**：断电后数据保留，是 Linux 存储管理的核心。
- 细分类型
  - 磁盘类（Rotating Disks）
    - HDD（机械硬盘）：通过 `scsi`/`ata` 驱动支持，依赖机械寻道，驱动需处理 I/O 调度（如 CFQ、Deadline 算法）。
  - 固态存储（Solid-State Storage）
    - **NOR Flash**：支持随机读写，常用于存储固件（如 BIOS），驱动直接通过 MTD 或字符接口访问。
    - **NAND Flash**：需处理坏块管理、磨损均衡，通过 MTD 子系统的 `nand` 驱动支持（如 `nand_base` 框架）。
    - **SSD（基于 NAND）**：通过 NVMe/SATA 接口，驱动为 `nvme`/`ahci`，内部由控制器处理坏块和磨损均衡。
  - **光存储 / 磁带**：如 CD/DVD、磁带机，通过 SCSI 驱动（`sr` 设备）支持，属于块设备。



### 按驱动层次与子系统分类

Linux 存储驱动的层次结构如下，不同层次对应不同的设备分类：

#### 高层接口（用户空间）

- **文件系统**：如 ext4、XFS、Btrfs（基于块设备），JFFS2/UBIFS（基于 MTD 设备）。
- **工具链**：`mkfs`（格式化块设备）、`mount`（挂载文件系统）、`dd`（原始数据操作）。

#### 内核子系统

- **块设备子系统**：管理块设备的 I/O 调度、缓存（如 Page Cache），驱动需注册到 `block_device_operations`。
- **MTD 子系统**：为闪存设备提供抽象层，驱动需实现 `mtd_device` 结构体。
- **SCSI 子系统**：处理 SCSI 协议相关设备（如磁盘、磁带机），驱动分为 **主机控制器驱动**（如 `ahci`）和 **设备驱动**（如 `sd`）。

#### 硬件驱动层

- **主机控制器驱动**：如 NVMe 控制器驱动（`drivers/nvme/host/`）、USB 存储控制器驱动（`drivers/usb/storage/`）。
- **设备特定驱动**：如 NAND 闪存驱动（`drivers/mtd/nand/`）、NOR 闪存驱动（`drivers/mtd/nor/`）。



### 典型设备驱动示例总结

| **设备类型**      | **驱动子系统 / 模块**  | **内核路径**                     | **设备文件示例**          |
| ----------------- | ---------------------- | -------------------------------- | ------------------------- |
| NVMe SSD          | `nvme`                 | `drivers/nvme/host/`             | `/dev/nvme0n1`            |
| SATA 硬盘         | `ahci`（控制器）+ `sd` | `drivers/ata/` + `drivers/scsi/` | `/dev/sda`                |
| NAND Flash（MTD） | `nand` + MTD           | `drivers/mtd/nand/`              | `/dev/mtd0`               |
| USB 移动硬盘      | `usb-storage`          | `drivers/usb/storage/`           | `/dev/sdb`                |
| RAM 盘            | `ramfs`/`tmpfs`        | `fs/ramfs/`                      | 由挂载点标识（如 `/tmp`） |



在 Linux 和驱动层面，存储设备的分类紧密围绕 **硬件接口**、**存储介质特性** 和 **内核子系统架构**：

- **块设备** 是文件系统的基础，通过块子系统和 SCSI/ATA/NVMe 等驱动管理。
- **MTD 设备** 专为闪存设计，通过 MTD 子系统屏蔽硬件差异，常见于嵌入式场景。
- **驱动层次** 从硬件控制器到高层文件系统，形成了清晰的抽象结构，便于扩展和维护。



## Diagnosis

### 常用诊断与操作工具

| 工具名称         | 功能描述                                                     |
| ---------------- | ------------------------------------------------------------ |
| `mtdinfo`        | 获取 MTD 设备的详细信息（如擦除块大小、分区类型、硬件特性等）。 |
| `flash_eraseall` | 完全擦除 MTD 设备，支持格式化为 JFFS2（通过 `-j` 参数）。    |
| `flashcp`        | 向 **NOR 闪存** 写入数据（适用于按字节寻址的闪存）。         |
| `nandwrite`      | 向 **NAND 闪存** 写入数据（适用于按块寻址的闪存，需注意块对齐）。 |
| `mkfs.jffs2`     | 创建 JFFS2 文件系统镜像（非直接格式化设备，需配合擦除和烧录操作）。 |
| `mkfs.ubifs`     | 创建 UBIFS 文件系统镜像（基于 UBI 卷，适用于 NAND 闪存）。   |
| `ubiutils`       | 管理 UBI（Unsorted Block Images）卷，用于 NAND 闪存的逻辑块管理。 |



#### 关键操作流程

##### (1) 验证设备信息

```bash
mtdinfo /dev/mtdX  # 查看 MTD 设备 X 的擦除块大小、分区属性等
```



##### (2) 擦除与格式化

- 快速擦除并格式化为 JFFS2

  ```bash
  sudo flash_eraseall -j /dev/mtdX  # X 为目标设备号
  ```

- 纯擦除（用于后续烧录镜像）

  ```bash
  sudo flash_eraseall /dev/mtdX
  ```



##### (3) 写入数据或镜像

- 直接写入文件（NOR 闪存）

  ```bash
  sudo flashcp source_file /dev/mtdblockX  # mtdblockX 为块设备接口
  ```

  

- 烧录 JFFS2 镜像（NAND 闪存）

  ```bash
  sudo nandwrite -p /dev/mtdX image.jffs2  # -p 表示按页写入，需与闪存块大小匹配
  ```

  

##### (4) 创建文件系统镜像

```bash
# 示例：生成 JFFS2 镜像（擦除块 256KB，内容来自 rootfs 目录）
sudo mkfs.jffs2 --eraseblock=256 --pad -d rootfs/ -o rootfs.jffs2
```

- `--pad`：确保镜像大小为擦除块的整数倍，避免写入时因边界不对齐导致错误。
- `--no-cleanmarkers`：仅用于 NAND 闪存，禁止生成清洁标记（NOR 闪存无需此参数）。



### Preparation

#### dd

```sh
# dd --help
Usage: dd [OPERAND]...
  or:  dd OPTION
Copy a file, converting and formatting according to the operands.

  bs=BYTES        read and write up to BYTES bytes at a time (default: 512);
                  overrides ibs and obs
  cbs=BYTES       convert BYTES bytes at a time
  conv=CONVS      convert the file as per the comma separated symbol list
  count=N         copy only N input blocks
  ibs=BYTES       read up to BYTES bytes at a time (default: 512)
  if=FILE         read from FILE instead of stdin
  iflag=FLAGS     read as per the comma separated symbol list
  obs=BYTES       write BYTES bytes at a time (default: 512)
  of=FILE         write to FILE instead of stdout
  oflag=FLAGS     write as per the comma separated symbol list
  seek=N          skip N obs-sized blocks at start of output
  skip=N          skip N ibs-sized blocks at start of input
  status=LEVEL    The LEVEL of information to print to stderr;
                  'none' suppresses everything but error messages,
                  'noxfer' suppresses the final transfer statistics,
                  'progress' shows periodic transfer statistics

N and BYTES may be followed by the following multiplicative suffixes:
c =1, w =2, b =512, kB =1000, K =1024, MB =1000*1000, M =1024*1024, xM =M,
GB =1000*1000*1000, G =1024*1024*1024, and so on for T, P, E, Z, Y.

Each CONV symbol may be:

  ascii     from EBCDIC to ASCII
  ebcdic    from ASCII to EBCDIC
  ibm       from ASCII to alternate EBCDIC
  block     pad newline-terminated records with spaces to cbs-size
  unblock   replace trailing spaces in cbs-size records with newline
  lcase     change upper case to lower case
  ucase     change lower case to upper case
  sparse    try to seek rather than write the output for NUL input blocks
  swab      swap every pair of input bytes
  sync      pad every input block with NULs to ibs-size; when used
            with block or unblock, pad with spaces rather than NULs
  excl      fail if the output file already exists
  nocreat   do not create the output file
  notrunc   do not truncate the output file
  noerror   continue after read errors
  fdatasync  physically write output file data before finishing
  fsync     likewise, but also write metadata

Each FLAG symbol may be:

  append    append mode (makes sense only for output; conv=notrunc suggested)
  direct    use direct I/O for data
  directory  fail unless a directory
  dsync     use synchronized I/O for data
  sync      likewise, but also for metadata
  fullblock  accumulate full blocks of input (iflag only)
  nonblock  use non-blocking I/O
  noatime   do not update access time
  nocache   Request to drop cache.  See also oflag=sync
  noctty    do not assign controlling terminal from file
  nofollow  do not follow symlinks
  count_bytes  treat 'count=N' as a byte count (iflag only)
  skip_bytes  treat 'skip=N' as a byte count (iflag only)
  seek_bytes  treat 'seek=N' as a byte count (oflag only)

Sending a USR1 signal to a running 'dd' process makes it
print I/O statistics to standard error and then resume copying.

Options are:

      --help     display this help and exit
      --version  output version information and exit

GNU coreutils online help: <https://www.gnu.org/software/coreutils/>
Full documentation at: <https://www.gnu.org/software/coreutils/dd>
or available locally via: info '(coreutils) dd invocation
```


#### lsblk

列出块设备

```sh
~# lsblk 
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0 59.6G  0 disk 
├─sda1   8:1    0  256M  0 part /boot/efi
├─sda2   8:2    0  128M  0 part 
├─sda3   8:3    0   64M  0 part /mnt/onl/boot
├─sda4   8:4    0    8M  0 part /mnt/onl/config
├─sda5   8:5    0  256M  0 part /mnt/onl/images
├─sda6   8:6    0    1G  0 part /
└─sda7   8:7    0    8M  0 part 
~# lsblk -S
NAME HCTL       TYPE VENDOR   MODEL           REV TRAN
sda  0:0:0:0    disk ATA      M.2__S80__3IE7 30i  sata
~# 
```


**说明**

| TYPE （lsblk -S） | 说明             | 示例设备        |
| ----------------- | ---------------- | --------------- |
| `disk`            | 物理磁盘         | HDD、SSD、U 盘  |
| `part`            | 磁盘分区         | `/dev/sda1`     |
| `lvm`             | LVM 逻辑卷       | `/dev/vg0/root` |
| `raid`            | 软件 RAID 设备   | `/dev/md0`      |
| `crypt`           | 加密设备         | LUKS 分区       |
| `loop`            | 回环设备         | ISO 镜像挂载    |
| `rom`             | 只读设备         | CD/DVD-ROM      |
| `zfs_member`      | ZFS 文件系统组件 | ZFS 池中的 vdev |
| `mpath`           | 多路径设备       | 企业存储阵列    |


| 设备类型 | 设备命名特征      | `TRAN` 值 | `ROTA` 值 | 典型场景     |
| -------- | ----------------- | --------- | --------- | ------------ |
| U 盘     | `sd[a-z]`         | `usb`     | `0`       | 便携存储     |
| NVMe SSD | `nvme[0-9]n[0-9]` | `nvme`    | `0`       | 高性能系统盘 |
| SATA HDD | `sd[a-z]`         | `sata`    | `1`       | 大容量存储   |
| SATA SSD | `sd[a-z]`         | `sata`    | `0`       | 主流桌面存储 |
| SAS HDD  | `sd[a-z]`         | `sas`     | `1`       | 企业服务器   |
| SD 卡    | `sd[a-z]`         | `sd`      | `0`       | 相机存储     |



#### fio

压力/性能测试工具

```sh
~# fio -filename=./SSD_SPACE -direct=0 -iodepth 64 -thread -rw=readwrite -ioengine=posixaio -bs=4k -size=16g -numjobs=2  -group_reporting -name=rr_16k   >> $SSD_TEST_LOG
rr_16k: (g=0): rw=rw, bs=4K-4K/4K-4K/4K-4K, ioengine=posixaio, iodepth=64
...
fio-2.15
Starting 2 threads
rr_16k: Laying out IO file(s) (1 file(s) / 16384MB)

rr_16k: (groupid=0, jobs=2): err= 0: pid=26297: Mon Jan  1 02:44:52 2001
  read : io=16378MB, bw=611220KB/s, iops=152804, runt= 27438msec
    slat (usec): min=0, max=22, avg= 0.03, stdev= 0.18
    clat (usec): min=18, max=307017, avg=389.79, stdev=3564.88
     lat (usec): min=19, max=307017, avg=389.82, stdev=3564.88
    clat percentiles (usec):
     |  1.00th=[   83],  5.00th=[  116], 10.00th=[  131], 20.00th=[  151],
     | 30.00th=[  165], 40.00th=[  179], 50.00th=[  193], 60.00th=[  209],
     | 70.00th=[  231], 80.00th=[  270], 90.00th=[  406], 95.00th=[  644],
     | 99.00th=[  932], 99.50th=[ 1064], 99.90th=[51456], 99.95th=[79360],
     | 99.99th=[144384]
  write: io=16390MB, bw=611699KB/s, iops=152924, runt= 27438msec
    slat (usec): min=0, max=22, avg= 0.14, stdev= 0.36
    clat (usec): min=18, max=306978, avg=395.85, stdev=3657.32
     lat (usec): min=18, max=306979, avg=395.98, stdev=3657.32
    clat percentiles (usec):
     |  1.00th=[   83],  5.00th=[  117], 10.00th=[  133], 20.00th=[  153],
     | 30.00th=[  167], 40.00th=[  179], 50.00th=[  193], 60.00th=[  209],
     | 70.00th=[  233], 80.00th=[  274], 90.00th=[  414], 95.00th=[  652],
     | 99.00th=[  932], 99.50th=[ 1080], 99.90th=[53504], 99.95th=[79360],
     | 99.99th=[148480]
    lat (usec) : 20=0.01%, 50=0.01%, 100=2.38%, 250=72.79%, 500=17.33%
    lat (usec) : 750=3.94%, 1000=2.91%
    lat (msec) : 2=0.29%, 4=0.02%, 10=0.06%, 20=0.01%, 50=0.14%
    lat (msec) : 100=0.08%, 250=0.02%, 500=0.01%
  cpu          : usr=37.21%, sys=14.55%, ctx=1490754, majf=0, minf=11
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=2.3%, 32=92.0%, >=64=5.5%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=95.1%, 8=0.5%, 16=1.6%, 32=2.5%, 64=0.3%, >=64=0.0%
     issued    : total=r=4192661/w=4195947/d=0, short=r=0/w=0/d=0, drop=r=0/w=0/d=0
     latency   : target=0, window=0, percentile=100.00%, depth=64

Run status group 0 (all jobs):
   READ: io=16378MB, aggrb=611219KB/s, minb=611219KB/s, maxb=611219KB/s, mint=27438msec, maxt=27438msec
  WRITE: io=16390MB, aggrb=611698KB/s, minb=611698KB/s, maxb=611698KB/s, mint=27438msec, maxt=27438msec

Disk stats (read/write):
  sda: ios=10356/5006, merge=185/944, ticks=16110/711120, in_queue=718969, util=45.61%
```


#### smartctl

监测和分析硬盘的状态

```sh
~# smartctl -h
smartctl 6.6 2017-11-05 r4594 [x86_64-linux-5.4.40-OpenNetworkLinux] (local build)
Copyright (C) 2002-17, Bruce Allen, Christian Franke, www.smartmontools.org

Usage: smartctl [options] device

============================================ SHOW INFORMATION OPTIONS =====

  -h, --help, --usage
         Display this help and exit

  -V, --version, --copyright, --license
         Print license, copyright, and version information and exit

  -i, --info
         Show identity information for device

  --identify[=[w][nvb]]
         Show words and bits from IDENTIFY DEVICE data                (ATA)

  -g NAME, --get=NAME
        Get device setting: all, aam, apm, dsn, lookahead, security,
        wcache, rcache, wcreorder, wcache-sct

  -a, --all
         Show all SMART information for device

  -x, --xall
         Show all information for device

  --scan
         Scan for devices

  --scan-open
         Scan for devices and try to open each device

================================== SMARTCTL RUN-TIME BEHAVIOR OPTIONS =====

  -q TYPE, --quietmode=TYPE                                           (ATA)
         Set smartctl quiet mode to one of: errorsonly, silent, noserial

  -d TYPE, --device=TYPE
         Specify device type to one of:
         ata, scsi, nvme[,NSID], sat[,auto][,N][+TYPE], usbcypress[,X], usbjmicron[,p][,x][,N], usbprolific, usbsunplus, intelliprop,N[+TYPE], marvell, areca,N/E, 3ware,N, hpt,L/M/N, megaraid,N, aacraid,H,L,ID, cciss,N, auto, test

  -T TYPE, --tolerance=TYPE                                           (ATA)
         Tolerance: normal, conservative, permissive, verypermissive

  -b TYPE, --badsum=TYPE                                              (ATA)
         Set action on bad checksum to one of: warn, exit, ignore

  -r TYPE, --report=TYPE
         Report transactions (see man page)

  -n MODE[,STATUS], --nocheck=MODE[,STATUS]                           (ATA)
         No check if: never, sleep, standby, idle (see man page)

============================== DEVICE FEATURE ENABLE/DISABLE COMMANDS =====

  -s VALUE, --smart=VALUE
        Enable/disable SMART on device (on/off)

  -o VALUE, --offlineauto=VALUE                                       (ATA)
        Enable/disable automatic offline testing on device (on/off)

  -S VALUE, --saveauto=VALUE                                          (ATA)
        Enable/disable Attribute autosave on device (on/off)

  -s NAME[,VALUE], --set=NAME[,VALUE]
        Enable/disable/change device setting: aam,[N|off], apm,[N|off],
        dsn,[on|off], lookahead,[on|off], security-freeze,
        standby,[N|off|now], wcache,[on|off], rcache,[on|off],
        wcreorder,[on|off[,p]], wcache-sct,[ata|on|off[,p]]

======================================= READ AND DISPLAY DATA OPTIONS =====

  -H, --health
        Show device SMART health status

  -c, --capabilities                                            (ATA, NVMe)
        Show device SMART capabilities

  -A, --attributes
        Show device SMART vendor-specific Attributes and values

  -f FORMAT, --format=FORMAT                                          (ATA)
        Set output format for attributes: old, brief, hex[,id|val]

  -l TYPE, --log=TYPE
        Show device log. TYPE: error, selftest, selective, directory[,g|s],
        xerror[,N][,error], xselftest[,N][,selftest], background,
        sasphy[,reset], sataphy[,reset], scttemp[sts,hist],
        scttempint,N[,p], scterc[,N,M], devstat[,N], defects[,N], ssd,
        gplog,N[,RANGE], smartlog,N[,RANGE], nvmelog,N,SIZE

  -v N,OPTION , --vendorattribute=N,OPTION                            (ATA)
        Set display OPTION for vendor Attribute N (see man page)

  -F TYPE, --firmwarebug=TYPE                                         (ATA)
        Use firmware bug workaround:
        none, nologdir, samsung, samsung2, samsung3, xerrorlba, swapid

  -P TYPE, --presets=TYPE                                             (ATA)
        Drive-specific presets: use, ignore, show, showall

  -B [+]FILE, --drivedb=[+]FILE                                       (ATA)
        Read and replace [add] drive database from FILE
        [default is +/etc/smart_drivedb.h
         and then    /var/lib/smartmontools/drivedb/drivedb.h]

============================================ DEVICE SELF-TEST OPTIONS =====

  -t TEST, --test=TEST
        Run test. TEST: offline, short, long, conveyance, force, vendor,N,
                        select,M-N, pending,N, afterselect,[on|off]

  -C, --captive
        Do test in captive mode (along with -t)

  -X, --abort
        Abort any non-captive test on device

=================================================== SMARTCTL EXAMPLES =====

  smartctl --all /dev/sda                    (Prints all SMART information)

  smartctl --smart=on --offlineauto=on --saveauto=on /dev/sda
                                              (Enables SMART on first disk)

  smartctl --test=long /dev/sda          (Executes extended disk self-test)

  smartctl --attributes --log=selftest --quietmode=errorsonly /dev/sda
                                      (Prints Self-Test & Attribute errors)
  smartctl --all --device=3ware,2 /dev/sda
  smartctl --all --device=3ware,2 /dev/twe0
  smartctl --all --device=3ware,2 /dev/twa0
  smartctl --all --device=3ware,2 /dev/twl0
          (Prints all SMART info for 3rd ATA disk on 3ware RAID controller)
  smartctl --all --device=hpt,1/1/3 /dev/sda
          (Prints all SMART info for the SATA disk attached to the 3rd PMPort
           of the 1st channel on the 1st HighPoint RAID controller)
  smartctl --all --device=areca,3/1 /dev/sg2
          (Prints all SMART info for 3rd ATA disk of the 1st enclosure
           on Areca RAID controller)

~# smartctl --all /dev/sda
smartctl 6.6 2017-11-05 r4594 [x86_64-linux-5.4.40-OpenNetworkLinux] (local build)
Copyright (C) 2002-17, Bruce Allen, Christian Franke, www.smartmontools.org

=== START OF INFORMATION SECTION ===
Device Model:     M.2 (S80) 3IE7
Serial Number:    YCA12312130330144
LU WWN Device Id: 5 24693e 001810759
Firmware Version: S23330i
User Capacity:    64,023,257,088 bytes [64.0 GB]
Sector Size:      512 bytes logical/physical
Rotation Rate:    Solid State Device
Form Factor:      2.5 inches
Device is:        Not in smartctl database [for details use: -P showall]
ATA Version is:   ACS-2 (minor revision not indicated)
SATA Version is:  SATA 3.2, 6.0 Gb/s (current: 6.0 Gb/s)
Local Time is:    Sun Feb  4 22:32:14 2001 UTC
SMART support is: Available - device has SMART capability.
SMART support is: Enabled

=== START OF READ SMART DATA SECTION ===
SMART overall-health self-assessment test result: PASSED

General SMART Values:
Offline data collection status:  (0x02) Offline data collection activity
                                        was completed without error.
                                        Auto Offline Data Collection: Disabled.
Self-test execution status:      (   0) The previous self-test routine completed
                                        without error or no self-test has ever 
                                        been run.
Total time to complete Offline 
data collection:                (   33) seconds.
Offline data collection
capabilities:                    (0x7b) SMART execute Offline immediate.
                                        Auto Offline data collection on/off support.
                                        Suspend Offline collection upon new
                                        command.
                                        Offline surface scan supported.
                                        Self-test supported.
                                        Conveyance Self-test supported.
                                        Selective Self-test supported.
SMART capabilities:            (0x0003) Saves SMART data before entering
                                        power-saving mode.
                                        Supports SMART auto save timer.
Error logging capability:        (0x01) Error logging supported.
                                        General Purpose Logging supported.
Short self-test routine 
recommended polling time:        (   2) minutes.
Extended self-test routine
recommended polling time:        (   2) minutes.
Conveyance self-test routine
recommended polling time:        (   2) minutes.
SCT capabilities:              (0x0039) SCT Status supported.
                                        SCT Error Recovery Control supported.
                                        SCT Feature Control supported.
                                        SCT Data Table supported.

SMART Attributes Data Structure revision number: 16
Vendor Specific SMART Attributes with Thresholds:
ID# ATTRIBUTE_NAME          FLAG     VALUE WORST THRESH TYPE      UPDATED  WHEN_FAILED RAW_VALUE
  5 Reallocated_Sector_Ct   0x0012   100   100   000    Old_age   Always       -       0
  9 Power_On_Hours          0x0012   108   100   000    Old_age   Always       -       7020
 12 Power_Cycle_Count       0x0012   246   000   000    Old_age   Always       -       246
163 Unknown_Attribute       0x0012   007   000   000    Old_age   Always       -       7
165 Unknown_Attribute       0x0012   153   000   000    Old_age   Always       -       153
167 Unknown_Attribute       0x0012   038   000   000    Old_age   Always       -       38
169 Unknown_Attribute       0x0000   100   000   000    Old_age   Offline      -       100
170 Unknown_Attribute       0x0013   100   100   001    Pre-fail  Always       -       1266
171 Unknown_Attribute       0x0012   000   100   000    Old_age   Always       -       0
172 Unknown_Attribute       0x0012   000   100   000    Old_age   Always       -       0
192 Power-Off_Retract_Count 0x0012   246   000   000    Old_age   Always       -       246
194 Temperature_Celsius     0x0002   032   100   000    Old_age   Always       -       32 (3 49 0 130 0)
229 Unknown_Attribute       0x0000   100   100   000    Old_age   Offline      -       251195517583000
235 Unknown_Attribute       0x0002   000   000   000    Old_age   Always       -       0
241 Total_LBAs_Written      0x0012   100   100   000    Old_age   Always       -       93778
242 Total_LBAs_Read         0x0012   100   100   000    Old_age   Always       -       11592

SMART Error Log Version: 1
No Errors Logged

SMART Self-test log structure revision number 1
Num  Test_Description    Status                  Remaining  LifeTime(hours)  LBA_of_first_error
# 1  Short offline       Completed without error       00%      7020         -
# 2  Short offline       Completed without error       00%      7020         -

SMART Selective self-test log data structure revision number 1
 SPAN  MIN_LBA  MAX_LBA  CURRENT_TEST_STATUS
    1        0        0  Not_testing
    2        0        0  Not_testing
    3        0        0  Not_testing
    4        0        0  Not_testing
    5        0        0  Not_testing
Selective self-test flags (0x0):
  After scanning selected spans, do NOT read-scan remainder of disk.
If Selective self-test is pending on power-up, resume after 0 minute delay.

```


#### badblocks

检查磁盘装置中损坏的区块

```sh
~# badblocks -h
badblocks: option requires an argument -- 'h'
Usage: badblocks [-b block_size] [-i input_file] [-o output_file] [-svwnfBX]
       [-c blocks_at_once] [-d delay_factor_between_reads] [-e max_bad_blocks]
       [-p num_passes] [-t test_pattern [-t test_pattern [...]]]
       device [last_block [first_block]]
~# badblocks -s /dev/sda
Checking for bad blocks (read-only test):  44.80% done, 1:19 elapsed. (0/0/0 errors)
~# badblocks -sv /dev/sda1
Checking blocks 0 to 262143
Checking for bad blocks (read-only test): done                                                 
Pass completed, 0 bad blocks found. (0/0/0 errors)
~# badblocks -sv /dev/sda
Checking blocks 0 to 62522711
Checking for bad blocks (read-only test): done                                                 
Pass completed, 0 bad blocks found. (0/0/0 errors)
```


#### fsck.vfat (U盘，FAT32)

对VFAT 文件系统进行错误检测、修复和优化的工具

```sh
~# fsck.vfat
usage: fsck.vfat [-aAbflrtvVwy] [-d path -d ...] [-u path -u ...]
               device
  -a       automatically repair the filesystem
  -A       toggle Atari filesystem format
  -b       make read-only boot sector check
  -c N     use DOS codepage N to decode short file names (default: 437)
  -d path  drop that file
  -f       salvage unused chains to files
  -l       list path names
  -n       no-op, check non-interactively without changing
  -p       same as -a, for compat with other *fsck
  -r       interactively repair the filesystem (default)
  -t       test for bad clusters
  -u path  try to undelete that (non-directory) file
  -v       verbose mode
  -V       perform a verification pass
  -w       write changes to disk immediately
  -y       same as -a, for compat with other *fsck
```


### 测试

- 检查信息
  - 磁盘类型 （`lsblk -S`）
- 读写测试
  - 用 `dd` 命令进行读写，然后用 `diff` 比对是否一致。数据源用 `/dev/urandom`。
    - 预：`mkdir /mnt/tmp`; `mount /dev/sda6 /mnt/tmp`; `dd if=/dev/urandom of=/tmp/testdata bs=100M count=1`
    - 写：`dd if=/tmp/testdata of=/mnt/tmp/data bs=1000M count=1`; `diff /tmp/testdata /mnt/tmp/data`
    - 读：`dd if=/tmp/tmp/data of=/tmp/testdatacmp bs=1000M count=1`; `diff /mnt/tmp/data /tmp/testdatacmp`
- 性能测试
  - 测试顺序写入（4KB块，队列深度1，持续时间30秒，带缓存direct=0）：
    ```
    fio -filename=./SSD_SPACE -direct=0 -iodepth 64 -thread -rw=readwrite -ioengine=posixaio -bs=4k -size=16g -numjobs=2  -group_reporting -name=rr_16k   >> $SSD_TEST_LOG
    ```
    - **问题**：`dd` 和 `fio` 的测试结果可能包含系统缓存（Page Cache）的影响，导致结果虚高。
      - 解决方案
        - 测试前清空缓存：
          ```bash
          sync && echo 3 > /proc/sys/vm/drop_caches  # 清空页缓存、目录项和inode
          ```
        - 在 `fio` 中添加 `direct=1` 参数（绕过缓存，直接写入磁盘）。
    - 也可以随机读写：rw=randwrite随机写入测试，randread 为随机读取。
- 磁盘坏道检测
  - 非破坏性检测
    - `smartctl --all /dev/sda`: Completed without error
    - `badblocks -sv /dev/sda`: Pass completed, 0 bad blocks found. (0/0/0 errors)
  - 破坏性检测
    ```sh
    # 1. 刚格式化并且mkfs.ext4/3, 非破坏性检测
    dumpe2fs -b /dev/sda1
    # 2
    umount /dev/sda1         # 卸载分区
    badblocks -w /dev/sda1    # 写入测试，标记坏块（危险！可能损坏数据）
    e2fsck -l badblocks.log /dev/sda1  # 将坏块列表写入文件系统元数据
    ```


