# Mac Address

网卡和非易失性存储NVM连接，即外接eeprom或flash等。

## OUI

Organizationally unique identifier (组织唯一标识符)

Mac Address由12个0-f组成，共12*4bit，oui为其前6个值。可查询MAC地址厂商信息、制造商名称等。

查询方式，网络，例如：
- https://www.wireshark.org/tools/oui-lookup.html
- https://standards-oui.ieee.org/oui/oui.txt
- https://itool.co/mac



## Burn

Tool: `eeupdate64e`
- Command: `./eeupdate64e /nic=? /mac=? ...`
- NIC: `Network Interface Controller`

```bash
~# ./eeupdate64e /NIC=1 /MAC_DUMP
Connection to QV driver failed - please reinstall it!

Using: Intel (R) PRO Network Connections SDK v2.30.25
EEUPDATE v5.30.25.06
Copyright (C) 1995 - 2017 Intel Corporation
Intel (R) Confidential and not for general distribution.

Driverless Mode


NIC Bus Dev Fun Vendor-Device  Branding string
=== === === === ============= =================================================
  1   4  00  00   8086-15AB    Intel(R) Ethernet Connection X552 10 GbE Backpla
  2   4  00  01   8086-15AB    Intel(R) Ethernet Connection X552 10 GbE Backpla
  3   5  00  00   8086-15AB    Intel(R) Ethernet Connection X552 10 GbE Backpla
  4   5  00  01   8086-15AB    Intel(R) Ethernet Connection X552 10 GbE Backpla
  5  15  00  00   8086-1533    Intel(R) I210 Gigabit Network Connection

 1: LAN MAC Address is DCDA4D7263D8.
```

**Notice**: 某些存放mac的eeprom存在*WP*(Write Protect)，需要关闭WP才能修改Mac Address。

## Modify Mac Address via software

软修改Mac的方式实际上无法真正修改Mac地址，方法如下：

```bash
# shutdown nic
ifconfig eth0 down
# modify mac nic
ifconfig eth0 hw ether 00:00:00:00:00:C1
# boot nic
ifconfig eth0 up
```

**Notice**: 这种方式**重启系统后会失效**，当然可以写入开机执行，这样即可“**永久生效**”。
