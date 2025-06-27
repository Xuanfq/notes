# Build

## Environment

### Docker

```shell
aiden@Xuanfq:~/workspace/onl/OpenNetworkLinux$ tree docker/
docker/
├── images
│   ├── builder7
│   │   ├── 1.0
│   │   │   ├── Dockerfile
│   │   │   └── Makefile
│   │   ├── 1.1
│   │   │   ├── Dockerfile
│   │   │   └── Makefile
│   │   └── 1.2
│   │       ├── README
│   │       └── history
│   ├── builder8
│   │   ├── 1.0
│   │   │   ├── Dockerfile
│   │   │   └── Makefile
│   │   ├── 1.1
│   │   │   ├── Dockerfile
│   │   │   └── Makefile
│   │   ├── ...
│   │   ├── 1.11
│   │   │   ├── Dockerfile
│   │   │   └── Makefile
│   ├── builder9
│   │   ├── 1.0
│   │   │   ├── Dockerfile
│   │   │   └── Makefile
│   │   ├── ...
│   │   └── 1.6
│   │       ├── Dockerfile
│   │       └── Makefile
│   ├── builder10
│   │   ├── 1.0
│   │   │   ├── Dockerfile
│   │   │   └── Makefile
│   │   ├── 1.1
│   │   │   ├── Dockerfile
│   │   │   ├── Makefile
│   │   │   └── multistrap-insecure-fix.patch
│   │   └── 1.2
│   │       ├── Dockerfile
│   │       └── Makefile
└── tools
    ├── Makefile
    ├── PKG.yml
    ├── container-id
    ├── docker_shell
    └── onlbuilder

32 directories, 56 files
aiden@Xuanfq:~/workspace/onl/OpenNetworkLinux$ 
```

用到了两个脚本：
- `docker/tools/docker_shell` -> `docker|/bin/docker_shell`: 用于初始化docker容器用户，使其与本地用户一致。
- `docker/tools/container-id` -> `docker|/bin/container-id`: 没有实际使用。


### Usage

Notice: 低版本的可能无法编译，如`debian7`, `debian8`, 需要修改镜像源等。


**Build OpenNetworkLinux Docker**:

```bash
#> cd OpenNetworkLinux/
#> make docker  # 通过命令 `@docker/tools/onlbuilder -$(VERSION) --isolate --hostname onlbuilder$(VERSION) --pull --autobuild --non-interactive` 拉取docker
#> Pulling opennetworklinux/builder7:1.0…
```

Notice: 也可以进入`docker/images/builder(debian version 7-10)/(docker version)`进行`make build`构建image，但构建高版本的docker version, 需要从低版本开始编译!


**Enter Docker Container**:

```bash
#> docker/tools/onlbuilder -9  # or -7/-8/-9/-10, default is -8
#> source setup.env
#> apt-cacher-ng  # 当局域网内某台主机通过 APT 安装或更新软件时，apt-cacher-ng 会将下载的软件包、索引文件（如 .deb 文件、Packages.gz 等）缓存到本地。
#> make amd64 arm64 onl-x86 onl-ppc
```


**Auto Build**:

- 方式1：设置运行命令
```bash
#> docker/tools/onlbuilder -9 --command "make amd64"
```

- 方式2：设置隔离环境和自动编译(`make all`)
```bash
#> docker/tools/onlbuilder -9 --isolates --hostname "autobuild"  --autobuild (--non-interactive)
```
实际上会将当前项目目录作为Home目录，通过项目`.bashrc`自动触发Build。



**More**:

Ref: `docs/Building.md`



## 构建逻辑与过程





