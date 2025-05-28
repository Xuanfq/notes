# 设备模型-kset kobject ktype


- Linux设备模型中，通过`设备`、`驱动`、`总线`组织成`拓扑结构`，通过`sysfs`文件系统以目录结构进行展示与管理，`sysfs`挂载方式: `mount -t sysfs sysfs /sys`。
- Linux设备模型中，`总线`负责`设备`和`驱动`的匹配，`设备`与`驱动`都挂在某一个`总线`上，当它们进行注册时由`总线`负责去完成**匹配**，进而`回调`驱动的`probe函数`。
- SoC系统中有spi, i2c, pci等实体总线用于外设的连接，而针对集成在SoC中的外设控制器，Linux内核提供一种`虚拟总线platform`用于这些外设控制器的连接，此外`platform总线`也可用于`没有实体总线的外设`。
- 在`/sys`目录下，`bus`用于存放各类`总线`，其中总线中会存放挂载在该总线上的`驱动`和`设备`，比如serial8250，devices存放了系统中的设备信息，`class`是针对`不同的设备进行分类`。


## 模型结构组成原理

### kobject

- `kobject`代表内核对象，结构体本身不单独使用，而是嵌套在其他高层结构中，用于组织成拓扑关系。
- `sysfs`文件系统中一个目录对应一个`kobject`，每个目录中的文件（如 uevent、power/state）对应内核对象的属性或操作接口。​​即，将内核对象（kobject）及其属性和关系映射为用户空间可见的目录和文件​​。
  - ​​kobject 是内核对象的基础结构。kobject 是内核中用于表示对象的基础数据结构，它负责：
    - 引用计数​​：管理对象的生命周期（何时创建/销毁）。
    - ​层次结构​​：通过父子关系构建对象间的层次（如设备属于总线）。
    - ​属性抽象​​：提供对对象属性的访问接口（如设备的状态、配置等）。
  - ​sysfs 是 kobject 的“可视化”映射​​。当内核代码注册一个 kobject 到 sysfs 时：
    - ​自动生成目录​​：sysfs 会在对应路径下创建一个目录，目录名通常是 kobject 的名称（通过 kobject.name 字段指定）。
    - ​属性映射为文件​​：该 kobject 的属性（kobj_attribute 或更高级的 attribute 结构）会被映射为目录中的文件，用户可以通过读写这些文件与内核对象交互。
    - ​层次关系映射为目录结构​​：kobject 的父子关系会反映为 sysfs 中的目录嵌套。例如，父对象的目录下会有子对象的目录。
  - ​示例：设备模型的映射​​。以 Linux 设备模型为例：
    - ​设备对象​​：每个设备（如 /sys/devices/pci0000:00/0000:00:1d.0/usb2/2-1）对应一个 struct device 中的 kobject。
    - ​驱动对象​​：每个驱动（如 /sys/bus/usb/drivers/hub）对应一个 struct device_driver 中的 kobject。
    - ​总线对象​​：总线（如 /sys/bus/usb）对应一个 struct bus_type 中的 kobject。
  - 关键机制​​：
    - ​动态创建/销毁​​：当内核中创建或销毁一个 kobject 时，sysfs 目录会自动生成或移除。
    - ​符号链接​​：某些情况下（如设备与驱动的绑定），sysfs 会创建符号链接，表示对象间的关系。
    - ​用户空间交互​​：通过读写 sysfs 文件，用户空间工具（如 udev）可以触发内核操作（如设备热插拔）。

**include/linux/kobject.h**:
```c
struct kobject {
	const char		*name;                      /* 名字，对应sysfs下的一个目录 */
	struct list_head	entry;                  /* kobject 中插入的 list_head 结构，用于构造双向链表 (include/linux/types.h)*/
	struct kobject		*parent;                /* 指向当前 kobject 父对象的指针，体现在 sys 中就是包含当前 kobject 对象的目录对象 */
	struct kset		*kset;                      /* 当前 kobject 对象所属的集合 */
	struct kobj_type	*ktype;                 /* 当前 kobject 对象的类型，default is dynamic_kobj_ktype = { .release	= dynamic_kobj_release, .sysfs_ops	= &kobj_sysfs_ops, } */
	struct kernfs_node	*sd;                    /* kernfs（内核文件系统）层次结构的基本组成单元。VFS 文件系统的目录项，是设备和文件之间的桥梁， sysfs 中的符号链接是通过 kernfs_node 内的联合体实现的。大多数字段对于 kernfs 来说是私有属性，不应被 kernfs 的用户直接访问。sd是sysfs_dirent的简写，dirent是directory entry的缩写，意思是sysfs的目录项 (include/linux/kernfs.h)*/
	struct kref		kref;                       /* kobject 的引用计数，当计数为0时，回调之前注册的 release 方法释放该对象 (include/linux/kref.h)*/
#ifdef CONFIG_DEBUG_KOBJECT_RELEASE
	struct delayed_work	release;
#endif
	unsigned int state_initialized:1;           /* 初始化标志位，初始化时被置位 */
	unsigned int state_in_sysfs:1;              /* kobject 在 sysfs 中的状态，在目录中创建则为1，否则为0 */
	unsigned int state_add_uevent_sent:1;       /* 添加设备的 uevent 事件是否发送标志，添加设备时向用户空间发送 uevent 事件，请求新增设备 */
	unsigned int state_remove_uevent_sent:1;    /* 删除设备的 uevent 事件是否发送标志，删除设备时向用户空间发送 uevent 事件，请求卸载设备 */
	unsigned int uevent_suppress:1;             /* 是否忽略上报（不上报 uevent ） */
};

//include/linux/kernfs.h
struct kernfs_node {
	atomic_t		count;
	atomic_t		active;
#ifdef CONFIG_DEBUG_LOCK_ALLOC
	struct lockdep_map	dep_map;
#endif
	/*
	 * Use kernfs_get_parent() and kernfs_name/path() instead of
	 * accessing the following two fields directly.  If the node is
	 * never moved to a different parent, it is safe to access the
	 * parent directly.
	 */
	struct kernfs_node	*parent;
	const char		*name;

	struct rb_node		rb;

	const void		*ns;	/* namespace tag */
	unsigned int		hash;	/* ns + name hash */
	union {
		struct kernfs_elem_dir		dir;
		struct kernfs_elem_symlink	symlink;
		struct kernfs_elem_attr		attr;
	};

	void			*priv;         /* 文件 私有数据, 即 kobject */

	union kernfs_node_id	id;
	unsigned short		flags;
	umode_t			mode;
	struct kernfs_iattrs	*iattr;
};

// fs/kernfs/kernfs-internal.h
struct kernfs_iattrs {
	kuid_t			ia_uid;
	kgid_t			ia_gid;
	struct timespec64	ia_atime;
	struct timespec64	ia_mtime;
	struct timespec64	ia_ctime;

	struct simple_xattrs	xattrs;
};
```



### kset

- `kset`是包含多个`kobject`的集合。如果需要在`sysfs`的目录中包含多个子目录，那需要将它定义成一个`kset`，`kset`本身也是个`kobject`。
- `kset`结构体中包含`struct kobject`字段，是该`kset`本身所属的`kobject`, 是该`kset`里多个`kobject`的集合的共同的`parent`。可以使用该字段链接到更上一层的结构，用于构建更复杂的拓扑结构。
- `sysfs`中的设备组织结构很大程度上根据`kset`组织的，`/sys/bus`目录就是一个`kset`对象，在Linux设备模型中，注册`设备`或`驱动`时就将`kobject`添加到对应的`kset`中。


**include/linux/kobject.h**:
```c
struct kset {
	struct list_head list;                      /* 包含在 kset 内的所有 kobject 构成一个双向链表 */
	spinlock_t list_lock;
	struct kobject kobj;                        /* 归属于该 kset 的所有的 kobject 的共有 parent */
	const struct kset_uevent_ops *uevent_ops;   /* kset 的 uevent 操作函数集，当 kset 中的 kobject 有状态变化时，会回调这个函数集，以便 kset 添加新的环境变量或过滤某些uevent，如果一个 kobject 不属于任何 kset 时，是不允许发送 uevent 的 */
} __randomize_layout;

struct kset_uevent_ops {
	int (* const filter)(struct kset *kset, struct kobject *kobj);
	const char *(* const name)(struct kset *kset, struct kobject *kobj);
	int (* const uevent)(struct kset *kset, struct kobject *kobj,
		      struct kobj_uevent_env *env);
};

struct kobj_uevent_env {
	char *argv[3];
	char *envp[UEVENT_NUM_ENVP];
	int envp_idx;
	char buf[UEVENT_BUFFER_SIZE];
	int buflen;
};
```



### kobj_type (ktype)

- `kobj_type`用于表征`kobject`的类型，指定了`删除kobject时要调用的函数`，kobject结构体中有`struct kref`字段用于对kobject进行`引用计数`，当计数值为0时，就会调用`kobj_type`中的`release`函数对kobject进行`释放`，这个就有点类似于C++中的智能指针了。
- `kobj_type`指定了通过`sysfs`显示或修改有关`kobject`的信息时要处理的操作`sysfs_ops`，实际是调用`show/store`函数。


**include/linux/kobject.h**:
```c
struct kobj_type {
	void (*release)(struct kobject *kobj);                                          /* 释放 kobject 对象的接口，有点类似面向对象中的析构 */
	const struct sysfs_ops *sysfs_ops;                                              /* 操作 kobject 的方法集 （show/store函数）(include/linux/sysfs.h) */
	struct attribute **default_attrs;                                               /* kobject 的默认属性列表，即 sysfs 中的文件 (include/linux/sysfs.h) */
    const struct attribute_group **default_groups;                                  /* kobject 的默认属性组列表，即 sysfs 中的文件 (include/linux/sysfs.h) */
	const struct kobj_ns_type_operations *(*child_ns_type)(struct kobject *kobj);   /* kobject 的子类命名空间类型的相关操作函数的获取方法/函数，这些命名空间相关类型的操作函数用于让 sysfs（虚拟文件系统）能够确定命名空间 (include/linux/kobject_ns.h) */
	const void *(*namespace)(struct kobject *kobj);                                 /* 如果 kobject 的父对象启用了命名空间操作，那么子kobject应该有一个与之关联的命名空间标签，该函数用于获取该命名空间标签 (lib/kobject.c/kobject_namespace) */
	void (*get_ownership)(struct kobject *kobj, kuid_t *uid, kgid_t *gid);          /* 获取 kobject 的所有权，即获取 kobject 的所有者的函数 (lib/kobject.c/kobject_get_ownership)*/
};

// include/linux/sysfs.h
struct sysfs_ops {      /* kobject操作函数集 */
	ssize_t	(*show)(struct kobject *, struct attribute *, char *);
	ssize_t	(*store)(struct kobject *, struct attribute *, const char *, size_t);
};

// include/linux/sysfs.h
/* 所谓的 attribute 就是内核空间和用户空间进行信息交互的一种方法，例如某个 driver 定义了一个变量，却希望用户空间程序可以修改该变量，以控制 driver 的行为，那么可以将该变量以 sysfs attribute 的形式开放出来 */
struct attribute {
	const char		*name;
	umode_t			mode;             /* 文件类型和权限, 无符号16位整数类型， 文件类型标志（高4位），权限位（低12位）​ (include/uapi/linux/stat.h)*/
#ifdef CONFIG_DEBUG_LOCK_ALLOC
	bool			ignore_lockdep:1;
	struct lock_class_key	*key;
	struct lock_class_key	skey;
#endif
};

// include/linux/sysfs.h
struct attribute_group {
	const char		*name;
	umode_t			(*is_visible)(struct kobject *,
					      struct attribute *, int);
	umode_t			(*is_bin_visible)(struct kobject *,
						  struct bin_attribute *, int);
	struct attribute	**attrs;
	struct bin_attribute	**bin_attrs;
};

// include/linux/sysfs.h
struct bin_attribute {  /* bin_attribute 是一种特殊的 attribute，针对二进制文件，该文件可以用于读取或写入二进制数据 */
	struct attribute	attr;
	size_t			size;
	void			*private;
	ssize_t (*read)(struct file *, struct kobject *, struct bin_attribute *,
			char *, loff_t, size_t);
	ssize_t (*write)(struct file *, struct kobject *, struct bin_attribute *,
			 char *, loff_t, size_t);
	int (*mmap)(struct file *, struct kobject *, struct bin_attribute *attr,
		    struct vm_area_struct *vma);
};

// include/linux/kobject_ns.h
struct kobj_ns_type_operations {
	enum kobj_ns_type type;
	bool (*current_may_mount)(void);
	void *(*grab_current_ns)(void);
	const void *(*netlink_ns)(struct sock *sk);
	const void *(*initial_ns)(void);
	void (*drop_ns)(void *);
};
enum kobj_ns_type {
	KOBJ_NS_TYPE_NONE = 0,
	KOBJ_NS_TYPE_NET,
	KOBJ_NS_TYPES
};
```


###  kobject创建 (lib/kobject.c)

#### kobject_create_and_add(const char *name, struct kobject *parent)

1. `kobject_create_and_add(const char *name, struct kobject *parent)`: 动态创建`kobject`，注册到`sysfs`并添加到`parent`中，返回kobject指针（或NULL）。使用完成后需使用`kobject_put()`释放。
   1. `kobj = kobject_create();`: (need to use kobject_put() when never used)
      1. `struct kobject *kobj;`
      2. `kobj = kzalloc(sizeof(*kobj), GFP_KERNEL);`: 分配`kobject`结构体内存。默认值为`0`。(GFP, Get Free Page, 它是内核用于内存分配的机制和相关标志的统称, tools/include/linux/types.h)
      3. `kobject_init(kobj, &dynamic_kobj_ktype);`: 初始化`kobject`结构体。(lib/kobject.c -> `void kobject_init(struct kobject *kobj, struct kobj_type *ktype)`)
         1. `if (kobj->state_initialized)`: error(默认为0).
         2. `kobject_init_internal(kobj);`: ( -> `static void kobject_init_internal(struct kobject *kobj)`)
            1. `kref_init(&kobj->kref);`: 初始化`kobject`的`kref`引用计数为`1`。(include/linux/kref.h -> `static inline void kref_init(struct kref *kref)`)
               1. `refcount_set(&kref->refcount, 1);`: 设置`kref`的`refcount`(struct kref的仅有的member)引用计数为`1`。 (include/linux/refcount.h -> `static inline void refcount_set(refcount_t *r, int n)`)
                  1. `atomic_set(&r->refs, n);`: 原子操作，设置`refs`(`struct refcount_struct`的仅有的成员`atomic_t refs`;)为`n`。(include/linux/atomic.h --include--> include/asm-generic/atomic.h)
            2. `INIT_LIST_HEAD(&kobj->entry);`: 初始化`kobject`的`entry`链表头，构造成链表如 `entry<->entry` (双向，`list_head`仅有`next`和`prev`两个成员(include/linux/types.h))。(include/linux/list.h -> `static inline void INIT_LIST_HEAD(struct list_head *list)`)
               1. `WRITE_ONCE(list->next, list);`: 设置`list->next`为`list`本身。强制直接内存访问和限制编译器优化，确保并发场景下的内存可见性。(tools/include/linux/compiler.h -> `#define WRITE_ONCE(x, val) ...`)
                  - 宏定义`WRITE_ONCE`和`READ_ONCE`用于在多处理器系统中，通过强制直接内存访问和限制编译器优化，确保并发场景下的内存可见性。它们不保证原子性（多 CPU 同时访问仍需锁或原子操作），仅解决编译器优化问题。适用于中断处理、无锁数据结构、统计计数器等需要轻量级同步的场合。原理：
                    - 编译器在优化代码时，可能会合并或重新排序内存操作（例如，多次读操作合并为一次，或调整写操作顺序）。这在并发场景（如多线程、中断处理程序）中会导致问题，因为程序可能依赖严格的内存访问顺序或实时性。
                      - 宏可以禁止合并/重排​​：READ_ONCE 和 WRITE_ONCE 强制编译器生成对内存的直接访问，而不是通过寄存器缓存值。
                      - ​​编译器感知顺序​​：如果两次调用被放在不同的 C 语句中，编译器会认为它们有明确的顺序依赖，从而避免重排。
                    - 对于结构体或联合体等复杂类型（大小超过机器字长，如 32 位系统的 64 位变量），直接操作可能导致非原子访问（“撕裂”，即部分值被更新）。
                      - 如果数据类型超过机器字长，READ_ONCE 和 WRITE_ONCE 会退化为 memcpy，通过内存拷贝确保完整读写。
                      - 编译器会打印警告，提示开发者注意潜在的性能或原子性问题。
                    - 使用场景：
                      - 进程级代码与中断/NMI 处理程序通信​
                        - ​​同一 CPU 上的并发​​：中断处理程序（如 IRQ/NMI）和进程级代码可能共享变量，但无需锁（中断不会抢占同一 CPU 的进程）。
                        - ​​确保可见性​​：使用 READ_ONCE 和 WRITE_ONCE 确保进程代码每次读取的是最新值，而不是寄存器缓存。
                      - 避免编译器不当优化​
                        - 配合显式内存屏障​​：当使用内存屏障（如 smp_rmb()、smp_wmb()）时，宏确保编译器不会在屏障前后重排访问。
                        - 松散顺序的访问​​：对无需严格顺序的变量（如统计计数器），宏防止编译器合并多次访问。
               2. `list->prev = list;`: 设置`list->prev`为`list`本身。
            3. `kobj->state_in_sysfs = 0;`
            4. `kobj->state_add_uevent_sent = 0;`
            5. `kobj->state_remove_uevent_sent = 0;`
            6. `kobj->state_initialized = 1;`
         3. `kobj->ktype = ktype;`: 设置`kobject`的类型。
      4. `return kobj;`
   2. `retval = kobject_add(kobj, parent, "%s", name);`: 设置 kobject 的名称，并将其添加到 kobject 层次结构中 (parent)。如果 @parent 为空指针（NULL），那么 @kobj 的父对象将被设置为与分配给该 kobject 的 kset 相关联的 kobject。如果没有 kset 分配给该 kobject，那么该 kobject 将位于 sysfs（虚拟文件系统）树的根节点处。不会生成 `add` 类型的用户空间事件（uevent）。 (lib/kobject.c -> `int kobject_add(struct kobject *kobj, struct kobject *parent, const char *fmt, ...)`)
      1. `if (!kobj->state_initialized){ pr_err(...); dump_stack(); return -EINVAL; }`: 初始化后应该为`1`。
      2. `retval = kobject_add_varg(kobj, parent, fmt, args);`: 设置 kobject 名称，并设置父节点 parent。 (lib/kobject.c -> `static __printf(3, 0) int kobject_add_varg(struct kobject *kobj, struct kobject *parent, const char *fmt, va_list vargs)`, (include/linux/compiler_attributes.h -> `#define __printf(a, b) __attribute__((__format__(printf, a, b)))`, clang/gcc(编译器相关)的宏，用于指定函数的格式化字符串参数，以便在编译时检查格式字符串的正确性。从1开始计数，a 表示格式字符串参数的索引，b 表示可变参数（...）的起始参数位置， 若b为0表示没有可变参数​​（即没有 ...），而是接受一个 ​​va_list 类型参数​​（类似 vprintf 或 vscanf 函数）。当 b=0 时，编译器 ​​不会检查后续参数的类型​​（因为参数已封装在 va_list 中），但仍会检查 ​​格式字符串本身的合法性​​（如无效的格式说明符）。))
         1. `retval = kobject_set_name_vargs(kobj, fmt, vargs);`: 安全地设置 kobject 的名称，替换 `/` 为 `!`。 (lib/kobject.c -> `int kobject_set_name_vargs(struct kobject *kobj, const char *fmt, va_list vargs)`)
            1. `s = kvasprintf_const ... if (strchr(s, '/')) ...`: 处理格式化字符串，并替换 `/` 为 `!`。(`kvasprintf_const`  include/linux/kernel.h -> lib/kasprintf.c -> `const char *kvasprintf_const(gfp_t gfp, const char *fmt, va_list ap)`)
            2. `kfree_const(kobj->name);`: 释放 kobject 的名称。
            3. `kobj->name = s;`: 设置 kobject 的名称。
            4. `return 0;`
         2. `kobj->parent = parent;`: 设置 kobject 的父节点。
         3. `return kobject_add_internal(kobj);`: 添加 kobject 到 kobject 层次结构中。 (lib/kobject.c -> `static int kobject_add_internal(struct kobject *kobj)`)
            1. `parent = kobject_get(kobj->parent);`: 获取 kobject ，并增加 kobject 引用计数。 (lib/kobject.c -> `struct kobject *kobject_get(struct kobject *kobj)`)
               1. `kref_get(&kobj->kref);`: 增加 kobject 的引用计数。 (include/linux/kref.h -> `static inline void kref_get(struct kref *kref)`)
                  1. `refcount_inc(&kref->refcount);`: 增加 kobject 的引用计数。 (include/linux/refcount.h -> `static inline void refcount_inc(refcount_t *r)`)
                     1. `refcount_add(1, r);`: 增加 kobject 的引用计数。 (include/linux/refcount.h -> `static inline void refcount_add(int i, refcount_t *r)`, i > 0)
                        1. `int old = atomic_fetch_add_relaxed(i, &r->refs);`: 原子操作
                        2. `if (unlikely(!old)) refcount_warn_saturate(r, REFCOUNT_ADD_UAF);`: UAF:Use-After-Free，引用计数已归零后再次增加，属于 ​​严重错误​​，但极少发生。初始化 kobject 时，`refcount_set(&kref->refcount, 1);`设置引用计数为1，所以正常情况下不会为0。 (tools/include/linux/compiler.h -> `# define unlikely(x)		__builtin_expect(!!(x), 0)`, __builtin_expect 是 GCC 内置函数, 告诉编译器，表达式 x 的结果 ​​很可能为假（0）​​，帮助编译器优化代码布局，将条件为真的分支代码（冷路径）放在次要位置，减少分支预测错误带来的性能损失。​​不影响实际逻辑​​：无论是否使用 unlikely，只要 x 为真，条件分支都会执行。unlikely 仅优化执行效率，不改变程序逻辑。)
                        3. `else if (unlikely(old < 0 || old + i < 0)) refcount_warn_saturate(r, REFCOUNT_ADD_OVF);`: 警告饱和，内存泄漏。
            2. `if (kobj->kset){ ... }`: 在 kset 已设置的情况下，如果 parent 为 NULL 且 kobject 有 kset，则设置父节点为 kset 的 kobject，即父节点为 kset，并增加`kset's kobj`引用计数；将 kobject 添加到 kset 中；设置父节点 parent 。
               1. `if (!parent) parent = kobject_get(&kobj->kset->kobj);`: 如果 parent 为 NULL，则设置父节点为 kset 的 kobject。
               2. `kobj_kset_join(kobj);`: 连接 kobj 和 kset ，将 kobject 添加到其成员 kset 中。 (lib/kobject.c -> `static void kobj_kset_join(struct kobject *kobj)`)
                  1. `kset_get(kobj->kset);`: 增加成员 kset 的引用计数。 (lib/kobject.c -> `static void kset_get(struct kset *kset)`)
                  2. `spin_lock(&kobj->kset->list_lock);`: 锁定 kset 的链表。
                  3. `list_add_tail(&kobj->entry, &kobj->kset->list);`: 将 kobject 添加到 kset 的 链表尾部 。过程演示：`list<->list;list<->kobj1<->list;list<->kobj1<->kobj2<->list;`。 (include/linux/list.h -> `static inline void list_add_tail(struct list_head *new, struct list_head *head)`)
                        1. `__list_add(new, head->prev, head);`: 将 new 添加到 head 前面。 (include/linux/list.h -> `static inline void __list_add(struct list_head *new, struct list_head *prev, struct list_head *next)`, 将 new 添加到 prev 和 next 之间)
                        1. `if (!__list_add_valid(new, prev, next)) return;`: 检查 new 是否有效，如果无效则返回。需配置 CONFIG_DEBUG_LIST 。 (lib/list_debug.c -> `bool __list_add_valid(struct list_head *new, struct list_head *prev, struct list_head *next)`)
                        2. `next->prev = new;`: 设置 next 的前一个节点为 new。
                        3. `new->next = next;`: 设置 new 的下一个节点为 next。
                        4. `new->prev = prev;`: 设置 new 的前一个节点为 prev。
                        5. `WRITE_ONCE(prev->next, new);`: 设置 prev 的下一个节点为 new。
                  4. `spin_unlock(&kobj->kset->list_lock);`: 解锁 kset 的链表。
               3. `kobj->parent = parent;`: 设置 kobject 的父节点。
            3. `error = create_dir(kobj);`: 创建 kobject 的目录。 (lib/kobject.c -> `static int create_dir(struct kobject *kobj)`)
               1. `const struct kobj_type *ktype = get_ktype(kobj);`: 获取 kobject 的 ktype。 (include/linux/kobject.h -> `static inline struct kobj_type *get_ktype(struct kobject *kobj){ return kobj->ktype; }`)
               2. `const struct kobj_ns_type_operations *ops;`: 定义命名空间类型的操作。
               3. `int error;`: 定义错误码。
               4. `error = sysfs_create_dir_ns(kobj, kobject_namespace(kobj));`: 在 sysfs 中创建 kobject 的目录。
                  1. `kobject_namespace(kobj)`: 获取 kobject 的命名空间标签。 (lib/kobject.c -> `onst void *kobject_namespace(struct kobject *kobj)`)
                     1. `const struct kobj_ns_type_operations *ns_ops = kobj_ns_ops(kobj);`: 获取 kobject 的命名空间类型的操作。 (lib/kobject.c -> `const struct kobj_ns_type_operations *kobj_ns_ops(struct kobject *kobj)`)
                        1. `return kobj_child_ns_ops(kobj->parent);`: 获取 kobject 父节点的子类命名空间类型的操作函数(回调)kobj_ns_type_operations。 (lib/kobject.c -> `const struct kobj_ns_type_operations *kobj_child_ns_ops(struct kobject *parent)`)
                           1. `const struct kobj_ns_type_operations *ops = NULL;`: 设置命名空间类型的操作默认为空。
                           2. `if (parent && parent->ktype && parent->ktype->child_ns_type) ops = parent->ktype->child_ns_type(parent);`: 如果父节点存在且父节点有子类命名空间操作的获取方法，则调用该获取方法以获取父节点的子类命名空间相关操作(回调)函数。
                           3. `return ops;`: 返回命名空间操作。
                     2. `if (!ns_ops || ns_ops->type == KOBJ_NS_TYPE_NONE) return NULL;`: 如果 命名空间类型的操作为空 或 命名空间类型为 KOBJ_NS_TYPE_NONE，则返回 NULL，即`parent`没有`enable namespace ops`。
                     3. `return kobj->ktype->namespace(kobj);`: 调用 kobject 的命名空间操作类型的相关(回调)函数 kobj_ns_type_operations，获取 kobject 的命名空间。 (. -> `const void *kobj->ktype->namespace(kobj)`)
                  2. `error = sysfs_create_dir_ns(kobj, kobject_namespace(kobj));`: 在 sysfs 中创建 kobject 的目录。(fs/sysfs/dir.c -> `int sysfs_create_dir_ns(struct kobject *kobj, const void *ns)`)
                     1. `struct kernfs_node *parent, *kn;`: 定义父节点kobj和当前kobj内核文件系统节点。
                     2. `kuid_t uid;kgid_t gid;`: 定义用户ID和组ID。
                     3. `if (kobj->parent) parent = kobj->parent->sd; else parent = sysfs_root_kn;`: 如果 kobj 有父节点，则获取父节点 kobj 的内核文件系统节点；没有则使用 sysfs 根节点 sysfs_root_kn (fs/sysfs/mount.c -> `int __init sysfs_init(void)`)。
                     4. `if (!parent) return -ENOENT;`: 如果父节点为空，则返回错误码 -ENOENT。
                     5. `kobject_get_ownership(kobj, &uid, &gid);`: 获取 kobject 的用户ID和组ID。 (lib/kobject.c -> `void kobject_get_ownership(struct kobject *kobj, kuid_t *uid, kgid_t *gid)`)
                        1. `*uid = GLOBAL_ROOT_UID; *gid = GLOBAL_ROOT_GID;`: 设置默认用户ID和组ID为 root。
                        2. `if (kobj->ktype->get_ownership) kobj->ktype->get_ownership(kobj, uid, gid);`: 如果 kobject 的 ktype 有获取用户ID和组ID的方法，则调用该方法。
                     6. `kn = kernfs_create_dir_ns(parent, kobject_name(kobj), S_IRWXU | S_IRUGO | S_IXUGO, uid, gid, kobj, ns);`: 在内核文件系统中创建 kobject 的目录，返回 内核文件系统节点。
                        1. `kobject_name(kobj)`: 获取 kobject 的名称。 (include/linux/kobject.h -> `static inline const char *kobject_name(const struct kobject *kobj)`)
                           1. `return kobj->name;`: 返回 kobject 的名称。
                        2. `kn = kernfs_create_dir_ns(parent, kobject_name(kobj), S_IRWXU | S_IRUGO | S_IXUGO, uid, gid, kobj, ns);`: 在内核文件系统中创建 kobject 的目录，返回 内核文件系统节点。 (fs/kernfs/dir.c -> `struct kernfs_node *kernfs_create_dir_ns(struct kernfs_node *parent, const char *name, umode_t mode, kuid_t uid, kgid_t gid, void *priv, const void *ns)`)
                           1. `struct kernfs_node *kn; int rc;`: 定义内核文件系统节点。定义返回码。
                           2. `kn = kernfs_new_node(parent, name, mode | S_IFDIR, uid, gid, KERNFS_DIR);`: 创建内核文件系统节点，并设置节点类型为目录。(fs/kernfs/dir.c -> `struct kernfs_node *kernfs_new_node(struct kernfs_node *parent, const char *name, umode_t mode, kuid_t uid, kgid_t gid, unsigned flags))`)
                              1. `struct kernfs_node *kn;`: 定义内核文件系统节点。
                              2. `if (parent->mode & S_ISGID)`: 如果父节点有组ID位，则更新参数gid和mode, 设置当前节点组ID为父节点组ID。
                                 1. `if (parent->iattr) gid = parent->iattr->ia_gid;`: 如果父节点有 iattr 属性，则设置当前节点组ID为父节点 iattr 属性中的组ID。
                                 2. `if (flags & KERNFS_DIR) mode |= S_ISGID;`: 如果当前节点类型为目录，则设置当前节点组ID位。
                              3. `kn = __kernfs_new_node(kernfs_root(parent), parent, name, mode, uid, gid, flags);`: 创建内核文件系统节点。
                                 1. `kernfs_root(parent)`: 获取父节点的根节点。 (fs/kernfs/kernfs-internal.h -> `static inline struct kernfs_root *kernfs_root(struct kernfs_node *kn)`)
                                    1. `if (kn->parent) kn = kn->parent;`: 如果当前节点有父节点，则使用父节点，父节点必然是目录节点，目录节点有根节点可以直接获取。
                                    2. `return kn->dir.root;`: 返回根节点。
                                 2. `kn = __kernfs_new_node(kernfs_root(parent), parent, name, mode, uid, gid, flags);`: 创建内核文件系统节点。(fs/kernfs/dir.c -> `static struct kernfs_node *__kernfs_new_node(struct kernfs_root *root, struct kernfs_node *parent, const char *name, umode_t mode, kuid_t uid, kgid_t gid, unsigned flags)`)
                                    1. `name = kstrdup_const(name, GFP_KERNEL);`: 复制 kobj 名字 (mm/util.c -> `const char *kstrdup_const(const char *s, gfp_t gfp)`)
                                    2. `kn = kmem_cache_zalloc(kernfs_node_cache, GFP_KERNEL);`: 从内核文件系统节点缓存中分配内存。(全局 kernfs_node_cache 来自 fs/kernfs/mount.c -> `void __init kernfs_init(void)`) (kmem_cache_create -> mm/slob.c -> `void *kmem_cache_alloc(struct kmem_cache *cachep, gfp_t flags)`)
                                    3. `idr_preload(GFP_KERNEL);`: IDR 预加载, 为 idr_alloc() 函数进行预加载。 是 ​IDR 机制中用于原子上下文下安全分配内存的关键函数​​。它通过预分配内存资源，确保后续的 idr_alloc() 调用在原子上下文（如中断处理、持有自旋锁时）中不会因内存分配而触发休眠，从而避免死锁或内核崩溃。(ID Radix Tree, ID基数树, 是一种用于高效管理唯一整数标识符（ID）并将其与指针关联的机制。它通过基数树（Radix Tree）实现，支持快速分配、查找和释放ID，适用于需要动态管理大量ID的场景（如文件描述符、进程ID等）。) (lib/radix-tree.c -> `void idr_preload(gfp_t gfp_mask)`)
                                    4. `spin_lock(&kernfs_idr_lock);`: 加锁，全局唯一，保护 IDR。(fs/kernfs/dir.c -> `static DEFINE_SPINLOCK(kernfs_idr_lock);`)
                                    5. `ret = idr_alloc_cyclic(&root->ino_idr, kn, 1, 0, GFP_ATOMIC);`: 循环从 1 到 最大指 的范围`[1,INT_MAX)`内分配一个未使用的标识符(ID)。@end <= 0 代表 INT_MAX。 (lib/idr.c -> `int idr_alloc_cyclic(struct idr *idr, void *ptr, int start, int end, gfp_t gfp)`)
                                       1. `u32 id = idr->idr_next;`: 获取下一个可用的ID。
                                       2. `int err, max = end > 0 ? end - 1 : INT_MAX;`: 获取可用分配范围最大ID。`[start,end)`，end取不到，如果 end <= 0，则最大ID为 INT_MAX。
                                       3. `if ((int)id < start) id = start;`: 如果下一个可用的ID小于起始ID，则将下一个可用的ID设置为起始ID。
                                       4. `err = idr_alloc_u32(idr, ptr, &id, max, gfp);`: 在指定范围内分配一个未使用的ID。@gfp: Memory allocation flags. (lib/idr.c -> `int idr_alloc_u32(struct idr *idr, void *ptr, u32 *nextid, unsigned long max, gfp_t gfp)`)
                                          1. `struct radix_tree_iter iter;`: 定义 radix_tree_iter 结构体。(`#define radix_tree_root		xarray`,`#define radix_tree_node		xa_node`)
                                          2. `u32 id = *nextid;`: 获取下一个可用的ID。
                                          3. `void __rcu **slot;`: 定义 radix_tree_iter 结构体中的 slot 指针。
                                          4. `unsigned int base = idr->idr_base;`: 获取 radix_tree 的基数。
                                          5. `nsigned int id = *nextid;`: 获取下一个可用的ID。
                                          6. `if (WARN_ON_ONCE(!(idr->idr_rt.xa_flags & ROOT_IS_IDR))) idr->idr_rt.xa_flags |= IDR_RT_MARKER;`: 如果 radix_tree 的标志位 ROOT_IS_IDR 没有被设置，则设置标志位 IDR_RT_MARKER。
                                          7. `id = (id < base) ? 0 : id - base;`: 如果下一个可用的ID小于基数，则将下一个可用的ID设置为0，否则将下一个可用的ID减去基数。
                                          8. `radix_tree_iter_init(&iter, id);: 初始化 radix_tree_iter 结构体。` (radix_tree_iter_init ->
                                          9.  include/linux/radix-tree.h -> `static __always_inline void __rcu **radix_tree_iter_init(struct radix_tree_iter *iter, unsigned long start)`)
                                              1.  `iter->index = 0;`
                                              2.  `iter->next_index = start;`
                                          10. `slot = idr_get_free(&idr->idr_rt, &iter, gfp, max - base);`: 在 radix_tree 中查找一个空闲的 slot。@max - base: 最大可用的ID减去基数。  
                                          11. 0*nextid = iter.index + base;`
                                          12. `radix_tree_iter_replace(&idr->idr_rt, &iter, slot, ptr);`: 用ptr指针替换一个槽位中的项目。 (radix_tree_iter_replace -> include/linux/radix-tree.h -> `static __always_inline void __rcu **radix_tree_iter_replace(struct radix_tree_root *root, struct radix_tree_iter *iter, void __rcu **slot, void *ptr)`)
                                          13. `radix_tree_iter_tag_clear(&idr->idr_rt, &iter, IDR_FREE);:` 清除标签和当前迭代条目 (lib/radix-tree.c -> `void radix_tree_iter_tag_clear(struct const struct radix_tree_iter *iter, unsigned int tag)`)
                                          14. 
                                       5. `if ((err == -ENOSPC) && (id > start)) { id = start; err = idr_alloc_u32(idr, ptr, &id, max, gfp);}`: 如果没有足够的ID可用，并且下一个可用的ID大于起始ID，则继续调用 idr_alloc_u32() 函数。
                                       6. `if (err) return err;`: 如果分配失败，则返回错误码。
                                       7. `idr->idr_next = id + 1;`: 更新下一个可用的ID。
                                       8. `return id;`: 返回分配的ID。
                                    6. `if (ret >= 0 && ret < root->last_ino) root->next_generation++;`: 如果分配的ID大于等于0且小于 root->last_ino，则增加（本次？）生成的值 root->next_generation 。
                                    7. `gen = root->next_generation;`: 获取下一次生成的值。
                                    8. `root->last_ino = ret;`: 更新最后一次分配的ID。
                                    9. `spin_unlock(&kernfs_idr_lock);`: 解锁。
                                    10. `idr_preload_end();`: 结束预加载。
                                    11. `if (ret < 0) goto err_out2;`: 如果分配失败，则跳转到 err_out2 标签释放内存并返回NULL。
                                    12. `kn->id.ino = ret; kn->id.generation = gen;`: 设置 kernfs_node 的 ID 和 generation。
                                    13. `atomic_set_release(&kn->count, 1);`: 设置 kernfs_node 的引用计数为1。
                                    14. `atomic_set(&kn->active, KN_DEACTIVATED_BIAS);`: 设置 kernfs_node 的 active 值为 KN_DEACTIVATED_BIAS。
                                    15. `RB_CLEAR_NODE(&kn->rb);`: 清除红黑树节点。
                                    16. `kn->name = name; kn->mode = mode; kn->flags = flags;`: 设置 kernfs_node 的 name、mode 和 flags。
                                    17. `if (!uid_eq(uid, GLOBAL_ROOT_UID) || !gid_eq(gid, GLOBAL_ROOT_GID)) { struct iattr iattr = {.ia_valid = ATTR_UID | ATTR_GID,.ia_uid = uid,.ia_gid = gid,}; ret = __kernfs_setattr(kn, &iattr); if (ret < 0) goto err_out3;`: 如果 uid 或 gid 不是全局 root 用户或组，则设置 kernfs_node 的 owner 和 group。
                                    18. `if (parent) {ret = security_kernfs_init_security(parent, kn); if (ret)goto err_out3;}`: 如果 kernfs_node 有父节点，则调用 security_kernfs_init_security() 函数初始化 kernfs_node 的安全上下文。
                                    19. `return kn;`: 返回 kernfs_node。
                              4. `if (kn) { kernfs_get(parent); kn->parent = parent;}`: 如果 kernfs_node 不为空，则增加父节点的引用计数并将 kernfs_node 的父节点设置为 parent。
                              5. `return kn;`: 返回 kernfs_node。
                     7. `kobj->sd = kn;`: 将 kernfs_node 设置为 kobj 的 sd sysfs目录项字段。
                     8. `return 0;`: 返回 0 表示成功。
               5. `if (error) return error;`: error 则返回。
               6. `error = populate_dir(kobj);`: 调用 populate_dir() 函数填充 kobj 的目录及其属性。(lib/kobject.c -> `static int populate_dir(struct kobject *kobj)`)
                  1. `struct kobj_type *t = get_ktype(kobj);`: 获取 kobj 的 ktype。
                  2. `if (t && t->default_attrs) for (i = 0; (attr = t->default_attrs[i]) != NULL; i++) { error = sysfs_create_file(kobj, attr); if (error) break; }`: 如果 ktype 存在且具有默认属性，则遍历这些属性并调用 `sysfs_create_file()` 函数创建 sysfs 文件。
                     1. `return sysfs_create_file_ns(kobj, attr, NULL);`: 调用 `sysfs_create_file_ns()` 函数创建带命名空间的 sysfs 属性文件。 (fs/sysfs/file.c -> `int sysfs_create_file_ns(struct kobject *kobj, const struct attribute *attr, const void *ns)`)
                        1. `kobject_get_ownership(kobj, &uid, &gid);`: 获取 kobj 的所有者信息。
                        2. `return sysfs_add_file_mode_ns(kobj->sd, attr, false, attr->mode, uid, gid, ns);`: 创建 sysfs 属性文件。 (fs/sysfs/file.c -> `int sysfs_add_file_mode_ns(struct kernfs_node *parent, const struct attribute *attr, bool is_bin, umode_t mode, kuid_t uid, kgid_t gid, const void *ns)`)
                           1. `struct lock_class_key *key = NULL;`: 定义锁类键。
                           2. `const struct kernfs_ops *ops;`: 定义 存放内核文件系统操作结构体(读写seek等) 指针。 (include/linux/kernfs.h -> `struct kernfs_ops { include/linux/kernfs.h ... };`)
                           3. `struct kernfs_node *kn;`: 定义 内核文件系统节点 指针。
                           4. `loff_t size;`: 定义文件大小。 (include/uapi/asm-generic/posix_types.h -> `typedef long long	__kernel_loff_t;`; include/linux/types.h -> `typedef __kernel_loff_t		loff_t;` )
                           5. `if (!is_bin)`: 如果不是二进制文件。
                              1. `struct kobject *kobj = parent->priv;`: 获取父节点的 kobj 。
                              2. `const struct sysfs_ops *sysfs_ops = kobj->ktype->sysfs_ops;`: 获取 父节点kobj 的 操作函数集 sysfs_ops 。每个 kobj 都要有 ktype，ktype 中有 sysfs_ops。
                              3. 根据 `sysfs_ops` 的 `store` & `show` 函数是否为空，设置不同的 `ops` : `sysfs_prealloc_kfops_rw`...这些都是文件`fs/sysfs/file.c`里的静态结构体，里面的函数类的成员也是静态函数，可共用。这些静态函数其实最终还是调用 `ktype->sysfs_ops`或`bin_attribute` 里的函数。
                                 - `sysfs_ops->show && sysfs_ops->store`:
                                   - `mode & SYSFS_PREALLOC`: `ops = &sysfs_prealloc_kfops_rw;`
                                   - `else`: `ops = &sysfs_file_kfops_rw;`
                                 - `sysfs_ops->show`: 
                                   - `mode & SYSFS_PREALLOC`: `ops = &sysfs_prealloc_kfops_ro;`
                                   - `else`: `ops = &sysfs_file_kfops_ro;`
                                 - `sysfs_ops->store`:
                                   - `mode & SYSFS_PREALLOC`: `ops = &sysfs_prealloc_kfops_wo;`
                                   - `else`: `ops = &sysfs_file_kfops_wo;`
                                 - `else`(both null): `ops = &sysfs_file_kfops_empty;`
                              4. `size = PAGE_SIZE;`: 设置文件大小为 PAGE_SIZE 。
                           6. `else`: 如果是二进制文件。
                              1. `struct bin_attribute *battr = (void *)attr;`: 获取 attr 转为 bin_attribute 结构体。
                              2. 根据 `bin_attribute` 的属性 `read` & `write` & `mmap` 函数是否为空，设置不同的 `ops` : 同上。
                                 - `battr->mmap`: `ops = &sysfs_bin_kfops_mmap;` (3者均有)
                                 - `battr->read && battr->write`: `ops = &sysfs_bin_kfops_rw;`
                                 - `battr->read`: `ops = &sysfs_bin_kfops_ro;`
                                 - `battr->write`: `ops = &sysfs_bin_kfops_wo;`
                                 - `else`(3者均为空): `ops = &sysfs_file_kfops_empty;`
                              3. `size = battr->size;`: 设置文件大小为 bin_attribute 的 size。
                           7. `#ifdef CONFIG_DEBUG_LOCK_ALLOC \n if (!attr->ignore_lockdep) key = attr->key ?: (struct lock_class_key *)&attr->skey; \n #endif`: 如果配置了 CONFIG_DEBUG_LOCK_ALLOC，并且不忽略锁依赖，则获取 attr 的锁类键。
                           8. `kn = __kernfs_create_file(parent, attr->name, mode & 0777, uid, gid, size, ops, (void *)attr, ns, key);`: 调用内核内部创建文件的函数进行文件创建。 (fs/kernfs/file.c -> `struct kernfs_node *__kernfs_create_file(struct kernfs_node *parent, const char *name, umode_t mode, kuid_t uid, kgid_t gid, loff_t size, const struct kernfs_ops *ops, void *priv, const void *ns, struct lock_class_key *key)`)
                              1. `flags = KERNFS_FILE;`: 设置节点标志为 内核文件系统的文件，即创建的是文件的kernfs_node节点。
                              2. `kn = kernfs_new_node(parent, name, (mode & S_IALLUGO) | S_IFREG, uid, gid, flags);`: 创建 kernfs_node 节点， 参照上分。
                              3. `kn->attr.ops = ops; kn->attr.size = size; kn->ns = ns; kn->priv = priv;`: 设置 kernfs_node 相关成员值
                              4. `#ifdef CONFIG_DEBUG_LOCK_ALLOC \n if (key) { lockdep_init_map(&kn->dep_map, "kn->count", key, 0); kn->flags |= KERNFS_LOCKDEP; } \n #endif`: 如果配置了 CONFIG_DEBUG_LOCK_ALLOC，并且有锁类键，则初始化 kernfs_node 的依赖映射，并设置标志位。
                              5. 只有在持有活动引用（active ref）时，才可以访问 `kn->attr.ops`。我们需要了解是否存在在活动引用之外实现的某些操作。将这些操作是否存在的信息缓存在标志位（flags）中:
                                 1. `if (ops->seq_show) kn->flags |= KERNFS_HAS_SEQ_SHOW;`: 如果 ops 的 `seq_show` 函数不为空，则添加 KERNFS_HAS_SEQ_SHOW 标志位。
                                 2. `if (ops->mmap) kn->flags |= KERNFS_HAS_MMAP;`: 如果 ops 的 `mmap` 函数不为空，则设置为KERNFS_HAS_MMAP标志位。
                                 3. `if (ops->release) kn->flags |= KERNFS_HAS_RELEASE; `: 如果 ops 的 `release` 函数不为空，则添加 KERNFS_HAS_RELEASE 标志位。
                              6. `rc = kernfs_add_one(kn);`: 将 kernfs_node 节点添加到 kernfs 文件系统 （其父类） 中。如果 `@kn` 是一个目录，此函数会递增其父节点索引节点（inode）的链接数（nlink），并将其链接到父节点的子节点列表中。 (fs/kernfs/dir.c -> `int kernfs_add_one(struct kernfs_node *kn)`)
                                 1. `struct kernfs_node *parent = kn->parent;`: 获取 kernfs_node 的父节点。
                                 2. `struct kernfs_iattrs *ps_iattr; bool has_ns; int ret; ret = -EINVAL;`: 声明 kernfs_iattrs 结构体指针和 has_ns 标志。
                                 3. `mutex_lock(&kernfs_mutex);`: 加锁, fs/kernfs/dir.c 的全局锁。
                                 4. `has_ns = kernfs_ns_enabled(parent);`: 判断 kernfs_node 的父节点是否启用了命名空间。(include/linux/kernfs.h -> `return kn->flags & KERNFS_NS;`)
                                 5. `if (kernfs_type(parent) != KERNFS_DIR) goto out_unlock;`: 如果 kernfs_node 的父节点不是目录，解锁并返回。
                                 6. `if (parent->flags & KERNFS_EMPTY_DIR) goto out_unlock;`: 如果 kernfs_node 的父节点是空目录，解锁并返回。
                                 7. `if ((parent->flags & KERNFS_ACTIVATED) && !kernfs_active(parent)) goto out_unlock;`: 如果 kernfs_node 的父节点已激活，并且父节点不是活动节点，解锁并返回。
                                 8. `kn->hash = kernfs_name_hash(kn->name, kn->ns);`: 计算  31 bit hash of ns + name  。(fs/kernfs/dir.c -> `static unsigned int kernfs_name_hash(const char *name, const void *ns)`)
                                 9. `ret = kernfs_link_sibling(kn);`: 将 @kn 链接到其兄弟节点红黑树中，该红黑树从 @kn->parent->dir.children 开始。 (fs/kernfs/dir.c -> `static int kernfs_link_sibling(struct kernfs_node *kn)`)
                                 10. `if (ret) goto out_unlock;`: 如果链接失败，解锁并返回。
                                 11. `ps_iattr = parent->iattr;`: 获取 kernfs_node 的父节点的 iattr。
                                 12. `if (ps_iattr) { ktime_get_real_ts64(&ps_iattr->ia_ctime); ps_iattr->ia_mtime = ps_iattr->ia_ctime; }`: 如果 kernfs_node 的父节点有 iattr，则更新其创建时间和修改时间。
                                 13. `mutex_unlock(&kernfs_mutex);`: 解锁。
                                 14. `if (!(kernfs_root(kn)->flags & KERNFS_ROOT_CREATE_DEACTIVATED)) kernfs_activate(kn);`: 如果 kernfs_node 的根节点标志位没有 KERNFS_ROOT_CREATE_DEACTIVATED，则激活 kernfs_node 。如果在此处未激活，内核文件系统（kernfs）的使用者有责任使用 kernfs_activate() 函数来激活该节点。一个尚未被激活的节点对于用户空间是不可见的，并且删除该节点不会触发去激活操作。 (fs/kernfs/dir.c -> `static bool kernfs_active(struct kernfs_node *kn)`, `lockdep_assert_held(&kernfs_mutex); return atomic_read(&kn->active) >= 0;`)
                                 15. `return 0;`
                              7. `if (rc) kernfs_put(kn); return ERR_PTR(rc);`
                              8. `return kn;`
               7. `if (error) sysfs_remove_dir(kobj); return error; }`: 如果填充失败，则删除 kobj 的目录并返回错误码。(fs/sysfs/dir.c -> `void sysfs_remove_dir(struct kobject *kobj)`)
                  1. `spin_lock(&sysfs_symlink_target_lock);`: 加锁。
                  2. `kobj->sd = NULL;`: 设置 kobj 的 sysfs_dirent 为 NULL。
                  3. `spin_unlock(&sysfs_symlink_target_lock);`: 解锁。
                  4. `if (kn) { WARN_ON_ONCE(kernfs_type(kn) != KERNFS_DIR); kernfs_remove(kn); }`: 如果 kn 不为空，则从 kernfs 文件系统中删除 kn，并释放 kn。(fs/kernfs/dir.c -> `void kernfs_remove(struct kernfs_node *kn)`)
                     1. `mutex_lock(&kernfs_mutex);`: 加锁。
                     2. `__kernfs_remove(kn);`: 从 kernfs 文件系统中删除 kn。(fs/kernfs/dir.c -> `static void __kernfs_remove(struct kernfs_node *kn)`)
                        1. `struct kernfs_node *pos;`
                        2. `lockdep_assert_held(&kernfs_mutex);`
                        3. `if (!kn || (kn->parent && RB_EMPTY_NODE(&kn->rb))) return;`: 如果 kn 为空，或者 kn 的父节点为空且 kn 的红黑树为空，则返回。
                        4. `pos = NULL; while ((pos = kernfs_next_descendant_post(pos, kn))) { if (kernfs_active(pos)) atomic_add(KN_DEACTIVATED_BIAS, &pos->active); }`: 遍历 kn 的所有后代节点，并将它们的 active 值增加 KN_DEACTIVATED_BIAS。通过deactive停用所有节点来防止在 `@kn` 下出现任何新的使用情况 
                        5. `do { while (pos != kn) }`: 逐个节点地停用并解除该子树的链接 
                           1. `pos = kernfs_leftmost_descendant(kn);`: 获取 kn 的最左后代节点。
                           2. `kernfs_get(pos);`: 获取 pos 的引用计数。 `kernfs_drain()` 会临时释放 `kernfs_mutex`（内核文件系统互斥锁），并且在该函数返回时，`@pos` 的基础引用可能已经被其他某一方释放了。要确保在我们不知情的情况下它不会消失。  
                           3. `if (kn->flags & KERNFS_ACTIVATED) kernfs_drain(pos);`: 如果 kn 已激活，则释放 pos 的引用计数。 仅当 `@kn` 已激活时才进行排空操作。这样可以避免对那些从未被激活过的节点进行排空操作及其相关的锁依赖注释检查，并且允许将 `kernfs_remove()` 嵌入到创建（节点）的错误处理路径中，而无需担心排空（操作带来的问题）。  
                           4. `if (!pos->parent || kernfs_unlink_sibling(pos))`: 从兄弟节点红黑树中解除 kernfs_node 的链接，更新并释放相关节点。`kernfs_unlink_sibling()` 尝试将 @kn 从以 kn->parent->dir.children 开始的兄弟节点红黑树中解除链接。如果 @kn 确实被移除，则返回 true；如果 @kn 不在该红黑树上，则返回 false。`kernfs_unlink_sibling()` 对于每个节点只会成功执行一次。可利用这一点来确定由谁负责清理工作。 
                              1. `struct kernfs_iattrs *ps_iattr = pos->parent ? pos->parent->iattr : NULL;`: 获取 kernfs_node 的父节点的 iattr。
                              2. `if (ps_iattr) { ktime_get_real_ts64(&ps_iattr->ia_ctime);ps_iattr->ia_mtime = ps_iattr->ia_ctime; }`: 如果 kernfs_node 的父节点有 iattr，则更新其创建时间和修改时间。
                              3. `kernfs_put(pos);`: 释放 pos 的引用计数，并且如果引用计数达到零，就销毁它。 
                           5. `kernfs_put(pos);`: 释放 pos 的引用计数，并且如果引用计数达到零，就销毁它。
                     3. `mutex_unlock(&kernfs_mutex);`: 解锁。
               8. `if (ktype)`: 
                  1. `error = sysfs_create_groups(kobj, ktype->default_groups);`: 创建 kobj 的默认属性组。给 目录 kobject 创建一组属性组。此函数创建一组属性组。如果在创建组时发生错误，所有先前已创建的组都将被删除，将所有内容恢复到调用此函数时的原始状态。如果正在创建的任何属性文件已经存在，它将明确发出警告并报告错误。 (fs/sysfs/group.c -> `int sysfs_create_groups(struct kobject *kobj, const struct kobj_type *ktype)`)
                  2. `if (error) { sysfs_remove_dir(kobj); return error; }`: 如果创建失败，则删除 kobj 的目录并返回错误码。
               9. `sysfs_get(kobj->sd);`: 获取/增加 kobj 的 sysfs_dirent 的引用计数。`@kobj`的`sd`成员可能会因（`kobj`的）某个祖先对象的消失而被删除。因此要额外持有一个引用，以便在`@kobj`消失之前`sd`能够一直存在。 (include/linux/sysfs.h -> `static inline struct kernfs_node *sysfs_get(struct kernfs_node *kn)` -> `kernfs_get(kn);return kn;`)
               10. `ops = kobj_child_ns_ops(kobj);`: 获取 kobj 的子对象操作。如果`@kobj`拥有命名空间操作（`ns_ops`），那么它的子对象需要根据它们的命名空间标签进行筛选。要在`@kobj`的`sd`成员上启用命名空间支持。  (include/linux/kobject.h -> `static inline const struct kobj_ns_type_operations *kobj_child_ns_ops(const struct kobject *kobj)`)
               11. `if (ops) sysfs_enable_ns(kobj->sd);`: 如果`@kobj`拥有命名空间操作（`ns_ops`），那么它的子对象需要根据它们的命名空间标签进行筛选。要在`@kobj`的`sd`成员上启用命名空间支持。(include/linux/sysfs.h -> `static inline void sysfs_enable_ns(struct kernfs_node *kn)` -> (include/linux/kernfs.h)`kernfs_enable_ns(kn);` -> `kn->flags |= KERNFS_NS;`)
               12. `return 0;`: 返回 0，表示成功。
            4. `if (error)`: 如果创建失败，则删除 kobj 并释放内存。
               1. `kobj_kset_leave(kobj);`: 将 kobj 从其 kset 中移除。
               2. `kobject_put(parent);`: 释放 parent 的引用计数，并且如果引用计数达到零，就销毁它。
               3. `kobj->parent = NULL;`: 将 kobj 的父节点设置为 NULL。
            5. `else kobj->state_in_sysfs = 1;`: 如果创建成功，则将 kobj 的 state_in_sysfs 标志设置为 1，表示 kobj 已经在 sysfs 中。
            6. `return error;`: 返回错误码。
      3. `return retval;`: 返回 kobj 的引用计数。
   3. `if (retval) {kobject_put(kobj); kobj = NULL;}`: 创建kobject时失败，当该结构将不再被使用时，它将被动态释放。
   4. `return kobj;`: 返回 kobj。



#### kobject_init_and_add(struct kobject *kobj, struct kobj_type *ktype, struct kobject *parent, const char *fmt, ...)

1. `kobject_init_and_add(struct kobject *kobj, struct kobj_type *ktype, struct kobject *parent, const char *fmt, ...)`: 初始化并添加一个 kobject 到系统中。
   1. `kobject_init(kobj, ktype);`: 初始化 kobject。 参照 kobject_create(); (#### kobject_create_and_add 1.1.3)
   2. `retval = kobject_add_varg(kobj, parent, fmt, args);`: 添加 kobject 到系统中。 (#### kobject_create_and_add 1.2.2)
      1. `static int kobject_add_internal(struct kobject *kobj)`: 添加 kobject 到系统中。
         1. `if (kobj->kset)`
            1. `if (!parent) parent = kobject_get(&kobj->kset->kobj)`: 如果 没有 parent， kobj 有 kset，则获取 kset 的 kobject 的作为 parent。
            2. `kobj_kset_join(kobj);`: 将 kobj 加入到 kset 中。
            3. `kobj->parent = parent;`
         2. `create_dir(kobj)`: 创建 kobject 的 sysfs 目录。
   3. `return retval;`: 返回错误码。



### kset创建 (lib/kobject.c)

#### struct kset *kset_create_and_add(const char *name, const struct kset_uevent_ops *uevent_ops, struct kobject *parent_kobj)

1. `struct kset *kset_create_and_add(const char *name, const struct kset_uevent_ops *uevent_ops, struct kobject *parent_kobj)`: 动态创建一个`kset`结构体，并将其添加到系统文件系统（sysfs）中。 当不再使用这个结构体时，调用kset_unregister()函数，当该结构体不再被使用时，它将被动态释放。
   1. 
























