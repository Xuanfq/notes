# SONiC Redis Data Structure

## 存储原理

- 主要使用了`Redis`中的*哈希/散列类型*的值，相当于`Key`->`Hash Tables`(字典/关联二维数组)。

- KEY:
  - KEY1: VAL1
  - KEY2: VAL2
  - ...

- 哈希类型/散列类型中，key 对应的 value 是一个二维数组。但是字段的值*只可以是字符串*。也就是说只能是二维数组，不能有更多的维度。

- 相关操作命令:
  - 赋值: `HSET key field value`. 如 hset user name lane, hset user age 23
  - 取值: `HGET key field`. 如 hget user name，得到的是 lane. 
  - 同一个key多个字段赋值: `HMSET key field1 value1 field2 value2...`
  - 同一个KEY多个字段取值: `HMGET key field1 fields2...`
  - 获取KEY的所有字段和所有值: `HGETALL key`. 如 HGETALL user 得到的是 name lane age 23. 每个返回都是独立的一行. 
  - 字段是否存在: `HEXISTS key field`. 存在返回 1，不存在返回 0
  - 当字段不存在时赋值: `HSETNX key field value`. 如果 key 下面的字段 field 不存在，则建立 field 字段，且值为 value. 如果 field 字段存在，则不执行任何操作. 它的效果等于 HEXISTS + HSET. 但是这个命令的优点是原子操作. 再高的并发也不会怕怕. 
  - 自增 N: `HINCREBY key field increment`. 同字符串的自增类型，不再阐述. 
  - 删除字段: `DEL key field1 field2...` 删除指定KEY的一个或多个字段. 
  - 只获取字段名: `HKEYS key`. 与 HGETALL 类似，但是只获取字段名，不获取字段值. 
  - 只获取字段值: `HVALS key`. 与 HGETALL 类似，但是只获取字段值，不获取字段名. 
  - 获取字段数量: `HLEN key`. 


## SONiC

- SONiC的Redis-DB中，大量使用了Redis的*哈希/散列类型*数据结构。

- SONiC所有的键，值，字段*都是字符串*。

- SONiC所有的*键的命名*为: *表名 (大写) + | + 键名 (小写)*
  - 如下方的`STATE_DB.PSU_INFO.<psu_name>`的键为`PSU_INFO|<psu_name>`
  - 用Redis命令读取数据`FAST_RESTART_ENABLE_TABLE.system.enable`，enable为散列类型的key: `hget "FAST_RESTART_ENABLE_TABLE|system" enable`




----




# CONFIG_DB

配置数据库


## CHASSIS_MODULE

Chassis的模块管理配置表，用于设置模块管理模式等


```
Read: docker/pmon/classisd
```

- <module_name>: 用于设置模块管理模式，该key被 SET-关闭管理状态`admin_state=0`，该key被 DEL-开启管理状态`admin_state=1`, 设置`chassis.get_module(chassis.get_module_index(module_name)).set_admin_state(admin_state)`
  - admin_status: `up` or `down`


## DEVICE_METADATA

设备的元数据表配置表

```
Read: docker/pmon/pcied (sonic_py_common/device_info.py)
```

- localhost
  - hostname: 
  - platform: 
  - hwsku: 
  - yang_config_validation: `enable`


## PORT

端口配置表，记录端口与子端口的索引、角色和拓扑等

```
Read: docker/pmon/ledd
Read: docker/pmon/xcvrd
```

- <port_name>  (Ethernet*)
  - index: `"0"` (0-255)
  - subport: `"0"` (0-255) (子端口的index)
  - lanes: `41,42,43,44` (SW CHIP ASIC 的通道)
  - 
  - admin_status: `"up"` or `"down"`
  - 
  - role: `Int`/`Inb`/`Rec`/`Dpc` etc.
    ```
    - 判断是否为前面板端口：`sonic_py_common.multi_asic.is_front_panel_port(port_name, port_role)`
      - 不是：
        - Ethernet-BP*      (port_name)(Ethernet-Backplane)
        - Ethernet-IB*      (port_name)(Ethernet-Inband)
        - Ethernet-Rec*     (port_name)(Ethernet-Recirc)
        - `*.*`             (port_name)(have '.')
        - role 属于内部角色的
          - Int: INTERNAL_PORT
          - Inb: INBAND_PORT
          - Rec: RECIRC_PORT
          - Dpc: DPU_CONNECT_PORT
      - 是：
        - Ethernet*         (port_name)(don't '.')
        - ...
    ```

## STORMOND_CONFIG

配置pmon中的stormond存储设备监控程序轮训和同步间隔时间

```
Read: docker/pmon/stormond
```

- INTERVALS:
  - daemon_polling_interval: 3600 (s, 轮训间隔1hour)
  - fsstats_sync_interval: 86400 (s, 同步数据保存到JSON的时间间隔为24hour, 实际上距离上次同步后已过的时间与同步间隔的差值小于轮询间隔也会进行同步)


---



# STATE_DB

状态数据库


## CHASSIS_INFO

Chassis信息状态表，记录Chassis的序列号、型号、版本等数据

```
Write: docker/pmon/classis_db_init
Write: docker/pmon/psud
```

- <"chassis 1">
  - serial: `chassis().get_serial()` or `N/A`
  - model: `chassis().get_model()` or `N/A`
  - revision: `chassis().get_revision()` or `N/A`
  - psu_num: `chassis().get_num_psus()` or `plugins/psuutil.py/PsuUtil(PsuBase).get_num_psus()`

- <"chassis_power_budget 1">
  - Supplied Power {PSU_NAME} (`psu.get_name()` or `PSU 1/2`): `psu.get_maximum_supplied_power()` or `0.0`
  - Consumed Power {FAN_DRAWER_NAME} (`chassis.get_all_fan_drawers()[index].get_name()` or `FAN-DRAWER 0/1/..`): `fan_drawer.get_maximum_supplied_power()` or `0.0`
  - Consumed Power {MODULE_NAME} (`chassis.get_all_modules()[index].get_name()` or `MODULE 0/1/..`): `fan_drawer.get_maximum_supplied_power()` or `0.0`
  - Total Supplied Power: Supplied Power 之和
  - Total Consumed Power: Consumed Power 之和


## CHASSIS_MODULE_TABLE

Chassis的模块状态表，实时更新记录模块的详细状态

```
Write: docker/pmon/classisd
```

- <module_name>: `chassis.get_module(module_index).get_xxx()`
  - desc: `get_description()`
  - slot: `get_slot()`
  - oper_status: `get_oper_status()`
  - num_asics: `len(get_all_asics())`
  - serial: `get_serial()`
  - presence: `get_presence()`
  - is_replaceable: `is_replaceable()`
  - model: `get_model()`


## CHASSIS_TABLE

Chassis状态表，记录Chassis的模块数量等

```
Write: docker/pmon/classisd
```

- "CHASSIS 1"
  - module_num: `chassis.get_num_modules()`


## CHASSIS_MIDPLANE_TABLE

Chassis MidPlane的状态表，记录MidPlane的ip和ip reachable等状态

```
Write: docker/pmon/classisd
```

- <module_name>
  - ip_address: `get_midplane_ip()` or `0.0.0.0`
  - access: `str(is_midplane_reachable())` or `str(False)`


## PCIE_DEVICE

PCIe设备表, 记录所有设备 及其 id / 高级错误报告统计AER(Advanced Error Reporting)信息

```
Write: docker/pmon/pcied
```

- <device_name>: (`device_name = "%02x:%02x.%d" % (Bus, Dev, Fn)`)
  - id: `$(cat '/sys/bus/pci/devices/0000:$bus:$device.$fn/device')` (若下方存在则该键值不存在)

  - correctable|field1: `0`
  - fatal|field1: `0`
  - non_fatal|field1: `0`

  - correctable|RxErr: `0`


## PCIE_DEVICES

PCIe设备状态表, 记录是否有PCIe设备丢失

```
Write: docker/pmon/pcied
```

- status
  - status: `PASSED` or `FAILED`(丢失)



## PCIE_DETACH_INFO

SmartSwitch的DPU设备断联信息

```
Read: docker/pmon/pcied
```

- <dpu*> (SmartSwitch)
  - bus_info: `0000:%02x:%02x.%d' % (bus, device, func)`
  - dpu_state: `detaching` (DPU状态, 断联)


## PHYSICAL_ENTITY_INFO

Chassis的模块物理实体状态表，实时更新记录模块的物理实体详细状态

```
Write: docker/pmon/classisd
Write: docker/pmon/psud
Write: docker/pmon/sensormond
Write: docker/pmon/thermalctld
```

- <module_name>
  - position_in_parent: <module_index>
  - parent_name: "chassis 1"
  - serial: <module_serial>
  - model: <module_model>
  - is_replaceable: <is_replaceable>

- <psu_name>  (`chassis().get_psu(psu_index).get_name()`)
  - position_in_parent: `Psu(PddfPsu).get_position_in_parent()` or `psu_index`
  - parent_name: "chassis 1"

- <thermal_name>  (`chassis/psu().get_all_thermals(index).get_name()`)
  - position_in_parent: `Thermal(ThermalBase).get_position_in_parent()`(暂无该函数) or `thermal_index`
  - parent_name: "chassis 1" or "Module 1-n" or "PSU 1-n" or "Module 1-n PSU 1-n"
    - chassis 1 (Module 1-n): `chassis.get_all_thermals()`
    - PSU 1-n (Module 1-n PSU 1-n): `chassis.get_all_psus()[index].get_all_thermals()`

- <fan_drawer_name>  (`FanDrawerBase().get_name()`)
  - position_in_parent: `FanDrawer(FanDrawerBase).get_position_in_parent()` or `drawer_index`
  - parent_name: "chassis 1"

- <fan_name>  `FanBase().get_name()` or `'{parent_name:"PSU $Num"|module.get_name()/"Module $Num"|fan_drawer.get_name()/"chassis 1"} fan {index}'`
  - position_in_parent: `Fan(FanBase).get_position_in_parent()` or `index`
  - parent_name: `{parent_name}`

- <voltage_sensor_name> (`/usr/share/sonic/platform/$hwsku/sensors.yaml`中配置, 或`f'{chassis 1} voltage_sensor {index+1}'`)
  - position_in_parent: `src/sonic-platform-common/sonic_platform_base/sensor_fs.py/SensorFs.get_position_in_parent()`, 或`'Module {index}'`或`index+1`
  - parent_name: "chassis 1"


## PORT_TABLE

FrontPort 前面板端口操作状态变化表，记录端口操作状态变化等。

```
Read: docker/pmon/ledd
Read: docker/pmon/xcvrd
```

- <port_name>  (Ethernet*)
  - netdev_oper_status: `up` or `down` (端口操作状态)
  - NPU_SI_SETTINGS_SYNC_STATUS: `'NPU_SI_SETTINGS_DEFAULT'` (NPU SI 默认设置)
  - host_tx_ready: `"true"` or `"false"`
- PortConfigDone
- PortInitDone


## PSU_INFO

记录PSU在位与否、上电正常与否、功率阈值、功率budget等状态。

```
Write: docker/pmon/psud
```

- <psu_name>  (`chassis().get_psu(psu_index).get_name()`)
  - model: `Psu(PddfPsu).get_model()` or 'N/A'
  - serial: `Psu(PddfPsu).get_serial()` or 'N/A'
  - revision: `Psu(PddfPsu).get_revision()` or 'N/A'
  - temp: `Psu(PddfPsu).get_temperature()` or 'N/A'
  - temp_threshold: `Psu(PddfPsu).get_temperature_high_threshold()` or 'N/A'
  - voltage: `Psu(PddfPsu).get_voltage()` or 'N/A'
  - voltage_min_threshold: `Psu(PddfPsu).get_voltage_low_threshold()` or 'N/A'
  - voltage_max_threshold: `Psu(PddfPsu).get_voltage_high_threshold()` or 'N/A'
  - current: `Psu(PddfPsu).get_current()` or 'N/A'
  - power: `Psu(PddfPsu).get_power()` or 'N/A'
  - power_warning_suppress_threshold: `Psu(PddfPsu).get_psu_power_warning_suppress_threshold()` or 'N/A'
  - power_critical_threshold: `Psu(PddfPsu).get_psu_power_critical_threshold()` or 'N/A'
  - power_overload: `Psu(PddfPsu).get_revision()` or 'N/A'
  - is_replaceable: `Psu(PddfPsu).is_replaceable()` or `False`
  - input_current: `Psu(PddfPsu).get_input_current()` or 'N/A'
  - input_voltage: `Psu(PddfPsu).get_input_voltage()` or 'N/A'
  - max_power: `Psu(PddfPsu).get_maximum_supplied_power()` or 'N/A'
  - presence: `"true" if Psu(PddfPsu).get_presence() else "false"`
  - status: `"true" if Psu(PddfPsu).get_powergood_status() else "false"`
  - 
  - led_status: `Psu(PddfPsu).get_status_led()` or 'N/A'


## FAN_INFO

记录PSU风扇状态。

```
Write: docker/pmon/psud
Write: docker/pmon/thermalctld
```

- <psu_fan_name>  `FanBase().get_name()` or (PSU: `f"Psu(PddfPsu).get_name() FAN {index}"`) (由下方覆盖)
  - presence: `Psu(PddfPsu).get_presence()` or 'N/A'
  - status: `"True" if Psu(PddfPsu).get_presence() else "False"`
  - direction: `Psu(PddfPsu).get_all_fans()[index].get_direction()` or 'N/A'
  - speed: `Psu(PddfPsu).get_all_fans()[index].get_speed()` or 'N/A'
  - timestamp: `datetime.now().strftime('%Y%m%d %H:%M:%S')`
  - 
  - led_status: `fan.get_status_led()` or 'N/A'

- <fan_name>  `FanBase().get_name()` or `'{parent_name:"PSU $Num"|module.get_name()/"Module $Num"|fan_drawer.get_name()/"chassis 1"} fan {index}'`
  - presence: `FanBase().get_presence()`
  - drawer_name: `fan_drawer.get_name()/"chassis 1"`
  - model: `FanBase().get_model()`
  - serial: `FanBase().get_serial()`
  - status: `presence and status and not under_speed and not over_speed and not invalid_direction`
  - direction: `FanBase().get_direction()`
  - speed: `FanBase().get_speed()`
  - speed_target: `FanBase().get_target_speed()`
  - is_under_speed: `FanBase().is_under_speed()`
  - is_over_speed: `FanBase().is_over_speed()`
  - is_replaceable: `FanBase().is_replaceable()`
  - timestamp: `'%Y%m%d %H:%M:%S'`
  - 
  - led_status: `fan.get_status_led()` or 'N/A'


## FAN_DRAWER_INFO

记录风扇抽屉状态。

```
Write: docker/pmon/thermalctld
```

- <fan_drawer_name>  (`FanDrawerBase().get_name()`)
  - presence: `FanDrawerBase().get_presence()`
  - model: `FanDrawerBase().get_model()`
  - serial: `FanDrawerBase().get_serial()`
  - status: `FanDrawerBase().get_status()`
  - is_replaceable: `FanDrawerBase().is_replaceable()`
  - 
  - led_status: `fan.get_status_led()` or 'N/A'



## VOLTAGE_INFO

记录`/usr/share/sonic/platform/$hwsku/sensors.yaml`和`PDDF.Chassis().get_all_voltage_sensors()`里的电压传感器信息。

```
Write: docker/pmon/sensormond
```

- <voltage_sensor_name> (`/usr/share/sonic/platform/$hwsku/sensors.yaml`中配置, 或`f'{chassis 1} voltage_sensor {index+1}'`)
  - voltage: `VoltageSensorBase().get_value()`
  - unit: `VoltageSensorBase().get_unit()` e.g. mV
  - minimum_voltage: `VoltageSensorBase().get_minimum_recorded()`
  - maximum_voltage: `VoltageSensorBase().get_maximum_recorded()`
  - high_threshold: `VoltageSensorBase().get_high_threshold()`
  - low_threshold: `VoltageSensorBase().get_low_threshold()`
  - high_critical_threshold: `VoltageSensorBase().get_high_critical_threshold()`
  - low_critical_threshold: `VoltageSensorBase().get_low_critical_threshold()`
  - is_replaceable: `VoltageSensorBase().is_replaceable()`
  - timestamp: `VoltageSensorBase().time.strftime('%Y%m%d %H:%M:%S')`


## CURRENT_INFO

记录`/usr/share/sonic/platform/$hwsku/sensors.yaml`和`PDDF.Chassis().get_all_current_sensors()`里的电流传感器信息。

```
Write: docker/pmon/sensormond
```

- <current_sensor_name> (`/usr/share/sonic/platform/$hwsku/sensors.yaml`中配置, 或`f'{chassis 1} current_sensor {index+1}'`)
  - current: `CurrentSensorBase().get_value()`
  - unit: `CurrentSensorBase().get_unit()` e.g. mV
  - minimum_current: `CurrentSensorBase().get_minimum_recorded()`
  - maximum_current: `CurrentSensorBase().get_maximum_recorded()`
  - high_threshold: `CurrentSensorBase().get_high_threshold()`
  - low_threshold: `CurrentSensorBase().get_low_threshold()`
  - warning_status: `"True"` or `"False"`
  - critical_high_threshold: `CurrentSensorBase().get_high_critical_threshold()`
  - critical_low_threshold: `CurrentSensorBase().get_low_critical_threshold()`
  - is_replaceable: `CurrentSensorBase().is_replaceable()`
  - timestamp: `CurrentSensorBase().time.strftime('%Y%m%d %H:%M:%S')`


## STORAGE_INFO

记录系统里的存储设备状态信息。

```
Write: docker/pmon/stormond
```

- <disk_device_name> (`ls /sys/block/`, sdx,nvmex,mmcblkx)
  - device_model: `Ssd/Emmc/UsbUtil(StorageCommon).get_model()`
  - serial: `Ssd/Emmc/UsbUtil(StorageCommon).get_serial()`
  - 
  - firmware: `Ssd/Emmc/UsbUtil(StorageCommon).get_firmware()`
  - health: `Ssd/Emmc/UsbUtil(StorageCommon).get_health()`
  - temperature: `Ssd/Emmc/UsbUtil(StorageCommon).get_temperature()`
  - latest_fsio_reads: `Ssd/Emmc/UsbUtil(StorageCommon).get_fs_io_reads()`
  - latest_fsio_writes: `Ssd/Emmc/UsbUtil(StorageCommon).get_fs_io_writes()`
  - disk_io_reads: `Ssd/Emmc/UsbUtil(StorageCommon).get_disk_io_reads()`
  - disk_io_writes: `Ssd/Emmc/UsbUtil(StorageCommon).get_disk_io_writes()`
  - reserved_blocks: `Ssd/Emmc/UsbUtil(StorageCommon).get_reserved_blocks()`
  - last_sync_time: `"%Y-%m-%d %H:%M:%S"`
  - total_fsio_reads: ``  (总)
  - total_fsio_writes: ``  (总)

- FSSTATS_SYNC
  - successful_sync_time: `"%Y-%m-%d %H:%M:%S"` (最近同步数据到/usr/share/stormond/fsio-rw-stats.json的时间)


## EEPROM_INFO

记录系统EERPOM里的信息。

```
Write: docker/pmon/syseepromd
```

- TlvHeader
  - Id String: 
  - Version: 
  - Total Length: 
- 0x21
  - Name: 
  - Len: 
  - Value: 
- ... (固定字段, 0x21-0x2F)
- 0x2F
  - Name: 
  - Len: 
  - Value: 
- 0xFD  (厂商扩展字段, 通过多次使用0xFD实现多个厂商自定义字段)
  - Name_0: 
  - Len_0: 
  - Value_0: 
  - Name_1: 
  - Len_1: 
  - Value_1: 
  - ...
  - Num_vendor_ext: `number`
- Checksum
  - Valid: `1` / `0`(无效)
- State
  - Initialized: `1` (默认)


## TEMPERATURE_INFO

记录所有的PDDF-ThermalBase温度传感器的信息。

```
Write: docker/pmon/thermalctld
```

- <thermal_name>  `thermal.get_name()` or `{parent_name} Thermal {index}`, parent_name可以是:
  ```md
  - chassis 1 (Module 1-n): `chassis.get_all_thermals()`
  - PSU 1-n (Module 1-n PSU 1-n): `chassis.get_all_psus()[index].get_all_thermals()`
  - SFP 1-n (Module 1-n SFP 1-n): `chassis.get_all_sfps()[index].get_all_thermals()`
  ```
  - temperature: `thermal.get_temperature()`
  - minimum_temperature: `thermal.get_minimum_recorded()`
  - maximum_temperature: `thermal.get_maximum_recorded()`
  - high_threshold: `thermal.get_high_threshold()`
  - low_threshold: `thermal.get_low_threshold()`
  - warning_status: `"True"` or `"False"` (是否超过阈值)
  - critical_high_threshold: `thermal.get_high_critical_threshold()`
  - critical_low_threshold: `thermal.get_low_critical_threshold()`
  - is_replaceable: `thermal.is_replaceable()`
  - timestamp: `'%Y%m%d %H:%M:%S'`


## FAST_RESTART_ENABLE_TABLE

记录 FAST_BOOT 状态信息。

```
Read: docker/pmon/xcvrd
```

- system
  - enable: "true"


## TRANSCEIVER_INFO

FrontPort 前面板端口光模块信息状态等。

```
Read: docker/pmon/xcvrd
```

- <port_name>  (Ethernet*)
  - type: `QSFP28` or `QSFP+` or `..` (XCVR_TYPE)

- <{port_name}:{n} (ganged)>  (聚合端口) (e.g. Ethernet8是由两个端口聚合: "Ethernet8:1 (ganged)", "Ethernet8:2 (ganged)")


## TRANSCEIVER_FIRMWARE_INFO



## TRANSCEIVER_DOM_SENSOR



## TRANSCEIVER_DOM_FLAG



## TRANSCEIVER_DOM_FLAG_CHANGE_COUNT



## TRANSCEIVER_DOM_FLAG_SET_TIME



## TRANSCEIVER_DOM_FLAG_CLEAR_TIME



## TRANSCEIVER_DOM_THRESHOLD



## TRANSCEIVER_STATUS



## TRANSCEIVER_STATUS_FLAG



## TRANSCEIVER_STATUS_FLAG_CHANGE_COUNT



## TRANSCEIVER_STATUS_FLAG_SET_TIME



## TRANSCEIVER_STATUS_FLAG_CLEAR_TIME



## TRANSCEIVER_STATUS_SW

FrontPort 前面板端口光模块信息状态等。

```
Write: docker/pmon/xcvrd
```

- <port_name>  (Ethernet*)
  - cmis_state: `"UNKNOWN"`


## TRANSCEIVER_VDM_REAL_VALUE



## TRANSCEIVER_VDM_HALARM_THRESHOLD



## TRANSCEIVER_VDM_LALARM_THRESHOLD



## TRANSCEIVER_VDM_HWARN_THRESHOLD



## TRANSCEIVER_VDM_LWARN_THRESHOLD










---



# CHASSIS_STATE_DB

机箱状态数据库


## CHASSIS_FABRIC_ASIC_TABLE

asic_table for supervisor slot

```
Write: docker/pmon/classisd
```

- `<module_name>|asic<id>` (e.g. <module_name>|asic1)
  - asic_pci_address: `get_all_asics()[$i][1]`
  - name: `<module_name>`
  - asic_id_in_module: `get_all_asics()[$i][0]`


## CHASSIS_ASIC_TABLE

asic_table for non-supervisor slot

```
Write: docker/pmon/classisd
```

- `asic<id>` (e.g. asic1)
  - asic_pci_address: `get_all_asics()[$i][1]`
  - name: `<module_name>`
  - asic_id_in_module: `get_all_asics()[$i][0]`


## CHASSIS_MODULE_TABLE

Chassis模块表，记录Line-Card模块的slot、hostname、asics数量等

```
Write: docker/pmon/classisd
```

- LINE-CARD`<slot>-1` (e.g. LINE-CARD0)
  - slot: <slot>
  - hostname: `sonic_py_common.device_info.get_hostname() or "None"`
  - num_asics: `len(get_all_asics())`


## CHASSIS_MODULE_REBOOT_INFO_TABLE

Chassis的模块重启信息状态表，记录Chassis模块的重启操作重启时间等

```
Write: docker/pmon/classisd
```

- <module_name> (下发KV不共存，仅一次一个key)
  - reboot: `expected`
  - timestamp: `str(time.time())`


## VOLTAGE_INFO_${SLOT}

模块化Chassis(`chassis.is_modular_chassis()`)才有，同`STATE.VOLTAGE_INFO`一样。

```
Write: docker/pmon/sensormond
```

- <voltage_sensor_name> (`/usr/share/sonic/platform/$hwsku/sensors.yaml`中配置, 或`f'{chassis 1} voltage_sensor {index+1}'`)
  - ... (Ref STATE.VOLTAGE_INFO)


## CURRENT_INFO_${SLOT}

模块化Chassis(`chassis.is_modular_chassis()`)才有，同`STATE.CURRENT_INFO`一样。

```
Write: docker/pmon/sensormond
```

- <current_sensor_name> (`/usr/share/sonic/platform/$hwsku/sensors.yaml`中配置, 或`f'{chassis 1} current_sensor {index+1}'`)
  - ... (Ref STATE.CURRENT_INFO)


## TEMPERATURE_INFO_${SLOT}`

`SLOT`值为`{chassis.get_my_slot() if self.is_chassis_system else chassis.get_dpu_id()}`

需满足以下二者之一才有，数据同`STATE.TEMPERATURE_INFO`一样:
  - `chassis.is_modular_chassis()` (该类型不一定有此项数据库)
  - `chassis.is_smartswitch() and chassis.is_dpu()`

```
Write: docker/pmon/thermalctld
```

- <thermal_name>  `thermal.get_name()` or `{parent_name} Thermal {index}`
  - ...


---



# CHASSIS_APP_DB





---



# APPL_DB



## PORT_TABLE



```
Read: docker/pmon/xcvrd
```

- PortConfigDone

- PortInitDone



















