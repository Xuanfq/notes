# pmon.sh start

## 1. 获取启动类型

```bash
BOOT_TYPE=`getBootType`
```

从内核参数中读取启动类型（cold/warm/fast/fastfast/express）

## 2. 获取平台名称

```bash
PLATFORM=${PLATFORM:-`$SONIC_CFGGEN -H -v DEVICE_METADATA.localhost.platform`}
```

## 3. 加载设备ASIC配置文件 - asic.conf

```bash
ASIC_CONF=/usr/share/sonic/device/$PLATFORM/asic.conf
if [ -f "$ASIC_CONF" ]; then
    source $ASIC_CONF
fi
```

如果存在 ASIC 配置文件，则加载它

## 4. 设置 Syslog 目标 IP

- 单 ASIC 平台：`127.0.0.1`
- 多 ASIC 平台：从 docker bridge 网络获取网关 IP

## 5. 加载设备平台环境配置 - platform_env.conf

```bash
PLATFORM_ENV_CONF=/usr/share/sonic/device/$PLATFORM/platform_env.conf
if [ -f "$PLATFORM_ENV_CONF" ]; then
    source $PLATFORM_ENV_CONF
fi
```

## 6. 获取 HWSKU 信息

```bash
HWSKU=${HWSKU:-`$SONIC_CFGGEN -d -v 'DEVICE_METADATA["localhost"]["hwsku"]'`}
MOUNTPATH="/usr/share/sonic/device/$PLATFORM/$HWSKU"
```

构建挂载路径，多 ASIC 平台会附加 `$DEV` 后缀

## 7. 检查容器状态

- 容器已存在且 HWSKU 匹配，直接启动现有容器：

```bash
if [ x"$DOCKERMOUNT" == x"$MOUNTPATH" ]; then
    preStartAction
    /usr/local/bin/container start ${DOCKERNAME}
    postStartAction
    exit $?
fi
```

- 容器已存在但 HWSKU 不匹配，删除旧容器，准备创建新容器：

```bash
docker rm -f ${DOCKERNAME}
```

## 8. 准备容器创建

### 8.1 解析数据库配置

```bash
SONIC_DB_GLOBAL_JSON="/var/run/redis/sonic-db/database_global.json"
```

获取多 ASIC 平台的 Redis 目录列表, 存入 `redis_dir_list`

### 8.2 设置 Redis 挂载选项

- **单实例容器(DEV=$2, 不传入该参数时)或 dpudb 类型**：
  - 网络模式：`host`
  - 挂载 `redis_dir_list`中所有 Redis 实例目录
- **多 ASIC 平台**：
  - 网络模式：`container:database$DEV`
  - 只挂载命名空间特定的 Redis 目录, `redis_dir_list`中第 `$DEV`个

### 8.3 设置命名空间 ID

```bash
NAMESPACE_ID="$DEV"
if [[ $DATABASE_TYPE == "dpudb" ]]; then
    NAMESPACE_ID=""
fi
```

## 9. 创建容器

```bash
docker create --privileged -t \
    -v /etc/sonic:/etc/sonic:ro \
    -v /etc/localtime:/etc/localtime:ro \
    -v /host/reboot-cause:/host/reboot-cause:rw \
    -v /host/pmon/stormond:/usr/share/stormond:rw \
    -v /var/run/platform_cache:/var/run/platform_cache:ro \
    -v /usr/share/sonic/device/pddf:/usr/share/sonic/device/pddf:ro \
    --net=$NET \
    --uts=host \
    --tmpfs /var/log/supervisor:rw \
    --log-opt max-size=2M --log-opt max-file=5 \
    -v /usr/share/sonic/firmware:/usr/share/sonic/firmware:rw \
    -v /var/run/redis-chassis:/var/run/redis-chassis:ro \
    -v /usr/share/sonic/device/$PLATFORM/$HWSKU/$DEV:/usr/share/sonic/hwsku:ro \
    $REDIS_MNT \
    -v /etc/fips/fips_enable:/etc/fips/fips_enable:ro \
    -v /usr/share/sonic/device/$PLATFORM:/usr/share/sonic/platform:ro \
    -v /usr/share/sonic/templates/rsyslog-container.conf.j2:/usr/share/sonic/templates/rsyslog-container.conf.j2:ro \
    --tmpfs /tmp \
    --tmpfs /var/tmp \
    --env "NAMESPACE_ID"="$NAMESPACE_ID" \
    --env "NAMESPACE_PREFIX"="$NAMESPACE_PREFIX" \
    --env "NAMESPACE_COUNT"="$NUM_ASIC" \
    --env "DEV"="$DEV" \
    --env "CONTAINER_NAME"=$DOCKERNAME \
    --env "SYSLOG_TARGET_IP"=$SYSLOG_TARGET_IP \
    --env "PLATFORM"=$PLATFORM \
    --name=$DOCKERNAME \
    docker-platform-monitor:latest
```

## 10. 启动容器

```bash
preStartAction
/usr/local/bin/container start ${DOCKERNAME}
postStartAction
```

### preStartAction

- 若是多 ASIC 平台，更新 syslog 配置，使其使用 gateway ip 作为日志传输 ip

### postStartAction

- 复制平台传感器脚本到容器：local-`/usr/local/bin/platform_sensors.py`—cp—>docker-`/usr/bin/platform_sensors.py`
- 后台更新容器 DNS 配置：`/etc/resolvconf/update-libc.d/update-containers ${DOCKERNAME} &`

---

## 关键挂载点

| 挂载源                                                                     | 容器内路径                    | 权限         | 说明       |
| -------------------------------------------------------------------------- | ----------------------------- | ------------ | ---------- |
| `/etc/sonic`                                                             | `/etc/sonic`                | ro           | SONiC 配置 |
| `/host/reboot-cause`                                                     | `/host/reboot-cause`        | rw           | 重启原因   |
| `/var/run/redis$DEV`                            | `/var/run/redis$DEV` | rw                            | Redis 数据库 |            |
| `/usr/share/sonic/device/$PLATFORM/$HWSKU/$DEV`                          | `/usr/share/sonic/hwsku`    | ro           | HWSKU 文件 |
| `/usr/share/sonic/firmware`                                              | `/usr/share/sonic/firmware` | rw           | 固件文件   |

## 环境变量

| 变量名               | 说明                 |
| -------------------- | -------------------- |
| `NAMESPACE_ID`     | 命名空间 ID          |
| `NAMESPACE_PREFIX` | 命名空间前缀（asic） |
| `NAMESPACE_COUNT`  | 命名空间数量         |
| `DEV`              | 设备编号             |
| `CONTAINER_NAME`   | 容器名称             |
| `SYSLOG_TARGET_IP` | Syslog 目标 IP       |
| `PLATFORM`         | 平台名称             |




---



# docker start

## 一、关键配置文件解析

### 1. supervisord 配置模板（docker-pmon.supervisord.conf.j2）

**配置模板**：`/usr/share/sonic/templates/docker-pmon.supervisord.conf.j2`

**核心功能**：定义 PMON 容器中所有守护进程的运行参数

**主要配置项**：

| 程序                                     | 功能           | 关键配置                 | 条件启动                                                            |
| ---------------------------------------- | -------------- | ------------------------ | ------------------------------------------------------------------- |
| **/usr/sbin/rsyslogd**             | 日志管理       | `priority=1`           | 无条件                                                              |
| **/usr/bin/delay.py**              | 非紧急延时     |                          | delay_non_critical_daemon                                           |
| **/usr/local/bin/chassisd**        | 模块化机箱管理 |                          | not skip_chassisd &&<br />IS_MODULAR_CHASSIS == 1 or is_smartswitch |
| **/usr/local/bin/chassis_db_init** |                |                          | not skip_chassis_db_init                                            |
| **/usr/bin/lm-sensors**            | 传感器监控     | 基于 `sensors.conf`    | not skip_sensors &&`HAVE_SENSORS_CONF == 1`                       |
| **/usr/sbin/fancontrol**           | 风扇控制       | 基于 `fancontrol` 配置 | not skip_fancontrol &&`HAVE_FANCONTROL_CONF == 1`                 |
| **/usr/local/bin/ledd**            | LED 控制       | 支持 Python 2/3          | not skip_ledd                                                       |
| **/usr/local/bin/xcvrd**           | 光模块监控     | 支持多种选项             | not skip_xcvrd                                                      |
| **/usr/local/bin/ycabled**         | 双 ToR 配置    | 仅 DualToR 设备          | 仅 DualToR 设备                                                     |
| **/usr/local/bin/psud**            | 电源监控       | 支持 Python 2/3          | not skip_psud                                                       |
| **/usr/local/bin/syseepromd**      | EEPROM 读取    | 支持 Python 2/3          | not skip_syseepromd                                                 |
| **/usr/local/bin/thermalctld**     | 温度控制       | 支持 Python 2/3          | not skip_thermalctld                                                |
| **/usr/local/bin/pcied**           | PCIe 设备监控  | 固定路径                 | not skip_pcied                                                      |
| **/usr/local/bin/sensormond**      |                | 固定路径                 | include_sensormond                                                  |
| **/usr/local/bin/stormond**        |                | 固定路径                 | not skip_stormond                                                   |

**依赖启动机制**：

- `dependent_startup=true`：启用依赖启动
- `dependent_startup_wait_for=rsyslogd:running`：等待 rsyslogd 运行
- 确保服务启动顺序正确，避免依赖失败

---

### 2. 守护进程控制文件（pmon_daemon_control.json）

**配置文件**：`/usr/share/sonic/hwsku/pmon_daemon_control.json`（优先），或 `/usr/share/sonic/platform/pmon_daemon_control.json`

**核心功能**：控制哪些守护进程需要启动

**典型配置**：

```json
{
    "skip_ledd": true,
    "skip_xcvrd": true,
    "skip_pcied": true,
    "skip_psud": true,
    "skip_syseepromd": true,
    "skip_thermalctld": true,
    "skip_ycabled": false
}
```

**详细配置**：

- pmon_daemon_control.json
  - delay_non_critical_daemon
  - skip_chassisd
    - is_smartswitch
  - skip_chassis_db_init
  - skip_sensors
  - skip_fancontrol
  - skip_ledd
  - skip_xcvrd
    - skip_xcvrd_cmis_mgr
    - enable_xcvrd_sff_mgr
    - delay_xcvrd
  - skip_ycabled
  - skip_psud
  - skip_syseepromd
  - skip_thermalctld
  - skip_pcied
  - include_sensormond
  - skip_stormond
- 自动识别
  - IS_MODULAR_CHASSIS: 1
  - HAVE_FANCONTROL_CONF
  - HAVE_SENSORS_CONF
  - API_VERSION
- 其他提供
  - DEVICE_METADATA

**配置逻辑**：

- `skip_*`：设置为 `true` 时，对应守护进程不会在 supervisord 配置中生成
- 不同硬件平台可以根据需要跳过不需要的服务
- 例如，虚拟设备（kvm）会跳过大部分硬件相关服务

---

### 3. 平台 API 包（sonic_platform）

**文件所在**：`/usr/share/sonic/platform/sonic_platform-1.0-py2|3-none-any.whl`

**核心功能**：提供统一的硬件抽象接口

**Python 版本**：

- 支持 Python 2 和 Python 3
- 启动脚本会优先使用 Python 3 版本
- 如未安装，会从 `/usr/share/sonic/platform/` 目录安装

**关键模块**：

- 传感器读取
- 风扇控制
- 电源监控
- LED 管理
- EEPROM 读取

---

## 二、启动流程详解

### 1. 环境准备阶段

**目录结构**：

- 创建 `/etc/supervisor/conf.d/` 目录
- 创建 `/var/sonic/` 目录

**配置路径初始化**：

- 定义传感器、风扇控制、模板等关键文件路径，参照下方配置文件说明
- 确定守护进程控制文件的优先级（SKU > Platform）

**容器生命周期管理**：

- 若存在 `/usr/share/sonic/scripts/container_startup.py` 脚本，则执行，默认不存在: `/usr/share/sonic/scripts/container_startup.py -f pmon -o ${RUNTIME_OWNER} -v ${IMAGE_VERSION}` （可参阅 `src/sonic-ctrmgrd/ctrmgr/container_startup.py`）
- 以通知系统容器状态到swss，支持 kube/local 两种运行时，默认kube，可通过 `RUNTIME_OWNER=local`指定为local

---

### 2. 硬件就绪检查

**平台同步**：

- 执行 `/usr/share/sonic/platform/platform_wait` 脚本（如存在）
- 等待硬件初始化完成（如 FPGA 加载、BMC 就绪）
- 硬件未就绪时直接退出，确保后续服务能正常运行

---

### 3. 平台 API 安装

**Python 版本检测与安装**：

1. 检查 Python 2 版本的 sonic-platform 包
2. 检查 Python 3 版本的 sonic-platform 包
3. 优先使用 Python 3 版本，更新 API 版本标志

**安装策略**：

- 从平台目录的 wheel 包安装
- 详细的安装状态日志
- 即使安装失败也会继续执行（容错设计）

---

### 4. 平台特定配置

由参数 `CONFIGURED_PLATFORM`识别平台

**mellanox**：

- 使用 `/usr/share/sonic/platform/get_sensors_conf_path` 脚本动态获取传感器配置路径覆盖之前的配置 （若存在）

**nvidia-bluefield**：

- 挂载 debugfs 文件系统用于 SmartNIC 调试

---

### 5. 传感器与风扇配置

**传感器配置**：

- 检查 `/usr/share/sonic/platform/sensors.conf` 文件是否存在，不存在则跳过本配置
- 执行 PSU 传感器配置更新 `/usr/share/sonic/platform/psu_sensors_conf_updater`（如存在）
  - `source /usr/share/sonic/platform/psu_sensors_conf_updater`
  - `update_psu_sensors_configuration /usr/share/sonic/platform/sensors.conf`
- 检查是否存在临时传感器配置，若存在则指定其为传感器配置 `/tmp/sensors.conf`
- 复制最终配置到 `/etc/sensors.d/`

**风扇控制配置**：

- 检查 `/usr/share/sonic/platform/fancontrol` 文件，不存在则跳过本配置
- 清理旧的 PID 文件 `/var/run/fancontrol.pid`
- 复制配置到 `/etc/` 目录

---

### 6. 平台环境配置与机箱架构检测

**平台环境变量**：

- 加载 `/usr/share/sonic/platform/platform_env.conf` 文件（若存在）
- 读取如 `disaggregated_chassis` 等关键变量

**模块化机箱检测**：

- 检查 `/usr/share/sonic/platform/chassisdb.conf` 文件，不存在则跳过本检查
- 结合 `disaggregated_chassis` 标志判断（`disaggregated_chassis` !=1)，设置 `IS_MODULAR_CHASSIS` 标志为 1

---

### 7. 配置数据整合与生成

**配置变量构建**：

```json
{
    "HAVE_SENSORS_CONF": 1,
    "HAVE_FANCONTROL_CONF": 1,
    "API_VERSION": 3,
    "IS_MODULAR_CHASSIS": 0
}
```

**supervisord 配置生成**（`/etc/supervisor/conf.d/supervisord.conf`）：

- 存在 `pmon_daemon_control.json`
  - 使用该配置作为额外配置，结合 `sonic-cfggen` 工具生成配置: `sonic-cfggen -d -j $PMON_DAEMON_CONTROL_FILE -a "$confvar" -t $SUPERVISOR_CONF_TEMPLATE > $SUPERVISOR_CONF_FILE`
- 不存在 `pmon_daemon_control.json`:
  - `sonic-cfggen` 工具生成配置: `sonic-cfggen -d -a "$confvar" -t $SUPERVISOR_CONF_TEMPLATE > $SUPERVISOR_CONF_FILE`
- 合并 ConfigDB、守护进程控制文件和内联变量
- 基于 Jinja2 模板 `/usr/share/sonic/templates/docker-pmon.supervisord.conf.j2`生成最终配置

---

### 8. 启动 supervisord

**进程替换**：

- 使用 `exec` 替换当前 shell 进程
- 成为容器的 PID 1 进程

**服务管理**：

- 读取生成的配置文件
- 按优先级和依赖关系启动守护进程
- 监控进程状态，自动重启异常进程

---

## 三、关键文件与启动流程的关系

### 1. 关键配置驱动的启动逻辑

| 配置文件                                                                                                                        | 必须 | 影响范围     | 作用机制                                                   |
| ------------------------------------------------------------------------------------------------------------------------------- | ---- | ------------ | ---------------------------------------------------------- |
| /usr/share/sonic/hwsku/**pmon_daemon_control.json**（优先）``/usr/share/sonic/platform/**pmon_daemon_control.json** | N    | 守护进程选择 | 决定哪些服务会在 supervisord 配置中生成                    |
| /usr/share/sonic/platform/**sensors.conf**                                                                                | N    | 传感器监控   | 控制 `HAVE_SENSORS_CONF` 标志，``影响 lm-sensors 启动    |
| /usr/share/sonic/platform/**fancontrol**                                                                                  | N    | 风扇控制     | 控制 `HAVE_FANCONTROL_CONF` 标志，``影响 fancontrol 启动 |
| /usr/share/sonic/platform/**platform_env.conf**                                                                           | N    | 平台参数     | 提供 `disaggregated_chassis` 等环境变量                  |
| /usr/share/sonic/platform/**chassisdb.conf**                                                                              | N    | 机箱架构     | 结合环境变量判断是否为模块化机箱                           |
|                                                                                                                                 |      |              |                                                            |

### 2. 关键程序驱动的启动逻辑

| 程序文件                                                                  | 必须 | 影响范围     | 作用机制                                                                                                                                                |
| ------------------------------------------------------------------------- | ---- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| /usr/share/sonic/platform/**sonic_platform-1.0-py2/3-none-any.whl** | N    | API 版本     | 决定 Python 版本和 API 能力                                                                                                                             |
| /usr/share/sonic/**scripts/container_startup.py**                   | N    | 容器状态管理 | 同步容器状态到swss                                                                                                                                      |
| /usr/share/sonic/platform/**platform_wait**                         | N    | 平台初始化   | 自定义等待硬件初始化完成（如 FPGA 加载、BMC 就绪）``时间过久还没完成可执行失败以触发服务重启                                                            |
| /usr/share/sonic/platform/**psu_sensors_conf_updater**              | N    | 传感器监控   | 当存在psu_sensors_conf_updater时，``通过其提供的Function生成配置/tmp/sensors.conf，``优先级更高，``覆盖/usr/share/sonic/platform/**sensors.conf** |
|                                                                           |      |              |                                                                                                                                                         |

### 3. 动态配置生成流程

```
┌─────────────────────┐
│ 启动脚本检测状态    │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│ 构建配置变量 JSON   │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│ 读取守护进程控制文件│
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│ 渲染 Jinja2 模板    │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│ 生成 supervisord 配置│
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│ 启动 supervisord    │
└──────────┬──────────┘
           ▼
┌─────────────────────┐
│ 按配置启动守护进程   │
└─────────────────────┘
```

---

## 四、实际运行示例

### 典型服务器配置（待校验）

**pmon_daemon_control.json**：

```json
{
    "skip_ledd": false,
    "skip_xcvrd": false,
    "skip_pcied": false,
    "skip_psud": false,
    "skip_syseepromd": false,
    "skip_thermalctld": false,
    "skip_ycabled": true
}
```

**启动服务**：

- rsyslogd（基础服务）
- ledd（LED 控制）
- xcvrd（光模块监控）
- psud（电源监控）
- syseepromd（EEPROM 读取）
- thermalctld（温度控制）
- pcied（PCIe 设备监控）
- lm-sensors（如配置）
- fancontrol（如配置）

### 虚拟设备配置（待校验）

**pmon_daemon_control.json**：

```json
{
    "skip_ledd": true,
    "skip_xcvrd": true,
    "skip_pcied": true,
    "skip_psud": true,
    "skip_syseepromd": true,
    "skip_thermalctld": true,
    "skip_ycabled": false
}
```

**启动服务**：

- rsyslogd（仅基础服务）
- 其他硬件相关服务全部跳过
