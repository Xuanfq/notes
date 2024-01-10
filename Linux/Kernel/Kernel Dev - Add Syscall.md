

# System Call


- 手册: man 2 syscall
- 上层应用程序调用的API
  - eg: printf() => glibc write() => kernel write()
- 系统调用的指令
  - syscall和int
  - syscall是64 bit机器的指令;int是32bit机器的指令
- 系统调用的返回值
  - 返回值: rax、rdx寄存器
- 系统调用的参数
  - 支持6个参数，分别对应6个寄存器


## Code Demo
### C语言
syscall()

```c
#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>

int main()
{
    int pid=syscall(39);//39 为 getpid 的系统调用号
    printf("pid=%d\n", pid);
}
```


### 汇编语言
x86_64 syscall


## Kernel Source Code of System Call


- 不同体系结构有不同的系统调用
  - arch/x86/entry/syscalls/syscall_64.tbl
- 系统调用属于内核的一部分，不能作为模块进行编译
  - 对系统调用的修改需要重新编译内核
- 宏__NR_syscalls
  - 系统调用的个数arch/x86/include/generated/uapi/asm/unistd_64.h
  - PS:系统调用编号从0开始


### Add System Call Demo (get number of cpu)

- 注册系统调用号
```c
// arch/x86/entry/syscalls/syscall_64.tbl
// # The format is:
// # <number> <abi> <name> <entry point>
451 common get_cpu_number  sys_get_cpu_number
```


- 声明系统调用函数
```c
// include/linux/syscalls.h
asmlinkage long sys_get_cpu_number(void);
```


- 实现系统调用函数
```c
// kernel/sys.c
SYSCALL_DEFINEO(get_cpu_number)
{
    return num_present_cpus();
}
```

#### Test Add System Call Demo

- 重新编译内核
- 本地静态编译测试代码，打包进initramfs
    - 测试代码:
        ```c
        // get_cpu.c
        #include <stdio.h>
        #include <unistd.h>
        #include <sys/syscall.h>

        int main()
        {
            int cpu_number=syscall(451);
            printf("cpus=%dn", cpu_number);
            return 0;
        }
        ```
    - `gcc -static get_cpu.c -o get_cpu`
- 用QEMU模拟，可以调整`-smp`参数观察效果
    ```sh
    qemu-system-x86_64  \
        -kernel bzImage  \
        -initrd initramfs.img  \
        -smp 2 \
        -m 1G  \
        -nographic  \
        -append "earlyprintk=serial,ttyS0 console=ttyS0"

    # Quit QEMU
    # Ctrl + a, then press x
    ```


### Summary

- 系统调用是内核提供给应用程序的API
- 系统调用和体系结构有关
- 系统调用属于内核，修改之后需要重新编译内核
- 添加系统调用很简单，但是设计和实现很难



