# Firmware - BMC(AMI)

## Version

```bash
ipmitool mc info
# Or OEM Command
# ipmitool raw ... 
# e.g. below
# ~# ipmitool raw 0x32 0x8f 0x08 0x01
# 03 1e
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
./CFUFLASH -nw -ip 169.254.0.17 -u admin -p admin -d 1 -mse 1 bmc_online_upgrade.bin
./Yafuflash -nw -ip 169.254.0.17 -u admin -p admin -d 1 -mse 1 bmc_online_upgrade.bin

# 5. Disable BMC virtual USB
# ipmitool raw ....
```

**Notice**: Need to AC Power Cycle if codebase upgraded
