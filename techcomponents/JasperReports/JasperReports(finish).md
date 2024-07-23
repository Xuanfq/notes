## 介绍
JasperReports是一个强大、灵活的报表生成工具，能够展示丰富的页面内容，并将之转换成PDF，HTML，或者XML格式。该库完全由Java写成，可以用于在各种Java应用程序，包括J2EE，Web应用程序中生成动态内容。一般情况下，JasperReports会结合Jaspersoft Studio(模板设计器)使用导出PDF报表。

## 原理
![20220402121827](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220810153603364-407577238.png)

-   JRXML：报表填充模板，本质是一个xml文件
    
-   Jasper：由JRXML模板编译成的二进制文件，用于代码填充数据
    
-   Jrprint：当用数据填充完Jasper后生成的对象，用于输出报表
    
-   Exporter：报表输出的管理类，可以指定要输出的报表为何种格式
    
-   PDF/HTML/XML：报表形式


## 示例
第一步：创建maven工程，导入JasperReports的maven坐标

```xml
<dependency>  
	<groupId>junit</groupId>  
	<artifactId>junit</artifactId>  
	<version>4.12</version>  
</dependency>
```

第二步：将提前准备好的jrxml文件复制到maven工程中(后面会详细讲解如何创建jrxml文件)
![20220402122114](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220810153603581-262690849.png)

第三步：编写单元测试，输出PDF报表

```java
@Test
public void testJasperReports()throws Exception{
    String jrxmlPath = 
        "D:\\ideaProjects\\projects111\\jasperdemo\\src\\main\\resources\\demo.jrxml";
    String jasperPath = 
        "D:\\ideaProjects\\projects111\\jasperdemo\\src\\main\\resources\\demo.jasper";

    //编译模板
    JasperCompileManager.compileReportToFile(jrxmlPath,jasperPath);

    //构造数据
    Map paramters = new HashMap();
    paramters.put("reportDate","2019-10-10");
    paramters.put("company","itcast");
    List<Map> list = new ArrayList();
    Map map1 = new HashMap();
    map1.put("name","xiaoming");
    map1.put("address","beijing");
    map1.put("email","xiaoming@itcast.cn");
    Map map2 = new HashMap();
    map2.put("name","xiaoli");
    map2.put("address","nanjing");
    map2.put("email","xiaoli@itcast.cn");
    list.add(map1);
    list.add(map2);

    //填充数据
    JasperPrint jasperPrint = 
        JasperFillManager.fillReport(jasperPath, 
                                     paramters, 
                                     new JRBeanCollectionDataSource(list));

    //输出文件
    String pdfPath = "D:\\test.pdf";
    JasperExportManager.exportReportToPdfFile(jasperPrint,pdfPath);
}
```

## Jaspersoft Studio模板设计器
Jaspersoft Studio是一个图形化的报表设计工具，可以非常方便的设计出PDF报表模板文件(其实就是一个xml文件)，再结合JasperReports使用，就可以渲染出PDF文件。

下载地址:[https://community.jaspersoft.com/community-download](https://community.jaspersoft.com/community-download)

![20220402122507](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220810153603751-1760487178.png)