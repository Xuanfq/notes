### 1. 执行系统更新

    sudo apt install xrdp

### 2. 安装并启动XRDP

    sudo apt install xrdp  # 安装xrdp

    sudo systemctl start xrdp  # 启动xrdp

    sudo systemctl enable xrdp  # 开机自启

    systemctl status xrdp  # 查看xrdp状态

### 3. Remote Desktop Connection连接

![](https://pic2.zhimg.com/80/v2-9d0e56840db9b195ebb2518d9ed42331_1440w.webp)

### 4. xrdp远程桌面黑屏/空屏/无画面解决办法

在 /etc/xrdp/startwm.sh 插入以下代码（注意代码位置）

    #vi /etc/xrdp/startwm.sh

    unset DBUS_SESSION_BUS_ADDRESS
    unset XDG_RUNTIME_DIR
    . $HOME/.profile

![](https://pic1.zhimg.com/80/v2-26630883e20c4ef9ffa7beea502ab8dc_1440w.webp)

重启xrdp
