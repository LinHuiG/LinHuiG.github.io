{
  "title": "Java字节码深挖 第一站：动态代理",
  "date": "2022-03-22T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351652",
  "author": "LinHuiG",
  "categories": [
    "Java实践"
  ],
  "tags": [
    "java",
    "代理",
    "动态代理",
    "对象",
    "接口"
  ],
  "draft": false,
  "original_date": "2022-03-22",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351652",
  "original_url": "https://blog.linhui.fun/article/61",
  "build": {
    "publishResources": false
  },
  "description": "Java字节码深挖 第一站：动态代理。旧文归档，原始发表于 2022-03-22。",
  "original_date_text": "2022-03-22",
  "original_sort_key": 20220322,
  "original_year": 2022,
  "date_precision": "day"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2022-03-22**；本站迁移：**2026-10-12**。正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351652) · [原个人博客地址](https://blog.linhui.fun/article/61)

严格来说，代理模式并不能算我们真的设计到了字节码的概念，字节码相关的操作都被Proxy类封装了起来，提供了Proxy.newProxyInstance(ClassLoader loader, Class&lt;?&gt;\[\] interfaces, InvocationHandler h)接口供我们调用，我们只需要考虑业务相关逻辑即可，实际开发中使用动态代理的时候，反射的知识其实更重要。

       实际的使用也非常简单粗暴，从Proxy.newProxyInstance需要传入三个参数便可大概猜出它的作用：第一个参数是类加载器ClassLoader，我们需要为代理类指定一个类加载器，实际开发中一般直接指定AppClassLoader就行；第二个参数是接口列表，将你需要代理的接口列表传入即可，注意是数组，我们可以传入多个接口；第三个参数是调用处理器，传入了我们的逻辑实现，先我将细说这个InvocationHandle。

 我们需要实现一个InvocationHandler 接口，它里面只包含了一个方法：public  Object invoke(Object proxy, Method method, Object\[\] args) throws Throwable;我们调用newProxyInstance 得到的对象在执行方法的时候，本身并不做逻辑操作，真正的逻辑实现在了这个方法内部，代理对象会将自己本身作为第一个参数，被调用的方法作为第二个参数，你调用代理对象方法时输入的参数作为第三个参数来调用你传入的InvocationHandler.invoke方法。在这个方法里，你可以用反射来得到你想得到的信息，并实现真正的业务逻辑。

 下面我将举一个简单的实战例子：

```java
@HttpClient("https://blog.linhui.fun/")
public interface TestHttpClient {
    @HttpRequest(value = "/attachment/20200609/cc4cfce1f93949efb6c3af5adb16b2a9.png", method = "GET")
    Object getPicTure(@RequestBody Map request,@Param("key") String key);

    @HttpRequest(value = "/test/post", method = "POST")
    Object postRequest(@RequestBody ReqClass request);

    static OtcTradeHttpClient getInstance(){
        return HttpClientFactory.getIns(OtcTradeHttpClient.class);
    }
}
```

HttpClientFactory中获取代理实例的代码如下：

```java
    public static <T> T getIns(Class<T> clz) {
        if (insCache.containsKey(clz)) return (T) insCache.get(clz).t;
        if (!clz.isInterface()) throw new RuntimeException("入参应为接口类");
        HttpClient aHC = Reflections.getAnnotation(clz, HttpClient.class);
        if (aHC == null) throw new RuntimeException("HttpClient接口应带有HttpClient注解");

        HttpClientHandler<T> httpClientHandler = new HttpClientHandler<>();
        switch (aHC.type()) {
            case URL:
                httpClientHandler.baseUrl = aHC.value();
                break;
            case PROPERTY_PARAM:
                httpClientHandler.baseUrl = PropertyUtil.getString(aHC.value());
                break;
        }
        Map<Method, Function<Object[], Object>> methodFunctionMap = initMethodFunctionMap(httpClientHandler.baseUrl, clz);
        httpClientHandler.methodFunctionMap = methodFunctionMap;
        InvocationHandler handler = (proxy, method1, args) -> methodFunctionMap.get(method1).apply(args);
        httpClientHandler.t = (T) Proxy.newProxyInstance(clz.getClassLoader(), new Class<?>[]{clz}, handler);
        insCache.putIfAbsent(clz, httpClientHandler);
        return (T) insCache.get(clz).t;
    }
```

       其中initMethodFunctionMap方法是根据接口类的class对象通过反射获取相关信息得到一个Method-&gt;Function的Map，Function中对该Method的方法中带@RequestBody注解的参数进行转为Map加入请求Json中，将@Param注解参数作为参数直接加入请求Json中，最后将生成的Json字符串通过@HttpRequest指定的方法和url相对路径发起请求，对得到的字符串进行反序列化成回参并返回，从而封装了Http客户端请求框架。

       这种方法只用了不到100行代码，实现了整个Http客户端的封装。开发者在进行Http客户端请求开发的时候再也不需要自己来封装请求参数和考虑序列化问题。

       以上就是动态代理的一种用法，提供思路，仅供参考。
