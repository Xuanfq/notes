新版ubuntu20.04 使用root用户并自动登录（桌面配置）

Ubuntu系统默认屏蔽了root登录权限，每次都要在终端给予权限

## 1.开启root用户登录权限

**a.为root设置密码**

`sudo passwd root`

密码强度要高，负责设置不成功

**b.修改50-ubuntu.conf配置文件内容**

`sudo chmod 777 /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf`

如果没有此文件，就到这个目录找类似文件

`sudo vim /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf`

在文件末尾加入两行代码

    greeter-show-manual-login=true
    all-guest=false

**c. 修改gdm-autologin和gdm-passwd文件**

    sudo chmod 777 /etc/pam.d/gdm-autologin
    sudo chmod 777 /etc/pam.d/gdm-password
    sudo vim /etc/pam.d/gdm-autologin
    sudo vim /etc/pam.d/gdm-password

两个文件都注释掉`auth required pam_success_if.so user!=root quiet_success`这一行

**d. 修改/root/.profile文件**

    sudo vim /root/.profile

打开文件，注释掉最后一行，然后加上

    tty -s&&mesg n || true

## 2.root用户自动登录

**a. 修改custom.conf**

    sudo vim /etc/gdm3/custom.conf

ps：没有这个文件的话把设置里的用户登录的自动登录选项打开。

修改文件

    AutomaticLoginEnable=true

    AutomaticLogin=root

    TimedLoginEnable = true

    TimedLogin = root

    TimedLoginDelay = 10

