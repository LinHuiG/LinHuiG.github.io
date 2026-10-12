{
  "title": "Java字节码深挖 第四站：JSR-269",
  "date": "2022-09-16T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351649",
  "author": "LinHuiG",
  "categories": [
    "Java实践"
  ],
  "tags": [
    "java",
    "编译",
    "语法",
    "源码",
    "注解"
  ],
  "draft": false,
  "original_date": "2022-09-16",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351649",
  "original_url": "https://blog.linhui.fun/article/69",
  "build": {
    "publishResources": false
  },
  "description": "Java字节码深挖 第四站：JSR-269。旧文归档，原始发表于 2022-09-16。",
  "original_date_text": "2022-09-16",
  "original_sort_key": 20220916,
  "original_year": 2022,
  "date_precision": "day"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2022-09-16**；本站迁移：**2026-10-12**。正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351649) · [原个人博客地址](https://blog.linhui.fun/article/69)

## 前言

本文参考了 [Java-JSR-269-插入式注解处理器](<https://liuyehcf.github.io/2018/02/02/Java-JSR-269-%E6%8F%92%E5%85%A5%E5%BC%8F%E6%B3%A8%E8%A7%A3%E5%A4%84%E7%90%86%E5%99%A8/>) ，**笔者也是根据该文入门，感谢大佬**。

本文是Java字节码深挖系列最后一章，被上海的疫情以及塔某些不可描述的操作搞的没心情写文，所以鸽了这么久~

我用这个东西做了个序列化框架，性能比protobuf强20%左右，易用性比protobuf高很多（传输类打个注解就完事了，写什么乱七八糟的文件），原理很简单，想看的直接拉到尾部。

### 编译原理

前面讲到的Javassist，cglib等等，虽然确实操作了字节码，但还是运行时生成，未涉及编译的过程，而JSR-269标准允许我们在**编译过程中对字节码进行操作**。如果学过编译原理的都知道，编译的过程一般包括：词法分析，语法分析，语义分析，中间代码生成，中间代码优化，目标代码生成，目标代码优化。而具体到Java语言，Javac的编译过程是：准备环境，词法分析，语法分析，填充符号表，**注解处理**，语义分析，标记检查，数据流分析，解语法糖，字节码生成

在这个过程中，我们着重关注注解处理这一步，java源代码经过词法分析和语法分析之后会生成**抽象语法树**，编译器后续的操作都在该语法树上进行，不会再对源代码（字符串）进行操作。注解处理这一步也是在抽象语法树上进行的，填充符号表过程的出口是一个待处理列表（To Do List），包含了每一个编译单元的抽象语法树的顶级节点。完成抽象语法树的构建并填充符号表之后，编译器将会开始进行注解处理，**jdk1.6实现了JSR-269规范，并提供了标准的Pluggable Annotations Processing API（插入式注解处理API）**，我们根据这套API，就可以进行插入式注解处理器的开发了，我们可以把注解器简单的理解为编译器的插件。

**现在，我们可以干涉java编译器的编译过程了，抽象语法树中包含了原始代码的一切（甚至包括代码注释），而我们通过这套API又可以修改语法树所以只要有足够的创意，我们可以做非常多的事情。**

### 开发流程

我们开发插入式注解器可以这么做，首先编写注解器代码，注解器类上应该带上@**SupportedSourceVersion**和@**SupportedAnnotationTypes**注解表示该注解器作用于哪个版本的java源码，以及作用于哪个注解。注解器还应该继承**AbstractProcessor**类接口，并重写**public boolean process(Set&lt;? extends TypeElement&gt; annotations, RoundEnvironment roundEnv)**方法，在该方法中使用访问者模式对语法树进行调整。编写完成后，我们应该编写配置文件，当然，谷歌的com.google.auto.service.AutoService注解可以帮助我们不用编写该文件（直接将该注解写在注解器上即可），而后编译打包注解器。之后，我们就可以在新的代码项目中使用该注解器，只需要引入注解器所在的包后进行编译即可（笔者工作中使用的是maven，可以傻瓜式调用，甚至可以对注解器进行debug）。我们可以使用**mvnDebug**命令对注解器进行bug，debug具体使用方式这里不展开了。

接下来说说注解器的一些api，抄自 [Java-JSR-269-插入式注解处理器](<https://liuyehcf.github.io/2018/02/02/Java-JSR-269-%E6%8F%92%E5%85%A5%E5%BC%8F%E6%B3%A8%E8%A7%A3%E5%A4%84%E7%90%86%E5%99%A8/>) ：

## 3 编译相关的数据结构与API

### 3.1 JCTree

JCTree是语法树元素的基类，**包含一个重要的字段**`pos`**，该字段用于指明当前语法树节点（JCTree）在语法树中的位置**，因此我们不能直接用new关键字来创建语法树节点，即使创建了也没有意义。此外，**结合访问者模式，将数据结构与数据的处理进行解耦**，部分源码如下：

```java
public abstract class JCTree implements Tree, Cloneable, DiagnosticPosition {

    public int pos = -1;

    ...

    public abstract void accept(JCTree.Visitor visitor);

    ...
}
```

这里重点介绍几个JCTree的子类，下面的Demo会用到

1. JCStatement：`声明`语法树节点，常见的子类如下            

  - JCBlock：`语句块`语法树节点

  - JCReturn：`return语句`语法树节点

  - JCClassDecl：`类定义`语法树节点

  - JCVariableDecl：`字段/变量定义`语法树节点

1. JCMethodDecl：`方法定义`语法树节点

1. JCModifiers：`访问标志`语法树节点

1. JCExpression：`表达式`语法树节点，常见的子类如下            

  - JCAssign：`赋值语句`语法树节点

  - JCIdent：`标识符`语法树节点，**可以是变量，类型，关键字等等**

### 3.2 TreeMaker

TreeMaker用于创建一系列`语法树节点`，**创建时会为创建出来的JCTree设置pos字段，所以必须用上下文相关的TreeMaker对象来创建语法树节点，而不能直接new语法树节点**

源码可以参考[TreeMaker DOC](<http://www.docjar.com/docs/api/com/sun/tools/javac/tree/TreeMaker.html>)

#### 3.2.1 TreeMaker.Modifiers

TreeMaker.Modifiers方法用于创建`访问标志`语法树节点(JCModifiers)，源码如下：

1. flags：访问标志

1. annotations：注解列表

```java
public JCModifiers Modifiers(long flags) {
    return Modifiers(flags, List.< JCAnnotation >nil());
}

public JCModifiers Modifiers(long flags,
    List<JCAnnotation> annotations) {
        JCModifiers tree = new JCModifiers(flags, annotations);
        boolean noFlags = (flags & (Flags.ModifierFlags | Flags.ANNOTATION)) == 0;
        tree.pos = (noFlags && annotations.isEmpty()) ? Position.NOPOS : pos;
        return tree;
}
```

其中入参`flags`可以用枚举类型`com.sun.tools.javac.code.Flags`，且支持拼接（枚举值经过精心设计）

例如，我们可以这样用

```text
treeMaker.Modifiers(Flags.PUBLIC + Flags.STATIC + Flags.FINAL);
```

#### 3.2.2 TreeMaker.ClassDef

TreeMaker.ClassDef用于创建`类定义`语法树节点(JCClassDecl)，源码如下：

1. mods：访问标志

1. name：类名

1. typarams：泛型参数列表

1. extending：父类

1. implementing：接口列表

1. defs：类定义的详细语句，包括字段，方法定义等等

```java
public JCClassDecl ClassDef(JCModifiers mods,
    Name name,
    List<JCTypeParameter> typarams,
    JCExpression extending,
    List<JCExpression> implementing,
    List<JCTree> defs) {
        JCClassDecl tree = new JCClassDecl(mods,
                                     name,
                                     typarams,
                                     extending,
                                     implementing,
                                     defs,
                                     null);
        tree.pos = pos;
        return tree;
}
```

#### 3.2.3 TreeMaker.MethodDef

TreeMaker.MethodDef用于创建`方法定义`语法树节点（JCMethodDecl），源码如下：

1. mods：访问标志

1. name：方法名

1. restype：返回类型

1. typarams：泛型参数列表

1. params：参数列表

1. thrown：异常声明列表

1. body：方法体

1. defaultValue：默认方法（可能是interface中的那个default）

1. m：方法符号

1. mtype：方法类型。包含多种类型，泛型参数类型、方法参数类型，异常参数类型、返回参数类型

```java
public JCMethodDecl MethodDef(JCModifiers mods,
    Name name,
    JCExpression restype,
    List<JCTypeParameter> typarams,
    List<JCVariableDecl> params,
    List<JCExpression> thrown,
    JCBlock body,
    JCExpression defaultValue) {
        JCMethodDecl tree = new JCMethodDecl(mods,
                                       name,
                                       restype,
                                       typarams,
                                       params,
                                       thrown,
                                       body,
                                       defaultValue,
                                       null);
        tree.pos = pos;
        return tree;
}

public JCMethodDecl MethodDef(MethodSymbol m,
    Type mtype,
    JCBlock body) {
        return (JCMethodDecl)
            new JCMethodDecl(
                Modifiers(m.flags(), Annotations(m.getAnnotationMirrors())),
                m.name,
                Type(mtype.getReturnType()),
                TypeParams(mtype.getTypeArguments()),
                Params(mtype.getParameterTypes(), m),
                Types(mtype.getThrownTypes()),
                body,
                null,
                m).setPos(pos).setType(mtype);
}
```

**其中，返回类型填**`null`**或者**`treeMaker.TypeIdent(TypeTag.VOID)`**都代表返回void类型**

#### 3.2.4 TreeMaker.VarDef

TreeMaker.VarDef用于创建`字段/变量定义`语法树节点（JCVariableDecl），源码如下：

1. mods：访问标志

1. vartype：类型

1. init：初始化语句

1. v：变量符号

```java
public JCVariableDecl VarDef(JCModifiers mods,
    Name name,
    JCExpression vartype,
    JCExpression init) {
        JCVariableDecl tree = new JCVariableDecl(mods, name, vartype, init, null);
        tree.pos = pos;
        return tree;
}

public JCVariableDecl VarDef(VarSymbol v,
    JCExpression init) {
        return (JCVariableDecl)
            new JCVariableDecl(
                Modifiers(v.flags(), Annotations(v.getAnnotationMirrors())),
                v.name,
                Type(v.type),
                init,
                v).setPos(pos).setType(v.type);
}
```

####  

3.2.5 TreeMaker.Ident

TreeMaker.Ident用于创建`标识符`语法树节点（JCIdent），源码如下：

```java
public JCIdent Ident(Name name) {
        JCIdent tree = new JCIdent(name, null);
        tree.pos = pos;
        return tree;
}

public JCIdent Ident(Symbol sym) {
        return (JCIdent)new JCIdent((sym.name != names.empty)
                                ? sym.name
                                : sym.flatName(), sym)
            .setPos(pos)
            .setType(sym.type);
}

public JCExpression Ident(JCVariableDecl param) {
        return Ident(param.sym);
}
```

#### 3.2.6 TreeMaker.Return

TreeMaker.Return用于创建`return语句`语法树节点（JCReturn），源码如下：

```java
public JCReturn Return(JCExpression expr) {
        JCReturn tree = new JCReturn(expr);
        tree.pos = pos;
        return tree;
}
```

####  

#### 3.2.7 TreeMaker.Select

TreeMaker.Select用于创建`域访问/方法访问`（这里的方法访问只是取到名字，方法的调用需要用TreeMaker.Apply）语法树节点（JCFieldAccess），源码如下：

1. selected：`.`运算符左边的表达式

1. selector：`.`运算符右边的名字

```java
public JCFieldAccess Select(JCExpression selected,
    Name selector) 
{
        JCFieldAccess tree = new JCFieldAccess(selected, selector, null);
        tree.pos = pos;
        return tree;
}

public JCExpression Select(JCExpression base,
    Symbol sym) {
        return new JCFieldAccess(base, sym.name, sym).setPos(pos).setType(sym.type);
}
```

#### 3.2.8 TreeMaker.NewClass

TreeMaker.NewClass用于创建`new语句`语法树节点（JCNewClass），源码如下：

1. encl：不太明白此参数含义

1. typeargs：参数类型列表

1. clazz：待创建对象的类型

1. args：参数列表

1. def：类定义

```java
public JCNewClass NewClass(JCExpression encl,
    List<JCExpression> typeargs,
    JCExpression clazz,
    List<JCExpression> args,
    JCClassDecl def) {
        JCNewClass tree = new JCNewClass(encl, typeargs, clazz, args, def);
        tree.pos = pos;
        return tree;
}
```

####  

#### 3.2.9 TreeMaker.Apply

TreeMaker.Apply用于创建`方法调用`语法树节点（JCMethodInvocation），源码如下：

1. typeargs：参数类型列表

1. fn：调用语句

1. args：参数列表

```java
public JCMethodInvocation Apply(List<JCExpression> typeargs,
    JCExpression fn,
    List<JCExpression> args) {
        JCMethodInvocation tree = new JCMethodInvocation(typeargs, fn, args);
        tree.pos = pos;
        return tree;
}
```

####  

#### 3.2.10 TreeMaker.Assign

TreeMaker.Assign用于创建`赋值语句`语法树节点（JCAssign），源码如下：

1. lhs：赋值语句左边表达式

1. rhs：赋值语句右边表达式

```java
public JCAssign Assign(JCExpression lhs,
    JCExpression rhs) {
        JCAssign tree = new JCAssign(lhs, rhs);
        tree.pos = pos;
        return tree;
}
```

#### 3.2.11 TreeMaker.Exec

TreeMaker.Exec用于创建`可执行语句`语法树节点（JCExpressionStatement），源码如下：

```java
public JCExpressionStatement Exec(JCExpression expr) {
        JCExpressionStatement tree = new JCExpressionStatement(expr);
        tree.pos = pos;
        return tree;
}
```

**例如，TreeMaker.Apply以及TreeMaker.Assign就需要外面包一层TreeMaker.Exec来获得一个JCExpressionStatement**

####  

#### 3.2.12 TreeMaker.Block

TreeMaker.Block用于创建`组合语句`语法树节点（JCBlock），源码如下：

1. flags：访问标志

1. stats：语句列表

```java
public JCBlock Block(long flags,
    List<JCStatement> stats) {
        JCBlock tree = new JCBlock(flags, stats);
        tree.pos = pos;
        return tree;
}
```

###  

### 3.3 com.sun.tools.javac.util.List

上述JSR-269 API中会涉及到一个List，这个List不是java.util.List，它是com.sun.tools.javac.util.List，这个List的操作比较奇特，不支持链式操作。下面给出部分源码，List包含两个字段，head和tail，其中head只是一个节点，而tail是一个List

```java
public class List<A> extends AbstractCollection<A> implements java.util.List<A> {
    public A head;
    public List<A> tail;
    private static final List<?> EMPTY_LIST = new List<Object>((Object)null, (List)null) {
        public List<Object> setTail(List<Object> var1) {
            throw new UnsupportedOperationException();
        }

        public boolean isEmpty() {
            return true;
        }
    };

    List(A head, List<A> tail) {
        this.tail = tail;
        this.head = head;
    }

    public static <A> List<A> nil() {
        return EMPTY_LIST;
    }

    public List<A> prepend(A var1) {
        return new List(var1, this);
    }

    public List<A> append(A var1) {
        return of(var1).prependList(this);
    }

    public static <A> List<A> of(A var0) {
        return new List(var0, nil());
    }

    public static <A> List<A> of(A var0, A var1) {
        return new List(var0, of(var1));
    }

    public static <A> List<A> of(A var0, A var1, A var2) {
        return new List(var0, of(var1, var2));
    }

    public static <A> List<A> of(A var0, A var1, A var2, A... var3) {
        return new List(var0, new List(var1, new List(var2, from(var3))));
    }

    ...
}
```

###  

### 3.4 com.sun.tools.javac.util.ListBuffer

由于com.sun.tools.javac.util.List用起来不是很方便，而ListBuffer的行为与java.util.List的行为类似，并且提供了转换成com.sun.tools.javac.util.List的方法

```text
ListBuffer<JCTree.JCStatement> jcStatements = new ListBuffer<>();

//添加语句 " this.xxx = xxx; "
jcStatements.append(...);

//添加Builder模式中的返回语句 " return this; "
jcStatements.append(...);

List<JCTree.JCStatement> lst = jcStatements.toList();
```

###  

### 3.5 tricky

#### 3.5.1 创建一个构造方法

**注意点：方法的名字就是**`<init>`

```text
treeMaker.MethodDef(
        treeMaker.Modifiers(Flags.PUBLIC), //访问标志
        names.fromString("<init>"), //名字
        treeMaker.TypeIdent(TypeTag.VOID), //返回类型
        List.nil(), //泛型形参列表
        List.nil(), //参数列表
        List.nil(), //异常列表
        jcBlock, //方法体
        null //默认方法（可能是interface中的那个default）
);
```

####  

#### 3.5.2 创建一个方法的参数

**注意点：访问标志设置成**`Flags.PARAMETER`

```text
treeMaker.VarDef(
        treeMaker.Modifiers(Flags.PARAMETER), //访问标志。极其坑爹！！！
        prototypeJCVariable.name, //名字
        prototypeJCVariable.vartype, //类型
        null //初始化语句
);
```

#### 3.5.3 创建一条赋值语句

```text
treeMaker.Exec(
        treeMaker.Assign(
                treeMaker.Select(
                        treeMaker.Ident(names.fromString(THIS)),
                        jcVariable.name
                ),
                treeMaker.Ident(jcVariable.name)
        )
)
```

#### 3.5.4 创建一条new语句

```text
treeMaker.NewClass(
        null, //尚不清楚含义
        List.nil(), //泛型参数列表
        treeMaker.Ident(builderClassName), //创建的类名
        List.nil(), //参数列表
        null //类定义，估计是用于创建匿名内部类
)
```

#### 3.5.5 创建一条方法调用语句

```text
treeMaker.Exec(
        treeMaker.Apply(
                List.nil(),
                treeMaker.Select(
                        treeMaker.Ident(getNameFromString(IDENTIFIER_DATA)),
                        jcMethodDecl.getName()
                ),
                List.of(treeMaker.Ident(jcVariableDecl.getName())) //传入的参数集合
        )
)
```

####  **提示**：我们开发后使用的时候，编译可能会报一些错误（我忘记了），比如树节点pos不对之类的，这是因为treeMaker默认的pos是-1，我们只需要在treeMaker使用之前加入如下代码即可：

```text
this.treeMaker.at(jcClass.pos);
```

### 工程应用-高性能序列化框架（只讲思路）

我们先来想一想，什么样的序列化代码性能最高？比如我们要传输int a=1,boolean b=false,long c=10,String d="123";这些数据

把他们序列化成二进制流最高性能的方案是不是类似这种写法

```text
  ByteBuffer byteBuffer=ByteBuffer.allocate(13)
                .order(ByteOrder.LITTLE_ENDIAN);
        byteBuffer.putInt(a);
        byteBuffer.put(b);
        byteBuffer.putLong(c);
        return byteBuffer.array();
```

那如果有一百个接口，每个接口有一百个字段呢？一个个写可能要熬出一个大秃头。

现在我们有了JSR-269，我们完全可以把这个事情交给编译器去做，在需要序列化的类上加上注解，然后让注解器去生成该类的序列化和反序列化代码。

对于**父类的序列化**支持也很简单，在需要支持父类的序列化函数第一行将super的该方法写入即可。

同理，对**复杂对象的序列化**（成员变量也为对象）也可以在该行调用改成员变量的序列化函数，（注：为了节约空间和性能，我们应该将buffer对象传入函数对buffer对象读写，而不是将该对象序列化好的字节数组返回后再写入buffer对象）。

以上方案对于有**递归**思维的程序员应该很好理解。

对于**泛型**的支持则稍微困难了一些，我们都知道java编译时候的泛型擦除是一个**假擦除**，实际上还是在类的字节码中，擦了个寂寞，所以我们反射的时候实际上是可以获取父类的泛型信息--clz.getGenericSuperclass().getActualTypeArguments()\[index\]。

但是我们编译的时候跨语法树去另一个类中获取这些信息还是比较麻烦的，所以这步我使用了**反射+缓存（当前类+父类+泛型下标作为key）**进行处理，实测对性能几乎没有影响。

不过对于当前类的泛型支持目前还做不太到，有思路的小伙伴可以一起交流一下~。

目前测试下来性能大约超过protobuf **20%** ，2.0将会结合（绑定）netty的**零拷贝技术**，这样在netty的使用场景下性能应该还能再进一步提高（提高很多，不论是空间占用还是耗时）。

当然，这样还有一个小问题，就是**idea无法识别**你在编译后才会出现的函数，所以调用的时候会爆红，编译倒是正常。对于这个问题，我模仿lombok写了一个**idea的插件**，使用该插件后idea就可以正确识别相关函数了。关于idea插件的开发，有空了我专门找个时间写一篇~
