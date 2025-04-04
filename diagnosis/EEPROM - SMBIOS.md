# EEPROM - SMBIOS

SMBIOS通常放在eeprom里。若是使用onie的交换机，smbios还和onie tlv的信息放在一起：
- tlv(max size:2048bytes): 0-n (n, i.e. 1024KB)
- smbios: n-eeprom_max (max eeprom, i.e. 8092KB)



