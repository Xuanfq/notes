# 安装elasticsearch



# 1.部署单点es

## 1.1.创建网络

因为我们还需要部署kibana容器，因此需要让es和kibana容器互联。这里先创建一个网络：

```sh
docker network create es-net
```



## 1.2.加载镜像

这里我们采用elasticsearch的7.12.1版本的镜像，这个镜像体积非常大，接近1G。不建议大家自己pull。

课前资料提供了镜像的tar包：

![image-20210510165308064](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220810152957520-238273574.png)

大家将其上传到虚拟机中，然后运行命令加载即可：

```sh
# 导入数据
docker load -i es.tar
```

同理还有`kibana`的tar包也需要这样做。



## 1.3.运行

运行docker命令，部署单点es：

```sh
docker run -d \
	--name es \
    -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" \
    -e "discovery.type=single-node" \
    -v es-data:/usr/share/elasticsearch/data \
    -v es-plugins:/usr/share/elasticsearch/plugins \
    --privileged \
    --network es-net \
    -p 9200:9200 \
    -p 9300:9300 \
elasticsearch:7.12.1
```

命令解释：

- `-e "cluster.name=es-docker-cluster"`：设置集群名称
- `-e "http.host=0.0.0.0"`：监听的地址，可以外网访问
- `-e "ES_JAVA_OPTS=-Xms512m -Xmx512m"`：内存大小
- `-e "discovery.type=single-node"`：非集群模式
- `-v es-data:/usr/share/elasticsearch/data`：挂载逻辑卷，绑定es的数据目录
- `-v es-logs:/usr/share/elasticsearch/logs`：挂载逻辑卷，绑定es的日志目录
- `-v es-plugins:/usr/share/elasticsearch/plugins`：挂载逻辑卷，绑定es的插件目录
- `--privileged`：授予逻辑卷访问权
- `--network es-net` ：加入一个名为es-net的网络中
- `-p 9200:9200`：端口映射配置



在浏览器中输入：http://192.168.150.101:9200 即可看到elasticsearch的响应结果：

![image-20210506101053676](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220810152956511-1738180294.png)





# 2.部署kibana

kibana可以给我们提供一个elasticsearch的可视化界面，便于我们学习。

## 2.1.部署

运行docker命令，部署kibana

```sh
docker run -d \
--name kibana \
-e ELASTICSEARCH_HOSTS=http://es:9200 \
--network=es-net \
-p 5601:5601  \
kibana:7.12.1
```

- `--network es-net` ：加入一个名为es-net的网络中，与elasticsearch在同一个网络中
- `-e ELASTICSEARCH_HOSTS=http://es:9200"`：设置elasticsearch的地址，因为kibana已经与elasticsearch在一个网络，因此可以用容器名直接访问elasticsearch
- `-p 5601:5601`：端口映射配置

kibana启动一般比较慢，需要多等待一会，可以通过命令：

```sh
docker logs -f kibana
```

查看运行日志，当查看到下面的日志，说明成功：

![image-20210109105135812](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220810152956281-329922093.png)

此时，在浏览器输入地址访问：http://192.168.150.101:5601，即可看到结果

## 2.2.DevTools

kibana中提供了一个DevTools界面：

![image-20210506102630393](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220810152956730-1052763099.png)

这个界面中可以编写DSL来操作elasticsearch。并且对DSL语句有自动补全功能。



# 3.安装IK分词器



## 3.1.在线安装ik插件（较慢）

```shell
# 进入容器内部
docker exec -it elasticsearch /bin/bash

# 在线下载并安装
./bin/elasticsearch-plugin  install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v7.12.1/elasticsearch-analysis-ik-7.12.1.zip

#退出
exit
#重启容器
docker restart elasticsearch
```

## 3.2.离线安装ik插件（推荐）

### 1）查看数据卷目录

安装插件需要知道elasticsearch的plugins目录位置，而我们用了数据卷挂载，因此需要查看elasticsearch的数据卷目录，通过下面命令查看:

```sh
docker volume inspect es-plugins
```

显示结果：

```json
[
    {
        "CreatedAt": "2022-05-06T10:06:34+08:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/es-plugins/_data",
        "Name": "es-plugins",
        "Options": null,
        "Scope": "local"
    }
]
```

说明plugins目录被挂载到了：`/var/lib/docker/volumes/es-plugins/_data `这个目录中。



### 2）解压缩分词器安装包

下面我们需要把课前资料中的ik分词器解压缩，重命名为ik

![image-20210506110249144](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220810152956929-1568523249.png)

### 3）上传到es容器的插件数据卷中

也就是`/var/lib/docker/volumes/es-plugins/_data `：

![image-20210506110704293](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220810152957118-2117104418.png)



###  4）重启容器

```shell
# 4、重启容器
docker restart es
```

```sh
# 查看es日志
docker logs -f es
```

### 5）测试：

IK分词器包含两种模式：

* `ik_smart`：最少切分

* `ik_max_word`：最细切分



```json
GET /_analyze
{
  "analyzer": "ik_max_word",
  "text": "黑马程序员学习java太棒了"
}
```

结果：

```json
{
  "tokens" : [
    {
      "token" : "黑马",
      "start_offset" : 0,
      "end_offset" : 2,
      "type" : "CN_WORD",
      "position" : 0
    },
    {
      "token" : "程序员",
      "start_offset" : 2,
      "end_offset" : 5,
      "type" : "CN_WORD",
      "position" : 1
    },
    {
      "token" : "程序",
      "start_offset" : 2,
      "end_offset" : 4,
      "type" : "CN_WORD",
      "position" : 2
    },
    {
      "token" : "员",
      "start_offset" : 4,
      "end_offset" : 5,
      "type" : "CN_CHAR",
      "position" : 3
    },
    {
      "token" : "学习",
      "start_offset" : 5,
      "end_offset" : 7,
      "type" : "CN_WORD",
      "position" : 4
    },
    {
      "token" : "java",
      "start_offset" : 7,
      "end_offset" : 11,
      "type" : "ENGLISH",
      "position" : 5
    },
    {
      "token" : "太棒了",
      "start_offset" : 11,
      "end_offset" : 14,
      "type" : "CN_WORD",
      "position" : 6
    },
    {
      "token" : "太棒",
      "start_offset" : 11,
      "end_offset" : 13,
      "type" : "CN_WORD",
      "position" : 7
    },
    {
      "token" : "了",
      "start_offset" : 13,
      "end_offset" : 14,
      "type" : "CN_CHAR",
      "position" : 8
    }
  ]
}
```





## 3.3 扩展词词典

随着互联网的发展，“造词运动”也越发的频繁。出现了很多新的词语，在原有的词汇列表中并不存在。比如：“奥力给”，“传智播客” 等。

所以我们的词汇也需要不断的更新，IK分词器提供了扩展词汇的功能。

1）打开IK分词器config目录：

![image-20210506112225508](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220810152957313-1075133278.png)

2）在IKAnalyzer.cfg.xml配置文件内容添加：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
        <comment>IK Analyzer 扩展配置</comment>
        <!--用户可以在这里配置自己的扩展字典 *** 添加扩展词典-->
        <entry key="ext_dict">ext.dic</entry>
</properties>
```

3）新建一个 ext.dic，可以参考config目录下复制一个配置文件进行修改

```properties
传智播客
奥力给
```

4）重启elasticsearch 

```sh
docker restart es

# 查看 日志
docker logs -f elasticsearch
```

![image-20201115230900504](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220810152956014-150887582.png)

日志中已经成功加载ext.dic配置文件

5）测试效果：

```json
GET /_analyze
{
  "analyzer": "ik_max_word",
  "text": "传智播客Java就业超过90%,奥力给！"
}
```

> 注意当前文件的编码必须是 UTF-8 格式，严禁使用Windows记事本编辑

## 3.4 停用词词典

在互联网项目中，在网络间传输的速度很快，所以很多语言是不允许在网络上传递的，如：关于宗教、政治等敏感词语，那么我们在搜索时也应该忽略当前词汇。

IK分词器也提供了强大的停用词功能，让我们在索引时就直接忽略当前的停用词汇表中的内容。

1）IKAnalyzer.cfg.xml配置文件内容添加：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
        <comment>IK Analyzer 扩展配置</comment>
        <!--用户可以在这里配置自己的扩展字典-->
        <entry key="ext_dict">ext.dic</entry>
         <!--用户可以在这里配置自己的扩展停止词字典  *** 添加停用词词典-->
        <entry key="ext_stopwords">stopword.dic</entry>
</properties>
```

3）在 stopword.dic 添加停用词

```properties
习大大
```

4）重启elasticsearch 

```sh
# 重启服务
docker restart elasticsearch
docker restart kibana

# 查看 日志
docker logs -f elasticsearch
```

日志中已经成功加载stopword.dic配置文件

5）测试效果：

```json
GET /_analyze
{
  "analyzer": "ik_max_word",
  "text": "传智播客Java就业率超过95%,习大大都点赞,奥力给！"
}
```

> 注意当前文件的编码必须是 UTF-8 格式，严禁使用Windows记事本编辑





# 4.部署es集群

部署es集群可以直接使用docker-compose来完成，不过要求你的Linux虚拟机至少有**4G**的内存空间



首先编写一个docker-compose文件，内容如下：

```sh
version: '2.2'
services:
  es01:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.12.1
    container_name: es01
    environment:
      - node.name=es01
      - cluster.name=es-docker-cluster
      - discovery.seed_hosts=es02,es03
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - data01:/usr/share/elasticsearch/data
    ports:
      - 9200:9200
    networks:
      - elastic
  es02:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.12.1
    container_name: es02
    environment:
      - node.name=es02
      - cluster.name=es-docker-cluster
      - discovery.seed_hosts=es01,es03
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - data02:/usr/share/elasticsearch/data
    networks:
      - elastic
  es03:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.12.1
    container_name: es03
    environment:
      - node.name=es03
      - cluster.name=es-docker-cluster
      - discovery.seed_hosts=es01,es02
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - data03:/usr/share/elasticsearch/data
    networks:
      - elastic

volumes:
  data01:
    driver: local
  data02:
    driver: local
  data03:
    driver: local

networks:
  elastic:
    driver: bridge
```



Run `docker-compose` to bring up the cluster:

```sh
docker-compose up
```


# 5.监控方案

## 5.1Cerebro

cerebro 这个名字大家可能觉得很陌生，其实它就是过去的 kopf 插件！因为 Elasticsearch 5.0 不再支持 site plugin，所以 kopf 作者放弃了原项目，另起炉灶搞了 cerebro，以独立的单页应用形式，继续支持新版本下 Elasticsearch 的管理工作。

项目地址：[https://github.com/lmenezes/cerebro](https://github.com/lmenezes/cerebro)


**安装部署**

单页应用的安装方式都非常简单，下载打开即可：

```
# git clone https://github.com/lmenezes/cerebro
# cd cerebro
# ./bin/cerebro
```

然后浏览器打开 `http://localhost:9000` 即可。

## 5.2bigdesk

要想最快的了解 ES 各节点的性能细节，推荐使用 bigdesk 插件，其原作者为 lukas-vlcek。但是从 Elasticsearch 1.4 版本开始就不再更新了。国内有用户 fork 出来继续维护到支持 5.0 版本，GitHub 地址见：[https://github.com/hlstudio/bigdesk](https://github.com/hlstudio/bigdesk)

bigdesk 通过浏览器直连 ES 节点，发起 RESTful 请求，并渲染结果成图。所以其安装部署极其简单：

```
# git clone https://github.com/hlstudio/bigdesk
# cd bigdesk/_site
# python -mSimpleHTTPServer
Serving HTTP on 0.0.0.0 port 8000 ...
```

浏览器打开 `http://localhost:8000` 即可看到 bigdesk 页面。在 **endpoint** 输入框内填写要连接的 ES 节点地址，选择 refresh 间隔和 keep 时长，点击 **connect**，完成。

![](assets/Pasted%20image%2020220418131229.png)

注意：设置 refresh 间隔请考虑 Elastic Stack 使用的 template 里实际的 `refresh_interval` 是多少。否则你可能看到波动太大的数据，不足以说明情况。

点选某个节点后，就可以看到该节点性能的实时走势。一般重点关注 JVM 性能和索引性能。

有关 JVM 部分截图如下：

![](assets/Pasted%20image%2020220418131245.png)

有关数据读写性能部分截图如下：

![](assets/Pasted%20image%2020220418131309.png)


## 5.3Zabbix

之前提到的都是 Elasticsearch 的 sites 类型插件，其实质是实时从浏览器读取 cluster stats 接口数据并渲染页面。这种方式直观，但不适合生产环境的自动化监控和报警处理。要达到这个目标，还是需要使用诸如 nagios、zabbix、ganglia、collectd 这类监控系统。

本节以 zabbix 为例，介绍如何使用监控系统完成 Elasticsearch 的监控报警。

github 上有好几个版本的 ESZabbix 仓库，都源自 Elastic 公司员工 untergeek 最早的贡献。但是当时 Elasticsearch 还没有官方 python 客户端，所以监控程序都是用的是 pyes 库。对于最新版的 ES 来说，已经不推荐使用了。

这里推荐一个修改使用了官方 `elasticsearch.py` 库的衍生版。GitHub 地址见：[https://github.com/Wprosdocimo/Elasticsearch-zabbix](https://github.com/Wprosdocimo/Elasticsearch-zabbix)。

### 安装配置

仓库中包括三个文件：

1.  ESzabbix.py
2.  ESzabbix.userparm
3.  ESzabbix_templates.xml

其中，前两个文件需要分发到每个 ES 节点上。如果节点上运行的是 yum 安装的 zabbix，二者的默认位置应该分别是：

1.  `/etc/zabbix/zabbix_externalscripts/ESzabbix.py`
2.  `/etc/zabbix/agent_include/ESzabbix.userparm`

然后在各节点安装运行 ESzabbix.py 所需的 python 库依赖：

```
# yum install -y python-pbr python-pip python-urllib3 python-unittest2
# pip install elasticsearch
```

安装成功后，你可以试运行下面这行命令，看看命令输出是否正常：

```
# /etc/zabbix/zabbix_externalscripts/ESzabbix.py cluster status
```

最后一个文件是 zabbix server 上的模板文件，不过在导入模板之前，还需要先创建一个数值映射，因为在模板中，设置了集群状态的触发报警，没有映射的话，报警短信只有 0, 1, 2 数字不是很易懂。

创建数值映射，在浏览器登录 zabbix-web，菜单栏的 **Zabbix Administration** 中选择 **General** 子菜单，然后在右侧下拉框中点击 **Value Maping**。

选择 **create**， 新建表单中填写：

> name: ES Cluster State  
> 0 ⇒ Green 1 ⇒ Yellow 2 ⇒ Red

完成以后，即可在 **Templates** 页中通过 **import** 功能完成导入 `ESzabbix_templates.xml`。

在给 ES 各节点应用新模板之前，需要给每个节点定义一个 `{$NODENAME}` 宏，具体值为该节点 `elasticsearch.yml` 中的 `node.name` 值。从统一配管的角度，建议大家都设置为 ip 地址。

### 模板应用

导入完成后，zabbix 里多出来三个可用模板：

1.  Elasticsearch Node & Cache 其中包括两个 Application：ES Cache 和 ES Node。分别有 Node Field Cache Size, Node Filter Cache Size 和 Node Storage Size, Records indexed per second 共计 4 个 item 监控项。在完成上面说的宏定义后，就可以把这个模板应用到各节点(即监控主机)上了。
2.  Elasticsearch Service 只有一个监控项 Elasticsearch service status，做进程监控的，也应用到各节点上。
3.  Elasticsearch Cluster 包括 11 个监控项，如下列所示。其中，**ElasticSearch Cluster Status** 这个监控项连带有报警的触发器，并对应之前创建的那个 Value Map。
    -   Cluster-wide records indexed per second
    -   Cluster-wide storage size
    -   ElasticSearch Cluster Status
    -   Number of active primary shards
    -   Number of active shards
    -   Number of data nodes
    -   Number of initializing shards
    -   Number of nodes
    -   Number of relocating shards
    -   Number of unassigned shards
    -   Total number of records 这个模板下都是集群总体情况的监控项，所以，运用在一台有 ES 集群读取权限的主机上即可，比如 zabbix server。

### 其他

untergeek 最近刚更新了他的仓库，重构了一个 es_stats_zabbix 模块用于 Zabbix 监控，有兴趣的读者可以参考：[https://github.com/untergeek/zabbix-grab-bag/blob/master/Elasticsearch/es_stats_zabbix.README.md](https://github.com/untergeek/zabbix-grab-bag/blob/master/Elasticsearch/es_stats_zabbix.README.md)

