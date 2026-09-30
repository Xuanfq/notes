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

Tool: `Yafuflash`, provided by AMI

- Upgrade via local
```md
1. Enable BMC Virtual USB:
`ipmitool raw 0x32 0xaa 0x00` (Then wait 15s)
2. Update Main BMC:  
`./Yafuflash -cd -mse 1 bmc.ima`
3. Update Backup BMC: 
`./Yafuflash -cd -mse 2 bmc.ima`
4. Disable BMC Virtual USB:
`ipmitool raw 0x32 0xaa 0x01
```

- Upgrade via remote
```bash
# 1. Enable BMC virtual USB
# ipmitool raw ....

# 2. Set IP for virtual USB
ifconfig enp0sxxx 169.254.0.16 up

# 3. Get BMC IP for virtual USB

# 4. Upgrade via Yafuflash with BMC IP
./Yafuflash -nw -ip 169.254.0.17 -u admin -p admin -d 1 -mse 1 bmc_online_upgrade.ima

# 5. Disable BMC virtual USB
# ipmitool raw ....
```

**Notice**: Need to AC Power Cycle if codebase upgraded

Usage:
```bash
```bash
~# Yafuflash -h
INFO: Yafu INI Configuration File not found... Default options will not be applied...
Usage: Yafuflash [OPTION] [FW_IMAGE_FILE]
 Perform BMC Flash Update
 -?                                            Displays the utility usage
 -h                                            Displays the utility usage
 -V                                            Displays the version of the tool
 -e                                            List outs a few examples of the tool
OPTION :
 -info                                         Displays information about current FW and new FW.
 -msi,-img-section-info                        Displays information about current FW Sections.
 -mi,-img-info                                 Displays information about current FW Versions.
 -fb,-force-boot                               Option to FORCE BootLoader upgrade during full upgrade.
                                               Also, skips user interaction in Interactive Upgrade mode.
                                               This option is not allowed with interactive upgrade option
 -bu,-block-upgrade                            Option to Flash using Block by Block method
 -netfn 0xXX                                   Option to Flash using OEM specific Netfuncion
 -pc,-preserve-config                          Option to preserve Config Module during full upgrade.
                                               If platform supports Dual Image, this option skips user
                                               interaction, preserves config and continues update process.
                                               This option is not allowed with interactive upgrade option.
 -ipc,-ignore-platform-check                   If this image is for a different platform, this option skips
                                               user interaction and continues update process.
 -idi,-ignore-diff-image                       If this image differs from the one currently programmed, this
                                               option skips user interaction and continues update process.
 -isi,-ignore-same-image                       If this image is same as the one currently programmed, this
                                               option skips user interaction and continues update process.
 -iml,-ignore-module-location                  If module(s) of this image is/are in a different location, this
                                               option skips user interaction and continues update process.
 -ibv,-ignore-boot-version                     If bootloader version is different and -force-boot is not specified,
                                               this option skips user interaction and continues update process.
                                               The bootloader will be updated.
 -iri,-ignore-reselect-image                   This option skips reselecting the active image.
 -inc,-ignore-non-preserve-config              If the Images of both flash share the same Configuration area.
                                               Not preserving will restore to default factory settings, this option skips it.
 -msp,-split-img                               Use this option to flash split image.
 -f-XXX,-flash-XXX                             Use this option to flash spection section where XXX denotes name of the section,
                                               example -flash-conf. If it is split image need to give -split-img along with this option.
 -q,-quiet                                     Use the option to show the minimum flash progress details.
 -i                                            Option to interactive upgrade (upgrade only required Modules)
 -f,-full                                      Performs full firmware upgrade with Interactive Upgrade mode. Skips option to select individual module upgrade.
                                               This option must be used along with -i (-interactive) option.
 -sc,-skip-crc                                 Option to skip the CRC check(Only for Dual Image Support)
 -sf,-skip-fmh                                 Option to skip the FMH check(Only for Dual Image Support)
 -d                                            Option to specify the peripheral(Only for Dual Image Support)
                                                   <BIT0> - BMC
                                                   <BIT1> - BIOS
                                                   <BIT2> - CPLD
                                                    <BIT4> - ME
 -mse,-img-select                              Option to specify the Image to be updated
                                                    0 - Inactive Image
                                                    1 - Image 1
                                                    2 - Image 2
                                                    3 - Both Images
 -a,-activate                                  Option to activate peripheral devices
                                                   <BIT0> - BMC
                                                   <BIT1> - BIOS
                                                   <BIT2> - CPLD
  -ini                                                  Option to give ini file as input.Ini file should be present in the current directory of the Yafuflash executable or in /etc folder
                                                        1. Yafu_SingleImage.ini - For Single Image.
                                                        2. Yafu_DualImage.ini   - For Dual Image.
                                                        3. Yafu_MMCImage.ini  - For MMC Image.
-spi , -mmc                                   Option to Flash HPM Image Component wise
                                                            0 -BOTH
                                                            1 -SPI Image
                                                            2- MMC Image
 -nr,-no-reboot                                Option to skip the reboot
 -pXXX,-preserve-XXX                           Option to preserve XXX configuration. Where XXX falls in sdr, fru, sel, ipmi, auth, net,
                                               ntp, snmp, ssh, kvm, syslog. If the preserve status of another configuration is enabled, then
                                               it will ask to confirm that those configuration is to be preserved.
 -ieo, -ignore-existing-overrides              Clears the existing overrides and preserves only the overrides given in command line if any
  -rp,-replace-publickey                        Option to replace the Signed Image Key in Existing Firmware
 -vcf,-version-cmp-flash                       Option to skip flashing modules only if the versions are same by selecting (N/n).
                                               Option (Y/y) Selects full firmware upgrade mode.
 -non-interactive                              This option skips user interaction. This option cannot be used along with 'ignore-diff-image',
                                               'ignore-same-image', '-ignore-module-location' & '-ignore-boot-version' options.
MEDIUM :
 -cd                                           Option to use USB Medium
 -nw,-ip,-u,-p,-host,-port                        Option to use Network Medium
                                               '-ip' Option to enter IP, when using Network Medium
                                               '-host' Option to enter host name, When using Network Medium
                                               '-u' Option to enter UserName, When using Network Medium
                                               '-p' Option to enter Password, When using Network Medium
                                               '-port' Option to enter Port Number
 -kcs                                          Option to use KCS Medium
 FW_IMAGE_FILE :
 fw_image_file                                 Firmware Image file name
 -pe,-preserve-extlog                          Option to preserve extlog configuration during firmware flash
```


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

