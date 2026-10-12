---
title: 用 Markdown 写好一篇文章
date: 2026-10-12T08:30:00+08:00
slug: markdown-notes
description: 标题、代码、表格与配图，写作常用格式的一页备忘。
summary: 把精力放在内容上。用简单的标题、列表、代码块和图片，组织一篇清楚易读的文章。
categories: [写作笔记]
tags: [Markdown, 写作, 入门]
draft: false
build:
  publishResources: false
---

这是一篇格式示例，也可以当作日常写作的速查表。文章保存在 `content/posts/文章目录/index.md`，配图与文章放在同一个文件夹。

## 标题与段落

文章标题写在文件顶部的 `title` 字段。正文从二级标题开始：

```markdown
## 一个主要问题

先用一段话说明背景，再展开细节。

### 一个具体步骤

这里写操作与结果。
```

段落之间空一行。**加粗**用来强调重点，*斜体*可以标记补充说明。

## 清单与引用

- 每一项表达一个意思。
- 步骤有先后时使用编号。
- 需要解释原因时，直接写成段落。

> 引用适合放原话，也适合突出一条简短的提醒。

## 代码与表格

给代码块标注语言，可以显示对应的语法高亮：

```python
from pathlib import Path

for article in Path('content/posts').glob('*/index.md'):
    print(article.parent.name)
```

| 内容 | 放在哪里 |
| --- | --- |
| 文章正文 | `content/posts/文章目录/index.md` |
| 文章配图 | 同一篇文章的文件夹 |
| 博客名称与导航 | `hugo.toml` |

## 加一张图片

把图片放进文章目录，然后这样引用：

```markdown
![用一句话描述图片](example.png)
```

构建时，博客会为本地 PNG、JPEG、WebP 配图生成压缩后的 WebP 版本，并根据屏幕尺寸选择合适的图片。GIF 和 SVG 保留原格式。

## 发布前再看一遍

检查标题是否清楚、链接是否正确，以及图片有没有文字说明。将草稿字段改为 `draft: false` 后，提交到主分支即可触发自动发布。
