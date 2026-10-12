# 相思不扫久积弥厚

LinHuiG 的个人博客。Hugo + PaperMod，网址为 `https://linhuig.github.io/`，由 GitHub Actions 在 `main` 分支更新后自动发布。

## 项目说明

页面、搜索、文章模板、图片处理、giscus 评论和自动部署工作流已包含在此项目中。`hugo.toml` 已配置本仓库的真实 giscus ID，评论保存在 Announcements 分类。giscus 仅安装到 `LinHuiG/LinHuiG.github.io`。

博客已于 2026-10-12 部署到 GitHub Pages，发布来源为 GitHub Actions。中文搜索与线上评论框已验证。日常更新只需修改 `content/posts/` 中的 Markdown 并提交到 `main`，不需要再运行首次上线脚本。读者通过评论框的 GitHub 登录入口授权后即可留言；第一条留言或回应会自动创建文章讨论。

三篇初始示例已设为草稿，正式列表展示迁入的旧文。关于页使用用户提供的 GitHub 名称，不包含私人邮箱或虚构的履历。

## 本地预览

需要 [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows) 和 Git，在 PowerShell 7 中运行下面的命令。首次运行会从官方发行页下载并校验固定版本 Hugo Extended，只存放在本项目的 `.tools` 文件夹，不修改系统 PATH。

```powershell
./scripts/blog.ps1 preview
```

打开 `http://localhost:1313/`。预览包含草稿，按 Ctrl+C 停止。若 PowerShell 提示脚本策略限制，也可直接使用 Hugo Extended 官方可执行文件：`hugo server -D`；项目不会自动修改系统执行策略。

正式构建：

```powershell
./scripts/blog.ps1 build
```

构建结果位于 `public`，无需提交 Git；工作流会重新生成。

## 在新仓库首次上线（已有站点无需重复）

1. 安装 [GitHub CLI](https://cli.github.com/)，运行 `gh auth login`，登录 **LinHuiG**。凭据只交给官方登录流程，不要粘贴进聊天或代码。
2. 在此项目目录执行：

   ```powershell
   ./scripts/publish.ps1
   ```

   脚本会创建公开仓库 `LinHuiG/LinHuiG.github.io`，开启 Discussions，设置 Pages 使用 GitHub Actions，提交并推送 `main`。若同名仓库已存在而项目没有关联到它，脚本会停止，不覆盖已有站点。
3. 到仓库 **Actions** 等待 `Build and deploy blog` 成功，再访问 `https://linhuig.github.io/`。若账号或组织策略禁用了 Actions，需要先在 GitHub 界面启用。

也可以手动创建同名公开仓库、推送本目录，并在 **Settings → Pages → Build and deployment → Source** 选择 **GitHub Actions**。

本方案源仓库公开。即使文章设置为 `draft: true`，提交进仓库的草稿源码和历史版本仍然公开；私密笔记请放在仓库之外。

## 启用评论（giscus）

1. 仓库 **Settings → General → Features** 开启 **Discussions**。
2. 打开 [giscus GitHub App](https://github.com/apps/giscus)，安装到 **LinHuiG**，选择 **Only select repositories**，仅授权 `LinHuiG.github.io`。这一步需要你在 GitHub 上完成授权。
3. 确认 Discussions 中有 **Announcements** 分类。它应使用 Announcement 类型，适合由 giscus 创建文章讨论。
4. 执行：

   ```powershell
   ./scripts/publish.ps1 -ConfigureComments
   ```

   脚本从 GitHub 读取真实仓库 ID 和分类 ID，保存为仓库 Actions variables，并触发一次重新部署。ID 不是密钥，仓库无需保存访问令牌。
5. 上线后打开任意文章，确认评论框可以加载；登录 GitHub 后可评论、回复和回应。这个步骤才是评论功能的线上验收。

如果不使用脚本，可到 [giscus 配置页](https://giscus.app/zh-CN) 选择仓库与 Announcements，保留 `pathname` 映射、严格匹配和中文，将生成的 `data-repo-id`、`data-category-id` 分别填入 `hugo.toml` 的 `repoId`、`categoryId` 并提交。

评论设置优先使用环境变量 `GISCUS_REPO`、`GISCUS_REPO_ID`、`GISCUS_CATEGORY`、`GISCUS_CATEGORY_ID`，未提供时使用 `hugo.toml`。本地如需预览真实评论，可以设置上述环境变量。

文章地址作为评论关联依据。发布后尽量保持 `slug` 不变；迁移域名但路径不变时，评论关联可以保留。未配置 ID 时显示准备提示，不会加载假的评论框；网络失败时提供 Discussions 入口。评论明暗模式跟随博客切换。

## 写一篇文章

```powershell
./scripts/blog.ps1 new -Slug my-first-post
```

编辑 `content/posts/my-first-post/index.md`。推荐保持英文 `slug` 稳定，标题可以自由使用中文。

```yaml
title: 我的第一篇文章
date: 2026-10-12T10:00:00+08:00
slug: my-first-post
description: 页面描述
summary: 文章列表中的摘要
categories: [技术实践]
tags: [Git, 学习]
draft: false
build:
  publishResources: false
```

把图片放在同一目录：

```text
content/posts/my-first-post/
  index.md
  example.png
```

正文引用 `![有意义的图片说明](example.png)`。构建会将本地 PNG/JPEG/WebP 压缩为最多 1600 像素的 WebP，并生成适合手机的版本。`publishResources: false` 避免将未引用的原始资源整体发布，渲染后的图片会自动输出。Git 仓库中仍保留原图，上传前建议裁剪和缩小大型原图。GIF、SVG 保持原格式，外部图片不处理。

修改完成后：

```powershell
git add .
git commit -m "发布新文章"
git push
```

推送到 `main` 自动上线；拉取请求只做构建检查，不部署。正式构建排除草稿和未来时间文章。

## 常用修改位置

| 内容 | 文件 |
| --- | --- |
| 名称、署名、网址、导航、评论配置 | `hugo.toml` |
| 首页介绍与排版 | `layouts/_partials/home_info.html` |
| 配色、间距、手机布局 | `assets/css/extended/journal.css` |
| 关于我 | `content/about.md` |
| 新文章模板 | `archetypes/posts/index.md` |
| 自动发布 | `.github/workflows/pages.yml` |

文章默认启用评论，某篇关闭可在文章前置字段加 `comments: false`。关于页、搜索页等不显示评论。

## 维护

- 主题已放入 `themes/PaperMod` 并保留 MIT 许可，构建不依赖子模块下载。
- 项目自己的样式和模板在根目录覆盖主题，避免直接修改主题文件。
- Hugo 版本在 `scripts/blog.ps1` 与 `.github/workflows/pages.yml` 中固定；升级时两处同步，并先做本地构建。
- 免费默认网址无需域名证书配置。将来绑定域名时修改 `baseURL`，并在 GitHub Pages 和 DNS 提供商处配置域名。
- 搜索在浏览器本地执行，文章索引不发送到第三方；giscus 是唯一为评论引入的外部服务。

## 首次上线验证

- Hugo Extended 0.167.0 正式构建通过，无警告；生成 33 个 HTML 页面（含分页别名）。
- 首页、文章、分类、标签、归档、搜索、关于、RSS 和 sitemap 均生成，站内链接检查通过。
- 用独立测试文章验证图片生成 1600×800、640×320 WebP，原始图片不发布；测试文章不包含在交付源码中。
- 草稿不进入正式页面和搜索索引；单篇关闭评论生效。
- 搜索中文、无结果、清空、键盘操作和索引失败提示通过 Node 模拟 DOM 测试；giscus 参数、主题同步、错误回退通过同类测试。
- PowerShell 脚本完成语法检查。通过 GitHub 网页完成仓库创建、源码提交、Pages 设置及 giscus 安装；最新自动构建和部署成功。
- 线上桌面首页、中文搜索、文章评论框与 390 像素手机布局已实测，无横向溢出。新文章无讨论的正常空状态不会误报加载失败。未代发测试留言。


## 旧文迁移

2026-10-12 迁入腾讯云原博客的 29 篇公开旧文，按原始发表日期归档，每篇仅展示原始日期与本站迁移日期，并保留来源链接。详见 [迁移清单](MIGRATION.md)。

迁移前已检查正文、77 个原文代码块和 8 张原配图的隐私信息；个人化示例值已泛化，1 张数据库状态截图改成脱敏文本。剩余 7 张配图随文章保存并由 Hugo 压缩。未获发布确认的材料不加入仓库或部署包。


## 写作日期与补录

2026-10-12 发布 11 篇经作者审阅的作品，与 29 篇迁入旧文共同归档。首页、文章列表、分类、标签、归档、RSS 和相邻文章导航共用原始写作时间排序。

日期明确时填写 `date`；只知道年份、月份或季节时，用 `original_date_text` 如实显示，并用 `original_sort_key`（YYYYMMDD，未知部分为 00）和 `original_year` 排序归档。00 仅表示未知精度，不是日历日期；不会写入文章的发布时间元数据。约略日期在已知年月内排列，不推断某一天。`backfilled_at` 与 `lastmod` 不参与文章排序。普通新文章未指定排序字段时使用 `date`。

Windows 换机文章附可下载的 skill 主文件与参考文件；公开内容不含本地审阅元数据或私人来源说明。

## 外观

浅色使用浅灰背景与白色卡片，深色使用黑色背景与深灰卡片。默认跟随浏览器的系统明暗偏好；页头可手动选择浅色、深色或跟随系统，手动选择只保存在当前浏览器。评论配色同步跟随博客。

首页与全部文章按原始写作日期排列，最新一篇使用大卡片。技术、诗文、项目三个入口先筛选全部文章再分页。悬停反馈保持轻微，并尊重系统的减少动态效果偏好。外观逻辑位于 `assets/js/appearance.js`，页头位于 `layouts/_partials/header.html`。
