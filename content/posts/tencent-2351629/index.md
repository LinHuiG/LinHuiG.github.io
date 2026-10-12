{
  "title": "代理服务内存调优记录",
  "date": "2022-03-04T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351629",
  "author": "LinHuiG",
  "categories": [
    "分布式与网络"
  ],
  "tags": [
    "对象",
    "内存",
    "性能"
  ],
  "draft": false,
  "original_date": "2022-03-04",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351629",
  "original_url": "https://blog.linhui.fun/article/59",
  "build": {
    "publishResources": false
  },
  "description": "代理服务内存调优记录。旧文归档，原始发表于 2022-03-04。",
  "original_date_text": "2022-03-04",
  "original_sort_key": 20220304,
  "original_year": 2022,
  "date_precision": "day"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2022-03-04**；本站迁移：**2026-10-12**。正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351629) · [原个人博客地址](https://blog.linhui.fun/article/59)

代理服务第一版速度挺猛，但是满载的时候内存消耗到无法忍受，最高的时候吃了我1.8G内存，后经过一系列调优操作，目前满载内存消耗约为100MB。

首先，Netty本身的零拷贝技术理论上内存消耗不大，但是经过对jvm堆分析发现netty的ByteBuf占用了大量的空间，查阅文档后发现Netty默认会开启缓存策略，将对象复用来提高性能，我的需求是性能差不多得了，内存消耗低才是王道，所以关了。

其次，我分析jvm堆的时候还发现占用最高的是byte\[\]对象，而大量使用byte对象的场景只有编解码以及加解密的时候，虽然byte\[\]用完就丢gc也能处理，但是众所周知gc并不会及时清理垃圾，而且频繁gc代价可不小。

所以我使用了对象池技术，byte\[\]对象只能在对象池中获取，对象池大小可以在极小和极大值之间动态扩张。

```text
    protected void encode(ChannelHandlerContext ctx, TcpMessage msg, ByteBuf out) throws Exception {
        if (msg.getBodyBuf() != null) {
            byte[] data=msg.getBodyBuf();
            byte[] ciphertext=ByteArrayPool.getIns().getByteArray(data.length);
            EncryptUtil.AESEncode(data, data.length, ciphertext, configProperties.getDesKey());
            msg.setEncryptBodyBuf(ciphertext);
            ByteArrayPool.getIns().returnByteArray(data);
        }
        byte[] headBuf = msg.getfHead().Serialize();
        byte[] ciphertext=ByteArrayPool.getIns().getByteArray(headBuf.length);
        EncryptUtil.AESEncode(headBuf, headBuf.length, ciphertext, configProperties.getDesKey());
        EncryptUtil.selfWriteByte(out,ciphertext,ciphertext.length,configProperties);
        if (msg.getBodyBuf() != null) {
           EncryptUtil.selfWriteByte(out,msg.getBodyBuf(),msg.getBodyBuf().length,configProperties);
        }
        ByteArrayPool.getIns().returnByteArray(headBuf);
        ByteArrayPool.getIns().returnByteArray(msg.getBodyBuf());

    }

protected void decode(ChannelHandlerContext ctx, ByteBuf in, List<Object> out) throws Exception {
        TcpMessage tcpMessage = new TcpMessage();
        try {
            in.markReaderIndex();
            if (in.readableBytes() < TcpHead.headLength) {
                in.resetReaderIndex();
                return;
            }

            TcpHead tcpHead = new TcpHead();
            byte[] ciphertext = ByteArrayPool.getIns().getByteArray(TcpHead.headLength);
            byte[] headByte = ByteArrayPool.getIns().getByteArray(TcpHead.headLength, true);

            if (!EncryptUtil.selfReadByte(in,ciphertext,ciphertext.length,configProperties)){
                //读取失败，长度不够
                in.resetReaderIndex();
                ByteArrayPool.getIns().returnByteArray(ciphertext);
                ByteArrayPool.getIns().returnByteArray(headByte);
                return;
            }

            EncryptUtil.AESDecode(ciphertext, ciphertext.length, headByte, configProperties.getDesKey());
            tcpHead.DeSerialize(ByteBuffer.wrap(headByte));
            ByteArrayPool.getIns().returnByteArray(ciphertext);
            ByteArrayPool.getIns().returnByteArray(headByte);

            tcpMessage.setfHead(tcpHead);
            if (tcpHead.getCrc() != tcpHead.calCrc()) {
                ctx.channel().close();
                System.out.println("CRC校验失败");
            }

            if (in.readableBytes() < tcpHead.getLength()) {
                in.resetReaderIndex();
                return;
            }
            if (tcpHead.getRealLength() > 0) {
                byte[] mainbuf = ByteArrayPool.getIns().getByteArray(tcpHead.getRealLength());
                ciphertext = ByteArrayPool.getIns().getByteArray(tcpHead.getLength(), true);

                if (!EncryptUtil.selfReadByte(in,ciphertext,ciphertext.length,configProperties)){
                    //读取失败，长度不够
                    in.resetReaderIndex();
                    ByteArrayPool.getIns().returnByteArray(ciphertext);
                    ByteArrayPool.getIns().returnByteArray(mainbuf);
                    return;
                }
                EncryptUtil.AESDecode(ciphertext, ciphertext.length, mainbuf, configProperties.getDesKey());
                ByteArrayPool.getIns().returnByteArray(ciphertext);
                tcpMessage.setBodyBuf(mainbuf, tcpHead.getRealLength());
            }

            out.add(tcpMessage);
        } catch (Exception ex) {
            //  Logger.LogError(ex.getMessage(), ex);
        }
    }
```

```java
public class ByteArrayPool {
    int minN = 100;
    int maxN = 500;
    int mod = 16;

    private static class Ins {
        private static ByteArrayPool I = new ByteArrayPool();
    }

    public static ByteArrayPool getIns() {
        return Ins.I;
    }

    private Map<Integer, LinkedBlockingQueue<byte[]>> pool = new ConcurrentHashMap<>();

    public byte[] getByteArray(int length, boolean isNotUpper) {
        if (isNotUpper) return get(length);
        length += mod - length % mod;
        return get(length);
    }

    public byte[] getByteArray(int length) {
        return getByteArray(length, false);
    }

    private byte[] get(int length) {
        byte[] ret;
        poolDataMap.computeIfAbsent(length,k->new AtomicInteger(0));
        pool.computeIfAbsent(length, k -> new LinkedBlockingQueue<>());
        LinkedBlockingQueue<byte[]> queue = pool.get(length);
        try {
            if (poolDataMap.get(length).get()<=minN){
                poolDataMap.get(length).addAndGet(1);
                return new byte[length];
            }
            ret= queue.poll();
            if (ret==null){
                if (length<50){
                    poolDataMap.get(length).addAndGet(1);
                    return new byte[length];
                }
                Thread.sleep(10);
                poolDataMap.get(length).addAndGet(1);
                return new byte[length];
            }
            return ret;
        } catch (Throwable exception) {
            poolDataMap.get(length).addAndGet(1);
            return new byte[length];
        }

    }
    public static Map<Integer, AtomicInteger> poolDataMap=new ConcurrentHashMap<>();
    public void returnByteArray(byte[] bytes) {
        if (bytes == null) return;
        pool.computeIfAbsent(bytes.length, k -> new LinkedBlockingQueue<>());
        LinkedBlockingQueue<byte[]> queue = pool.get(bytes.length);
        if (queue.size() > maxN) {
            poolDataMap.computeIfAbsent(bytes.length,k->new AtomicInteger(0));
            poolDataMap.get(bytes.length).addAndGet(-1);
            System.gc();
            return;
        }
        queue.offer(bytes);
    }
}
```

另外cipher.doFinal是可以传入byte\[\]来接收加解密结果的，这样我们加解密时候cipher就不会浪费我们多余空间了。

```text
 cipher.doFinal(data, 0, length, result, 0);
```

最后就是jvm启动的时候，我换了cms来做gc，因为cms提供了一个fullGc的参数，老年代内存占用达到临界值就强行fullGc，而且cms管理小内存貌似不错，我把临界值设置为70%。

做完这些后把jvm堆大小上限设置为100M，测试后发现我的500M带宽能跑满，内存占用不到100M，收工！
