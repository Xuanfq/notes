# Supervisord

`Supervisord`是一个用 **Python** 编写的进程管理工具，主要用于在类 Unix 系统（如 Linux）中**监控和控制多个前台进程**。它能确保进程持续运行，并在进程崩溃或退出时自动重启，非常适合守护长期运行的服务。


## 核心特点

- C/S架构: supervisord 作为服务端负责启动、监控、重启进程；supervisorctl 作为客户端提供命令行接口管理进程。
- 自动重启: 进程异常退出时可自动拉起。
- 集中管理: 支持统一配置文件管理多个进程，并可通过 Web 界面操作。
- 日志管理: 可捕获 stdout/stderr 输出并保存到指定日志文件。


## 安装方式

- 使用pip安装
```sh
pip install supervisor
```

- 使用yum安装

```sh
sudo yum install epel-release
sudo yum install -y supervisor
```


## 修改配置

- 生成默认配置文件: `echo_supervisord_conf > /etc/supervisord.conf`

- 建议使用 include 引入子配置

  - `mkdir -p /etc/supervisord.d/`

  - 在主配置文件中添加

    ```config
    [include]
    files = /etc/supervisord.d/*.ini
    ```

- 配置Web管理界面 （ `/etc/supervisord.conf` ）：

  ```
  [inet_http_server]
  port=*:9001
  username=admin
  password=your_password
  ```



示例：/etc/supervisord.d/my_app.ini

```
[program:my_app]
directory=/opt/myapp
command=python app.py
autostart=true
autorestart=true
startsecs=5
user=root
stdout_logfile=/var/log/supervisor/my_app.out.log
stderr_logfile=/var/log/supervisor/my_app.err.log
environment=ENV="production"
```



## 常用命令

- 启动/停止supervisord服务
```
systemctl start supervisord
systemctl stop supervisord
```


- 管理进程
```
supervisorctl status
supervisorctl start my_app
supervisorctl stop my_app
supervisorctl restart my_app
```


- 配置变更后重载
```
supervisorctl update # 仅更新有变动的进程
supervisorctl reload # 重启所有进程
```





