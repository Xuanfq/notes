## 介绍？

Apache POI是一种流行的API，它允许程序员使用Java程序创建，修改和显示MS Office文件。这由Apache软件基金会开发使用Java分布式设计或修改Microsoft Office文件的开源库。它包含类和方法对用户输入数据或文件到MS Office文档进行解码。

官网：[Apache POI - the Java API for Microsoft Documents](https://poi.apache.org/)

## 组件

Apache POI包含类和方法，来将MS Office所有OLE 2文档复合。此API组件的列表如下。

-   **POIFS (较差混淆技术实现文件系统) :** 此组件是所有其他POI元件的基本因素。它被用来明确地读取不同的文件。
    
-   **HSSF (可怕的电子表格格式) :** 它被用来读取和写入MS-Excel文件的xls格式。
    
-   **XSSF (XML格式) :** 它是用于MS-Excel中XLSX文件格式。
    
-   **HPSF (可怕的属性设置格式) :** 它用来提取MS-Office文件属性设置。
    
-   **HWPF (可怕的字处理器格式) :** 它是用来读取和写入MS-Word的文档扩展名的文件。
    
-   **XWPF (XML字处理器格式) :** 它是用来读取和写入MS-Word的docx扩展名的文件。
    
-   **HSLF (可怕的幻灯片版式格式) :** 它是用于读取，创建和编辑PowerPoint演示文稿。
    
-   **HDGF (可怕的图表格式) :** 它包含类和方法为MS-Visio的二进制文件。
    
-   **HPBF (可怕的出版商格式) :** 它被用来读取和写入MS-Publisher文件。


## 示例

### 依赖

```xml

<dependency>  
	<groupId>org.apache.poi</groupId>  
	<artifactId>poi</artifactId>  
</dependency>

```

### 代码

```java

/**  
 * 导出运营数据Excel  
 */
@RequestMapping("/exportBusinessReport")  
public Result exportBusinessReport(HttpServletRequest request, HttpServletResponse response) {  
    try {  
        //远程调用报表服务获取报表数据  
		Map<String, Object> result = reportService.getBusinessReportData();  
		  
		String filepath = request.getSession().getServletContext().getRealPath("template") + File.separator + "report_template.xlsx";  
		  
		 //基于提供的Excel模板文件在内存中创建一个Excel表格对象  
		XSSFWorkbook excel = new XSSFWorkbook(new FileInputStream(new File(filepath)));  
		XSSFSheet sheet = excel.getSheetAt(0);  
		  
		XSSFRow row = sheet.getRow(2);  
		row.getCell(5).setCellValue((string)result.get("reportDate"));//日期  
		
	    //使用输出流进行表格下载，基于浏览器作为客户端下载  
		OutputStream out = response.getOutputStream();  
		response.setContentType("application/vnd.ms-excel");//代表的是Excel文件类型  
		response.setHeader("content-Disposition", "attachment;filename=report.xlsx");//指定以附件形式下载  
		excel.write(out);  
		  
		out.close();  
		out.flush();  
		  
		excel.close();  
  
		return null; 
	} catch (Exception e) {  
		e.printStackTrace();  
		return new Result(false,MessageConstant.GET_BUSINESS_REPORT_FAIL);  
	}  
}

```
