# mux

i2c mux (多路复用器)

## Usage

### Channel

通过 I2C 总线向 PCA9548 的控制寄存器(0x00)写入相应的值来选择通道，

控制寄存器的每一位对应一个通道，置位为 “1” 表示选择该通道，清零为 “0” 表示关闭该通道，

若要选择通道 0，可向控制寄存器写入二进制值 00000001；

选择通道 1，则写入 00000010，以此类推。

e.g. PCA9548's bus is 0 and addr is 0x70:
```
# reset/close channel:
i2cset -f -y 0 0x70 0x00 0
# select channel 0:
i2cset -f -y 0 0x70 0x00 0x01
# select channel 1:
i2cset -f -y 0 0x70 0x00 0x02
# select channel 2:
i2cset -f -y 0 0x70 0x00 0x04
# ...
```

### Read / Write Slave Device after select channel

After select channel, just access the slave device as normal i2c:

e.g. 
```bash
# 读取从设备地址0x50的寄存器0x00
i2cget -y 0 0x50 0x00
# 向从设备地址0x50的寄存器0x01写入0xFF
i2cset -y 0 0x50 0x01 0xFF
```

