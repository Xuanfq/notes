# Firmware - BIOS

## Version

#### Command

`dmidecode -t bios | grep Version`

#### Example

```bash
~# dmidecode -t bios|grep Version
        Version: DS4101.03.01.00
```

## FW Upgrade With AMI BMC

Tool: `CFUFLASH` & `Yafuflash`, provided by AMI

```bash
# 1. Enable BMC virtual USB
# ipmitool raw ....

# 2. Set IP for virtual USB
ifconfig enp0sxxx 169.254.0.16 up

# 3. Get BMC IP for virtual USB

# 4. Upgrade via CFUFLASH/Yafuflash with BMC IP
./CFUFLASH -nw -ip 169.254.0.17 -u admin -p admin -d 2 bios_online_upgrade.bin
./Yafuflash -nw -ip 169.254.0.17 -u admin -p admin -d 2 bios_online_upgrade.bin

# 5. Disable BMC virtual USB
# ipmitool raw ....
```

**Notice**: Need to Power Cycle after upgrade

## FW Upgrade Without AMI BMC

Tool: `afulnx_64`

```bash
./afulnx_64 bios_online_upgrade.bin /p /b /n /x /k /me
```

**Notice**: Need to Power Cycle after upgrade

## FW Upgrade With UEFI

Tool: `AfuEfix64.efi`

```sh
Shell> fs1:  # switch to usb disk

Shell> AfuEfix64.efi BIOS.bin /p /b /n /me /x
```

**Notice**: Need to Power Cycle after upgrade
