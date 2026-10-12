{
  "title": "Java字节码深挖 第二站：CGLIB",
  "date": "2022-05-05T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351653",
  "author": "LinHuiG",
  "categories": [
    "Java实践"
  ],
  "tags": [
    "java",
    "代理",
    "对象",
    "接口",
    "注解"
  ],
  "draft": false,
  "original_date": "2022-05-05",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351653",
  "original_url": "https://blog.linhui.fun/article/65",
  "build": {
    "publishResources": false
  },
  "description": "Java字节码深挖 第二站：CGLIB。旧文归档，原始发表于 2022-05-05。",
  "original_date_text": "2022-05-05",
  "original_sort_key": 20220505,
  "original_year": 2022,
  "date_precision": "day"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2022-05-05**；本站迁移：**2026-10-12**。正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351653) · [原个人博客地址](https://blog.linhui.fun/article/65)

不同于jdk自带的动态代理只能针对接口生成代理类，cglib可以对类实现代理，实现也非常的傻瓜式，我们只需要实现net.sf.cglib.proxy.MethodInterceptor接口，使用方法与jdk自带的动态代理类似。

net.sf.cglib.proxy.MethodInterceptor接口中只有一个待实现的方法：

```java
public Object intercept(Object obj, java.lang.reflect.Method method, Object[] args,
                               MethodProxy proxy) throws Throwable;
```

其中第一个参数便是被调用的对象本身，第二个参数是被调用的方法，第三个参数是被调用的参数，第四个参数是被代理的方法，其中第一个和第三个参数比较好理解，method和proxy可能造成歧义，我这里解释一下，method是当前对象的方法，调用这个方法会再次进入intercept回调，而proxyMethod是被代理的方法，调用proxyMethod.invokeSuper(Object obj, Object\[\] args)方法即可调用原始的方法。

实现了本接口后，我们便可以使用 Enhancer类生成clz类增强后的代理实例了

```text
        Enhancer enhancer = new Enhancer();
        //设置代理目标
        enhancer.setSuperclass(clz);
        //设置单一回调对象，在调用中拦截对目标方法的调用
        enhancer.setCallback(methodInterceptor);
        //设置类加载器
        enhancer.setClassLoader(clz.getClassLoader());
        Object obj=enhancer.create();
```

关于应用，我使用cglib实现了参数校验框架，实现逻辑如下：

    1.我们可以设置校验规则注解，将其注在需要被校验的成员变量上，该注解内部需要实现Validate接口方法，并将该类设为默认validate值。

    2.递归检查注解@RecursionCheck，将其注在同样需要校验的对象成员变量上。

    3.关联注解@Relevancy(String\[\])，将其注在可能改变成员变量值的方法上，注解参数为字符串数组，需要把可能被改变值的成员变量名称写入。

核心实现逻辑如下：

    1.net.sf.cglib.proxy.MethodInterceptor接口实现：

```java
public class ValCheckInterceptor implements MethodInterceptor {
    public static MethodInterceptor I = new ValCheckInterceptor();
    private static final Map<Class<?>, Map<Method, Set<Field>>> classMap = new ConcurrentHashMap<>();

    @Override
    public Object intercept(Object o, Method method, Object[] objects, MethodProxy methodProxy) throws Throwable {
        Class<?> clz = o.getClass().getSuperclass();
        classMap.computeIfAbsent(clz, this::initClassCheckMethod);
        Object result = methodProxy.invokeSuper(o, objects);
        Map<Method, Set<Field>> methodFieldMap = classMap.get(o.getClass().getSuperclass());
        if (methodFieldMap != null && methodFieldMap.containsKey(method)) {
            Set<Field> fields = methodFieldMap.get(method);
            for (Field field : fields) {
                field.setAccessible(true);
                for (Annotation annotation : field.getAnnotations()) {
                    if (annotation instanceof RecursionCheck) {
                        Object f = field.get(o);
                        if (f != null && f.getClass().equals(field.getType())) {
                            Object feh = ValCheckProxyFactory.getProxyInstance(f, this);
                            field.set(o, feh);
                        }
                        continue;
                    }
                    Class<? extends Validate> validateClz = null;
                    try {
                        Method validateCMethod = annotation.getClass().getMethod("validate");
                        validateClz = (Class<? extends Validate>) validateCMethod.invoke(annotation);
                    } catch (Throwable ignored) {
                    }
                    if (validateClz != null) {
                        Validate validate = validateClz.newInstance();
                        Object value = field.get(o);
                        validate.validate(o, field, value, annotation);
                    }
                }
            }
        }
        return result;
    }

    public Map<Method, Set<Field>> initClassCheckMethod(Class<?> clz) {
        Map<Method, Set<Field>> methodFieldMap = new ConcurrentHashMap<>();
        try {
            Set<Field> fields = ReflectUtil.getFields(clz);
            for (Field field : fields) {
                PropertyDescriptor pd = null;
                pd = new PropertyDescriptor(field.getName(), clz);
                Method setMethod = pd.getWriteMethod();//获得set方法
                methodFieldMap.computeIfAbsent(setMethod, m -> {
                    Set<Field> set = ConcurrentHashMap.newKeySet();
                    set.add(field);
                    return set;
                });
            }
        } catch (IntrospectionException e) {
            e.printStackTrace();
        }
        //获取对象的关联注解方法
        Arrays.stream(clz.getMethods()).forEach(method1 -> {
            Relevancy relevancy = method1.getAnnotation(Relevancy.class);
            if (relevancy == null) return;
            methodFieldMap.computeIfAbsent(method1, m -> ConcurrentHashMap.newKeySet());
            Set<Field> fields = methodFieldMap.get(method1);
            String[] fstr = relevancy.value();
            for (String s : fstr) {
                fields.add(ReflectUtil.getField(clz, s));
            }
        });
        return methodFieldMap;
    }
}
```

2.

样例如下

```java
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.RUNTIME)
public @interface Max {
    double value();
    String message() default "";

    Class<? extends Validate<Max>> validate() default Max.DefaultValidate.class;

    class DefaultValidate implements Validate<Max> {
        @Override
        public void validate(Object obj, Field field, Object value, Max annotation) throws ValidateException {
            if (!(value instanceof Number)) {
                return;
            }

            double v;
            if (value instanceof BigDecimal) {
                v = ((BigDecimal) value).doubleValue();
            } else {
                v = (double) value;
            }

            if (v > annotation.value()) {
                throw new ValidateException(obj, field, value, annotation, "value should <= " + annotation.value(), annotation.message());
            }
        }
    }
}
```

```java
public class TestModel extends BaseModel{
    /**
     *
     */
    @Max(100)
    private Integer integer;

    @Max(100)
    private Integer integer2;

    @RecursionCheck
    private TestModel2 m2;

    public TestModel2 getM2() {
        return m2;
    }

    public void setM2(TestModel2 m2) {
        this.m2 = m2;
    }

    public static class TestModel2 extends BaseModel{
        @ValMax(100)
        private Integer integer1;

        public Integer getInteger1() {
            return integer1;
        }

        public void setInteger1(Integer integer1) {
            this.integer1 = integer1;
        }
    }

    public Integer getInteger() {
        return integer;
    }

    public Integer getInteger2() {
        return integer2;
    }

    public void setInteger2(Integer integer2) {
        this.integer2 = integer2;
    }

    public void setInteger(Integer integer) {
        this.integer = integer;
    }
    @Relevancy({"integer","integer2"})
    public void test(int a,int b){
        integer=a+b;
    }
}
```

最后测试代码如下：

```text
        TestModel model1=new TestModel();
        model1.setInteger(13);
        TestModel model= ValCheckProxyFactory.getProxyInstance(model1, ValCheckInterceptor.I);
        model.setInteger(566);
```

校验成功：

```text
learning.proxy.ValidateException: [learning.proxy.TestModel$$EnhancerByCGLIB$$bafbcd1.integer] validation [ValMax] failed: value should <= 100.0, value=566
```
