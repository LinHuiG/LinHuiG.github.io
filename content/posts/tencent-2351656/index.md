{
  "title": "记阿里笔试编程题目（JAVA研发）",
  "date": "2020-07-28T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351656",
  "author": "LinHuiG",
  "categories": [
    "算法练习"
  ],
  "tags": [
    "java",
    "编程",
    "遍历",
    "研发"
  ],
  "draft": false,
  "original_date": "2020-07-28",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351656",
  "original_url": "https://blog.linhui.fun/article/47",
  "build": {
    "publishResources": false
  },
  "description": "记阿里笔试编程题目（JAVA研发）。旧文归档，原始发表于 2020-07-28。",
  "original_date_text": "2020-07-28",
  "original_sort_key": 20200728,
  "original_year": 2020,
  "date_precision": "day"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2020-07-28**；本站迁移：**2026-10-12**。正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351656) · [原个人博客地址](https://blog.linhui.fun/article/47)

### 昨天晚上在线笔试了一下阿里巴巴JAVA研发岗的校招编程题，难度倒是不大，不过快两年没刷算法题的我差点没做完~~今天写个博客记录一下。

### **一共两道题，第一题题面大概是给一串单调递增数字，问如果a和b两个人轮流选择其中的一个数字，被选中的数字中最左边的那个和小于这个数字的数字全部删掉（比如\[2 2 2 3 3 5\]，若是选中了3 ，那么剩下数组为\[3 5\]），假设两人都很聪明问谁会获胜？**

### **解**：这题难度不大，我们可以发现只要某个数字的数量为奇数个，那么先手胜利，否则后手胜利，读入遍历一遍就a了，本题就不给代码了。。

### **第二题稍微难点，题面是一个装小气鬼送礼物，他有一个架子，有n排礼物（每个礼物有自己的权值c，c越大礼物越贵），他要送m个礼物出去，但是他又不想送最贵的m个又想装大方，所以他给自己立了个规矩，每次选礼物都只能从任意一排的两端选择，问他最贵能送多少权值出去？**

### **输入格式**：第一行输入n，m ，下面n行每行输入一个x代表这一行有x个礼物，后面跟x个数字，每个数字代表这个位置的礼物的权值。

### **输出**：一个数字，代表最贵的权值。

### **解**：这题需要转换一下，首先先把b\[n\]\[m\]算出来，b\[i\]\[j\]代表第i行选择j个礼物的最高权值。这里可以稍微做个优化，每个c\[i\]\[j\]读入的时候都加上c\[i\]\[j-1\]（我把c\[i\]\[0\]用来存x了，所以j=1时候特判一下不加），c\[i\]\[j\]就成了第i行前j个礼物的总权值，这时候算b\[i\]\[j\]就简单一些了，遍历z&lt;=j，让y=j-z，c\[i\]\[j\]=max（c\[i\]\[z\] + c\[i\]\[zs\] - c\[i\]\[zs - y\]）,zs表示本行礼物数量，j&gt;zs的时候开始算下一行。

### b\[n\]\[m\]算好后，就可以开始用动态规划算答案了，转移方程dp\[i\]\[j\]=max（dp\[i-1\]\[j-bc\] + b\[i\]\[bc\] , 0&lt;bc&lt;=j），由于本题的m比较大，不知道会不会mle，所以我这边把它优化成一维dp了，之后遍历一遍找到最大值就行了。

### 代码如下：

```cpp
#include <iostream>
#include<stdio.h>
int c[105][105];
int b[105][105];
int dp[10005];
int dpa[10005];
int main()
{
	int n, m, x,ans;
	scanf("%d%d", &n, &m);
	for (int i = 0; i < n; i++)
	{
		scanf("%d", &c[i][0]);
		for (int j = 1; j <= c[i][0]; j++)
		{
			scanf("%d", &x);
			c[i][j] = x;
			if (j > 1)c[i][j] += c[i][j - 1];
		}
	}
	for (int i = 0; i < n; i++)
	{
		int zs = c[i][0];
		for (int j = 1; j <= zs; j++)
		{
			for (int z = 0; z <= j; z++)
			{
				int y = j - z;
				if(z!=0)ans = c[i][z] + c[i][zs] - c[i][zs - y];
				else ans = c[i][zs] - c[i][zs - y];
				b[i][j] = b[i][j] > ans ? b[i][j] : ans;
			}
		}

	}
	for (int i = 0; i < n; i++)
	{
		ans = 0;
		for (int j = 0; j <= m; j++)
		{
			for (int bc = 0; bc <= j; bc++)
			{
				int temp = dp[j-bc] + b[i][bc];
				if (temp > ans)ans = temp;
			}
			dpa[j] = ans;

		}
		for (int j = 1; j <= m; j++)dp[j] = dpa[j];
	}
	ans = 0;
	for (int i = 0; i <= m; i++)ans = ans > dp[i] ? ans : dp[i];
	printf("%d\n", ans);
}
```
