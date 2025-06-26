# 虚拟文件系统VFS

## 基本概述

### **1. VFS的核心概念**

#### **1.1 文件系统的抽象**

VFS是一个抽象层，它位于用户空间和具体文件系统之间，提供了一组统一的系统调用接口（如 `open`、`read`、`write` 等）。当应用程序请求进行文件操作时，VFS会将这些请求转发到具体的文件系统上去执行。这使得操作系统能够同时支持多种不同的文件系统，并为用户和程序提供透明的访问方式。



#### **1.2 文件系统操作的统一接口**

VFS通过提供一组通用的操作接口，允许操作系统支持不同的文件系统类型。操作系统的内核只需要通过VFS接口与文件系统进行交互，而不必关心文件系统具体的实现方式。



#### **1.3 文件描述符和VFS**

VFS将文件描述符视作文件对象与实际文件之间的“桥梁”。文件描述符是内核用来引用打开文件的一个整数，而VFS内部通过 `struct file` 和 `struct inode` 来管理这些文件对象。



#### **1.4 优势和作用**

- **统一接口**

VFS为所有文件系统提供了统一的访问接口，应用程序和用户空间程序不需要关心底层文件系统的具体实现，只需通过标准的系统调用（如 `open`、`read`、`write`）与文件系统交互。

- **多种文件系统支持**

通过VFS，Linux内核能够支持多种不同的文件系统（如 ext4、NTFS、FAT、NFS 等）。用户可以在同一系统中同时使用不同类型的文件系统，并在它们之间无缝切换。

- **性能优化**

VFS可以通过缓存目录项和文件的 `inode`，减少磁盘访问次数，提高文件操作的性能。

- **挂载机制**

VFS支持文件系统挂载，使得不同的文件系统可以在一个统一的目录树中共存。通过挂载点，用户可以在一个文件系统上访问另一个文件系统的内容。




### **2. VFS的组成部分**

VFS实现涉及多个关键的数据结构和函数。它们帮助内核管理文件系统的不同实现，并提供统一的操作接口。

```c
struct task_struct			// 进程描述符
    |
    v
files_struct *files        	// 进程打开的文件表
    |
    v
struct file *fd_array[]    	// 文件描述符数组
    |
    v
file{						// 打开的文件实例
	.f_path -> path{			// 所在路径，包含dentry和vfsmount
		.dentry -> dentry{		// 指向目录项
			.d_parent -> dentry ...
			.d_inode -> inode			// 关联的inode
			.d_op -> dentry_operations	// 目录函数操作表
		}
		.mnt -> vfsmount{		// 指向挂载点
			.mnt_root -> dentry
			.mnt_sb -> super_block
		}
	}
	.f_inode -> inode{			// 指向inode
		.i_op -> inode_operations		// inode操作函数表
		.i_sb -> super_block{
			.s_op -> super_operations	// 超级块函数操作表
			.s_type -> file_system_type	// 文件系统类型
		}
	}
	.f_op -> file_operations	// 文件操作函数表
}
```

文件打开流程

1. 用户调用`open("/home/user/test.txt", O_RDONLY)`
2. VFS 从根目录 dentry 开始，通过路径解析找到 "home"、"user" 和 "test.txt" 的 dentry
3. 通过 dentry 找到对应的 inode
4. 创建新的`struct file`实例，设置`f_path.dentry`和`f_inode`
5. 根据 inode 类型设置`file->f_op`(通常来自`inode->i_fop`)
6. 将`file`添加到进程的文件描述符表

文件读取流程

1. 用户调用`read(fd, buffer, size)`
2. 通过 fd 找到对应的`struct file`
3. 调用`file->f_op->read_iter()`(或旧接口`read`)
4. 该函数指针通常指向具体文件系统实现的函数 (如 ext4_file_read_iter)
5. 文件系统函数通过 inode 和文件位置读取实际数据




#### **2.1 `struct file`**

`struct file` 是VFS中的一个重要数据结构，它代表一个打开的文件，并包含文件的状态信息，如指向文件操作表的指针。每当进程调用系统调用（如 `read` 或 `write`）时，VFS会根据文件描述符查找对应的 `struct file` 结构体，从而执行实际的操作。

```c
// include/linux/fs.h
struct file {
	union {
		struct llist_node	fu_llist;
		struct rcu_head 	fu_rcuhead;
	} f_u;
	struct path		f_path;								// 目录，包括vfsmount和dentry
	struct inode		*f_inode;	/* cached value */  // 文件的 inode，指向文件的元数据
	const struct file_operations	*f_op;              // 指向文件操作函数表的指针

	/*
	 * Protects f_ep_links, f_flags.
	 * Must not be taken from IRQ context.
	 */
	spinlock_t		f_lock;
	enum rw_hint		f_write_hint;
	atomic_long_t		f_count;
	unsigned int 		f_flags;                        // 文件的状态标志（例如，是否是只读） (unsigned long 6.x)
	fmode_t			f_mode;                             // 文件的打开模式
	struct mutex		f_pos_lock;
	loff_t			f_pos;
	struct fown_struct	f_owner;
	const struct cred	*f_cred;
	struct file_ra_state	f_ra;

	u64			f_version;
#ifdef CONFIG_SECURITY
	void			*f_security;
#endif
	/* needed for tty driver, and maybe others */
	void			*private_data;

#ifdef CONFIG_EPOLL
	/* Used by fs/eventpoll.c to link all the hooks to this file */
	struct list_head	f_ep_links;
	struct list_head	f_tfile_llink;
#endif /* #ifdef CONFIG_EPOLL */
	struct address_space	*f_mapping;
	errseq_t		f_wb_err;
} __randomize_layout
  __attribute__((aligned(4)));	/* lest something weird decides that 2 is OK */

/* file is open for reading */
#define FMODE_READ		((__force fmode_t)0x1)
// ...

// include/linux/types.h
typedef unsigned int __bitwise fmode_t;

// include/linux/path.h
struct path {
	struct vfsmount *mnt;
	struct dentry *dentry;
} __randomize_layout;

// include/linux/mount.h
struct vfsmount {
	struct dentry *mnt_root;	/* root of the mounted tree */
	struct super_block *mnt_sb;	/* pointer to superblock */
	int mnt_flags;
} __randomize_layout;
```



#### **2.2 `struct inode`**

`struct inode` 代表文件的元数据，包含文件的属性，如文件的大小、权限、所有者、文件类型等。VFS通过 `inode` 来定位文件，并执行相应的文件操作。**每个文件系统都会定义一个自己的 inode 结构**，但它们都会通过VFS接口来进行交互。


具体文件系统的 inode：

- **定义**：每种实际文件系统（如 ext4、XFS）都有自己的 inode 结构（如 `ext4_inode`、`xfs_inode`），存储在磁盘上。
- **作用**：
  - 存储特定文件系统的元数据（如 ext4 的块分配信息、XFS 的日志结构）。
  - 在文件系统挂载时，磁盘 inode 会被加载到内存中，并与 VFS 的 inode 关联。
- **关联方式**：
  - 存储特定文件系统的元数据（如 ext4 的块分配信息、XFS 的日志结构）。
  - *在文件系统挂载时，磁盘 inode 会被加载到内存中，并与 VFS 的 inode 关联。*



```c
// include/linux/fs.h
// 应将大部分为只读且经常访问的字段（尤其是用于 RCU 路径查找和 “stat” 数据的字段）置于 “struct inode” 结构体的开头。
struct inode {
	umode_t			i_mode;             // 文件的类型和权限
	unsigned short		i_opflags;
	kuid_t			i_uid;
	kgid_t			i_gid;
	unsigned int		i_flags;

#ifdef CONFIG_FS_POSIX_ACL
	struct posix_acl	*i_acl;
	struct posix_acl	*i_default_acl;
#endif

	const struct inode_operations	*i_op;		// 指向inode操作函数表的指针
	struct super_block	*i_sb;          // 指向文件系统超级块的指针
	struct address_space	*i_mapping;

#ifdef CONFIG_SECURITY
	void			*i_security;
#endif

	/* Stat data, not accessed from path walking */
	unsigned long		i_ino;          // 文件的 inode 号
	/*
	 * Filesystems may only read i_nlink directly.  They shall use the
	 * following functions for modification:
	 *
	 *    (set|clear|inc|drop)_nlink
	 *    inode_(inc|dec)_link_count
	 */
	union {
		const unsigned int i_nlink;
		unsigned int __i_nlink;
	};
	dev_t			i_rdev;
	loff_t			i_size;             // 文件大小
	struct timespec64	i_atime;
	struct timespec64	i_mtime;
	struct timespec64	i_ctime;
	spinlock_t		i_lock;	/* i_blocks, i_bytes, maybe i_size */
	unsigned short          i_bytes;
	u8			i_blkbits;
	u8			i_write_hint;
	blkcnt_t		i_blocks;

#ifdef __NEED_I_SIZE_ORDERED
	seqcount_t		i_size_seqcount;
#endif

	/* Misc */
	unsigned long		i_state;
	struct rw_semaphore	i_rwsem;

	unsigned long		dirtied_when;	/* jiffies of first dirtying */
	unsigned long		dirtied_time_when;

	struct hlist_node	i_hash;
	struct list_head	i_io_list;	/* backing dev IO list */
#ifdef CONFIG_CGROUP_WRITEBACK
	struct bdi_writeback	*i_wb;		/* the associated cgroup wb */

	/* foreign inode detection, see wbc_detach_inode() */
	int			i_wb_frn_winner;
	u16			i_wb_frn_avg_time;
	u16			i_wb_frn_history;
#endif
	struct list_head	i_lru;		/* inode LRU list */
	struct list_head	i_sb_list;
	struct list_head	i_wb_list;	/* backing dev writeback list */
	union {
		struct hlist_head	i_dentry;
		struct rcu_head		i_rcu;
	};
	atomic64_t		i_version;
	atomic64_t		i_sequence; /* see futex */
	atomic_t		i_count;
	atomic_t		i_dio_count;
	atomic_t		i_writecount;
#if defined(CONFIG_IMA) || defined(CONFIG_FILE_LOCKING)
	atomic_t		i_readcount; /* struct files open RO */
#endif
	union {
		const struct file_operations	*i_fop;	/* former ->i_op->default_file_ops */
		void (*free_inode)(struct inode *);
	};
	struct file_lock_context	*i_flctx;
	struct address_space	i_data;
	struct list_head	i_devices;
	union {
		struct pipe_inode_info	*i_pipe;
		struct block_device	*i_bdev;
		struct cdev		*i_cdev;
		char			*i_link;
		unsigned		i_dir_seq;
	};

	__u32			i_generation;

#ifdef CONFIG_FSNOTIFY
	__u32			i_fsnotify_mask; /* all events this inode cares about */
	struct fsnotify_mark_connector __rcu	*i_fsnotify_marks;
#endif

#ifdef CONFIG_FS_ENCRYPTION
	struct fscrypt_info	*i_crypt_info;
#endif

#ifdef CONFIG_FS_VERITY
	struct fsverity_info	*i_verity_info;
#endif

	void			*i_private; /* fs or device private pointer */
} __randomize_layout;
```



#### **2.3 `struct super_block`**

`struct super_block` 表示一个文件系统的超级块，包含该文件系统的元数据，如文件系统的类型、挂载信息等。VFS通过超级块来访问和管理文件系统的*整体*状态。

文件系统超级块是操作系统中文件系统的核心元数据结构，用于存储*文件系统的全局配置信息和关键参数*。它是文件系统初始化时创建的第一个数据结构，对文件系统的正常运行至关重要。

```c
// include/linux/fs.h
struct super_block {
	struct list_head	s_list;		/* Keep this first */
	dev_t			s_dev;		/* search index; _not_ kdev_t */
	unsigned char		s_blocksize_bits;
	unsigned long		s_blocksize;                    // 文件系统的块大小
	loff_t			s_maxbytes;	/* Max file size */     // 文件系统能够支持的最大文件大小
	struct file_system_type	*s_type;                    // 文件系统类型
	const struct super_operations	*s_op;				// 超级块操作函数表
	const struct dquot_operations	*dq_op;
	const struct quotactl_ops	*s_qcop;
	const struct export_operations *s_export_op;
	unsigned long		s_flags;
	unsigned long		s_iflags;	/* internal SB_I_* flags */
	unsigned long		s_magic;
	struct dentry		*s_root;
	struct rw_semaphore	s_umount;
	int			s_count;
	atomic_t		s_active;
#ifdef CONFIG_SECURITY
	void                    *s_security;
#endif
	const struct xattr_handler **s_xattr;
#ifdef CONFIG_FS_ENCRYPTION
	const struct fscrypt_operations	*s_cop;
	struct key		*s_master_keys; /* master crypto keys in use */
#endif
#ifdef CONFIG_FS_VERITY
	const struct fsverity_operations *s_vop;
#endif
	struct hlist_bl_head	s_roots;	/* alternate root dentries for NFS */
	struct list_head	s_mounts;	/* list of mounts; _not_ for fs use */
	struct block_device	*s_bdev;
	struct backing_dev_info *s_bdi;
	struct mtd_info		*s_mtd;
	struct hlist_node	s_instances;
	unsigned int		s_quota_types;	/* Bitmask of supported quota types */
	struct quota_info	s_dquot;	/* Diskquota specific options */

	struct sb_writers	s_writers;

	/*
	 * Keep s_fs_info, s_time_gran, s_fsnotify_mask, and
	 * s_fsnotify_marks together for cache efficiency. They are frequently
	 * accessed and rarely modified.
	 */
	void			*s_fs_info;	/* Filesystem private info */

	/* Granularity of c/m/atime in ns (cannot be worse than a second) */
	u32			s_time_gran;
	/* Time limits for c/m/atime in seconds */
	time64_t		   s_time_min;
	time64_t		   s_time_max;
#ifdef CONFIG_FSNOTIFY
	__u32			s_fsnotify_mask;
	struct fsnotify_mark_connector __rcu	*s_fsnotify_marks;
#endif

	char			s_id[32];	/* Informational name */
	uuid_t			s_uuid;		/* UUID */

	unsigned int		s_max_links;
	fmode_t			s_mode;

	/*
	 * The next field is for VFS *only*. No filesystems have any business
	 * even looking at it. You had been warned.
	 */
	struct mutex s_vfs_rename_mutex;	/* Kludge */

	/*
	 * Filesystem subtype.  If non-empty the filesystem type field
	 * in /proc/mounts will be "type.subtype"
	 */
	const char *s_subtype;

	const struct dentry_operations *s_d_op; /* default d_op for dentries */

	/*
	 * Saved pool identifier for cleancache (-1 means none)
	 */
	int cleancache_poolid;

	struct shrinker s_shrink;	/* per-sb shrinker handle */

	/* Number of inodes with nlink == 0 but still referenced */
	atomic_long_t s_remove_count;

	/* Pending fsnotify inode refs */
	atomic_long_t s_fsnotify_inode_refs;

	/* Being remounted read-only */
	int s_readonly_remount;

	/* AIO completions deferred from interrupt context */
	struct workqueue_struct *s_dio_done_wq;
	struct hlist_head s_pins;

	/*
	 * Owning user namespace and default context in which to
	 * interpret filesystem uids, gids, quotas, device nodes,
	 * xattrs and security labels.
	 */
	struct user_namespace *s_user_ns;

	/*
	 * The list_lru structure is essentially just a pointer to a table
	 * of per-node lru lists, each of which has its own spinlock.
	 * There is no need to put them into separate cachelines.
	 */
	struct list_lru		s_dentry_lru;
	struct list_lru		s_inode_lru;
	struct rcu_head		rcu;
	struct work_struct	destroy_work;

	struct mutex		s_sync_lock;	/* sync serialisation lock */

	/*
	 * Indicates how deep in a filesystem stack this SB is
	 */
	int s_stack_depth;

	/* s_inode_list_lock protects s_inodes */
	spinlock_t		s_inode_list_lock ____cacheline_aligned_in_smp;
	struct list_head	s_inodes;	/* all inodes */

	spinlock_t		s_inode_wblist_lock;
	struct list_head	s_inodes_wb;	/* writeback inodes */
} __randomize_layout;

```




#### **2.4 `struct dentry`**

`struct dentry` 是目录项的表示，它用于实现路径名到文件的映射。每当文件名被访问时，VFS会通过 `dentry` 结构体来查找对应的 `inode`，并根据文件路径执行相应的操作。

作用：

- **路径解析**：作为文件路径的中间节点，加速路径名到 inode 的转换（如 `open("/path/to/file")`）。
- **缓存机制**：缓存最近访问的目录项，避免重复磁盘 I/O。
- **父子关系**：通过 `d_parent`、`d_subdirs` 等字段构建目录树结构。
- **inode 关联**：通过 `d_inode` 字段指向对应的 inode（一个 inode 可被多个 dentry 引用）。


实际文件系统的关系：

- **磁盘目录项**：每种文件系统（如 ext4、XFS）在磁盘上都有自己的目录项格式，存储文件名和 inode 编号的映射。
- **内存映射**：当访问文件路径时，VFS 从磁盘读取目录项并创建对应的 `struct dentry`，将文件名与 inode 关联。
- **动态映射**：一个磁盘目录项可能对应多个 `dentry`（如硬链接），而一个 `dentry` 始终指向一个 inode


工作流程：

- **路径解析**：当用户执行 `ls /home/user` 时：
  - VFS 从根目录（`/`）的 dentry 开始，查找 `home` 的 dentry。
  - 如果 `home` 的 dentry 已缓存，则直接使用；否则从磁盘读取并创建。
  - 重复此过程，直到找到 `user` 的 dentry 并关联到对应的 inode。
- **硬链接处理**：
  - 多个 dentry（不同文件名）可指向同一个 inode。
  - 修改任一硬链接的文件内容会影响所有关联的 dentry。


与inode区别：

| **struct dentry**                      | **struct inode**                         |
| -------------------------------------- | ---------------------------------------- |
| 表示路径中的一个组件（如目录、文件名） | 表示文件或目录的元数据（权限、时间戳等） |
| 存在于内存的目录项缓存（dcache）       | 存在于内存的 inode 缓存（inode cache）   |
| 可动态创建和销毁（基于访问模式）       | 生命周期与文件系统对象绑定               |
| 可能没有对应的磁盘实体（如挂载点）     | 始终对应磁盘上的文件或目录               |





```c
// include/linux/dcache.h
struct dentry {
	/* RCU lookup touched fields */
	unsigned int d_flags;		/* protected by d_lock */
	seqcount_t d_seq;		/* per dentry seqlock */
	struct hlist_bl_node d_hash;	/* lookup hash list */
	struct dentry *d_parent;	/* parent directory */                      // 父目录项
	struct qstr d_name;
	struct inode *d_inode;		/* Where the name belongs to - NULL is
					 * negative */                                          // 对应的 inode
	unsigned char d_iname[DNAME_INLINE_LEN];	/* small names */

	/* Ref lookup also touches following */
	struct lockref d_lockref;	/* per-dentry lock and refcount */
	const struct dentry_operations *d_op;									// 目录操作函数集
	struct super_block *d_sb;	/* The root of the dentry tree */
	unsigned long d_time;		/* used by d_revalidate */
	void *d_fsdata;			/* fs-specific data */

	union {
		struct list_head d_lru;		/* LRU list */
		wait_queue_head_t *d_wait;	/* in-lookup ones only */
	};
	struct list_head d_child;	/* child of parent list */
	struct list_head d_subdirs;	/* our children */
	/*
	 * d_alias and d_rcu can share memory
	 */
	union {
		struct hlist_node d_alias;	/* inode alias list */
		struct hlist_bl_node d_in_lookup_hash;	/* only for in-lookup ones */
	 	struct rcu_head d_rcu;
	} d_u;
} __randomize_layout;

```





##### **2.3.1 主要作用与功能**

1. **标识文件系统属性**
   - 记录文件系统的类型（如 Ext4、NTFS、FAT32 等）、版本号和 UUID（唯一标识符）。
   - 标识块设备的基本信息，如分区大小、块大小（Block Size）、inode 总数等。
2. **管理存储空间**
   - 记录文件系统中数据块（Data Block）和 inode 的分配状态，例如：
     - 空闲块数量、已用块数量、空闲 inode 数量。
     - 块组（Block Group）的布局信息（常见于 Ext 系列文件系统）。
3. **存储关键元数据**
   - 包含文件系统的挂载时间、最后写入时间、修改时间等时间戳。
   - 记录文件系统的状态（如是否干净卸载、是否需要检查修复），例如 Ext4 通过超级块标记 “脏” 状态（Dirty Bit）。
4. **保障数据一致性**
   - 部分文件系统（如 ZFS、Btrfs）的超级块支持校验和（Checksum），用于检测元数据损坏，确保数据完整性。

##### **2.3.2 典型存储位置与结构**

- **存储位置**：
  超级块通常位于文件系统的固定位置（如磁盘分区的起始扇区，如第 1 个或第 8 个扇区），不同文件系统可能有差异。例如：

  - Ext4 文件系统的超级块位于分区的**第 2 个块**（块编号为 1）。
  - FAT32 的超级块（称为 “引导扇区”）位于分区的第一个扇区。

- **结构示例（以 Ext4 为例）**：

  | 字段名称          | 描述                                                         |
  | ----------------- | ------------------------------------------------------------ |
  | s_inodes_count    | inode 总数                                                   |
  | s_blocks_count    | 块总数                                                       |
  | s_free_blocks     | 空闲块数量                                                   |
  | s_free_inodes     | 空闲 inode 数量                                              |
  | s_magic           | 文件系统魔数（如 Ext4 的魔数为 0xEF53，用于标识文件系统类型） |
  | s_state           | 文件系统状态（如正常、需要修复）                             |
  | s_last_mount_time | 最后挂载时间                                                 |

##### **2.3.3 与其他组件的关系**

1. **inode**：
   超级块管理 inode 的全局分配，而单个文件 / 目录的元数据（如权限、所有者、数据块指针）存储在 inode 中。
2. **数据块（Data Block）**：
   超级块记录数据块的分配情况，文件内容实际存储在数据块中。
3. **引导块（Boot Block）**：
   某些文件系统（如 FAT32）的超级块与引导块合并，包含引导程序代码和文件系统元数据；而 Ext4 等系统的引导块与超级块分离。

##### **2.3.4 常见文件系统的超级块特点**

| 文件系统  | 超级块特点                                                   |
| --------- | ------------------------------------------------------------ |
| **Ext4**  | - 支持多个块组（Block Group），每个块组包含独立的超级块副本（冗余备份）。 - 通过`sudo tune2fs -l /dev/sda1`命令查看超级块信息。 |
| **NTFS**  | - 超级块称为 “主文件表”（MFT）的一部分，存储在特定簇中。 - 包含文件系统日志（NTFS Journal）的位置信息。 |
| **FAT32** | - 超级块位于引导扇区，包含 BPB（BIOS 参数块），记录簇大小、根目录条目数等。 |
| **ZFS**   | - 超级块（称为 “引导块”）包含池（Pool）元数据，支持校验和和事务性写入。 |

##### **2.3.5 重要性与风险**

- **不可缺失性**：
  若超级块损坏，文件系统可能无法挂载或数据丢失。部分文件系统（如 Ext4）会在多个块组中存储超级块副本，可通过工具（如`fsck`）从副本恢复。
- **访问权限**：
  超级块的修改通常需要管理员权限，普通用户无法直接操作，以避免误操作导致文件系统崩溃。



#### **2.5 `struct file_system_type`**

文件系统类型结构。每个*文件系统*都要实现一套自己的文件操作函数，这些函数定义在 `struct file_operations` 和 `struct inode_operations` 结构体中。例如，`read` 和 `write` 操作会在不同的文件系统中有所不同。每种文件系统类型通过 `struct file_system_type` 来注册到VFS。

```c
// include/linux/fs.h
struct file_system_type {
	const char *name;                           // 文件系统名称
	int fs_flags;
#define FS_REQUIRES_DEV		1 
#define FS_BINARY_MOUNTDATA	2
#define FS_HAS_SUBTYPE		4
#define FS_USERNS_MOUNT		8	/* Can be mounted by userns root */
#define FS_DISALLOW_NOTIFY_PERM	16	/* Disable fanotify permission events */
#define FS_RENAME_DOES_D_MOVE	32768	/* FS will handle d_move() during rename() internally. */
	int (*init_fs_context)(struct fs_context *);
	const struct fs_parameter_description *parameters;
	struct dentry *(*mount) (struct file_system_type *, int,
		       const char *, void *);           // 挂载操作
	void (*kill_sb) (struct super_block *);
	struct module *owner;
	struct file_system_type * next;
	struct hlist_head fs_supers;				// 管理该类型所有活跃的 super_block 实例

	struct lock_class_key s_lock_key;
	struct lock_class_key s_umount_key;
	struct lock_class_key s_vfs_rename_key;
	struct lock_class_key s_writers_key[SB_FREEZE_LEVELS];

	struct lock_class_key i_lock_key;
	struct lock_class_key i_mutex_key;
	struct lock_class_key i_mutex_dir_key;
};

```



#### **2.6 `struct file_operations`**

这是文件操作的核心结构体，定义了文件的基本操作（如 `read`、`write`、`open`、`close` 等）在*特定文件系统*中的具体实现。VFS通过它来执行相应的操作。

```c
// include/linux/fs.h
struct file_operations {
	struct module *owner;
	loff_t (*llseek) (struct file *, loff_t, int);
	ssize_t (*read) (struct file *, char __user *, size_t, loff_t *);
	ssize_t (*write) (struct file *, const char __user *, size_t, loff_t *);
	ssize_t (*read_iter) (struct kiocb *, struct iov_iter *);
	ssize_t (*write_iter) (struct kiocb *, struct iov_iter *);
	int (*iopoll)(struct kiocb *kiocb, bool spin);
	int (*iterate) (struct file *, struct dir_context *);
	int (*iterate_shared) (struct file *, struct dir_context *);
	__poll_t (*poll) (struct file *, struct poll_table_struct *);
	long (*unlocked_ioctl) (struct file *, unsigned int, unsigned long);
	long (*compat_ioctl) (struct file *, unsigned int, unsigned long);
	int (*mmap) (struct file *, struct vm_area_struct *);
	unsigned long mmap_supported_flags;
	int (*open) (struct inode *, struct file *);
	int (*flush) (struct file *, fl_owner_t id);
	int (*release) (struct inode *, struct file *);
	int (*fsync) (struct file *, loff_t, loff_t, int datasync);
	int (*fasync) (int, struct file *, int);
	int (*lock) (struct file *, int, struct file_lock *);
	ssize_t (*sendpage) (struct file *, struct page *, int, size_t, loff_t *, int);
	unsigned long (*get_unmapped_area)(struct file *, unsigned long, unsigned long, unsigned long, unsigned long);
	int (*check_flags)(int);
	int (*flock) (struct file *, int, struct file_lock *);
	ssize_t (*splice_write)(struct pipe_inode_info *, struct file *, loff_t *, size_t, unsigned int);
	ssize_t (*splice_read)(struct file *, loff_t *, struct pipe_inode_info *, size_t, unsigned int);
	int (*setlease)(struct file *, long, struct file_lock **, void **);
	long (*fallocate)(struct file *file, int mode, loff_t offset,
			  loff_t len);
	void (*show_fdinfo)(struct seq_file *m, struct file *f);
#ifndef CONFIG_MMU
	unsigned (*mmap_capabilities)(struct file *);
#endif
	ssize_t (*copy_file_range)(struct file *, loff_t, struct file *,
			loff_t, size_t, unsigned int);
	loff_t (*remap_file_range)(struct file *file_in, loff_t pos_in,
				   struct file *file_out, loff_t pos_out,
				   loff_t len, unsigned int remap_flags);
	int (*fadvise)(struct file *, loff_t, loff_t, int);
	bool may_pollfree;
} __randomize_layout;
```



#### **2.7 `struct inode_operations`**

这是文件元数据操作的核心结构体，定义了文件元数据的基本操作（如 `read`、`write`、`open`、`close` 等）在*特定文件系统*中的具体实现。VFS通过它来执行相应的操作。

```c
// include/linux/fs.h
struct inode_operations {
	struct dentry * (*lookup) (struct inode *,struct dentry *, unsigned int);
	const char * (*get_link) (struct dentry *, struct inode *, struct delayed_call *);
	int (*permission) (struct inode *, int);
	struct posix_acl * (*get_acl)(struct inode *, int);

	int (*readlink) (struct dentry *, char __user *,int);

	int (*create) (struct inode *,struct dentry *, umode_t, bool);
	int (*link) (struct dentry *,struct inode *,struct dentry *);
	int (*unlink) (struct inode *,struct dentry *);
	int (*symlink) (struct inode *,struct dentry *,const char *);
	int (*mkdir) (struct inode *,struct dentry *,umode_t);
	int (*rmdir) (struct inode *,struct dentry *);
	int (*mknod) (struct inode *,struct dentry *,umode_t,dev_t);
	int (*rename) (struct inode *, struct dentry *,
			struct inode *, struct dentry *, unsigned int);
	int (*setattr) (struct dentry *, struct iattr *);
	int (*getattr) (const struct path *, struct kstat *, u32, unsigned int);
	ssize_t (*listxattr) (struct dentry *, char *, size_t);
	int (*fiemap)(struct inode *, struct fiemap_extent_info *, u64 start,
		      u64 len);
	int (*update_time)(struct inode *, struct timespec64 *, int);
	int (*atomic_open)(struct inode *, struct dentry *,
			   struct file *, unsigned open_flag,
			   umode_t create_mode);
	int (*tmpfile) (struct inode *, struct dentry *, umode_t);
	int (*set_acl)(struct inode *, struct posix_acl *, int);
} ____cacheline_aligned;

```



#### **2.8 `struct super_operations`**

```c
struct super_operations {
   	struct inode *(*alloc_inode)(struct super_block *sb);
	void (*destroy_inode)(struct inode *);
	void (*free_inode)(struct inode *);

   	void (*dirty_inode) (struct inode *, int flags);
	int (*write_inode) (struct inode *, struct writeback_control *wbc);
	int (*drop_inode) (struct inode *);
	void (*evict_inode) (struct inode *);
	void (*put_super) (struct super_block *);
	int (*sync_fs)(struct super_block *sb, int wait);
	int (*freeze_super) (struct super_block *);
	int (*freeze_fs) (struct super_block *);
	int (*thaw_super) (struct super_block *);
	int (*unfreeze_fs) (struct super_block *);
	int (*statfs) (struct dentry *, struct kstatfs *);
	int (*remount_fs) (struct super_block *, int *, char *);
	void (*umount_begin) (struct super_block *);

	int (*show_options)(struct seq_file *, struct dentry *);
	int (*show_devname)(struct seq_file *, struct dentry *);
	int (*show_path)(struct seq_file *, struct dentry *);
	int (*show_stats)(struct seq_file *, struct dentry *);
#ifdef CONFIG_QUOTA
	ssize_t (*quota_read)(struct super_block *, int, char *, size_t, loff_t);
	ssize_t (*quota_write)(struct super_block *, int, const char *, size_t, loff_t);
	struct dquot **(*get_dquots)(struct inode *);
#endif
	int (*bdev_try_to_free_page)(struct super_block*, struct page*, gfp_t);
	long (*nr_cached_objects)(struct super_block *,
				  struct shrink_control *);
	long (*free_cached_objects)(struct super_block *,
				    struct shrink_control *);
};
```



#### **2.8 `struct dentry_operations`**


```c
struct dentry_operations {
	int (*d_revalidate)(struct dentry *, unsigned int);
	int (*d_weak_revalidate)(struct dentry *, unsigned int);
	int (*d_hash)(const struct dentry *, struct qstr *);
	int (*d_compare)(const struct dentry *,
			unsigned int, const char *, const struct qstr *);
	int (*d_delete)(const struct dentry *);
	int (*d_init)(struct dentry *);
	void (*d_release)(struct dentry *);
	void (*d_prune)(struct dentry *);
	void (*d_iput)(struct dentry *, struct inode *);
	char *(*d_dname)(struct dentry *, char *, int);
	struct vfsmount *(*d_automount)(struct path *);
	int (*d_manage)(const struct path *, bool);
	struct dentry *(*d_real)(struct dentry *, const struct inode *);
} ____cacheline_aligned;
```



### **3. VFS的工作原理**

#### **3.1 文件的打开和查找**

当进程通过系统调用（如 `open`）请求访问某个文件时，VFS会根据文件路径查找相应的文件。VFS首先通过目录项（`dentry`）查找文件对应的 `inode`，然后将文件操作映射到相应的文件系统类型。

- 查找过程：
  - VFS通过挂载点找到文件系统。
  - 通过超级块（`super_block`）定位到文件系统的根目录。
  - 通过目录项（`dentry`）找到对应的 `inode`，并执行相应操作。



#### **3.2 文件操作的处理**

当文件被打开之后，VFS会通过 `struct file_operations` 来执行具体的操作。例如，`read` 操作会调用对应文件系统的 `read` 函数，将数据从存储设备读取到用户空间。



#### **3.3 文件的关闭**

文件操作完成后，VFS会关闭文件，释放相关资源（如文件描述符、`dentry`、`inode` 等）。



#### **3.4 文件的删除和回收**

当文件被删除时，VFS会移除目录项，释放对应的 `inode`，并将其交给内核的内存管理子系统进行回收。



#### **3.5 文件修改的流程**

在 Linux 系统中，文件修改涉及 VFS 层、具体文件系统和磁盘 I/O 等多个环节。下面详细解析整个流程：

##### **1. 用户空间发起修改请求**

用户通过应用程序调用系统调用（如`write()`、`fwrite()`）发起文件修改：

运行

```c
// 用户空间代码示例
int fd = open("/path/to/file", O_WRONLY);
write(fd, "Hello", 5);
close(fd);
```


##### **2. 系统调用进入内核空间**

1. **用户态到内核态切换**：通过中断（如`int 0x80`或`syscall`指令）进入内核。
2. **系统调用处理**：内核根据系统调用号（如`__NR_write`）找到对应的处理函数（如`sys_write()`）。
3. **参数校验**：检查文件描述符是否有效、权限是否足够等。



##### **3. VFS 层处理**

内核通过文件描述符（fd）找到对应的`struct file`：

```c
struct file *f = fget(fd);  // 获取文件对象
```

###### **关键步骤**：

1. **定位 inode**：通过`file->f_inode`获取文件的 inode。
2. **检查权限**：验证进程是否有写权限（`inode->i_mode`）。
3. **调用文件操作函数**：执行`file->f_op->write_iter()`（新接口）或`write()`（旧接口）。



##### **4. 具体文件系统处理**

以 ext4 文件系统为例，调用链通常为：

```plaintext
ext4_file_write_iter() → generic_file_buffered_write() → __block_write_full_page()
```

###### **关键操作**：

1. **页缓存查找**：检查文件内容是否已在页缓存（page cache）中。
   - 命中：直接修改缓存页。
   - 未命中：从磁盘读取数据到缓存页（通过`mpage_readpages()`）。
2. **写入数据**：
   - 将用户数据复制到页缓存（`copy_from_user()`）。
   - 设置缓存页为 “脏”（dirty）状态。
3. **文件大小调整**：
   - 如果写入导致文件变大，更新`inode->i_size`。
   - 分配新的数据块（通过`ext4_get_blocks()`）。



##### **5. 磁盘 I/O 调度**

修改后的页缓存不会立即写入磁盘，而是通过以下机制异步刷新：

###### **脏页回写机制**：

1. **定时回写**：内核线程`pdflush`/`flush`定期将脏页写入磁盘。
2. **内存压力**：当系统内存不足时，`kswapd`会触发脏页回写。
3. **手动触发**：调用`fsync()`、`fdatasync()`或`sync()`强制同步。

###### **具体文件系统的 I/O 操作**：

- **ext4**：通过`ext4_writepage()`将脏页转换为块 I/O 请求。
- **块设备层**：将 I/O 请求排队到设备驱动（如`mmc_blk`、`sd`）。
- **驱动层**：通过 DMA 将数据传输到磁盘硬件。



##### **6. 元数据更新**

文件修改后，inode 元数据（如`i_mtime`、`i_ctime`）需要更新：



1. **标记 inode 为脏**：设置`inode->i_state |= I_DIRTY`。

2. **inode 回写**：与数据页类似，inode 也会异步写入磁盘。

3. 文件系统日志（如 ext4）：
   - 先将修改记录到日志（journal）。
   - 提交事务完成后，再更新实际数据块。



##### **7. 事务提交（日志文件系统）**

对于支持日志的文件系统（如 ext4、XFS）：

1. **开始事务**：在日志中记录操作开始标记。
2. **写入日志**：将数据块和 inode 的修改写入日志区域。
3. **提交事务**：在日志中写入提交标记。
4. **同步数据**：按计划将日志中的修改应用到实际数据区。



##### **8. 完成返回**

1. **数据同步完成**：`fsync()`返回表示数据已持久化到磁盘。
2. **异步完成**：普通`write()`返回仅表示数据已进入页缓存，不保证已写入磁盘。



##### **总结**

###### **流程图**

```plaintext
用户程序 → write() → 系统调用处理 → VFS层 → 具体文件系统 → 页缓存
                                                       ↓
                                                 脏页回写机制
                                                       ↓
                                                块设备层 → 磁盘驱动
                                                       ↓
                                                 元数据更新
                                                       ↓
                                                日志提交（如需要）
```


###### **关键优化机制**

1. **页缓存（Page Cache）**：减少重复磁盘读取，提高性能。
2. **延迟写（Delayed Write）**：合并小写入，减少磁盘 I/O 次数。
3. **预读（Read Ahead）**：提前加载相邻数据块，提高顺序读取性能。
4. **日志（Journaling）**：提高文件系统一致性和崩溃恢复能力。


###### **相关系统调用**

- `write()`：将数据写入文件
- `fsync()`：强制将文件数据和元数据同步到磁盘
- `fdatasync()`：仅同步数据（不同步元数据，性能更高）
- `sync()`：将所有脏页和 inode 同步到磁盘
- `ftruncate()`：截断文件大小






