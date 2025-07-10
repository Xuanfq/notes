# Firmware - Network Card

Introduce the NIC(Network Card) of Intel Solution, e.g. X722/X710/X520/I210.


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

1. Download firmware package from Intel

2. Update

    2.1. Windows: `nvmupdatew64e.exe`

    2.2. Linux: `nvmupdate64e`


