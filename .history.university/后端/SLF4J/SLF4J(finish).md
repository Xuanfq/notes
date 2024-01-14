## 介绍
SLF4J代表*Simple Logging Facade for Java*。它提供了Java中所有日志框架的简单抽象。因此，它使用户能够使用单个依赖项处理任何日志框架，例如：[Log4j](http://www.yiibai.com/log4j/ "Log4j")，Logback和JUL(`java.util.logging`)。可以在运行时/部署时迁移到所需的日志记录框架。

CekiGülcü创建了SLF4J作为`Jakarta commons-logging`框架的替代品。

![20220408110447](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220814132438676-1569031075.png)

## 优点
-   使用SLF4J框架，可以在部署时迁移到所需的日志记录框架。
-   Slf4J提供了对所有流行的日志框架的绑定，例如log4j，JUL，Simple logging和NOP。因此可以在部署时切换到任何这些流行的框架。
-   无论使用哪种绑定，SLF4J都支持参数化日志记录消息。
-   由于SLF4J将应用程序和日志记录框架分离，因此可以轻松编写独立于日志记录框架的应用程序。而无需担心用于编写应用程序的日志记录框架。
-   SLF4J提供了一个简单的Java工具，称为迁移器。使用此工具，可以迁移现有项目，这些项目使用日志框架(如Jakarta Commons Logging(JCL)或log4j或Java.util.logging(JUL))到SLF4J。

## 日志框架
在编程中的日志是指记录活动/事件。通常，应用程序开发人员应该负责日志记录。
为了使日志记录更容易，Java提供了各种框架 *log4J，java.util.logging(JUL)， tiny log，logback*等。

### 日志记录框架概述
日志框架通常包含三个元素 -

-   **记录仪** - 捕获消息和元数据。
-   **格式化** - 格式化记录器捕获的消息。
-   **处理器** - `Handler`或`appender`最终通过在控制台上打印或通过存储在数据库中或通过发送电子邮件来调度消息。

一些框架结合了`logger`和`appender`元素来加速操作。

### 记录器对象
要记录消息，应用程序会发送一个带有名称和安全级别的记录器对象(有时还有异常情况)。

### 严重程度
日志记录的消息具有级别。下表列出了日志记录的级别。
| 序号 | 严重程度 | 描述 | 
|----|----|----|
| 1 | Fatal | 导致应用程序终止的严重问题。 | 
| 2 | ERROR | 运行时错误 | 
| 3 | WARNING | 在大多数情况下，这种级别的错误是由于使用了已弃用的API。 |
| 4 | INFO | 运行时发生的事件。 |
| 5 | DEBUG | 有关系统流程的信息。 |
| 6 | TRACE | 有关系统流程的更多详细信息。|

## 与Log4j的区别
log4j是一个用Java编写的可靠，快速和灵活的日志框架(API)，它是在Apache软件许可下发布的。
log4j可在运行时通过外部配置文件进行高度配置。它根据优先级来查看日志记录过程，并提供将日志记录定向到各种目标的机制，例如：数据库，文件，控制台，UNIX Syslog等

与log4j不同，SLF4J不是日志框架的实现，它是Java中所有日志框架的抽象，类似于log4J。因此，两者难以比较。但是，要在两者之间选择一个，那就比较难以决择了。
如果一定要选择，则日志记录抽象始终优于日志记录框架。如果使用日志记录抽象，特别是SLF4J，可以迁移到部署时所需的任何日志记录框架，而无需选择单一依赖项。

![20220408102331](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220814132438956-1171042076.png)

## 环境配置
对于commons-logging来说，无需在pom.xml文件中单独引入日志实现框架，便可进行日志打印。但是，slf4j并不支持此功能，必须在pom.xml中**单独引入底层日志**实现。

搭配log4j使用：
```xml
//slf4j:
<dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>slf4j-api</artifactId>
    <version>1.7.20</version>
</dependency>

//slf4j-log4j:
<dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>slf4j-log4j12</artifactId>
    <version>1.7.12</version>
</dependency>

//log4j:
<dependency>
    <groupId>log4j</groupId>
    <artifactId>log4j</artifactId>
    <version>1.2.17</version>
</dependency>
```
配置log4j：
```properties
log4j.debug=true   
log4j.rootLogger=DEBUG,D,E

log4j.appender.E = org.apache.log4j.DailyRollingFileAppender
log4j.appender.E.File = logs/logs.log
log4j.appender.E.Append = true
log4j.appender.E.Threshold = DEBUG
log4j.appender.E.layout = org.apache.log4j.PatternLayout
log4j.appender.E.layout.ConversionPattern = %-d{yyyy-MM-dd HH:mm:ss}  [ %t:%r ] - [ %p ]  %m%n

log4j.appender.D = org.apache.log4j.DailyRollingFileAppender
log4j.appender.D.File = logs/error.log
log4j.appender.D.Append = true
log4j.appender.D.Threshold = ERROR
log4j.appender.D.layout = org.apache.log4j.PatternLayout
log4j.appender.D.layout.ConversionPattern = %-d{yyyy-MM-dd HH:mm:ss}  [ %t:%r ] - [ %p ]  %m%n
```

## 参考API

### Logger接口
`org.slf4j`包中的`logger`接口是SLF4J API的入口点。以下列出了此接口的重要方法。
  | 编号 | 方法 | 描述 |
  |---|---|---|
| 1 |`void debug(String msg)` |在`DEBUG`级别记录消息。|
| 2 |`void error(String msg)`| 在`ERROR`级别记录消息。|
|3 |`void info(String msg)`| 在`INFO`级别记录消息。|
| 4 |`void trace(String msg)` |在`TRACE`级别记录消息。|
| 5 |`void warn(String msg)`| 在`WARN`级别记录消息。|

### LoggerFactory类
`org.slf4j`包中的`LoggerFactory`类是一个实用程序类，用于为各种日志API生成记录器，例如log4j，JUL，NOP和简单记录器。

|编号 |方法 |描述|
|---|---|---|
| 1| `Logger getLogger(String name)` |此方法接受表示名称的字符串值，并返回具有指定名称的`Logger`对象。|

### Profiler类
这个类属于org.slf4j包，它用于分析目的，它被称为穷人的探查器。使用它，程序员可以找出执行长时间任务所需的时间。

以下是`Profiler`类的重要方法。
| 编号 | 方法                            | 描述                                                         |
| ---- | ------------------------------- | ------------------------------------------------------------ |
| 1    | `void start(String name)`       | 此方法将启动一个新的子秒表(命名)，并停止较早的子秒表(或时间工具)。 |
| 2    | `TimeInstrument stop()`         | 此方法将停止最近的子秒表和全局秒表并返回当前的时间仪器。     |
| 3    | `void setLogger(Logger logger)` | 此方法接受`Logger`对象并将指定的记录器与当前的`Profiler`相关联。 |
| 4    | `void log()`                    | 记录与记录器关联的当前时间仪器的内容。                       |
| 5    | `void print()`                  | 打印当前时间工具的内容。                                     |

## 示例
```java
public class slf4j_log4jDemo {

    Logger logger = LoggerFactory.getLogger(slf4j_log4jDemo.class);

    @Test
    public void test() throws IOException {
        logger.error("Error Message!");
        logger.warn("Warn Message!");
        logger.info("Info Message!{}","你好");
        logger.debug("Debug Message!");
        logger.trace("Trace Message!");
    }
}
```

## @Slf4j

### 1.在pom中引入依赖
```xml
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
</dependency>
```

2.IDE中安装lombok插件
安装完成后重启即可，其他IDE中类似安装。

3.在类上添加@Slf4j注解，在方法中直接使用log

```java
package com.test;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import lombok.extern.slf4j.XSlf4j;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

@RunWith(SpringRunner.class)
@SpringBootTest
@Slf4j
public class LoggerTest {
	//自定义logger，lombok会自动生成一个log，无需在此处写，可直接log.xxx()
    private final Logger logger = LoggerFactory.getLogger(LoggerTest.class);

    @Test
    public void test(){
        log.debug("debug");
        log.info("info");
        log.error("error");
        log.warn("warn");
    }
}
```
