# CONFIG_DB


## CHASSIS_MODULE

```
Read: docker/pmon/classisd
```

- <module_name>: 用于设置模块管理模式，该key被 SET-关闭管理状态`admin_state=0`，该key被 DEL-开启管理状态`admin_state=1`, 设置`chassis.get_module(chassis.get_module_index(module_name)).set_admin_state(admin_state)`
  - admin_status: `up` or `down`


## PORT

```
Read: docker/pmon/ledd
```

- <port_name>
  - index
  - subport
  - role


---



# STATE_DB


## CHASSIS_INFO

```
Write: docker/pmon/classis_db_init
```

- serial: `chassis().get_serial()` or `N/A`
- model: `chassis().get_model()` or `N/A`
- revision: `chassis().get_revision()` or `N/A`


## CHASSIS_MODULE_TABLE

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

```
Write: docker/pmon/classisd
```

- "CHASSIS 1"
  - module_num: `chassis.get_num_modules()`

## CHASSIS_MIDPLANE_TABLE
```
Write: docker/pmon/classisd
```
- <module_name>
  - ip_address: `get_midplane_ip()` or `0.0.0.0`
  - access: `str(is_midplane_reachable())` or `str(False)`


## PHYSICAL_ENTITY_INFO

```
Write: docker/pmon/classisd
```

- <module_name>
  - position_in_parent: <module_index>
  - parent_name: "chassis 1"
  - serial: <module_serial>
  - model: <module_model>
  - is_replaceable: <is_replaceable>


## PORT_TABLE

```
Read: docker/pmon/ledd
```

- <port_name>
  - netdev_oper_status: `up` or `down` (端口操作状态)
- PortConfigDone
- PortInitDone



---



# CHASSIS_STATE_DB


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

hostname

```
Write: docker/pmon/classisd
```

- LINE-CARD`<slot>-1` (e.g. LINE-CARD0)
  - slot: <slot>
  - hostname: `sonic_py_common.device_info.get_hostname() or "None"`
  - num_asics: `len(get_all_asics())`


## CHASSIS_MODULE_REBOOT_INFO_TABLE

```
Write: docker/pmon/classisd
```

- <module_name> (下发KV不共存，仅一次一个key)
  - reboot: `expected`
  - timestamp: `str(time.time())`



---



# CHASSIS_APP_DB






















