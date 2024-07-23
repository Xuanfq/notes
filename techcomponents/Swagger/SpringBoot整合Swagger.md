# 基础知识

## 常用注解
-   Api
-   ApiModel
-   ApiModelProperty
-   ApiOperation
-   ApiParam
-   ApiResponse
-   ApiResponses
-   ResponseHeader

### Api

Api 用在类上，说明该类的作用。可以标记一个Controller类做为swagger 文档资源，使用方式：

```java
@Api(value = "/user", description = "Operations about user")
```


与Controller注解并列使用。 属性配置：

| 属性名称       |                                             备注 |
| :-------------: | :----------------------------------------------- |
| value          |                                      url的路径值 |
| tags           |                如果设置这个值、value的值会被覆盖 |
| description    |                                  对api资源的描述 |
| basePath       |                               基本路径可以不配置 |
| position       |             如果配置多个Api 想改变显示的顺序位置 |
| produces       | For example, "application/json, application/xml" |
| consumes       | For example, "application/json, application/xml" |
| protocols      |           Possible values: http, https, ws, wss. |
| authorizations |                               高级特性认证时配置 |
| hidden         |                        配置为true 将在文档中隐藏 |


在SpringMvc中的配置如下：

```java
@Controller
@RequestMapping(value = "/api/pet", produces = {APPLICATION_JSON_VALUE, APPLICATION_XML_VALUE})
@Api(value = "/pet", description = "Operations about pets")
public class PetController {

}
```



### ApiOperation

ApiOperation：用在方法上，说明方法的作用，每一个url资源的定义,使用方式：

```java
@ApiOperation(
          value = "Find purchase order by ID",
          notes = "For valid response try integer IDs with value <= 5 or > 10. Other values will generated exceptions",
          response = Order,
          tags = {"Pet Store"})
```


与Controller中的方法并列使用。 属性配置：

| 属性名称          |                                                         备注 |
| :----------------: | :----------------------------------------------------------- |
| value             |                                                  url的路径值 |
| tags              |                            如果设置这个值、value的值会被覆盖 |
| description       |                                              对api资源的描述 |
| basePath          |                                           基本路径可以不配置 |
| position          |                         如果配置多个Api 想改变显示的顺序位置 |
| produces          |             For example, "application/json, application/xml" |
| consumes          |             For example, "application/json, application/xml" |
| protocols         |                       Possible values: http, https, ws, wss. |
| authorizations    |                                           高级特性认证时配置 |
| hidden            |                                    配置为true 将在文档中隐藏 |
| response          |                                                   返回的对象 |
| responseContainer |           这些对象是有效的 "List", "Set" or "Map".，其他无效 |
| httpMethod        | "GET", "HEAD", "POST", "PUT", "DELETE", "OPTIONS" and "PATCH" |
| code              |                                        http的状态码 默认 200 |
| extensions        |                                                     扩展属性 |


在SpringMvc中的配置如下：

```java
	@RequestMapping(value = "/order/{orderId}", method = GET)
	@ApiOperation(
      value = "Find purchase order by ID",
      notes = "For valid response try integer IDs with value <= 5 or > 10. Other values will generated exceptions",
      response = Order.class,
      tags = { "Pet Store" })
	public ResponseEntity<Order> getOrderById(@PathVariable("orderId") String orderId)
      throws NotFoundException {
	    Order order = storeData.get(Long.valueOf(orderId));
	    if (null != order) {
	      return ok(order);
	    } else {
	      throw new NotFoundException(404, "Order not found");
	    }
	}
```



### ApiParam

ApiParam请求属性,使用方式：

```java
public ResponseEntity<User> createUser(@RequestBody @ApiParam(value = "Created user object", required = true)  User user)
```

与Controller中的方法并列使用。属性配置：

| 属性名称        |         备注 |
| :--------------: | :----------- |
| name            |     属性名称 |
| value           |       属性值 |
| defaultValue    |   默认属性值 |
| allowableValues |   可以不配置 |
| required        | 是否属性必填 |
| access          |   不过多描述 |
| allowMultiple   |  默认为false |
| hidden          |   隐藏该属性 |
| example         |       举例子 |

在SpringMvc中的配置如下：

```java
 public ResponseEntity<Order> getOrderById(
      @ApiParam(value = "ID of pet that needs to be fetched", allowableValues = "range[1,5]", required = true)
      @PathVariable("orderId") String orderId)
```



### ApiResponse

ApiResponse：响应配置，使用方式：

```java
@ApiResponse(code = 400, message = "Invalid user supplied")
```

与Controller中的方法并列使用。 属性配置：

| 属性名称          |                             备注 |
| :----------------: | :------------------------------- |
| code              |                     http的状态码 |
| message           |                             描述 |
| response          |                  默认响应类 Void |
| reference         |           参考ApiOperation中配置 |
| responseHeaders   | 参考 ResponseHeader 属性配置说明 |
| responseContainer |           参考ApiOperation中配置 |

在SpringMvc中的配置如下：

```java
 @RequestMapping(value = "/order", method = POST)
  @ApiOperation(value = "Place an order for a pet", response = Order.class)
  @ApiResponses({ @ApiResponse(code = 400, message = "Invalid Order") })
  public ResponseEntity<String> placeOrder(
      @ApiParam(value = "order placed for purchasing the pet", required = true) Order order) {
    storeData.add(order);
    return ok("");
  }
```

### ApiResponses

ApiResponses：响应集配置，使用方式：

```java
 @ApiResponses({ @ApiResponse(code = 400, message = "Invalid Order") })
```

与Controller中的方法并列使用。 属性配置：

| 属性名称 |                备注 |
| :-------: | :------------------ |
| value    | 多个ApiResponse配置 |

在SpringMvc中的配置如下：

```java
 @RequestMapping(value = "/order", method = POST)
  @ApiOperation(value = "Place an order for a pet", response = Order.class)
  @ApiResponses({ @ApiResponse(code = 400, message = "Invalid Order") })
  public ResponseEntity<String> placeOrder(
      @ApiParam(value = "order placed for purchasing the pet", required = true) Order order) {
    storeData.add(order);
    return ok("");
  }
```



### ResponseHeader

ResponseHeader：响应头设置，使用方法

```java
@ResponseHeader(name="head1",description="response head conf")
```

与Controller中的方法并列使用。 属性配置：

| 属性名称          |                   备注 |
| :----------------: | :--------------------- |
| name              |             响应头名称 |
| description       |                 头描述 |
| response          |        默认响应类 Void |
| responseContainer | 参考ApiOperation中配置 |

在SpringMvc中的配置如下：

```Java
@ApiModel(description = "群组")
```

### 其他

- @ApiImplicitParams：用在方法上包含一组参数说明；
- @ApiImplicitParam：用在@ApiImplicitParams注解中，指定一个请求参数的各个方面
  - paramType：参数放在哪个地方
  - name：参数代表的含义
  - value：参数名称
  - dataType： 参数类型，有String/int，无用
  - required ： 是否必要
  - defaultValue：参数的默认值
- @ApiResponses：用于表示一组响应；
- @ApiResponse：用在@ApiResponses中，一般用于表达一个错误的响应信息；
  - code： 响应码(int型)，可自定义
  - message：状态码对应的响应信息
- @ApiModel：描述一个Model的信息（这种一般用在post创建的时候，使用@RequestBody这样的场景，请求参数无法使用@ApiImplicitParam注解进行描述的时候；
- @ApiModelProperty：描述一个model的属性。



# 入门示例
## 引入依赖

```xml
<!--引入swagger-->
<dependency>  
    <groupId>io.springfox</groupId>  
    <artifactId>springfox-swagger2</artifactId>  
    <!--mapstruct冲突-->
    <!--
    <exclusions>        
	    <exclusion>            
		    <groupId>org.mapstruct</groupId>  
            <artifactId>mapstruct</artifactId>  
        </exclusion>    
    </exclusions>
    -->
</dependency>  
<dependency>  
    <groupId>io.springfox</groupId>  
    <artifactId>springfox-swagger-ui</artifactId>  
</dependency>
```


## 配置Swagger

```java
@Configuration  
@ConditionalOnProperty(prefix = "swagger", value = {"enable"}, havingValue = "true")  
@EnableSwagger2  
public class SwaggerConfiguration {  
    
	@Value("true") //判断是否是生产环境或开发环境，是否开启  
	private Boolean enable;
	
    @Bean  
    public Docket buildDocket() {  
        return new Docket(DocumentationType.SWAGGER_2)  
                .apiInfo(buildApiInfo())    
				.enable(enable)
                // 配置扫描接口  
                .select()  
                // 要扫描的API(Controller)基础包  
                /*  
                 *RequestHandlerSelectors,配置要扫描接口的方式  
                 * 参数说明:  
                 * basePackage:基于包扫描  
                 * class:基于类扫描  
                 * any():扫描全部  
                 * none():全部都不扫描  
                 * withMethodAnnotation:通过方法的注解扫描  
                 * // withMethodAnnotation(GetMapping.class))                 * withClassAnnotation:通过类的注解扫描  
                 */                .apis(RequestHandlerSelectors.basePackage("com.shanjupay.merchant.controller"))  
                // .paths()过滤,不扫描哪些接口  
                .paths(PathSelectors.any())  
                .build();  
    }  
  
    /**  
     * @param  
     * @return springfox.documentation.service.ApiInfo  
     * @Title: 构建API基本信息  
     * @methodName: buildApiInfo  
     */    private ApiInfo buildApiInfo() {  
        Contact contact = new Contact("开发者", "", "");  
        return new ApiInfoBuilder()  
                .title("闪聚支付‐商户应用API文档")  
                .description("")  
                .contact(contact)  
                .version("1.0.0").build();  
    }  
}
```

多组
```java
 @Configuration // 标识配置类

 @EnableSwagger2 // 开启Swagger

 public class SwaggerConfig {

     /**
      * 添加A组
      * 每个组各司其职
      *
      * @return
      */
     @Bean
     public Docket docket1() {
         return new Docket(DocumentationType.SWAGGER_2)
                 .groupName("A");

     }

     /**
      * 添加B组
      *
      * @return
      */
     @Bean
     public Docket docket2() {
         return new Docket(DocumentationType.SWAGGER_2)
                 .groupName("B");

     }

     /**
      * 添加C组
      *
      * @return
      */
     @Bean
     public Docket docket3() {
         return new Docket(DocumentationType.SWAGGER_2)
                 .groupName("C");

     }

     /**
      * 配置了Swagger的Docket的Bean实例
      *
      * @return
      */
     @Bean
     public Docket docket(Environment environment) {

         // 设置要显示的Swagger环境

         Profiles profiles = Profiles.of("dev", "test");

         // 通过environment.acceptsProfiles();判断自己是否在自己设定换的环境当中

         boolean flag = environment.acceptsProfiles(profiles);


         return new Docket(DocumentationType.SWAGGER_2)  

			.apiInfo(buildApiInfo())   
			.enable(flag) 
			
			// 配置扫描接口  
			
			.select()  
			
			// 要扫描的API(Controller)基础包  
			
			/*  
			
			 *RequestHandlerSelectors,配置要扫描接口的方式  
			
			 * 参数说明:  
			
			 * basePackage:基于包扫描  
			
			 * class:基于类扫描  
			
			 * any():扫描全部  
			
			 * none():全部都不扫描  
			
			 * withMethodAnnotation:通过方法的注解扫描  
			
			 * // withMethodAnnotation(GetMapping.class))                 * withClassAnnotation:通过类的注解扫描  
			
			 */                .apis(RequestHandlerSelectors.basePackage("com.shanjupay.merchant.controller"))  
			
			// .paths()过滤,不扫描哪些接口  
			
			.paths(PathSelectors.any())  
			
			.build();

     }

}
```

## 注解开发
```java
@Slf4j  
@Api(value = "商户平台-渠道和支付参数相关", tags = "商户平台-渠道和支付参数", description = "商户平台-渠道和支付参数相关")  
@RestController  
public class PlatformParamController {  
  
    @Reference  
    private PayChannelService payChannelService;  
  
    @ApiOperation("获取平台服务类型")  
    @GetMapping("/my/platform-channels")  
    public List<PlatformChannelDTO> queryPlatformChannel() {  
        return payChannelService.queryPlatformChannel();  
    }  
  
  
    @ApiOperation("绑定服务类型")  
    @ApiImplicitParams({  
            @ApiImplicitParam(value = "应用appId", name = "appId", required = true, dataType = "String", paramType = "path"),  
            @ApiImplicitParam(value = "服务类型code", name = "platformChannelCodes", required = true, dataType = "String", paramType = "query")  
    })  
    @PostMapping("/my/apps/{appId}/platform-channels")  
	public void bindPlatformForApp(@PathVariable("appId") String appId, @RequestParam("platformChannelCodes") String platformChannelCodes) {  
	    payChannelService.bindPlatformChannelForApp(appId, platformChannelCodes);  
	}
  
    @ApiOperation("根据服务类型查询支付渠道")  
    @ApiImplicitParam(value = "服务类型编码", name = "platformChannelCode", required = true, dataType = "String", paramType = "path")  
    @GetMapping("/my/pay-channels/platform-channel/{platformChannelCode}")  
    public List<PayChannelDTO> queryPayChannelByPlatformChannel(@PathVariable("platformChannelCode") String platformChannelCode) {  
        return payChannelService.queryPayChannelByPlatformChannel(platformChannelCode);  
    }  
}
```