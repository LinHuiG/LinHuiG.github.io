{
  "title": "带括号计算器----Java实现",
  "date": "2020-02-20T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351625",
  "author": "LinHuiG",
  "categories": [
    "Java实践"
  ],
  "tags": [
    "java",
    "bigdecimal"
  ],
  "draft": false,
  "original_date": "2020-02-20",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351625",
  "original_url": "https://blog.linhui.fun/article/24",
  "build": {
    "publishResources": false
  },
  "description": "带括号计算器----Java实现。旧文归档，原始发表于 2020-02-20。",
  "original_date_text": "2020-02-20",
  "original_sort_key": 20200220,
  "original_year": 2020,
  "date_precision": "day"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2020-02-20**；本站迁移：**2026-10-12**。正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351625) · [原个人博客地址](https://blog.linhui.fun/article/24)

大一时候写过不科学计算器，那时候碰到好多问题都是头铁莽上去，加特判就完事了，导致屁大点功能写了几百行代码，一点也不优雅（雾）。

今天晚上闲来无事就把那份代码重写了一下，用算数栈的方法，顺便把double改成了大数BigDecimal，妈妈再也不用怕我溢出了~~

具体代码在gitee上 ：[https://gitee.com/mofanyunxiang/calculator](<https://gitee.com/mofanyunxiang/calculator>)

核心代码不多，都在下面了：

```text
for(int i=0;i<s.length();i++)
        {
            char si=s.charAt(i);
            if(si==')')
            {
                char tc='\0';
                while(!cstack.empty())//将括号内部的东西算完，直到碰到左括号后匹配
                {
                    tc=cstack.pop().toString().charAt(0);
                    if(tc=='(')break;
                    BigDecimal n2=nstack.pop();
                    BigDecimal n1=nstack.pop();
                    n1=add(n1,n2,tc);
                    if(n1==null)return "null";
                    nstack.push(n1);
                }
                if(tc!='(')return "Bracket mismatch";
                //括号不匹配，如果缺右括号的话，默认自动在算式尾部添加，缺左括号则报错
                continue;
            }
            ndj=dj;
            dj=zh(si);
            if(dj==-1||((ndj!=-1&&si=='-')))//数字为-1，或者带负号的数字，负号和减号判断规则见上
            {
                int be=i++;
                while(i<s.length()&&zh(s.charAt(i))<0)i++;
                BigDecimal n1=new BigDecimal(s.substring(be,i));
                i--;
                nstack.push(n1);
                continue;
            }
            if(dj==0)//左括号
            {
                cstack.push(si);
                continue;
            }
            if(dj>=1)//算符计算
            {
                if(cstack.empty())
                {
                    cstack.push(si);
                    continue;
                }
                char tc=cstack.peek().toString().charAt(0);
                while(zh(tc)>=dj)//入栈时如果本算符优先级小于等于栈顶算符，则先计算栈顶算符
                {
                    BigDecimal n2=nstack.pop();
                    BigDecimal n1=nstack.pop();
                    cstack.pop();
                    n1=add(n1,n2,tc);
                    if(n1==null)return "null";
                    nstack.push(n1);
                    if(!cstack.empty())tc=cstack.peek().toString().charAt(0);
                    else tc='0';
                }
                cstack.push(si);//算符入栈
            }

        }
        /**
         * 算式栈全部计算，此时优先级就是出栈顺序，直接计算即可。
         */
        while(!cstack.empty())
        {
            char tc=cstack.pop().toString().charAt(0);
            if(tc=='(')continue;
            BigDecimal n2=nstack.pop();
            BigDecimal n1=nstack.pop();
            n1=add(n1,n2,tc);
            if(n1==null)return "null";
            nstack.push(n1);
        }
        s=nstack.pop().toString();
```
