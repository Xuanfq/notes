# I2C设备的添加方法

- 静态注册
- 动态注册
- 用户空间注册
- 驱动扫描注册

## 1.静态注册

静态注册就是在架构板级文件或初始化文件中添加i2c设备信息，并注册到特定位置（`__i2c_board_list`链表）上就可以了，如`arm`架构下`board-xxx-yyy.c`文件，x86架构下`xxx-yyy-init-zzz.c`文件。
当系统静态注册i2c控制器（adapter）时，将会去查找这个链表，并实例化i2c设备添加到i2c总线上。注意：一定要赶在i2c控制器注册前将i2c设备信息添加到链表上。

具体实现：

- 1）定义一个` i2c_board_info` 结构体

必须要有名字和设备地址，其他如中断号、私有数据非必须。

```c
static struct i2c_board_info my_tmp75_info = {
    I2C_BOARD_INFO("my_tmp75", 0x48),
};
```

`@my_tmp75`是设备名字，用于匹配i2c驱动。
`@0x48`是i2c设备的基地址。

如果有多个设备，可以定义成结构数组，一次添加多个设备信息。

- 2）注册设备

使用`i2c_register_board_info`函数将`i2c`设备信息添加到特定链表，函数原型如下:

```c
i2c_register_board_info(int busnum, struct i2c_board_info const * info, unsigned n)
{
    devinfo->busnum = busnum; /* 组装i2c总线 */
    devinfo->board_info = *info; /* 绑定设备信息 */
    list_add_tail(&devinfo->list, &__i2c_board_list); /* 将设备信息添加进链表中 */
}
```

`@busnum`：哪一条总线，也就是选择哪一个i2c控制器（adapter）
`@info`：i2c设备信息，就是上面的结构体
`@n`：info中有几个设备

将在`i2c_register_adapter`函数中使用到

```c
static int i2c_register_adapter(struct i2c_adapter *adap)
{
    //…
    if (adap->nr < __i2c_first_dynamic_bus_num)
        i2c_scan_static_board_info(adap);
    //…
}

static void i2c_scan_static_board_info(struct i2c_adapter *adapter)
{
    struct i2c_devinfo        *devinfo;

    down_read(&__i2c_board_lock);
    list_for_each_entry(devinfo, &__i2c_board_list, list) {
        if (devinfo->busnum == adapter->nr && !i2c_new_device(adapter, &devinfo->board_info))
            dev_err(&adapter->dev,"Can't create device at 0x%02x\n",devinfo->board_info.addr);
    }
    up_read(&__i2c_board_lock);
}
```

而调用`i2c_register_adapter`函数的有两个地方，分别是`i2c_add_adapter`函数和`i2c_add_numbered_adapter`函数，但`i2c_add_adapter`函数中是动态分配的总线号，`adapter->nr`一定比`__i2c_first_dynamic_bus_num`变量大，因此不会进入到`i2c_scan_static_board_info`函数，所以只有`i2c_add_numbered_adapter`最终使用到，而这个函数是`i2c`控制器静态注册时调用的，因此静态注册i2c设备必须赶在i2c控制器注册前添加。

## 2.动态注册

动态注册i2c设备可以使用两个函数，分别为`i2c_new_device`函数与`i2c_new_probed_device`函数，它们两区别是：

- `i2c_new_device`：不管i2c设备是否真的存在，都实例化i2c_client。
- `i2c_new_probed_device`：调用probe函数去探测i2c地址是否有回应，存在则实例化`i2c_client`。如果自己不提供probe函数的话，使用默认的i2c_default_probe函数。



- 1）使用`i2c_new_device`注册设备

```c
#include <linux/module.h>
#include <linux/init.h>
#include <linux/i2c.h>
#include <linux/platform_device.h>

static struct i2c_board_info my_tmp75_info = {
    I2C_BOARD_INFO("my_tmp75", 0x48),//这个名字很重要，用于匹配I2C驱动
};

static struct i2c_client *my_tmp75_client;

static int my_tmp75_init(void)
{
    struct i2c_adapter *i2c_adapt;
    int ret = 0;

    i2c_adapt = i2c_get_adapter(6);
    if (i2c_adapt == NULL)
    {
        printk("get adapter fail!\n");
        ret = -ENODEV;
    }
     
    my_tmp75_client = i2c_new_device(i2c_adapt, &my_tmp75_info);
    if (my_tmp75_client == NULL)
    {
        printk("i2c new fail!\n");
        ret = -ENODEV;
    }
     
    i2c_put_adapter(i2c_adapt);
     
    return ret;
}

static void my_tmp75_exit(void)
{
    i2c_unregister_device(my_tmp75_client);
}

module_init(my_tmp75_init);
module_exit(my_tmp75_exit);

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("caodongwang");
MODULE_DESCRIPTION("This my i2c device for tmp75");
```

- 2）使用`i2c_new_probed_device`注册设备

```c
#include <linux/module.h>
#include <linux/init.h>
#include <linux/i2c.h>
#include <linux/platform_device.h>

static struct i2c_client *my_tmp75_client;

static const unsigned short addr_list[] = { 0x46, 0x48, I2C_CLIENT_END };//必须以I2C_CLIENT_END宏结尾

static int my_i2c_dev_init(void)
{
    struct i2c_adapter *i2c_adap;
    struct i2c_board_info my_i2c_dev_info;

    memset(&my_i2c_dev_info, 0, sizeof(struct i2c_board_info));   
    strlcpy(my_i2c_dev_info.type, "my_tmp75", I2C_NAME_SIZE);
     
    i2c_adap = i2c_get_adapter(0);
    my_tmp75_client = i2c_new_probed_device(i2c_adap, &my_i2c_dev_info, addr_list, NULL);//只会匹配到0x48地址
    i2c_put_adapter(i2c_adap);
     
    if (my_tmp75_client)
        return 0;
    else
        return -ENODEV;
}

static void my_i2c_dev_exit(void)
{
    i2c_unregister_device(my_tmp75_client);
}

module_init(my_i2c_dev_init);
module_exit(my_i2c_dev_exit);

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("caodongwang");
MODULE_DESCRIPTION("This my i2c device for tmp75");
```

## 3.用户空间注册

- 1）创建i2c设备

```c
echo i2c_test 0x48 > /sys/bus/i2c/devices/i2c-6/new_device  // i2c_test 是 compatible 中的值之一
```

使用这种方法创建的i2c设备会挂在`i2c_adapter`的链表上，为了方便用户空间删除i2c设备。

注意：是在`i2c-x`目录下，而`/sys/bus/i2c/devices/x-xxxx`是已经创建了的有设备的。

- 2）删除设备

```c
echo 0x48 > /sys/bus/i2c/devices/i2c-6/delete_device
```

删除设备只能删除在用户空间创建的i2c设备！


在i2c控制器注册时，会在`/sys/bus/i2c/devices/`目录下创建`i2c-x`设备文件，并且设置它的属性，而`new_device`和`delete_device`均是它的属性，写`new_device`时会调用`i2c_sysfs_new_device`函数，内部再调用`i2c_new_device`函数

```c
static DEVICE_ATTR(new device, S_IWUSR, NULL, i2c_sysfs_new_device);
```

写delete_device时会调用i2c_sysfs_delete_device函数，内部再调用i2c_unregister_device函数

```c
static DEVICE_ATTR_IGNORE_LOCLDEP(delete_device, S_IWUSR, NULL, i2c_sysfs_delete_device);
```



## 4.驱动扫描注册

i2c驱动注册时会使用两种匹配方法去寻找i2c设备，代码如下：

```c
int i2c_register_driver(struct module *owner, struct i2c_driver *driver)
{
    driver->driver.bus = &i2c_bus_type;//添加总线

	/* When registration returns, the driver core
	 * will have called probe() for all matching-but-unbound devices.
	 */
    res = driver_register(&driver->driver);//驱动注册核心函数(通用驱动程序初始化后)，注意只传入了driver成员
     
    /* 遍历所有挂在总线上的iic适配器，用它们去探测driver中指定的iic设备地址列表 */
    i2c_for_each_dev(driver, __process_new_driver);
}
```

分析`i2c_for_each_dev`函数:

```c
int i2c_for_each_dev(void *data, int (*fn)(struct device *, void *))
{
    int res;
    mutex_lock(&core_lock);
    res = bus_for_each_dev(&i2c_bus_type, NULL, data, fn);
    mutex_unlock(&core_lock);
    return res;
}

int bus_for_each_dev(struct bus_type *bus, struct device *start,
     void *data, int (*fn)(struct device *, void *))
{
    struct klist_iter i;
    struct device *dev;
    int error = 0;
    if (!bus || !bus->p)
        return -EINVAL;

    klist_iter_init_node(&bus->p->klist_devices, &i, (start ? &start->p->knode_bus : NULL));
     
    while (!error && (dev = next_device(&i)))
        error = fn(dev, data);
    klist_iter_exit(&i);
    return error;
}
```

最终调用`__process_new_driver`函数，使用i2c总线上所有i2c适配器去探测i2c驱动中的设备地址数组！

```c
static int __process_new_driver(struct device *dev, void *data)
{
    if (dev->type != &i2c_adapter_type)
        return 0;
    return i2c_do_add_adapter(data, to_i2c_adapter(dev));
}
```

入口先判断传入的设备是不是i2c适配器（i2c控制器），i2c适配器和i2c设备一样，都会挂在i2c总线上，它们是通过dev->type项区分的！

```c
static int i2c_do_add_adapter(struct i2c_driver *driver, struct i2c_adapter *adap)
{
    /* Detect supported devices on that bus, and instantiate them */
    i2c_detect(adap, driver);
    …
}
```

最终调用i2c_detect函数，函数简化后如下：

```c
static int i2c_detect(struct i2c_adapter *adapter, struct i2c_driver *driver)
{
    int adap_id = i2c_adapter_id(adapter);

    address_list = driver->address_list;
    if (!driver->detect || !address_list)
        return 0;
    
    temp_client = kzalloc(sizeof(struct i2c_client), GFP_KERNEL);
    itemp_client->adapter = adapter;
     
    for (i = 0; address_list[i] != I2C_CLIENT_END; i += 1)
    {
        temp_client->addr = address_list[i];
        err = i2c_detect_address(temp_client, driver);
        if (unlikely(err))
            break;
    }
}
```

如果i2c驱动的设备地址数组为空或detect函数不存在，则结束返回，否则临时实例化一个temp_client设备赋值adapter为当前i2c控制器，然后在使用该i2c控制器去探测i2c驱动设备地址数组中的所有地址，关键函数是 `i2c_detect_address`如下（简化后）：

```c
static int i2c_detect_address(struct i2c_client *temp_client, struct i2c_driver *driver)
{
    struct i2c_board_info info;
    struct i2c_adapter *adapter = temp_client->adapter;
    int addr = temp_client->addr;
    int err;

    err = i2c_check_7bit_addr_validity_strict(addr);//检查地址是否有效，即7位有效地址
    if (err) {
        return err;
    }
     
    if (i2c_check_addr_busy(adapter, addr))//跳过已经使用的i2c设备
        return 0;
     
    if (!i2c_default_probe(adapter, addr))//检查这个地址是否有回应
        return 0;
     
    memset(&info, 0, sizeof(struct i2c_board_info));
    info.addr = addr;
    err = driver->detect(temp_client, &info);
    if (err) {
        return err == -ENODEV ? 0 : err;
    }
     
    if (info.type[0] == '\0')
    {
    }
    else
    {
        struct i2c_client *client;
        client = i2c_new_device(adapter, &info);
        if (client)
            list_add_tail(&client->detected, &driver->clients);
    }
}
```

首先检查有效性、是否有设备回应、是否被使用，之后初始化了`i2c_board_info`结构，注意只初始化了地址（实例化设备必须还要名字），然后调用了i2c驱动中的`detect`函数，如果成功则调用`i2c_new_device`函数真正实例化i2c设备，并且将i2c设备挂在i2c驱动的链表上！注意：只有这种方式添加的i2c设备才会挂在驱动的链表上！

仔细思考上面就能发现，i2c驱动中的detect函数必须要填写`i2c_board_info`结构体中`name`，`i2c_new_device`才能实例化i2c设备。

所以，使用i2c驱动扫描注册设备时，需要按如下格式编写驱动:

```c
#include <linux/module.h>
#include <linux/init.h>
#include <linux/i2c.h>
#include <linux/platform_device.h>

static int __devinit my_i2c_drv_probe(struct i2c_client *client, const struct i2c_device_id *id)
{
    return 0;
}

static int __devexit my_i2c_drv_remove(struct i2c_client *client)
{
    return 0;
}

static const struct i2c_device_id my_dev_id_table[] = {
    { "my_i2c_dev", 0 },
    {}
};//这里的名字很重要，驱动第一种匹配设备的方式要用到

static int my_i2c_drv_detect(struct i2c_client *client, struct i2c_board_info *info)
{
    /* 能运行到这里, 表示该addr的设备是存在的
     * 但是有些设备单凭地址无法分辨(A芯片的地址是0x50, B芯片的地址也是0x50)
     * 还需要进一步读写I2C设备来分辨是哪款芯片，自己写方法
     * detect就是用来进一步分辨这个芯片是哪一款，并且设置info->type，也就是设备名字
     */
    printk("my_i2c_drv_detect: addr = 0x%x\n", client->addr);

    /* 进一步判断是哪一款 */
    strlcpy(info->type, "my_i2c_dev", I2C_NAME_SIZE);
    return 0;
}

static const unsigned short addr_list[] = { 0x46, 0x48, I2C_CLIENT_END };//必须使用I2C_CLIENT_END宏结尾

/* 1. 分配/设置i2c_driver */
static struct i2c_driver my_i2c_driver = {
    .class  = I2C_CLASS_HWMON, /* 表示去哪些适配器上找设备，不是对应类将不会调用匹配 */
    .driver        = {
        .name        = "my_i2c_dev",
        .owner        = THIS_MODULE,
    },
    .probe                = my_i2c_drv_probe,
    .remove        = __devexit_p(my_i2c_drv_remove),
    .id_table        = my_dev_id_table,
    .detect     = my_i2c_drv_detect,  /* 用这个函数来检测设备确实存在 ，并填充设备名字*/
    .address_list        = addr_list,   /* 这些设备的地址 */
};

static int my_i2c_drv_init(void)
{
    /* 2. 注册i2c_driver */
    i2c_add_driver(&my_i2c_driver);

    return 0;
}

static void my_i2c_drv_exit(void)
{
    i2c_del_driver(&my_i2cc_driver);
}

module_init(my_i2c_drv_init);
module_exit(my_i2c_drv_exit);
MODULE_LICENSE("GPL");
```