## 介绍
Apache Dubbo 是一款微服务开发框架，它提供了 RPC通信 与 微服务治理 两大关键能力。这意味着，使用 Dubbo 开发的微服务，将具备相互之间的远程发现与通信能力， 同时利用 Dubbo 提供的丰富服务治理能力，可以实现诸如服务发现、负载均衡、流量调度等服务治理诉求。同时 Dubbo 是高度可扩展的，用户几乎可以在任意功能点去定制自己的实现，以改变框架的默认行为来满足自己的业务需求。

- Dubbo是阿里巴巴公司开源的一个高性能、轻量级的 Java RPC 框架。
- 致力于提供高性能和透明化的 RPC 远程服务调用方案，以及 SOA 服务治理方案。

官网：[Apache Dubbo](https://dubbo.apache.org/zh/)

![](assets/Pasted%20image%2020220402222519.png)

老版本架构：
![](assets/Pasted%20image%2020220402225357.png)


## 示例
### 定义服务接口

DemoService.java

```java
package org.apache.dubbo.samples.basic.api;

public interface DemoService {
    String sayHello(String name);
}
```

### 在服务提供方实现接口

DemoServiceImpl.java

```java
public class DemoServiceImpl implements DemoService {
    @Override
    public String sayHello(String name) {
        System.out.println("[" + new SimpleDateFormat("HH:mm:ss").format(new Date()) + "] Hello " + name +
                ", request from consumer: " + RpcContext.getContext().getRemoteAddress());
        return "Hello " + name + ", response from provider: " + RpcContext.getContext().getLocalAddress();
    }
}
```

### 用 Spring 配置声明暴露服务

spring-provider.xml：

```xml
<bean id="demoService" class="org.apache.dubbo.samples.basic.impl.DemoServiceImpl"/>

<dubbo:service interface="org.apache.dubbo.samples.basic.api.DemoService" ref="demoService"/>
```
或者
```xml
<!--1.配置项目的名称-->  
<dubbo:application name="dubbo-service"/>  
<!--2.配置注册中心的地址-->  
<dubbo:registry address="zookeeper://192.168.44.3:2181"/>  
<!--3.配置dubbo包扫描-->  
<dubbo:annotation package="com.itheima.service.impl"/>  
  
<!-- 元数据配置 -->  
<dubbo:metadata-report address="zookeeper://192.168.44.3:2181" />
```


### 服务消费者

#### 引用远程服务

spring-consumer.xml：

```xml
<dubbo:reference id="demoService" check="true" interface="org.apache.dubbo.samples.basic.api.DemoService"/>
```
或者
```xml
<!--dubbo的配置-->  
<!--1.配置项目的名称-->  
<dubbo:application name="dubbo-web">  
 <dubbo:parameter key="qos.port" value="33333"/>  
</dubbo:application>  
<!--2.配置注册中心的地址-->  
<dubbo:registry address="zookeeper://192.168.44.3:2181"/>  
<!--3.配置dubbo包扫描-->  
<dubbo:annotation package="com.itheima.controller"/>
```

#### 加载Spring配置，并调用远程服务

Consumer.java

```java
public static void main(String[] args) {
    ...
    DemoService demoService = (DemoService) context.getBean("demoService");
    String hello = demoService.sayHello("world");
    System.out.println(hello);
}
```

示例步骤或者可以是：
- 创建服务提供者Provider模块
- 创建服务消费者Consumer模块
- 在服务提供者模块编写 UserServiceImpl 提供服务
- 在服务消费者中的 UserController 远程调用UserServiceImpl 提供的服务
- 分别启动两个服务，测试

老版本Dubbo架构：


![](assets/Pasted%20image%2020220402225424.png)

![](assets/Pasted%20image%2020220402225705.png)


## dubbo-admin管理平台
- dubbo-admin 管理平台，是图形化的服务管理页面
- 从注册中心中获取到所有的提供者 / 消费者进行配置管理
- 路由规则、动态配置、服务降级、访问控制、权重调整、负载均衡等管理功能
- dubbo-admin 是一个前后端分离的项目。前端使用vue，后端使用springboot
- 安装 dubbo-admin 其实就是部署该项目


## 高级特性
### 序列化
![](assets/Pasted%20image%2020220402231640.png)

好像新版本有了新的协议？
```xml
<!--
Dubbo3.0在序列化协议安全方面进行了升级加固，推荐使用Tripe协议非Wrapper模式。 该协议默认安全，但需要开发人员编写IDL文件。

Triple协议Wrapper模式下，允许兼容其它序列化数据，提供了良好的兼容性。但其它协议可能存在反序列化安全缺陷，对于Hession2协议，高安全属性用户应当按照samples代码指示，开启白名单模式，框架默认会开启黑名单模式，拦截恶意调用。

不建议使用其它序列化协议，当攻击者可访问Provider接口时，其它序列化协议的安全缺陷，可能导致 Povider 接口命令执行。

若必须使用其它序列化协议，同时希望具备一定安全性。应当开启Token鉴权机制，防止未鉴权的不可信请求来源威胁Provider的安全性。开启Token鉴权机制时，应当同步开启注册中心的鉴权功能。
-->
```

### 地址缓存
注册中心挂了，服务是否可以正常访问？

- 可以，因为dubbo服务消费者在第一次调用时，会将服务提供方地址缓存到本地，以后在调用则不会访问注册中心。
- 当服务提供者地址发生变化时，注册中心会通知服务消费者。

### 超时与重试
问题：服务消费者在调用服务提供者的时候发生了阻塞、等待的情形，这个时候，服务消费者会一直等待下去。在某个峰值时刻，大量的请求都在同时请求服务消费者，会造成线程的大量堆积，势必会造成雪崩

- dubbo 利用超时机制来解决这个问题，设置一个超时时间，在这个时间段内，无法完成服务访问，则自动断开连接。
- 使用timeout属性配置超时时间，默认值1000，单位毫秒。
- 设置了超时时间，在这个时间段内，无法完成服务访问，则自动断开连接。
- 如果出现网络抖动，则这一次请求就会失败。
- Dubbo 提供重试机制来避免类似问题的发生。
- 通过 retries  属性来设置重试次数。默认为 2 次

### 多版本
- 灰度发布：当出现新功能时，会让一部分用户先使用新功能，用户反馈没问题时，再将所有用户迁移到新功能。
- dubbo 中使用version 属性来设置和调用同一个接口的不同版本

### 负载均衡
负载均衡策略（4种）：
- Random ：按权重随机，默认值。按权重设置随机概率。
- RoundRobin ：按权重轮询。
- LeastActive：最少活跃调用数，相同活跃数的随机。
- ConsistentHash：一致性 Hash，相同参数的请求总是发到同一提供者。

### 集群容错
集群容错模式：
- Failover Cluster：失败重试。默认值。当出现失败，重试其它服务器 ，默认重试2次，使用 retries 配置。一般用于读操作
- Failfast Cluster ：快速失败，只发起一次调用，失败立即报错。通常用于写操作。
- Failsafe Cluster ：失败安全，出现异常时，直接忽略。返回一个空结果。
- Failback Cluster ：失败自动恢复，后台记录失败请求，定时重发。通常用于消息通知操作。
- Forking Cluster ：并行调用多个服务器，只要一个成功即返回。
- Broadcast  Cluster ：广播调用所有提供者，逐个调用，任意一台报错则报错。

### 服务降级
可以通过服务降级功能临时屏蔽某个出错的非关键服务，并定义降级后的返回策略。

- 向注册中心写入动态配置覆盖规则：
```java
RegistryFactory registryFactory = ExtensionLoader.getExtensionLoader(RegistryFactory.class).getAdaptiveExtension();
Registry registry = registryFactory.getRegistry(URL.valueOf("zookeeper://10.20.153.10:2181"));
registry.register(URL.valueOf("override://0.0.0.0/com.foo.BarService?category=configurators&dynamic=false&application=foo&mock=force:return+null"));
```
其中：

-   `mock=force:return+null` 表示消费方对该服务的方法调用都直接返回 null 值，不发起远程调用。用来屏蔽不重要服务不可用时对调用方的影响。
-   还可以改为 `mock=fail:return+null` 表示消费方对该服务的方法调用在失败后，再返回 null 值，不抛异常。用来容忍不重要服务不稳定时对调用方的影响。

