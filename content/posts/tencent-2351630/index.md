{
  "title": "Netty手撸代理服务",
  "date": "2022-03-03T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351630",
  "author": "LinHuiG",
  "categories": [
    "分布式与网络"
  ],
  "tags": [
    "netty",
    "服务端",
    "客户端",
    "连接",
    "数据"
  ],
  "draft": false,
  "original_date": "2022-03-03",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351630",
  "original_url": "https://blog.linhui.fun/article/58",
  "build": {
    "publishResources": false
  },
  "description": "Netty手撸代理服务。旧文归档，原始发表于 2022-03-03。"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2022-03-03**；本站迁移：**2026-10-12**。原始日期依据腾讯云页尾记录，正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351630) · [原个人博客地址](https://blog.linhui.fun/article/58)

### **首先声明：本文内容仅作为技术研究，学习者不得用于违法用途，本文涉及到的源码仅展示部分核心代码以供学习，全部的功能代码不会开源！！！**

**分析**

网络代理的原理非常简单，源地址访问目标地址的时候流量并不直接传输，而是将目标地址信息和流量包发送到代理服务器上，由代理服务器进行转发，从而实现网络代理功能。

通过分析可以得知，我们的代理服务器对外只需要满足**3个基础功能**即可：**1.连接建立 2.字节流转发 3.连接断开**。当然为了服务功能的完善，我们额外需要一个**4.登录功能**。

同时，我们还可以分析得知，一般源服务器并不会只通过代理建立一个连接，所以我们还需要有个**连接管理功能**，所以协议内需要带上连接相关信息，我们可以用一个int来表示。

**报文设计**

**初定报文：**

所以，我们的协议就拟定了：

 **报文头**：

        连接编号          4字节

        指令              4字节

        报文体长度        4字节

        crc校验           4字节

 **报文体**：

 数据内容，长度不定

```java
public enum FUNC_ENUM {
    CONN(0x01,"连接目标地址"),
    DIS_CONN(0x02,"断开目标地址"),
    SEND(0x03,"转发数据"),
    LOGIN(0x04,"登录"),
    ;
    private int code;
    private String desc;

    private static final class Mapping{
        private final static Map<Integer, FUNC_ENUM> code2Enum=new HashMap<>();
    }
    FUNC_ENUM(int code, String desc) {
        this.code = code;
        this.desc = desc;
        Mapping.code2Enum.put(this.code,this);
    }
    public static FUNC_ENUM getByCode(int code){
        return  Mapping.code2Enum.get(code);
    }
    public int getCode() {
        return code;
    }

    public void setCode(int code) {
        this.code = code;
    }

    public String getDesc() {
        return desc;
    }

    public void setDesc(String desc) {
        this.desc = desc;
    }
}

public class TcpHead {
    /**
     * 包头长度
     */
    public static int headLength = 20;

    private int sessionId;
    private int funcId;
    private int length;
    private int realLength=0;
    private int crc;


    public byte[] Serialize() {
        byte[] bHead = null;
        try {
            ByteBuffer byteBuffer = ByteBuffer.wrap(ByteArrayPool.getIns().getByteArray(headLength,true)).order(ByteOrder.BIG_ENDIAN);
            byteBuffer.putInt(sessionId);
            byteBuffer.putInt(funcId);
            byteBuffer.putInt(length);
            byteBuffer.putInt(realLength);
            byteBuffer.putInt(crc= calCrc());
            bHead = byteBuffer.array();
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return bHead;
    }

    public void DeSerialize(ByteBuf byteBuf){
        sessionId=byteBuf.readInt();
        funcId=byteBuf.readInt();
        length=byteBuf.readInt();
        realLength =byteBuf.readInt();
        crc=byteBuf.readInt();
    }
    public void DeSerialize(ByteBuffer byteBuffer){
        sessionId=byteBuffer.getInt();
        funcId=byteBuffer.getInt();
        length=byteBuffer.getInt();
        realLength =byteBuffer.getInt();
        crc=byteBuffer.getInt();
    }

    public int calCrc(){

        ByteBuffer byteBuffer = ByteBuffer.allocate(headLength-4).order(ByteOrder.LITTLE_ENDIAN);
        byteBuffer.putInt(sessionId);
        byteBuffer.putInt(funcId);
        byteBuffer.putInt(length);
        byteBuffer.putInt(realLength);
        return CrcUtils.getCrc32ByData(byteBuffer.array());
    }
}
public class TcpMessage {
    public TcpMessage() {
    }

    public TcpMessage(int funcId, int sessionId) {
        tcpHead = new TcpHead();
        tcpHead.setFuncId(funcId);
        tcpHead.setSessionId(sessionId);
    }
    /**
     * 协议包头
     */
    private TcpHead tcpHead;


    /**
     * 协议包体
     */

    private byte[] bodyBuf;

    public TcpHead getfHead() {
        return tcpHead;
    }

    public void setfHead(TcpHead tcpHead) {
        this.tcpHead = tcpHead;
    }

    public byte[] getBodyBuf() {
        return bodyBuf;
    }


    public void setBodyBuf(byte[] bodyBuf,int length) {
        this.bodyBuf = bodyBuf;
        this.tcpHead.setRealLength(length);
    }
    public void setEncryptBodyBuf(byte[] bodyBuf) {
        this.tcpHead.setLength(bodyBuf.length);
        this.bodyBuf = bodyBuf;
    }
}
```

**加密报文**

报文直接进行传输并不安全，很有可能导致数据泄露问题，所以我们需要进行加密，此处我采用了AES-256加密算法，采用了时间（小时单位）+初始密码的形式作为AES密码对报文进行加密（包括报文头），所以我们的报文头需要增加一个字段：**报文体实际长度，**如下：

**报文头**：

        连接编号          4字节

        指令              4字节

        报文体长度        4字节

        报文体实际长度    4字节

        crc校验           4字节

 **报文体**：

 数据内容，长度不定

加密后的报文头长度固定为32字节，报文体则会被填充至16的整倍数。

```java
    public static void AESEncode(byte[] data, int length, byte[] result, byte[] keyBytes) {
        try {
            if (aesKey == null) setAesKey(keyBytes);

            Cipher cipher = Cipher.getInstance("AES");
            cipher.init(Cipher.ENCRYPT_MODE, key);

            cipher.doFinal(data, 0, length, result, 0);
   
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    public static void AESDecode(byte[] data, int length, byte[] result, byte[] keyBytes) {
        try {
            if (aesKey == null) setAesKey(keyBytes);

            Cipher cipher = Cipher.getInstance("AES");
            cipher.init(Cipher.DECRYPT_MODE, key);
       
            cipher.doFinal(data, 0, length, result, 0);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
```

**混淆报文**：

由于AES加密后的数据长度非常具有特征（16倍数），并且加密后的报文可能被特征识别，所以我们对报文再次进行混淆，混淆的算法简单粗暴，如下：

 根据密码生成固定的一组数字，根据这组数据在报文体和报文头插入随机数据，比例为20%

如生成的数字为5    6,3,10,15,20....

其中第0位数字比较特殊

若第0位数为奇数，则先传输3个有效数据，再传输10个随机数据，再传输15个有效数字......随机数据占比20%

若第0位数为偶数，则先传输6个随机数据，传输3个有效数据，再传输10个随机数据，再传输15个有效数字......随机数据占比20%

```java
    public static boolean selfReadByte(ByteBuf in, byte[] result, int readLength, ConfigProperties configProperties) {
        int index = 0;
        int i = configProperties.getRandomByKey(0,2)+ 1;
        Set<ByteBuf> waitForClearSet = new HashSet<>();
        while (index < readLength) {
            if (i % 2 == 0) {//除去无用字节
                int readByteL = configProperties.getRandomByKey(i, readLength / 10) + 5;
                if (in.readableBytes() < readByteL) return false;
                waitForClearSet.add(in.readBytes(readByteL));
            } else {
                int readByteL = configProperties.getRandomByKey(i, readLength / 2) + 5;
                if (index > readLength - readByteL) readByteL = readLength - index;
                if (in.readableBytes() < readByteL) return false;
                in.readBytes(result, index, readByteL);
                index += readByteL;
            }
            i++;
        }
        for (ByteBuf byteBuf : waitForClearSet) {
            byteBuf.release();
        }
        return true;
    }

    public static boolean selfWriteByte(ByteBuf out, byte[] data, int writeLength, ConfigProperties configProperties) {
        int index = 0;
        int i = configProperties.getRandomByKey(0,2)+ 1;
        while (index < writeLength) {
            if (i % 2 == 0) {//写入随机字节
                int readByteL = configProperties.getRandomByKey(i, writeLength / 10) + 5;
                byte[] bytes = configProperties.getRandomBytes(readByteL);
                out.writeBytes(bytes, 0, readByteL);
                ByteArrayPool.getIns().returnByteArray(bytes);
            } else {
                int readByteL = configProperties.getRandomByKey(i, writeLength / 2) + 5;
                if (index > writeLength - readByteL) readByteL = writeLength - index;
                out.writeBytes(data, index, readByteL);
                index += readByteL;
            }
            i++;
        }
        return true;
    }
```

**结构设计**

Netty是一个非常流行的网络io框架，内置了Sock5的编解码类，我们设计的VPN客户端对外提供的接口便是Sock5接口，便于浏览器的接入。

因此我们的目标便清晰了，我们的客户端作为sock5服务端在本地打开sock5服务端口便于其他软件接入，客户端收到sock5的连接请求后将其转换为私有协议（上面设计的报文）传输给服务端，服务端与目标服务器建立连接后通知客户端，之后服务端/客户端收到的数据流包装为报文后发送给对方，对方根据连接编号找到实际的连接写入即可。

**首先是登录功能：**

这里客户端只需要把账号密码发送给服务端即可。

```java
public class PasswordAuthRequestInboundHandler extends SimpleChannelInboundHandler<TcpMessage> {

    private final ConfigUtil configUtil;

    @Override
    protected void channelRead0(ChannelHandlerContext ctx, TcpMessage msg) throws Exception {
        byte[] data = msg.getBodyBuf();
        if (msg.getfHead().getFuncId() == FUNC_ENUM.LOGIN.getCode() && data.length >= UsernameAndPasswordModel.length)
        {
            UsernameAndPasswordModel usernameAndPasswordModel = new UsernameAndPasswordModel();
            usernameAndPasswordModel.userName = BytesUtils.getString(data, 0, UsernameAndPasswordModel.userNameLength, StandardCharsets.UTF_8);
            usernameAndPasswordModel.password = BytesUtils.getString(data, UsernameAndPasswordModel.userNameLength, UsernameAndPasswordModel.passwordLength, StandardCharsets.UTF_8);
            //认证成功
            if (configUtil.getUsers().get(usernameAndPasswordModel.userName).equals(usernameAndPasswordModel.password)) {
                byte[] bytes="succeed".getBytes(StandardCharsets.UTF_8);
                msg.setBodyBuf(bytes,bytes.length);
                ctx.writeAndFlush(msg);
                ctx.pipeline().remove(this);
                System.out.println("客户端登录成功");
                return;
            }
        }
        byte[] bytes="fail".getBytes(StandardCharsets.UTF_8);
        msg.setBodyBuf(bytes,bytes.length);
        //发送鉴权失败消息，完成后关闭channel
        ctx.writeAndFlush(msg).addListener(ChannelFutureListener.CLOSE);
    }
}
```

**功能指令开发-发送连接服务器指令（客户端）：**

```java
    public void connDest(ChannelHandlerContext clientCtx, String ip, int port, Socks5AddressType socks5AddressType) {
        int sessionId = sessionIdGenerate.addAndGet(1);
        ConnDestModel connDestModel = new ConnDestModel(sessionId);
        connDestModel.ip = ip;
        connDestModel.port = port;
        TcpMessage message = new TcpMessage(FUNC_ENUM.CONN.getCode(), sessionId);
        byte[] bytes = connDestModel.toBytes();
        message.setBodyBuf(bytes, bytes.length);
        send(message);
        sessionId2CtxMap.put(sessionId, clientCtx.channel());
        ctx2SessionIdMap.put(clientCtx.channel(), sessionId);
        sessionId2Sock5TypeMap.put(sessionId, socks5AddressType);
    }
```

**功能指令开发-连接服务器（服务端）：**

```java
    private void connDest(ChannelHandlerContext ctx, ConnDestModel data) {
        Bootstrap bootstrap = new Bootstrap();
        bootstrap.group(clientWorkGroup);
        bootstrap.channel(NioSocketChannel.class);
        bootstrap.option(ChannelOption.TCP_NODELAY, true);
        ServerInboundHandler serverInboundHandler=this;
        bootstrap.handler(new ChannelInitializer<SocketChannel>() {
            @Override
            protected void initChannel(SocketChannel ch) throws Exception {
                //添加服务端写客户端的Handler
                ch.pipeline()
                        .addLast(new ByteDecode())
                        .addLast(new ByteEncode())
                        .addLast(new ReceiveDestInboundHandler(ctx.channel(), data.sessionId,serverInboundHandler,ctx));
            }
        });
        ChannelFuture future = bootstrap.connect(data.ip, data.port);
        future.addListener((ChannelFutureListener) future1 -> {
            if (future1.isSuccess()) {
                log.debug("目标服务器连接成功");
                ctx.channel().writeAndFlush(getConnMsg(data.sessionId));
                sessionId2CtxMap.put(data.sessionId,future1.channel());
                ctx2SessionIdMap.put(future1.channel(),data.sessionId);
            } else {
                log.error("连接目标服务器失败,address={},port={}", data.ip, data.port);
                ctx.channel().writeAndFlush(getDisConnMsg(data.sessionId));
                future1.channel().close();
            }
        });
    }
```

**功能指令开发-流量转发（客户端）：**

```java
    protected void channelRead0(ChannelHandlerContext channelHandlerContext, ByteModel data) throws Exception {
        sendMsg(channelHandlerContext.channel(),data);
    }
    public void sendMsg(Channel clientCtx, ByteModel data) {
        int sessionId = ctx2SessionIdMap.get(clientCtx);
        TcpMessage message = new TcpMessage(FUNC_ENUM.SEND.getCode(), sessionId);
        message.setBodyBuf(data.getData(), data.getLength());
        send(message);
    }
    private void send(TcpMessage message) {
        if (!isLogin.get()) return;
        if (!serverChannel.isActive() || !serverChannel.isOpen()) {
            connServer();
        }
        serverChannel.writeAndFlush(message);
    }
```

**功能指令开发-流量转发（服务端）：**

```java
    Channel clientCh;
    int sessionId;
    public ReceiveDestInboundHandler(Channel clientCh, int sessionId) {
        this.clientCh = clientCh;
        this.sessionId=sessionId;
    }


    @Override
    protected void channelRead0(ChannelHandlerContext channelHandlerContext, ByteModel data) throws Exception {
        TcpMessage message=new TcpMessage(FUNC_ENUM.SEND.getCode(),sessionId);
        message.setBodyBuf(data.getData(),data.getLength());
        clientCh.writeAndFlush(message);
    }
```

**指令功能开发-断开连接（客户端）：**

```java
    public void disConnDest(int sessionId) {
        disConnDest(sessionId, sessionId2CtxMap.get(sessionId));
    }

    public void disConnDest(Channel clientCtx) {
        if (clientCtx == null) return;
        int sessionId = ctx2SessionIdMap.getOrDefault(clientCtx, -1);
        disConnDest(sessionId, clientCtx);
    }

    private void disConnDest(int sessionId, Channel clientCtx) {
        if (clientCtx == null || sessionId == -1) return;
        TcpMessage message = new TcpMessage(FUNC_ENUM.DIS_CONN.getCode(), sessionId);
        send(message);
        clientCtx.close();
        ctx2SessionIdMap.remove(clientCtx);
        sessionId2CtxMap.remove(sessionId);
    }
```

**指令功能开发-断开连接（服务端）：**

```java
    public void disConn(ChannelHandlerContext ctx, int sessionId) {
        Channel dest = sessionId2CtxMap.get(sessionId);
        if (dest != null) {
            dest.close();
            sessionId2CtxMap.remove(sessionId);
            ctx2SessionIdMap.remove(dest);
            ctx.writeAndFlush(getDisConnMsg(sessionId));
        }
    }

    private TcpMessage getDisConnMsg(int sessionId) {
        TcpHead tcpHead = new TcpHead();
        tcpHead.setFuncId(FUNC_ENUM.DIS_CONN.getCode());
        tcpHead.setSessionId(sessionId);
        TcpMessage message = new TcpMessage();
        message.setfHead(tcpHead);
        return message;
    }
```

到此，我们的服务写完了，稍微测了一下性能有点问题，居然占用了100M内存，通过分析发现是流量包转发的时候new了太多的byte数组了，因此我们改造了一下编解码的地方，使用了byte数组池的方式复用了byte数组：

```java
public class ByteArrayPool {
    int minN = 10;
    int maxN = 1000;
    int mod=16;
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
        pool.computeIfAbsent(length, k -> new LinkedBlockingQueue<>());
        LinkedBlockingQueue<byte[]> queue = pool.get(length);
        if (queue.size() < minN) return new byte[length];
        else {
            try {
                return queue.take();
            } catch (InterruptedException exception) {
                return new byte[length];
            }
        }
    }
    public void returnByteArray(byte[] bytes){
        if (bytes==null)return;
        pool.computeIfAbsent(bytes.length, k -> new LinkedBlockingQueue<>());
        LinkedBlockingQueue<byte[]> queue = pool.get(bytes.length);
        if (queue.size()>maxN)return;
        queue.offer(bytes);
    }
}
```

**编解码改造：**

```text
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
                return;
            }

            EncryptUtil.AESDecode(ciphertext, ciphertext.length, headByte, configProperties.getDesKey());
            tcpHead.DeSerialize(ByteBuffer.wrap(headByte));
            ByteArrayPool.getIns().returnByteArray(ciphertext);
            ByteArrayPool.getIns().returnByteArray(headByte);

            tcpMessage.setfHead(tcpHead);
            if (tcpHead.getCrc() != tcpHead.calCrc()) {
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
                    return;
                }
        name));

            out.add(tcpMessage);
        } catch (Exception ex) {
            //  Logger.LogError(ex.getMessage(), ex);
        }
    }


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
```

**大功告成！**
