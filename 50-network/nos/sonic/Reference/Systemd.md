# Systemd


在现代 Linux 系统中，`systemd` 已成为事实上的初始化系统（init system）和系统管理器，取代了传统的 SysVinit 和 Upstart。它不仅负责系统启动、服务管理，还整合了日志、设备管理、挂载点、定时器等功能，提供了更高效、灵活且统一的系统管理方式。本文将深入探讨 systemd 的核心概念、常用工具、最佳实践及常见用例，帮助读者从入门到精通 systemd 的使用与配置。



## 1. 什么是 systemd？

`systemd`（"system daemon" 的缩写）是一个系统初始化程序和服务管理器，由 Lennart Poettering 等人开发，首次发布于 2010 年。它的设计目标是解决传统 SysVinit 的缺点（如串行启动、依赖管理复杂、启动速度慢等），提供：

- **并行化启动**：通过异步启动服务加速系统引导；
- **按需激活服务**：通过 socket、D-Bus 或路径触发服务启动；
- **统一的配置与管理**：使用单元文件（Unit Files）描述系统资源；
- **集成日志系统**（journald）：集中管理系统日志，支持结构化查询；
- **跨会话服务管理**：支持系统级和用户级服务；
- **依赖管理**：精确控制服务启动顺序和依赖关系。

目前，主流 Linux 发行版（如 Ubuntu、Fedora、Debian、CentOS、Arch Linux 等）均已采用 systemd 作为默认 init 系统。

## 2. 核心概念

### 2.1 Units（单元）

**Unit（单元）** 是 systemd 管理的最基本对象，用于描述系统资源和服务。每个单元由一个 **单元文件**（Unit File）定义，包含配置参数和行为规则。

### 2.2 Targets（目标）

**Target（目标）** 是一组单元的集合，用于模拟传统 SysVinit 的“运行级别”（Runlevel），定义系统的一种“状态”。例如，`multi-user.target` 表示多用户命令行模式，`graphical.target` 表示图形界面模式。

### 2.3 Systemd 守护进程与工具链

- **systemd**：核心守护进程，PID 为 1，是所有进程的父进程；
- **systemctl**：管理 systemd 的主要命令行工具（启停服务、查看状态等）；
- **journalctl**：查看和管理 systemd 日志（journald 服务的前端工具）；
- **systemd-analyze**：分析启动性能、验证单元文件等；
- **systemd-cgtop**：查看控制组（cgroup）资源使用情况；
- **systemd-run**：临时运行一次性服务或进程。

## 3. Units：systemd 的基本管理单元

### 3.1 单元类型

systemd 支持多种单元类型，常见类型及后缀如下表：

| 单元类型       | 后缀         | 描述                                   | 示例场景                        |
| -------------- | ------------ | -------------------------------------- | ------------------------------- |
| Service Unit   | `.service`   | 管理系统服务（最常用）                 | `nginx.service`、`sshd.service` |
| Socket Unit    | `.socket`    | 管理网络/UNIX 套接字，用于按需激活服务 | `sshd.socket`、`docker.socket`  |
| Target Unit    | `.target`    | 定义系统状态（类似运行级别）           | `multi-user.target`             |
| Mount Unit     | `.mount`     | 管理文件系统挂载                       | `mnt_data.mount`                |
| Automount Unit | `.automount` | 自动挂载文件系统（按需挂载）           | `mnt_data.automount`            |
| Timer Unit     | `.timer`     | 定时任务（替代 cron 的部分功能）       | `backup.timer`                  |
| Path Unit      | `.path`      | 监控文件/目录变化，触发服务            | `monitor_logs.path`             |

### 3.2 单元文件结构

单元文件采用 INI 格式，包含多个 **小节（Section）** 和 **键值对（Key=Value）**。以 `.service` 文件为例，常见小节如下：

#### 示例：`nginx.service` 简化版

```
[Unit]
Description=A high performance web server and a reverse proxy server  # 描述
After=network.target remote-fs.target nss-lookup.target  # 启动依赖（在这些单元之后启动） 

[Service]Type=forking  # 服务类型（simple/forking/oneshot/dbus/notify/idle）
PIDFile=/run/nginx.pid  # PID 文件路径（Type=forking 时必填）
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf  # 启动命令
ExecReload=/bin/kill -s HUP $MAINPID  # 重载配置命令
ExecStop=/bin/kill -s TERM $MAINPID  # 停止命令
Restart=on-failure  # 故障时自动重启User=root  # 运行用户
Group=root  # 运行组 

[Install]
WantedBy=multi-user.target  # 安装目标（启动时依赖的目标）
```

#### 核心小节说明：

- **[Unit]**：定义单元的元数据（描述、依赖关系等）。
  常用指令：`Description`（描述）、`After`/`Before`（启动顺序）、`Requires`/`Wants`（依赖关系）
- `Requires`：强依赖，依赖单元失败则本单元也失败；
  - `Wants`：弱依赖，依赖单元失败不影响本单元。
- **[Service]**：仅服务单元（`.service`）特有，定义服务行为。
  常用指令：

  - `Type`：服务类型（关键！）：

    - `simple`（默认）：`ExecStart` 进程即为服务主进程，前台运行；
    - `forking`：`ExecStart` 进程会 fork 子进程并退出，子进程为服务主进程（需指定 `PIDFile`）；
    - `oneshot`：一次性任务，执行完后服务退出（需配合 `RemainAfterExit=yes` 保持“激活”状态）。

  - `Restart`：重启策略（`no`/`on-success`/`on-failure`/`always`/`on-abnormal`）；

  - `User`/`Group`：服务运行的用户/组（安全最佳实践：避免使用 root）；

  - `ExecStart`/`ExecStop`/`ExecReload`：启动/停止/重载命令。
- **[Install]**：定义单元的安装配置（如开机自启时依赖的目标）。
  常用指令：
  - `WantedBy`（当前单元被哪个目标“需要”，即开机自启时关联的目标）。

### 3.3 常用单元操作命令

`systemctl` 是管理单元的核心工具，以下为高频命令：

| 命令                                  | 作用                                 | 示例                                  |
| ------------------------------------- | ------------------------------------ | ------------------------------------- |
| `systemctl start <unit>`              | 启动单元                             | `systemctl start nginx.service`       |
| `systemctl stop <unit>`               | 停止单元                             | `systemctl stop nginx.service`        |
| `systemctl restart <unit>`            | 重启单元                             | `systemctl restart nginx.service`     |
| `systemctl reload <unit>`             | 重载单元配置（不重启服务）           | `systemctl reload nginx.service`      |
| `systemctl status <unit>`             | 查看单元状态（详细信息）             | `systemctl status nginx.service`      |
| `systemctl enable <unit>`             | 开机自启（创建符号链接到目标目录）   | `systemctl enable nginx.service`      |
| `systemctl disable <unit>`            | 禁止开机自启（删除符号链接）         | `systemctl disable nginx.service`     |
| `systemctl is-active <unit>`          | 检查单元是否激活（运行中）           | `systemctl is-active nginx.service`   |
| `systemctl is-enabled <unit>`         | 检查单元是否开机自启                 | `systemctl is-enabled nginx.service`  |
| `systemctl list-units --type=service` | 列出所有活动的服务单元               | `systemctl list-units --type=service` |
| `systemctl cat <unit>`                | 查看单元文件内容                     | `systemctl cat nginx.service`         |
| `systemctl edit <unit>`               | 编辑单元文件（推荐，会生成覆盖配置） | `systemctl edit nginx.service`        |

## 4. Targets：系统运行级别管理

### 4.1 目标与传统运行级别的对应关系

systemd 的 Target 替代了 SysVinit 的“运行级别”（Runlevel），常见对应关系如下：

| SysVinit 运行级别 | systemd Target      | 描述                                         |
| ----------------- | ------------------- | -------------------------------------------- |
| 0                 | `poweroff.target`   | 关机                                         |
| 1 / s             | `rescue.target`     | 单用户救援模式                               |
| 2                 | `multi-user.target` | 多用户模式（无图形界面，Debian/Ubuntu 特殊） |
| 3                 | `multi-user.target` | 多用户命令行模式                             |
| 4                 | `multi-user.target` | 未使用（保留）                               |
| 5                 | `graphical.target`  | 图形界面模式                                 |
| 6                 | `reboot.target`     | 重启                                         |

### 4.2 目标管理命令

| 命令                             | 作用                               | 示例                                      |
| -------------------------------- | ---------------------------------- | ----------------------------------------- |
| `systemctl get-default`          | 查看当前默认目标                   | `systemctl get-default`                   |
| `systemctl set-default <target>` | 设置默认目标（永久生效）           | `systemctl set-default multi-user.target` |
| `systemctl isolate <target>`     | 切换到指定目标（临时生效，不重启） | `systemctl isolate graphical.target`      |
| `systemctl list-targets`         | 列出所有目标状态                   | `systemctl list-targets`                  |

## 5. Journal：systemd 的日志系统

systemd 通过 **journald** 服务统一管理日志，日志以二进制格式存储（默认路径 `/run/log/journal/` 或 `/var/log/journal/`），通过 `journalctl` 工具查询。

### 5.1 Journalctl 常用命令

| 命令                                    | 作用                                     | 示例                                           |
| --------------------------------------- | ---------------------------------------- | ---------------------------------------------- |
| `journalctl`                            | 查看所有日志（按时间倒序）               | `journalctl`                                   |
| `journalctl -u <unit>`                  | 查看指定单元的日志                       | `journalctl -u nginx.service`                  |
| `journalctl -u <unit> --since "1h ago"` | 查看指定单元最近 1 小时的日志            | `journalctl -u nginx.service --since "1h ago"` |
| `journalctl -f`                         | 实时跟踪日志（类似 `tail -f`）           | `journalctl -f -u sshd.service`                |
| `journalctl -p err`                     | 只显示错误级别（priority=err）及以上日志 | `journalctl -p err`                            |
| `journalctl --no-pager`                 | 不分页显示日志                           | `journalctl --no-pager`                        |
| `journalctl -o json`                    | 以 JSON 格式输出日志（便于解析）         | `journalctl -o json -u nginx.service`          |

### 5.2 日志持久化与配置

默认情况下，journald 日志存储在内存（`/run/log/journal/`，重启后丢失）。如需持久化，需：

1. 创建日志目录并设置权限：

   ```
   sudo mkdir -p /var/log/journalsudo systemd-tmpfiles --create --prefix /var/log/journal
   ```

2. 重启 journald 服务：

   ```
   sudo systemctl restart systemd-journald
   ```

3. （可选）配置日志大小限制：编辑`/etc/systemd/journald.conf`，设置：

   ```
    SystemMaxUse=500M  # 最大占用磁盘空间MaxRetentionSec=1month  # 日志最大保留时间
   ```

## 6. 最佳实践

### 6.1 编写高质量的单元文件

- **明确依赖关系**：使用 `After`/`Before` 控制启动顺序，`Wants`（弱依赖）替代 `Requires`（强依赖）避免级联失败；

- **合理设置重启策略**：非关键服务使用 `Restart=on-failure`，避免 `Restart=always` 导致无限重启；

- **遵循最小权限原则**：通过 `User`/`Group` 指定非 root 用户运行服务，避免直接使用 root；

- 启用安全加固选项（在`[Service]`小节添加）：

  ```
  PrivateTmp=yes  # 为服务分配独立的 /tmp 目录，隔离其他服务
  NoNewPrivileges=yes  # 禁止提升权限（防止漏洞利用）
  ProtectSystem=strict  # 只读保护 /usr、/boot 等系统目录
  ReadWritePaths=/var/log/myapp  # 仅允许写入指定目录
  ```

- **避免硬编码路径**：使用环境变量（如 `$MAINPID` 指代主进程 PID）。

### 6.2 服务管理与优化

- **禁用不需要的服务**：通过 `systemctl disable <service>` 关闭开机自启，减少资源占用（如 `bluetooth.service`、`avahi-daemon.service` 等非必需服务）；
- **使用用户级服务**：通过 `systemctl --user` 管理用户私有服务（配置文件路径 `~/.config/systemd/user/`），避免污染系统级配置；
- **优先使用 Timer 替代 Cron**：Timer 单元（`.timer`）与 systemd 集成度更高，支持依赖管理和日志记录（见用例 2）；
- ** masking 危险服务**：对于绝对不能启动的服务，使用 `systemctl mask <service>`（创建 `/dev/null` 符号链接，禁止任何方式启动），而非 `disable`。

### 6.3 日志管理最佳实践

- **开启日志持久化**：避免重启后日志丢失（见 5.2 节）；
- **定期清理日志**：使用 `journalctl --vacuum-size=100M` 手动清理日志，或配置 `journald.conf` 自动限制大小；
- **结合集中式日志**：对于多主机环境，将 journald 日志转发到 ELK、Graylog 等集中日志平台（配置 `/etc/systemd/journald.conf` 中的 `ForwardToSyslog=yes` 或 `ForwardToConsole=yes`）。

## 7. 常见用例

### 7.1 用例 1：创建自定义服务

**需求**：将一个 Python 脚本（`/opt/myapp/app.py`）注册为系统服务，支持开机自启、日志记录和故障重启。

#### 步骤 1：编写单元文件

创建 `/etc/systemd/system/myapp.service`：

```
[Unit]
Description=My Custom Python Application
After=network.target  # 网络就绪后启动
 
[Service]
Type=simple
User=www-data  # 非 root 用户运行
Group=www-data
WorkingDirectory=/opt/myapp
ExecStart=/usr/bin/python3 /opt/myapp/app.py
Restart=on-failure  # 故障时重启
RestartSec=5  # 重启间隔 5 秒
PrivateTmp=yes  # 安全加固：独立 /tmp
 
[Install]
WantedBy=multi-user.target  # 多用户模式下自启
```

#### 步骤 2：加载并测试服务

```
sudo systemctl daemon-reload  # 重新加载单元文件
sudo systemctl start myapp.service  # 启动服务
sudo systemctl status myapp.service  # 检查状态
sudo systemctl enable myapp.service  # 设置开机自启
```

#### 步骤 3：查看日志

```
journalctl -u myapp.service -f  # 实时跟踪服务日志
```

### 7.2 用例 2：使用 Timer 替代 Cron 任务

**需求**：每天凌晨 3 点执行 `/opt/backup.sh` 备份脚本。

#### 步骤 1：创建服务单元（`backup.service`）

```
[Unit]
Description=Daily Backup Script
 
[Service]
Type=oneshot  # 一次性任务
ExecStart=/opt/backup.sh
User=root
```

#### 步骤 2：创建定时器单元（`backup.timer`）

```
[Unit]
Description=Run daily backup at 3 AM
 
[Timer]
OnCalendar=*-*-* 03:00:00  # 每天凌晨 3 点执行
Persistent=yes  # 若上次未执行（如关机），开机后补执行
AccuracySec=1min  # 允许 1 分钟误差（减少资源消耗）
 
[Install]
WantedBy=timers.target  # 依赖 timers.target
```

#### 步骤 3：启用定时器

```
sudo systemctl daemon-reload
sudo systemctl enable --now backup.timer  # 启用并立即启动定时器
```

#### 验证定时器状态

```
systemctl list-timers --all  # 查看所有定时器（包含下次执行时间）
```

### 7.3 用例 3：故障排查：修复启动失败的服务

**问题**：`nginx.service` 启动失败，提示 `Job for nginx.service failed because the control process exited with error code.`

#### 排查步骤：

1. **查看服务状态**：

   ```
   systemctl status nginx.service -l  # -l 显示完整日志
   ```

   可能看到错误信息：`nginx: [emerg] invalid port in listen directive`（配置文件端口错误）。

2. **查看详细日志**：

   ```
   journalctl -u nginx.service --since "10min ago"  # 查看最近 10 分钟的 nginx 日志
   ```

3. **验证单元文件语法**：

   ```
   systemd-analyze verify nginx.service  # 检查单元文件是否有语法错误
   ```

4. **修复配置并重启**：
   修正 `/etc/nginx/nginx.conf` 中的端口配置，然后：

   ```
   sudo systemctl restart nginx.service
   ```

## 8. 故障排查工具

- **`systemctl status <unit>`**：快速定位服务失败原因（状态、错误日志片段）；

- **`journalctl -u <unit> -b`**：查看当前启动周期内的服务日志（`-b` 表示当前启动）；

- **`systemd-analyze verify <unit>`**：验证单元文件语法和依赖关系；

- `systemd-analyze blame`

  ：列出启动过程中耗时最长的单元（用于优化开机速度）；

  示例：

  ```
  systemd-analyze blame  # 输出：5.234s NetworkManager-wait-online.service
  ```

- `systemctl list-dependencies <unit>`：查看单元的依赖关系链；

  示例：

  ```
  systemctl list-dependencies nginx.service  # 查看 nginx 依赖的所有单元
  ```

## 9. 总结

systemd 作为现代 Linux 的核心组件，提供了统一、高效的系统管理能力。掌握其单元、目标、日志等核心概念，结合最佳实践（如最小权限、合理依赖、日志持久化），能显著提升系统稳定性和可维护性。无论是日常服务管理、自定义任务调度，还是故障排查，systemd 都是 Linux 管理员不可或缺的工具。

## 10. 参考资料

- **官方文档**：[Freedesktop.org systemd 文档](https://www.freedesktop.org/wiki/Software/systemd/)
- **Man 手册**：`man systemd`、`man systemctl`、`man journalctl`、`man systemd.unit`
- **Arch Linux Wiki**：[Systemd 专题](https://wiki.archlinux.org/title/Systemd)（内容全面，适用于所有发行版）
- **书籍**：《Systemd: Managing Services and Daemons in Linux》by Lars Wirzenius
- **工具**：[Systemd 单元文件生成器](https://systemd-generator.net/)（在线生成简单单元文件）
- **笔记**：https://geek-blogs.com/blog/linux-system-d/



