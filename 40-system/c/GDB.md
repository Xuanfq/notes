# GDB

## 简介

GDB(GNU Debugger)是Linux下一款C/C++程序调试工具，通过在命令行中执行相应的命令实现程序的调试，使用GDB时只需要在shell中输入`gdb`命令或`gdb filename`（filename为可执行程序文件名）即可进入GDB调试环境。

GDB主要有以下功能：

- 设置断点
- 单步调试
- 查看变量的值
- 动态改变程序的执行环境
- 分析崩溃程序产生的core文件

## GDB常用命令

| 命令                      | 简写                | 含义                                        |
| ------------------------- | ------------------- | ------------------------------------------- |
| file <file>               | -                   | 装入待调试的可执行文件                      |
| **run**                   | r                   | 执行程序(至结束)                            |
| **start**                 | -                   | 开始调试(至main开始处暂停)                  |
| **step**                  | s                   | 执行一条程序，若为函数则进入内部执行        |
| **next**                  | n                   | 执行一条程序，不进入函数内部                |
| continue                  | c                   | 连续运行                                    |
| finish                    | -                   | 运行到当前函数返回                          |
| kill                      | k                   | 终止正在调试的程序                          |
| **list**                  | l                   | 列出源代码的一部分(10行)                    |
| **print** <tmp>           | p <tmp>             | 打印变量的值                                |
| **info locals**           | i locals            | 查看当前栈帧的局部变量                      |
| **backtrace**             | bt                  | 查看函数调用栈帧编号                        |
| **frame** <id>            | f <id>              | 选择栈帧(再看局部变量)                      |
| **display** <tmp>         | -                   | 每次自动显示跟踪的变量的值                  |
| undisplay <tmp>           | -                   | 取消跟踪                                    |
| **break** <num>           | b                   | 设置(调试)断点                              |
| delete breakpoints <num>  | d breakpoints <num> | 删除断点，不加行号则删除所有                |
| disable breakpoints <num> | -                   | 屏蔽断点                                    |
| enable breakpoints <num>  | -                   | 启用断点                                    |
| **info breakpoints**      | i breakpoints       | 显示所有断点                                |
| break 9 if sum != 0       | -                   | 根据条件设置断点(sum不等于0时，第9行设断点) |
| **set var** sum=0         | -                   | 修改变量的值(使sum变量的值为0)              |
| watch <tmp>               | -                   | 监视一个变量的值                            |
| examine <...>             | -                   | 查看内存中的地址                            |
| jump <num>                | j                   | 跳转执行                                    |
| signal <...>              | -                   | 产生信号量                                  |
| return                    | -                   | 强制函数返回                                |
| call <fun>                | -                   | 强制调用函数                                |
| make <...>                | -                   | 不退出gdb下重新产生可执行文件               |
| shell <...>               | -                   | 不退出gdb下执行shell命令                    |
| **quit**                  | q                   | 退出gdb环境                                 |

## 调试示例1

gdbtest.c:

```javascript
#include <stdio.h>

int add(int start, int end)
{
    int i, sum;
    for(i=start; i<=end; i++)
        sum += i;
    return sum;
}

int main()
{
    int result;
    result = add(1, 10);
    printf("result=%d\n", result);

    return 0;
}
```

编译，需要添加`-g`参数，用于GDB调试：

```javascript
$ gcc -o gdbtest gdbtest.c -g
```

该程序是计算1~10电脑的和，正确结果应该输出55，我们先运行一下程序：

```javascript
$ ./gdbtest
result=55
```

程序在本电脑上运行正确，但是，该程序是存在问题的，add()函数中的sum变量应该赋初值0，否则在其它电脑上运行，如果该变量被初始化了随机数，则会计算出错误的结果。本次运行未出错的原因应该是该变量被默认初始化为0，所以计算无误。

下面使用GDB对该可执行程序进程调试：

```javascript
$ gdb gdbtest
```

输出以下信息：

```javascript
GNU gdb (Ubuntu 8.1-0ubuntu3.2) 8.1.0.20180409-git
Copyright (C) 2018 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
and "show warranty" for details.
This GDB was configured as "x86_64-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<http://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
<http://www.gnu.org/software/gdb/documentation/>.
For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from gdbtest...done.
(gdb)
```

首先输出一些系统信息，最后一行开头的`(gdb)`为命令提示符，输入`start`命令开始调试:

```javascript
(gdb) start
Temporary breakpoint 1 at 0x67b: file gdbtest.c, line 14.
Starting program: /home/deeplearning/dcj/linuxCTest/GDBtest/gdbtest

Temporary breakpoint 1, main () at gdbtest.c:14
14          result = add(1, 10);
(gdb)
```

程序直接运行至主函数处的第一条实质性的运行语句处，即第14行的子程序调用处，此处可以使用`step`命令步入该语句的程序内部：

```javascript
(gdb) step
add (start=1, end=10) at gdbtest.c:6
6           for(i=start; i<=end; i++)
(gdb)
```

继续使用`backtrace`命令查看**函数调用帧栈**：

```javascript
(gdb) backtrace
#0  add (start=1, end=10) at gdbtest.c:6
#1  0x000055555555468a in main () at gdbtest.c:14
(gdb)
```

可以看出函数add()被主函数调用，主函数传入的start和end参数值。add()函数的**栈帧号**为0，主函数的栈帧号为1。

可以继续使用`info locals`命令查看add()函数中的局部变量的值，也可以使用`frame 1`命令先选择主函数所在的1号帧栈，再使用`info locals`命令查看主函数中的局部变量的值：

```javascript
(gdb) info locals
i = 0
sum = 0
(gdb) frame 1
#1  0x000055555555468a in main () at gdbtest.c:14
14          result = add(1, 10);
(gdb) info locals
result = 0
(gdb)
```

可以看到，add()函数中两个局部变量的值均被默认初始化为0，主函数中的局部变量result也被初始化为0。

如果局部变量默认不是初始化为0，可以在GDB环境下通过`set var`命令修改变量的值，并查看运行效果。由于程序在本电脑上运行无误，我们现在故意修改sum的初始值为100，并查看最终的运行结果：

```javascript
(gdb) set var sum=100
No symbol "sum" in current context.
(gdb) frame 0
#0  add (start=1, end=10) at gdbtest.c:6
6           for(i=start; i<=end; i++)
(gdb) set var sum=100
(gdb) print sum
$1 = 100
(gdb) info locals
i = 0
sum = 100
(gdb) finish
Run till exit from #0  add (start=1, end=10) at gdbtest.c:6
0x000055555555468a in main () at gdbtest.c:14
14          result = add(1, 10);
Value returned is $2 = 155
(gdb)
```

使用`set var sum=100`将sum的值修改为100，注意要切换到sum变量所在的帧栈环境中执行，然后可以使用`print`或`info locals`命令查看修改后的结果，接着使用`finish`命令使程序自动运行结果，可以看出最终的输出的结果为155，符合预期。最后可以使用`quit`命令退出GDB环境：

```javascript
(gdb) quit
A debugging session is active.

        Inferior 1 [process 31210] will be killed.

Quit anyway? (y or n) y
$
```

键入`y`确认退出即可。

## 调试示例2

计算从1到n是和，gdbbreakpoint.c:

```javascript
#include <stdio.h>

int main()
{
    int sum=0, i, data;
    while(1)
    {
        printf("please input a num(<100)\n");
        scanf("%d", &data);

        for(i=1; i<=data; i++)
            sum += i;

        printf("sum from 1 to %d is: %d\n", data, sum);
    }

    return 0;
}
```

编译并运行测试：

```javascript
$ gcc -o gdbbreakpoint gdbbreakpoint.c -g
$ ./gdbbreakpoint
please input a num(<100)
2
sum from 1 to 2 is: 3
please input a num(<100)
3
sum from 1 to 3 is: 9
please input a num(<100)
4
sum from 1 to 4 is: 19
please input a num(<100)
^C
```

可以看到只有第一次计算正确，其后的都计算错误。

这次对程序设置断点进行调试，进入GDB环境后，可以先使用`list`命令查看源程序，确定所需加断点和行号：

```javascript
(gdb) list
1       #include <stdio.h>
2
3       int main()
4       {
5           int sum=0, i, data;
6           while(1)
7           {
8               printf("please input a num(<100)\n");
9               scanf("%d", &data);
10
(gdb)
11              for(i=1; i<=data; i++)
12                  sum += i;
13
14              printf("sum from 1 to %d is: %d\n", data, sum);
15          }
16
17          return 0;
18      }
(gdb)
```

`list`每次显示10行，可以使用`Enter`键继续显示，for循环语句位于第11行，使用`break`加行号命令设置断点：

```javascript
(gdb) break 11
Breakpoint 1 at 0x73c: file gdbbreakpoint.c, line 11.
(gdb) info breakpoints
Num     Type           Disp Enb Address            What
1       breakpoint     keep y   0x000000000000073c in main
                                                   at gdbbreakpoint.c:11
(gdb)
```

此处还使用了`info breakpoints`查看当前已设置的所有断点。

然后使用`start`命令启动调试：

```javascript
(gdb) start
Temporary breakpoint 2 at 0x702: file gdbbreakpoint.c, line 4.
Starting program: /home/deeplearning/dcj/linuxCTest/GDBtest/gdbbreakpoint

Temporary breakpoint 2, main () at gdbbreakpoint.c:4
4       {
(gdb) continue
Continuing.
please input a num(<100)
2

Breakpoint 1, main () at gdbbreakpoint.c:11
11              for(i=1; i<=data; i++)
(gdb) info locals
sum = 0
i = 32767
data = 2
(gdb)
```

程序先运行到主函数处暂停，继续使用`continue`命令使程序继续运行，然后程序提示输入一个数字，先输入2，之后程序执行至11行断点处，此时使用`info locals`命令查看局部变量的值，i此时为随机数(对后续结果不影响)，sum和data为预期结果。

继续使用`continue`命令，此次输入3，并在11行断点再次使用`info locals`命令查看局部变量的值，发现sum的值在每次循环后没有清零，因此导致之后的计算结果出错。

```javascript
(gdb) continue
Continuing.
sum from 1 to 2 is: 3
please input a num(<100)
3

Breakpoint 1, main () at gdbbreakpoint.c:11
11              for(i=1; i<=data; i++)
(gdb) info locals
sum = 3
i = 3
data = 3
(gdb)
```

找到原因，手动修改源程序，在while循环体的开始处将sum赋值0修正程序问题。



