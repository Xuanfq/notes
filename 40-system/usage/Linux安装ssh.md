1.  Update apt-get: `sudo apt-get update`.
2.  Install ssh service: `sudo apt-get install openssh-server` and `sudo apt-get install openssh-client`(ssh client usually doesn't need because ). Or `apt-get install ssh`.
3.  Startup ssh service: `sudo /etc/init.d/ssh start`.
4.  Modify the ssh configuration file: `sudo vim /etc/ssh/sshd_config`. Find the `PermitRootLogin without-password` item and change as `PermitRootLogin yes`.
5.  Reboot ssh service: `service ssh restart`.

##

### 一、安装openssh

使用如下命令安装openssh

    sudo apt install openssh-server

### 二、修改配置文件

安装完成后修改配置文件/etc/ssh/sshd\_config，命令如下

    sudo nano /etc/ssh/sshd_config

将

     #PermitRootLogin prohibit-password

改成

    PermitRootLogin yes

### 三、重启服务

使用如下命令程序ssh服务

    sudo systemctl restart ssh

### 四、测试

使用如下命令测试是否能成功登录

    ssh root@localhost

## 一键配置脚本

以下是一键配置脚本，直接新建rootlogin.sh脚本文件，打开后把以下命令粘贴进去然后，运行脚本文件即可。

    #!/bin/bash

    #set root password
    sudo passwd root
     
    #notes Document content
    sudo sed -i "s/.*root quiet_success$/#&/" /etc/pam.d/gdm-autologin
    sudo sed -i "s/.*root quiet_success$/#&/" /etc/pam.d/gdm-password
     
    #modify profile
    sudo sed -i 's/^mesg.*/tty -s \&\& mesg n \|\| true/' /root/.profile
     
    #install openssh
    sudo apt install openssh-server
     
    #delay
    sleep 1
     
    #modify conf
    sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
     
    #restart server
    sudo systemctl restart ssh

