{
  "title": "记华为笔试编程题目（软件开发）",
  "date": "2020-08-12T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351642",
  "author": "LinHuiG",
  "categories": [
    "算法练习"
  ],
  "tags": [
    "编程",
    "华为",
    "软件开发",
    "字符串"
  ],
  "draft": false,
  "original_date": "2020-08-12",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351642",
  "original_url": "https://blog.linhui.fun/article/50",
  "build": {
    "publishResources": false
  },
  "description": "记华为笔试编程题目（软件开发）。旧文归档，原始发表于 2020-08-12。",
  "original_date_text": "2020-08-12",
  "original_sort_key": 20200812,
  "original_year": 2020,
  "date_precision": "day"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2020-08-12**；本站迁移：**2026-10-12**。正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351642) · [原个人博客地址](https://blog.linhui.fun/article/50)

倒霉透了，电脑每次都在关键时候给我整点刺激的，笔试做最后一题的时候，ide卡死了，怕关了笔试页面打不开又不敢重启，硬是靠着记事本+脑内编译做完了。。。。

话说为啥华为阿里这些大企业笔试那么水，发offer却。。。。。

今天的题目比较简单，第一题是让你开个咖啡店，每一杯咖啡5块钱，接下来进来一堆顾客，每个顾客都会拿5块或10块或20块的整钱支付，问你能不能找的开，初始状态你没有零钱~

这题秒了~~不放代码了~

第二题是个最基本的DFS，给你个地图问你从左上角到右下角是否可达，，也秒了~

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
using namespace std;
int a[100][100];
bool b[100][100];
int bc;
int m, n;
bool dfs(int i, int j)
{
	if(i < 0 || j < 0)return 0;
	if (i >= n || j >= m)return 0;
	if (i == n - 1 && j == m - 1)return 1;
	if (b[i][j])return 0;
	b[i][j] = 1;
	if (!a[i][j])return 0;
	if (dfs(i - bc, j))return 1;
	if (dfs(i + bc, j))return 1;
	if (dfs(i, j - bc))return 1;
	if (dfs(i, j + bc))return 1;
	return 0;
}
int main()
{

	scanf("%d%d%d", &bc,&n,&m);
	for (int i = 0; i < n; i++)
	{
		for (int j = 0; j < m; j++)
		{
			scanf("%d", &a[i][j]);
		}
	}
	if(dfs(0, 0))printf("1\n");
	else printf("0\n");
}
```

第三题，爷的噩梦来了，题目倒是没啥，IDE抽风了，重启IDE也不能解决，，又不敢跳出去百度这问题咋解决，万一被判作弊就得不偿失，，也不敢直接重启，，万一这卷子直接给我提交了。。。。

最后靠着记事本+脑内运行+oj自测，我终于ac了！！！

题目也不难，就是个字符串按照一定规则重新排列的，给你个字符串比如abcdefghijklmn，再给你个数字比如5

然后按照这个样子画一下：

a          b

   c    d

      e

   f    g

h          i

   j    k

      l

  m   n

然后竖下来读

变成 ahcfjmeldgknbi

难度不高~代码如下：（我恨Visio Studio.....本来三题半小时多就能做完的，呜呜呜~）

```cpp
#include <iostream>
#include<stdio.h>
#include<string>
#include <vector>
#include <algorithm>
#include <stack>
#include <set>
#include <map>
using namespace std;
string str="";
int main()
{
	string strs;
	cin >> strs;
	int x=0;
	bool pd = 0;
	for (char c:strs)
	{
		if (c == ',')
		{
			pd = 1;
			continue;
		}
		if (!pd)str.push_back(c);
		else
		{
			x *= 10;
			x += c - '0';
		}
	}
	int zq = 2 * x - 3;
	string ans="";
	for (int i = 0; i < str.size(); i+=zq)
	{
		ans.push_back(str[i]);
	}
	for (int i = 1; i < x  / 2;i++)
	{
		for (int j = 2*i; j < str.size(); j += zq)
		{
			ans.push_back(str[j]);
			int t = (x + 1) / 2 - i;
			t = 4 * t - 5 + j;
			if(t< str.size())ans.push_back(str[t]);
		}
	}
	for(int i=x-1; i < str.size(); i += zq)
	{
		ans.push_back(str[i]);
	}
	for (int i = x / 2-1; i > 0; i--)
	{
		for (int j = 2 * i + 1; j < str.size(); j += zq)
		{
			ans.push_back(str[j]);
			int t= (x + 1) / 2 - i;
			t = 4 * t - 5 + j;
			if (t < str.size())ans.push_back(str[t]);
		}
	}
	for (int i = 1; i < str.size(); i += zq)
	{
		ans.push_back(str[i]);
	}
	cout << ans << endl;
}
```
