# Notes

个人笔记仓库。按**领域**分域，域内按**主题**分目录，主题目录里是一篇或多篇 Markdown 加它自己的图片目录。

## 领域

| 目录 | 内容 |
|---|---|
| [`00-inbox/`](00-inbox/) | 收件箱：新剪藏、还没归类的笔记 |
| [`10-dev/`](10-dev/) | 通用开发技能：git、设计模式、编码技巧、构建、前端 |
| [`20-backend/`](20-backend/) | Java 后端：java、spring、middleware、data、libs、ops、practice |
| [`30-hardware/`](30-hardware/) | 硬件：器件与原理图、整机诊断与测试项 |
| [`40-system/`](40-system/) | 固件与系统：BIOS/UEFI、引导、内核、Linux 使用、虚拟化 |
| [`50-network/`](50-network/) | 网络：协议、光模块、网络操作系统（SONiC / ONL / ONIE） |
| [`60-windows/`](60-windows/) | Windows 相关 |
| [`90-refs/`](90-refs/) | 全局索引：外链收藏、术语表 |
| [`99-archive/`](99-archive/) | 归档：过时但想保留的内容 |

每个领域目录下都有 `README.md`，列出该领域内的全部笔记。当前学习/工作方向见 [`TODO.md`](TODO.md)。

## 约定

1. **一篇笔记一个主题目录**：`<topic>/<note>.md`，图片放在主题的 `assets/`，或笔记自己的 `<note>.assets/`（两种都在用，新建笔记用后者），由 [.scripts/download_images.sh](.scripts/download_images.sh) 下载与维护。
2. **目录名用小写英文 + 短横线**；笔记文件名保留中文标题（可读性优先）。
3. **一个主题有 3 篇以上笔记、或需要独立附件时**，才在它下面再分子目录。
4. **图片就近放，大文件出仓**：成套 PDF 资料和大体量二进制（含第三方源码包）放在仓库外的 `D:\Project\notes-resources`（对照表见该目录的 README）；与笔记直接相关、体量小的示例代码留在笔记目录里。
5. **版本用 git 表达**：不再有 `(finish)` 双份、`.md.orig` 脚本备份、`文件名 1.png` 同步冲突副本这类东西。
6. 笔记之间用**相对 Markdown 链接**互链，不使用 `[[wiki]]` 语法。
7. 新笔记先写进 `00-inbox/`，定期归类到对应领域。

## 子模块

`private/` 是私有笔记子模块（`git@github.com:Xuanfq/notes-private.git`），本机尚未检出，需要时执行：

```bash
git submodule update --init private
```

## 变更记录

### 本次结构重构

顶层由 `Internet application tech / basic hardware / basic software / diagnosis / lang / linux / networking / windows` 重划为上面 9 个目录。原来的 `Internet application tech` 里，`Git`、`DesignPattern`、`Programming Skills`、`Apache ECharts`、`lang/makefile` 这些**与技术栈无关**的内容被拆到了 `10-dev`，其余 Java 生态按 `java / spring / middleware / data / libs / ops / practice` 归入 `20-backend`。

清理与瘦身：

- 删除 **44 组 `(finish)` 双份**（其中 16 组正文已经漂移）、8 个 `.md.orig` 脚本备份、61 个 `文件名 1.png` 同步冲突副本、5 张重复图片，共 117 个文件。
- 约 **131MB** 二进制与第三方源码移出仓库：`linux/.book` 的 7 个 PDF（PCIe 规范等）、教程配套的 Java 工程与 nginx 程序、ONIE/ONL 的厂商示例与固件、混在图片目录里的 seata 安装包（44.7MB）和 redis 源码包。
- 仓库工作区从 265MB 降到约 135MB。注意 `.git` 里仍保留这些文件的历史，仓库总大小不会因此变小。

### 已废弃的约定

`(finish)` 后缀的规则原本是「`xxx(finish).md` 的图片走云端图床，`xxx.md` 的图片放本地 `assets/`」，等于同一篇正文维护两份，实际已经出现 16 组内容漂移。现在正文只保留离线版；需要生成走云端的发布版本时，用脚本改写图片链接即可。
