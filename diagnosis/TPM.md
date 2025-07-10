# TPM


## Diagnosis

### Preparation

#### TPMFactoryUpd 工具安装与使用

Source Code: https://github.com/iavael/infineon-firmware-updater.git

Reference `Firmware - TPM`

Usage:

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


#### TPM2 工具安装

源码：`git clone https://github.com/tpm2-software/tpm2-tools.git`
编译：https://tpm2-tools.readthedocs.io/en/latest/INSTALL/

Or

```bash
sudo apt-get install tpm2-tools
```



#### TPM 重启

关机: `shutdown`
开机：`startup`

Or：`systemctl restart tpm2-abrmd.service`?

#### 获取 TPM 信息/固定属性

`tpm2 getcap properties-fixed`

- Family Version: TPM2_PT_FAMILY_INDICATOR
- Manufacturer Code: TPM2_PT_MANUFACTURER
- Vendor Model: TPM2_PT_VENDOR_STRING_1 + TPM2_PT_VENDOR_STRING_2 + TPM2_PT_VENDOR_STRING_3
- Revision: TPM2_PT_REVISION [Option]

```bash
# tpm2 getcap properties-fixed 
TPM2_PT_FAMILY_INDICATOR:
  raw: 0x322E3000
  value: "2.0"
TPM2_PT_LEVEL:
  raw: 0
TPM2_PT_REVISION:
  raw: 0x8A
  value: 1.38
TPM2_PT_DAY_OF_YEAR:
  raw: 0x12F
TPM2_PT_YEAR:
  raw: 0x7E3
TPM2_PT_MANUFACTURER:
  raw: 0x4E544300
  value: "NTC"
TPM2_PT_VENDOR_STRING_1:
  raw: 0x4E504354
  value: "NPCT"
TPM2_PT_VENDOR_STRING_2:
  raw: 0x37357800
  value: "75x"
TPM2_PT_VENDOR_STRING_3:
  raw: 0x22212134
  value: ""!!4"
TPM2_PT_VENDOR_STRING_4:
  raw: 0x726C7300
  value: "rls"
TPM2_PT_VENDOR_TPM_TYPE:
  raw: 0x0
TPM2_PT_FIRMWARE_VERSION_1:
  raw: 0x70002
TPM2_PT_FIRMWARE_VERSION_2:
  raw: 0x20000
TPM2_PT_INPUT_BUFFER:
  raw: 0x400
TPM2_PT_HR_TRANSIENT_MIN:
  raw: 0x5
TPM2_PT_HR_PERSISTENT_MIN:
  raw: 0x7
TPM2_PT_HR_LOADED_MIN:
  raw: 0x5
TPM2_PT_ACTIVE_SESSIONS_MAX:
  raw: 0x40
TPM2_PT_PCR_COUNT:
  raw: 0x18
TPM2_PT_PCR_SELECT_MIN:
  raw: 0x3
TPM2_PT_CONTEXT_GAP_MAX:
  raw: 0xFF
TPM2_PT_NV_COUNTERS_MAX:
  raw: 0x0
TPM2_PT_NV_INDEX_MAX:
  raw: 0x800
TPM2_PT_MEMORY:
  raw: 0x6
TPM2_PT_CLOCK_UPDATE:
  raw: 0x400000
TPM2_PT_CONTEXT_HASH:
  raw: 0xC
TPM2_PT_CONTEXT_SYM:
  raw: 0x6
TPM2_PT_CONTEXT_SYM_SIZE:
  raw: 0x100
TPM2_PT_ORDERLY_COUNT:
  raw: 0xFF
TPM2_PT_MAX_COMMAND_SIZE:
  raw: 0x800
TPM2_PT_MAX_RESPONSE_SIZE:
  raw: 0x800
TPM2_PT_MAX_DIGEST:
  raw: 0x30
TPM2_PT_MAX_OBJECT_CONTEXT:
  raw: 0x714
TPM2_PT_MAX_SESSION_CONTEXT:
  raw: 0x148
TPM2_PT_PS_FAMILY_INDICATOR:
  raw: 0x1
TPM2_PT_PS_LEVEL:
  raw: 0x0
TPM2_PT_PS_REVISION:
  raw: 0x104
TPM2_PT_PS_DAY_OF_YEAR:
  raw: 0x0
TPM2_PT_PS_YEAR:
  raw: 0x0
TPM2_PT_SPLIT_MAX:
  raw: 0x80
TPM2_PT_TOTAL_COMMANDS:
  raw: 0x71
TPM2_PT_LIBRARY_COMMANDS:
  raw: 0x68
TPM2_PT_VENDOR_COMMANDS:
  raw: 0x9
TPM2_PT_NV_BUFFER_MAX:
  raw: 0x400
TPM2_PT_MODES:
  raw: 0x1
  value: TPMA_MODES_FIPS_140_2
```

#### TPM nvram write & read certificate

1. 清除nvram索引：`tpm2 clear`
2. 列出nvram索引：`tpm2 getcap handles-nv-index`
    ```bash
    # ./tpm2 getcap handles-nv-index
    - 0x1C00002
    - 0x1C0000A
    ```
3. 定义nvram空间与索引：`tpm2 nvdefine 0x1500015 -C o -s 1424 -a 0x2060006`
    ```bash
    # ./tpm2 nvdefine --help
    Usage: nvdefine [<options>] <arguments>
    Where <options> are:
        [ -C | --hierarchy=<value>] [ -s | --size=<value>] [ -a | --attributes=<value>] [ -P | --hierarchy-auth=<value>]
        [ -g | --hash-algorithm=<value>] [ -p | --index-auth=<value>] [ -L | --policy=<value>] [ --cphash=<value>]
        [ --rphash=<value>] [ -S | --session=<value>]
    ```
4. 写入证书数据到nvram：`tpm2 nvwrite -Q 0x1500015 -C o -i ./Test.crt`
    ```bash
    # ./tpm2 nvwrite --help
    Usage: nvwrite [<options>] <arguments>
    Where <options> are:
        [ -C | --hierarchy=<value>] [ -P | --auth=<value>] [ -i | --input=<value>] [ --offset=<value>]
        [ --cphash=<value>]
    ```
5. 读取证书数据到指定文件：`tpm2 nvread -Q 0x1500015 -C o -o ./NvRead.crt`
    ```bash
    # ./tpm2 nvread --help
    Usage: nvread [<options>] <arguments>
    Where <options> are:
        [ -C | --hierarchy=<value>] [ -o | --output=<value>] [ -s | --size=<value>] [ --offset=<value>]
        [ --cphash=<value>] [ -P | --auth=<value>]
    ```
6. 验证证书读写是否一致：`diff -u ./Test.crt ./NvRead.crt`
7. 取消定义nvram空间与索引：`tpm2 nvundefine 0x1500015`


#### TPM selftest

1. Test: `tpm2 selftest -f`
2. Get Result: `tpm2 gettestresult`

```bash
# ./tpm2 selftest -f
# ./tpm2 gettestresult
status:   success
data:   aa550000000001fe010004000042f50200a80000002900000003000000030000000c0000000c0000000b0000000300000003000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000b00000002000000020000000b0000000b0000000c000000020000000200000002000000090000000c0000000b0000000b0000000b0000000b0000000b0000000b0000000b0000000b0000000b0000000b04000100030010000010000008a96013b20922ff0c5f21
# ./tpm2 selftest --help
Usage: selftest [<options>]
Where <options> are:
    [ -f | --fulltest]
# ./tpm2 gettestresult --help
Usage: gettestresult
# 
```


### Diagnosis

Reference About.








