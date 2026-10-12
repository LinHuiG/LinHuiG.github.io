{
  "title": "MySql双机热备份",
  "date": "2020-02-10T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351627",
  "author": "LinHuiG",
  "categories": [
    "环境与运维"
  ],
  "tags": [
    "mysql",
    "备份",
    "数据",
    "域名",
    "主机"
  ],
  "draft": false,
  "original_date": "2020-02-10",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351627",
  "original_url": "https://blog.linhui.fun/article/20",
  "build": {
    "publishResources": false
  },
  "description": "MySql双机热备份。旧文归档，原始发表于 2020-02-10。",
  "original_date_text": "2020-02-10",
  "original_sort_key": 20200210,
  "original_year": 2020,
  "date_precision": "day"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2020-02-10**；本站迁移：**2026-10-12**。正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351627) · [原个人博客地址](https://blog.linhui.fun/article/20)

> **隐私处理：** 数据库名和服务地址已替换为示例值；原数据库状态截图改为脱敏文本。

在主从机上的配置文件中都修改\[mysqld\]下的内容  
 server-id = 1 （主1 从2）  
 log-bin = mysql-bin  
 binlog-do-db = example\_db   
 binlog-ignore-db = mysql 

重启主从机的mysql

主机用show master status；查询File和Position的数据记下；

在从机上输入如下指令

 change master to   
  master\_host='db.example.com',  (你的域名或者ip)  
  master\_user='root', (你的用户)  
  master\_password='\*\*\*\*\*\*\*', (你的密码)  
  master\_port=3306, (你的端口)  
  master\_log\_file='localhost-bin.000003', (刚刚记下的File)  
  master\_log\_pos=110983 ;(刚刚记下的Position)

括号（包括里面）全删掉

然后   
 start slave;                                                        
 show slave status\\G  

若是如下图有两个yes即可

```text
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
```

（迁移说明：原状态截图含具体库名，此处只保留正文需要说明的两个状态值。）

同步出现问题参考：[https://www.cnblogs.com/l-hh/p/9922548.html](<https://www.cnblogs.com/l-hh/p/9922548.html>)
