# Linux Kernel Printk

内核消息`/proc/sys/kernel/printk`用于动态修改 Linux 内核的 ​​printk 日志级别​​，控制内核消息（如 dmesg 输出）的打印行为。

文件内容格式：<console_loglevel> <default_loglevel> <minimum_loglevel> <default_console_loglevel>

i.e.

```sh
echo "5 4 1 5" > /proc/sys/kernel/printk
```
- **作用**：向 `/proc/sys/kernel/printk` 写入 `"5 4 1 5"`，设置 4 个日志级别参数。
- **格式**：`<console_loglevel> <default_loglevel> <minimum_loglevel> <default_console_loglevel>`
- **说明**：
  1. **控制台仅显示级别 0-5 的消息**（`KERN_EMERG` 到 `KERN_NOTICE`），忽略 `INFO` 和 `DEBUG` 信息。
  2. 未指定级别的 printk 默认使用级别 4（`KERN_WARNING`）。
  3. 允许设置的最低级别为 1（防止误设为 0 导致日志完全关闭）。
  4. 控制台初始级别为 5（与参数 1 一致）。
---

### **参数含义**
| 参数位置 | 名称 | 默认值 | 作用 |
|----------|------|-------|------|
| 1 | `console_loglevel` | 7 | **控制台日志级别**：优先级高于此值的消息会打印到控制台。 |
| 2 | `default_loglevel` | 7 | **默认日志级别**：未明确指定级别的 printk 消息使用的优先级。 |
| 3 | `minimum_loglevel` | 1 | **最低允许级别**：允许设置的最小日志级别（内核强制限制）。 |
| 4 | `default_console_loglevel` | 7 | **默认控制台级别**：启动时控制台的初始日志级别。 |

---

### **日志级别对照表**
| 级别值 | 宏定义 | 说明 |
|--------|--------|------|
| 0 | `KERN_EMERG` | 系统不可用（最高优先级） |
| 1 | `KERN_ALERT` | 必须立即处理 |
| 2 | `KERN_CRIT` | 严重错误 |
| 3 | `KERN_ERR` | 错误条件 |
| 4 | `KERN_WARNING` | 警告条件 |
| 5 | `KERN_NOTICE` | 正常但重要的事件 |
| 6 | `KERN_INFO` | 提示信息 |
| 7 | `KERN_DEBUG` | 调试信息（最低优先级） |


---

### 典型应用场景
1. **减少控制台刷屏**  
   在生产环境中屏蔽调试信息（避免日志淹没控制台）：
   ```sh
   echo "4 4 1 7" > /proc/sys/kernel/printk  # 仅显示 0-4 级（EMERG~WARNING）
   ```

2. **调试内核驱动**  
   临时启用调试日志：
   ```sh
   echo "7 7 1 7" > /proc/sys/kernel/printk  # 显示所有级别
   ```

3. **系统启动时**  
   在 `/etc/sysctl.conf` 中永久设置：
   ```ini
   kernel.printk = 5 4 1 5
   ```

---

### 注意事项
1. **权限要求**  
   - 需要 `root` 权限才能修改 `/proc/sys/kernel/printk`。

2. **临时性修改**  
   - 通过 `echo` 写入的参数在重启后失效，需通过 `sysctl` 或配置文件永久生效。

3. **级别范围**  
   - 参数 3（`minimum_loglevel`）通常为 `1`，若尝试设置更低值（如 `0`）会被内核自动修正。

4. **内核版本差异**  
   - 某些旧版本内核可能仅支持 3 个参数（忽略第 4 个）。

---

### 查看当前设置
```sh
cat /proc/sys/kernel/printk
```
输出示例：
```
7    4    1    7
```

---

### 总结
此文件可动态调整 printk 级别，灵活控制内核日志的详细程度，尤其适用于：
- **抑制非关键消息**（如生产服务器）
- **聚焦调试信息**（如开发驱动程序）
- **平衡日志量与系统性能**

如需永久生效，建议结合 `sysctl` 或 `/etc/sysctl.conf` 配置。




