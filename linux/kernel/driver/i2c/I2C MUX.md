# I2C MUX

I2C多路复用器

- Base Kernel: 5.4.40

## i2c-mux-pca954x

在Linux中，加载该设备后：
- 在文件系统中会出现`channelx`目录，代表各个通道的设备目录。
- `idle_state`是通道选择，其值为数值`MUX_IDLE_AS_IS(-1), MUX_IDLE_DISCONNECT(-2) or >= 0 for channel`。




