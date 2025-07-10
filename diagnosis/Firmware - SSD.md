# Firmware - SSD

不同的厂商的FW升级方式可能有所不同，需要同厂商确认。

## Update with hdparm

- Model Command: `sudo hdparm -I /dev/sda | grep "Model Number" | sed 's/ //g' | cut -d ':' -f 2`
- Version Command: `sudo hdparm -I /dev/sda | grep "Firmware Revision" | sed 's/ //g' | cut -d ':' -f 2`
- Update Command: `sudo hdparm --yes-i-know-what-i-am-doing --please-destroy-my-drive --fwdownload <Firmware> <device:/dev/sda>`

- Command Usage: 

```bash
# hdparm

hdparm - get/set hard disk parameters - version v9.60, by Mark Lord.

clue=6
Usage:  hdparm  [options] [device ...]

Options:
 -a   Get/set fs readahead
 -A   Get/set the drive look-ahead flag (0/1)
 -b   Get/set bus state (0 == off, 1 == on, 2 == tristate)
 -B   Set Advanced Power Management setting (1-255)
 -c   Get/set IDE 32-bit IO setting
 -C   Check drive power mode status
 -d   Get/set using_dma flag
 -D   Enable/disable drive defect management
 -E   Set cd/dvd drive speed
 -f   Flush buffer cache for device on exit
 -F   Flush drive write cache
 -g   Display drive geometry
 -h   Display terse usage information
 -H   Read temperature from drive (Hitachi only)
 -i   Display drive identification
 -I   Detailed/current information directly from drive
 -J   Get/set Western DIgital "Idle3" timeout for a WDC "Green" drive (DANGEROUS)
 -k   Get/set keep_settings_over_reset flag (0/1)
 -K   Set drive keep_features_over_reset flag (0/1)
 -L   Set drive doorlock (0/1) (removable harddisks only)
 -m   Get/set multiple sector count
 -M   Get/set acoustic management (0-254, 128: quiet, 254: fast)
 -n   Get/set ignore-write-errors flag (0/1)
 -N   Get/set max visible number of sectors (HPA) (VERY DANGEROUS)
 -p   Set PIO mode on IDE interface chipset (0,1,2,3,4,...)
 -P   Set drive prefetch count
 -q   Change next setting quietly
 -Q   Get/set DMA queue_depth (if supported)
 -r   Get/set device readonly flag (DANGEROUS to set)
 -R   Get/set device write-read-verify flag
 -s   Set power-up in standby flag (0/1) (DANGEROUS)
 -S   Set standby (spindown) timeout
 -t   Perform device read timings
 -T   Perform cache read timings
 -u   Get/set unmaskirq flag (0/1)
 -U   Obsolete
 -v   Use defaults; same as -acdgkmur for IDE drives
 -V   Display program version and exit immediately
 -w   Perform device reset (DANGEROUS)
 -W   Get/set drive write-caching flag (0/1)
 -x   Obsolete
 -X   Set IDE xfer mode (DANGEROUS)
 -y   Put drive in standby mode
 -Y   Put drive to sleep
 -z   Re-read partition table
 -Z   Disable Seagate auto-powersaving mode
 --dco-freeze      Freeze/lock current device configuration until next power cycle
 --dco-identify    Read/dump device configuration identify data
 --dco-restore     Reset device configuration back to factory defaults
 --dco-setmax      Use DCO to set maximum addressable sectors
 --direct          Use O_DIRECT to bypass page cache for timings
 --drq-hsm-error   Crash system with a "stuck DRQ" error (VERY DANGEROUS)
 --fallocate       Create a file without writing data to disk
 --fibmap          Show device extents (and fragmentation) for a file
 --fwdownload            Download firmware file to drive (EXTREMELY DANGEROUS)
 --fwdownload-mode3      Download firmware using min-size segments (EXTREMELY DANGEROUS)
 --fwdownload-mode3-max  Download firmware using max-size segments (EXTREMELY DANGEROUS)
 --fwdownload-mode7      Download firmware using a single segment (EXTREMELY DANGEROUS)
 --fwdownload-modee      Download firmware using mode E (min-size segments) (EXTREMELY DANGEROUS)
 --fwdownload-modee-max  Download firmware using mode E (max-size segments) (EXTREMELY DANGEROUS)
 --idle-immediate  Idle drive immediately
 --idle-unload     Idle immediately and unload heads
 --Iraw filename   Write raw binary identify data to the specfied file
 --Istdin          Read identify data from stdin as ASCII hex
 --Istdout         Write identify data to stdout as ASCII hex
 --make-bad-sector Deliberately corrupt a sector directly on the media (VERY DANGEROUS)
 --offset          use with -t, to begin timings at given offset (in GiB) from start of drive
 --prefer-ata12    Use 12-byte (instead of 16-byte) SAT commands when possible
 --read-sector     Read and dump (in hex) a sector directly from the media
 --repair-sector   Alias for the --write-sector option (VERY DANGEROUS)
 --sanitize-antifreeze-lock  Block sanitize-freeze-lock command until next power cycle
 --sanitize-block-erase      Start block erase operation
 --sanitize-crypto-scramble  Change the internal encryption keys that used for used data
 --sanitize-freeze-lock      Lock drive's sanitize features until next power cycle
 --sanitize-overwrite  PATTERN  Overwrite the internal media with constant PATTERN
 --sanitize-status           Show sanitize status information
 --security-help             Display help for ATA security commands
 --set-sector-size           Change logical sector size of drive
 --trim-sector-ranges        Tell SSD firmware to discard unneeded data sectors: lba:count ..
 --trim-sector-ranges-stdin  Same as above, but reads lba:count pairs from stdin
 --verbose                   Display extra diagnostics from some commands
 --write-sector              Repair/overwrite a (possibly bad) sector directly on the media (VERY DANGEROUS)
# sudo hdparm -I /dev/sda

/dev/sda:

ATA device, with non-removable media
        Model Number:       SanDisk SD9TB8W256G1001
        Serial Number:      1849DE800119
        Firmware Revision:  X6107101
        Media Serial Num:
        Media Manufacturer:
        Transport:          Serial, ATA8-AST, SATA 1.0a, SATA II Extensions, SATA Rev 2.5, SATA Rev 2.6, SATA Rev 3.0
Standards:
        Used: unknown (minor revision code 0x005e)
        Supported: 11 10 9 8 7 6 5
        Likely used: 11
Configuration:
        Logical         max     current
        cylinders       16383   0
        heads           16      0
        sectors/track   63      0
        --
        LBA    user addressable sectors:   268435455
        LBA48  user addressable sectors:   500118192
        Logical  Sector size:                   512 bytes
        Physical Sector size:                   512 bytes
        Logical Sector-0 offset:                  0 bytes
        device size with M = 1024*1024:      244198 MBytes
        device size with M = 1000*1000:      256060 MBytes (256 GB)
        cache/buffer size  = unknown
        Form Factor: 2.5 inch
        Nominal Media Rotation Rate: Solid State Device
Capabilities:
        LBA, IORDY(can be disabled)
        Queue depth: 32
        Standby timer values: spec'd by Standard, no device specific minimum
        R/W multiple sector transfer: Max = 1   Current = 1
        Advanced power management level: 254
        DMA: mdma0 mdma1 mdma2 udma0 udma1 udma2 udma3 udma4 udma5 *udma6
             Cycle time: min=120ns recommended=120ns
        PIO: pio0 pio1 pio2 pio3 pio4
             Cycle time: no flow control=120ns  IORDY flow control=120ns
Commands/features:
        Enabled Supported:
           *    SMART feature set
                Security Mode feature set
           *    Power Management feature set
           *    Write cache
           *    Look-ahead
           *    WRITE_BUFFER command
           *    READ_BUFFER command
           *    DOWNLOAD_MICROCODE
           *    Advanced Power Management feature set
           *    48-bit Address feature set
           *    Mandatory FLUSH_CACHE
           *    FLUSH_CACHE_EXT
           *    SMART error logging
           *    SMART self-test
           *    General Purpose Logging feature set
           *    64-bit World wide name
           *    WRITE_UNCORRECTABLE_EXT command
           *    {READ,WRITE}_DMA_EXT_GPL commands
           *    Segmented DOWNLOAD_MICROCODE
                unknown 119[8]
           *    Gen1 signaling speed (1.5Gb/s)
           *    Gen2 signaling speed (3.0Gb/s)
           *    Gen3 signaling speed (6.0Gb/s)
           *    Native Command Queueing (NCQ)
           *    Phy event counters
           *    READ_LOG_DMA_EXT equivalent to READ_LOG_EXT
           *    DMA Setup Auto-Activate optimization
                Device-initiated interface power management
           *    Asynchronous notification (eg. media change)
           *    Software settings preservation
                Device Sleep (DEVSLP)
           *    SANITIZE feature set
           *    CRYPTO_SCRAMBLE_EXT command
           *    BLOCK_ERASE_EXT command
           *    Device encrypts all user data
           *    DOWNLOAD MICROCODE DMA command
           *    WRITE BUFFER DMA command
           *    READ BUFFER DMA command
           *    Data Set Management TRIM supported (limit 8 blocks)
           *    Deterministic read ZEROs after TRIM
Security:
        Master password revision code = 65534
                supported
        not     enabled
        not     locked
                frozen
        not     expired: security count
                supported: enhanced erase
        2min for SECURITY ERASE UNIT. 2min for ENHANCED SECURITY ERASE UNIT.
Logical Unit WWN Device Identifier: 5001b448b97e5f05
        NAA             : 5
        IEEE OUI        : 001b44
        Unique ID       : 8b97e5f05
Device Sleep:
        DEVSLP Exit Timeout (DETO): 30 ms (drive)
        Minimum DEVSLP Assertion Time (MDAT): 30 ms (drive)
Checksum: correct

```

> 已知Swissbit部分型号支持。

