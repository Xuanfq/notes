## 介绍
log4j是一个用Java编写的可靠，快速和灵活的日志框架（API），它在Apache软件许可下发布。 

Log4j已经被移植到了C，C++，C＃，Perl，Python和Ruby等语言中。

Log4j是高度可配置的，并可通过在运行时的外部文件配置。它根据记录的优先级别，并提供机制，以指示记录信息到许多的目的地，诸如：数据库，文件，控制台，UNIX系统日志等。

Log4j中有三个主要组成部分：
-   **loggers:** 负责捕获记录信息。
-   **appenders :** 负责发布日志信息，以不同的首选目的地。
-   **layouts:** 负责格式化不同风格的日志信息。

## 特性

-   log4j的是线程安全的

-   log4j是经过优化速度的

-   log4j是基于一个名为记录器的层次结构

-   log4j的支持每个记录器多输出追加器（appender）

-   log4j支持国际化。

-   log4j并不限于一组预定义的设备

-   日志行为可以使用配置文件在运行时设置

-   log4j设计从一开始就是处理Java异常

-   log4j使用多个层次，即ALL，TRACE，DEBUG，INFO，WARN，ERROR和FATAL

-   日志输出的格式可以通过扩展Layout类容易地改变

-   日志输出的目标，以及在写入策略可通过实现Appender程序接口改变

-   log4j 会故障停止。然而，尽管它肯定努力确保传递，log4j不保证每个日志语句将被传递到目的地。

## 优缺点
日志是软件开发的重要组成部分。一个精心编写的日志代码提供快速的调试，维护方便，以及应用程序的运行时信息结构化存储。

日志记录确实也有它的缺点。它可以减缓的应用程序。如果太详细，它可能会导致滚动失明。为了减轻这些影响，log4j被设计为是可靠，快速和可扩展。

由于记录很少为应用的主要重点，但log4j API致力于成为易于理解和使用。

## 架构
Log4j API设计为分层结构，其中每一层提供了不同的对象，对象执行不同的任务。这使得设计灵活，根据将来需要来扩展。

有两种类型可用在Log4j的框架对象。
-   **核心对象：** 框架的强制对象和框架的使用。
-   **支持对象：** 框架和支持体核心对象，可选的对象执行另外重要的任务。

### 核心对象

#### Logger对象

顶级层的Logger，它提供Logger对象。Logger对象负责捕获日志信息及它们存储在一个空间的层次结构。

#### 布局对象

该层提供其用于格式化不同风格的日志信息的对象。布局层提供支持Appender对象到发布日志信息之前。

布局对象的发布方式是人类可读的及可重复使用的记录信息的一个重要的角色。

#### Appender对象

下位层提供Appender对象。Appender对象负责发布日志信息，以不同的首选目的地，如数据库，文件，控制台，UNIX系统日志等。

以下是显示Log4J框架的不同组件的虚拟图：
![](assets/Pasted%20image%2020220408120252.png)

### 支持对象

log4j框架的其他重要的对象起到日志框架的一个重要作用：

#### Level对象

级别对象定义的任何记录信息的粒度和优先级。有记录的七个级别在API中定义：OFF, DEBUG, INFO, ERROR, WARN, FATAL 和 ALL

#### Filter对象

过滤对象用于分析日志信息及是否应记录或不用这些信息做出进一步的决定。

一个appender对象可以有与之关联的几个Filter对象。如果日志记录信息传递给特定Appender对象，都和特定Appender相关的Filter对象批准的日志信息，然后才能发布到所连接的目的地。

#### 对象渲染器

ObjectRenderer对象是一个指定提供传递到日志框架的不同对象的字符串表示。这个对象所使用的布局对象来准备最后的日志信息。

#### 日志管理

日志管理对象管理的日志框架。它负责从一个系统级的配置文件或配置类读取初始配置参数。


## 环境配置
```xml
<dependency>
    <groupId>log4j</groupId>
    <artifactId>log4j</artifactId>
    <version>1.2.17</version>
</dependency>
```

## 配置文件

### 日志级别

我们使用DEBUG和两个appenders。所有可能的选项是：
-   跟踪
-   调试
-   信息
-   警告
-   错误
-   致命
-   所有

org.apache.log4j.Level类提供以下级别，但也可以通过Level类的子类自定义级别。

| Level | 描述                                                   |
| ----- | ------------------------------------------------------ |
| ALL   | 各级包括自定义级别                                     |
| DEBUG | 指定细粒度信息事件是最有用的应用程序调试               |
| ERROR | 错误事件可能仍然允许应用程序继续运行                   |
| FATAL | 指定非常严重的错误事件，这可能导致应用程序中止         |
| INFO  | 指定能够突出在粗粒度级别的应用程序运行情况的信息的消息 |
| OFF   | 这是最高等级，为了关闭日志记录                         |
| TRACE | 指定细粒度比DEBUG更低的信息事件                        |
| WARN  | 指定具有潜在危害的情况                                 |



### 追加者

Apache log4j提供了用于将日志消息打印到不同目标（如控制台，文件，套接字，NT事件日志等）的Appender对象。

每个Appender对象都具有与其关联的不同属性，这些属性指示该对象的行为。

| 属性      | 描述                                                         |
| --------- | ------------------------------------------------------------ |
| layout    | Appender使用布局对象和转换模式来格式化日志记录信息。         |
| target    | 目标可以是控制台，文件或其他项目，具体取决于附加程序。       |
| level     | 级别过滤日志消息。                                           |
| threshold | Appender可以具有阈值级别，并忽略具有低于阈值级别的级别的任何日志记录消息。 |
| filter    | Filter对象决定日志记录请求是由特定Appender处理还是忽略。     |

我们可以使用以下方法在配置文件中添加一个Appender对象到Logger：

```properties
log4j.logger.[logger-name]=level, appender1,appender..n
```

我们可以用XML格式编写相同的配置。

```xml
<logger name="com.apress.logging.log4j" additivity="false">
   <appender-ref ref="appender1"/>
   <appender-ref ref="appender2"/>
</logger>
```

要添加Appender对象，请使用以下方法：

```java
public void addAppender(Appender appender);
```

addAppender()方法将Appender添加到Logger对象。我们可以在逗号分隔的列表中添加许多Appender对象到记录器。

所有可能的追加者选项是：

- AppenderSkeleton
- AsyncAppender
- ConsoleAppender
- DailyRollingFileAppender
- ExternallyRolledFileAppender
- FileAppender
- JDBCAppender
- JMSAppender
- LF5Appender
- NTEventLogAppender
- NullAppender
- RollingFileAppender
- SMTPAppender
- SocketAppender
- SocketHubAppender
- SyslogAppender
- TelnetAppender
- WriterAppender

### 日志布局

我们可以使用下面的布局列表。

-   DateLayout
-   HTMLLayout生成HTML格式的消息。
-   PatternLayout
-   SimpleLayout
-   XMLLayout生成XML格式的消息

### 输出到控制台

以下`log4j.properties`显示如何将信息记录到控制台。

```properties
# Root logger option
log4j.rootLogger=INFO, stdout

# Direct log messages to stdout
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.Target=System.out
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=%d{yyyy-MM-dd HH:mm:ss} %-5p %c{1}:%L - %m%n
```

以下xml代码将重写上面列出的配置。
```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE log4j:configuration SYSTEM "log4j.dtd">
<log4j:configuration debug="true"
  xmlns:log4j="http://jakarta.apache.org/log4j/">
  <appender name="console" class="org.apache.log4j.ConsoleAppender">
      <layout class="org.apache.log4j.PatternLayout">
    <param name="ConversionPattern" 
      value="%d{yyyy-MM-dd HH:mm:ss} %-5p %c{1}:%L - %m%n" />
      </layout>
  </appender>
  <root>
    <level value="DEBUG" />
    <appender-ref ref="console" />
  </root>
</log4j:configuration>
```

### 输出到文件

FileAppender配置
| 属性           | 描述                                                         |
| -------------- | ------------------------------------------------------------ |
| immediateFlush | 标志的默认设置为true，这意味着输出流的文件被刷新，在每个追加操作 |
| encoding       | 它可以使用任何字符编码。默认情况下是特定于平台的编码方案     |
| threshold      | 这个 appender 阈值级别                                       |
| Filename       | 日志文件的名称                                               |
| fileAppend     | 默认设置为true，这意味着记录的信息被附加到同一文件的末尾     |
| bufferedIO     | 此标志表示是否需要写入缓存启用。默认设置为false              |
| bufferSize     | 如果 bufferedI/O 启用，这表示缓冲区的大小，默认设置为8KB     |


下面是一个示例配置文件 log4j.properties 的 FileAppender。

```properties
# Define the root logger with appender file
log4j.rootLogger = DEBUG, FILE

# Define the file appender
log4j.appender.FILE=org.apache.log4j.FileAppender
# Set the name of the file
log4j.appender.FILE.File=${log}/log.out

# Set the immediate flush to true (default)
log4j.appender.FILE.ImmediateFlush=true

# Set the threshold to debug mode
log4j.appender.FILE.Threshold=debug

# Set the append to false, overwrite
log4j.appender.FILE.Append=false

# Define the layout for file appender
log4j.appender.FILE.layout=org.apache.log4j.PatternLayout
log4j.appender.FILE.layout.conversionPattern=%m%n
```

如果喜欢相当于上述log4j.properties文件的XML配置文件，在这里是xml配置文件的内容：

```
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE log4j:configuration SYSTEM "log4j.dtd">
<log4j:configuration>

<appender name="FILE" class="org.apache.log4j.FileAppender">
   <param name="file" value="${log}/log.out"/>
   <param name="immediateFlush" value="true"/>
   <param name="threshold" value="debug"/>
   <param name="append" value="false"/>
   <layout class="org.apache.log4j.PatternLayout">
      <param name="conversionPattern" value="%m%n"/>
   </layout>
</appender>

<logger name="log4j.rootLogger" additivity="false">
   <level value="DEBUG"/>
   <appender-ref ref="FILE"/>
</logger>

</log4j:configuration>
```



#### 日志记录到多个文件

- 当想要写日志信息转化多个文件要求一样，例如，如果文件大小达到一定的阈值等。

- 写日志记录信息分成多个文件，必须扩展FileAppender类，并继承其所有属性useorg.apache.log4j.RollingFileAppender类。

- 有以下除了已如上所述为 FileAppender 可配置参数：

| 属性           | 描述                                        |
| -------------- | ------------------------------------------- |
| maxFileSize    | 上述的文件的回滚临界尺寸。默认值是10MB      |
| maxBackupIndex | 此属性表示要创建的备份文件的数量。默认值是1 |

- 下面是一个示例配置文件log4j.properties的RollingFileAppender进行

```properties
# Define the root logger with appender file
log4j.rootLogger = DEBUG, FILE

# Define the file appender
log4j.appender.FILE=org.apache.log4j.RollingFileAppender
# Set the name of the file
log4j.appender.FILE.File=${log}/log.out

# Set the immediate flush to true (default)
log4j.appender.FILE.ImmediateFlush=true

# Set the threshold to debug mode
log4j.appender.FILE.Threshold=debug

# Set the append to false, should not overwrite
log4j.appender.FILE.Append=true

# Set the maximum file size before rollover
log4j.appender.FILE.MaxFileSize=5KB

# Set the the backup index
log4j.appender.FILE.MaxBackupIndex=2

# Define the layout for file appender
log4j.appender.FILE.layout=org.apache.log4j.PatternLayout
log4j.appender.FILE.layout.conversionPattern=%m%n
```

- 如果想有一个XML配置文件，可以生成中提到的初始段，并添加相关的 RollingFileAppender 进行唯一额外的参数。

- 此示例配置说明每个日志文件的最大允许大小为5MB。当超过最大尺寸，新的日志文件将被创建并因为maxBackupIndex被定义为2，当第二个日志文件达到最大值，第一个日志文件将被删除，之后所有的日志信息将被回滚到第一个日志文件。


#### 每天生成日志文件

- 当想生成每一天的日志文件，以保持日志记录信息的良好记录。

- 日志记录信息纳入日常的基础文件，就必须它扩展FileAppender类，并继承其所有属性useorg.apache.log4j.DailyRollingFileAppender类。

- 有除了已如上所述为 FileAppender 只有一个重要的下列配置参数：

| Property    | 描述                                                         |
| ----------- | ------------------------------------------------------------ |
| DatePattern | 这表示在滚动的文件，并按命名惯例来执行。默认情况下，在每天午夜滚动 |

DatePattern控制使用下列滚动的时间表方式之一：

| DatePattern          | 描述                                 |
| -------------------- | ------------------------------------ |
| '.' yyyy-MM          | 滚动在每个月的结束和下一个月初       |
| '.' yyyy-MM-dd       | 这是默认值，每天午夜滚动             |
| '.' yyyy-MM-dd-a     | 滚动每一天的午夜和中午               |
| '.' yyyy-MM-dd-HH    | 滚动在每一个小时                     |
| '.' yyyy-MM-dd-HH-mm | 滚动在每一个分钟                     |
| '.' yyyy-ww          | 滚动每个星期取决于区域设置时的第一天 |

下面是一个示例配置文件log4j.properties生成日志文件滚动的在每天午夜。
```properties
# Define the root logger with appender file
log4j.rootLogger = DEBUG, FILE

# Define the file appender
log4j.appender.FILE=org.apache.log4j.DailyRollingFileAppender
# Set the name of the file
log4j.appender.FILE.File=${log}/log.out

# Set the immediate flush to true (default)
log4j.appender.FILE.ImmediateFlush=true

# Set the threshold to debug mode
log4j.appender.FILE.Threshold=debug

# Set the append to false, should not overwrite
log4j.appender.FILE.Append=true

# Set the DatePattern
log4j.appender.FILE.DatePattern='.' yyyy-MM-dd-a

# Define the layout for file appender
log4j.appender.FILE.layout=org.apache.log4j.PatternLayout
log4j.appender.FILE.layout.conversionPattern=%m%n
```

如果想使用XML配置文件，可以生成中提到的初始段，并添加相关DailyRollingFileAppender 唯一的额外参数和数据。



### 输出到控制台和文件

以下 `log4j.properties` 显示如何将信息记录到文件和控制台。

```properties
# Root logger option
log4j.rootLogger=INFO, file, stdout
 
# Direct log messages to a log file
log4j.appender.file=org.apache.log4j.RollingFileAppender
log4j.appender.file.File=C:\\my.log
log4j.appender.file.MaxFileSize=10MB
log4j.appender.file.MaxBackupIndex=10
log4j.appender.file.layout=org.apache.log4j.PatternLayout
log4j.appender.file.layout.ConversionPattern=%d{yyyy-MM-dd HH:mm:ss} %-5p %c{1}:%L - %m%n
 
# Direct log messages to stdout
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.Target=System.out
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=%d{yyyy-MM-dd HH:mm:ss} %-5p %c{1}:%L - %m%n
```

以下xml代码将重写上面列出的配置。
```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE log4j:configuration SYSTEM "log4j.dtd">
<log4j:configuration debug="true"
  xmlns:log4j="http://jakarta.apache.org/log4j/">
 
  <appender name="console" class="org.apache.log4j.ConsoleAppender">
      <layout class="org.apache.log4j.PatternLayout">
    <param name="ConversionPattern" 
      value="%d{yyyy-MM-dd HH:mm:ss} %-5p %c{1}:%L - %m%n" />
      </layout>
  </appender>
 
  <appender name="file" class="org.apache.log4j.RollingFileAppender">
      <param name="append" value="false" />
      <param name="maxFileSize" value="10MB" />
      <param name="maxBackupIndex" value="10" />
      <param name="file" value="${catalina.home}/logs/my.log" />
      <layout class="org.apache.log4j.PatternLayout">
    <param name="ConversionPattern" 
      value="%d{yyyy-MM-dd HH:mm:ss} %-5p %c{1}:%L - %m%n" />
      </layout>
  </appender>
 
  <root>
    <level value="DEBUG" />
    <appender-ref ref="console" />
    <appender-ref ref="file" />
  </root>
 
</log4j:configuration>
```

### 输出到数据库
#### JDBCAppender 配置

| Property   | 描述                                                         |
| ---------- | ------------------------------------------------------------ |
| bufferSize | 设置缓冲区的大小。默认大小为1                                |
| driver     | 设置驱动程序类为指定的字符串。如果没有指定驱动程序类，默认为sun.jdbc.odbc.JdbcOdbcDriver |
| layout     | 设置要使用的布局。默认布局是org.apache.log4j.PatternLayout   |
| password   | Sets the database password.                                  |
| sql        | 指定SQL语句在每次记录事件发生的时间执行。这可能是INSERT，UPDATE或DELETE |
| URL        | 设置JDBC URL                                                 |
| user       | 设置数据库用户名                                             |

#### 日志表配置

- 开始使用基于JDBC日志，要创建在哪里保存日志信息的表。下面是创建日志表的SQL语句：

```sql
CREATE TABLE LOGS
   (USER_ID VARCHAR(20) NOT NULL,
    DATED   DATE NOT NULL,
    LOGGER  VARCHAR(50) NOT NULL,
    LEVEL   VARCHAR(10) NOT NULL,
    MESSAGE VARCHAR(1000) NOT NULL
   );
```

#### 配置文件示例

- 以下是将用于将消息记录到一个日志表中的示例配置文件 log4j.properties的JDBCAppender

```properties
# Define the root logger with appender file
log4j.rootLogger = DEBUG, DB

# Define the DB appender
log4j.appender.DB=org.apache.log4j.jdbc.JDBCAppender

# Set JDBC URL
log4j.appender.DB.URL=jdbc:mysql://localhost/DBNAME

# Set Database Driver
log4j.appender.DB.driver=com.mysql.jdbc.Driver

# Set database user name and password
log4j.appender.DB.user=user_name
log4j.appender.DB.password=password

# Set the SQL statement to be executed.
log4j.appender.DB.sql=INSERT INTO LOGS 
                      VALUES('%x','%d','%C','%p','%m')

# Define the layout for file appender
log4j.appender.DB.layout=org.apache.log4j.PatternLayout
```

- 这里使用的是MySQL数据库，必须要使用实际DBNAME，用户ID和在其中创建的日志表的数据库密码。SQL语句是使用日志表名和输入值到表，需要执行INSERT语句。

- JDBCAppender不需要明确定义的布局。相反，使用PatternLayout 传递给它 SQL语句

- 如果想拥有相当于上述log4j.properties文件的XML配置文件，可以参考在这里的内容：

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE log4j:configuration SYSTEM "log4j.dtd">
<log4j:configuration>

<appender name="DB" class="org.apache.log4j.jdbc.JDBCAppender">
   <param name="url" value="jdbc:mysql://localhost/DBNAME"/>
   <param name="driver" value="com.mysql.jdbc.Driver"/>
   <param name="user" value="user_id"/>
   <param name="password" value="password"/>
   <param name="sql" value="INSERT INTO LOGS VALUES('%x',
                             '%d','%C','%p','%m')"/>
   <layout class="org.apache.log4j.PatternLayout">
   </layout>

</appender>

<logger name="log4j.rootLogger" additivity="false">
   <level value="DEBUG"/>
   <appender-ref ref="DB"/>
</logger>

</log4j:configuration>
```


## Logger方法
Logger类提供了多种方法来处理日志活动。 Logger类不允许实例化一个新的记录器实例，但它提供了两个静态方法获得一个 Logger 对象：

- **public static Logger getRootLogger();**
- **public static Logger getLogger(String name);**

此处两种方法的第一个返回应用程序实例根记录器并没有名字。任何其他命名的Logger对象实例是通过第二种方法通过记录器的名称获得。记录器名称是可以传递任何字符串，通常是类或包的名称，因为我们已经使用在最后一章。

```
static Logger log = Logger.getLogger(log4jExample.class.getName());
```

![](assets/Pasted%20image%2020220408162255.png)

所有的级别定义在org.apache.log4j.Level类中，并且任何上述方法都可以调用如下：
```java
import org.apache.log4j.Logger;

public class LogClass {
   private static org.apache.log4j.Logger log = Logger
                                    .getLogger(LogClass.class);
   public static void main(String[] args) {
      log.trace("Trace Message!");
      log.debug("Debug Message!");
      log.info("Info Message!");
      log.warn("Warn Message!");
      log.error("Error Message!");
      log.fatal("Fatal Message!");
   }
}
```

## Log4j日志级别

![](#日志级别)


### 日志级别是如何工作？

级别p的级别使用q，在记录日志请求时，如果p>=q启用。这条规则是log4j的核心。它假设级别是有序的。
对于标准级别它们关系如下：ALL < DEBUG < INFO < WARN < ERROR < FATAL < OFF。


## 日志格式化

### 布局类型
在层次结构中的顶级类是抽象类是org.apache.log4j.Layout。这是 log4j 的 API 中的所有其他布局类的基类。

布局类定义为抽象在应用程序中，不要直接使用这个类; 相反，使用它的子类来工作，如下：

-   DateLayout
-   HTMLLayout生成HTML格式的消息。
-   PatternLayout
-   SimpleLayout
-   XMLLayout生成XML格式的消息

### 布局方法
![](assets/Pasted%20image%2020220408164624.png)

### HTMLLayout
如果想生成一个HTML格式的文件，日志信息，那么可以使用 org.apache.log4j.HTMLLayout 格式化日志信息。

HTMLLayout类扩展抽象org.apache.log4j.Layout类，并覆盖其基类的 format()方法来提供HTML样式格式。

这提供了以下信息显示：

-   生成特定的日志事件之前，从应用程序的开始所经过的时间
    
-   调用该记录请求的线程的名称
    
-   与此记录请求相关联的级别
    
-   日志记录器(Logger)和记录消息的名称
    
-   可选程序文件的位置信息，并从其中记录被调用的行号
    

![](assets/Pasted%20image%2020220408164958.png)

例子：
```properties
# Define the root logger with appender file 
log = /usr/home/log4j 
log4j.rootLogger = DEBUG, FILE 

# Define the file appender 
log4j.appender.FILE=org.apache.log4j.FileAppender 
log4j.appender.FILE.File=${log}/htmlLayout.html 

# Define the layout for file appender 
log4j.appender.FILE.layout=org.apache.log4j.HTMLLayout
log4j.appender.FILE.layout.Title=HTML Layout Example 
log4j.appender.FILE.layout.LocationInfo=true
```

### PatternLayout
如果想生成基于模式的特定格式的日志信息，那么可以使用 org.apache.log4j.PatternLayout 格式化日志信息。

PatternLayout类扩展抽象 org.apache.log4j.Layout 类并覆盖format()方法根据提供的模式构建日志信息。

![](assets/Pasted%20image%2020220408165431.png)

#### 模式转换字符

| 转换字符 | 表示的意思                                                   |
| :------: | ------------------------------------------------------------ |
|    c     | 用于输出的记录事件的类别。例如，对于类别名称"a.b.c" 模式 %c{2} 会输出 "b.c" |
|    C     | 用于输出呼叫者发出日志请求的完全限定类名。例如，对于类名 "org.apache.xyz.SomeClass", 模式 %C{1} 会输出 "SomeClass". |
|    d     | 用于输出的记录事件的日期。例如， %d{HH:mm:ss,SSS} 或 %d{dd MMM yyyy HH:mm:ss,SSS}. |
|    F     | 用于输出被发出日志记录请求，其中的文件名                     |
|    l     | 用于将产生的日志事件调用者输出位置信息                       |
|    L     | 用于输出从被发出日志记录请求的行号                           |
|    m     | 用于输出使用日志事件相关联的应用程序提供的消息               |
|    M     | 用于输出发出日志请求所在的方法名称                           |
|    n     | 输出平台相关的行分隔符或文字                                 |
|    p     | 用于输出的记录事件的优先级                                   |
|    r     | 用于输出毫秒从布局的结构经过直到创建日志记录事件的数目       |
|    t     | 用于输出生成的日志记录事件的线程的名称                       |
|    x     | 用于与产生该日志事件的线程相关联输出的NDC（嵌套诊断上下文）  |
|    X     | 在X转换字符后面是键为的MDC。例如 X{clientIP} 将打印存储在MDC对键clientIP的信息 |
|    %     | 文字百分号 \%\%将打印％标志                                    |



#### 格式修饰符

| Format modifier | left justify | minimum width | maximum width | 注释                                                         |
| :-------------: | :----------: | :-----------: | :-----------: | ------------------------------------------------------------ |
|      %20c       |    false     |      20       |     none      | 用空格左垫，如果类别名称少于20个字符长                       |
|      %-20c      |     true     |      20       |     none      | 用空格右垫，如果类别名称少于20个字符长                       |
|      %.30c      |      NA      |     none      |      30       | 从开始截断，如果类别名称超过30个字符长                       |
|     %20.30c     |    false     |      20       |      30       | 用空格左侧垫，如果类别名称短于20个字符。但是，如果类别名称长度超过30个字符，那么从开始截断。 |
|    %-20.30c     |     true     |      20       |      30       | 用空格右侧垫，如果类别名称短于20个字符。但是，如果类别名称长度超过30个字符，那么从开始截断。 |

#### 例子
```properties
# Define the root logger with appender file 
log = /usr/home/log4j log4j.rootLogger = DEBUG, FILE 
# Define the file appender 
log4j.appender.FILE=org.apache.log4j.FileAppender 
log4j.appender.FILE.File=${log}/log.out 

# Define the layout for file appender 
log4j.appender.FILE.layout=org.apache.log4j.PatternLayout 
log4j.appender.FILE.layout.ConversionPattern= %d{yyyy-MM-dd}-%t-%x-%-5p-%-10c:%m%n
```


