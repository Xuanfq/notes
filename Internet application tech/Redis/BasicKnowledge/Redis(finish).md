## 一、Redis常用指令

```
//启动容器
docker run -d -p 6379:6379 -it   --name="myredis"  redis
输入密码：
auth 密码
//进入redis容器
docker exec -it myredis  redis-cli
//退出
quit
exit
//清屏
clear
//获取帮助, 可以使用Tab键来切换
help 命令名称
help @组名
```

## 二、数据类型

**所有的key都为String类型，讨论数据类型是说的value的类型**

### 1、String

#### 基本操作

```
//设置String
set key value
mset key1 value1 key2 value2...
//设置生命周期
setex key seconds value 

//得到String
get key 
mget key1 key2...

//删除String
del key

//向字符串的后面追加字符，如果有就补在后面，如果没有就新建
append key value
```

#### string 类型数据的扩展操作

**String作为数值的操作**

```
//增长指令，只有当value为数字时才能增长
incr key  
incrby key increment  
incrbyfloat key increment //精度问题

//减少指令，有当value为数字时才能减少
decr key  
decrby key increment //精度问题
```

- string在redis内部存储默认就是一个**字符串**，当遇到增减类操作incr，decr时会**转成数值型**进行计算。
- redis所有的操作都是**原子性**的，采用**单线程**处理所有业务，命令是一个一个执行的，因此无需考虑并发带来的数据影响。
- 注意：按数值进行操作的数据，如果原始数据不能转成数值，或超越了redis 数值上限范围，将报错。 9223372036854775807（java中long型数据最大值，Long.MAX_VALUE）

**tips：**

- redis用于控制数据库表主键id，为数据库表主键**提供生成策略**，保障数据库表的主键**唯一性**
- 此方案适用于所有数据库，且支持数据库集群

**指定生命周期**

```
//设置数据的生命周期，单位 秒
setex key seconds value
//设置数据的生命周期，单位 毫秒
psetex key milliseconds value
```

**tips**

- redis 控制数据的生命周期，通过数据是否失效控制业务行为，适用于所有具有时效性限定控制的操作

#### 命名规范

![20200608142355](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231920384-2100649682.png)


### 2、Hash

![20200608142425](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231920806-1891740273.png)


#### 基本操作

```
//插入（如果已存在同名的field，会被覆盖）
hset key field value
hmset key field1 value1 field2 value2...
//插入（如果已存在同名的field，不会被覆盖）
hsetnx key field value

//取出
hget key field
hgetall key

//删除
hdel key field1 field2...

//获取field数量
hlen key

//查看是否存在
hexists key field

//获取哈希表中所有的字段名或字段值 
hkeys key
hvals key

//设置指定字段的数值数据增加指定范围的值 
hincrby key field increment 
hdecrby key field increment
```

#### hash 类型数据操作的注意事项

- hash类型下的value**只能存储字符串**，不允许存储其他数据类型，**不存在嵌套现象**。如果数据未获取到， 对应的值为（nil）
- 每个 hash 可以存储 2^32 - 1 个键值（unsigned int的大小）
- hash类型十分贴近对象的数据存储形式，并且可以灵活添加删除对象属性。但hash设计初衷不是为了存储大量对象而设计的，**切记不可滥用**，更**不可以将hash作为对象列表使用**
- hgetall 操作可以获取全部属性，如果内部field过多，遍历整体**数据效率就很会低**，有可能成为数据访问瓶颈

### 3、List

- 数据存储需求：存储多个数据，并对数据进入存储空间的顺序进行区分
- 需要的存储结构：一个存储空间保存多个数据，且通过数据可以体现进入顺序
- list类型：保存多个数据，底层使用双向链表存储结构实现
- **元素有序，且可重**

#### 基本操作

```/添加修改数据,lpush为从左边添加
/，rpush为从右边添加
lpush key value1 value2 value3...
rpush key value1 value2 value3...

//查看数据, 从左边开始向右查看. 如果不知道list有多少个元素，end的值可以为-1,代表倒数第一个元素
//lpush先进的元素放在最后,rpush先进的元素放在最前面
lrange key start end
//得到长度
llen key
//取出对应索引的元素
lindex key index

//获取并移除元素（从list左边或者右边移除）
lpop key
rpop key
```

#### 拓展操作

```
//规定时间内获取并移除数据,b=block,给定一个时间，如果在指定时间内放入了元素，就移除
blpop key1 key2... timeout
brpop key1 key2... timeout

//移除指定元素 count:移除的个数 value:移除的值。 移除多个相同元素时，从左边开始移除
lrem key count value
```

#### 注意事项

- list中保存的数据都是string类型的，数据总容量是有限的，最多2^32 - 1 个元素 (4294967295)。
- list具有索引的概念，但是操作数据时通常以**队列**的形式进行入队出队(rpush, rpop)操作，或以**栈**的形式进行入栈出栈(lpush, lpop)操作
- 获取全部数据操作结束索引设置为-1 (倒数第一个元素)
- list可以对数据进行分页操作，通常第一页的信息来自于list，第2页及更多的信息通过数据库的形式加载

### 4、Set

- **不重复且无序**

#### 基本操作

```
//添加元素
sadd key member1 member2...

//查看元素
smembers key

//移除元素
srem key member

//查看元素个数
scard key

//查看某个元素是否存在
sismember key member
```

#### 扩展操作

```
//从set中任意选出count个元素
srandmember key count

//从set中任意选出count个元素并移除
spop key count

//求两个集合的交集、并集、差集
sinter key1 key2...
sunion key1 key2...
sdiff key1 key2...

//求两个set的交集、并集、差集，并放入另一个set中
sinterstore destination key1 key2...
sunionstore destination key1 key2...
sdiffstore destination key1 key2...

//求指定元素从原集合放入目标集合中
smove source destination key
```

### 5、sorted_set

- **不重但有序（score）**
- 新的存储需求：数据排序有利于数据的有效展示，需要提供一种可以根据自身特征进行**排序**的方式
- 需要的存储结构：新的存储模型，可以保存**可排序**的数据
- sorted_set类型：在set的存储结构基础上添加可排序字段

![20200608142442](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231921229-576463098.png)

#### 基本操作

```
//插入元素, 需要指定score(用于排序)
zadd key score1 member1 score2 member2

//查看元素(score升序), 当末尾添加withscore时，会将元素的score一起打印出来
zrange key start end (withscore)
//查看元素(score降序), 当末尾添加withscore时，会将元素的score一起打印出来
zrevrange key start end (withscore)

//移除元素
zrem key member1 member2...

//按条件获取数据, 其中offset为索引开始位置，count为获取的数目
zrangebyscore key min max [withscore] [limit offset count]
zrevrangebyscore key max min [withscore] [limit offset count]

//按条件移除元素
zremrangebyrank key start end
zremrangebysocre key min max
//按照从大到小的顺序移除count个值
zpopmax key [count]
//按照从小到大的顺序移除count个值
zpopmin key [count]

//获得元素个数
zcard key

//获得元素在范围内的个数
zcount min max

//求交集、并集并放入destination中, 其中numkey1为要去交集或并集集合的数目
zinterstore destination numkeys key1 key2...
zunionstore destination numkeys key1 key2...
```

**注意**

- min与max用于限定搜索查询的**条件**
- start与stop用于限定**查询范围**，作用于索引，表示开始和结束索引
- offset与count用于限定查询范围，作用于查询结果，表示**开始位置**和**数据总量**

#### 拓展操作

```
//查看某个元素的索引(排名)
zrank key member
zrevrank key member

//查看某个元素索引的值
zscore key member
//增加某个元素索引的值
zincrby key increment member
```

#### 

#### 注意事项

- score保存的数据存储空间是64位，如果是整数范围是-9007199254740992~9007199254740992
- score保存的数据也可以是一个双精度的double值，基于双精度浮点数的特征，**可能会丢失精度**，使用时候要**慎重**
- sorted_set 底层存储还是**基于set**结构的，因此数据**不能重复**，如果重复添加相同的数据，score值将被反复覆盖，**保留最后一次**修改的结果

## 三、通用指令

### 1、Key的特征

- key是一个**字符串**，通过key获取redis中保存的数据

### 2、Key的操作

#### 基本操作

```
//查看key是否存在
exists key

//删除key
del key

//查看key的类型
type key
```

#### 拓展操作（时效性操作）

```
//设置生命周期
expire key seconds
pexpire key milliseconds

//查看有效时间, 如果有有效时间则返回剩余有效时间, 如果为永久有效，则返回-1, 如果Key不存在则返回-2
ttl key
pttl key

//将有时限的数据设置为永久有效
persist key
```

#### 拓展操作（查询操作）

```
//根据key查询符合条件的数据
keys pattern
```

**查询规则**

![20200608142500](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231921481-159024879.png)

#### 拓展操作（其他操作）

```
//重命名key，为了避免覆盖已有数据，尽量少去修改已有key的名字，如果要使用最好使用renamenx
rename key newKey
renamenx key newKey

//查看所有关于key的操作, 可以使用Tab快速切换
help @generic
```

### 3、数据库通用操作

#### 数据库

- Redis为每个服务提供有16个数据库，编号从0到15
- 每个数据库之间的数据相互独立

#### 基本操作

```
//切换数据库 0~15
select index

//其他操作
quit
ping
echo massage
```

#### 拓展操作

```
//移动数据, 必须保证目的数据库中没有该数据
move key db

//查看该库中数据总量
dbsize
```

## 三、Jedis

**JAVA**操作Redis需要导入jar或引入Maven依赖

### 1、Java操作redis的步骤

- 连接Redis

```java
//参数为Redis所在的ip地址和端口号
Jedis jedis = new Jedis(String host, int port)
```

- 操作Redis

```java
//操作redis的指令和redis本身的指令几乎一致
jedis.set(String key, String value);
```

- 断开连接

```java
jedis.close();
```

### 2、配置工具

- 配置文件

```properties
redis.host=47.103.10.63
redis.port=6379
redis.maxTotal=30 # 连接池中总连接的最大数量
redis.maxIdle=10 # 连接池中最大活跃数
```

- 工具类

```java
import redis.clients.jedis.Jedis;
import redis.clients.jedis.JedisPool;
import redis.clients.jedis.JedisPoolConfig;
import java.util.ResourceBundle;

/**
 * @author Chen Panwen
 * @data 2020/4/6 16:24
 */
public class JedisUtil {
	private static Jedis jedis = null;
	private static String host = null;
	private static int port;
	private static int maxTotal;
	private static int maxIdle;

	//使用静态代码块，只加载一次
	static {
		//读取配置文件
		ResourceBundle resourceBundle = ResourceBundle.getBundle("redis");
		//获取配置文件中的数据
		host = resourceBundle.getString("redis.host");
		port = Integer.parseInt(resourceBundle.getString("redis.port"));
		//读取最大连接数
		maxTotal = Integer.parseInt(resourceBundle.getString("redis.maxTotal"));
		//读取最大活跃数
		maxIdle = Integer.parseInt(resourceBundle.getString("redis.maxIdle"));
		JedisPoolConfig jedisPoolConfig = new JedisPoolConfig();
		jedisPoolConfig.setMaxTotal(maxTotal);
		jedisPoolConfig.setMaxIdle(maxIdle);
		//获取连接池
		JedisPool jedisPool = new JedisPool(jedisPoolConfig, host, port);
		jedis = jedisPool.getResource();
	}

	public Jedis getJedis() {
		return jedis;
	}
}
```

## 四、持久化

### Redis容器配置redis.conf

- redis容器里边的配置文件是需要在**创建容器时映射**进来的

  ```
  停止容器：docker container stop myredis
  删除容器：docker container rm myredis
  ```

- 重新开始创建容器

  ```
  1. 创建docker统一的外部配置文件
  
  mkdir -p docker/redis/{conf,data}
  
  2. 在conf目录创建redis.conf的配置文件
  
  touch /docker/redis/conf/redis.conf
  
  3. redis.conf文件的内容需要自行去下载，网上很多
  
  4. 创建启动容器，加载配置文件并持久化数据
  
  docker run -d --privileged=true -p 6379:6379 -v /docker/redis/conf/redis.conf:/etc/redis/redis.conf -v /docker/redis/data:/data --name myredis redis redis-server /etc/redis/redis.conf --appendonly yes
  ```

- 文件目录

  ```
  /docker/redis
  ```

### 1、简介

#### 什么是持久化？

利用**永久性**存储介质将数据进行保存，在特定的时间将保存的数据进行恢复的工作机制称为持久化。

#### 为什么要持久化

**防止**数据的意外**丢失**，确保数据**安全性**

#### 持久化过程保存什么

- 将当前**数据状态**进行保存，**快照**形式，存储数据结果，存储格式简单，关注点在**数据**
- 将数据的**操作过程**进行保存，**日志**形式，存储操作过程，存储格式复杂，关注点在数据的操作**过程**

![20200608142523](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231921772-1346700975.png)
### 2、RDB

#### RDB启动方式 —— save

- 命令

  ```
  save
  ```

- 作用

  手动执行一次保存操作

#### RDB配置相关命令

- dbfilename dump.rdb
  - 说明：设置本地数据库文件名，默认值为 dump.rdb
  - 经验：通常设置为dump-端口号.rdb
- dir
  - 说明：设置存储.rdb文件的路径
  - 经验：通常设置成存储空间较大的目录中，目录名称data
- rdbcompression yes
  - 说明：设置存储至本地数据库时是否压缩数据，默认为 yes，采用 LZF 压缩
  - 经验：通常默认为开启状态，如果设置为no，可以节省 CPU 运行时间，但会使存储的文件变大（巨大）
- rdbchecksum yes
  - 说明：设置是否进行RDB文件格式校验，该校验过程在写文件和读文件过程均进行
  - 经验：通常默认为开启状态，如果设置为no，可以节约读写性过程约10%时间消耗，但是存储一定的数据损坏风险

#### RDB启动方式 —— save指令工作原理

![20200608142541](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231922033-823244179.png)

**注意**：**save指令**的执行会**阻塞**当前Redis服务器，直到当前RDB过程完成为止，有可能会造成**长时间阻塞**，线上环境**不建议使用**。

#### RDB启动方式 —— bgsave

- 命令

  ```
  bgsave
  ```

- 作用

  手动启动后台保存操作，但**不是立即执行**

#### RDB启动方式 —— bgsave指令工作原理

![20200608142558](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231922310-270417953.png)

**注意**： **bgsave命令**是针对save阻塞问题做的**优化**。Redis内部所有涉及到RDB操作都采用bgsave的方式，save命令可以放弃使用，推荐使用bgsave

**bgsave的保存操作可以通过redis的日志查看**

```
docker logs myredis
```

#### RDB启动方式 —— save配置

- 配置

  ```
  save second changes
  ```

- 作用

  满足**限定时间**范围内key的变化数量达到**指定数量**即进行持久化

- 参数

  - second：监控时间范围
  - changes：监控key的变化量

- 配置位置

  在**conf文件**中进行配置

#### RDB启动方式 —— save配置原理

![20200608142617](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231922584-128293909.png)

**注意**：

- save配置要根据实际业务情况进行设置，频度过高或过低都会出现性能问题，结果可能是灾难性的
- save配置中对于second与changes设置通常具有**互补对应**关系（一个大一个小），尽量不要设置成包含性关系
- save配置启动后执行的是**bgsave操作**

#### RDB启动方式对比

![20200608142629](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231923510-229851069.png)

#### RDB优缺点

- 优点
  - RDB是一个紧凑压缩的二进制文件，**存储效率较高**
  - RDB内部存储的是redis在某个时间点的数据快照，非常适合用于**数据备份，全量复制**等场景
  - RDB恢复数据的**速度**要比AOF**快**很多
  - 应用：服务器中每X小时执行bgsave备份，并将RDB文件拷贝到远程机器中，**用于灾难恢复**
- 缺点
  - RDB方式无论是执行指令还是利用配置，**无法做到实时持久化**，具有较大的可能性丢失数据
  - bgsave指令每次运行要执行fork操作**创建子进程**，要**牺牲**掉一些**性能**
  - Redis的众多版本中未进行RDB文件格式的版本统一，有可能出现各版本服务之间数据格式**无法兼容**现象

### 3、AOF

#### AOF概念

- AOF(append only file)持久化：以独立日志的方式记录**每次**写命令，重启时再重新执行AOF文件中命令，以达到恢复数据的目的。与RDB相比可以简单描述为改记录数据为记录数据产生的过程
- AOF的主要作用是解决了数据持久化的实时性，目前已经是Redis持久化的**主流**方式

#### AOF写数据过程

![20200608142645](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231923797-33854552.png)

#### AOF写数据三种策略(appendfsync)

- always
  - 每次写入操作均同步到AOF文件中，数据零误差，**性能较低**,**不建议使用**
- everysec
  - 每秒将缓冲区中的指令同步到AOF文件中，数据准确性较高，**性能较高** ，**建议使用**，也是默认配置
  - 在系统突然宕机的情况下丢失1秒内的数据
- no
  - 由操作系统控制每次同步到AOF文件的周期，整体过程**不可控**

#### AOF功能开启

- 配置

  ```conf
  appendonly yes|no
  ```

  -  作用
    - 是否开启AOF持久化功能，**默认为不开启状态**

- 配置

  ```conf
  appendfsync always|everysec|no
  ```

  - 作用
    - AOF写数据策略

#### AOF重写

##### 作用

- 降低磁盘占用量，提高磁盘利用率
- 提高持久化效率，降低持久化写时间，提高IO性能
- 降低数据恢复用时，提高数据恢复效率

##### 规则

- 进程内已超时的数据不再写入文件

- 忽略

  无效指令，重写时使用进程内数据直接生成，这样新的AOF文件

  只保留最终数据的写入命令

  - 如del key1、 hdel key2、srem key3、set key4 111、set key4 222等

- 对同一数据的多条写命令合并为一条命令

  - 如lpush list1 a、lpush list1 b、 lpush list1 c 可以转化为：lpush list1 a b c
  - 为防止数据量过大造成客户端缓冲区溢出，对list、set、hash、zset等类型，每条指令最多写入64个元素

##### 如何使用

- 手动重写

  ```
  bgrewriteaof
  ```

- 自动重写

  ```
  auto-aof-rewrite-min-size size 
  auto-aof-rewrite-percentage percentage
  ```

##### 工作原理

![20200608142657](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231924104-704418699.png)

##### AOF自动重写

- 自动重写触发条件设置

  ```
  //触发重写的最小大小
  auto-aof-rewrite-min-size size 
  //触发重写须达到的最小百分比
  auto-aof-rewrite-percentage percent
  ```

- 自动重写触发比对参数（ 运行指令info Persistence获取具体信息 ）

  ```
  //当前.aof的文件大小
  aof_current_size 
  //基础文件大小
  aof_base_size
  ```

- 自动重写触发条件

  ![20200608142715](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231924334-638941231.png)

##### 工作原理

![20200608142734](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231924581-551572702.png)

![20200608142755](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231924834-655467162.png)

![20200608142814](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231925084-1047256523.png)

##### 缓冲策略

AOF缓冲区同步文件策略，由参数**appendfsync**控制

- write操作会触发延迟写（delayed write）机制，Linux在内核提供页缓冲区用 来提高硬盘IO性能。write操作在写入系统缓冲区后直接返回。同步硬盘操作依 赖于系统调度机制，列如：缓冲区页空间写满或达到特定时间周期。同步文件之 前，如果此时系统故障宕机，缓冲区内数据将丢失。
- fsync针对单个文件操作（比如AOF文件），做强制硬盘同步，fsync将阻塞知道 写入硬盘完成后返回，保证了数据持久化。

#### 4、RDB VS AOF

![20200608142837](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231925362-289050337.png)

##### RDB与AOF的选择之惑

- 对数据非常敏感，建议使用默认的AOF持久化方案

  - AOF持久化策略使用**everysecond**，每秒钟fsync一次。该策略redis仍可以保持很好的处理性能，当出现问题时，最多丢失0-1秒内的数据。
  - 注意：由于AOF文件**存储体积较大**，且**恢复速度较慢**

- 数据呈现阶段有效性，建议使用RDB持久化方案

  - 数据可以良好的做到阶段内无丢失（该阶段是开发者或运维人员手工维护的），且**恢复速度较快**，阶段 点数据恢复通常采用RDB方案
  - 注意：利用RDB实现紧凑的数据持久化会使Redis降的很低

- 综合比对

  - RDB与AOF的选择实际上是在做一种权衡，每种都有利有弊
  - 如不能承受数分钟以内的数据丢失，对业务数据非常**敏感**，选用**AOF**
  - 如能承受数分钟以内的数据丢失，且追求大数据集的**恢复速度**，选用**RDB**
  - **灾难恢复选用RDB**
  - 双保险策略，同时开启 RDB 和 AOF，重启后，Redis优先使用 AOF 来恢复数据，降低丢失数据

## 五、Redis事务

### 1、Redis事务的定义

redis事务就是一个命令执行的队列，将一系列预定义命令**包装成一个整体**（一个队列）。当执行时，**一次性按照添加顺序依次执行**，中间不会被打断或者干扰

### 2、事务的基本操作

- 开启事务

  ```shell
  multi
  ```

  - 作用
    - 作设定事务的开启位置，此指令执行后，后续的所有指令均加入到事务中

- 取消事务

  ```shell
  discard
  ```

  - 作用
    - 终止当前事务的定义，发生在multi之后，exec之前

- 执行事务

  ```shell
  exec
  ```

  - 作用
    - 设定事务的结束位置，同时执行事务。**exec与multi成对出现**，成对使用

### 3、事务操作的基本流程

![20200608142857](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231925633-560852709.png)

### 4、事务操作的注意事项

**定义事务的过程中，命令格式输入错误怎么办？**

- 语法错误
  - 指命令书写格式有误 例如执行了一条不存在的指令
- 处理结果
  - 如果定义的事务中所包含的命令存在语法错误，整体事务中**所有命令均不会执行**。包括那些语法正确的命令

**定义事务的过程中，命令执行出现错误怎么办？**

- 运行错误
  - 指命令**格式正确**，但是**无法正确的执行**。例如对list进行incr操作
- 处理结果
  - 能够正确运行的命令会执行，运行错误的命令不会被执行

**注意**：已经执行完毕的命令对应的数据**不会自动回滚**，需要程序员自己在代码中实现回滚。

### 5、基于特定条件的事务执行

#### 锁

- 对 key 添加监视锁，在执行exec前如果key发生了变化，终止事务执行

  ```
  watch key1, key2....
  ```

- 取消对**所有**key的监视

  ```
  unwatch
  ```

#### 分布式锁

- 使用 setnx 设置一个公共锁

  ```
  //上锁
  setnx lock-key value
  //释放锁
  del lock-key
  ```

  - 利用setnx命令的返回值特征，有值（被上锁了）则返回设置失败，无值（没被上锁）则返回设置成功
  - 操作完毕通过del操作释放锁

**注意**：上述解决方案是一种**设计概念**，依赖规范保障，具有风险性

#### 分布式锁加强

- 使用 expire 为锁key添加**时间限定**，到时不释放，放弃锁

  ```
  # 先setnx lock-key，再执行以下命令
  expire lock-key seconds
  pexpire lock-key milliseconds
  ```

- 由于操作通常都是微秒或毫秒级，因此该锁定时间**不宜设置过大**。具体时间需要业务测试后确认。

  - 例如：持有锁的操作最长执行时间127ms，最短执行时间7ms。
  - 测试百万次最长执行时间对应命令的最大耗时，测试百万次网络延迟平均耗时
  - 锁时间设定推荐：最大耗时*120%+平均网络延迟*110%
  - 如果业务最大耗时<<网络平均延迟，通常为2个数量级，取其中单个耗时较长即可

## 六、删除策略

### 1、数据删除策略

- 定时删除
- 惰性删除
- 定期删除

#### 时效性数据的存储结构

- Redis中的数据，在expire中以哈希的方式保存在其中。其value是数据在内存中的地址，filed是对应的生命周期

![20200608142921](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231925867-218488665.png)

#### 数据删除策略的目标

在内存占用与CPU占用之间寻找一种**平衡**，顾此失彼都会造成整体redis性能的下降，甚至引发服务器宕机或内存泄露

### 2、三种删除策略

#### 定时删除

- 创建一个定时器，当key设置有过期时间，且过期时间到达时，由定时器任务**立即执行**对键的删除操作
- 优点：**节约内存**，到时就删除，快速释放掉不必要的内存占用
- 缺点：**CPU压力很大**，无论CPU此时负载量多高，均占用CPU，会影响redis服务器响应时间和指令吞吐量
- 总结：用处理器性能换取存储空间 （**拿时间换空间**）

#### 惰性删除

- 数据到达过期时间，不做处理。等下次访问该数据时
  - 如果未过期，返回数据
  - 发现已过期，删除，返回不存在
- 优点：**节约CPU性能**，发现必须删除的时候才删除
- 缺点：**内存压力很大**，出现长期占用内存的数据
- 总结：用存储空间换取处理器性能 （拿空间换时间）

#### 定期删除

![20200608142941](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231926211-340305003.png)

- 周期性轮询redis库中的时效性数据，采用**随机抽取的策略**，利用过期数据占比的方式控制删除频度
- 特点1：CPU性能占用设置有峰值，检测频度可自定义设置
- 特点2：内存压力不是很大，长期占用内存的冷数据会被持续清理
- 总结：周期性抽查存储空间 （随机抽查，重点抽查）

### 3、逐出算法

**当新数据进入redis时，如果内存不足怎么办？ **

- Redis使用内存存储数据，在执行每一个命令前，会调用**freeMemoryIfNeeded()**检测内存是否充足。如果内存不满足新加入数据的最低存储要求，redis要临时删除一些数据为当前指令清理存储空间。清理数据的策略称为**逐出算法**
- **注意**：逐出数据的过程不是100%能够清理出足够的可使用的内存空间，如果不成功则反复执行。当对所有数据尝试完毕后，如果不能达到内存清理的要求，将出现错误信息。

#### 影响数据逐出的相关配置

- 最大可使用内存

  ```
  maxmemory
  ```

  占用物理内存的比例，默认值为0，表示不限制。生产环境中根据需求设定，通常设置在50%以上。

- 每次选取待删除数据的个数

  ```
  maxmemory-samples
  ```

  选取数据时并不会全库扫描，导致严重的性能消耗，降低读写性能。因此采用随机获取数据的方式作为待检测删除数据

- 删除策略

  ```
  maxmemory-policy
  ```

  达到最大内存后的，对被挑选出来的数据进行删除的策略

#### 影响数据逐出的相关配置

![20200608142953](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231926559-1132981033.png)

**LRU**：最长时间没被使用的数据

**LFU**：一段时间内使用次数最少的数据

#### **数据逐出策略配置依据**

- 使用**INFO命令**输出监控信息，查询缓存 **hit 和 miss** 的次数，根据业务需求调优Redis配置

![20200608143004](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231926815-428749382.png)

## 七、高级数据类型

### 1、Bitmaps

![](assets/Pasted%20image%2020220604161935.png)

Redis提供了Bitmaps这个“数据结构”，可以实现对位的操作。把数据结构加上引号主要因为：
- Bitmaps本身不是一种数据结构，**实际上它就是字符串**，，但它可以对字符串的位进行操作；
- Bitmaps单独提供了一套命令，所以在Redis中使用Bitmaps和使用字符串的方法不太一样;
- 设置键的第offset个位的值（从0算起），假设现在有20个用户，userid=0，5，11，15，19的用户对网站进行了访问，那么当前Bitmaps初始化结果如上图所示。
- 很多应用的用户id以一个指定的数字（例如10000）开头，直接将用户id和Bitmaps的偏移量对应势必会造成一定的浪费，通常的做法是每次做setbit操作时将用户id减去这个指定数字。

>
>可以把Bitmaps想象成一个以位为单位的数组，数组的每个单元只能存储0和1，数组的下标在Bitmaps中叫做偏移量。
>

#### 基础操作

- 获取指定key对应偏移量上的bit值

  ```
  getbit key offset
  ```

- 设置指定key对应偏移量上的bit值，value只能是1或0

  ```
  setbit key offset value
  ```

#### 扩展操作

- 对指定key按位进行交、并、非、异或操作，并将结果**保存到destKey**中

  ```
  bitop op destKey key1 [key2...]
  ```

  - and：交
  - or：并
  - not：非
  - xor：异或

- 统计指定key中1的数量

  ```
  bitcount key [start end]
  ```

### 2、HyperLogLog

#### 基数

- 基数是数据集**去重后元素个数**
- HyperLogLog 是用来做基数统计的，运用了LogLog的算法

![20200608143020](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231926978-1928050737.png)

#### 基本操作

- 添加数据

  ```
  pfadd key element1, element2...
  ```

- 统计数据

  ```
  pfcount key1 key2....
  ```

- 合并数据

  ```
  pfmerge destkey sourcekey [sourcekey...]
  ```

#### 相关说明

- 用于进行基数统计，**不是集合，不保存数据**，只记录数量而不是具体数据
- 核心是基数估算算法，最终数值**存在一定误差**
- 误差范围：基数估计的结果是一个带有 0.81% 标准错误的近似值
- **耗空间极小**，每个hyperloglog key占用了12K的内存用于标记基数
- pfadd命令不是一次性分配12K内存使用，会随着基数的增加内存**逐渐增大**
- Pfmerge命令**合并后占用**的存储空间为**12K**，无论合并之前数据量多少

### 3、GEO

#### 基本操作

- 添加坐标点

  ```
  geoadd key longitude latitude member [longitude latitude member ...] 
  georadius key longitude latitude radius m|km|ft|mi [withcoord] [withdist] [withhash] [count count]
  ```

- 获取坐标点

  ```
  geopos key member [member ...] 
  georadiusbymember key member radius m|km|ft|mi [withcoord] [withdist] [withhash] [count count]
  ```

- 计算坐标点距离

  ```
  geodist key member1 member2 [unit] 
  geohash key member [member ...]
  ```

## 八、主从复制

### 1、简介

#### 多台服务器连接方案

![20200608143033](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231927205-2140193313.png)

- 提供数据方：master
  - 主服务器，主节点，主库
  - 主客户端
- 接收数据的方：slave
  - 从服务器，从节点，从库
  - 从客户端
- 需要解决的问题
  - **数据同步**
- 核心工作
  - master的数据**复制**到slave中

#### 主从复制

主从复制即将master中的数据即时、有效的**复制**到slave中

特征：一个master可以拥有多个slave，一个slave只对应一个master

职责：

- master:
  - 写数据
  - 执行写操作时，将出现变化的数据自动**同步**到slave
  - 读数据（可忽略）
- slave:
  - 读数据
  - 写数据（**禁止**）

### 2、作用

- 读写分离：master写、slave读，提高服务器的读写负载能力
- 负载均衡：基于主从结构，配合读写分离，由slave分担master负载，并根据需求的变化，改变slave的数量，通过多个从节点分担数据读取负载，大大提高Redis服务器并发量与数据吞吐量
- 故障恢复：当master出现问题时，由slave提供服务，实现快速的故障恢复
- 数据冗余：实现数据热备份，是持久化之外的一种数据冗余方式
- 高可用基石：基于主从复制，构建哨兵模式与集群，实现Redis的高可用方案

### 3、工作流程

#### **总述**

- 主从复制过程大体可以分为3个阶段
  - 建立连接阶段（即准备阶段）
  - 数据同步阶段
  - 命令传播阶段

![20200608143046](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231927440-491519390.png)

#### 阶段一：建立连接

- 建立slave到master的连接，使master能够识别slave，并保存slave端口号

  ![20200608143102](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231927724-893591768.png)

**主从连接（slave连接master）**

- 方式一：客户端发送命令

  ```
  slaveof <masterip> <masterport>
  ```

- 方式二：启动服务器参数

  ```
  redis-server -slaveof <masterip> <masterport>
  ```

- 方式三：服务器配置 （常用）

  ```
  slaveof <masterip> <masterport>
  ```

  ![20200821110845](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231934057-1792601042.png)

**主从断开连接**

- **客户端**发送命令

  ```
  slaveof no one
  ```

  - 说明： slave断开连接后，**不会删除已有数据**，只是不再接受master发送的数据

**授权访问**

- master客户端发送命令设置密码

  ```
  requirepass <password>
  ```

- master配置文件设置密码

  ```
  config set requirepass <password> 
  config get requirepass
  ```

- slave客户端发送命令设置密码

  ```
  auth <password>
  ```

- slave配置文件设置密码

  ```
  masterauth <password>
  ```

- slave启动服务器设置密码

  ```
  redis-server –a <password>
  ```

#### 阶段二：数据同步阶段

![20200608143117](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231928032-528371964.png)

- 全量复制

  - 将master执行bgsave之前，master中所有的数据同步到slave中

- 部分复制

  （增量复制）

  - 将master执行bgsave操作中，新加入的数据（复制缓冲区中的数据）传给slave，slave通过bgrewriteaof指令来恢复数据

##### 数据同步阶段master说明

1. 如果master数据量巨大，数据同步阶段应**避开流量高峰期**，**避免**造成master**阻塞**，影响业务正常执行
2. 复制缓冲区大小设定不合理，会导致数据溢出。如进行全量复制周期太长，进行部分复制时发现数据已经存在丢失的情况，必须进行第二次全量复制，致使slave陷入**死循环**状态。

```
repl-backlog-size 1mb
```

1. master单机内存占用主机内存的比例不应过大，建议使用50%-70%的内存，留下30%-50%的内存用于执 行bgsave命令和创建复制缓冲区

##### 数据同步阶段slave说明

1. 为避免slave进行全量复制、部分复制时服务器响应阻塞或数据不同步，**建议关闭**此期间的对外服务

```
slave-serve-stale-data yes|no
```

1. 数据同步阶段，master发送给slave信息可以理解master是slave的一个客户端，主动向slave发送命令
2. 多个slave同时对master请求数据同步，master发送的RDB文件增多，会对带宽造成巨大冲击，如果master带宽不足，因此数据同步需要根据业务需求，适量错峰
3. slave过多时，建议调整拓扑结构，由一主多从结构变为树状结构，中间的节点既是master，也是 slave。注意使用树状结构时，由于层级深度，导致深度越高的slave与最顶层master间数据同步延迟较大，**数据一致性变差，应谨慎选择**

#### 阶段三：命令传播阶段

- 当master数据库状态被修改后，导致主从服务器数据库状态不一致，此时需要让主从数据同步到一致的状态，**同步**的动作称为**命令传播**
- master将接收到的数据变更命令发送给slave，slave接收命令后执行命令

- 主从复制过程大体可以分为3个阶段
  - 建立连接阶段（即准备阶段）
  - 数据同步阶段
  - 命令传播阶段

##### 命令传播阶段的部分复制

- 命令传播阶段出现了断网现象
  - 网络闪断闪连
  - 短时间网络中断
  - 长时间网络中断

- 部分复制的**三个核心要素**
  - 服务器的运行 id（run id）
  - 主服务器的复制积压缓冲区
  - 主从服务器的复制偏移量

##### 服务器运行ID（runid）

- 概念：服务器运行ID是每一台服务器每次运行的身份识别码，一台服务器多次运行可以生成多个运行id
- 组成：运行id由40位字符组成，是一个随机的十六进制字符 例如：
  - fdc9ff13b9bbaab28db42b3d50f852bb5e3fcdce
- 作用：运行id被用于在服务器间进行传输，识别身份
  - 如果想两次操作均对同一台服务器进行，必须每次操作携带对应的运行id，用于对方识别
- 实现方式：运行id在每台服务器启动时自动生成的，master在首次连接slave时，会将自己的运行ID发送给slave，slave保存此ID，通过**info Server**命令，可以查看节点的runid

##### 复制缓冲区

- 概念：复制缓冲区，又名复制积压缓冲区，是一个**先进先出（FIFO）的队列**，用于存储服务器执行过的命令，每次传播命令，master都会将传播的命令记录下来，并存储在复制缓冲区
- 由来：每台服务器启动时，如果开启有AOF或被连接成为master节点，即创建复制缓冲区
- 作用：用于保存master收到的所有指令（仅影响数据变更的指令，例如set，select）
- 数据来源：当master接收到主客户端的指令时，除了将指令执行，会将该指令存储到缓冲区中

![20200608143134](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231928282-862743091.png)

##### 复制缓冲区内部工作原理

- 组成

  - 偏移量
  - 字节值

- 工作原理

  - 通过offset区分不同的slave当前数据传播的差异
  - master记录**已发送**的信息对应的offset
  - slave记录**已接收**的信息对应的offset

  ![20200608143149](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231928568-215284702.png)

##### 主从服务器复制偏移量（offset）

- 概念：一个数字，描述复制缓冲区中的指令字节位置
- 分类：
  - master复制偏移量：记录发送给所有slave的指令字节对应的位置（多个）
  - slave复制偏移量：记录slave接收master发送过来的指令字节对应的位置（一个）
- 数据来源： master端：发送一次记录一次 slave端：接收一次记录一次
- 作用：**同步信息**，比对master与slave的差异，当slave断线后，恢复数据使用

##### 数据同步+命令传播阶段工作流程

![20200608143228](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231928953-1695070385.png)

#### 心跳机制

- 进入**命令传播阶段后**，master与slave间需要进行信息交换，使用心跳机制进行维护，实现双方连接保持在线
- master心跳：
  - 指令：PING
  - 周期：由repl-ping-slave-period决定，默认10秒
  - 作用：判断slave是否在线
  - 查询：INFO replication 获取slave最后一次连接时间间隔，lag项维持在0或1视为正常
- slave心跳任务
  - 指令：REPLCONF ACK {offset}
  - 周期：1秒
  - 作用1：汇报slave自己的复制偏移量，获取最新的数据变更指令
  - 作用2：判断master是否在线

##### 心跳阶段注意事项

- 当slave多数掉线，或延迟过高时，master为保障数据稳定性，将拒绝所有信息同步操作

  ```
  min-slaves-to-write 2 
  min-slaves-max-lag 8
  ```

  - slave数量少于2个，或者所有slave的延迟都大于等于10秒时，强制关闭master写功能，停止数据同步

- slave数量由slave发送**REPLCONF ACK**命令做确认

- slave延迟由slave发送**REPLCONF ACK**命令做确认

#### 完整流程

![20200608143241](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231929300-124750468.png)

#### 常见问题

![20200608143304](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231929627-137351942.png)

![20200608143317](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231929904-1857450828.png)

#### 频繁的网络中断

![20200608143327](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231930178-959260299.png)

![20200821110907](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231934324-995904755.png)

#### 数据不一致

![20200608143352](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231930495-1537230707.png)

## 九、哨兵

### 1、简介

哨兵(sentinel) 是一个**分布式系统**，用于对主从结构中的每台服务器进行**监控**，当出现故障时通过投票机制**选择**新的master并将所有slave连接到新的master。

![20200608143401](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231930753-855461353.png)

### 2、作用

- 监控
  - 不断的检查master和slave是否正常运行。 master存活检测、master与slave运行情况检测
- 通知（提醒）
  - 当被监控的服务器出现问题时，向其他（哨兵间，客户端）发送通知。
- 自动故障转移
  - 断开master与slave连接，选取一个slave作为master，将其他slave连接到新的master，并告知客户端新的服务器地址

**注意：**
哨兵也是一台**redis服务器**，只是不提供数据服务 通常哨兵配置数量为**单数**

### 3、配置哨兵

- 配置一拖二的主从结构

- 配置三个哨兵（配置相同，端口不同）

  - 参看sentinel.conf

- 启动哨兵

  ```
  redis-sentinel sentinel端口号 .conf
  ```

![20200608143413](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231931092-108699964.png)

### 4、工作原理

#### 监控阶段

- 用于同步各个节点的状态信息
  - 获取各个sentinel的状态（是否在线）
- 获取master的状态
  - master属性
    - runid
    - role：master
    - 各个slave的详细信息
- 获取所有slave的状态（根据master中的slave信息）
  - slave属性
    - runid
    - role：slave
    - master_host、master_port
    - offset
    - …

![20200608143539](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231931382-822339247.png)

![20200608143602](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231931678-618589608.png)

#### 通知阶段

- 各个哨兵将得到的信息相互同步（信息对称）

![20200608143614](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231932034-901079383.png)

#### 故障转移

##### 确认master下线

- 当某个哨兵发现主服务器挂掉了，会将master中的SentinelRedistance中的master改为**SRI_S_DOWN**（主观下线），并通知其他哨兵，告诉他们发现master挂掉了。
- 其他哨兵在接收到该哨兵发送的信息后，也会尝试去连接master，如果超过半数（配置文件中设置的）确认master挂掉后，会将master中的SentinelRedistance中的master改为**SRI_O_DOWN**（客观下线）

![20200608143633](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231932339-1048938190.png)

##### 推选哨兵进行处理

- 在确认master挂掉以后，会推选出一个哨兵来进行故障转移工作（由该哨兵来指定哪个slave来做新的master）。
- 筛选方式是哨兵互相发送消息，并且参与投票，票多者当选。

![20200608143649](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231932650-1133560162.png)

##### 具体处理

- 由推选出来的哨兵对当前的slave进行筛选，筛选条件有：
  - 服务器列表中挑选备选master
  - 在线的
  - 响应慢的
  - 与原master断开时间久的
  - 优先原则
    - 优先级
    - offset
    - runid
  - 发送指令（ sentinel ）
    - 向新的master发送**slaveof no one**(断开与原master的连接)
    - 向其他slave发送slaveof 新masterIP端口（让其他slave与新的master相连）

## 十、集群

### 1、简介

#### 集群架构

- 集群就是使用网络将若干台计算机**联通**起来，并提供**统一的管理方式**，使其对外呈现单机的服务效果

#### 集群作用

- 分散单台服务器的访问压力，实现**负载均衡**
- 分散单台服务器的存储压力，实现**可扩展性**
- **降低**单台服务器宕机带来的**业务灾难**

### 2、Redis集群结构设计

#### 数据存储设计

- 通过算法设计，计算出key应该保存的位置
- 将所有的存储空间计划切割成16384份，每台主机保存一部分 每份代表的是一个存储空间，不是一个key的保存空间
- 将key按照计算出的结果放到对应的存储空间

![20200608143701](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231932880-1743842657.png)

![20200608143712](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231933049-1903264241.png)

- 增强可扩展性 ——槽

![20200608143720](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231933248-811572907.png)

#### 集群内部通讯设计

- 各个数据库互相连通，保存各个库中槽的编号数据
- 一次命中，直接返回
- 一次未命中，告知具体的位置，key再直接去找对应的库保存数据

![20200608143733](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231933538-660306455.png)

## 十一、企业级解决方案

### 1、缓存预热

#### 问题排查

- 请求数量较高
- 主从之间数据吞吐量较大，数据同步操作频度较高

#### 解决方案

- 前置准备工作：
  - 日常例行统计数据访问记录，统计访问频度较高的热点数据
  - 利用LRU数据删除策略，构建数据留存队列 例如：storm与kafka配合
- 准备工作：
  - 将统计结果中的数据分类，根据级别，redis优先加载级别较高的热点数据
  - 利用分布式多服务器同时进行数据读取，提速数据加载过程
  - 热点数据主从同时预热
- 实施：
  - 使用脚本程序固定触发数据预热过程
  - 如果条件允许，使用了CDN（内容分发网络），效果会更好

#### 总结

缓存预热就是系统启动前，提前将相关的缓存数据直接加载到缓存系统。避免在用户请求的时候，先查询数据库，然后再将数据缓存的问题！用户直接查询事先被预热的缓存数据！

### 2、缓存雪崩

#### 数据库服务器崩溃（1）

1. 系统平稳运行过程中，忽然数据库连接量激增
2. 应用服务器无法及时处理请求
3. 大量408，500错误页面出现
4. 客户反复刷新页面获取数据
5. 数据库崩溃
6. 应用服务器崩溃
7. 重启应用服务器无效
8. Redis服务器崩溃
9. Redis集群崩溃
10. 重启数据库后再次被瞬间流量放倒

#### 问题排查

1. 在一个**较短**的时间内，缓存中较多的key**集中过期**
2. 此周期内请求访问过期的数据，redis未命中，redis向数据库获取数据
3. 数据库同时接收到大量的请求无法及时处理
4. Redis大量请求被积压，开始出现超时现象
5. 数据库流量激增，数据库崩溃
6. 重启后仍然面对缓存中无数据可用
7. Redis服务器资源被严重占用，Redis服务器崩溃
8. Redis集群呈现崩塌，集群瓦解
9. 应用服务器无法及时得到数据响应请求，来自客户端的请求数量越来越多，应用服务器崩溃
10. 应用服务器，redis，数据库全部重启，效果不理想

#### 问题分析

- 短时间范围内
- 大量key集中过期

#### 解决方案（道）

1. 更多的页面静态化处理
2. 构建**多级缓存架构** Nginx缓存+redis缓存+ehcache缓存
3. 检测Mysql严重耗时业务进行优化 对数据库的瓶颈排查：例如超时查询、耗时较高事务等
4. 灾难预警机制 监控redis服务器性能指标
   - CPU占用、CPU使用率
   - 内存容量
   - 查询平均响应时间
   - 线程数
5. 限流、降级 短时间范围内牺牲一些客户体验，限制一部分请求访问，降低应用服务器压力，待业务低速运转后再逐步放开访问

解决方案（术）

1. LRU与LFU切换
2. 数据有效期策略调整
   - 根据业务数据有效期进行**分类错峰**，A类90分钟，B类80分钟，C类70分钟
   - 过期时间使用固定时间+随机值的形式，**稀释**集中到期的key的数量
3. **超热**数据使用永久key
4. 定期维护（自动+人工） 对即将过期数据做访问量分析，确认是否延时，配合访问量统计，做热点数据的延时
5. 加锁 **慎用！**

#### 总结

缓存雪崩就是**瞬间过期数据量太大**，导致对数据库服务器造成压力。如能够**有效避免过期时间集中**，可以有效解决雪崩现象的出现 （约40%），配合其他策略一起使用，并监控服务器的运行数据，根据运行记录做快速调整。

![20200608143749](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231933839-875957081.png)

### 3、缓存击穿

#### 数据库服务器崩溃（2）

1. 系统平稳运行过程中
2. 数据库连接量**瞬间激增**
3. Redis服务器无大量key过期
4. Redis内存平稳，无波动
5. Redis服务器CPU正常
6. **数据库崩溃**

#### 问题排查

1. Redis中**某个key过期，该key访问量巨大**
2. 多个数据请求从服务器直接压到Redis后，均未命中
3. Redis在短时间内发起了大量对数据库中同一数据的访问

#### 问题分析

- 单个key高热数据
- key过期

#### 解决方案（术）

1. 预先设定

   以电商为例，每个商家根据店铺等级，指定若干款主打商品，在购物节期间，**加大**此类信息key的**过期时长**

   注意：购物节不仅仅指当天，以及后续若干天，访问峰值呈现逐渐降低的趋势

2. 现场调整

   - 监控访问量，对自然流量激增的数据延长过期时间或设置为永久性key

3. 后台刷新数据

   - 启动定时任务，高峰期来临之前，刷新数据有效期，确保不丢失

4. 二级缓存

   - 设置不同的失效时间，保障不会被同时淘汰就行

5. 加锁 分布式锁，防止被击穿，但是要注意也是性能瓶颈，**慎重！**

#### 总结

缓存击穿就是**单个高热数据过期的瞬间**，数据访问量较大，未命中redis后，发起了大量对同一数据的数据库问，导致对数据库服务器造成压力。应对策略应该在业务数据分析与预防方面进行，配合运行监控测试与即时调整策略，毕竟单个key的过期监控难度较高，配合雪崩处理策略即可

### 4、缓存穿透

#### 恶意请求

我们的数据库中的主键都是从0开始的，即使我们将数据库中的所有数据都放到了缓存中。当有人用id=-1来发生**恶意请求**时，**因为redis中没有这个数据，就会直接访问数据库，这就称谓缓存穿透**

#### 解决办法

- 在程序中进行数据的合法性检验，如果不合法直接返回
- 使用[**布隆过滤器**]

#### 布隆过滤器简介

想要尽量避免缓存穿透，一个办法就是对数据进行**预校验**，在对Redis和数据库进行操作前，**先检查数据是否存在，如果不存在就直接返回。**如果我们想要查询一个元素是否存在，要保证查询效率，可以选择HashSet，但是如果有10亿个数据，都用HashSet进行存储，**内存肯定是无法容纳的**。这时就需要布隆过滤器了

**布隆过滤器**（英语：Bloom Filter）是1970年由布隆提出的。它实际上是一个很长的二进制向量（bit数组）和一系列随机映射函数（hash）。布隆过滤器可以用于检索一个元素是否在一个集合中

因为是基于**位数组和hash函数**的，所以它的**优点**是**空间效率和查询**时间都远远超过一般的算法。但**缺点**也很明显，那就是有一定的误识别率和删除困难。但是可以通过增加位数组的大小和增加hash函数个数来**降低**误识别率（**只能降低，没法避免**）

**放入过程**

布隆过滤器初始化后，位数组中的值都为0。当一个变量将要放入布隆过滤器时，会通过多个hash函数映射到位数组的各个位上，然后**将对应位置为1**

**查询过程**

查询依然是通过多个hash函数映射到位数组的各个位上，如果各个位都为1，说明该元素**可能存在，注意是可能存在！！**。但是如果通过映射后，位数组对应位上**不为1，那么该元素肯定不存在**

**放入过程图解**

比如我们的布隆过滤器位一个**8位的位数组**，并且有**3个hash函数**对元素进行计算，映射到数组中的各个位上

![20201204191457](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231934549-957042946.png)

我们将字符串”Nyima”放入布隆过滤器中

![20201204191637](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231934718-2047068687.png)

接下来将字符串”Cpower”放入布隆过滤器中

![20201204191725](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231934885-33278764.png)

**查询过程图解**

比如我们要查询字符串”Cpower”是否存在，通过3个hash函数映射到了位数组的三个位置上， 三个位置都为1，那么该**字符串可能存在**

![20201204191725](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231934885-33278764.png)

比如我们要查询字符串”SWPU”是否存在，通过3个hash函数映射到了位数组的三个位置，发现有一个位置不为1，那么该**字符串肯定不存在**

![20201204192628](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231935060-708614975.png)

比如我们要查询字符串”Hulu”是否存在，通过3个hash函数映射到了位数组的三个位置，发现所有位置都为1，但是我们前面并没有将字符串”Hulu”放入布隆过滤器中，所以这里**发生了误判**

![20201204192741](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220809231935272-398817774.png)

**增加位数组的大小和hash函数个数可以降低误判率，但是无法避免误判**