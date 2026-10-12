{
  "title": "Ubuntu18.04 增加Swap分区",
  "date": "2020-04-17T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351623",
  "author": "LinHuiG",
  "categories": [
    "环境与运维"
  ],
  "tags": [
    "swap",
    "内存"
  ],
  "draft": false,
  "original_date": "2020-04-17",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351623",
  "original_url": "https://blog.linhui.fun/article/31",
  "build": {
    "publishResources": false
  },
  "description": "Ubuntu18.04 增加Swap分区。旧文归档，原始发表于 2020-04-17。",
  "original_date_text": "2020-04-17",
  "original_sort_key": 20200417,
  "original_year": 2020,
  "date_precision": "day"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2020-04-17**；本站迁移：**2026-10-12**。正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351623) · [原个人博客地址](https://blog.linhui.fun/article/31)

## **增加swap分区**

查看内存和swap分区大小命令：

```text
free -m
```

创建swap文件（大小为bs\*count的Swap空间），目录为/myswap：

```text
cd /
sudo mkdir myswap
cd myswap
sudo dd if=/dev/zero of=swapfile bs=1M count=2048
sudo mkswap swapfile
```

激活swap文件：

```text
sudo swapon swapfile
```

设置该swap开机自动挂载：

```text
sudo cp /etc/fstab /etc/fstab.bf
echo '/myswap/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## **删除某swap分区：**

停用该swap分区文件：

```text
sudo swapoff -v /swapfile
```

删除/etc/fstab中对应的行：

//自己用vi或者vim删除

删除swapfile文件：

```text
sudo rm /swap/swapfile
```
