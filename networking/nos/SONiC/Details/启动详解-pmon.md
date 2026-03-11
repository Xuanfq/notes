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

| 程序                                                                    | 功能                                | 关键配置                 | 条件启动                                                            |
| ----------------------------------------------------------------------- | ----------------------------------- | ------------------------ | ------------------------------------------------------------------- |
| **/usr/sbin/rsyslogd**                                            | 日志管理                            | `priority=1`           | 无条件                                                              |
| **/usr/bin/delay.py**                                             | 非紧急延时                          |                          | delay_non_critical_daemon                                           |
| **/usr/local/bin/chassisd**                                       | 模块化机箱管理                      |                          | not skip_chassisd &&<br />IS_MODULAR_CHASSIS == 1 or is_smartswitch |
| **/usr/local/bin/chassis_db_init**                                |                                     |                          | not skip_chassis_db_init                                            |
| **/usr/bin/lm-sensors.sh**``(sensors -s && service sensord start) | 应用传感器配置并启动sensord.service | 基于 `sensors.conf`    | not skip_sensors &&`HAVE_SENSORS_CONF == 1`                       |
| **/usr/sbin/fancontrol**                                          | 风扇控制                            | 基于 `fancontrol` 配置 | not skip_fancontrol &&`HAVE_FANCONTROL_CONF == 1`                 |
| **/usr/local/bin/ledd**                                           | LED 控制                            | 支持 Python 2/3          | not skip_ledd                                                       |
| **/usr/local/bin/xcvrd**                                          | 光模块监控                          | 支持多种选项             | not skip_xcvrd                                                      |
| **/usr/local/bin/ycabled**                                        | 双 ToR 配置                         | 仅 DualToR 设备          | 仅 DualToR 设备                                                     |
| **/usr/local/bin/psud**                                           | 电源监控                            | 支持 Python 2/3          | not skip_psud                                                       |
| **/usr/local/bin/syseepromd**                                     | EEPROM 读取                         | 支持 Python 2/3          | not skip_syseepromd                                                 |
| **/usr/local/bin/thermalctld**                                    | 温度控制                            | 支持 Python 2/3          | not skip_thermalctld                                                |
| **/usr/local/bin/pcied**                                          | PCIe 设备监控                       | 固定路径                 | not skip_pcied                                                      |
| **/usr/local/bin/sensormond**                                     |                                     | 固定路径                 | include_sensormond                                                  |
| **/usr/local/bin/stormond**                                       |                                     | 固定路径                 | not skip_stormond                                                   |

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

- 若存在 `/usr/share/sonic/scripts/container_startup.py` 脚本，则执行（除stretch外都有，位于docker内部）: `/usr/share/sonic/scripts/container_startup.py -f pmon -o ${RUNTIME_OWNER} -v ${IMAGE_VERSION}` （可参阅 `src/sonic-ctrmgrd/ctrmgr/container_startup.py`）
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
- 复制最终配置到 `/etc/sensors.d/`，用于 lm-sersors 中的 sensord 守护进程

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



---



# src/sonic-platform-daemons

[sonic-platform-daemons](https://github.com/sonic-net/sonic-platform-daemons)，是基于 `python`开发的系列平台监控守护程序，多个 `whl`，如 `sonic_chassisd-1.0-py3-none-any.whl`, `sonic_ledd-1.1-py2-none-any.whl`等

## sonic-chassisd/classis_db_init

- 初始化 `STATE_DB`中Chassis硬件信息

```python
# DB.Table
STATE_DB.CHASSIS_INFO=dict([
	(serial , sonic_platform.platform.Platform().get_chassis().get_serial() or N/A),
	(model , sonic_platform.platform.Platform().get_chassis().get_model() or N/A),
	(revision , sonic_platform.platform.Platform().get_chassis().get_revision() or N/A),
])
```

- STATE_DB
  - CHASSIS_INFO
    - serial: `chassis().get_serial()` or `N/A`
    - model: `chassis().get_model()` or `N/A`
    - revision: `chassis().get_revision()` or `N/A`

> SYSLOG_IDENTIFIER = "chassis_db_init"


## sonic-chassisd/classisd

**核心功能**: 模块信息更新守护进程，负责收集和管理 SONiC 模块化机架系统中的所有模块信息，并将信息写入 State DB。

**运行周期**: 每 10 秒（`CHASSIS_INFO_UPDATE_PERIOD_SECS`）更新一次

**支持模式**:

1. **模块化机架模式**: Supervisor + Line Cards + Fabric Cards
2. **智能交换机模式**: Supervisor + DPUs（Data Processing Units）

**chassisd** 是 SONiC 模块化机架和智能交换机的核心管理守护进程，实现了：

1. **模块生命周期管理**: 监控模块在线/离线状态
2. **配置管理**: 响应配置变化，执行模块管理操作
3. **状态同步**: 定期更新数据库中的模块信息
4. **中平面监控**: 检查模块间连接状态
5. **DPU 状态管理**: 监控 DPU 数据平面和控制平面状态
6. **错误恢复**: 自动清理离线模块记录
7. **平台适配**: 支持多种平台架构

---

### 平台适配

#### 模块化机架平台

**组件**:

- Supervisor 卡（管理整个机架）
- Line Cards（业务处理）
- Fabric Cards（交换网络）

**特殊处理**:

- Supervisor 和 Line Card 运行不同的逻辑
- Fabric ASIC 信息单独管理
- 中平面连接监控

#### 智能交换机平台

**组件**:

- Supervisor 卡
- DPUs（数据处理单元）

**特殊处理**:

- DPU 数据平面和控制平面状态监控
- PCI 设备分离/重新扫描
- 传感器配置变更
- 异步模块配置更新

---

### 核心数据定义

#### 1. Redis 数据库结构

| 数据库           | 表名                             | 键模板          | 用途                     |
| ---------------- | -------------------------------- | --------------- | ------------------------ |
| CONFIG_DB        | CHASSIS_MODULE                   | `<module_name>` | 模块配置（admin_status） |
| STATE_DB         | CHASSIS_TABLE                    | `CHASSIS 1`     | 机架信息（模块数量）     |
| STATE_DB         | CHASSIS_MODULE_TABLE             | `<module_name>` | 模块状态信息             |
| STATE_DB         | CHASSIS_MIDPLANE_TABLE           | `<module_name>` | 中平面连接信息           |
| STATE_DB         | PHYSICAL_ENTITY_INFO             | `<module_name>` | 物理实体信息             |
| CHASSIS_STATE_DB | CHASSIS_ASIC_TABLE               | `<asic_key>`    | ASIC 信息                |
| CHASSIS_STATE_DB | CHASSIS_FABRIC_ASIC_TABLE        | `<asic_key>`    | Fabric ASIC 信息         |
| CHASSIS_STATE_DB | CHASSIS_MODULE_TABLE             | `<module_name>` | 模块主机名               |
| CHASSIS_STATE_DB | CHASSIS_MODULE_REBOOT_INFO_TABLE | `<module_name>` | 模块重启信息             |
| CHASSIS_STATE_DB | DPU_STATE                        | `DPU<id>`       | DPU 状态                 |

- CONFIG_DB
  - CHASSIS_MODULE
    - <module_name>: 用于设置模块管理模式，该key被 SET-关闭管理状态`admin_state=0`，该key被 DEL-开启管理状态`admin_state=1`, 设置`chassis.get_module(chassis.get_module_index(module_name)).set_admin_state(admin_state)`
      - admin_status: up|down
- STATE_DB
  - CHASSIS_MODULE_TABLE
    - <module_name>: `chassis.get_module(module_index).get_xxx()`
      - desc: `get_description()`
      - slot: `get_slot()`
      - oper_status: `get_oper_status()`
      - num_asics: `len(get_all_asics())`
      - serial: `get_serial()`
      - presence: `get_presence()`
      - is_replaceable: `is_replaceable()`
      - model: `get_model()`
  - CHASSIS_TABLE
    - "CHASSIS 1"
      - module_num: `chassis.get_num_modules()`
  - CHASSIS_MIDPLANE_TABLE
    - <module_name>
      - ip_address: `get_midplane_ip()` or `0.0.0.0`
      - access: `str(is_midplane_reachable())` or `str(False)`
  - PHYSICAL_ENTITY_INFO
    - <module_name>
      - position_in_parent: <module_index>
      - parent_name: "chassis 1"
      - serial: <module_serial>
      - model: <module_model>
      - is_replaceable: <is_replaceable>
- CHASSIS_STATE_DB
  - CHASSIS_FABRIC_ASIC_TABLE (asic_table for supervisor slot)
    - `<module_name>|asic<id>` (e.g. <module_name>|asic1)
      - asic_pci_address: `get_all_asics()[$i][1]`
      - name: `<module_name>`
      - asic_id_in_module: `get_all_asics()[$i][0]`
  - CHASSIS_ASIC_TABLE (asic_table for non-supervisor slot)
    - `asic<id>` (e.g. asic1)
      - asic_pci_address: `get_all_asics()[$i][1]`
      - name: `<module_name>`
      - asic_id_in_module: `get_all_asics()[$i][0]`
  - CHASSIS_MODULE_TABLE (hostname)
    - LINE-CARD`<slot>-1` (e.g. LINE-CARD0)
      - slot: <slot>
      - hostname: `sonic_py_common.device_info.get_hostname() or "None"`
      - num_asics: `len(get_all_asics())`
  - CHASSIS_MODULE_REBOOT_INFO_TABLE
    - <module_name> (下发KV不共存，仅一次一个key)
      - reboot: `expected`
      - timestamp: `str(time.time())`
- CHASSIS_APP_DB

#### 2. Chassis 模块类型

Chassis 模块继承自 `src/sonic-platform-common/sonic_platform_base/module_base.py`中的`ModuleBase(device_base.DeviceBase)`类，是**通用类型的平台外设设备**的**抽象基类**。

| 模块类型    | 前缀          | 说明                       |
| ----------- | ------------- | -------------------------- |
| Supervisor  | `SUPERVISOR`  | 管理卡                     |
| Line Card   | `LINE-CARD`   | 线卡                       |
| Fabric Card | `FABRIC-CARD` | 交换卡                     |
| DPU         | `DPU`         | 数据处理单元（智能交换机） |

#### 3. Chassis 模块状态

| 状态                  | 值        | 引用                       | 说明                               |
| --------------------- | --------- | -------------------------- | ---------------------------------- |
| MODULE_STATUS_EMPTY   | `Empty`   | `module.get_oper_status()` | 模块不存在                         |
| MODULE_STATUS_OFFLINE | `Offline` | `module.get_oper_status()` | 模块离线                           |
| MODULE_STATUS_ONLINE  | `Online`  | `module.get_oper_status()` | 模块在线，fully functional         |
| MODULE_STATUS_PRESENT | `Present` | `module.get_oper_status()` | not fully functional               |
| MODULE_STATUS_FAULT   | `Fault`   | `module.get_oper_status()` | Present\|Online->fault，无法Online |
|                       |           |                            |                                    |
| MODULE_ADMIN_DOWN     | `0`       | module.set_admin_state(0)  | 管理状态关闭                       |
| MODULE_ADMIN_UP       | `1`       | module.set_admin_state(1)  | 管理状态开启                       |
| MODULE_PRE_SHUTDOWN   | `2`       | module.set_admin_state(2)  | DPU预关机状态                      |

---

### 核心总体流程

根据Chassis类型启动对应Daemon (此处主要梳理非PDU&SmartSwitch的Chassis):

- 若是DPU Chassis (`chassis.is_smartswitch() and chassis.is_dpu()`): `DpuChassisdDaemon(SYSLOG_IDENTIFIER, chassis).run()`
- 否则按平台Chassis: `ChassisdDaemon(SYSLOG_IDENTIFIER, chassis).run()`


如下为非PDU Chassis:

1. 设置-模块配置更新器`ModuleUpdater`

   - smartswitch: `SmartSwitchModuleUpdater(SYSLOG_IDENTIFIER, self.platform_chassis)`
   - 非smartswitch: `ModuleUpdater(SYSLOG_IDENTIFIER, self.platform_chassis, chassis.get_my_slot() or -1, chassis.get_supervisor_slot() or -1)`
     1. 连接数据库及相应表格 (仅展示差异): 
        - `STATE_DB`
        - `CHASSIS_STATE_DB`
          - asic_table: 
            - supervisor slot: `CHASSIS_FABRIC_ASIC_TABLE`
            - common slot: `CHASSIS_ASIC_TABLE`
     2. 设置`linecard_reboot_timeout`为180s。可通过平台环境变量`platform_env.conf`覆盖。
     3. 初始化midplane (成功需返回"True", 使if条件判断通过): `chassis.init_midplane_switch()`

2. 更新数据库`STATE_DB.CHASSIS_TABLE`中的**模块数量** (或DPU数量) (非0值): `"CHASSIS 1"=dict([("module_num", chassis.get_num_modules())])`

3. 非smartswitch: 若获取到`slot`或`supervisor_slot`是非法值`-1`，退出

4. 设置并启动-配置管理任务`ConfigManagerTask`

   - smartswitch: `SmartSwitchConfigManagerTask().task_run()`

   - 非smartswitch，需当前`slot`是`supervisor_slot`: `ConfigManagerTask().task_run()`

     - 监听`CONFIG_DB.CHASSIS_MODULE`中的配置项修改：

       - 配置项名称-`key`：
         - `SUPERVISOR**`, 如`SUPERVISOR-xxx`
         - `LINE-CARD**`
         - `FABRIC-CARD**`

       - 修改动作:
         - SET: 关闭模块管理 (`admin_state=0`)
         - DEL: 开启模块管理 (`admin_state=1`)

     - 根据配置项的修改动作，设置Chassis-Module的管理状态:

       - ```python
         chassis.get_module(chassis.get_module_index(key)).set_admin_state(admin_state)
         ```

   - 其他：无此任务

5. smartswitch: 初始化DPU管理状态

6. 循环执行: (每CHASSIS_INFO_UPDATE_PERIOD_SECS=10s执行一次)

   1. 模块状态检测与更新: `module_updater.module_db_update()`
      1. 遍历所有模块
         1. 获取最新的模块信息字典: `chassis.get_module(module_index).get_xxx()` 
         2. 若`slot`与本模块更新器`module_updater`中设置的一致，记下其模块索引: `my_index = module_index`
         3. 检查最新的模块信息中模块名`name`是否合法，不合法则**跳过**剩下步骤 (合法如`SUPERVISOR**`, `LINE-CARD**`, `FABRIC-CARD**`)
         4. 获取数据库中模块信息中的上一次`oper_status`状态 (name是模块名, 默认为空`empty`): `STATE.CHASSIS_MODULE_TABLE.module_name` 
         5. 更新数据库中模块信息: `STATE_DB.CHASSIS_MODULE_TABLE.module_name`
         6. 更新数据库中物理条目信息: `STATE_DB.PHYSICAL_ENTITY_INFO.module_name`
         7. 获取数据库中该模块的hostname, 定义变量down_module_key为`<module_name>|<hostname>`: `CHASSIS_STATE_DB.CHASSIS_MODULE_TABLE.module_name` 
         8. 对比上一次与最新的`oper_status`状态：
            1. 从Online变成非Online，输出Offline日志，并记录到`down_modules["<module_name>|<hostname>"]`: 
               - `down_time=time.time()`
               - `cleaned=False`
               - `slot=`最新slot
            2. 从非Online变成Online，输出Online日志
            3. 最新为Online，并且模块从down_modules中移除，输出恢复Online日志
            4. 若为Online，且数据库中配置模块管理状态`CONFIG_DB.CHASSIS_MODULE.<module_name>.admin_status`为非`down`，遍历模块中所有的`asics`更新数据库中`CHASSIS_STATE_DB.$ASIC_TABLE`对应的状态
      2. 若非Supervisor，获取循环中记下的与本模块更新器一致的模块索引`my_index`，获取其模块信息用以 - 更新数据库中hostname部分: `CHASSIS_STATE_DB.CHASSIS_MODULE_TABLE.LINE-CARD<slot-1>`
      3. 清除数据库中非Online模块的ASIC记录: `CHASSIS_STATE_DB.$ASIC_TABLE`
   2. 模块midplane状态检测与更新: `module_updater.check_midplane_reachability()`
      1. 若midplane没有初始化，则**跳过**剩下步骤
      2. 遍历所有模块进行检查
         1. 跳过这些模块:
            1. **非FABRIC-CARD**
            2. **Supervisor**: 若Chassis所在的slot是**Supervisor** - slot，且是正在遍历中的模块的slot
            3. **LINE-CARD**: 若遍历中的 **LINE-CARD**模块的slot不是Supervisor
         2. 获取最新的模块midplane信息和状态: name，midplane_ip，midplane_reachable
         3. 获取数据库中上一次记录的模块midplane信息和状态: midplane_reachable
         4. 对比上一次与最新的模块midplane信息和状态：
            1. 若从reachable变成非reachable：
               - 若为预期的，即预期reboot导致(`CHASSIS_STATE_DB.CHASSIS_MODULE_REBOOT_INFO_TABLE.<module_name>.reboot=expected`)，则更新reboot信息数据库中模块midplane重启时间(`CHASSIS_STATE_DB.CHASSIS_MODULE_REBOOT_INFO_TABLE.<module_name>.timestamp=str(time.time())`)，并输出日志
               - 若为非预期的，输出日志
            2. 若从非reachable变成reachable，则输出日志，并删除reboot信息数据库中的对应模块`CHASSIS_STATE_DB.CHASSIS_MODULE_REBOOT_INFO_TABLE.<module_name>`
            3. 若一致都是非reachable，检查reboot是否超时(`linecard_reboot_timeout`)，若超时则删除reboot数据库中对应模块，并输出日志
         5. 更新数据库中模块midplane信息和状态: `STATE_DB.CHASSIS_MIDPLANE_TABLE.<module_name>={"ip_address":"0.0.0.0","access": "False"}`
   3. 检查所有Offline模块Offline是否超时(30min)，超时则清除数据库（仅LINE-CARD）并标记清除: `module_updater.module_down_chassis_db_cleanup()`
      - CHASSIS_APP_DB:
        - SYSTEM_NEIGH*
        - SYSTEM_INTERFACE*
        - SYSTEM_LAG_MEMBER_TABLE*
        - SYSTEM_LAG_TABLE*





> SYSLOG_IDENTIFIER = "chassisd"


## sonic-ledd

### 核心总体流程

#### 初始化守护进程基类

```python
daemon_base.DaemonBase.__init__(self, SYSLOG_IDENTIFIER)
```

#### 多 ASIC 平台配置

- 若为多 ASIC 平台配置，让swsscommon先从`database_global.json`加载详细命名空间配置

  ```python
  if sonic_py_common.multi_asic.is_multi_asic():
      swsscommon.SonicDBConfig.initializeGlobalConfig()
  ```

- src/sonic-swss-common/tests/redis_multi_db_ut_config/database_global.json

#### 加载平台特定 LED 控制模块

- 尝试加载平台特定的 `led_control` 模块中的 `class LedControl()` 类，位于**`/usr/share/sonic/platform/plugins/led_control.py`**
- 如果加载失败，记录错误并退出（错误码：LEDUTIL_LOAD_ERROR=1）

```python
self.led_control = self.load_platform_util(LED_MODULE_NAME, LED_CLASS_NAME)
```

#### 初始化端口状态观察器

```python
self.portObserver = PortStateObserver()
```

#### 订阅前面板端口命名空间

- 获取所有前端命名空间: `namespaces = sonic_py_common.multi_asic.get_front_end_namespaces()`
  - 详细命名空间原理
    - 相关配置：`src/sonic-swss-common/tests/redis_multi_db_ut_config/database_global.json`
    - 实际原理：
      - 物理隔离：每个命名空间有独立的Redis实例（通过不同的unix socket路径）
      - 逻辑隔离：相同的数据库名称（如APPL_DB）在不同命名空间中指向不同的物理Redis实例
      - 灵活配置：支持namespace和container_name的组合，实现更细粒度的隔离
      - 代码流程：
        1. 用户调用 db_connect("APPL_DB", "asic0")
        2. 创建 DBConnector("APPL_DB", 0, True, "asic0")
        3. 创建 SonicDBKey(netns="asic0")
        4. 从 m_db_info[{netns="asic0"}] 中查找 "APPL_DB" 的配置
        5. 获取 dbId=1, instName="redis"
        6. 从 m_inst_info[{netns="asic0"}] 中查找 "redis" 实例
        7. 获取 unix_socket_path="/var/run/redis0/redis.sock"
        8. 连接到该socket的Redis实例
- 订阅这些命名空间的 `STATE_DB.PORT` 表: `self.portObserver.subscribePortTable(namespaces)`
- 即向RedisDB提交多个订阅: `STATE_DB.PORT_TABLE.<namespace>`

#### 发现前面板端口

```python
fp_plist, fp_ups, lmap = self.findFrontPanelPorts(namespaces)
self.fp_ports = FrontPanelPorts(fp_plist, fp_ups, lmap, self.led_control)
```

- 调用 `findFrontPanelPorts()` 发现前面板端口及其状态 (最多256个Port)
  - 数据库
    - `CONFIG_DB.PORT.`
    - `STATE_DB.PORT_TABLE.`
  - 判断是否为前面板端口：`sonic_py_common.multi_asic.is_front_panel_port(port_name, port_role)`
- 创建 `FrontPanelPorts` 对象管理这些端口
  - fp_port_list (前面板端口索引及其端口归属列表：`{port-index, list of logical ports' name}`)
  - fp_port_up_subports (端口的子端口状态：`{port-index, total number of subports oper UP (netdev_oper_status is up)}`)
  - logical_port_mapping (逻辑端口映射：`{port-name, Port Object}`)

#### 初始化端口 LED 颜色

根据当前端口状态初始化所有端口 LED：

- **若该端口的所有子端口(的netdev_oper_status)都是up，则端口up，否则down**
  - **控制端口状态更新`led_control.port_link_state_change(port_name, ‘up')`**

```python
self.fp_ports.initPortLeds()
```



> SYSLOG_IDENTIFIER = "ledd"


## sonic-pcied

## sonic-psud

## sonic-sensormond

## sonic-stormond

## sonic-syseepromd

## sonic-thermalctld

## sonic-xcvrd

## sonic-ycabled

---

# src/lm-sensors (fancontrol)

`lm_sensors` (Linux monitoring sensors) 是一款免费开源应用程序，提供用于监控温度、电压和控制风扇的工具和驱动程序。包含 `fancontrol`。

[参阅-lm-sersors.md](../Reference/lm-sersors.md)

## lm-sensors

## sensors

## sensord

## fancontrol

---

# dockers/docker-platform-monitor

[参阅-lm-sersors.md](../Reference/lm-sersors.md)

## lm-sensors.sh

1. 应用配置:
   - 存在配置: `sensors -s -c /etc/sensors.d/sensors.conf`
   - 不存在配置: `sensors -s`
2. 启动后台监控并输出日志: `service sensord start`

> 日志配置位于 `dockers/docker-platform-monitor/etc/rsyslog.conf`
