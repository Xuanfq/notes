# Firmware - TPM

Source Code: https://github.com/iavael/infineon-firmware-updater.git


## Update by TPMFactoryUpd

### How To Build and Install TPMFactoryUpd

#### Set up Compilation Environment

##### Check Host Environment

###### Hardware

According to the Hardware Spec, e.g. CPU is ARM Cortex-A57

```
Broadcom’s BCM58711 is selected as the host processor, which contains a high-performance ARM CPU subsystem. The CPU/SOC subsystem integrates the latest ARM Cortex-A57 CPUs in a single-cluster configuration for a total of two processor cores and several peripheral interfaces. 
```


###### Software

```shell
root@bcm958712k:~# uname -a
Linux bcm958712k 3.14.65+ #2 SMP Wed Aug 9 19:59:46 CST 2017 aarch64 GNU/Linux
root@bcm958712k:~#
root@bcm958712k:~# cat /etc/issue
Poky (Yocto Project Reference Distro) 1.8.1 \n \l

root@bcm958712k:~#
root@bcm958712k:~# cat /proc/cpuinfo
processor       : 0
BogoMIPS        : 50.00
Features        : fp asimd aes pmull sha1 sha2 crc32
CPU implementer : 0x41
CPU architecture: 8
CPU variant     : 0x1
CPU part        : 0xd07
CPU revision    : 3

processor       : 1
BogoMIPS        : 50.00
Features        : fp asimd aes pmull sha1 sha2 crc32
CPU implementer : 0x41
CPU architecture: 8
CPU variant     : 0x1
CPU part        : 0xd07
CPU revision    : 3
root@bcm958712k:~# file ?* # check gcc version
```


##### Setting up a Docker virtual build environment

Build a compilation environment close to the system

- ARM Cortex-A57: arm64v8
- Linux Kernel 3.14.65+

Use DUE to build:

1. docker from arm64v8:debian8
2. docker-arm64v8:debian8: install header which is much closest to linux kernel
   apt search linux-headers
   apt search linux-image
3. docker-arm64v8:debian8: install gcc version 4.9 and switch to 4.9
   apt install gcc-4.9 g++-4.9



#### Compile

##### Compile TPMFactoryUpd

1. Install dependence: openssl >= 1.1.1
2. Modify Makefile:
   1. `CFLAGS+=-I/usr/local/include/openssl`
   2. `LDFLAGS+=-L/usr/local/lib/`
3. Build: `make -j8`


### How to Update Firmware


```bash
# ./TPMFactoryUpd
  **********************************************************************
  *    Infineon Technologies AG   TPMFactoryUpd   Ver 02.03.4733.00    *
  **********************************************************************

Call: TPMFactoryUpd [parameter] [parameter] ...

Parameters:

-? or -help
  Displays a short help page for the operation of TPMFactoryUpd (this screen).
  Cannot be used with any other parameter.

-info
  Displays TPM information related to TPM Firmware Update.
  Cannot be used with -update, -firmware, -config, -tpm12-clearownership,
  -policyhandle, -policyfile, -setmode or -force parameter.

-update <update-type>
  Updates a TPM with <update-type>.
  Possible values for <update-type> are:
   tpm12-PP - TPM1.2 with Physical Presence or Deferred Physical Presence.
   tpm12-ownerauth - TPM1.2 with TPM Owner Authorization.
                     Requires the -ownerauth parameter.
   tpm12-takeownership - TPM1.2 with TPM Ownership taken by TPMFactoryUpd.
                         Use the -ownerauth parameter to overwrite the default
                         secret.
   tpm20-emptyplatformauth - TPM2.0 with platformAuth set to Empty Buffer.
   tpm20-platformpolicy - TPM2.0 with an already set platform policy.
                          Use optional parameters -policyhandle for an
                          external created policy session or -policyfile
                          for a configuration file with policy digests.
                          Without parameter the default policy behavior is
                          used.
   config-file - Updates either a TPM1.2 or TPM2.0 to the firmware version
                 configured in the configuration file.
                 Requires the -config parameter.
  Cannot be used with -info, -tpm12-clearownership or -setmode parameter.

-firmware <firmware-file>
  Specifies the path to the firmware image to be used for TPM Firmware Update.
  Required if -update parameter is given with values tpm*.

-config <config-file>
  Specifies the path to the configuration file to be used for TPM Firmware
  Update. Required if -update parameter is given with value config-file.

-log [<log-file>]
  Optional parameter. Activates logging for TPMFactoryUpd to the log file
  specified by <log-file>. Default value .\TPMFactoryUpd.log is used if
  <log-file> is not given.
  Note: total path and file name length must not exceed 260 characters

-tpm12-clearownership
  Clears the TPM Ownership taken by TPMFactoryUpd.
  Use the -ownerauth parameter to overwrite the default secret.
  Cannot be used with -info, -update, -firmware, -config, -setmode,
  -policyhandle, -policyfile or -force parameter.

-ownerauth <owner-authorization-file>
  Specifies the path to the Owner Authorization file to be used for
  TPM Firmware Update. Required if -tpm12-ownerauth parameter is given.

-setmode <setmode-type>
  Specifies the TPM mode to switch into.
  Possible values for <setmode-type> are:
   tpm20-fwupdate - Switch to firmware update mode.
                    Requires the -firmware parameter.
   tpm20-fwrecovery - Switch to firmware recovery mode.
   tpm20-operational - Switch back to TPM operational mode.
  Cannot be used with -info, -update, -tpm12-clearownership, -config,
  -policyhandle, -policyfile or -force parameter.

-policyhandle [<policyhandle>]
  Optional parameter. Specifies a policy handle as a hexadecimal value of a
  policy session for TPM Firmware Update. Requires the tpm20-platformpolicy
  parameter. Cannot be used with -policyfile parameter.

-policyfile [<policyfile>]
  Optional parameter. Specifies a policy configuration file of policy digests
  utilizing TPM2_PolicyOR command including one policy digest for the TPM
  Firmware Update command. Requires the tpm20-platformpolicy parameter.
  Cannot be used with -policyhandle parameter.

-force
  Allows a TPM Firmware Update onto the same firmware version when
  used with -update parameter.
  Cannot be used with -info, -tpm12-clearownership or -setmode parameter.

-access-mode <mode> <path>
  Optional parameter. Sets the mode the tool should use to connect to
  the TPM device.
  Possible values for <mode> are:
  1 - Memory based access (default value, only supported on x86 based systems
      with PCH TPM support)
  3 - Linux TPM driver. The <path> option can be set to define a device path
      (default value: /dev/tpm0)
# ./TPMFactoryUpd -info
  **********************************************************************
  *    Infineon Technologies AG   TPMFactoryUpd   Ver 02.03.4733.00    *
  **********************************************************************

       TPM information:
       ----------------
       TPM family                        :    2.0
       TPM firmware version              :    7.62.3126.0
       TPM firmware recovery support     :    No
       TPM firmware valid                :    Yes
       TPM operation mode                :    Operational
       TPM platformAuth                  :    Empty Buffer
       Remaining updates                 :    63
# ./TPMFactoryUpd -update tpm20-emptyplatformauth -firmware TPM20_7.62.3126.0_to_TPM20_7.85.4555.0.BIN  # firmware update
  **********************************************************************
  *    Infineon Technologies AG   TPMFactoryUpd   Ver 02.03.4733.00    *
  **********************************************************************

       TPM update information:
       -----------------------
       TPM family                        :    2.0
       TPM firmware version              :    7.62.3126.0
       TPM firmware valid                :    Yes
       TPM operation mode                :    Operational
       TPM platformAuth                  :    Empty Buffer
       Remaining updates                 :    63
       New firmware valid for TPM        :    Yes
       TPM family after update           :    2.0
       TPM firmware version after update :    7.85.4555.0
       TPM chip state after update       :    reset to factory defaults

       Preparation steps:
       TPM2.0 policy session created to authorize the update.

    DO NOT TURN OFF OR SHUT DOWN THE SYSTEM DURING THE UPDATE PROCESS!

       Updating the TPM firmware ...
       Completion: 100 %
       TPM Firmware Update completed successfully.

A system restart is required before the TPM can enter operational mode again.
# ./TPMFactoryUpd -info
  **********************************************************************
  *    Infineon Technologies AG   TPMFactoryUpd   Ver 02.03.4733.00    *
  **********************************************************************

       TPM information:
       ----------------
       TPM family                        :    2.0
       TPM firmware version              :    7.85.4555.0
       TPM firmware recovery support     :    N/A
       TPM firmware valid                :    Yes
       TPM operation mode                :    Firmware update
       TPM platformAuth                  :    N/A
       Remaining updates                 :    N/A

A system restart is required before the TPM can enter operational mode again.
# 
```



## Update by TPMFactoryUpd.efi

1. Get `TPMFactoryUpd.efi` from Supplier/Vendor and copy to U-disk
2. Enter UEFI Shell, switch workspace to `TPMFactoryUpd.efi`'s location
3. Input `TPMFactoryUpd.efi` to get help.


```
FS1:\TPM\> TPMFactoryUpd.efi -update tpm20-emptyplatformauth -firmware TPM20_7.85.4555.0_to_TPM20_7.86.19393.2.BIN
  **********************************************************************
  *    Infineon Technologies AG   TPMFactoryUpd   Ver 02.03.4566.00    *
  **********************************************************************

       TPM update information:
       -----------------------
       TPM family                        :    2.0
       TPM firmware version              :    7.85.4555.0
       TPM firmware valid                :    Yes
       TPM operation mode                :    Operational
       TPM platformAuth                  :    Empty Buffer
       Remaining updates                 :    64
       New firmware valid for TPM        :    Yes
       TPM family after update           :    2.0
       TPM firmware version after update :    7.86.19393.2

       Preparation steps:
       TPM2.0 policy session created to authorize the update.
                 
    DO NOT TURN OFF OR SHUT DOWN THE SYSTEM DURING THE UPDATE PROCESS!

       Updating the TPM firmware ...
       Completion: 100 %
       TPM Firmware Update completed successfully.

A system restart is required before the TPM can enter operational mode again.
```

