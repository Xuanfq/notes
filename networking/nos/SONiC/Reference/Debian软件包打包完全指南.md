# Debian软件包打包完全指南
## 一、 核心概念
### 1.1 源码包 vs 二进制包
| 类型         | 定义                                  | 组成文件                                  | 用途                     |
|--------------|---------------------------------------|-------------------------------------------|--------------------------|
| **源码包**   | 包含源码+打包配置的原始包             | `.dsc`（描述文件）、`.tar.xz`（源码压缩包） | 用于构建二进制包，开发者使用 |
| **二进制包** | 从源码包构建出的可安装包             | `.deb`（最终安装文件）| 最终用户安装使用         |

### 1.2 分包（Multi-Package）机制
**核心价值**：一个源码包 → 多个二进制包，实现功能拆分、按需安装、复用构建逻辑。
**典型场景**：`platform-modules` 源码包 → `platform-modules-ds1000.deb`、`platform-modules-abc8000.deb`。

## 二、 打包必备文件与目录
所有打包配置都存放在项目根目录下的 `debian/` 文件夹中，是打包的核心。

### 2.1 必需文件（缺一不可）
| 文件路径             | 作用                                  | 核心要点                                                                 |
|----------------------|---------------------------------------|--------------------------------------------------------------------------|
| `debian/control`     | 分包总配置文件                        | 分**源码段**（全局配置）和**二进制包段**（子包独立配置）|
| `debian/rules`       | 构建规则脚本（Makefile 格式）| 定义编译、安装、清理逻辑，需赋予可执行权限 `chmod +x`|
| `debian/compat`      | debhelper 兼容级别                    | 推荐值 `12`，解决兼容警告，内容仅一行数字                                |
| `debian/changelog`   | 版本更新日志（合规必备）| 记录版本、变更内容、维护者，可通过 `dch --create` 生成                  |

### 2.2 常用可选文件（按需添加）
| 文件命名规则                | 作用                                  | 适用场景                                                                 |
|-----------------------------|---------------------------------------|--------------------------------------------------------------------------|
| `debian/[包名].install`     | 定义文件安装路径                      | 替代 `rules` 中的 `cp` 命令，格式：`源文件 目标目录`|
| `debian/[包名].postinst`    | 包安装后执行脚本                      | 加载内核模块、启动服务，需 `chmod +x`|
| `debian/[包名].prerm`       | 包卸载前执行脚本                      | 卸载内核模块、停止服务，需 `chmod +x`|
| `debian/[包名].conffiles`   | 标记配置文件                          | 升级包时不覆盖用户自定义配置，每行一个配置文件路径                        |
| `debian/copyright`          | 版权与许可证信息                      | 开源软件打包必备，声明版权所有者、许可证类型                              |
| `debian/patches/`           | 存放源码补丁                          | 用于修改上游源码，适配 Debian 环境                                      |
| `debian/source/format`      | 源码包格式                            | 推荐 `3.0 (quilt)`，支持补丁管理                                        |

|   文件后缀   |       作用       |                 示例                 |
| :----------: | :--------------: | :----------------------------------: |
| `.postinst`  | 安装后执行的脚本 |        加载对应模块、启动服务        |
|   `.prerm`   | 卸载前执行的脚本 |       卸载前卸载模块、停止服务       |
|  `.postrm`   | 卸载后执行的脚本 |        清理残留文件、恢复配置        |
|  `.preinst`  | 安装前执行的脚本 |         检查依赖、备份旧配置         |
|  `.install`  | 定义文件安装路径 | 指定 `.ko` 文件复制到子包的哪个目录  |
| `.conffiles` |   标记配置文件   |      升级时不覆盖用户自定义配置      |
| `.templates` | debconf 交互模板 | 安装时提示用户输入配置（如模块参数） |
| `.manpages`  |    手册页路径    |        指定子包的帮助文档位置        |

### 2.3 目录结构示例（多模块分包场景）
```
project-root/
├── modules/                  # 内核模块源码
│   ├── ds1000/
│   └── abc8000/
└── debian/
    ├── control                      # 分包总配置
    ├── rules                        # 构建规则
    ├── compat                       # 兼容级别
    ├── changelog                    # 更新日志
    ├── platform-modules-ds1000.postinst  # ds1000 安装后脚本
    ├── platform-modules-abc8000.prerm     # abc8000 卸载前脚本
    ├── platform-modules-ds1000.install    # ds1000 文件安装规则
    └── platform-modules-abc8000.install   # abc8000 文件安装规则
```

## 三、 核心配置文件详解
### 3.1 debian/control（分包核心）
分段式配置，分为**源码段**（1 个）和**二进制包段**（多个，每个对应一个子包）。

#### 完整示例（多模块场景）
```
# -------------------------- 源码段（全局配置） --------------------------
Source: platform-modules          # 源码包名（全局唯一）
Section: kernel                   # 包分类（内核相关）
Priority: optional                # 优先级（可选安装）
Maintainer: Your Name <your@email.com>  # 维护者信息
Build-Depends: debhelper (>= 12), build-essential, linux-headers-$(uname -r)  # 构建依赖
Standards-Version: 4.6.2          # 遵循的 Debian 标准版本

# -------------------------- 二进制包段 1：ds1000 模块 --------------------------
Package: platform-modules-ds1000  # 子包名
Architecture: any                 # 架构（any=任意架构，all=架构无关）
Depends: ${shlibs:Depends}, ${misc:Depends}, linux-image-$(uname -r)  # 运行依赖
Description: Kernel modules for DS1000 platform  # 简短描述
 This package contains exclusive kernel modules and scripts for DS1000 hardware.
 # 详细描述，必须缩进

# -------------------------- 二进制包段 2：abc8000 模块 --------------------------
Package: platform-modules-abc8000
Architecture: any
Depends: ${shlibs:Depends}, ${misc:Depends}, linux-image-$(uname -r), abc8000-firmware  # 专属依赖
Description: Kernel modules for ABC8000 platform
 This package requires ABC8000 firmware to work properly.
```

#### 关键变量说明
| 变量               | 作用                                  |
|--------------------|---------------------------------------|
| `${shlibs:Depends}`| 自动推导共享库依赖                    |
| `${misc:Depends}`  | 自动填充通用依赖（如 debhelper 相关）|
| `$(uname -r)`      | 动态获取当前内核版本                  |

### 3.2 debian/rules（构建规则）
Makefile 格式脚本，核心是 `dh $@` 调用 debhelper 工具链，支持自定义覆盖默认逻辑。

#### 最简通用版（适配分包）
```makefile
#!/usr/bin/make -f

# 核心规则：debhelper 自动处理所有子包
%:
	dh $@

# 自定义覆盖：为子包添加差异化逻辑
override_dh_install:
	# 先执行默认逻辑（加载各子包的 .install 文件）
	dh_install
	# 为 ds1000 额外复制配置文件
	install -D -m 644 ./configs/ds1000.conf debian/platform-modules-ds1000/etc/ds1000.conf
	# 为 abc8000 额外复制固件
	install -D -m 644 ./firmware/abc8000.fw debian/platform-modules-abc8000/lib/firmware/

# 批量处理所有子包（适合大量模块）
override_dh_installdirs:
	MODULES := ds1000 abc8000 xyz9000
	for mod in $(MODULES); do \
		dh_installdirs -pplatform-modules-$$mod /lib/modules/$(shell uname -r)/extra/$$mod; \
	done
```

#### 关键技巧
- `-p[子包名]`：精准操作单个子包，如 `dh_installdirs -pplatform-modules-ds1000 /path`
- `override_xxx`：覆盖 debhelper 默认命令（如 `dh_install`）
- `$(shell uname -r)`：Makefile 中获取内核版本（Shell 脚本中用 `$(uname -r)`）

### 3.3 子包专属脚本（.postinst/.prerm）
命名规则：`debian/[子包名].postinst`，需赋予可执行权限 `chmod +x`。

#### 示例：platform-modules-ds1000.postinst
```bash
#!/bin/sh
set -e  # 出错立即退出

# 安装后自动加载 ds1000 模块
echo "Loading DS1000 kernel modules..."
modprobe ds1000_core || true
modprobe ds1000_usb || true

# 启动专属服务（如有）
systemctl enable --now ds1000-monitor || true

exit 0
```

## 四、 打包命令与流程
### 4.1 安装打包依赖工具
```bash
# 核心依赖（必装）
sudo apt install dpkg-dev fakeroot debhelper build-essential
# 内核模块打包额外依赖
sudo apt install linux-headers-$(uname -r) module-assistant
```

### 4.2 核心打包命令
```bash
dpkg-buildpackage -rfakeroot -b -us -uc -tc -j4
```

| 参数                 | 作用                                  |
|----------------------|---------------------------------------|
| `-rfakeroot`         | 模拟 root 权限，避免权限混乱          |
| `-b`                 | 仅构建二进制包（不生成源码包）|
| `-us -uc`            | 跳过源码包和 .changes 文件签名        |
| `-tc`                | 构建完成后清理临时文件                |
| `-jN`                | 指定多核编译线程数（N=CPU 核心数）|
| `--admindir`         | 自定义 dpkg 管理目录（定制化场景）|
| `-T[目标]`           | 指定 Makefile 自定义目标（如 SONiC 项目）|

### 4.3 打包流程
1. **准备工作**：编写 `debian/` 目录下的所有配置文件，赋予 `rules` 和脚本可执行权限。
2. **检查配置**：验证配置文件语法正确性
    ```bash
    # 检查 control 文件依赖
    dpkg-checkbuilddeps debian/control
    # 检查 rules 文件语法
    make -f debian/rules check
    # 模拟构建（不生成最终包）
    dpkg-buildpackage -rfakeroot -b -us -uc -nc -d
    ```
3. **执行打包**：运行 `dpkg-buildpackage` 命令，构建完成后在项目根目录生成 `.deb` 包。
4. **验证安装**：测试子包的独立性和脚本有效性
    ```bash
    # 安装子包
    dpkg -i platform-modules-ds1000_1.0.0_amd64.deb
    # 检查模块是否加载
    lsmod | grep ds1000
    # 卸载子包
    dpkg -r platform-modules-ds1000
    ```

## 五、 分包机制深度解析
### 5.1 分包核心原理
- **一个源码包**：共享同一份源码和构建逻辑（`rules`、`control` 源码段）。
- **多个二进制包**：每个子包有独立的依赖、脚本、安装路径，通过 `debian/[子包名].[后缀]` 关联专属文件。
- **自动关联**：debhelper 工具会根据文件名自动识别子包专属文件，无需手动配置。

### 5.2 分包优势
1. **功能拆分**：将大项目拆分为多个小功能包，便于维护。
2. **按需安装**：用户仅安装需要的模块（如只装 `ds1000`，不装 `abc8000`）。
3. **独立管理**：子包的安装、卸载、升级互不影响，脚本和依赖独立。
4. **复用逻辑**：避免重复编写构建脚本，降低维护成本。

### 5.3 分包注意事项
1. **文件权限**：所有子包脚本（`.postinst`/`.prerm`）必须执行 `chmod +x`，否则安装时不生效。
2. **依赖冲突**：子包之间的 `Depends`/`Conflicts` 需避免循环依赖。
3. **变量区分**：Makefile 中用 `$(shell uname -r)`，Shell 脚本中用 `$(uname -r)`。
4. **全局 vs 专属**：优先使用子包专属文件，避免全局文件导致逻辑混乱。

## 六、 常见问题与避坑指南
### 权限问题
- **问题**：无法创建 `/lib/modules` 目录
  **原因**：未使用 `-rfakeroot` 模拟 root 权限
  **解决**：打包命令添加 `-rfakeroot` 参数，避免直接用 `sudo` 构建。

- **问题**：安装后脚本不执行
  **原因**：脚本未赋予可执行权限
  **解决**：`chmod +x debian/[子包名].postinst`

### 兼容警告
- **问题**：`Compatibility levels before 10 are deprecated`
  **原因**：`debian/compat` 文件级别过低
  **解决**：修改 `debian/compat` 内容为 `12`

## 七、 进阶技巧
### 7.1 批量生成子包文件
当模块数量较多时，编写 Shell 脚本批量生成子包专属文件：
```bash
#!/bin/bash
MODULES="ds1000 abc8000 xyz9000"
for mod in $MODULES; do
    # 生成 .install 文件
    echo "./modules/$mod/*.ko /lib/modules/\$(uname -r)/extra/$mod/" > debian/platform-modules-$mod.install
    # 生成 .postinst 脚本
    cat > debian/platform-modules-$mod.postinst << EOF
#!/bin/sh
set -e
echo "Loading $mod modules..."
modprobe $mod_core || true
exit 0
EOF
    chmod +x debian/platform-modules-$mod.postinst
done
```

### 7.2 交叉编译打包
为非当前架构（如 x86 构建 arm64 包）添加交叉编译选项：
```bash
# 定义交叉编译选项
export ANT_DEB_CROSS_OPT="--host=arm64-linux-gnu"
# 执行打包
dpkg-buildpackage -rfakeroot -b -us -uc -tc $ANT_DEB_CROSS_OPT
```

### 7.3 日志记录
将打包过程日志写入文件，便于调试：
```bash
dpkg-buildpackage -rfakeroot -b -us -uc --log=/tmp/build.log
```

## 八、 参考资料
1. [Debian 官方打包指南](https://www.debian.org/doc/manuals/debian-faq/pkg-basics.en.html)
2. [debhelper 工具手册](https://manpages.debian.org/unstable/debhelper/debhelper.7.en.html)
3. [SONiC Wiki](https://github.com/Azure/SONiC/wiki)

---







