# Firmware - CPLD

A complex programmable logic device (CPLD) is a programmable logic device with complexity between that of PALs and FPGAs, and architectural features of both. The main building block of the CPLD is a macrocell, which contains logic implementing disjunctive normal form expressions and more specialized logic operations.

## Version

CPLD本身一般有存放版本的`寄存器`，通过`OS驱动/I2C`或`BMC`读取该`寄存器的值`。

## FW Upgrade With AMI BMC

Tool: `CFUFLASH` & `Yafuflash`, provided by AMI

```bash
# 1. Enable BMC virtual USB
# ipmitool raw ....

# 2. Set IP for virtual USB
ifconfig enp0sxxx 169.254.0.16 up

# 3. Get BMC IP for virtual USB

# 4. Upgrade via CFUFLASH/Yafuflash with BMC IP
./CFUFLASH -nw -ip 169.254.0.17 -u admin -p admin -d 4 cpld_online_upgrade.vme
./Yafuflash -nw -ip 169.254.0.17 -u admin -p admin -d 4 cpld_online_upgrade.vme

# 5. Disable BMC virtual USB
# ipmitool raw ....
```

**Notice**: Need to AC Power Cycle after upgrade

## FW Upgrade Without AMI BMC

Tool: `ispvm`

```bash
./ispvm cpld_online_upgrade.vme
```

**Notice**: Need to AC Power Cycle after upgrade
