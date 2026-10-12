{
  "title": "字符画视频 动态字符画java源代码2.0",
  "date": "2021-05-09T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351637",
  "author": "LinHuiG",
  "categories": [
    "Java实践"
  ],
  "tags": [
    "java",
    "代码规范",
    "内存",
    "视频",
    "线程"
  ],
  "draft": false,
  "original_date": "2021-05-09",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351637",
  "original_url": "https://blog.linhui.fun/article/54",
  "build": {
    "publishResources": false
  },
  "description": "字符画视频 动态字符画java源代码2.0。旧文归档，原始发表于 2021-05-09。",
  "original_date_text": "2021-05-09",
  "original_sort_key": 20210509,
  "original_year": 2021,
  "date_precision": "day"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2021-05-09**；本站迁移：**2026-10-12**。正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351637) · [原个人博客地址](https://blog.linhui.fun/article/54)

之前有 [字符画视频 动态字符画java源代码](</posts/tencent-2351615/>) 已经做了差不多了，今天运行了一下发现内存泄露，代码规范，线程安全......全都有问题，，改了改现在内存泄露好一些了（之前大点的视频一跑直接内存爆炸，太信任GC了），线程安全加了Lock目前来看没啥问题，，代码规范..能用就行，以后再改..。

加了个新功能，直接导出MJPG格式的视频，然后可以用ffmpeg转换成mp4。

具体使用方法如下：

##### 进入Draw，设置好视频地址，运行生成vedio文件（无音源）

1. 进入Play可以播放vedio文件（无音源），可设置音源播放

1. 进入VedioToMjpg可以将vedio文件转为Mjpg视频文件（无音源）

1. 可以使用ffmpeg将Mjpg视频文件转为mp4 如：ffmpeg -i input.mjpg -i input.mp3 -c:v libx264 -strict -2 output.mp4
