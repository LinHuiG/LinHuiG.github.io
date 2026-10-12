{
  "title": "记京东笔试编程题目（JAVA开发）",
  "date": "2020-08-27T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351641",
  "author": "LinHuiG",
  "categories": [
    "算法练习"
  ],
  "tags": [
    "java",
    "编程",
    "开发"
  ],
  "draft": false,
  "original_date": "2020-08-27",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351641",
  "original_url": "https://blog.linhui.fun/article/51",
  "build": {
    "publishResources": false
  },
  "description": "记京东笔试编程题目（JAVA开发）。旧文归档，原始发表于 2020-08-27。"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2020-08-27**；本站迁移：**2026-10-12**。原始日期依据腾讯云页尾记录，正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351641) · [原个人博客地址](https://blog.linhui.fun/article/51)

第一题是给你2,3,5三个数字，问你用这三个数字组成的数字按照大小排序，第n个是多少。（2,3,5,22,23,25,32,33,35,52,53,55,222,223........）

思路：1位数是3个，2位数是9个，k位数是3^k个，用n一路减下去，看看第n个是几位数，如第10个的话，10&gt;3,所以大于一位数，10-3=7,7&lt;=9,所以是两位数，两位数里的第7个，这题就转换成3进制中第7个数字是什么了（两位数），由于进制是0-base，所以7-1=6，一个个位算下去，6%3=0，所以第一位选择第0个的2，然后6/3=2，算第2位，2%3=2，所以选择第2个数5，最后结果是52~

代码不贴了~

第二题是很简单的dp问题，问你一个类型下面的图，一个球从上往下滚，每滚到一个数字就加上它，滚到最底层的时候，最大的数是多少？（只能向下或向左下右下滚）

                                                3

                                       2       5       7

                              9       6       2       7       4

                     6       7       4       7       9       5       10

首先把这个图装换一下变成

3

2       5       7

9       6       2       7       4

6       7       4       7       9       5       10

然后每个球只能往下，右下，右右下滚，就好做了~

dp一波就行了~

代码如下：

```cpp
#include <iostream>
#include<stdio.h>
#include<string>
#include <vector>
#include <algorithm>
#include <stack>
#include <set>
#include <map>
#include<string.h>
using namespace std;
int dp[1000];
int a[1000];
int main()
{
	int n;
	scanf("%d", &n);
	for (int i = 1; i <= n; i++)
	{
		for (int j = 0; j < 2 * i - 1; j++)scanf("%d", &a[j]);
		for (int j = 2 * i - 2; j >=0; j--)
		{
			if (j >= 2 && dp[j - 2] > dp[j])dp[j] = dp[j - 2];
			if (j >= 1 && dp[j - 1] > dp[j])dp[j] = dp[j - 1];
			dp[j] += a[j];
		}
	}
	int ans = dp[0];
	for (int j = 0; j < 2 * n - 1; j++)ans = ans > dp[j] ? ans : dp[j];
	printf("%d\n", ans);
}
```
