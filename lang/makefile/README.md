
# Makefile

Makefile 是一个程序构建工具，可在 Unix、Linux 及其版本上运行。它有助于简化可能需要各种模块的构建程序可执行文件。要确定模块需要如何一起编译或重新编译，make借助用户定义的makefile。



# Makefile - 功能

编译源代码文件可能很累人，尤其是当您必须包含多个源文件并在每次需要编译时键入编译命令时。Makefile 是简化此任务的解决方案。
Makefile 是特殊格式的文件，可帮助自动构建和管理项目。

例如，假设我们有以下源文件:
- main.cpp
- hello.cpp
- factorial.cpp
- functions.h



**main.cpp**

```c
#include <iostream>
#include "functions.h"
using namespace std;

int main(){
   print_hello();
   cout << endl;
   cout << "The factorial of 5 is " << factorial(5) << endl;
   return 0;
}
```



**hello.cpp**

```c
#include <iostream>
#include "functions.h"
using namespace std;

void print_hello(){
   cout << "Hello World!";
}
```



**factorial.cpp**

```c
#include "functions.h"

int factorial(int n){
   if(n!=1){
      return(n * factorial(n-1));
   } else return 1;
}
```



**functions.h**

```h
void print_hello();
int factorial(int n);
```



编译文件并获得可执行文件的简单方法是运行命令:

```sh
gcc  main.cpp hello.cpp factorial.cpp -o hello
```
此命令生成hello二进制文件。

在这个例子中，我们只有四个文件，并且我们知道函数调用的顺序。因此，输入上述命令并准备最终的二进制文件是可行的。
但是，对于我们拥有数千个源代码文件的大型项目，维护二进制构建变得很困难。
这make命令允许您管理大型程序或程序组。当您开始编写大型程序时，您会注意到重新编译大型程序比重新编译短程序需要更长的时间。
此外，您注意到您通常只处理程序的一小部分（例如单个函数），而其余程序的大部分都没有改变。
在接下来的部分中，我们将看到如何为我们的项目准备一个makefile。





# Makefile - 宏



**make**程序允许您使用类似于变量的宏。宏在 Makefile 中定义为 = 键值对。下面显示了一个示例:

```makefile
MACROS  = -me
PSROFF  = groff -Tps
DITROFF = groff -Tdvi
CFLAGS  = -O -systype bsd43
LIBS    = "-lncurses -lm -lsdl"
MYFACE  = ":*)"
```



## 特殊宏

在目标规则集中发出任何命令之前，有一些预定义的特殊宏:

- `$@` 是要创建的文件的名称
- `$?` 是更改后的家属的姓名

例如，我们可以使用如下规则: 

```makefile
hello: main.cpp hello.cpp factorial.cpp
   $(CC) $(CFLAGS) $? $(LDFLAGS) -o $@
# Alternatively:
hello: main.cpp hello.cpp factorial.cpp
   $(CC) $(CFLAGS) $@.cpp $(LDFLAGS) -o $@
```

在这个例子中，$@ 代表*hello*, $? 或 $@.cpp 拾取所有更改的源文件。



隐式规则中使用了另外两个特殊的宏:

- `$<` 导致该操作的相关文件的名称
- `$*` 目标文件和依赖文件共享的前缀

常见的隐含规则是用于从 .cpp（源文件）构建 .o（对象）文件: 

```makefile
.cpp.o:
   $(CC) $(CFLAGS) -c
# Alternatively:
.cpp.o:
   $(CC) $(CFLAGS) -c $*.c
```





## 常规宏

有各种默认宏。您可以通过键入**`make -p`**来查看它们以打印出默认值。从使用它们的规则来看，大多数都是非常明显的。

这些预定义的变量，即隐式规则中使用的宏，分为两类。它们如下:

- 作为程序名称的宏（例如 CC）
- 包含程序参数的宏（例如 CFLAGS）。`



### **程序名称**

下面是在 makefile 的内置规则中用作程序名称的一些常用变量的表格:

| 序号 | 变量和描述                                                   |
| :--: | :----------------------------------------------------------- |
|  1   | **AR**档案维护计划；默认为“ar”。                             |
|  2   | **AS**编译汇编文件的程序；默认为“as”。                       |
|  3   | **CC**编译C程序的程序；默认为“cc”。                          |
|  4   | **CO**从 RCS 签出文件的程序；默认为“co”。                    |
|  5   | **CXX**编译 C++ 程序的程序；默认为“g++”。                    |
|  6   | **CPP**运行 C 预处理器的程序，并将结果输出到标准输出；默认是`$(CC) -E'。 |
|  7   | **FC**编译或预处理 Fortran 和 Ratfor 程序的程序；默认为“f77”。 |
|  8   | **GET**从 SCCS 中提取文件的程序；默认为“获取”。              |
|  9   | **LEX**用于将 Lex 语法转换为源代码的程序；默认为“lex”。      |
|  10  | **YACC**用于将 Yacc 语法转换为源代码的程序；默认为“yacc”。   |
|  11  | **LINT**用于在源代码上运行 lint 的程序；默认为“lint”。       |
|  12  | **M2C**用于编译 Modula-2 源代码的程序；默认为“m2c”。         |
|  13  | **PC**用于编译 Pascal 程序的程序；默认为“电脑”。             |
|  14  | **MAKEINFO**将 Texinfo 源文件转换为 Info 文件的程序；默认为“makeinfo”。 |
|  15  | **TEX**从 TeX 源代码制作 TeX dvi 文件的程序；默认为“tex”。   |
|  16  | **TEXI2DVI**从 Texinfo 源制作 TeX dvi 文件的程序；默认为“texi2dvi”。 |
|  17  | **WEAVE**将 Web 翻译成 TeX 的程序；默认为“编织”。            |
|  18  | **CWEAVE**将 C Web 翻译成 TeX 的程序；默认为“cweave”。       |
|  19  | **TANGLE**将 Web 翻译成 Pascal 的程序；默认为“缠结”。        |
|  20  | **CTANGLE**将 C Web 翻译成 C 的程序；默认为“矩形”。          |
|  21  | **RM**删除文件的命令；默认为“rm -f”。                        |



### **程序参数**

这是一个变量表，其值是上述程序的附加参数。除非另有说明，否则所有这些的默认值都是空字符串。

| 序号 | 变量和描述                                                   |
| :--: | :----------------------------------------------------------- |
|  1   | **ARFLAGS**提供存档维护程序的标志；默认为“rv”。              |
|  2   | **ASFLAGS**在 `.s` 或 `.S` 文件上显式调用时提供给汇编器的额外标志。 |
|  3   | **CFLAGS**提供给 C 编译器的额外标志。                        |
|  4   | **CXXFLAGS**提供给 C 编译器的额外标志。                      |
|  5   | **COFLAGS**提供给 RCS co 程序的额外标志。                    |
|  6   | **CPPFLAGS**提供给 C 预处理器和使用它的程序（例如 C 和 Fortran 编译器）的额外标志。 |
|  7   | **FFLAGS**提供给 Fortran 编译器的额外标志。                  |
|  8   | **GFLAGS**提供给 SCCS 获取程序的额外标志。                   |
|  9   | **LDFLAGS**当编译器应该调用链接器时提供额外的标志，'ld'。    |
|  10  | **LFLAGS**给 Lex 的额外标志。                                |
|  11  | **YFLAGS**给 Yacc 的额外标志。                               |
|  12  | **PFLAGS**提供给 Pascal 编译器的额外标志。                   |
|  13  | **RFLAGS**为 Ratfor 程序提供给 Fortran 编译器的额外标志。    |
|  14  | **LINTFLAGS**给予 lint 的额外标志。                          |



*NOTE*

> 您可以使用“-R”或“--no-builtin-variables”选项取消隐式规则使用的所有变量。
>
> 您还可以在命令行定义宏，如下所示:
>
> ``````shell
> make CPP=/home/dev/gcc
> ``````





# Makefile - 依赖



最终的二进制文件依赖于各种源代码和源头文件是很常见的。依赖关系很重要，因为它们让**make**知道任何目标的来源。

语法:

```makefile
make_aim: file_dependency_1 file_dependency_2
	make_cmd  # how to generate the make_aim
```



以下示例:

```python
hello: main.o factorial.o hello.o
   $(CC) main.o factorial.o hello.o -o hello
```

在这里，我们告诉**make** hello 依赖于 main.o、factorial.o 和 hello.o 文件。因此，每当这些目标文件中的任何一个发生变化时，**make**将采取行动。

同时，我们需要告诉**make**如何准备 .o 文件。因此，我们还需要如下定义这些依赖项:

```python
main.o: main.cpp functions.h
   $(CC) -c main.cpp
factorial.o: factorial.cpp functions.h
   $(CC) -c factorial.cpp
hello.o: hello.cpp functions.h
   $(CC) -c hello.cpp
```









































