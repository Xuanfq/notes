# Network Card - I210 Gigabit Network Connection

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


## Help

```
Intel(R) EEUpdate Release Notes
================================
May 17, 2006


DISCLAIMER
==========

This software is furnished under license and may only be used or copied
in accordance with the terms of the license.  The information in this
manual is furnished for informational use only, is subject to change
without notice, and should not be construed as a commitment by Intel
Corporation.  Intel Corporation assumes no responsibility or liability
for any errors or inaccuracies that may appear in this document or any
software that may be provided in association with this document.  Except
as permitted by such license, no part of this document may be reproduced,
stored in a retrieval system, or transmitted in any form or by any means
without the express written consent of Intel Corporation.


Contents
========

- OVERVIEW
- RUNNING THE UTILITY
   - OPTIONS
   - BASIC USAGE GUIDELINES
   - EEPROM IMAGE FILE FORMAT
   - MAC ADDRESS FILE FORMAT
   - EELOG.DAT
   - EXAMPLES
   - ERROR CODES   
- INSTALLATION
- CUSTOMER SUPPORT
-LEGAL

OVERVIEW
========

EEUpdate is the EEPROM Update Utility.  Allows manufacturing programming of
EEPROMs, in cases where EEPROM is not preprogrammed, or programmed
at In-circuit test.


RUNNING THE UTILITY
===================

Using the "/?" option will display a list of supported 
command line options.
    
NOTE: EEPROM checksums and CRCs are automatically updated with any 
      command that modifies the EEPROM contents.  

OPTIONS:
--------

EEUPDATE can be run with any of the following command line options:

    /HELP or /?
        Displays command line help.
    /EXITCODES
        Displays exit code help.
    /ALL
        Selects all adapters found in the system.
    /NIC=XX
        Selects a specific adapter (1-32).
    /BUS=XX
        Selects PCI bus of adapter to program.  Must be used with the DEV
        parameter to specify an adapter.
    /DEV=XX
        Selects PCI device of the adapter to program.  Must be used with the 
        BUS parameter to specify an adapter.
    /FUN=XX
        Selects PCI function of the adapter to program.  Must be used with both
        the BUS and DEV parameters to specify an adapter.       
    /DEVICE=<pci device id>
        4 hex digit device id of card to program.        
    /DUMP
        Dumps EEPROM memory contents to file.
    /CB <offset> <bitmask>
        Clears bits in the EEPROM, specified in <bitmask>.
    /SB <offset> <bitmask>
        Sets bits in the EEPROM, specified in <bitmask>.
    /RW <word>
        Reads <word> from the EEPROM.
    /WW <word> <value>
        Writes <value> into <word> in EEPROM.
    /MAC=macaddr
        Programs the EEPROM with only the MAC address of
        macaddr without changing the rest of the EEPROM.
    /A <addrfile> or /address <addrfile>
        Programs the EEPROM with only the MAC address from
        the <addrfile> without changing the rest of the
        EEPROM.
    /D <imagefile> or /DATA <imagefile>
        Programs the EEPROM with the contents of <imagefile>
        without changing the MAC address.
    /CALCCHKSUM
        Forces the EEPROM checksum and CRCs to be updated.
    /EEPROMVER
        Displays the version of the EEPROM image.
    /PCIINFO
        Displays the PCI information of the adapter.
    /TEST
        Checks the EEPROM checksum and size.
    /IDFLASH
       Displays the flash ID and its protected status.
    /WOLDISABLE or /WOLD
        Disables WOL bit.
    /WOLENABLE or /WOLE
        Enables WOL bit.
    /BMCMAC_DUMP
        Displays the dedicated MAC address for the BMC.
    /MNGMAC=macaddr
        Programs the dedicated MAC address for the manageability component without
        changing the rest of the EEPROM.
    /MNGADDRESS <addrfile>
        Programs the dedicated MAC address for the manageability component with the
        MAC address from <addrfile>.
    /VERSION
        Displays version and the diagnostic library information.
    /GUI
        Brings up GUI mode.
    /NOPROT
	When programing an image for devices that support NVM protection, 
	prevents protection from being enabled.  This switch must be used 
 	with the /DATA command and has no effect on NVM devices that are 
	already protected.           
    /BMCMAC=macaddr is replaced with MNGMAC command.
    /BMCADDRESS <addrfile> is replaced with MNGADDRESS command.
    /RETAINMNGMAC Uses the manageability MAC address in the NVM rather than the image
    /DEBUGLOG <debugfile>      
	Log debug messages into the debugfile.
    /VERIFY <targetfile>
    	Verifies the eeprom image in eeprom to the target file
    	specified in <targetfile>.

BASIC USAGE GUIDELINES
----------------------
To display a list of installed adapters call EEUPDATE without any 
parameters as follows:

EEUPDATE

EEUPDATE will display a list of network adapters installed in the
system similar to the following:

    [EEUPDATE ver 5.0.1.0] - Intel PCI NIC EEPROM Utility
    Copyright (C) 1995 - 2004 Intel Corporation
    Intel (R) Confidential and not for general distribution.

    Warning: No Adapter Selected

    NIC Bus Dev Fun Vendor-Device  Branding string
    === === === === ============= =================================================
    1  1   00  00   8086-1008     Intel(R) PRO/1000 XT Server Adapter
    2  1   08  00   8086-1039     Intel(R) PRO/100 VE Network Connection


To perform an operation on an installed network adapter you must specify
the "/NIC=" parameter.  For example, to perform an EEPROM dump on NIC 3 
from the list above call EEUPDATE like this:

EEUPDATE /NIC=3 /DUMP

Alternatively you may specify the "/BUS=" and "/DEV=" parameters instead of the
"/NIC=" parameter to specify which network adapter to select.  For example
to program NIC 1 from the list above with the EEPROM image file "image.eep"
call EEUPDATE.EXE as follows:

EEUPDATE /BUS=0 /DEV=D /DATA image.eep


EEPROM IMAGE FILE FORMAT
------------------------
The <imagefile> parameter designates a text file which contains
hexadecimal values with which to program the EEPROM.  Each 
value should consist of up to four hex digits seperated by
a space or newline.  The data contained in <imagefile> must be
formatted the same as the EEPROM imagefile produced by the 
"/dump" parameter.  An imagefile produced by the "/dump"
parameter may be used to program the EEPROM.
Comments may be added to the EEPROM image file as long as they
are preceded by a semicolon ';'.
NOTE: When programming the EEPROM using the "/DATA" parameter,
EEupdate will ignore the MAC Address (first 6 bytes), and 
EEPROM checksum (last 2 bytes).  However, the MAC Address and 
checksum locations in the EEPROM image file must be filled
with valid hexadecimal values.


MAC ADDRESS FILE FORMAT
-----------------------
The <addrfile> parameter designates a text file which contains
MAC addresses to be programmed to the NIC.  This file should
contain a list of one or more legal MAC addresses, one per
line.  Each MAC address contains exactly 12 hexadecimal 
digits:

Example:

000AC45D7800
000AC45D7801
000AC45D7802

A special "count" syntax may also be used.  When a decimal
integer in square brackets follows the mac address on the line,
it is interpreted as a count of consecutive MAC addresses to be
programmed.  

Example:

000AC45D7800 [3]

The two examples above are the same.  Both represent three 
consecutive MAC addresses starting at 000AC45D7800.

Note: Every line in the address file must end with a carriage return.
When EEUPDATE is executed with the <addrfile>, it will sequentially program 
each selected NIC with MAC addresses from the address file, starting with 
the first entry.  A file, EELOG.DAT, is generated with a record of which 
MAC addresses were used and which remain available.  

To program the remaining MAC addresses, EEUPDATE must be run again with 
the EELOG.DAT specified for the <addrfile>.  This is necessary because 
only EELOG.DAT contains the information on which MAC addresses have been 
programmed and which still remain available.  

Alternatively, the EELOG.DAT file may be copied over to the previous 
address file to eliminate the possibility of MAC Address reuse.
(See Example 1 and 2).  

If EEUPDATE is run again using the same address file (without copying 
EELOG.DAT), it will program MAC addresses starting back at the first entry 
in the address file.  Please use caution to always use the EELOG.DAT file in 
order to not program two different NIC ports with the same MAC address.

Dual port adapters:
When programming the MAC address and EEPROM from a file on a dual port adapter, 
the recommended method to only select the 1st port of the dual port adapter 
for programming.  The MAC address file should therefore contain only the 1st 
port MAC addresses.  This method is more efficient, as the EEPROM is only 
programmed once.


EELOG.DAT
---------
When <addrfile> is used as a source for MAC addresses, EEUPDATE
generates a file named EELOG.DAT which contains a record of 
which MAC addresses in <addrfile> were used and which remain 
available.  Those addresses used are tagged with a date/time 
stamp like this:

000AC45D7800 : 10:43:14  08/30/2000

The file format for EELOG.DAT is readable as input for <addrfile>
in future invocations of EEUPDATE.  As of EEUPDATE 3.27, the 
EELOG.DAT file may be used as both input and output 
simultaneously.


EXAMPLES
--------
Example 1:
To update the EEPROM and MAC Address with the data stored in the 
files imagefile.eep, and addrfile.dat respectively, call EEUPDATE
like this:
   STEP1: EEUPDATE /NIC=1 imagefile.eep addrfile.dat
   STEP2: copy eelog.dat addrfile.dat

Example 2:
To update the MAC Address on the third Intel network adapter found in your 
system without changing the rest of the EEPROM, call EEUPDATE like this:
   STEP1: EEUPDATE /NIC=3 /A addrfile.dat
   STEP2: copy eelog.dat addrfile.dat

Example 3:
To update the EEPROM without changing the MAC address on all
of the Intel network adapters with device ID 2449 found in
your system, call EEUPDATE like this:
   EEUPDATE /DEVICE=2449 /D imagefile.eep

Example 4:
To dump the EEPROM contents on all of the Intel network adapters
in your system, call EEUPDATE like this:
   EEUPDATE /ALL /DUMP

Example 5:
To clear specific bit 1 in word 0xA in the EEPROM on 
all of the Intel network adapters in your system with 
device IDs 1038, call EEUPDATE like this:
   EEUPDATE /DEVICE=1038 /CB 0xA 0x2

Example 6:
To set bit 1 in word 0xA in the EEPROM on all of the Intel 
network adapters in your system, call EEUPDATE like this:
   EEUPDATE /ALL /SB 0xA 0x2

Example 7:
To read word 0x9 from the EEPROM, call EEUPDATE like this:
   EEUPDATE /NIC=3 /RW 0x9

Example 8:
To write word 0x9 to the EEPROM on the third Intel 
network adapter found in your system, and update its
checksum, call EEUPDATE like this:
   EEUPDATE /NIC=3 /WW 0x9 0x1234


NOTE
-----

* If you run EEUPDATE without any command line options,
  EEUPDATE will display a listing of all of the supported
  Intel Network adapters found in your system.

* When using the '/dump' command, EEUPDATE will automatically 
  create a file and name it, based on the last 8 bytes
  of your Intel Network adapter's MAC Address.  For example,
  if your MAC Address was '00AA11223344', EEUPDATE would
  create the file called '11223344.EEP'.

* Both <word> and <bitmask> parameters *must* be sent
  to eeupdate in hexadecimal.

* The EEPROM Checksums and CRCs are automatically updated when 
  you clear/set a bit or bits, and when you write a word to
  the EEPROM.  

ERROR CODES:
----------------
EEUPDATE returns error codes to the command line.  A description of each 
of these codes can be found in the tool by running eeupdate /exitcodes.

Installation
=============

INSTALLING THE TOOLS ON MICROSOFT WINDOWS(R)
============================================

The tools driver can be installed on all versions of Windows since Windows 2000.  
The tools driver for the 32-bit versions of Windows are in the 
Win32 directory on the CD.  The tools driver for the 64-bit versions of Windows
are in the Win64 or Win64e directory on the CD.

To install the tools drivers on 32-bit Windows, run install.bat from the Win32
directory on the CD.  Run install.bat from the Win64 directory to install 
the tools drivers on 64-bit Windows. 

Although the tools are not installed with install.bat, the driver that
the tools require is copied into the local machine Windows driver directory.
To run the tools, launch a Command Prompt window from the Windows Start Menu.  
Go to the media and directory where the tools are located and run the tools.
The readme files for each tool are found in the same directory as the tools.
These tools can be manually installed on the local hard drive in any directory.

Although the tools driver can be installed on the system at the same time as
Intel(R) PROSet, this is not recommended, as the system may become unstable.
Uninstall PROSet before installing the tools.  When reinstalling PROSet, the
tools driver will be replaced, so the tools may not function properly.  In other
words, PROSet and the tools should be mutually exclusive.


INSTALLING THE TOOLS ON EFI
==============================

The tools support Intel EFI-32/64 v1.10.  The tools for EFI-32 are in the 
EFI32 directory on the CD.  The EFI-64 tools are in the EFI64 directory on the
CD.  There is no installation required for EFI tools.  The tools can simply be
copied from the EFI32 or EFI64 directory to the drive that they will run from.


INSTALLING THE TOOLS ON DOS
===========================

The tools support DOS v6.22 but should run in various DOS versions since 
including FreeDos.  There is no installation required for DOS tools.
The tools can simply be copied from the DOS directory on the CD to the drive
that they will run from.  It is expected that the tools have a clean boot 
environment. The tools will not run with memory managers and/or DOS networking
drivers loaded. The tools expect that they have full, unlimited control of the
hardware. The tools *WILL NOT* run properly if EMM386 is present.


INSTALLING THE TOOLS ON LINUX
==============================

The tools support RedHat distributions since v8.0 (32-bit, 64-bit, and EM64T architectures), but should run on any standard distribution with kernel 2.4
or later. Kernel source and working GCC is required for building the driver
stub required by the tools.  If you are having problems getting the tools to work
on your particular version of Linux, please fall back to one of the RedHat/Fedora
line of products. This is the installation procedure:

    1. Log in as root and create a temporary directory to build the Intel(R)
       PRO Network Connection Tools driver.

    2. Copy ‘install’ and ‘iqvlinux.tar.gz’ to the temporary directory.
       These files are in the Linux32 directory on the CD.

    3. CD to the temporary directory and run ‘.\install.’  The driver has been
       installed now, so the files in the temporary directory can be removed. 
       Note: the kernel source package is required to be installed from the 
       Redhat CD in order to build the driver.

    4. Copy the tools that you want to use from the Linux32 or Linux64 
       directory of the CD.


CUSTOMER SUPPORT
================

- Main Intel web support site: http://support.intel.com

- Network products information: http://www.intel.com/network

- Worldwide access: Intel has technical support centers worldwide.  Many
  of the centers are staffed by technicians who speak the local languages.
  For a list of all Intel support centers, the telephone numbers, and the
  times they are open, visit http://www.intel.com/support/9089.htm.

- Telephone support: US and Canada: 1-916-377-7000
  (7:00 - 17:00 M-F Pacific Time)


Legal / Disclaimers
===================

Copyright (C) 2002-2006, Intel Corporation.  All rights reserved.

Intel Corporation assumes no responsibility for errors or omissions in this
document.  Nor does Intel make any commitment to update the information
contained herein.

* Other product and corporate names may be trademarks of other companies and
are used only for explanation and to the owners' benefit, without intent to
infringe.
```



