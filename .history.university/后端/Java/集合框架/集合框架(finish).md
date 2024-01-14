## 集合框架
![20220714122308](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220811213403524-439456777.png)

![20220714122340](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220811213403699-759242630.png)

常用：
![20220711160628](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220811213402306-1007140189.png)

Collection
![20220714095721](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220811213403138-1166571795.png)
![20220711160734](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220811213402868-1349001890.png)

Map
![20220714100140](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220811213403332-313253149.png)
![20220711160654](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220811213402644-650430660.png)

### 体系图
- 单例集合Collection
	- List(接口)
		- ArrayList
		- LinkedList
		- Vector
	- Set(接口)
		- HashSet
			- LinkedHashSet
		- TreeSet
- 双列集合Map
	- HashMap
		- LinkedHashMap
	- Hashtable
		- Properties
	- TreeMap


### Collection
#### List

![20220715232700](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220811213404704-1509523156.png)

##### LinkedList、ArrayList和Vector
|  |底层结构| 版本 | 线程安全(同步) 效率 | 扩容倍数 |
| -- | -- | -- | -- | -- |
| LinkedList | 双向链表 | jdk1.2 | 不安全，效率高 | 无 |
| ArrayList | 可变数组Object[] | jdk1.2 | 不安全，效率高 | 如果有参构造则按1.5倍扩容；如果是无参构造第一次扩容为10，第二次(包含)开始按1.5倍扩容 |
| Vector | 可变数组Object[] | jdk1.0 | 安全，效率不高 | 如果是无参构造，默认容量10，满后就按2倍扩容；如果指定初始容量，则按2倍扩容；也可以有参构造进行扩容大小的指定 |


##### ArrayList和LinkedList
|  | 底层结构 | 增删的效率 | 改查的效率 | 
 |--- | ----| ---- | ----- |
| ArrayList | 可变数组 Object[] | 较低、数组扩容 | 较高 |
| LinkedList | 双向链表 | 较高，通过链表增删 | 较低 |


#### Set
特点：
- 无序，无索引
- 不允许重复元素，最多一个null（TreeSet不允许null）
- 主要实现类：HashSet、LinkedHashSet、TreeSet

遍历方式：
- 迭代器
- 增强for

![20220715221705](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220811213403874-1794387588.png)


##### HashSet
底层是HashMap，HashMap的底层是数组+链表+红黑树，用一个静态类占位`K,V`中的V：`PRESENT = new Object()`

```Java
//HashMap
static class Node<K,V> implements Map.Entry<K,V> {  
    final int hash;  
    final K key;  
    V value;  
    Node<K,V> next;  
	//...
}

transient Node<K,V>[] table;
```

**HashSet添加元素原理**：
1. HashSet底层是 HashMap
2. 添加一个元素时，先得到hash值(可以通过重写hashCode()方法改变hash)，hash会转成索引值(数组索引)
3. 找到存储数据表table，看这个索引位置是否已经存放的有元素
4. 如果没有，直接加入
5. 如果有，调用”\=\=“和equals 比较，如果相同，就放弃添加，如果不相同，则添加到最后。
6. 在Java8中，如果一条链表的元素个数到达 TREEIFY_THRESHOLD(树化临界值，默认是8)，并且table的大小>=MIN_TREEIFY_CAPACITY(默认64)，就会进行树化(红黑树)

**HashSet的扩容和树化机制**：
1. HashSet底层是HashMap，第一次添加时,table数组扩容到16，临界值(threshold)是16 \* 加载因子(loadFactor)是0.75 = 12
2. 如果table数组使用到了临界值12，就会扩容到16 \* 2=32，新的临界值就是32 \* 0.75 =24,依次类推。由于我们使用的是2倍扩容，每个bin中的元素
	1. 要么保持相同的索引：当(e.hash & oldCap) == 0时，
	2. 要么在新表中以2倍的偏移量移动(旧下标加上旧数组的长度)：当(e.hash & oldCap) == 1时。
3. 在Java8中，如果一条链表的元素个数到达 TREEIFY_THRESHOLD(默认是8)，并且table的大小>=MIN TREEIFY CAPACITY(默认64)，就会进行树化(红黑树)，否则仍然采用数组扩容机制


##### LinkedHashSet
HashSet的子类，底层是LinkedHashMap，LinkedHashMap继承自HashMap，底层是数组+链表+红黑树，LinkedHashMap在HashMap基础上增加一条双向链表，保持遍历顺序和插入顺序一致问题。在HashMap替换、插入或移除某个元素等操作后，调用回调方法(子类重写该方法)，以修改双向链表：

	void afterNodeAccess(Node<K,V> p) { }
	void afterNodeInsertion(boolean evict) { }
	void afterNodeRemoval(Node<K,V> p) { }


```Java
//LinkedHashMap
static class Entry<K,V> extends HashMap.Node<K,V> {  
    Entry<K,V> before, after;  
    Entry(int hash, K key, V value, Node<K,V> next) {  
        super(hash, key, value, next);  
    }  
}

transient LinkedHashMap.Entry<K,V> head;  
  
transient LinkedHashMap.Entry<K,V> tail;
```

![20220715225734](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220811213404176-1732662646.png)


##### TreeSet
TreeSet底层是TreeMap，TreeMap是红黑树。当我们使用无参构造器，创建TreeSet时，仍然是无序的。当使用TreeSet 提供的一个构造器，可以传入一个比较器(匿名内部类)并指定排序规则 ，此时才是有序的。


1. 构造器把传入的比较器对象，赋给了 TreeSet的底层的 TreeMap的属性this.comparator  
```Java
public TreeMap(Comparator<? super K> comparator) {  
	this.comparator = comparator;   
}
```

2. 在调用 treeSet.add("tom")，在底层会执行到
```Java  
Comparator<? super K> cpr = comparator;
if (cpr != null) {//cpr 就是我们的匿名内部类(对象)  
	do {            
		parent = t;            
		//动态绑定到我们的匿名内部类(对象)compare  
		cmp = cpr.compare(key, t.key);            
		if (cmp < 0)                
			t = t.left;            
		else if (cmp > 0)                
			t = t.right;            
		else //如果相等，即返回0,这个Key就没有加入  
			return t.setValue(value);        
	} while (t != null);    
}
```


### Map
特点：
- Map与Collection并列存在，用于保存具有映射关系的数据：Key-Value
- Map中的 key 和 value 可以是任何引用类型的数据，会封装到 HashMap$Node 对象中
- Map中的 key 不允许重复，原因和 HashSet 一样，前面分析过源码
- Map中的 value 可以重复
- Map的key可以为null，value也可以为null。注意key为null，只能有一个，value 为null，可以多个
- 常用String类作为Map的key
- key和 value 之间存在单向一对一关系，即通过指定的key总能找到对应的value
- Map存放数据的key-value示意图，一对k-v是放在一个HashMap$Node中的，有因为Node实现了Entry 接口，有些书上也说一对k-v就是一个Entry。如图：![20220715231105](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220811213404494-1217843134.png)


遍历方式：
- map.keySet增强for：通过map.get(key)获取value
- map.keySet迭代器：通过map.get(key)获取value
- map.values增强for：仅有value没有key
- map.values迭代器：仅有value没有key
- map.entrySet增强for：对于每个entry，向下转型为Map.Entry，调用getKey()，getValue()
- map.entrySet迭代器：对于每个entry，向下转型为Map.Entry，调用getKey()，getValue()

#### HashMap
jdk7.0的hashmap底层实现[数组+链表], jdk8.0底层[数组+链表+红黑树]

![20220715232832](https://img2022.cnblogs.com/blog/2950406/202208/2950406-20220811213404927-519691282.png)

见HashSet ![HashSet](#HashSet)


#### LinkedHashMap
LinkedHashMap继承自HashMap，底层是数组+链表+红黑树，LinkedHashMap在HashMap基础上增加一条双向链表，保持遍历顺序和插入顺序一致问题。在HashMap替换、插入或移除某个元素等操作后，调用回调方法(子类重写该方法)，以修改双向链表。

见HashSet ![HashSet](#LinkedHashSet)


#### Hashtable
- 存放的元素是键值对：即K-V
- hashtable的键和值都不能为null，否则会抛出NullPointerException
- hashtable使用方法基本上和HashMap一样
- hashtable是线程安全的(synchronized)，hashMap是线程不安全的


#### HashMap和Hashtable
|  | 版本 | 线程安全(同步) | 效率 | 允许null键null值 |
|--|--|--|--|--|
| HashMap | 1.2 | 不安全 | 高 | 可以 |
| Hashtable | 1.0 | 安全 | 较低 | 不可以 |


#### Properties
1. Properties类继承自Hashtable类并且实现了Map接口，也是使用一种键值对的形式来保存数据
	2.他的使用特点和Hashtable类似：
	1. 存放的元素是键值对：即K-V
	2. 键和值都不能为null，否则会抛出NullPointerException
	3. 使用方法基本上和HashMap一样
	4. 是线程安全的(synchronized)
3. Properties 还可以用于从xoxx.properties文件中，加载数据到Properties类对象，并进行读取和修改
4、说明:工作后 xxx.properties 文件通常作为配置文件


#### TreeMap
红黑树。

必须有比较器：通过构造器传入或key的类型实现了Comparable(如String)。
```java
public TreeMap(Comparator<? super K> comparator) {  
    this.comparator = comparator;
}
```

见TreeSet![TreeSet](#TreeSet)


### 总结
在开发中，选择什么集合实现类，主要取决于业务操作特点，然后根据集合实现类特性进行选择,分析如下：
1) 先判断存储的类型(一组对象[单列]或一组键值对[双列])
2) 一组对象[单列]：Collection接口
	- 允许重复：List
		- 增删多：LinkedList（底层维护了一个双向链表）
		- 改查多：ArrayList （底层维护Object类型的可变数组）
	- 不允许重复：Set
		- 无序：HashSet（底层是HashMap，维护了一个哈希表即(数组+链表+红黑树)）
		- 排序：TreeSet
		- 插入和取出顺序一致：LinkedHashSet，（底层是LinkedHashMap，维护了一个哈希表即(数组+链表+红黑树)）数组+双向链表
3) 一组键值对[双列]：Map
	- 键无序：HashMap [底层是：哈希表 。jdk7：数组+链表，jdk8：数组+链表+红黑树]
	- 键排序：TreeMap
	- 键插入和取出顺序一致：LinkedHashMap
	- 读取文件Properties



### Collections工具类
1. Collections是一个操作 Set、List 和 Map等集合的工具类
2. Collections中提供了一系列静态的方法对集合元素进行排序、查询和修改等操作



