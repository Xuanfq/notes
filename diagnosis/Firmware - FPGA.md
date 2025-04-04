# Firmware - FPGA

Field Programmable Gate Arrays (FPGAs) are integrated circuits often sold off-the-shelf. They're referred to as 'field programmable' because they provide customers the ability to reconfigure the hardware to meet specific use case requirements after the manufacturing process.

FPGA Flash 结构：

The MultiBoot feature allows FPGA to selectively reprogram and reload its bitstream from external SPI flash. When an error is detected during the MultiBoot configuration process, FPGA can trigger a fallback and ensure a known good image can be loaded into the device.

During loading of the MultiBoot image, the following errors can trigger fallback.
1. A CRC error
2. A watchdog timer-out error 

The golden image is loaded from address space 0x0000_0000 at power up. Then the golden image triggers a MultiBoot image to be loaded from Upper Address. The upper address is set to 0x0040_0000. The golden image is write-protected during upgrade. 

![MultiBoot Image Map](./Firmware%20-%20FPGA.assets/MultiBootImageMap.png)

## Version

FPGA本身一般有存放版本的`寄存器`，通过`OS驱动`或`BMC`读取该`寄存器的值`。

## FW Upgrade With AMI BMC

可能需要生成特定的FPGA Image给实现通过BMC升级FPGA

Tool: `CFUFLASH` & `Yafuflash`, provided by AMI

```bash
# 1. Enable BMC virtual USB
# ipmitool raw ....

# 2. Set IP for virtual USB
ifconfig enp0sxxx 169.254.0.16 up

# 3. Get BMC IP for virtual USB

# 4. Upgrade via CFUFLASH/Yafuflash with BMC IP
./CFUFLASH -nw -ip 169.254.0.17 -u admin -p admin -d 0x10 fpga_for_bmc_online_upgrade.bin
./Yafuflash -nw -ip 169.254.0.17 -u admin -p admin -d 0x10 fpga_for_bmc_online_upgrade.bin

# 5. Disable BMC virtual USB
# ipmitool raw ....
```

**Notice**: Need to AC Power Cycle after upgrade

## FW Upgrade Without AMI BMC

FPGA 本身提供SPI升级接口，OS实现SPI接口进行升级。

### FPGA SPI Configuration Interface
A SPI serial flash is used to store data for FPGA configuration. The master SPI interface is provided for processor to update the bitstream into the SPI flash through PCIE interface. FPGA can configure itself with the updated bitstream after power cycle. 

![Master SPI Configuration Interface](./Firmware%20-%20FPGA.assets/MasterSPIConfigurationInterface.png)

The .bin file is FPGA image used for remote update. To use the module to program an update image, the system needs to:
1. Set SPI module reset='0' to start the programming process. (0x1214). The module will do the following:
   A. Check ID
   B. Erase critical switch word
   C. Erase the update image area. 
2.  Software sends the update image data in order to be programmed. Write SPI write data register (0x1204) with 4 bytes each time. 
   For Step 2, this module does the following:
   A. Set outReady_BusyB='1'. (0x1210, bit[15])
   B. On rising edge of inClk when SPI Write Enable='1' (0x1200), capture inData32 and forward to SPI flash.
3. After sending last data word, wait for outDone='1' or outError='1'. Software can exit the update process if no error oocurs.
   A. After programming the last data word (which takes up to Page Program time), this
        module takes N inClk cycles to read and compute the CRC32 of the updated image.


### OS FPGA Upgrade Program

Command: `./fpga_prog /sys/devices/pci0000:00/0000:00:1c.6/0000:10:00.0/resource0 fpga_os_online_upgrade.bin`

**Notice**: Need to AC Power Cycle after upgrade

```c
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>
#include <limits.h>
#include "utility.h"

#define VERSION         "1.0.0"


uint32_t reg_start;

#define PAGESIZE        sysconf(_SC_PAGE_SIZE)
#define MMAP_OFFSET     (reg_start - (reg_start % PAGESIZE))
#define MAP_SIZE        ((reg_start % PAGESIZE) + 0x1F)
#define mm_offset(addr) (addr - MMAP_OFFSET)

uint32_t reg_spi_wr_en;
uint32_t reg_spi_wr_dat;
uint32_t reg_spi_chk_id;
uint32_t reg_spi_verify;
uint32_t reg_spi_stat;
uint32_t reg_spi_reset;

#define SPI_STAT_MARK_READY             (1 << 15)
#define SPI_STAT_MARK_DONE              (1 << 14)
#define SPI_STAT_MARK_ERROR_ANY         (1 << 13)
#define SPI_STAT_MARK_ERROR_CHKID       (1 << 12)
#define SPI_STAT_MARK_ERROR_ERASE       (1 << 11)
#define SPI_STAT_MARK_ERROR_PROG        (1 << 10)
#define SPI_STAT_MARK_ERROR_TOUT        (1 << 9)
#define SPI_STAT_MARK_ERROR_CRC         (1 << 8)
#define SPI_STAT_MARK_STG_STARTED       (1 << 7)
#define SPI_STAT_MARK_STG_INITED        (1 << 6)
#define SPI_STAT_MARK_STG_CHECKED_ID    (1 << 5)
#define SPI_STAT_MARK_STG_ERSD_SW       (1 << 4)
#define SPI_STAT_MARK_STG_UP_ERSD_IMG   (1 << 3)
#define SPI_STAT_MARK_STG_UP_PRG_IMG    (1 << 2)
#define SPI_STAT_MARK_STG_VERIFIED      (1 << 1)
#define SPI_STAT_MARK_STG_PRG_CMPT      (1 << 0)

#define WAIT_WRITE_READY_SEC 180
#define WAIT_WRITE_CONTINUE_CYCLE 100000
#define PATH_MAX        4096

#define debug(fmt,args...)          printf("debug : "fmt"\n",##args)
#define reg_write(mm,reg,value)     func_write(mm,reg,value)
#define reg_read(mm,reg,value)      value = func_read(mm,reg)

char        config_file[NAME_MAX];
char        msg_buf[MSG_MAX_SIZE];

void read_config(){

    FILE* fp;
    sprintf(config_file, "%s", "../"CEL_DIAG_CONFIGS"fpga.yaml");
    char key[20];
    uint32_t value;

    /* check whether file exists */

    if (access(config_file, F_OK)) {
        sprintf(msg_buf, "\nError: Config file [%s] not found.\n", config_file);
        printf("%x",STATUS_ERROR);
    }
    
    fp=fopen(config_file,"r");
    if(fp == NULL) {
        printf("Unable to open file! ");
        exit(1);
    }
    while(fscanf(fp, "%s %x", key, &value) == 2) {
        if(strcmp(key,"REG_START:")==0){
            reg_start = value;
        }else if(strcmp(key,"REG_SPI_WR_EN:")==0){
            reg_spi_wr_en = value;
        }else if(strcmp(key,"REG_SPI_WR_DAT:")==0){
            reg_spi_wr_dat = value;
        }else if(strcmp(key,"REG_SPI_CHK_ID:")==0){
            reg_spi_chk_id = value;
        }else if(strcmp(key,"REG_SPI_VERIFY:")==0){
            reg_spi_verify = value;
        }else if(strcmp(key,"REG_SPI_STAT:")==0){
            reg_spi_stat = value;
        }else if(strcmp(key,"REG_SPI_RESET:")==0){
            reg_spi_reset = value;
        }else{
            break;
        }
    }
    fclose(fp);

}

unsigned int func_write(char *mm, int addr, uint32_t value) {
    memcpy(mm + addr, &value, 4);
    msync(mm + addr, 4, MS_SYNC);
    return 0;
}

unsigned int func_read(char *mm, int addr) {
    uint32_t ret;
    memcpy(&ret, mm + addr, 4);
    return ret;
}

void dump_status(int Stat) {
    debug("#########################");
    debug("%d ready(1)/busy(0)",        (Stat & SPI_STAT_MARK_READY) != 0);
    debug("%d done",                    (Stat & SPI_STAT_MARK_DONE) != 0);
    debug("%d error any",               (Stat & SPI_STAT_MARK_ERROR_ANY) != 0);
    debug("%d error checkId",           (Stat & SPI_STAT_MARK_ERROR_CHKID) != 0);
    debug("%d error erase",             (Stat & SPI_STAT_MARK_ERROR_ERASE) != 0);
    debug("%d error program",           (Stat & SPI_STAT_MARK_ERROR_PROG) != 0);
    debug("%d error timeout",           (Stat & SPI_STAT_MARK_ERROR_TOUT) != 0);
    debug("%d error crc",               (Stat & SPI_STAT_MARK_ERROR_CRC) != 0);
    debug("%d stage started",           (Stat & SPI_STAT_MARK_STG_STARTED) != 0);
    debug("%d stage inited",            (Stat & SPI_STAT_MARK_STG_INITED) != 0);
    debug("%d stage checked id",        (Stat & SPI_STAT_MARK_STG_CHECKED_ID) != 0);
    debug("%d stage erasred",           (Stat & SPI_STAT_MARK_STG_ERSD_SW) != 0);
    debug("%d stage upload erase img",  (Stat & SPI_STAT_MARK_STG_UP_ERSD_IMG) != 0);
    debug("%d stage upload program img", (Stat & SPI_STAT_MARK_STG_UP_PRG_IMG) != 0);
    debug("%d stage verified",          (Stat & SPI_STAT_MARK_STG_VERIFIED) != 0);
    debug("%d stage completed",         (Stat & SPI_STAT_MARK_STG_PRG_CMPT) != 0);
}

int flash_program(char *mm, char *data, int lens) {
    int ctimeout;
    int error = 0;
    uint32_t Stat = 0;

    printf("Resetting Module \n");
    reg_write(mm, mm_offset(reg_spi_reset), 0x1); // reset
    sleep(1);
    reg_write(mm, mm_offset(reg_spi_reset), 0x0); // normal mode
    sleep(1);

    ctimeout = 0;
    do {       
        // wait for done flag
        reg_read(mm, mm_offset(reg_spi_stat), Stat);
        if (Stat & SPI_STAT_MARK_ERROR_ANY) {
            dump_status(Stat);
            error = Stat;
            break;
        }
        if (ctimeout++ > WAIT_WRITE_READY_SEC) {
            error = Stat | SPI_STAT_MARK_ERROR_TOUT;
            debug("wait ready timeout . . .");
            break;
        }
        printf(" waiting status to ready ... %d s.  status = %x\n", ctimeout, Stat);
        sleep(1);
    } while ((Stat & 0x80F8) != 0x80F8);
    if (error) {
        return error;
    }
    printf("Ready, Start FPGA Flash ...\n");


    for (int i = 0; i < lens;) {

        do {    // wait for ready flag
            reg_read(mm,  mm_offset(reg_spi_stat), Stat);
        } while ((Stat & SPI_STAT_MARK_READY) == 0);

        uint32_t dbuf = 0;

        // first byte is MSB
        dbuf =  (((uint32_t)data[i]  ) & 0xFF) << 24;
        dbuf |= (((uint32_t)data[i + 1]) & 0xFF) << 16;
        dbuf |= (((uint32_t)data[i + 2]) & 0xFF) << 8;
        dbuf |= (((uint32_t)data[i + 3]) & 0xFF);

        reg_write(mm, mm_offset(reg_spi_wr_dat), dbuf); // write data
        reg_write(mm, mm_offset(reg_spi_wr_en), 0x1); // write enable
        reg_read(mm, mm_offset(reg_spi_stat), Stat);  // just for a delay before disable write
        reg_write(mm, mm_offset(reg_spi_wr_en), 0x0); // write disable

        ctimeout = 0;
        do {       // wait for done flag
            reg_read(mm,  mm_offset(reg_spi_stat), Stat);
            if (Stat & SPI_STAT_MARK_ERROR_ANY) {
                error = Stat;
                break;
            }

            if (ctimeout++ > WAIT_WRITE_CONTINUE_CYCLE) {
                error = Stat | SPI_STAT_MARK_ERROR_TOUT;
                debug("wait ready timeout . . .");
                break;
            }
        } while ((Stat & 0x80F8) != 0x80F8);

        if (error) {
            printf("FPGA programing fail at %d/%d\n", i, lens);
            dump_status(Stat);
            debug("Status = %4.4X", error);
            break;
        }

        i += 4;

        if (i % (lens / 40 * 4) == 0) {
            printf(" FPGA programmed ... %d/%d\n", i, lens);
        } else if (i >= lens){
            printf(" FPGA programmed ... %d/%d\n", lens, lens);
        }
    }

    printf("Status = %4.4X\n", Stat);

    reg_write(mm, mm_offset(reg_spi_wr_en), 0x0);  // write protect
    reg_write(mm, mm_offset(reg_spi_reset), 0x1);  // module reset

    return error;
}

int main(int argc, char **argv) {
    FILE *pFILE;
    int fd, filesize;
    char *mm, *fpga_buff;
    int status;
    read_config();
    printf(" FPGA PROGRAMMNG version %s \n", VERSION);
    printf(" build date : %s %s\n", __DATE__, __TIME__);
    printf("\n");

    if (argc != 3) {
        errno = EINVAL;
        printf("Error: %s\n", strerror(errno));
        printf("Usage: %s <resfile> <fwfile>\n"
               "  resfile     PCI resource file eg. /sys/bus/pci/devices/0000:03:00.0/resource0\n"
               "  fwfile      FPGA firmware binary file\n", getenv("_"));
        exit(errno);
    }

    //Open PCI resource file for mmap
    fd = open(argv[1], O_RDWR );
    if (fd == -1) {
        printf("Error while opening \"%s\" : %s\n", argv[1], strerror(errno));
        exit(errno);
    }

    //Memory map the PCI resource file
    mm = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, MMAP_OFFSET);
    if (mm == MAP_FAILED) {
        close(fd);
        printf("Error while mmapping the file : %s\n", strerror(errno));
        exit(errno);
    }

    //Read FPGA fw binary file to buffer
    pFILE = fopen(argv[2], "rb");
    if (pFILE == NULL)
    {
        printf("Error while opening \"%s\" : %s\n", argv[2], strerror(errno));
        exit(errno);
    }

    fseek(pFILE , 0 , SEEK_END);
    filesize = ftell (pFILE);
    rewind(pFILE);
    fpga_buff = malloc(filesize);
    if (fpga_buff == NULL) {
        printf("Can't Allocate memory : %s\n", strerror(errno));
        exit(errno);
    }

    fread(fpga_buff, 1, filesize, pFILE);
    printf("%d bytes read\n", filesize);
    fclose(pFILE);

    status = flash_program(mm, fpga_buff, filesize);

    //Memory un-map
    if (munmap(mm, MAP_SIZE) == -1) {
        printf("Error un-mmapping the file\n");
    }
    close(fd);

    if (status == 0) {
        printf("Programing is complete\n");
    } else {
        printf("Program Error : error code %4.4x \n", status);
    }

    return status;
}

```
