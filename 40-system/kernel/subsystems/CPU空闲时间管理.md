# CPU空闲时间管理

## CPU空闲时间管理子系统

每当系统中的某个逻辑CPU（即看似负责获取并执行指令的实体：若存在硬件线程，则指硬件线程；否则指处理器核心）**在中断或类似唤醒事件后处于空闲状态**，这意味着除了与之关联的特殊“空闲”任务外，该逻辑CPU上**无其他任务可运行**，此时就有机会**为其所归属的处理器节省能源**。实现方式是**让空闲的逻辑CPU停止从内存中获取指令，并将该逻辑CPU所依赖的处理器功能单元中的一部分置于空闲状态，这样这些功能单元就会消耗更少的功率**。

然而，原则上在这种情况下可能有多种不同的空闲状态可供使用，因此可能*需要找到（从内核角度来看）最合适的一种，并要求处理器使用（或 “进入”）该特定空闲状态*。这就是内核中CPU空闲时间管理子系统的作用，称为`CPUIdle`。

`CPUIdle`的设计采用模块化方式，并基于避免代码重复的原则，因此，原则上*无需依赖硬件或平台设计细节的通用代码*，与和硬件交互的代码是分开的。它通常分为三类功能单元：*负责选择要让处理器进入的空闲状态的调控器*、*将调控器的决策传递给硬件的驱动程序*，以及*为它们提供通用框架的核心*。



## CPU空闲时间调控器

**CPU空闲时间（`CPUIdle`）调控器**是系统中某个逻辑CPU变为空闲时调用的一组`策略代码`。其作用是**选择一个空闲状态，让处理器进入该状态以节省能源**。

`CPUIdle`调控器具有通用性，它们中的每一个都可用于Linux内核能够运行的任何硬件平台。因此，它们所操作的数据结构也不能依赖于任何硬件架构或平台设计细节。

调控器本身由一个`cpuidle_governor`结构体对象表示，该对象包含四个回调指针，即`enable`、`disable`、`select`、`reflect`，下面会介绍的`rating`字段，以及一个用于标识它的`name`（字符串）。

要使调控器可用，需要通过调用 `cpuidle_register_governor()` 并将指向该调控器的指针作为参数传递，将该对象注册到 `CPUIdle` 核心。如果注册成功，核心会将该调控器添加到全局可用调控器列表中。如果它是列表中的唯一调控器（即列表之前为空），或者其 `rating` 字段的值*大于*当前使用的调控器该字段的值，又或者新调控器的名称作为 `cpuidle.governor=` 命令行参数的值传递给了内核，那么从那时起将使用新的调控器（一次只能使用一个 `CPUIdle` 调控器）。此外，用户空间可以在运行时通过 `sysfs` 选择要使用的 CPUIdle 调控器。

一旦注册，CPUIdle调控器就**无法注销**，因此将它们**放入可加载内核模块中并不现实**。

```c
// include/linux/cpuidle.h
struct cpuidle_governor {
	char			name[CPUIDLE_NAME_LEN];
	struct list_head 	governor_list;
	unsigned int		rating;

	int  (*enable)		(struct cpuidle_driver *drv,
					struct cpuidle_device *dev);
	void (*disable)		(struct cpuidle_driver *drv,
					struct cpuidle_device *dev);

	int  (*select)		(struct cpuidle_driver *drv,
					struct cpuidle_device *dev,
					bool *stop_tick);
	void (*reflect)		(struct cpuidle_device *dev, int index);
};

#ifdef CONFIG_CPU_IDLE
extern int cpuidle_register_governor(struct cpuidle_governor *gov);
extern int cpuidle_governor_latency_req(unsigned int cpu);
#else
static inline int cpuidle_register_governor(struct cpuidle_governor *gov)
{return 0;}
#endif
```

`CPUIdle调控器`与内核之间的接口由四个回调函数组成：

- enable

```c
int (*enable) (struct cpuidle_driver *drv, struct cpuidle_device *dev);
```

此回调函数的作用是为管理程序做好准备，以便处理由参数 `dev` 所指向的 `cpuidle_device` 结构体对象表示的（逻辑）CPU。参数 `drv` 所指向的 `cpuidle_driver` 结构体对象表示要与该CPU一起使用的 `CPUIdle` 驱动程序（除其他事项外，它应包含 `cpuidle_state` 结构体对象列表，这些对象表示持有给定CPU的处理器可被要求进入的空闲状态）。

它可能会失败，在这种情况下，预期它会返回一个负的错误码，这会导致内核在相关CPU上运行特定于体系结构的空闲CPU默认代码，而不是运行CPUIdle，直到再次为该CPU调用->enable()调控器回调函数。


- disable

```c
void (*disable) (struct cpuidle_driver *drv, struct cpuidle_device *dev);
```

该函数用于使 governor 停止处理由参数 `dev` 指向的 `cpuidle_device` 结构体所代表的（逻辑）CPU。

预计它将撤销上次为目标CPU调用 `->enable()` 回调时所做的任何更改，释放该回调分配的所有内存等等。


- select

```c
int (*select) (struct cpuidle_driver *drv, struct cpuidle_device *dev, bool *stop_tick);
```

该函数被调用来为持有由`dev`参数所指向的`cpuidle_device`结构体对象所代表的（逻辑）CPU的处理器选择一个空闲状态。

要考虑的空闲状态列表由`drv`参数（表示当前CPU要使用的CPUIdle驱动程序）所指向的`cpuidle_driver`结构体对象中的`cpuidle_state`结构体对象的`states`数组表示。此回调函数返回的值被解释为该数组中的索引（除非它是一个负错误码）。

`stop_tick`参数用于指示在请求处理器进入选定的空闲状态之前是否停止调度器节拍。当它所指向的 bool 变量（在调用此回调之前设置为 true）被清除为 false 时，将请求处理器进入选定的空闲状态，而不会在给定的CPU上停止调度器节拍（但是，如果该CPU上的节拍已经停止，那么在请求处理器进入空闲状态之前，它不会重新启动）。

此回调函数是必需的（即，为使调控器注册成功，cpuidle_governor 结构体中的 select 回调指针不得为 NULL）。


- reflect

```c
void (*reflect) (struct cpuidle_device *dev, int index);
```

此函数用于让调控器评估由 `->select()` 回调（上次调用时）所做的空闲状态选择的准确性，并有可能利用该结果在未来提高空闲状态选择的准确性。



此外，CPUIdle调控器在选择空闲状态时，需要考虑处理器唤醒延迟方面的电源管理服务质量 (PM QoS) 约束。为了获取给定 CPU 当前有效的 PM QoS 唤醒延迟约束，预计 CPUIdle 调控器会将 CPU 编号传递给 `cpuidle_governor_latency_req()`。然后，调控器的 `->select()` 回调函数一定不能返回退出延迟 `exit_latency` 值大于该函数返回值的空闲状态索引。




## CPU空闲时间管理驱动程序

```c
// include/linux/cpuidle.h
struct cpuidle_device {
	unsigned int		registered:1;
	unsigned int		enabled:1;
	unsigned int		use_deepest_state:1;
	unsigned int		poll_time_limit:1;
	unsigned int		cpu;
	ktime_t			next_hrtimer;

	int			last_state_idx;
	int			last_residency;
	u64			poll_limit_ns;
	struct cpuidle_state_usage	states_usage[CPUIDLE_STATE_MAX];
	struct cpuidle_state_kobj *kobjs[CPUIDLE_STATE_MAX];
	struct cpuidle_driver_kobj *kobj_driver;
	struct cpuidle_device_kobj *kobj_dev;
	struct list_head 	device_list;

#ifdef CONFIG_ARCH_NEEDS_CPU_IDLE_COUPLED
	cpumask_t		coupled_cpus;
	struct cpuidle_coupled	*coupled;
#endif
};

struct cpuidle_driver {
	const char		*name;
	struct module 		*owner;
	int                     refcnt;

        /* used by the cpuidle framework to setup the broadcast timer */
	unsigned int            bctimer:1;
	/* states array must be ordered in decreasing power consumption */
	struct cpuidle_state	states[CPUIDLE_STATE_MAX];
	int			state_count;
	int			safe_state_index;

	/* the driver handles the cpus in cpumask */
	struct cpumask		*cpumask;

	/* preferred governor to switch at register time */
	const char		*governor;
};

struct cpuidle_state {
	char		name[CPUIDLE_NAME_LEN];
	char		desc[CPUIDLE_DESC_LEN];

	unsigned int	flags;
	unsigned int	exit_latency; /* in US */
	int		power_usage; /* in mW */
	unsigned int	target_residency; /* in US */
	bool		disabled; /* disabled on all CPUs */

	int (*enter)	(struct cpuidle_device *dev,
			struct cpuidle_driver *drv,
			int index);

	int (*enter_dead) (struct cpuidle_device *dev, int index);

	/*
	 * CPUs execute ->enter_s2idle with the local tick or entire timekeeping
	 * suspended, so it must not re-enable interrupts at any point (even
	 * temporarily) or attempt to change states of clock event devices.
	 */
	void (*enter_s2idle) (struct cpuidle_device *dev,
			      struct cpuidle_driver *drv,
			      int index);
};
```


CPU空闲时间管理（`CPUIdle`）驱动程序在`CPUIdle`的其他部分与硬件之间提供了一个接口。

首先，一个CPUIdle驱动程序必须填充其对应的`struct cpuidle_driver`对象中包含的`struct cpuidle_state`对象的`states`数组。此后，该数组将代表给定驱动程序所管理的所有逻辑CPU可请求进入的处理器硬件可用空闲状态列表。

预计`states`数组中的条目将按结构体`cpuidle_state`中`target_residency`字段的值升序排序（即，索引0应对应于`target_residency`值最小的空闲状态）。 [由于预计`target_residency`值反映持有该值的`cpuidle_state`结构体对象所表示的空闲状态的 “深度”，因此该排序顺序应与按空闲状态 “深度” 的升序排序顺序相同。]

结构体`cpuidle_state`中的三个字段由现有的CPUIdle调控器用于与空闲状态选择相关的计算：

- `target_residency`: 在此空闲状态下，为了比在较浅空闲状态下花费相同时间节省更多能源，所需花费的最短时间（包括进入该状态所需的时间，这可能相当长），以微秒为单位。
- `exit_latency`: CPU 请求处理器进入此空闲状态后，从该状态唤醒并开始执行第一条指令所需的最长时间，单位为微秒。
- `flags`: 表示空闲状态属性的标志。目前，调速器仅使用 `CPUIDLE_FLAG_POLLING` 标志，若给定对象并不代表实际的空闲状态，而是一个软件 “循环” 的接口，该接口可用于避免让处理器进入任何空闲状态，则会设置此标志。[在特殊情况下，CPUIdle 内核会使用其他标志。]


在 `cpuidle_state` 结构体中，`enter` 回调指针指向用于请求处理器进入特定空闲状态的执行例程，该指针不得为 `NULL`：
```c
void (*enter) (struct cpuidle_device *dev, struct cpuidle_driver *drv,  int index);
```

它的前两个参数分别指向表示运行此回调的逻辑CPU的`cpuidle_device`结构体对象和表示驱动程序本身的`cpuidle_driver`结构体对象，最后一个参数是驱动程序的`states`数组中`cpuidle_state`结构体条目的索引，表示请求处理器进入的空闲状态。

结构体`cpuidle_state`中类似的`->enter_s2idle()`回调仅用于实现系统范围的空闲时挂起电源管理功能。它与`->enter()`的区别在于，它在任何时候（即使是暂时的）都不能重新启用中断，也不能尝试更改时钟事件设备的状态，而`->enter()`回调有时可能会这样做。

一旦`states`数组被填充，其中有效条目的数量必须存储在表示该驱动程序的`cpuidle_driver`结构体对象的`state_count`字段中。此外，如果`states`数组中的任何条目表示 “耦合” 空闲状态（即只有在多个相关逻辑CPU都空闲时才能请求的空闲状态），那么`cpuidle_driver`结构体中的`safe_state_index`字段必须是一个非 “耦合” 空闲状态的索引（即只有一个逻辑CPU空闲时就可以请求的状态）。

除此之外，如果给定的CPUIdle驱动程序仅处理系统中逻辑CPU的一个子集，则其`cpuidle_driver`结构体对象中的`cpumask`字段必须指向该驱动程序将处理的CPU集合（掩码）。

CPUIdle 驱动程序只有在注册后才能使用。如果驱动程序的 `states` 数组中没有 “耦合” 空闲状态条目，可以通过将驱动程序的 `cpuidle_driver` 结构体对象传递给 `cpuidle_register_driver()` 来完成注册。否则，应使用 `cpuidle_register()` 进行此操作。

然而，在驱动程序注册之后，还需要借助`cpuidle_register_device()` 为给定的CPUIdle 驱动程序要处理的所有逻辑CPU注册结构体`cpuidle_device` 对象，并且与`cpuidle_register()` 不同，`cpuidle_register_driver()` 不会自动执行此操作。因此，使用`cpuidle_register_driver()` 注册自身的驱动程序还必须根据需要负责注册结构体`cpuidle_device` 对象，所以通常建议在所有情况下都使用`cpuidle_register()` 进行CPUIdle 驱动程序注册。

注册一个 `cpuidle_device` 结构体对象会导致创建 `CPUIdlesysfs` 接口，并为其所代表的逻辑CPU调用调控器的 `->enable()` 回调函数，因此，必须在注册负责处理该CPU的驱动程序之后进行此操作。

在调用`cpuidle_unregister_driver()`注销驱动程序之前，必须借助`cpuidle_unregister_device()`注销表示由给定CPUIdle驱动程序处理的CPU的所有`cpuidle_device`结构体对象。或者，可以调用`cpuidle_unregister()`来注销一个CPUIdle驱动程序以及表示由它处理的CPU的所有`cpuidle_device`结构体对象。

CPUIdle 驱动程序可以响应运行时系统配置更改，这些更改会导致可用处理器空闲状态列表的修改（例如，当系统电源从交流电源切换到电池电源或反之亦然时，就可能发生这种情况）。在收到此类更改通知时，预计 CPUIdle 驱动程序会调用 `cpuidle_pause_and_lock()` 暂时关闭 `CPUIdle`，然后对表示受该更改影响的 CPU 的所有 `struct cpuidle_device` 对象调用 `cpuidle_disable_device()`。接下来，它可以根据系统的新配置更新其 `states` 数组，对所有相关的 `struct cpuidle_device` 对象调用 `cpuidle_enable_device()`，并调用 `cpuidle_resume_and_unlock() `以允许再次使用 CPUIdle。
