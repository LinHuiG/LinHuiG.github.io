{
  "title": "浮点数加减法过程模拟（C语言）",
  "date": "2019-04-29T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351610",
  "author": "LinHuiG",
  "categories": [
    "算法练习"
  ],
  "tags": [
    "二进制",
    "计算机",
    "调试"
  ],
  "draft": false,
  "original_date": "2019-04-29",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351610",
  "original_url": "https://blog.linhui.fun/article/9",
  "build": {
    "publishResources": false
  },
  "description": "浮点数加减法过程模拟（C语言）。旧文归档，原始发表于 2019-04-29。",
  "original_date_text": "2019-04-29",
  "original_sort_key": 20190429,
  "original_year": 2019,
  "date_precision": "day"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2019-04-29**；本站迁移：**2026-10-12**。正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351610) · [原个人博客地址](https://blog.linhui.fun/article/9)

## 浮点数加减法过程模拟（C语言）

###         过程在课本（计算机组成与系统结构第五版）51页，不介绍了，代码如下（自己敲的不知道好使不，试了几次感觉还行）。

代码如下：（float精度好低）

```cpp
#include<bits/stdc++.h>
using namespace std;
void print_bin(int n)//输出n（int型）的二进制表示，用于调试
{
    int l = sizeof(n)*8;//总位数。
    int i;
    if(i == 0)
    {
         printf("0");
         return;
     }
    for(i = l-1; i >= 0; i --)//略去高位0.
    {
        if(n&(1<<i)) break;
    }

    for(int k=1;k<32-i;k++)printf("0");
    for(;i>=0; i --)
        printf("%d", (n&(1<<i)) != 0);
    printf("\n");
}
bool check_0(int n)
{
    n&=0x7fffffff;//去符号
    if(n<<9)return 0;//尾数不为0
    return n>>23==0x0;//阶码为00000000
}
float calculate(float a,float b,char sign)//a sign b
{
    float ans_f=0;
    int &ans=*((int*)&ans_f);
    int &x=*((int*)&a);
    int &y=*((int*)&b);

    //如果是减法就把y的第一位取反
    if(sign=='-')
    {
        if(y&0x80000000)//如果y的第一位是1的话把它变0
        {
            y&=0x7fffffff;
        }
        else //把它变1
        {
            y|=0x80000000;
        }
    }


    //0操作数检查
    if(check_0(x))return b;
    if(check_0(y))return a;

    //对阶操作
    int x_j=(x&0x7fffffff)>>23;//取阶码
    int y_j=(y&0x7fffffff)>>23;

    int x_w=(x<<9)>>1;//取尾数
    x_w=x_w&0x7fffffff;
    x_w>>=8;
    int y_w=(y<<9)>>1;
    y_w=y_w&0x7fffffff;
    y_w>>=8;

    x_w|=0x800000;//对尾数加上前置的1.
    y_w|=0x800000;

    while(x_j<y_j)
    {
        ++x_j;
        x_w>>=1;
        if(x_w==0)return b;
    }

    while(x_j>y_j)
    {
        ++y_j;
        y_w>>=1;
        if(y_w==0)return a;
    }
    int ans_j=x_j;

    if(x&0x80000000)x_w=-x_w;//如果是负数，尾数取负
    if(y&0x80000000)y_w=-y_w;
    int ans_w=x_w+y_w;
    if(ans_w<0)//负数则ans取负
    {
        ans=1<<31;
        ans_w=-ans_w;
    }


    if(!ans_w)return 0;//如果ans为0，返回0

    while(ans_w>>24)//处理尾数上溢
    {
        ++ans_j;
        ans_w>>=1;
        if(ans_j>>8)
        {
            ans+=0x7fffffff;//阶码上溢，ans取最大值返回

            return ans_f;
        }
    }


    while(!(ans_w>>23))
    {
        --ans_j;
        ans_w<<=1;
        if(!ans_j)
        {
            ans=0;//阶码下溢，ans取0返回
            return ans_f;
        }
    }

    ans_w&=0xff7fffff;
    ans+=ans_w;
    ans+=ans_j<<23;

    return ans_f;
}
int main()
{
    float aa,bb;
    char cc;
    while(1)
    {
        cin>>aa>>cc>>bb;
        cout<<calculate(aa,bb,cc)<<endl;
    }
}
```
