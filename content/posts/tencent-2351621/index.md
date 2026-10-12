{
  "title": "MySql创建新用户并授权",
  "date": "2020-04-30T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351621",
  "author": "LinHuiG",
  "categories": [
    "环境与运维"
  ],
  "tags": [
    "mysql",
    "权限"
  ],
  "draft": false,
  "original_date": "2020-04-30",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351621",
  "original_url": "https://blog.linhui.fun/article/34",
  "build": {
    "publishResources": false
  },
  "description": "MySql创建新用户并授权。旧文归档，原始发表于 2020-04-30。"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2020-04-30**；本站迁移：**2026-10-12**。原始日期依据腾讯云页尾记录，正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351621) · [原个人博客地址](https://blog.linhui.fun/article/34)

> **隐私处理：**示例中的个人化用户名和固定密码已替换为占位符。

创建用户：

```sql
create user 'demo_user'@'%' identified by 'REPLACE_WITH_STRONG_PASSWORD';
```

赋予权限`：`

```text
grant all privileges on xxxDB.* to 'demo_user'@'%' ;
```

删除用户：

```text
drop user 'demo_user'@'%' ;
```

操作后记得刷新权限表：

```sql
flush privileges;
```

查看用户信息`：`

```text
select distinct * from (select user.Host,user.User,db.Db,user.Password,user.Drop_priv,user.Grant_priv,user.Alter_priv from db inner JOIN user on db.user=user.user) as it where user='demo_user';
```
