{
  "title": "N皇后问题--bitset解的思路",
  "date": "2020-08-10T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351620",
  "author": "LinHuiG",
  "categories": [
    "算法练习"
  ],
  "tags": [
    "存储",
    "华为",
    "数组",
    "算法"
  ],
  "draft": false,
  "original_date": "2020-08-10",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351620",
  "original_url": "https://blog.linhui.fun/article/48",
  "build": {
    "publishResources": false
  },
  "description": "N皇后问题--bitset解的思路。旧文归档，原始发表于 2020-08-10。"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2020-08-10**；本站迁移：**2026-10-12**。原始日期依据腾讯云页尾记录，正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351620) · [原个人博客地址](https://blog.linhui.fun/article/48)

听说华为会让人在LeetCode上手撕代码，我就去那瞄了一眼，随手点到了N皇后问题~

这题目以前做过，不过今天突然想到了个新的思路，就是用位来存不可置放点，比如弄3个数z,y,isfill，初始状态都是0。

当我在第0行放一个点时，比如放在第2列，这三个数就和1&lt;&lt;2做或操作，变成了00100000....（左边为最小位）

当我在第1行的时候，z左移一位，y右移一位，变成z=010000000....，y=0001000000...，isfill不变，将它们三或一下，得到011100000.....这时候0的位子就可以放皇后，1的位置不能放直接剪枝~~所以第1 2 3列不能放，如果我们第1行放在第0列的话，

它们三就变成z=11000000....，y=1001000000...，isfill==10100000....，之后的操作就都一样了~

因为直接用int存的话n最大只能32位，所以我改成了数组，第j列就是\[j/32\]的j%32位，解决了存储的问题，算法就直接用回溯法就行了~~~

（LeetCode的输出好蠢啊....呐喊.jpg

代码如下：

```cpp
#include<iostream>
#include <string>
#include <vector>
#include <stack>
using namespace std;
class Solution {
public:
    int isfill[10], z[10], y[10];
    stack<int>xt;
    stack<int> tt;
    int count = 0;
    vector<vector<string>> ans;
    vector<vector<string>> solveNQueens(int n) {

        for (int i = 0; i < n; i++)
        {
            sol(0, i, n);
        }
        return ans;
    }
    int toz(int* a , int c, int n)
    {
        int ans = a[0] & 1;
        for (int i = 0; i <= n / 32; i++)
        {
            a[i] >>= 1;
            a[i] |= (a[i + 1] & 1) << 31;
        }
        if (c)
        {
            a[n / 32] |= 1 << (n % 32);
        }
        return ans;
    }
    int toy(int* a, int c, int n)
    {
        int t,ans;
        t = n % 32;
        ans = a[n / 32] & (1<<t);
        a[n / 32] -= ans;
        for (int i = 0; i <= n / 32; i++)
        {
            t = a[i] & (1 << 31);
            a[i] <<= 1;
            if (c)a[i] |= 1;
            c = t;
        }
        return ans;
    }
    bool sol(int i, int j, int n)
    {
        if (i >= n)
        {
            string str="";
            vector<string> vect;
            while (!xt.empty())
            {
                for (int c = 0; c < n; c++)
                {
                    if (c == xt.top())str .push_back('Q') ;
                    else str.push_back('.');
                }
                vect.push_back(str);
                str.clear();
                tt.push(xt.top());
                xt.pop();
            }
            ans.push_back(vect);
            count++;
            while (!tt.empty())
            {
                xt.push(tt.top());
                tt.pop();
            }
            return 1;
        }
        if (i == 0)
        {
            memset(isfill, 0, sizeof isfill);
            memset(z, 0, sizeof z);
            memset(y, 0, sizeof y);
            while (!xt.empty())xt.pop();
        }
        int t = isfill[j / 32] | z[j / 32] | y[j / 32];
        if (t & (1 << (j % 32)))
        {
            return 0;
        }
        t = 1 << (j % 32);
        isfill[j / 32] |= t;
        z[j / 32] |= t;
        y[j / 32] |= t;
        int tz = toz(z, 0, n);
        int ty = toy(y, 0, n);
        xt.push(j);
        for (int k = 0; k < n; k++)
        {
            sol(i + 1, k, n);
            if (i + 1 >= n)break;
        }
        toz(y, ty, n);
        toy(z, tz, n);
        isfill[j / 32] -= t;
        z[j / 32] -= t;
        y[j / 32] -= t;
        xt.pop();
        return 0;
    }
};
```
