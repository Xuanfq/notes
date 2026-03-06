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
获取多 ASIC 平台的 Redis 目录列表, 存入`redis_dir_list`

### 8.2 设置 Redis 挂载选项
- **单实例容器(DEV=$2, 不传入该参数时)或 dpudb 类型**：
  - 网络模式：`host`
  - 挂载`redis_dir_list`中所有 Redis 实例目录
- **多 ASIC 平台**：
  - 网络模式：`container:database$DEV`
  - 只挂载命名空间特定的 Redis 目录, `redis_dir_list`中第`$DEV`个

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

| 挂载源                                          | 容器内路径                  | 权限 | 说明         |
| ----------------------------------------------- | --------------------------- | ---- | ------------ |
| `/etc/sonic`                                    | `/etc/sonic`                | ro   | SONiC 配置   |
| `/host/reboot-cause`                            | `/host/reboot-cause`        | rw   | 重启原因     |
| `/var/run/redis$DEV`                            | `/var/run/redis$DEV`            | rw   | Redis 数据库 |
| `/usr/share/sonic/device/$PLATFORM/$HWSKU/$DEV` | `/usr/share/sonic/hwsku`    | ro   | HWSKU 文件   |
| `/usr/share/sonic/firmware`                     | `/usr/share/sonic/firmware` | rw   | 固件文件     |

## 环境变量

| 变量名             | 说明                 |
| ------------------ | -------------------- |
| `NAMESPACE_ID`     | 命名空间 ID          |
| `NAMESPACE_PREFIX` | 命名空间前缀（asic） |
| `NAMESPACE_COUNT`  | 命名空间数量         |
| `DEV`              | 设备编号             |
| `CONTAINER_NAME`   | 容器名称             |
| `SYSLOG_TARGET_IP` | Syslog 目标 IP       |
| `PLATFORM`         | 平台名称             |



# 容器 start





