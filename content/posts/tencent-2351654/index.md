{
  "title": "Java字节码深挖 第三站：Javassist",
  "date": "2022-05-05T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351654",
  "author": "LinHuiG",
  "categories": [
    "Java实践"
  ],
  "tags": [
    "java",
    "接口"
  ],
  "draft": false,
  "original_date": "2022-05-05",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351654",
  "original_url": "https://blog.linhui.fun/article/66",
  "build": {
    "publishResources": false
  },
  "description": "Java字节码深挖 第三站：Javassist。旧文归档，原始发表于 2022-05-05。"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2022-05-05**；本站迁移：**2026-10-12**。原始日期依据腾讯云页尾记录，正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351654) · [原个人博客地址](https://blog.linhui.fun/article/66)

javassist是真正的可以对class为所欲为，甚至可以生成真正的class文件，它将字节码操作过程全部封装了起来，我们可以直接使用符合java规范的String直接修改，做到了动态修改代码跟修改字符串一样方便。并且，javassist的接口也简洁明了，操作难度跟反射没什么区别，我就不赘述了，具体接口看下面样例代码。（目前还没用javassist做出过啥好玩的东西，主要javassist是动态修改class，用起来隐隐约约感觉有点不安，而且目前项目生产方面好像还没有这方面的需求。。）

预告：下一节我会说说JSR-269，编译时修改语法树，按照我们的规则生成想要的字节码。

```java
        //获取类池
        ClassPool cp = ClassPool.getDefault();
        //获取类
        CtClass cc = cp.get("learning.ATest");
        //获取对象
        CtMethod m = cc.getDeclaredMethod("print");

        //修改方法体
        m.setBody("{ System.out.println(\"running\"); }");
        //方法前插入
        m.insertBefore("{ System.out.println(\"start\"); }");
        //方法后
        m.insertAfter("{ System.out.println(\"end\"); }");

        //获取所有成员变量
        CtField[] f=cc.getDeclaredFields();
        for (CtField ctField : f) {
            //设置get方法
            String methodStrF ="public %s get%s(){"
                    +" return %s;"
                    +"}";
            String methodStr=String.format(methodStrF,ctField.getType().getSimpleName(),captureName(ctField.getName()),ctField.getName());
            CtMethod newMethod = CtNewMethod.make(methodStr, cc);
            cc.addMethod(newMethod);


            //设置set方法
            methodStrF ="public void set%s(%s %s){"
                    +" this.%s=%s;"
                    +"}";
            methodStr=String.format(methodStrF,captureName(ctField.getName()),ctField.getType().getSimpleName(),ctField.getName(),ctField.getName(),ctField.getName());
            newMethod = CtNewMethod.make(methodStr, cc);
            cc.addMethod(newMethod);

        }

        Class c = cc.toClass();
        //生成class文件
        cc.writeFile();
        ATest h = (ATest)c.newInstance();
        h.print();
```

 原ATest.java文件：

```java
public class ATest  implements Serializable {
    private static final long serialVersionUID = 140932343675039705L;
    private double aaa;
    private double ddd;
    private Double ccc;
    public void print(){
        System.out.println("run...");
    }
    public void testRe(){
        this.ddd=10;
        this.aaa=60;
        this.ccc=null;
    }
    private Object readResolve() {
        System.out.println("readResolve exec...");
        return this;
    }
    public void t(double a){}
    public void t(Double a){}
}
```

 生成的ATest.class文件：

```java
//
// Source code recreated from a .class file by IntelliJ IDEA
// (powered by FernFlower decompiler)
//

package learning;

import java.io.Serializable;

public class ATest implements Serializable {
    private static final long serialVersionUID = 140932343675039705L;
    private double aaa;
    private double ddd;
    private Double ccc;

    public ATest() {
    }

    public void print() {
        System.out.println("start");
        System.out.println("running");
        Object var2 = null;
        System.out.println("end");
    }

    public void testRe() {
        this.ddd = 10.0D;
        this.aaa = 60.0D;
        this.ccc = null;
    }

    private Object readResolve() {
        System.out.println("readResolve exec...");
        return this;
    }

    public void t(double a) {
    }

    public void t(Double a) {
    }

    public long getSerialVersionUID() {
        return 140932343675039705L;
    }

    public void setSerialVersionUID(long var1) {
        serialVersionUID = var1;
    }

    public double getAaa() {
        return this.aaa;
    }

    public void setAaa(double var1) {
        this.aaa = var1;
    }

    public double getDdd() {
        return this.ddd;
    }

    public void setDdd(double var1) {
        this.ddd = var1;
    }

    public Double getCcc() {
        return this.ccc;
    }

    public void setCcc(Double var1) {
        this.ccc = var1;
    }
}
```
