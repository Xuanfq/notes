# I210 Gigabit Network Connection

I210 是Intel 推出的**千兆**网络芯片解决方案，用来替代老产品82547；i210目前已经广泛应用在各个行业，主要以工控行业为主，应用场景需要保证稳定的网络传输效果，Intel 推出的 I210方案，包括i210AT（正常工作温度），i210IT（工业级宽温），i210IS（光纤通信），i211(i210AT 降成本方案)主要针对不同市场应用。

- 常用于网络管理口

## Firmware Version

#### Tool

`ethtool`

#### Command

`ethtool -i $nic |grep firmware-version`

#### Example
```bash

~# ethtool -i ma1
driver: igb
version: 5.6.0-k
firmware-version: 3.25, 0x800005cc
expansion-rom-version: 
bus-info: 0000:0f:00.0
supports-statistics: yes
supports-test: yes
supports-eeprom-access: yes
supports-register-dump: yes
supports-priv-flags: yes

~# ethtool ma1
Settings for ma1:
        Supported ports: [ TP ]
        Supported link modes:   10baseT/Half 10baseT/Full 
                                100baseT/Half 100baseT/Full 
                                1000baseT/Full 
        Supported pause frame use: Symmetric
        Supports auto-negotiation: Yes
        Supported FEC modes: Not reported
        Advertised link modes:  10baseT/Half 10baseT/Full 
                                100baseT/Half 100baseT/Full 
                                1000baseT/Full 
        Advertised pause frame use: No
        Advertised auto-negotiation: Yes
        Advertised FEC modes: Not reported
        Speed: 1000Mb/s
        Duplex: Full
        Port: Twisted Pair
        PHYAD: 1
        Transceiver: internal
        Auto-negotiation: on
        MDI-X: off (auto)
        Supports Wake-on: pumbg
        Wake-on: g
        Current message level: 0x00000007 (7)
                               drv probe link
        Link detected: yes
```


## Firmware Upgrade

1. 进Intel官网下载firmware更新包/降级包

2. 升级

    2.1. Windows: `nvmupdatew64e`

    2.2. Linux: `nvmupdate64e`


## Mac Address Modify

#### Tool

eeupdate64e

#### Command

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



