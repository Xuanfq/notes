
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





# Makefile - 流程

GNU的make工作时的执行步骤入下：

1. 读入所有的Makefile。
2. 读入被include的其它Makefile。
3. 初始化文件中的变量。
4. 推导隐晦规则，并分析所有规则。
5. 为所有的目标文件创建依赖关系链。
6. 根据依赖关系，决定哪些目标要重新生成。
7. 执行生成命令。

1-5步为第一阶段，6-7为第二阶段。第一阶段中，如果定义的变量被使用了，那么，make会把其展开在使用的位置。但make并不会完全马上展开，make使用的是拖延战术，如果变量出现在依赖关系的规则中，那么仅当这条依赖被决定要使用了，变量才会在其内部展开。





# Makefile - 编译

**make**程序是一个智能实用程序，根据您在源文件中所做的更改工作。

如果你有四个文件 main.cpp、hello.cpp、factorial.cpp 和 functions.h，那么所有剩余的文件都依赖于 functions.h，而 main.cpp 依赖于 hello.cpp 和 factorial.cpp。因此，如果您对 functions.h 进行任何更改，则**make**重新编译所有源文件以生成新的目标文件。但是，如果您在 main.cpp 中进行任何更改，因为它不依赖于任何其他文件，则只会重新编译 main.cpp 文件，而不会重新编译 help.cpp 和 factorial.cpp。

在编译文件时，**make**检查其目标文件并比较时间戳。如果源文件具有比目标文件更新的时间戳，则假定源文件已更改，它会生成新的目标文件。



**避免重新编译**

可能有一个项目由数千个文件组成。有时您可能已经更改了源文件，但您可能不想重新编译依赖它的所有文件。例如，假设您将宏或声明添加到其他文件所依赖的头文件中，实际上**make**会设定头文件中的任何更改都需要重新编译所有依赖文件。

如果您在更改头文件之前已经预设到可能存在的问题，您可以使用 `-t` 标志。这个标准告诉**make**不要运行规则中的命令，而是通过更改其最后修改日期来将目标标记为最新。您需要遵循此程序：

- 使用命令 `make` 重新编译真正需要重新编译的源文件。
- 在头文件中进行更改。
- 使用命令“make -t”将所有目标文件标记为最新。下次运行 make 时，头文件中的更改不会导致任何重新编译。

如果您在某些文件确实需要重新编译时已经更改了头文件，这时可以删除对应的`.o`并重新编译。





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

- `$@` :
  - 代表目标文件名(target)。在一个规则中，它通常用于表示将要生成的文件。
  - 示例：在 `gcc -o $@ $^` 中，`$@` 会被替换为规则的目标文件名。

- `$^` :
  - 代表所有的依赖文件列表（以空格分隔）。在一个规则中，它表示用于生成目标的所有先决条件（或依赖项）。
  - 示例：在上面的 `gcc` 命令中，`$^` 可能会替换为 `main.c utils.c`。

- `$<` :
  - 代表第一个依赖文件名。这在多个依赖项中只关心其中一个时很有用。
  - 示例：假设你有一个规则，它依赖于 `file1.o` 和 `file2.o`，但在命令中你只想使用 `file1.o`。在这种情况下，`$<` 会被替换为 `file1.o`。

- `$?` :
  - 代表所有比目标更新的依赖文件列表。这通常用于避免不必要的重新编译。
  - 示例：如果你有一个规则来链接多个 `.o` 文件，并且只有其中的一些 `.o` 文件被修改过，那么 `$?` 将只包含这些被修改过的 `.o` 文件。
- `$+` :
  - 类似于`$^`，也是所有依赖目标的集合，只是它不去除重复的依赖目标。这在使用模式规则（pattern rules）时可能很有用。
  - 示例：假设一个规则依赖于 `file.h` 两次（可能是由于某种复杂的依赖关系），`$+` 将确保 `file.h` 在列表中出现了两次。

- `$%` :
  - 当目标是一个归档文件的成员时，代表归档文件成员的名称。在普通的文件操作中，它通常不会被使用。
  - 示例：当你正在操作一个 `.a`（归档）文件，并且目标是该归档中的一个对象文件时，`$%` 会很有用。
  - 仅当目标是函数库文件中，表示规则中的目标成员名。例如，如果一个目标是“foo.a(bar.o)”，那么，“$%”就是“bar.o”，“$@”就是“foo.a”。如果目标不是函数库文件（Unix下是[.a]，Windows下是[.lib]），那么，其值为空。

- `$*` ：
  - 代表目标文件名中去除后缀的部分。这通常用于模式规则中，其中目标文件名和依赖文件名遵循某种模式。
  - 示例：假设你有一个模式规则，它将 `.c` 文件编译为 `.o` 文件。在这种情况下，`$*` 将代表 `.c` 文件名中去除 `.c` 后缀的部分。




例如，我们可以使用如下规则: 

```makefile
hello: main.cpp hello.cpp factorial.cpp
   $(CC) $(CFLAGS) $? $(LDFLAGS) -o $@
# Alternatively:
hello: main.cpp hello.cpp factorial.cpp
   $(CC) $(CFLAGS) $@.cpp $(LDFLAGS) -o $@
```

在这个例子中，$@ 代表*hello*, $? 或 $@.cpp 拾取所有更改的源文件。

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

| 变量         | 描述                                                         |
| :----------- | :----------------------------------------------------------- |
| **AR**       | 档案维护计划；默认为“ar”。                                   |
| **AS**       | 编译汇编文件的程序；默认为“as”。                             |
| **CC**       | 编译C程序的程序；默认为“cc”。                                |
| **CO**       | 从 RCS 签出文件的程序；默认为“co”。                          |
| **CXX**      | 编译 C++ 程序的程序；默认为“g++”。                           |
| **CPP**      | 运行 C 预处理器的程序，并将结果输出到标准输出；默认是`$(CC) -E'。 |
| **FC**       | 编译或预处理 Fortran 和 Ratfor 程序的程序；默认为“f77”。     |
| **GET**      | 从 SCCS 中提取文件的程序；默认为“获取”。                     |
| **LEX**      | 用于将 Lex 语法转换为源代码的程序；默认为“lex”。             |
| **YACC**     | 用于将 Yacc 语法转换为源代码的程序；默认为“yacc”。           |
| **LINT**     | 用于在源代码上运行 lint 的程序；默认为“lint”。               |
| **M2C**      | 用于编译 Modula-2 源代码的程序；默认为“m2c”。                |
| **PC**       | 用于编译 Pascal 程序的程序；默认为“电脑”。                   |
| **MAKEINFO** | 将 Texinfo 源文件转换为 Info 文件的程序；默认为“makeinfo”。  |
| **TEX**      | 从 TeX 源代码制作 TeX dvi 文件的程序；默认为“tex”。          |
| **TEXI2DVI** | 从 Texinfo 源制作 TeX dvi 文件的程序；默认为“texi2dvi”。     |
| **WEAVE**    | 将 Web 翻译成 TeX 的程序；默认为“编织”。                     |
| **CWEAVE**   | 将 C Web 翻译成 TeX 的程序；默认为“cweave”。                 |
| **TANGLE**   | 将 Web 翻译成 Pascal 的程序；默认为“缠结”。                  |
| **CTANGLE**  | 将 C Web 翻译成 C 的程序；默认为“矩形”。                     |
| **RM**       | 删除文件的命令；默认为“rm -f”。                              |



### **程序参数**

这是一个变量表，其值是上述程序的附加参数。除非另有说明，否则所有这些的默认值都是空字符串。

| 变量          | 描述                                                         |
| :------------ | :----------------------------------------------------------- |
| **ARFLAGS**   | 提供存档维护程序的标志；默认为“rv”。                         |
| **ASFLAGS**   | 在 `.s` 或 `.S` 文件上显式调用时提供给汇编器的额外标志。     |
| **CFLAGS**    | 提供给 C 编译器的额外标志。                                  |
| **CXXFLAGS**  | 提供给 C 编译器的额外标志。                                  |
| **COFLAGS**   | 提供给 RCS co 程序的额外标志。                               |
| **CPPFLAGS**  | 提供给 C 预处理器和使用它的程序（例如 C 和 Fortran 编译器）的额外标志。 |
| **FFLAGS**    | 提供给 Fortran 编译器的额外标志。                            |
| **GFLAGS**    | 提供给 SCCS 获取程序的额外标志。                             |
| **LDFLAGS**   | 当编译器应该调用链接器时提供额外的标志，'ld'。               |
| **LFLAGS**    | 给 Lex 的额外标志。                                          |
| **YFLAGS**    | 给 Yacc 的额外标志。                                         |
| **PFLAGS**    | 提供给 Pascal 编译器的额外标志。                             |
| **RFLAGS**    | 为 Ratfor 程序提供给 Fortran 编译器的额外标志。              |
| **LINTFLAGS** | 给予 lint 的额外标志。                                       |



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

```makefile
hello: main.o factorial.o hello.o
   $(CC) main.o factorial.o hello.o -o hello
```

在这里，我们告诉**make** hello 依赖于 main.o、factorial.o 和 hello.o 文件。因此，每当这些目标文件中的任何一个发生变化时，**make**将采取行动。

同时，我们需要告诉**make**如何准备 .o 文件。因此，我们还需要如下定义这些依赖项:

```makefile
main.o: main.cpp functions.h
   $(CC) -c main.cpp
factorial.o: factorial.cpp functions.h
   $(CC) -c factorial.cpp
hello.o: hello.cpp functions.h
   $(CC) -c hello.cpp
```





# Makefile - 规则



Makefile 目标规则的一般语法:

```makefile
target [target...] : [dependent ....]
[ command ...]
```

在上面的代码中，括号中的参数是可选的，省略号表示一个或多个。在这里，请注意每个命令前面的选项卡是必需的。

下面给出了一个简单的示例 (在本例中，您必须给出规则以从源文件生成所有目标文件):

```makefile
hello: main.o factorial.o hello.o
   $(CC) main.o factorial.o hello.o -o hello
```



## 显式规则

- `make target`时，make找到适用的目标规则`target`并执行。
- 如果任何家属比目标新，make一次执行一个命令（在宏替换之后）。
- 如果必须建立任何依赖项，则首先发生（递归）。即依赖项未构建，则先递归进行依赖项构建。
- make如果遇到命令返回失败状态（命令退出状态为非0），则终止。
- `-`: 如果被执行的命令前面加上`-`，即使命令执行失败或出错，也会继续执行后续命令 (实际是忽略返回状态):

```makefile
clean:
   -rm *.o *~ core paper
```

- 在宏替换之后，每条命令都会显示以向您显示执行的命令。
- `@`: 如果被执行的命令前面加上`@`，会关闭正在执行的命令。例如:

```makefile
install:
   @echo You must be root to install
```

- 对于阅读Makefile文件，请始终先浏览`target`。可以合理地期望找到目标 all（或只是 make）、install 和 clean:

  - **make all**: 它编译所有内容，以便您可以在安装应用程序之前进行本地测试。

  - **make install**: 它将应用程序安装在正确的位置。

  - **make clean**: 它清理应用程序、删除可执行文件、任何临时文件、目标文件等。



## 隐式规则

这里我们将讲述所有预先设置（也就是make内建）的隐含规则，如果我们不明确地写下规则，那么，make就会在这些规则中寻找所需要规则和命令。

当然，我们也可以使用make的参数 `-r` 或 `--no-builtin-rules` 选项来取消所有的预设置的隐含规则。

当然，即使是我们指定了 `-r` 参数，某些隐含规则还是会生效，因为有许多的隐含规则都是使用了“后缀规则”来定义的，所以，只要隐含规则中有 “后缀列表”（也就一系统定义在目标 `.SUFFIXES` 的依赖目标），那么隐含规则就会生效。

默认的后缀列表`.SUFFIXES` 为：`.out, .a, .ln, .o, .c, .cc, .C, .p, .f, .F, .r, .y, .l, .s, .S, .mod, .sym, .def, .h, .info, .dvi, .tex, .texinfo, .texi, .txinfo, .w, .ch .web, .sh, .elc, .el`



**隐式规则列表**

1. 编译C程序的隐含规则:

   `<n>.o` 的目标的依赖目标会自动推导为 `<n>.c` ，并且其生成命令是 `$(CC) –c $(CPPFLAGS) $(CFLAGS)`

2. 编译C++程序的隐含规则:

   `<n>.o` 的目标的依赖目标会自动推导为 `<n>.cc` 或 `<n>.cpp` 或是 `<n>.C` ，并且其生成命令是 `$(CXX) –c $(CPPFLAGS) $(CXXFLAGS)` 。（建议使用 `.cc` 或 `.cpp` 作为C++源文件的后缀，而不是 `.C` ）

3. 汇编和汇编预处理的隐含规则:

   `<n>.o` 的目标的依赖目标会自动推导为 `<n>.s` ，默认使用编译器 `as` ，并且其生成命令是： `$ (AS) $(ASFLAGS)` 。 `<n>.s` 的目标的依赖目标会自动推导为 `<n>.S` ，默认使用C预编译器 `cpp` ，并且其生成命令是： `$(CPP) $(CPPFLAGS)` 。

4. 链接Object文件的隐含规则:

   `<n>` 目标依赖于 `<n>.o` ，通过运行C的编译器来运行链接程序生成（一般是 `ld` ），其生成命令是： `$(CC) $(LDFLAGS) <n>.o $(LOADLIBES) $(LDLIBS)` 。这个规则对于只有一个源文件的工程有效，同时也对多个Object文件（由不同的源文件生成）的也有效。例如如下规则:

   ```makefile
   x : y.o z.o
   ```

   并且 `x.c` 、 `y.c` 和 `z.c` 都存在时，隐含规则将执行如下命令:

   ```makefile
   cc -c x.c -o x.o
   cc -c y.c -o y.o
   cc -c z.c -o z.o
   cc x.o y.o z.o -o x
   rm -f x.o
   rm -f y.o
   rm -f z.o
   ```

   如果没有一个源文件（如上例中的x.c）和你的目标名字（如上例中的x）相关联，那么，你最好写出自己的生成规则，不然，隐含规则会报错的。

5. ....





# Makefile - 指令

有许多以各种形式提供的指令，系统上的程序可能不支持所有指令，需要请检查系统的**GNU make**支持些指令。



## 条件指令

**条件指令语法**

- **ifeq**: 指令开始条件，并指定条件。它包含两个参数，用逗号分隔并用括号括起来。对两个参数执行变量替换，然后将它们进行比较。如果两个参数匹配，则遵循 ifeq 后面的 makefile 行；否则它们将被忽略。
- **ifneq**: 指令开始条件，并指定条件。它包含两个参数，用逗号分隔并用括号括起来。对两个参数执行变量替换，然后将它们进行比较。如果两个参数不匹配，则遵循 ifneq 后面的 makefile 行；否则它们将被忽略。
- **ifdef**: 指令开始条件，并指定条件。它包含单个参数。如果给定参数为真，则条件为真。
- **ifndef**: 指令开始条件，并指定条件。它包含单个参数。如果给定参数为假，则条件为真。
- **else**: 如果前一个条件失败，指令会导致遵循以下行。在上面的示例中，意味着只要不使用第一个替代项，就会使用第二个替代链接命令。在条件中有一个 else 是可选的。
- **endif**: 指令结束条件。每个条件都必须以 endif 结尾。



- 没有其他条件的简单条件的语法如下:

```makefile
conditional-directive
   text-if-true
endif
```

text-if-true 可以是任何文本行，如果条件为真，则将其视为 makefile 的一部分。如果条件为假，则不使用任何文本。



- 复杂条件的语法如下:

```makefile
conditional-directive
   text-if-true
else
   text-if-false
endif
```

如果条件为真，则使用 text-if-true ；否则，使用 text-if-false。text-if-false 可以是任意数量的文本行。



- 无论条件是简单的还是复杂的，条件指令的语法都是相同的。有四种不同的指令可以测试各种条件。它们是给定的:

```makefile
ifeq (arg1, arg2)
ifeq 'arg1' 'arg2'
ifeq "arg1" "arg2"
ifeq "arg1" 'arg2'
ifeq 'arg1' "arg2" 
```

上述条件的相反指令如下:

```makefile
ifneq (arg1, arg2)
ifneq 'arg1' 'arg2'
ifneq "arg1" "arg2"
ifneq "arg1" 'arg2'
ifneq 'arg1' "arg2" 
```



**条件指令示例**

```python
libs_for_gcc = -lgnu
normal_libs =
foo: $(objects)
ifeq ($(CC),gcc)
   $(CC) -o foo $(objects) $(libs_for_gcc)
else
   $(CC) -o foo $(objects) $(normal_libs)
endif
```





## 包含指令

**include directive**允许**make**暂停读取当前 makefile 并在继续之前读取一个或多个其他 makefile，完成后make继续读取指令出现的makefile。该指令是生成文件中的一行，如下所示:

```makefile
include filenames...
```

文件名可以包含 shell 文件名模式。行首允许并忽略多余的空格，但不允许使用制表符。例如，如果你有 3 个 `.mk' 文件，分别是 `a.mk'、`b.mk' 和 `c.mk'，以及 $(bar) 那么它会扩展为 bish bash，如:

```makefile
include foo *.mk $(bar)
# is equivalent to:
include foo a.mk b.mk c.mk bish bash
```





## 覆盖指令

如果使用命令参数设置了变量，则忽略 makefile 中的普通赋值。如果你想在 makefile 中设置变量，即使它是用命令参数设置的，你可以使用覆盖指令，如下所示:

```makefile
override variable = value
#or
override variable := value
```







# Makefile - 其他功能

## Make - 递归执行: `-C`

递归使用**make**意味着使用**make**作为makefile中的命令。当您需要为组成更大系统的各种子系统分别生成文件时，此技术很有用。例如，假设您有一个名为 `subdir' 的子目录，它有自己的 makefile，并且您希望包含目录的 makefile 运行**make**子目录上。您可以通过编写以下代码来做到这一点 -

```makefile
subsystem:
   cd subdir && $(MAKE)

# or, equivalently:
   
subsystem:
   $(MAKE) -C subdir
   
# make -C subdir1 subdir2 subdir3 ...
# =
# cd subdir1 && $(MAKE); cd subdir2 && $(MAKE); cd subdir3 && $(MAKE)
```





## Make - 指定Makefile文件: `-f`

如果您已经准备好名为“Makefile”的 Makefile，那么只需在命令提示符下编写 make，它就会运行 Makefile 文件。但是，如果您的 Makefile 文件名为其他名称，请使用以下命令:

```makefile
make -f your-makefile-name
```





## Makefile - 递归传递变量: `export`

- 顶层变量值**make**可以通过显式请求通过环境传递给子make。这些变量在 sub-make 中定义为默认值。除非您使用 `-e` ，否则您不能覆盖sub-make makefile 使用的 makefile 中指定的内容。在`make`工具中，`-e`选项（或者`--environment-overrides`）用于指示`make`在处理Makefile时，如果Makefile中的变量与环境中的同名变量发生冲突(Makefile中使用=)，则优先使用环境中的变量值。

- 要传递或导出变量，**make**将变量及其值添加到运行每个命令的环境中。反过来，sub-make使用环境来初始化其变量值表。

- 特殊变量 SHELL 和 MAKEFLAGS 始终被导出（除非您取消导出它们）。

如果要将特定变量导出到sub-make或`shell`，请使用导出指令，如下所示:

```makefile
export variable ...
```

如果要防止变量被导出，请使用 unexport 指令，如下所示:

```makefile
unexport variable ...
```





## Makefile - MAKEFILES

在 `Makefile` 中，`MAKEFILES` 是一个特殊的变量，它允许你指定一个或多个额外的 `Makefile` 文件，这些文件将被 `make` 命令在读取主 `Makefile` 之前首先读取。这在某些复杂的项目结构中特别有用，当你想要在不同的目录或不同的 `Makefile` 片段中共享一些公共的构建规则时。

这里有一些关键点关于 `MAKEFILES` 变量：

1. **定义**：你可以在命令行上设置 `MAKEFILES` 变量，也可以在 `Makefile` 中设置它。但是，如果在命令行上设置了该变量，它将覆盖任何在 `Makefile` 中设置的定义。

   * 在命令行上：`MAKEFILES=/path/to/extra.mk make`

   * 在 `Makefile` 中：`MAKEFILES += /path/to/extra.mk`

2. **顺序**：如果 `MAKEFILES` 变量包含多个文件，这些文件将按照在 `MAKEFILES` 变量中列出的顺序被读取。每个额外的 `Makefile` 都可以包含变量定义、规则等。
3. **递归**：当 `make` 递归地调用自身（例如，在子目录中）时，`MAKEFILES` 变量也会被传递给子 `make` 实例。但是，你需要注意，如果子 `Makefile` 也设置了 `MAKEFILES`，那么子 `Makefile` 的设置将覆盖从父 `Makefile` 继承的设置。
4. **覆盖**：如果 `MAKEFILES` 和主 `Makefile` 中定义了同名的变量，那么后读取的 `Makefile`（即主 `Makefile`）中的变量定义会覆盖先前读取的 `Makefile` 中的定义。这是因为 `make` 在处理 `Makefile` 时，变量的值是在解析过程中逐步确定的，并且后定义的变量值会覆盖先定义的变量值。MAKEFILES 的主要用途是在递归调用之间进行通信**make**。
5. **用途**：`MAKEFILES` 的主要用途之一是允许在多个不同的项目中共享公共的构建规则。例如，你可以有一个包含所有常见编译器标志和链接器选项的 `Makefile`，然后在每个项目的 `Makefile` 中包含这个公共的 `Makefile`。
5. **区别**：需要注意的是，`MAKEFILES` 变量和 `include` 指令在 `make` 中是两种不同的机制。`MAKEFILES` 变量用于指定在读取主 `Makefile` 之前要读取的额外 `Makefile` 文件，而 `include` 指令则用于在主 `Makefile` 内部包含其他 `Makefile` 文件的内容。使用 `include` 指令时，被包含的 `Makefile` 文件会在 `include` 指令所在的位置被插入到主 `Makefile` 中，并且其内容会按照常规的解析顺序进行处理。
6. **注意事项**：虽然 `MAKEFILES` 变量在某些情况下可能很有用，但它也可能使构建过程变得复杂和难以维护。因此，在使用它之前，请确保你了解它的工作原理和潜在问题。





## Makefile - 指定头文件路径: `-I`

如果您将头文件放在不同的目录中并且您正在运行**make**在不同的目录下，则需要提供头文件的路径。这可以使用 `makefile` 中的 `-I` 选项来完成。假设 `functions.h` 文件在 `/home/project/include` 文件夹中，其余文件在 /home/project/src/ 文件夹中，则 `makefile` 将编写如下:

```makefile
INCLUDES = -I "/home/project/include"
CC = gcc
LIBS =  -lm
CFLAGS = -g -Wall
OBJ =  main.o factorial.o hello.o
hello: ${OBJ}
   ${CC} ${CFLAGS} ${INCLUDES} -o $@ ${OBJS} ${LIBS}
.cpp.o:
   ${CC} ${CFLAGS} ${INCLUDES} -c
```





## Makefile - 变量追加内容: `+=`

可以使用 `+=` 来向已定义的变量的值添加更多文本，如图所示:

```makefile
objects += another.o
```

它获取变量`objects`的值，并将文本`another.o`添加到其中，前面有一个**空格**，如下所示。

```makefile
objects = main.o hello.o factorial.o
objects += another.o  # 此时 object = main.o hello.o factorial.o another.o
```

上面的代码将对象设置为`main.o hello.o factorial.o another.o'

使用 `+=` 类似于:

```makefile
objects = main.o hello.o factorial.o
objects := $(objects) another.o
```





## Makefile - 续行: `\`

如果您不喜欢 Makefile 中的行太长，那么您可以使用反斜杠`\`换行，如下所示:

```python
OBJ =  main.o factorial.o \
   hello.o
# is equivalent to
OBJ =  main.o factorial.o hello.o
```

















