# Secure Boot

## Boot Sequence

```
UEFI --> shimx64.efi -- > grubx64.efi -- > Linux kernel
```

具体来说，Linux 内核的启动顺序会经历以下阶段：
- 开机
- 底层 “PRE UEFI” 代码将 UEFI 固件的度量值（哈希扩展）存入可信平台模块（TPM）的平台配置寄存器（PCR）中
- UEFI 固件验证 shimx64.efi 的签名并执行它
  - 对 shimx64.efi 进行签名的实体的公证书必须存放在 UEFI 的授权数据库（db）中。
  - 标准做法是将微软的公证书存放在 UEFI 数据库中，并且由微软对 shimx64.efi 进行签名
  - 将 shimx64.efi 的度量值存入 TPM 的 PCR 中
- shimx64.efi 找到 grubx64.efi，验证其签名并执行它
  - 通常情况下，shim 使用嵌入的公证书来验证 grubx64.efi
  - 将机器所有者密钥（MOK）环境变量的度量值存入 TPM 的 PCR 中
  - 将 grubx64.efi 的度量值存入 TPM 的 PCR 中
  - shim 还会查询 UEFI 数据库和 MOK 数据库
  - 如果其他方法都失败了，shim 会尝试加载 MokManager.efi
- grubx64.efi 找到一个 Linux 内核，验证其签名并执行它
  - 使用 shim 提供的验证接口，即回调到 shim，使用 shim 所采用的所有方法来验证 Linux 内核的签名
  - 将 Linux 内核的度量值存入 TPM 的 PCR 中
- Linux 内核启动
  - 可以选择继续信任链，并验证内核可加载模块和用户空间应用程序的签名 


### UEFI

UEFI 只管验efi文件，shim是efi文件，grub也是efi文件，grub验kernel，kenel验module。

BIOS Secure Boot的原理：把公钥包在`code`里面，当使用`gBS->LoadImage()`去加载模块（`UEFI Image`）的时候会用BIOS里面的公钥去验证Image有没有正确签名，验证通过则Image成功被加载。签名实例：`signtoolx64.exe sign -f 私钥.pfx -fd sha256 shell.efi`

例如：当我们在BIOS里面把Secure Boot[Enable]之后，会发现我们的U盘shell进不去，这是因为shell环境(bootx64.efi)没有经过签名，如果要使Secure Boot[Enable]之后，也能进U盘shell，需要对bootx64.efi进行签名，同时**把签名用的私钥的对应公钥包到BIOS里面**。

把公钥添加到BIOS里面，有两种方法：
- 通过`BIOS菜单`，通过`Key Management`、`Import(Public Key)`把公钥(一般是`.cer`文件)添加进去。
- 通过`UEFI Shell`，使用命令（如`certtool -add -file mykey.cer -db db`），把公钥(一般是`.cer`文件)添加进去。
- 通过`Linux系统`，使用`mokutil`命令（如`sudo mokutil --import MOK.der`），把公钥(一般是`.der`(PEM)文件)添加进去。


### shimx64.efi

shimx64.efi是一个非常精简的可扩展固件接口（EFI）应用程序，具有以下特性：
- 代码基数小，易于验证其正确性。
- 通常由微软公司进行签名。
- 包含了shim所有者嵌入的公共证书。

`Shim`的代码规模小，使得签名实体能够快速进行安全审计。在实际应用中，签名实体是微软。较小的代码规模有助于加快签名过程。

嵌入的公共证书在延续信任链方面发挥着重要作用。由于`shimx64.efi`是由可扩展固件接口（UEFI）的授权密钥数据库中的密钥进行签名的，因此UEFI固件能够对shimx64.efi进行身份验证并加载它。 

为了对下一阶段的加载程序进行身份验证，Shim 会尝试执行以下操作：
- 采用与 UEFI 自身相同的流程，即使用签名数据库 db 和 dbx 来验证镜像。
- 使用由 MokManager 管理的机器所有者密钥（MOK）数据库，下一部分将对此进行讨论。
- 使用 Shim 所有者嵌入的公证书。

如果 Shim 无法验证下一阶段的加载程序，它会默认启动 MokManager.efi，让机器所有者能够注册自己的公证书以进行验证。

**Shim 的关键之处在于**，微软只需对 Shim 二进制文件进行签名。微软无需对下一阶段的加载程序（grubx64.efi）或 MokManager 进行签名。Shim 可以通过使用嵌入的公证书对下一阶段进行身份验证，从而延续信任链。

作为对其他 UEFI 应用程序的一项服务，Shim 还会向 UEFI 运行时注册一个验证接口。该接口提供了与 Shim 用于验证第二阶段加载程序相同的身份验证检查。实际上，grubx64.efi 在启动 Linux 内核镜像之前会使用这个接口来验证该镜像。 

在没有启用 安全启动（Secure Boot） 的计算机中，启动 shimx64.efi 和启动 grubx64.efi是一样的。

开源项目“shim”是在UEFI安全启动环境中引导Linux系统的一种常见且普遍被认可的方法。许多知名的Linux发行版都采用了shim项目，其中包括红帽（Redhat）、Debian、Ubuntu和SUSE。


#### Other

在现代基于UEFI固件的系统中，`shim`已经成为目前所有Linux发行版本中必备的一阶`bootloader`；而传统上我们熟悉的`grub2`变成了二阶`bootloader`。

从一阶bootloader过渡到二阶bootloader再到`内核`和`initramfs`，这一启动链的建立其实并不像想象中的那么简单。

`shim`项目由两个EFI二进制应用程序组成，即`shimx64.efi`和`MokManager.efi`(类似`mokutil`)，实际还包括`mmx64.efi`、`fbx64.efi`等。 

一个由UEFI固件引导的系统必须有一个EFI分区，即FAT文件系统。一个安装了shim的EFI分区的文件如下所示：
```
.
├── EFI
│   ├── myos
│   │   ├── BOOT.CSV
│   │   ├── BOOTX64.CSV
│   │   ├── fonts
│   │   │   └── unicode.pf2
│   │   ├── grub.cfg
│   │   ├── grubenv
│   │   ├── grubx64.efi
│   │   ├── mmx64.efi
│   │   ├── MokManager.efi
│   │   ├── shim.efi
│   │   ├── shimx64-myos.efi
│   │   └── shimx64.efi
│   └── boot
│          ├── bootx64.efi
│          ├── fallback.efi  # 即fbx64.efi
│          └── fbx64.efi
└── startup.nsh
```

##### shim first boot

系统完成装机并进行第一次启动的时候，UEFI boot manager会自动枚举出一个叫做UEFI OS的启动选项，该启动选项将bootloader程序的路径设置为/EFI/boot/bootx64.efi，即一阶bootloader shim。

shim的主要工作是启动二阶bootloader；shim会在当前目录下寻找grubx64.efi，即/EFI/boot/grubx64.efi。如果不存在，shim会加载当前目录下的fbx64.efi(或fallback.efi)，即/EFI/boot/fbx64.efi(或/EFI/boot/fallback.efi)；该程序的职责是枚举/EFI目录下的、除boot子目录以外的所有子目录（这个目录的实际内容在更通用的场景里是不定的，所以我们用<bootloader-id>来描述它；比如可能值是centos等发型版本的名字，或者像myos这种自定义的Linux发行版本），并找到第一个BOOTX64.CSV文件。下面是一个记录了自定义的myos的BOOTX64.CSV文件的示例：

```
shimx64.efi,My Linux,,This is the boot entry for my Linux
```

该文件记录了二阶bootloader的路径（该路径相对于当前的\目录）和title。title字段会被用来创建一个全新的启动选项，该启动选项中的程序路径也会被设定为二阶bootloader所在的绝对路径(/EFI/<二阶bootloader路径>)。从这里的内容可以看出，fallback的作用就是创建一个启动选项，该启动选项指向了/EFI/<bootloader-id>/shimx64.efi（比如/EFI/myos/shimx64.efi）。

fallback程序的最后一个工作就是修改BootOrder变量，将新创建的启动选项设为最优先启动，然后issue warm boot重启系统。

这种自动重启的机制，其实非常有利于可信系统在setup阶段后利用第一次启动向管控中心注册有效的基准值，原因在于shim first boot不会启动到OS。假设shim first boot没有执行自动重启，那么启动链就有可能变成：/EFI/boot/bootx64.efi -> /EFI/boot/fbx64.efi -> /EFI/BOOTX64.CSV -> 创建启动选项；修改BootOrder -> /EFI/grubx64.efi -> /EFI/grub.cfg -> /boot/vmlinuz-* 。这与下面介绍的shim normal boot的启动顺序非常不一致，进而影响基准值的录入。

但是这种自动重启机制可能也会带来如下问题：

系统启动或重启时间变长，比如管控层的健康检查机制会判定系统启动超时。
某些固件的引导选项策略会导致bootloader创建的启动选项无效，进而导致系统陷入无限重启的境地。解决方法见最下面。


##### shim normal boot

正常情况下，UEFI boot manager会根据新的BootOrder变量，从新的启动选项（比如上面的xxx Linux）启动一阶bootloader，即/EFI/<bootloader-id>/shimx64.efi。

然后，/EFI/<bootloader-id>/shimx64.efi在当前目录下找到grubx64.efi，即/EFI/<bootloader-id>/grubx64.efi，这样就来到了我们熟悉的grub2启动流程里了。


##### 总结

`shim first boot`：`默认启动选项UEFI OS -> /EFI/boot/bootx64.efi（本质就是/EFI/boot/shimx64.efi） -> /EFI/boot/fbx64.efi -> /EFI/myos/BOOTX64.CSV（记录了自定义启动选项的名称为My Linux） -> 自动创建启动选项，并修改BootOrder变量，然后自动执行warm reboot`。正常情况下，重启后会进入shim normal boot流程。
`shim normal boot`：`启动选项My Linux -> /EFI/myos/shimx64.efi -> /EFI/myos/grubx64.efi -> /EFI/myos/grub.cfg -> /boot/vmlinuz-*` 。正常情况下，不管系统再经过多少次重启，每次都会走该启动流程，不会再执行`shim first boot`。


**注意事项**

上述举例中用myos代替了<bootloader-id>；如果是其他Linux发行版本请对号入座。
UEFI固件对启动顺序有一个策略：
- Keep original priority
- Adjust device priority by bootloader
如果启用了前者，那么shim first boot在修改完BootOrder变量并重启后，自建的引导选项不会影响实际的启动顺序，会导致系统看起来在不停地warm reboot；如果启用了后者，就会按照预期在重启后走shim normal boot流程。



### grubx64.efi




### Linux Kernel



## ONIE

硬件平台供应商会将 ONIE 与硬件一同构建并分发。安全启动所需的额外软件也将由平台供应商提供。此表描述了硬件供应商有责任提供的新组件：

| Binary | Built By | Signed By | Contains| Notes| 
| --- | --- | --- | --- | -- |
| ONIE shimx64.efi | HW Vendor |Microsoft |HW Vendor public certificate |Measures, verifies and executes ONIE grubx64.efi|
| ONIE grubx64.efi | HW Vendor |HW Vendor |N/A | Measures, verifies and executes ONIE Linux kernel and initramfs|
| ONIE Linux kernel | HW Vendor |HW Vendor [Optional] |HW Vendor public certificate for verifying kernel loadable modules| |

可以合理地预期，对于硬件供应商的所有 x86_64 平台，能够交付使用单个 shimx64.efi 二进制文件。这使得每个硬件供应商只需对单个二进制文件执行微软代码签名流程，从而将该流程的工作量降至最低。 

开放网络安装环境（ONIE）的构建过程按以下方式使用硬件供应商的公钥/私钥对： 

1. The public certificate is embedded into the ONIE shimx64.efi binary
2. The private key and public certificate are used to sign the ONIE grubx64.efi binary
3. The private key and public certificate are used to sign the ONIE Linux kernel
4. [Optional] The private key and public certificate are used to sign ONIE kernel loadable modules



### ONIE Install

Sequence of events during ONIE installation:

- Formats the disk for GUID Partition Table (GPT)
- Creates the EFI System Partition (ESP)
- Creates an ONIE partition
- Installs ONIE shimx64.efi, MokManager.efi and grubx64.efi into the ESP
- Installs the ONIE kernel and initramfs into the ONIE partition
- Configures GRUB2 to load the ONIE kernel and initramfs
- Modifies the UEFI BootOrder and Boot#### global variables to boot into ONIE shim at the next boot.



### ONIE Secure Boot Configuration

Refer `machine-security.make`

#### 制作Keys
- 方法1：`build-config/make/signing-keys.make`
```
# 1. set SECURE_BOOT_ENABLE = yes in machine.make
# ...

# 2. modify key settings
encryption/onie-encrypt.lib:function:fxnGenerateAllKeys:

        fxnGenerateKeys "$HW_VENDOR_PREFIX"   "HW"   "hardware@onie.org" "Hardware vendor certificate." "" 
        fxnGenerateKeys "$SW_VENDOR_PREFIX"   "SW"   "software@onie.org" "Software vendor certificate." "" 
        fxnGenerateKeys "$ONIE_VENDOR_PREFIX" "ONIE" "onie@onie.org" "ONIE vendor certificate."         "" 

# 3. make
make MACHINEROOT=../machine/$vendor/ MACHINE=$machinename signing-keys-generate
```

- 方法2：`encryption/onie-encrypt.sh`
```
./onie-encrypt.sh generate-key-set 'dev-vendor' 'dev-key' 'dev-test@vendor.org' 'development key' 

			GEN_KEY_USER="$2"
			GEN_KEY_CERT_NAME="$3"
			GEN_KEY_USER_EMAIL="$4"
			GEN_KEY_DESCRIPTION="$5"

./encryption/machines/cls_ds4101/keys/SW/gpg-keys/SW-pubring.kbx
pub   rsa4096 2025-05-19 [SCEAR]
      5DF74B564CB9027477AE42ECE9B84207114878DB
uid           [ unknown] SW (Software vendor certificate.) <software@onie.org>

./onie-encrypt.sh build-uefi-vars
```

#### Keys用途

- ONIE_VENDOR_SECRET_KEY_PEM ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-secret-key.pem
  - 用 efi-sign.sh (sbsign) 给 grubx64.efi 签名的 私钥 (grub.make/efi-sign.sh | images.make/onie-mk-iso.sh) (实际是仅 recovery image 有效)
  - 用 sbsign 给 KERNEL_VMLINUZ 签名的 私钥 (kernel.make/sbsign)
- ONIE_VENDOR_CERT_DER ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-cert.der
  - shim 编译时，作为 VENDOR_CERT_FILE 的值 被写入 shimx64.efi ， 作为 grubx64.efi 的签名证书/公钥 (所以从shim验证grub成功)
- ONIE_VENDOR_CERT_PEM ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-cert.pem
  - 用 efi-sign.sh (sbsign) 给 grubx64.efi 签名的 私钥对应的公钥 (grub.make/efi-sign.sh | images.make/onie-mk-iso.sh) (实际是仅 recovery image 有效)
  - 用 sbsign 给 KERNEL_VMLINUZ 签名的 私钥对应的公钥 (kernel.make/sbsign)

- SHIM_SELF_SIGN_SECRET_KEY_PEM ?= $(SIGNING_KEY_DIRECTORY)/SW/efi-keys/SW-database-key-secret-key.pem
  - 用 efi-sign.sh (sbsign) 给 shim bin 的各个文件 (`shim$(EFI_ARCH).efi fb$(EFI_ARCH).efi mm$(EFI_ARCH).efi`) 自我签名的 私钥 (shim.make/efi-sign.sh)
- SHIM_SELF_SIGN_PUBLIC_CERT_PEM ?= $(SIGNING_KEY_DIRECTORY)/SW/efi-keys/SW-database-key-cert.pem
  - 用 efi-sign.sh (sbsign) 给 shim bin 的各个文件 (`shim$(EFI_ARCH).efi fb$(EFI_ARCH).efi mm$(EFI_ARCH).efi`) 自我签名的 公钥 (shim.make/efi-sign.sh)

- ONIE_MODULE_SIG_KEY_SRCPREFIX ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys
  - 编译 kernel 时， 作为 MODULE_SIG_KEY_SRCPREFIX 的值， 给 kernel loadable modules 提供签名所需的 私钥公钥等。在开启安全启动时(在内核.config处enable)内核构建时会自动查找和签名 (kernel.make/`$(MAKE) -C $(LINUXDIR) all`)

- SHIM_EMBED_DER ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-cert.der
  - 此处应放 NOS 的公钥，用于编译进 shimx64.efi ， shimx64.efi 将传递该公钥到 OS 层 (shim.make)

- GPG_SIGN_PUBRING ?= $(SIGNING_KEY_DIRECTORY)/ONIE/gpg-keys/ONIE-pubring.kbx
  - GPG 签名 grub 模块时用的 公钥 (grub.make/mk-grub-efi-image)
- GPG_SIGN_SECRING ?= $(SIGNING_KEY_DIRECTORY)/ONIE/gpg-keys/ONIE-secret.asc
  - GPG 签名 SYSROOT_CPIO_XZ 时用的 私钥 (images.make/gpg-sign.sh)
  - GPG 签名 KERNEL_VMLINUZ 时用的 私钥 (kernel.make/gpg-sign.sh)
  - GPG 签名 onie-updater 里的 grub 配置文件 grub_sb.cfg grub.cfg 时用的 私钥 (images.make/onie-mk-installer.sh/gpg-sign.sh)


- Others
  ```
  # Keys that sign Grub
  GRUB_SECRET_KEY ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-secret-key.pem
  GRUB_PUBLIC_CERT ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-cert.pem

  # Keys that sign the kernel
  KERNEL_SECRET_KEY ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-secret-key.pem
  KERNEL_PUBLIC_CERT ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-cert.pem

  # Keys that sign grub in the recovery image
  IMAGE_SECRET_KEY ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-secret-key.pem
  IMAGE_PUBLIC_CERT ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-cert.pem

  # UEFI keys

  # Key Exchange Key database. Keys here can modify db/dbx entries
  KEK_SOFTWARE_CERT ?= $(SIGNING_KEY_DIRECTORY)/SW/efi-keys/SW-key-exchange-key-cert.pem
  KEK_HARDWARE_CERT ?= $(SIGNING_KEY_DIRECTORY)/HW/efi-keys/HW-key-exchange-key-cert.pem

  # Key DataBase - keys here are available for shim/grub use too
  DB_SOFTWARE_CERT ?= $(SIGNING_KEY_DIRECTORY)/SW/efi-keys/SW-database-key-cert.pem
  DB_HARDWARE_CERT ?= $(SIGNING_KEY_DIRECTORY)/HW/efi-keys/HW-database-key-cert.pem

  # Example of Support for an additional key in UEFI db. This could be a development key,
  # or an additional NOS vendor key.  Uncomment to use.
  #DB_EXTRA_CERT ?= $(SIGNING_KEY_DIRECTORY)/extra/key-exported-dev/dev-code-signing.pem

  # Hardware manufacturer's keys
  PLATFORM_CERT ?= $(SIGNING_KEY_DIRECTORY)/HW/efi-keys/HW-platform-key-cert.pem
  PLATFORM_SECRET_KEY ?= $(SIGNING_KEY_DIRECTORY)/HW/efi-keys/HW-platform-key-secret-key.pem

  # Copy this key to be available for the developer at BIOS setup time.
  PK_BIOS_KEY ?= $(SIGNING_KEY_DIRECTORY)/HW/efi-keys/HW-platform-key-cert.der
  ```

