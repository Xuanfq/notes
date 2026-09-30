# I2C Code

## Data Structure

- `i2c_device_id`

```c
// mod_devicetable.h
struct i2c_device_id {
	char name[I2C_NAME_SIZE];
	kernel_ulong_t driver_data;	/* Data private to the driver */ // Data Address
};
```

