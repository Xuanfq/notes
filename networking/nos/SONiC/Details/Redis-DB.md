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
```

- <port_name>
  - index: `"0"` (0-255)
  - subport: `"0"` (0-255)
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

- <voltage_sensor_name> (`/usr/share/sonic/platform/$hwsku/sensors.yaml`中配置, 或`f'{chassis 1} voltage_sensor {index+1}'`)
  - position_in_parent: `src/sonic-platform-common/sonic_platform_base/sensor_fs.py/SensorFs.get_position_in_parent()`, 或`'Module {index}'`或`index+1`
  - parent_name: "chassis 1"


## PORT_TABLE

FrontPort 前面板端口操作状态变化表，记录端口操作状态变化等。

```
Read: docker/pmon/ledd
```

- <port_name>
  - netdev_oper_status: `up` or `down` (端口操作状态)
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
```

- <fan_name> (PSU: `f"Psu(PddfPsu).get_name() FAN {index}"`)
  - presence: `Psu(PddfPsu).get_presence()` or 'N/A'
  - status: `"True" if Psu(PddfPsu).get_presence() else "False"`
  - direction: `Psu(PddfPsu).get_all_fans()[index].get_direction()` or 'N/A'
  - speed: `Psu(PddfPsu).get_all_fans()[index].get_speed()` or 'N/A'
  - timestamp: `datetime.now().strftime('%Y%m%d %H:%M:%S')`
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



---



# CHASSIS_APP_DB






















