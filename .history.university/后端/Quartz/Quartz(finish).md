## 介绍
Quartz是一个功能丰富的开源作业调度(Job scheduling)库，几乎可以集成到任何Java应用程序中——从最小的独立应用程序到最大的电子商务系统。Quartz可以用于创建简单或复杂的调度，用于执行数十个、数百个甚至数万个作业;任务定义为标准Java组件的作业，这些组件可以执行您编程让它们执行的几乎任何事情。Quartz Scheduler包含许多企业级特性，比如对JTA事务和集群的支持。

官网：[http://www.quartz-scheduler.org/](http://www.quartz-scheduler.org/)

## 示例

### 1.依赖
```xml
<dependency>
  <groupId>org.quartz-scheduler</groupId>
  <artifactId>quartz</artifactId>
  <version>2.2.1</version>
</dependency>
<dependency>
  <groupId>org.quartz-scheduler</groupId>
  <artifactId>quartz-jobs</artifactId>
  <version>2.2.1</version>
</dependency>
```

### 2.配置
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
	xmlns:context="http://www.springframework.org/schema/context"
	xmlns:dubbo="http://code.alibabatech.com/schema/dubbo" 
	xmlns:mvc="http://www.springframework.org/schema/mvc"
	xsi:schemaLocation="http://www.springframework.org/schema/beans
							http://www.springframework.org/schema/beans/spring-beans.xsd
							http://www.springframework.org/schema/mvc
							http://www.springframework.org/schema/mvc/spring-mvc.xsd
							http://code.alibabatech.com/schema/dubbo
							http://code.alibabatech.com/schema/dubbo/dubbo.xsd
							http://www.springframework.org/schema/context
							http://www.springframework.org/schema/context/spring-context.xsd">
							
	<context:annotation-config></context:annotation-config>
	
	<!-- 注册自定义Job类 -->
	<bean id="clearImgJob" class="com.itheima.jobs.ClearImgJob"></bean>
	
	<!-- 注册JobDetail,作用是负责通过反射调用指定的Job -->
	<bean id="jobDetail" class="org.springframework.scheduling.quartz.MethodInvokingJobDetailFactoryBean">
		<!-- 注入目标对象 -->
		<property name="targetObject" ref="clearImgJob"/>
		<!-- 注入目标方法 -->
		<property name="targetMethod" value="clearImg"/>
	</bean>
	
	<!-- 注册一个触发器，指定任务触发的时间 -->
	<bean id="myTrigger" class="org.springframework.scheduling.quartz.CronTriggerFactoryBean">
		<!-- 注入JobDetail -->
		<property name="jobDetail" ref="jobDetail"/>
		<!-- 指定触发的时间，基于Cron表达式 -->
		<property name="cronExpression">
			<value>0 0 2 * * ?</value><!--cron表达式-->
		</property>
	</bean>
	
	<!-- 注册一个统一的调度工厂，通过这个调度工厂调度任务 -->
	<bean id="scheduler" class="org.springframework.scheduling.quartz.SchedulerFactoryBean">
		<!-- 注入多个触发器 -->
		<property name="triggers">
			<list>
				<ref bean="myTrigger"/>
			</list>
		</property>
	</bean>
	
</beans>
```

### 3.代码
```java
/**
 * 自定义Job，实现定时清理垃圾图片
 */
public class ClearImgJob {
    @Autowired
    private JedisPool jedisPool;
    public void clearImg(){
        //根据Redis中保存的两个set集合进行差值计算，获得垃圾图片名称集合
        Set<String> set = 
            jedisPool.getResource().sdiff(RedisConstant.SETMEAL_PIC_RESOURCES, 
                                          RedisConstant.SETMEAL_PIC_DB_RESOURCES);
        if(set != null){
            for (String picName : set) {
                //删除七牛云服务器上的图片
                QiniuUtils.deleteFileFromQiniu(picName);
                //从Redis集合中删除图片名称
                jedisPool.getResource().
                    srem(RedisConstant.SETMEAL_PIC_RESOURCES,picName);
            }
        }
    }
}
```

## cron表达式
0 0 2 * * ?
这种表达式称为cron表达式，通过cron表达式可以灵活的定义出符合要求的程序执行的时间。

![6](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220812163851604-1869808273.png)

cron表达式分为七个域，之间使用空格分隔。其中最后一个域（年）可以为空。每个域都有自己允许的值和一些特殊字符构成。使用这些特殊字符可以使我们定义的表达式更加灵活。

下面是对这些特殊字符的介绍：

- 逗号（,）：指定一个值列表，例如使用在月域上1,4,5,7表示1月、4月、5月和7月

- 横杠（-）：指定一个范围，例如在时域上3-6表示3点到6点（即3点、4点、5点、6点）

- 星号（\*）：表示这个域上包含所有合法的值。例如，在月份域上使用星号意味着每个月都会触发

- 斜线（/）：表示递增，例如使用在秒域上0/15表示每15秒

- 问号（?）：只能用在日和周域上，但是不能在这两个域上同时使用。表示不指定

- 井号（#）：只能使用在周域上，用于指定月份中的第几周的哪一天，例如6#3，意思是某月的第三个周五 (6=星期五，3意味着月份中的第三周)

- L：某域上允许的最后一个值。只能使用在日和周域上。当用在日域上，表示的是在月域上指定的月份的最后一天。用于周域上时，表示周的最后一天，就是星期六

- W：W 字符代表着工作日 (星期一到星期五)，只能用在日域上，它用来指定离指定日的最近的一个工作日

## cron表达式在线生成器
地址：[http://cron.qqe2.com/](http://cron.qqe2.com/)