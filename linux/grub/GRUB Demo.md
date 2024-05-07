
## GRUB Demo






- 首先需要一个空白文件，我将其填充为zero 512MiB

```
dd if=/dev/zero of=./grub.img bs=1024 count=524288
```


- 得到grub.img大小为512MiB的文件，然后将其挂载为loop设备

```
mknod /dev/loop200 b 7 200
losetup /dev/loop200 ./grub.img
```

为loop200分区, 若loop0-7为空，可使用loop0-7，不执行mknod

- 添加dos分区表，然后创建一个主分区，通过kpartx刷新系统分区识别信息

```
fdisk /dev/loop200
```

```
kpartx -av /dev/loop200
```

- 然后在/dev/mapper/下可以看到loop200p1设备文件，此设备文件就是loop200的第一个分区，为此分区创建文件系统，并将其挂载在boot文件夹下(可以是任意文件夹，我将其指定为boot)

```
mkfs.ext4 /dev/mapper/loop200p1
mount /dev/mapper/loop200p1 ./boot
```

- 手动安装grub2

```
apt install grub2
```

```
grub-install --boot-directory=/绝对路径/boot --target=i386-pc /dev/loop200
```

其中，–boot-directory指定了grub所需文件的放置位置，–target制定了平台，/dev/loop200指定了引导程序安装的设备

- 此时，这个grub启动盘已经安装好了，已经可以运行了

- 需要将这个文件转换为qemu镜像

```
sudo apt-get -y install qemu-system-x86
# apt-get install qemu-utils
```

```
qemu-img convert -O qcow2 grub.img qemu-grub.img
```

- 然后就可以用qemu运行这个虚拟启动盘
```
qemu-system-x86_64 -hda ./qemu-grub.img
```

此时可以看到，qemu窗口中已经出现grub画面: 
```
GNU GRUB version 2.06
Minimal BASH-like line editing is supported. For the first word，TAB
lists possible command completions. Anywhere else TAB lists possible
device or file completions

grub>
```

说明此时已经成功运行grub

- 编译一个linux内核，得到bzImage
将bzImage放入boot文件夹中，即放入镜像文件
然后重新用qemu-img制作一次镜像
然后在grub窗口中执行命令去引导此linux内核

```
grub>ls
(hd0)(hd0,msdos1)(fd0)
grub>root=(hd0,msdos1)
grub>linux /bzImage
grub>boot
```

然后可以看到内核已经启动了
但是我们没有传任何参数给内核，所以内核会在挂载根文件系统这一步崩溃，但此时至少可以证明grub可以引导linux内核了，引导功能是正常的