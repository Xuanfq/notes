# EEPROM - TLV & FRU Info

[TLV](https://opencomputeproject.github.io/onie/design-spec/hw_requirements.html)
[FRU Info](https://www.intel.com/content/dam/www/public/us/en/documents/specification-updates/ipmi-platform-mgt-fru-info-storage-def-v1-0-rev-1-3-spec-update.pdf)

FRU (Field Replaceable Unit) 

`TLV` 和 `FRU Info` 通常放在 `eeprom` 里。

若是使用`onie`的交换机，`smbios`还和`onie tlv`的信息放在一起：
- tlv(max size:2048bytes, 16K bits): 0-n (n, i.e. 一般大小1024bytes, 8K bits足够)
- smbios: n-eeprom_max (max eeprom, i.e. 8092bytes, 64K bits) (一般大小1024bytes, 8K bits足够, 此时max=(8+8)(K bits))


## TLV

### TLV 格式定义

- 类型代码(Type)：这是一个单字节，用于定义值字段的类型和格式。这些类型的定义见下表。由于这些类型代码可能会随时间推移而添加，因此无法理解特定类型代码的软件应将值字段视为不透明数据，不为其类型或格式赋予任何含义。类型代码 0x00 和 0xFF 为保留代码，永远不会使用。这样最多可以有 254 个类型代码。
- 长度(Length)：这是一个单字节，包含`值(Value)字段`的字节数。此字段的有效值范围为 0 到 255。长度为零表示此类型代码没有关联的值字段。在这种情况下，长度字段后面的字节是下一个 TLV 的第一个字节，即其​​类型代码字段。
- 值(Value)：此字段包含指定类型代码的值。其大小范围为 0 到 255 字节。此字段的格式将针对每种类型代码进行定义，具体如下。由于每个 TLV 都包含一个长度字段，因此 ASCII 字符串不以 NULL 结尾，除非另有说明（如下所述）。


#### 存储结构

Field Name | Size in Bytes | Value
--|--|--
ID String | 8 | "TlvInfo\0"
Header Version | 1 | 0x01
Total Length | 2 | Total number of bytes that follow
TLV 1 | Varies | The data for TLV 1
TLV 2 | Varies | The data for TLV 2
….. | ….. | …..
TLV N | Varies | The data for TLV N
CRC-32 TLV | 6 | Type = 0xFE, Length = 4, Value = 4 byte CRC-32, CRC作用范围是[0, $eeprom_len-4]

> Notice: 禁用/保留 Type 0x00 & 0xFF


#### 代码表达

```c
struct __attribute__ ((__packed__)) tlvinfo_header_s { 
	char    signature[8];   /* 0x00 - 0x07 EEPROM Tag "TlvInfo" */
	u8      version;  /* 0x08        Structure version */     
	u16     totallen; /* 0x09 - 0x0A Length of all data which follows */
}; 
```

```c
struct __attribute__ ((__packed__)) tlvinfo_tlv_s {
     u8  type; 
	 u8  length;      
	 u8  value[0]; 
};
```

> Notice: 所有数据排列紧凑，一旦其中一个值的长度改变了，后面的数据往后延，且需更新CRC


## FRU Info

### 格式定义

#### 存储结构

Refer: https://www.intel.com/content/dam/www/public/us/en/documents/specification-updates/ipmi-platform-mgt-fru-info-storage-def-v1-0-rev-1-3-spec-update.pdf

- Common Header
- Internal Use Area
  - Field 1
  - Field 2
  - ...
- Chassis Info Area
  - ...
- Board Info Area
- Product Info Area

1. `type/length`类型的Field对应的数据Field长度才会变换，当然一般定了就不会变。
2. 按顺序存放，就算是没有值也会保留所需的存储空间。


#### 代码表达

```c
typedef struct fru_info {
    int32_t fru_area_offset;  // bytes
    int32_t fru_area_len;
    char   *field_name;       
    int32_t field_offset;  // bytes
} fru_info_t;

const fru_info_t g_fru_info[] = {
    //Common Header
    {0, 8, "Common Header Format Version"      , 0},
    {0, 8, "Interal Use Area Starting Offset"  , 1},
    {0, 8, "Chassis Info Area Starting Offset" , 2},
    {0, 8, "Board Info Area Starting Offset"   , 3},
    {0, 8, "Product Info Area Starting Offset" , 4},
    {0, 8, "MultiRecord Area Starting Offset"  , 5},
    {0, 8, "Head PAD"                          , 6},
    {0, 8, "Common Header Checksum"            , 7},
    {0, 0, NULL, 8},

    //Intel Use Area
    {8, 64, "Internal Use Area Format Version"    , 0 },
    {8, 64, "Internal Use Area Length"            , 1 },
    {8, 64, "COM-E Base Spec Revision type/length", 2 },
    {8, 64, "COM-E Base Spec Revision data"       , 3 },
    {8, 64, "COME-E Connector Type type/length"   , 4 },
    {8, 64, "COME-E Connector Type data"          , 5 },
    {8, 64, "COM-E H/W Revision type/length"      , 6 },
    {8, 64, "COM-E H/W Revision data"             , 7 },
    {8, 64, "Customer Name type/length"           , 8 },
    {8, 64, "Customer Name string"                , 9 },
    {8, 64, "MAC Address type/length"             , 51},
    {8, 64, "MAC Address Data"                    , 52},
    {8, 64, "Internal FRU File ID type/length"    , 58},
    {8, 64, "Internal FRU File ID"                , 59},
    {8, 64, "Internal End of Field"               , 61},
    {8, 64, "Internal PAD (Optional)"             , 62},
    {8, 64, "Intenal Use Area Checksum"           , 63},
    {0, 0, NULL, 64},

    //Chassis Info Area
    {72, 192, "Chassis Info Area Format Version" , 0  },
    {72, 192, "Chassis Info Area Length"         , 1  },
    {72, 192, "Chassis Type"                     , 2  },
    {72, 192, "Chassis Part Number type/length"  , 3  },
    {72, 192, "Chassis Part Number string"       , 4  },
    {72, 192, "Chassis Serial Number type/length", 36 },
    {72, 192, "Chassis Serial Number string"     , 37 },
    {72, 192, "Chassis Manufacture type/length"  , 69 },
    {72, 192, "Chassis Manufacturer"       , 70 },
    {72, 192, "Chassis Version type/length"      , 102},
    {72, 192, "Chassis Version"           , 103},
    {72, 192, "Chassis Asset Tag type/length"    , 135},
    {72, 192, "Chassis Asset Tag"         , 136},
    {72, 192, "Chassis End of Field"             , 189},
    {72, 192, "Chassis PAD (Optional)"           , 190},
    {72, 192, "Chassis Info Area Checksum"       , 191},
    {0, 0, NULL, 192},

    //Board Info Area
    {264, 256, "Board Info Area Format Version"        , 0  },
    {264, 256, "Board Info Area Length"                , 1  },
    {264, 256, "Board Language Code"                   , 2  },
    {264, 256, "Board Mgt. Date/Time"                  , 3  },
    {264, 256, "Board Manufacturer type/length"        , 6  },
    {264, 256, "Board Manufacturer"             , 7  },
    {264, 256, "Board Product Name type/length"        , 39 },
    {264, 256, "Board Product"             , 40 },
    {264, 256, "Board Serial Number type/length"       , 72 },
    {264, 256, "Board Serial Number"            , 73 },
    {264, 256, "Board Part Number type/length"         , 105},
    {264, 256, "Board Part Number String"              , 106},
    {264, 256, "Board FRU File ID type/length"         , 138},
    {264, 256, "Board FRU File ID"                     , 139},
    {264, 256, "Board Revision type/length"            , 141},
    {264, 256, "Board Version"                 , 142},
    {264, 256, "Board Asset Tag type/length"                       , 174},
    {264, 256, "Board Asset Tag"                , 175},
    {264, 256, "Board Location In Chassis type/length" , 207},
    {264, 256, "Board Location In Chassis"      , 208},
    {264, 256, "Board End of Field"                    , 253},
    {264, 256, "Board PAD (Optional)"                  , 254},
    {264, 256, "Board Info Area Checksum"              , 255},
    {0, 0, NULL, 256},

    //Product Info Area
    {520, 288, "Product Info Area Format Version"  , 0  },
    {520, 288, "Product Info Area Length"          , 1  },
    {520, 288, "Product Language Code"             , 2  },
    {520, 288, "Product Manufacture Name type/length" , 3  },
    {520, 288, "System Manufacturer"  , 4  },
    {520, 288, "Product Name type/length"          , 36 },
    {520, 288, "System Product"               , 37 },

    {520, 288, "Product Part Number type/length"   , 69 },
    {520, 288, "Product Part Number String"        , 70 },
    {520, 288, "Product Version type/length"       , 102},
    {520, 288, "System Version"            , 103},
    {520, 288, "Product Serial Number type/length" , 135},
    {520, 288, "System Serial Number"      , 136},
    {520, 288, "Product Asset Tag type/length"     , 168},
    {520, 288, "Product Asset Tag String"          , 169},
    {520, 288, "Product FRU File ID type/length"   , 201},
    {520, 288, "Product FRU File ID"               , 202},
    {520, 288, "ProductSystem UUID type/length"    , 204},
    {520, 288, "System UUID"                 , 205},
    {520, 288, "Product Sku Number type/length"    , 221},
    {520, 288, "System SKU Number"         , 222},
    {520, 288, "Product Family Name type/length"   , 254},
    {520, 288, "System Family Name"        , 255},
    {520, 288, "Product End of Field"              , 285},
    {520, 288, "Product PAD (Optional)"            , 286},
    {520, 288, "Product Info Area Checksum"        , 287},
    {0, 0, NULL, 288}
};
```



## EEPROM

https://www.giantec-semi.com/juchen1123/uploads/pdf/GT24C64_DS_Cu.pdf
https://ww1.microchip.com/downloads/en/DeviceDoc/I2C%20Serial%20EE%20Family%20Data%20Sheet%2021930C.pdf

### 读

读取偏移为`0x$hightreg$lowreg`(16bit)的数据：
```shell
i2cset -y -f $bus $addr $hightreg $lowreg
i2cget -y -f $bus $addr  # 循环执行该指令时，默认读取下一个字节 (offset/reg + 1)
```

### 写

写入 8bit `data`到偏移为`0x$hightreg$lowreg`的地址：
```shell
i2cset -y -f $bus $addr $hightreg ($data << 8 | $lowreg) w
```
i.e. 写入`0x12`到`0x856`地址：`i2cset -y -f $bus $addr 0x08 0x1256 w`
