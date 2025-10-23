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


## FW Upgrade With socflash

Tool: `socflash_x64`, socflash_x64 is provided by Aspeed, it's used to upgrade the BMC FW. Since there is a code base upgrade for BMC, AMI yafuflash doesn't work anymore, we have to use the socflash.

Usage: `./socflash_x64 -s if=bmc.ima option=l lpcport=0x2e cs=0`

1. bmc.ima is BMC file.
2. "option=l"(lowercase of "L")is used to select LPC bus.
3. "lpcport=0x2e"is used to pointed out the super I/O address. Usually will not changed.
4. "cs=0" is defalut for primary BMC flash,"cs=1"is used for upgrade backup BMC flash.

```bash
root@localhost:~# ./socflash_x64 -s if=xxx.ima option=l lpcport=0x2e cs=0
ASPEED SOC Flash Utility v.1.22.10
Warning:
SoCflash utility is only for engineers to update the firmware in lab,
it is not a commercialized software product,
ASPEED has not done compatibility/reliability stress test for SoCflash.
Please do not use this utility for any mass production purpose.
Press y to continue if you are agree ....
y
Static Memory Controller Information:
CS0 Flash Type is SPI
CS1 Flash Type is SPI
CS2 Flash Type is SPI
CS3 Flash Type is NOR
CS4 Flash Type is NOR
Boot CS is 0
Option Information:
CS: 0
Flash Type: SPI
[Warning] Don't AC OFF or Reboot System During BMC Firmware Update!!
[SOCFLASH] Flash ID : 1940ef
Find Flash Chip #1: WinbondW25Q256/257
Update Flash Chip #1 O.K.
Update Flash Chip O.K.
root@localhost:~#
```

