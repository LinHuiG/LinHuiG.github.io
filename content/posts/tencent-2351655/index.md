{
  "title": "小气鬼送礼物算法优化-（2020阿里笔试题）",
  "date": "2022-03-04T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351655",
  "author": "LinHuiG",
  "categories": [
    "算法练习"
  ],
  "tags": [
    "遍历",
    "数组",
    "算法",
    "优化"
  ],
  "draft": false,
  "original_date": "2022-03-04",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351655",
  "original_url": "https://blog.linhui.fun/article/60",
  "build": {
    "publishResources": false
  },
  "description": "小气鬼送礼物算法优化-（2020阿里笔试题）。旧文归档，原始发表于 2022-03-04。",
  "original_date_text": "2022-03-04",
  "original_sort_key": 20220304,
  "original_year": 2022,
  "date_precision": "day"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2022-03-04**；本站迁移：**2026-10-12**。正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351655) · [原个人博客地址](https://blog.linhui.fun/article/60)

原解在：[http://www.linhui.fun/article/47](</posts/tencent-2351656/>)

### 题面是一个装逼小气鬼送礼物，他有一个架子，有n排礼物（每个礼物有自己的权值c，c越大礼物越贵），他要送m个礼物出去，但是他又不想送最贵的m个又想装大方，所以他给自己立了个规矩，每次选礼物都只能从任意一排的两端选择，问他最贵能送多少权值出去？

### 输入格式：第一行输入n，m ，下面n行每行输入一个x代表这一行有x个礼物，后面跟x个数字，每个数字代表这个位置的礼物的权值。

### 输出：一个数字，代表最贵的权值。

**发现计算b数组的时候也可以动态规划算，并且可以优化为一维。**

**另外算dp数组的时候不需要复制，也不需要遍历到m（到本行最大数量即可）**

```cpp
#include <iostream>
#include<stdio.h>
int c[105];
int b[105];
int dp[10005];
int main() {
    int n, m, x;
    scanf("%d%d", & n, &m);
    for (int i = 0; i < n; i++) {
        scanf("%d", & c[0]);
        for (int j = 1; j <= c[0]; j++) {
            scanf("%d", & x);
            c[j] = j > 1 ? c[j - 1] + x : x;
            for (int k = j; k >= 1; k--) {
                b[k] = b[k - 1] + x > c[k] ? b[k - 1] + x : c[k];
            }
        }
        for (int j = m; j >= 1; j--) {
            for (int k = 1; k <= c[0] && k <= j; k++) {
                int temp = dp[j - k] + b[k];
                dp[j] = temp > dp[j] ? temp : dp[j];
            }
        }
    }
    printf("%d\n", dp[m]);
}
```
