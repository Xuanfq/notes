### 简介

*   **linux环境下定时或者周期性的执行一些任务通常由cron这个守护进程来完成，这是一个系统自带的相对也比较方便的系统工具。**
*   **cron进程能实现定时任务这些需求，cron搭配shell脚本，非常复杂的指令也没有问题。**
*   **crontab命令是cron table的简写，它是cron的配置文件，也可以叫它作业列表，我们可以在以下文件夹内找到相关配置文件。**

### 目录结构

*   **/var/spool/cron/crontabs 用户调度任务** 目录下存放的是每个用户包括root的crontab任务，每个任务以创建者的名字命名，比如用户定期要执行的工作，比如用户数据备份、定时邮件提醒等
*   **/etc/crontab 系统调度任务** 这个文件负责调度各种管理和维护任务，比如写缓存数据到硬盘、日志清理等。
*   **/etc/cron.d/** 这个目录用来存放任何要执行的crontab文件或脚本。

我们还可以把脚本放在\*\*/etc/cron.hourly\*\*、**/etc/cron.daily**、**/etc/cron.weekly**、**/etc/cron.monthly**目录中，让它每小时/天/星期、月执行一次。

### crontab的使用

#### crontab 安装

一般是系统自带，如果没有需要自己装下

```
sudo apt-get install cron

```

#### crontab 命令格式

```
usage:  crontab [-u user] file  //加载file文件内容到工作表
crontab [ -u user ] [ -i ] { -e | -l | -r } //省略用户表示操作当前用户的crontab
		(默认操作是 replace)
	-e	(编辑用户的工作表)
	-l	(列出用户的工作表)
	-r	(删除用户的工作表)
	-i	(在删除用户的crontab文件时给确认提示)

```

我们用**crontab -e** 既可进入当前用户的工作表编辑

#### crontab 默认编辑器配置

第一次使用crontab 时，会出现以下提示：

```
root@ubuntu:# crontab -e
Select an editor.  To change later, run 'select-editor'.
  1. /bin/ed
  2. /bin/nano        <---- easiest
  3. /usr/bin/vim.basic
  4. /usr/bin/vim.tiny

```

这个提示是让用户选择编辑器，正常情况下我们选择第三个就可以。如果选错了可以执行**select-editor**命令在选择一次。

```
root@ubuntu:# crontab -e

Select an editor.  To change later, run 'select-editor'.
  1. /bin/ed
  2. /bin/nano        <---- easiest
  3. /usr/bin/vim.basic
  4. /usr/bin/vim.tiny

Choose 1-4 [2]: 3
root@B-OPS-68-1:~#

```

#### crontab 任务配置编写

用**crontab -e**进入当前用户的工作表编辑

crontab的配置语法为 **时间+动作**，其时间有**分、时、日、月、周** 五种，每个时间注意用空格分开，动作就是你要执行的命令

格式：

| 分 minute (m) | 小时 hour (h) | 日 day of month (dom) | 月 month (mon) | 星期 day of week (dow) | 命令      |
| :----------- | :---------- | :------------------- | :------------ | :------------------- | :------ |
| 0-59         | 0-23        | 1-31                 | 1-12          | 0-6                  | command |

其中时间还可以使用下列特殊字符，更细致的设置时间

*   **(\*)** 星号代表所有可能的值，例如month字段如果是星号，则表示在满足其它字段的制约条件后每月都执行该命令操作
*   **(,)** 可以用逗号隔开的值指定一个列表范围，例如，“1,2,5,7,8,9”
*   **(-)** 可以用整数之间的中杠表示一个整数范围，例如“2-6”表示“2,3,4,5,6”
*   **(/)** 可以用正斜线指定时间的间隔频率，例如“0-23/2”表示每两小时执行一次。同时正斜线可以和星号一起使用，例如\*/10，如果用在minute字段，表示每十分钟执行一次。

小 结：\
数字的表示最好用阿拉伯数字显示\
周和日最好不要同时用\
定时任务要加注解\
可以定向到日志文件或者空文件\
定时任务一定是绝对路径，且目录必须存在才能出结果\
crontab 服务一定要开启运行

#### 示例

**着重说明一下，为了避免权限问题请切换到root用户再创建对cron服务的任务。**

用**crontab -e**进入任务配置编写，内容如下图

![image-20200426174939086](https://img2020.cnblogs.com/blog/1652001/202004/1652001-20200427083601232-129674041.png "image-20200426174939086")

##### 每分钟执行一次 echo "hello world..."，并将结果输出到/var/log/test.log

```
* * * * * echo "hello world...\n" >> /var/log/test.log

```

执行**cat /var/log/test.log**，结果

![image-20200426174827897](https://img2020.cnblogs.com/blog/1652001/202004/1652001-20200427083600696-1061351916.png "image-20200426174827897")

##### 每天的23点55分执行命令

```
55 23 * * * myCommand

```

##### 每月的最后一天的23点55分执行命令

```
55 23 * * * if [`date +%d -d tomorrow` = 01 ] ; then myCommand ; fi 
or 
55 23 * * * if [`date +%d -d tomorrow` = 01 ] ; then ; command

```

##### 更多其他示例(示例参考菜鸟教程)

实例\
实例1：每1分钟执行一次myCommand

```
* * * * * myCommand

```

实例2：每小时的第3和第15分钟执行

```
3,15 * * * * myCommand

```

实例3：在上午8点到11点的第3和第15分钟执行

```
3,15 8-11 * * * myCommand

```

实例4：每隔两天的上午8点到11点的第3和第15分钟执行

```
3,15 8-11 */2  *  * myCommand

```

实例5：每周一上午8点到11点的第3和第15分钟执行

```
3,15 8-11 * * 1 myCommand

```

实例6：每晚的21:30重启smb

```
30 21 * * * /etc/init.d/smb restart

```

实例7：每月1、10、22日的4 : 45重启smb

```
45 4 1,10,22 * * /etc/init.d/smb restart

```

实例8：每周六、周日的1 : 10重启smb

```
10 1 * * 6,0 /etc/init.d/smb restart

```

实例9：每天18 : 00至23 : 00之间每隔30分钟重启smb

```
0,30 18-23 * * * /etc/init.d/smb restart

```

实例10：每星期六的晚上11 : 00 pm重启smb

```
0 23 * * 6 /etc/init.d/smb restart

```

实例11：每一小时重启smb

```
* */1 * * * /etc/init.d/smb restart

```

实例12：晚上11点到早上7点之间，每隔一小时重启smb

```
* 23-7/1 * * * /etc/init.d/smb restart

```

#### 可能会用到的其他命令

    service cron start    //启动服务
    service cron stop     //关闭服务
    service cron restart  //重启服务
    service cron reload   //重新载入配置
    service cron status   //查看服务状态 

    tail /var/log/syslog  //使用crontab进行设置定时任务,任务没有执行，查看系统日志排查

    ps -ef | grep cron  //查看cron 进程是否存在

