{
  "title": "公共最长（连续）子串",
  "date": "2019-05-06T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351619",
  "author": "LinHuiG",
  "categories": [
    "算法练习"
  ],
  "tags": [
    "动态规划",
    "数组",
    "字符串"
  ],
  "draft": false,
  "original_date": "2019-05-06",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351619",
  "original_url": "https://blog.linhui.fun/article/10",
  "build": {
    "publishResources": false
  },
  "description": "公共最长（连续）子串。旧文归档，原始发表于 2019-05-06。"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2019-05-06**；本站迁移：**2026-10-12**。原始日期依据腾讯云页尾记录，正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351619) · [原个人博客地址](https://blog.linhui.fun/article/10)

## **公共最长（连续）子串**

### **   思路很简单，动态规划就行了，设dp\[i\]\[j\]为a串的0-i，b串的0-j的最长公共后缀长度。那么状态转移方程就是dp\[i\]\[j\]=a\[i\]==b\[i\]?dp\[i-1\]\[j-1\]:0**

###  **因为在i j为0时可能会出现dp\[-1\]\[-1\]的情况，所以把dp数组后推一位，且dp数组会用到的最多就是dp\[i-1\]\[j-1\],所以可以优化一下空间，把它变成一维数组从后往前dp，代码如下：**

```cpp
#include <bits/stdc++.h>
using namespace std;
char a[10000007],b[10000007];
int dp[10000007];
int main()
{
    while(1)
    {
        scanf("%s%s",a,b);
        int acd=strlen(a);//计算a和b字符串长度 
        int bcd=strlen(b);
        int maxn=0,jl;//maxn用来记录最长后缀，jl记录maxn出现时公共字符串位置。 
        memset(dp,0,(sizeof (int))*(bcd+1));//把dp置0，初始化。 
        for(int i=0;i<acd;i++)
        {
            for(int j=bcd-1;j>=0;j--)
            {
                dp[j+1]=a[i]==b[j]?dp[j]+1:0;//核心代码，状态转移。 
                if(maxn<dp[j+1])
                {
                    maxn=dp[j+1];//更新maxn与jl 
                    jl=i-maxn+1;
                }
            }
        }
        printf("%d\n",maxn);//输出 
        for(int i=jl;i<jl+maxn;i++)
        {
            printf("%c",a[i]);
        }
        printf("\n");
    }
}
```
