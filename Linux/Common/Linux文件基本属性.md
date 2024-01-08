Linux 系统是一种典型的多用户系统，不同的用户处于不同的地位，拥有不同的权限。

为了保护系统的安全性，Linux 系统对不同的用户访问同一文件（包括目录文件）的权限做了不同的规定。

在 Linux 中我们通常使用以下两个命令来修改文件或目录的所属用户与权限：

*   `chown` (change owner) ： 修改所属用户与组。
*   `chmod` (change mode) ： 修改用户的权限。

### 显示文件属性

语法：

    ll 或 ls -l



    drwxr-xr-x  20 root root       4096 Sep  9  2022 ../
    lrwxrwxrwx   1 root root          7 Sep  9  2022 bin -> usr/bin/
    drwxr-xr-x   4 root root       4096 May  8 06:55 boot/
    drwxrwxr-x   2 root root       4096 Sep  9  2022 cdrom/
    drwxr-xr-x  21 root root       4480 May 24 04:34 dev/

### 文件属性详情

`drwxr-xr-x 20 root root 4096 Sep 9 2022 ../ `

`lrwxrwxrwx 1 root root 7 Sep 9 2022 bin -> usr/bin/`

*   `drwxr-xr-x` 中d为file type，file type包括：

    *   当为 d 则是目录
    *   当为 - 则是文件；
    *   若是 l 则表示为链接文档(link file)；
    *   若是 b 则表示为装置文件里面的可供储存的接口设备(可随机存取装置)；
    *   若是 c 则表示为装置文件里面的串行端口设备，例如键盘、鼠标(一次性读取装置)。
*   `drwxr-xr-x` 三个为一组，且均为 rwx 的三个参数的组合。其中， r 代表可读(read)、 w 代表可写(write)、 x 代表可执行(execute)：

    *   rwx为user permissions属主权限
    *   第一个r-x为group permissions属组权限
    *   第二个r-x为other (everyone) permissions其他用户权限
*   `20` 是number of hard links
*   `root` 是user (owner) name
*   `root` 是group name
*   `4096` 是size
*   `Sep 9 2022` 是date/time last modified
*   `bin -> usr/bin/` 是filename (and link)

### &#x20;更改文件属性

#### 1、chgrp：更改文件属组

语法：

    chgrp [-R] 属组名 文件名

参数选项

*   \-R：递归更改文件属组，就是在更改某个目录文件的属组时，如果加上-R的参数，那么该目录下的所有文件的属组都会更改。

### 2、chown：更改文件属主，也可以同时更改文件属组

语法：

    chown [–R] 属主名 文件名
    chown [-R] 属主名：属组名 文件名

进入 /root 目录（\~）将install.log的拥有者改为bin这个账号：

    [root@www ~] cd ~
    [root@www ~]# chown bin install.log
    [root@www ~]# ls -l
    -rw-r--r--  1 bin  users 68495 Jun 25 08:53 install.log

将install.log的拥有者与群组改回为root：

    [root@www ~]# chown root:root install.log
    [root@www ~]# ls -l
    -rw-r--r--  1 root root 68495 Jun 25 08:53 install.log

### 3、chmod：更改文件权限

Linux文件属性有两种设置方法，一种是数字，一种是符号。

Linux 文件的基本权限就有九个，分别是 **owner/group/others(拥有者/组/其他)** 三种身份各有自己的 **read/write/execute** 权限。

先复习一下刚刚上面提到的数据：文件的权限字符为： -rwxrwxrwx ， 这九个权限是三个三个一组的！其中，我们可以使用数字来代表各个权限，各权限的分数对照表如下：

*   r:4
*   w:2
*   x:1

每种身份(owner/group/others)各自的三个权限(r/w/x)分数是需要累加的，例如当权限为： -rwxrwx--- 分数则是：

*   owner = rwx = 4+2+1 = 7
*   group = rwx = 4+2+1 = 7
*   others= --- = 0+0+0 = 0

所以等一下我们设定权限的变更时，该文件的权限数字就是 **770**。变更权限的指令 chmod 的语法是这样的：

     chmod [-R] xyz 文件或目录

选项与参数：

*   **xyz** : 就是刚刚提到的数字类型的权限属性，为 **rwx** 属性数值的相加。
*   **-R** : 进行递归(recursive)的持续变更，以及连同次目录下的所有文件都会变更

举例来说，如果要将 **.bashrc** 这个文件所有的权限都设定启用，那么命令如下：

    [root@www ~]# ls -al .bashrc
    -rw-r--r--  1 root root 395 Jul  4 11:45 .bashrc
    [root@www ~]# chmod 777 .bashrc
    [root@www ~]# ls -al .bashrc
    -rwxrwxrwx  1 root root 395 Jul  4 11:45 .bashrc

那如果要将权限变成 *-rwxr-xr--* 呢？那么权限的分数就成为 \[4+2+1]\[4+0+1]\[4+0+0]=754。

#### 符号类型改变文件权限

还有一个改变权限的方法，从之前的介绍中我们可以发现，基本上就九个权限分别是：

*   user：用户
*   group：组
*   others：其他

那么我们就可以使用 **u, g, o** 来代表三种身份的权限。

此外， **a** 则代表 **all**，即全部的身份。读写的权限可以写成 r, w, x，也就是可以使用下表的方式来看：

| chmod | u g o a | +(加入) -(除去) =(设定) | r w x | 文件或目录 |
| :---- | :------ | :---------------- | :---- | :---- |

如果我们需要将文件权限设置为 **-rwxr-xr--** ，可以使用 chmod u=rwx,g=rx,o=r 文件名 来设定:

    #  touch test1    // 创建 test1 文件
    # ls -al test1    // 查看 test1 默认权限
    -rw-r--r-- 1 root root 0 Nov 15 10:32 test1
    # chmod u=rwx,g=rx,o=r  test1    // 修改 test1 权限
    # ls -al test1
    -rwxr-xr-- 1 root root 0 Nov 15 10:32 test1

而如果是要将权限去掉而不改变其他已存在的权限呢？例如要拿掉全部人的可执行权限，则：

    #  chmod  a-x test1
    # ls -al test1
    -rw-r--r-- 1 root root 0 Nov 15 10:32 test1

