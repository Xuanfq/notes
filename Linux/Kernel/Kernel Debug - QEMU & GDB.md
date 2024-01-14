# Kernel Debug - QEMU & GDB

- Kernel
  - bzImage(x86_64)
- GDB
  - x86_64 Version
- QEMU
  - qemu-system-x86_64

## Kernel Compile

- bzImage(x86_64)
- 编译时开启内核调试选项
  - CONFIG_DEBUG_INFO (make menuconfig -> Kernel hacking -> Compile-time checks and compiler options -> Rely on the toolchain's implicit default DWARF version)
- 结果
  - vmlinux(ELF 文件)
    - file vmlinux
      ```sh
      aiden@Xuanooo:~/kernel/linux-5.19$ ls
      COPYING         System.map  kernel                   security
      CREDITS         arch        lib                      sound
      Documentation   block       mm                       tools
      Kbuild          certs       modules-only.symvers     usr
      Kconfig         crypto      modules.builtin          virt
      LICENSES        drivers     modules.builtin.modinfo  vmlinux
      MAINTAINERS     fs          modules.order            vmlinux.o
      Makefile        include     net                      vmlinux.symvers
      Module.symvers  init        samples
      README          ipc         scripts
      aiden@Xuanooo:~/kernel/linux-5.19$ file vmlinux
      vmlinux: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, BuildID[sha1]=a5022e8769502dc96f217c02fd5cc290e1f5c83d, with debug_info, not stripped
      aiden@Xuanooo:~/kernel/linux-5.19$
      ```
  - System.map(符号映射表)
    - vim System.map
      ```sh
      aiden@Xuanooo:~/kernel/linux-5.19$ head System.map
      0000000000000000 D __per_cpu_start
      0000000000000000 D fixed_percpu_data
      00000000000001ea A kexec_control_code_size
      0000000000001000 D cpu_debug_store
      0000000000002000 D irq_stack_backing_store
      0000000000006000 D cpu_tss_rw
      000000000000b000 D gdt_page
      000000000000c000 d exception_stacks
      0000000000014000 d entry_stack_storage
      0000000000015000 D espfix_waddr
      ```

## QEMU & GDB

- QEMU 调试参数
  - cmdline: nokaslr (禁用内核地址空间布局随机)
  - -S 在开始时阻塞 CPU 执行
  - -s 开启 GDB 服务器，端口 1234
  - -gdb tcp::1234 开启 GDB 服务器，自定义端口
    ```sh
    qemu-system-x86_64 \
                -kernel bzImage  \
                -initrd initramfs.img  \
                -smp 4 \
                -m 1G  \
                -nographic  \
                -append "earlyprintk=serial,ttyS0 console=ttyS0 nokaslr" \
                -S \  # 命令执行后会卡住（阻塞CPU），此时用gdb连接
                -gdb tcp::9000
    ```
- `gdb vmlinux` to create terminal and then input:
  - `target remote:1234`
  - `break start_kernel`, set breakpoint
  - `continue`
  - `step`

## Debug Step

1. QEMU(Terminal 1):

```sh
qemu-system-x86_64 \
            -kernel bzImage  \
            -initrd initramfs.img  \
            -smp 4 \
            -m 1G  \
            -nographic  \
            -append "earlyprintk=serial,ttyS0 console=ttyS0 nokaslr" \
            -S \  # 命令执行后会卡住（阻塞CPU），此时用gdb连接
            -gdb tcp::9000
```

2. GBD(Terminal 2):

```sh
gdb vmlinux
```

3. Opimize

vim .gdbinit

```sh
target remote:1234
break start_kernel
continue
step
```

## VS Code Kernel Debug

### QEMU

```sh
qemu-system-x86_64 \
            -kernel bzImage  \
            -initrd initramfs.img  \
            -smp 4 \
            -m 1G  \
            -nographic  \
            -append "earlyprintk=serial,ttyS0 console=ttyS0 nokaslr" \
            -S \  # 命令执行后会卡住（阻塞CPU），此时用gdb连接
            -s
```

### 配置及启动 VS Code Debug

- VS Code中代码报红:
  - 预编译指令 `ifdef` 等
  - VS Code 不知道编译时的命令
  - 缺少 `compile_commands.json` 文件
- 使用内核自带脚本
  - 执行脚本：`./scripts/clang-tools/gen_compile_commands.py`
  - 源码目录下多了 `compile_commands.json` 文件
- 插件
  - C/C++
- 配置文件
  - `launch.json`
    - 配置调试信息
  - `c_cpp_properties.json` (爆红问题)
    - 配置compile_commands.json 文件
      - ctrl + shift + p 选择 C/C++: Edit Configurations
- VS Code -> Set Breakpoints -> Run -> Start Debugging


**launch.json**
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "qemu-kernel-gdb",
            "type": "cppdbg",
            "request": "launch",
            "miDebuggerServerAddress": "127.0.0.1:1234",
            "program": "${workspaceRoot}/vmlinux",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "environment": [],
            "externalConsole": false,
            "logging": {
                "engineLogging": false,
            },
            "MIMode": "gdb"
        }
    ]
}
```

**c_cpp_properties.json**
```json
{
    "configurations": [
        {
            "name": "Linux",
            "includePath": [
                "${workspaceFolder}/**"
            ],
            "defines": [],
            "compilerPath": "/usr/bin/gcc",
            "cStandard": "c17",
            "cppStandard": "gnu++17",  //c++14
            "intelliSenseMode": "linux-gcc-x64", //linux-clang-x64
            "compileCommands": "${workspaceFolder/compile_commands.json}"  // add
        }
    ],
    "version": 4
}
```











