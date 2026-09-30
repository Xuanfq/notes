# 50-network — 网络

| 子目录 | 内容 |
|---|---|
| `protocol/` | 协议分层笔记 L1/L2/L3/L5（含 Summary） |
| `optical/` | 光模块：类型、封装标准 |
| `hardware/` | 硬件原理：交换机高精度时间同步 |
| `software/` | SNMP 等软件组件 |
| `nos/` | 网络操作系统：sonic、onl |
| `onie/` | ONIE：启动/镜像逻辑、机型适配、Secure Boot |
| `misc/` | 交换机与路由器对比 |

## 目录内笔记

### hardware
- [交换机的高精度时间同步](hardware/交换机的高精度时间同步.md)

### misc
- [Switch & Router Comparison](misc/Switch%20&%20Router%20Comparison.md)

### nos/onl
- [Build](nos/onl/Build.md)
- [Logic of onl images](nos/onl/Logic%20of%20onl%20images.md)
- [Logic of onl startup](nos/onl/Logic%20of%20onl%20startup.md)
- [Machine Implementation](nos/onl/Machine%20Implementation.md)
- [onl](nos/onl/README.md)

### nos/sonic
- [Build](nos/sonic/Build.md)
- [Implementation](nos/sonic/Implementation.md)
- [Logic of sonic images](nos/sonic/Logic%20of%20sonic%20images.md)
- [Logic of sonic startup](nos/sonic/Logic%20of%20sonic%20startup.md)
- [Machine Implementation](nos/sonic/Machine%20Implementation.md)
- [PDDF](nos/sonic/PDDF.md)
- [sonic](nos/sonic/README.md)
- [SONiC架构分析](nos/sonic/SONiC架构分析.md)
- [SONiC子系统概述](nos/sonic/SONiC子系统概述.md)
- [Structure](nos/sonic/Structure.md)
- [开源网络操作系统SONiC](nos/sonic/开源网络操作系统SONiC.md)

### nos/sonic/Details
- [ASIC-Broadcom](nos/sonic/Details/ASIC-Broadcom.md)
- [DPU-SmartSwitch](nos/sonic/Details/DPU-SmartSwitch.md)
- [Redis-DB](nos/sonic/Details/Redis-DB.md)
- [syncd](nos/sonic/Details/syncd.md)
- [初始化引导-initramfs-tools](nos/sonic/Details/初始化引导-initramfs-tools.md)
- [启动详解-pmon](nos/sonic/Details/启动详解-pmon.md)

### nos/sonic/Reference
- [Debhelper](nos/sonic/Reference/Debhelper.md)
- [Debian软件包打包完全指南](nos/sonic/Reference/Debian软件包打包完全指南.md)
- [lm-sersors](nos/sonic/Reference/lm-sersors.md)
- [Supervisord](nos/sonic/Reference/Supervisord.md)
- [Systemd](nos/sonic/Reference/Systemd.md)
- [Y-Cable](nos/sonic/Reference/Y-Cable.md)

### onie
- [Logic of onie images](onie/Logic%20of%20onie%20images.md)
- [Logic of onie startup](onie/Logic%20of%20onie%20startup.md)
- [Machine Implementation](onie/Machine%20Implementation.md)
- [onie](onie/README.md)
- [Secure Boot](onie/Secure%20Boot.md)

### optical
- [10G Base-KR & 10G SFP+ & 10G Base-T](optical/10G%20Base-KR%20&%2010G%20SFP+%20&%2010G%20Base-T.md)
- [光模块](optical/光模块.md)
- [光模块封装标准](optical/光模块封装标准.md)
- [光模块类型](optical/光模块类型.md)

### protocol
- [L1-SyncE](protocol/L1-SyncE.md)
- [L2-AP](protocol/L2-AP.md)
- [L2-LACP](protocol/L2-LACP.md)
- [L2-LCP](protocol/L2-LCP.md)
- [L2-LLDP](protocol/L2-LLDP.md)
- [L2-NCP](protocol/L2-NCP.md)
- [L2-PPP](protocol/L2-PPP.md)
- [L2-PTP](protocol/L2-PTP.md)
- [L2-STP](protocol/L2-STP.md)
- [L2-VLAN](protocol/L2-VLAN.md)
- [L3-ARP](protocol/L3-ARP.md)
- [L3-IPv4](protocol/L3-IPv4.md)
- [L5-BGP](protocol/L5-BGP.md)
- [Summary](protocol/Summary.md)

### software
- [SNMP](software/SNMP.md)
