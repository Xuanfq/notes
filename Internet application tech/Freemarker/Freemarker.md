## 介绍
FreeMarker 是一款 _模板引擎_： 即一种基于模板和要改变的数据， 并用来生成输出文本(HTML网页，电子邮件，配置文件，源代码等)的通用工具。 它不是面向最终用户的，而是一个Java类库，是一款程序员可以嵌入他们所开发产品的组件。

![](assets/Pasted%20image%2020220402155541.png)

## 文档
[FreeMarker 中文官方参考手册 (foofun.cn)](http://freemarker.foofun.cn/)

## 示例
### 1.依赖
```xml
<dependency>
  <groupId>org.freemarker</groupId>
  <artifactId>freemarker</artifactId>
  <version>2.3.23</version>
</dependency>
```

### 2.模板
- 模板示例1
```html
<html>
<head>
  <title>Welcome!</title>
</head>
<body>
  <#-- Greet the user with his/her name -->
  <h1>Welcome ${user}!</h1>
  <p>We have these animals:
  <ul>
  <#list animals as animal>
    <li>${animal.name} for ${animal.price} Euros
  </#list>
  </ul>
</body>
</html>
```

- 模板示例2
```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <!-- 上述3个meta标签*必须*放在最前面，任何其他内容都*必须*跟随其后！ -->
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0,user-scalable=no,minimal-ui">
    <meta name="description" content="">
    <meta name="author" content="">
    <link rel="icon" href="../img/asset-favico.ico">
    <title>预约</title>
    <link rel="stylesheet" href="../css/page-health-order.css" />
</head>
<body data-spy="scroll" data-target="#myNavbar" data-offset="150">
<div class="app" id="app">
    <!-- 页面头部 -->
    <div class="top-header">
        <span class="f-left"><i class="icon-back" onclick="history.go(-1)"></i></span>
        <span class="center">传智健康</span>
        <span class="f-right"><i class="icon-more"></i></span>
    </div>
    <!-- 页面内容 -->
    <div class="contentBox">
        <div class="list-column1">
            <ul class="list">
                <#list setmealList as setmeal>
                    <li class="list-item">
                        <a class="link-page" href="setmeal_detail_${setmeal.id}.html">
                            <img class="img-object f-left" 
                                 src="http://puco9aur6.bkt.clouddn.com/${setmeal.img}" 
                                 alt="">
                            <div class="item-body">
                                <h4 class="ellipsis item-title">${setmeal.name}</h4>
                                <p class="ellipsis-more item-desc">${setmeal.remark}</p>
                                <p class="item-keywords">
                                    <span>
                                        <#if setmeal.sex == '0'>
                                            性别不限
                                            <#else>
                                                <#if setmeal.sex == '1'>
                                                男
                                                <#else>
                                                女
                                                </#if>
                                        </#if>
                                    </span>
                                    <span>${setmeal.age}</span>
                                </p>
                            </div>
                        </a>
                    </li>
                </#list>
            </ul>
        </div>
    </div>
</div>
<!-- 页面 css js -->
<script src="../plugins/vue/vue.js"></script>
<script src="../plugins/vue/axios-0.18.0.js"></script>
</body>
```

### 4.配置
- 创建属性文件freemarker.properties
```properties
out_put_path=D:/ideaProjects/health_parent/health_mobile/src/main/webapp/pages
```

- Spring配置文件中配置
```xml
<bean id="freemarkerConfig" 
      class="org.springframework.web.servlet.view.freemarker.FreeMarkerConfigurer">
  <!--指定模板文件所在目录-->
  <property name="templateLoaderPath" value="/WEB-INF/ftl/" />
  <!--指定字符集-->
  <property name="defaultEncoding" value="UTF-8" />
</bean>
<context:property-placeholder location="classpath:freemarker.properties"/>
```

### 5.代码
```java
 public void generateHtml(String templateName,String htmlPageName,Map<String, Object> dataMap){
    Configuration configuration = freeMarkerConfigurer.getConfiguration();
    Writer out = null;
    try {
      // 加载模版文件
      Template template = configuration.getTemplate(templateName);
      // 生成数据
      File docFile = new File(outputpath + "\\" + htmlPageName);
      out = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(docFile)));
      // 输出文件
      template.process(dataMap, out);
    } catch (Exception e) {
      e.printStackTrace();
    } finally {
      try {
        if (null != out) {
          out.flush();
        }
      } catch (Exception e2) {
        e2.printStackTrace();
      }
    }
  }
  ```

# 示例2

## 创建模型类
```java
import lombok.Data;
import lombok.ToString;
import java.util.Date;
import java.util.List;
@Data
@ToString
public class Student {
	private String name;//姓名
	private int age;//年龄
	private Date birthday;//生日
	private Float mondy;//钱包
	private List<Student> friends;//朋友列表
	private Student bestFriend;//最好的朋友
}
```

## 配置文件
```yaml
server:
	port: 8088 #服务端口
	servlet:
		context‐path: /test‐freemarker
spring:
	application:
		name: test‐freemarker #指定服务名
	freemarker:
		charset: UTF‐8
		content‐type: text/html
		suffix: .ftl  #可换为html
		enabled: true
		template‐loader‐path: classpath:/templates/ # 可更换
	resources:
		add‐mappings: false #关闭工程中默认的资源处理
	mvc:
		throw‐exception‐if‐no‐handler‐found: true #出现错误时直接抛出异常
```

## 创建模板
resource/templates/test.ftl
```html
<!DOCTYPE html>
<html>
<head>
<meta charset="utf‐8">
<title>Hello World!</title>
</head>
<body>
Hello ${name}!
</body>
</html>
```

## 创建controller
```java
@Controller
public class FreemarkerController{
	@GetMapper("/test")
	public String test(Map<String,Object> model){
		model.put("name","test");
		//model.put("students",xxx);
		return "test";//返回模板文件名称，自动返回嵌入数据的视图（test.ftl）到前端
	}
}
```
