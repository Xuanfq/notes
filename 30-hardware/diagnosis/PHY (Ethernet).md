# PHY (Ethernet)

## Command Tool

- Command: `ethtool`


- Command Help:

```bash
# ethtool -h
ethtool version 4.19
Usage:
        ethtool DEVNAME Display standard information about device
        ethtool -s|--change DEVNAME     Change generic options
                [ speed %d ]
                [ duplex half|full ]
                [ port tp|aui|bnc|mii|fibre ]
                [ mdix auto|on|off ]
                [ autoneg on|off ]
                [ advertise %x ]
                [ phyad %d ]
                [ xcvr internal|external ]
                [ wol p|u|m|b|a|g|s|f|d... ]
                [ sopass %x:%x:%x:%x:%x:%x ]
                [ msglvl %d | msglvl type on|off ... ]
        ethtool -a|--show-pause DEVNAME Show pause options
        ethtool -A|--pause DEVNAME      Set pause options
                [ autoneg on|off ]
                [ rx on|off ]
                [ tx on|off ]
        ethtool -c|--show-coalesce DEVNAME      Show coalesce options
        ethtool -C|--coalesce DEVNAME   Set coalesce options
                [adaptive-rx on|off]
                [adaptive-tx on|off]
                [rx-usecs N]
                [rx-frames N]
                [rx-usecs-irq N]
                [rx-frames-irq N]
                [tx-usecs N]
                [tx-frames N]
                [tx-usecs-irq N]
                [tx-frames-irq N]
                [stats-block-usecs N]
                [pkt-rate-low N]
                [rx-usecs-low N]
                [rx-frames-low N]
                [tx-usecs-low N]
                [tx-frames-low N]
                [pkt-rate-high N]
                [rx-usecs-high N]
                [rx-frames-high N]
                [tx-usecs-high N]
                [tx-frames-high N]
                [sample-interval N]
        ethtool -g|--show-ring DEVNAME  Query RX/TX ring parameters
        ethtool -G|--set-ring DEVNAME   Set RX/TX ring parameters
                [ rx N ]
                [ rx-mini N ]
                [ rx-jumbo N ]
                [ tx N ]
        ethtool -k|--show-features|--show-offload DEVNAME       Get state of protocol offload and other features
        ethtool -K|--features|--offload DEVNAME Set protocol offload and other features
                FEATURE on|off ...
        ethtool -i|--driver DEVNAME     Show driver information
        ethtool -d|--register-dump DEVNAME      Do a register dump
                [ raw on|off ]
                [ file FILENAME ]
        ethtool -e|--eeprom-dump DEVNAME        Do a EEPROM dump
                [ raw on|off ]
                [ offset N ]
                [ length N ]
        ethtool -E|--change-eeprom DEVNAME      Change bytes in device EEPROM
                [ magic N ]
                [ offset N ]
                [ length N ]
                [ value N ]
        ethtool -r|--negotiate DEVNAME  Restart N-WAY negotiation
        ethtool -p|--identify DEVNAME   Show visible port identification (e.g. blinking)
               [ TIME-IN-SECONDS ]
        ethtool -t|--test DEVNAME       Execute adapter self test
               [ online | offline | external_lb ]
        ethtool -S|--statistics DEVNAME Show adapter statistics
        ethtool --phy-statistics DEVNAME        Show phy statistics
        ethtool -n|-u|--show-nfc|--show-ntuple DEVNAME  Show Rx network flow classification options or rules
                [ rx-flow-hash tcp4|udp4|ah4|esp4|sctp4|tcp6|udp6|ah6|esp6|sctp6 [context %d] |
                  rule %d ]
        ethtool -N|-U|--config-nfc|--config-ntuple DEVNAME      Configure Rx network flow classification options or rules
                rx-flow-hash tcp4|udp4|ah4|esp4|sctp4|tcp6|udp6|ah6|esp6|sctp6 m|v|t|s|d|f|n|r... [context %d] |
                flow-type ether|ip4|tcp4|udp4|sctp4|ah4|esp4|ip6|tcp6|udp6|ah6|esp6|sctp6
                        [ src %x:%x:%x:%x:%x:%x [m %x:%x:%x:%x:%x:%x] ]
                        [ dst %x:%x:%x:%x:%x:%x [m %x:%x:%x:%x:%x:%x] ]
                        [ proto %d [m %x] ]
                        [ src-ip IP-ADDRESS [m IP-ADDRESS] ]
                        [ dst-ip IP-ADDRESS [m IP-ADDRESS] ]
                        [ tos %d [m %x] ]
                        [ tclass %d [m %x] ]
                        [ l4proto %d [m %x] ]
                        [ src-port %d [m %x] ]
                        [ dst-port %d [m %x] ]
                        [ spi %d [m %x] ]
                        [ vlan-etype %x [m %x] ]
                        [ vlan %x [m %x] ]
                        [ user-def %x [m %x] ]
                        [ dst-mac %x:%x:%x:%x:%x:%x [m %x:%x:%x:%x:%x:%x] ]
                        [ action %d ] | [ vf %d queue %d ]
                        [ context %d ]
                        [ loc %d]] |
                delete %d
        ethtool -T|--show-time-stamping DEVNAME Show time stamping capabilities
        ethtool -x|--show-rxfh-indir|--show-rxfh DEVNAME        Show Rx flow hash indirection table and/or RSS hash key
                [ context %d ]
        ethtool -X|--set-rxfh-indir|--rxfh DEVNAME      Set Rx flow hash indirection table and/or RSS hash key
                [ context %d|new ]
                [ equal N | weight W0 W1 ... | default ]
                [ hkey %x:%x:%x:%x:%x:.... ]
                [ hfunc FUNC ]
                [ delete ]
        ethtool -f|--flash DEVNAME      Flash firmware image from the specified file to a region on the device
               FILENAME [ REGION-NUMBER-TO-FLASH ]
        ethtool -P|--show-permaddr DEVNAME      Show permanent hardware address
        ethtool -w|--get-dump DEVNAME   Get dump flag, data
                [ data FILENAME ]
        ethtool -W|--set-dump DEVNAME   Set dump flag of the device
                N
        ethtool -l|--show-channels DEVNAME      Query Channels
        ethtool -L|--set-channels DEVNAME       Set Channels
               [ rx N ]
               [ tx N ]
               [ other N ]
               [ combined N ]
        ethtool --show-priv-flags DEVNAME       Query private flags
        ethtool --set-priv-flags DEVNAME        Set private flags
                FLAG on|off ...
        ethtool -m|--dump-module-eeprom|--module-info DEVNAME   Query/Decode Module EEPROM information and optical diagnostics if available
                [ raw on|off ]
                [ hex on|off ]
                [ offset N ]
                [ length N ]
        ethtool --show-eee DEVNAME      Show EEE settings
        ethtool --set-eee DEVNAME       Set EEE settings
                [ eee on|off ]
                [ advertise %x ]
                [ tx-lpi on|off ]
                [ tx-timer %d ]
        ethtool --set-phy-tunable DEVNAME       Set PHY tunable
                [ downshift on|off [count N] ]
        ethtool --get-phy-tunable DEVNAME       Get PHY tunable
                [ downshift ]
        ethtool --reset DEVNAME Reset components
                [ flags %x ]
                [ mgmt ]
                [ mgmt-shared ]
                [ irq ]
                [ irq-shared ]
                [ dma ]
                [ dma-shared ]
                [ filter ]
                [ filter-shared ]
                [ offload ]
                [ offload-shared ]
                [ mac ]
                [ mac-shared ]
                [ phy ]
                [ phy-shared ]
                [ ram ]
                [ ram-shared ]
                [ ap ]
                [ ap-shared ]
                [ dedicated ]
                [ all ]
        ethtool --show-fec DEVNAME      Show FEC settings
        ethtool --set-fec DEVNAME       Set FEC settings
                [ encoding auto|off|rs|baser [...]]
        ethtool -h|--help               Show this help
        ethtool --version               Show version number
# ethtool ma1
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
        Speed: 1000Mb/s                         # <--- speed
        Duplex: Full                            # <--- duplex: Half, Full
        Port: Twisted Pair                      # <--- connector port type(physical attribute): 0-TP,1-AUI,2-MII,3-FIBRE,4-BNC
        PHYAD: 1                                # <--- phy address
        Transceiver: internal                   # <--- transceiver, 0-INTERNAL,1-EXTERNAL,2-DUMMY1,3-DUMMY2,4-DUMMY3
        Auto-negotiation: on
        MDI-X: on (auto)
        Supports Wake-on: pumbg
        Wake-on: g
        Current message level: 0x00000007 (7)
                               drv probe link
        Link detected: yes
```


## Diagnosis

### Preparation

#### Dump Register

- Command: `ethtool -d NicDevName`


#### Dump EEPROM

- Command: `ethtool -e NicDevName`


#### Check MAC

- `cat /sys/class/net/$NicDevName/address`, "dc:xx:xx:72:xx:xx"
- By C lang: 
  ```
  #include <linux/if_ether.h>
  #include <linux/if.h>
  struct ifreq ifr;
  memset(&ifr, 0, sizeof(ifr));
  strcpy(ifr.ifr_name, devname);
  int32_t fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_IP);
  ifr.ifr_addr.sa_family = AF_INET; 
  strncp(ifr.ifr_name, devname, IFNAMSIZ - 1);
  if (0 == ioctl(fd, SIOCGIFHWADDR, &ifr)) {
      mac = (uint8_t *)ifr.ifr_hwaddr.sa_data;
  }
  ```

#### Check Duplex

- `cat /sys/class/net/$NicDevName/duplex`, "full"/"half"
- `ethtool $NicDevName`, "Duplex: Full"/"Duplex: Half"
- By C lang: 
  ```
  if (0 == ioctl(fd, SIOCETHTOOL, &ifr)) {
  }
  ```

#### Check Speed


- `cat /sys/class/net/$NicDevName/speed`, "1000"/"100"
- `ethtool $NicDevName`, "Speed: 1000Mb/s"/"Speed: 100Mb/s"
- By C lang: 
  ```
  if (0 == ioctl(fd, SIOCETHTOOL, &ifr)) {
  }
  ```


#### Check Port Type Attribute

TP（Twisted Pair）：双绞线（如 RJ-45 接口的以太网电缆）。
FIBRE：光纤接口（如 SFP、SFP+、QSFP + 等光模块）。
AUI（Attachment Unit Interface）：早期以太网粗同轴电缆接口。
BNC：细同轴电缆接口（如 10Base2 网络）。
MII（Media Independent Interface）：媒体无关接口。
None：无特定物理端口（如虚拟网卡）。

- `ethtool $NicDevName`, "Port: Twisted Pair"
- By C lang: 0-TP,1-AUI,2-MII,3-FIBRE,4-BNC
  ```
  if (0 == ioctl(fd, SIOCETHTOOL, &ifr)) {
  }
  ```


#### Check Transceiver 

用于描述网卡如何与网络介质（如网线、光纤）连接，以及收发器的类型和状态。它直接关联到物理层的信号转换和传输方式。

internal：内置收发器（如网卡自带 RJ-45 接口）。
external：外置收发器（如 SFP/SFP+/QSFP + 光模块）。
None：无收发器（如虚拟网卡或未连接设备）


- `ethtool $NicDevName`, "Transceiver: internal"
- By C lang: 0-INTERNAL,1-EXTERNAL,2-DUMMY1,3-DUMMY2,4-DUMMY3
  ```
  if (0 == ioctl(fd, SIOCETHTOOL, &ifr)) {
  }
  ```


#### Check PHY Address

PHY（Physical Layer Device）：是网卡中负责电信号 / 光信号转换的硬件组件，实现 OSI 模型的物理层功能。MAC -> PHY

在 ethtool 的输出中，PHYAD（PHY Address）是一个重要参数，用于标识网卡上的物理层设备（PHY）地址。理解 PHYAD 有助于网络故障排查和底层配置管理。

常见场景：
- 以太网网卡中的 PHY 芯片处理 RJ-45 接口的电信号（如 1000BASE-T）。
- 光模块（如 SFP）内部包含 PHY，负责光纤信号转换。

PHYAD的作用：
- 地址标识：在一个网卡或交换机中，可能存在多个 PHY 设备（如多端口交换机），每个 PHY 需要唯一的地址以便被控制器访问。
- 访问方式：控制器通过 MDIO（Management Data Input/Output）总线与 PHY 通信，使用 PHYAD 作为寻址依据。

PHYAD 的取值范围
- 标准范围：0-31（MDIO 总线使用 5 位地址，支持 32 个设备）。
- 常见值：
  - 单 PHY 网卡：通常为 0 或 1。
  - 多 PHY 设备（如交换机）：每个端口对应一个唯一的 PHYAD（0-31）。交换机芯片如博通在OS下的虚拟网卡也可能不会不会报告这些信息，Port Type也拿不到。

- `ethtool $NicDevName`, "PHYAD: 1"
- By C lang: 0-INTERNAL,1-EXTERNAL,2-DUMMY1,3-DUMMY2,4-DUMMY3
  ```
  if (0 == ioctl(fd, SIOCETHTOOL, &ifr)) {
  }
  ```


#### Check status

- `cat /sys/class/net/$NicDevName/operstate`, "up"/"down"



### Diagnosis

Reference Above

