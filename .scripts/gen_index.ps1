# 重新生成各领域目录的 README.md（导语 + 目录内笔记索引）。
#
# 用法：powershell -NoProfile -ExecutionPolicy Bypass -File .scripts\gen_index.ps1
# 说明：导语写在本脚本的 $Headers 里，索引部分由目录结构自动生成；
#       想改导语就改这里，想改笔记就改目录，然后重跑本脚本。

$ErrorActionPreference = 'Stop'
$enc  = New-Object Text.UTF8Encoding($false)
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Get-Index([string]$domain) {
    $base  = Join-Path $root $domain
    $notes = Get-ChildItem -LiteralPath $base -Recurse -File -Filter *.md -ErrorAction SilentlyContinue |
             Where-Object { $_.FullName -ne (Join-Path $base 'README.md') } | Sort-Object FullName
    $sb = New-Object Text.StringBuilder
    $groups = $notes | Group-Object {
        [IO.Path]::GetDirectoryName($_.FullName).Replace($base, '').TrimStart('\').Replace('\', '/')
    }
    foreach ($g in ($groups | Sort-Object Name)) {
        [void]$sb.AppendLine('### ' + $(if ($g.Name) { $g.Name } else { '（本层）' }))
        foreach ($n in $g.Group) {
            $rel   = $n.FullName.Replace($base + '\', '').Replace('\', '/').Replace(' ', '%20')
            $label = $(if ($n.BaseName -eq 'README') { Split-Path $n.DirectoryName -Leaf } else { $n.BaseName })
            [void]$sb.AppendLine('- [' + $label + '](' + $rel + ')')
        }
        [void]$sb.AppendLine('')
    }
    return $sb.ToString()
}

$Headers = [ordered]@{}

$Headers['00-inbox'] = @'
# 00-inbox — 收件箱

新剪藏、还没归类的笔记先放这里，定期归类到对应领域目录。

规则：这里的内容不该长期停留——在 `git status` 里看到它就说明该整理了。
'@

$Headers['10-dev'] = @'
# 10-dev — 通用开发技能

与具体技术栈无关、可迁移到任何项目的开发技能。

| 子目录 | 内容 |
|---|---|
| `git/` | Git 常用命令 |
| `design-patterns/` | 设计模式（含 UML 图与 Web 层模式） |
| `coding-skills/` | 编码技巧 |
| `build/makefile/` | Makefile |
| `web/echarts/` | Apache ECharts |
'@

$Headers['20-backend'] = @'
# 20-backend — Java 后端

Java 语言、Spring 生态、中间件、数据存储与工程实践。

| 子目录 | 内容 |
|---|---|
| `java/` | 语言与运行时：io、concurrency、thread-basics、collections、jvm |
| `spring/` | boot、cloud、security |
| `middleware/` | dubbo、zookeeper、nacos、seata、sentinel、rabbitmq、quartz、canal、openresty |
| `data/` | mysql、elasticsearch、redis |
| `libs/` | log4j、slf4j、poi、freemarker、jasperreports、swagger |
| `ops/` | docker、tomcat |
| `practice/` | 接口优化、多级缓存、技术方案 |
'@

$Headers['30-hardware'] = @'
# 30-hardware — 硬件

面向整机/板级的硬件知识与诊断。

| 子目录 | 内容 |
|---|---|
| `design/` | 器件与原理图：EEPROM、I2C MUX、如何看硬件原理图 |
| `diagnosis/` | 整机诊断与出厂测试项（见 [diagnosis/README.md](diagnosis/README.md)） |
'@

$Headers['40-system'] = @'
# 40-system — 固件与系统

从固件/引导到内核、再到日常使用。

| 子目录 | 内容 |
|---|---|
| `firmware/` | BIOS/UEFI、ACPI、GPT/MBR、BootLoader、I2C、GPIO、字节序 |
| `bootloader/` | grub、uboot |
| `kernel/` | 内核 API、驱动模型、启动流程、调试（driver / note / reference） |
| `knowledge/` | 启动参数、runlevel、printk 等 |
| `usage/` | Linux 日常命令与运维 |
| `vm/` | KVM 等虚拟化 |
| `c/` | C 语言与工具链：define、GDB、GNU Tools、编译链接 |
'@

$Headers['50-network'] = @'
# 50-network — 网络

| 子目录 | 内容 |
|---|---|
| `protocol/` | 协议分层笔记 L1/L2/L3/L5（含 Summary） |
| `optical/` | 光模块：类型、封装标准 |
| `hardware/` | 硬件原理：交换机高精度时间同步 |
| `software/` | SNMP 等软件组件 |
| `nos/` | 网络操作系统：sonic、onl |
| `onie/` | ONIE：启动/镜像逻辑、机型适配、Secure Boot |
| `misc/` | 交换机与路由器对比 |
'@

$Headers['60-windows'] = @'
# 60-windows — Windows

- `tera-term/`：Tera Term 宏语言（TTL）与命令参考
- `WSL2 Install Linux Kernel Module.md`：WSL2 下编译安装内核模块
'@

$Headers['90-refs'] = @'
# 90-refs — 全局索引

| 文件 | 内容 |
|---|---|
| [LINK.md](LINK.md) | 外部链接收藏（内核源码、SONiC 文档、Linux 教程等） |
| [NOUN.md](NOUN.md) | 术语表（内核、网络） |
'@

$Headers['99-archive'] = @'
# 99-archive — 归档

过时、被取代或不再维护，但仍想保留的内容放这里。

归档时在文件开头加一行说明：归档原因 + 现在应该看哪一篇。
'@

foreach ($d in $Headers.Keys) {
    $body = $Headers[$d].TrimEnd() + "`r`n"
    $idx  = Get-Index $d
    if ($idx.Trim()) { $body += "`r`n## 目录内笔记`r`n`r`n" + $idx }
    $path = Join-Path $root ($d + '\README.md')
    $dir  = [IO.Path]::GetDirectoryName($path)
    if (-not [IO.Directory]::Exists($dir)) { [void][IO.Directory]::CreateDirectory($dir) }
    [IO.File]::WriteAllText($path, $body, $enc)
    $n = ($idx -split "`r`n" | Where-Object { $_ -like '- *' } | Measure-Object).Count
    Write-Host ("{0,-12} README 已生成, 收录 {1} 篇笔记" -f $d, $n)
}
