## 重定向

`>&2`、`>&1`

文件描述符 1 是`stdout`，文件描述符 2 是`stderr`。

使用`>`重定向输出与使用相同`1>`。这表示重定向`stdout`（文件描述符 1）。

```bash
ps 1> /tmp/ps.log 2>&1; grep "innovium.user" /tmp/ps.log > /dev/null 2>&1

1>  # stdout输出到/tmp/ps.log，stderr也输出到stdout，即/tmp/ps.log，
```

## getopts

getpots是Shell命令行参数解析工具，旨在从Shell Script的命令行当中解析参数。getopts被Shell程序用来分析位置参数，option包含需要被识别的选项字符，**如果这里的字符后面跟着一个冒号，表明该字符选项需要一个参数，其参数需要以空格分隔**。冒号和问号不能被用作选项字符。getopts每次被调用时，它会将下一个选项字符放置到变量中，OPTARG则可以拿到参数值；如果option前面加冒号，则代表忽略错误；

    getopts OPTSTRING VARNAME [ARGS...]

where:

*   `OPTSTRING` is string with list of expected arguments,

    *   `h` - check for option `-h` **without** parameters; gives error on unsupported options;
    *   `h:` - check for option `-h` **with** parameter; gives errors on unsupported options;
    *   `abc` - check for options `-a`, `-b`, `-c`; **gives** errors on unsupported options;
    *   `:abc` - check for options `-a`, `-b`, `-c`; **silences** errors on unsupported options;

        ^Notes: In other words, colon in front of options allows you handle the errors in your code. Variable will contain ^^?^^ in the case of unsupported option, ^^:^^ in the case of missing value.^
*   `OPTARG` - is set to current argument value,
*   `OPTERR` - indicates if Bash should display error messages.

**命令格式：**

    getopts optstring name [arg...]

**命令描述：**\
optstring列出了对应的Shell Script可以识别的所有参数。比如：如果 Shell Script可以识别-a，-f以及-s参数，则optstring就是afs；如果对应的参数后面还跟随一个值，则在相应的optstring后面加冒号。比如，a\:fs 表示a参数后面会有一个值出现，-a value的形式。另外，getopts执行匹配到a的时候，会把value存放在一个叫OPTARG的Shell Variable当中。如果 optstring是以冒号开头的，命令行当中出现了optstring当中没有的参数将不会提示错误信息。

name表示的是参数的名称，每次执行getopts，会从命令行当中获取下一个参数，然后存放到name当中。如果获取到的参数不在optstring当中列出，则name的值被设置为?。命令行当中的所有参数都有一个index，第一个参数从1开始，依次类推。 另外有一个名为OPTIND的Shell Variable存放下一个要处理的参数的index。

**shift的使用——参数移位**

很多脚本执行的时候我们并不知道后面参数的个数，但可以使用\$\*来获取所有参数。但在程序处理的过程中有时需要逐个的将\$1、\$2、\$3……\$n进行处理。shift是shell中的内部命令，用于处理参数位置。每次调用shift时，它将所有位置上的参数减一。 \$2变成了\$1, \$3变成了\$2, \$4变成了\$3。shift命令的作用就是在执行完\$1后，将\$2变为\$1，\$3变为\$2，依次类推。

参考：<https://www.cnblogs.com/kevingrace/p/11753294.html>
