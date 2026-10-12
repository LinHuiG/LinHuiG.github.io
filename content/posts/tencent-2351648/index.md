{
  "title": "RAFT代码设计",
  "date": "2022-10-17T00:00:00+08:00",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "slug": "tencent-2351648",
  "author": "LinHuiG",
  "categories": [
    "分布式与网络"
  ],
  "tags": [
    "raft",
    "接口",
    "日志",
    "设计",
    "推送"
  ],
  "draft": false,
  "original_date": "2022-10-17",
  "backfilled_at": "2026-10-12",
  "migration_source": "https://cloud.tencent.com/developer/article/2351648",
  "original_url": "https://blog.linhui.fun/article/70",
  "build": {
    "publishResources": false
  },
  "description": "RAFT代码设计。旧文归档，原始发表于 2022-10-17。"
}

> **旧文迁移 · 补录说明**
>
> 原始发表：**2022-10-17**；本站迁移：**2026-10-12**。原始日期依据腾讯云页尾记录，正文与代码按历史版本归档。
>
> [腾讯云原文](https://cloud.tencent.com/developer/article/2351648) · [原个人博客地址](https://blog.linhui.fun/article/70)

根据RAFT论文，准备自己写一个RAFT包（两手准备，有别人开源的就好了QAQ）（论文地址 [https://github.com/maemual/raft-zh\_cn/blob/master/raft-zh\_cn.md](<https://github.com/maemual/raft-zh_cn/blob/master/raft-zh_cn.md>)）

根据论文里的内容做了接口和实体类初步设计（可能有问题，我也不知道）

## **一、功能**

###  **1.选举**

 发起预选

 预选请求处理

 预选响应处理

 发起选举

 选举请求处理

 选举响应处理

###  **2.日志复制/心跳**

 日志推送（心跳）

 日志接收（心跳）处理

### **    3.扩容**

 扩容

 减容

## **二、设计**

        tcp传输层使用netty  
         对其他节点，每个节点两个链接池，一个用来发选举信息，一个用来发日志和心跳（多连接）

        收到的信息反序列化后写入对应的disruptor队列处理  
         每个节点有一个核心线程，一个核心线程池，线程用来处理选举，线程池用来处理日志和心跳相关操作

###  **1.Node类（物理节点）**

 NodeChannelManage（连接管理）

 RAFT实例数组

 定时任务线程

####  **接口1：推送心跳**

 遍历当前节点所有实例（非leader不发）

 实例状态形成心跳

 心跳推送其他节点

 设置下一次心跳定时任务

####  **接口2：写入日志**

 找到对应raft实例提交

####  

###  **2.NodeChannelManage类（连接管理）**

 选举连接  
 日志连接池(一个实例哈希到一个连接，保证单实例有序)

####  **接口1.推送实例的心跳（心跳视为0size的日志推送）**

 从日志连接池推送

####  **接口2.推送实例的日志**

 从日志连接池推送

####  **接口3.推送实例的预选请求**

 从选举连接推送

####  **接口4.推送实例的选举请求**

 从选举连接推送

####  **接口5.推送实例的预投票请求**

 从选举连接推送

####  **接口6.推送实例的投票请求**

 从选举连接推送

###  

###  **3.raft实例：**

 基本参数：  
 coreId（实例编号）  
 nodeId（节点编号）  
 状态：  
 state（实例状态：leader，follower，candidate，learner）  
 term（任期，第一次初始化为0）  
 votedFor（当前任期投票对象）  
 leaderNodeId（领导者节点编号）  
 LogMap（日志，logIndex-&gt;Log 采用内存+RocksDB,RocksDB每个coreId独立建表，日志索引从1开始）  
 maxLogIndex（已保存最大日志序号，等于logMap中最大的Index，无需落地）  
 易失性状态：  
 committedIndex（已知已提交的最高的日志条目的索引（初始值为0，单调递增））  
 lastApplied（已经被应用到状态机的最高的日志条目的索引（初始值为0，单调递增））  
 leaderHeartbeatTime（领导者节点最后一次发送心跳的时间，领导者自己无需维护）  
 领导人专属易失性状态：  
 nextIndex\[\] 对于每一台服务器，发送到该服务器的下一个日志条目的索引（初始值为领导人最后的日志条目的索引+1）  
 matchIndex\[\] 对于每一台服务器，已知的已经复制到该服务器的最高日志条目的索引（初始值为0，单调递增）  
 heartbeatTime\[\] 对于每一台服务器，最后一次心跳响应的时间戳  
   
 lastVoteTime 最后一次投票时间戳（包括预投票）  
   
 选举线程（状态检查，leader心跳回调处理）  
 日志线程（接收日志，心跳的处理）  
 日志推送线程（leader专用，其他节点用不到）  
 日志apply线程  
 

 **初始化**

            term=Index最大的日志的term

            maxLogInde=日志最大Index

            state=跟随者

            设置状态检查定时任务（随机延迟1~2倍）

####  **接口1.写入日志 submit**

 if 不是领导  
 return  
 提交日志推送线程

####  **接口2.接收日志/心跳 appendEntries**

 日志提交 日志线程  
 if（日志的任期小于本节点任期）return  
 更新leaderHeartbeatTime  
 if（本节点状态为候选人）  
 调用投票结果处理（失败）  
 if（日志的 prevLogIndex 且 prevLogTerm在本实例找不到一个日志能匹配上）推送失败响应并返回  
 if（日志的Index在本实例存在，且term不一致）删除index以及之后的所有日志  
 追加未保存日志  
 if 已提交日志Index大于本节点已提交日志Index：  
 更新本实例committedIndex=min（日志最大序号，新日志的committedIndex更新）  
 更新lastApplied+1 循环到本实例committedIndex  
 lastApplied日志提交日志apply线程对状态机进行apply  
 推送成功并返回

####  **接口3.接收日志/心跳的回调 onAppendEntries（发起者的回调）（term，succeed，logIndex（若succeed为false使用））**

 （在选举线程里）  
 term小于本实例term直接丢弃（可能是之前任期的leader的回调，不应理会）  
 更新heartbeatTime\[\]  
 if 失败：  
 nextIndex\[\]中 该接收者的nextIndex--（需要优化的话让跟随者返回可能正常的logIndex（跟随者冲突条目的term的相同日志全部越过，返回小于冲突条目term的最大logIndex，这里直接赋值））；  
 对该节点推送日志（一条）  
 if 成功：  
 nextIndex\[\]中 该接收者的nextIndex=请求prevLogIndex+请求日志size+1  
 matchIndex\[\]中 该接收者的nextIndex=请求prevLogIndex+请求日志size  
 if(matchIndex\[\]中 第N/2+1大的数字&gt;当前committedIndex)  
 committedIndex=matchIndex\[\]中 第N/2+1大的数字  
 对所有节点发起心跳  
 if（nextIndex\[\]中 该接收者的nextIndex&lt;=当前日志序号）  
 对该节点推送新日志（记得用批大小控制每次发送数量，记得和matchIndex比对，不要发送太多在途日志）

####  **接口4.定时检查状态**

 （在选举线程里）  
 switch 本实例状态：  
 是领导：检查心跳时间戳是否有过半超时，若过半超时则下台  
 是跟随者：检查最后一次领导者心跳时间戳是否超时，若超时且最后一次投票的时间戳也超时，则发起预投票  
 重新定时检查状态任务提交定时任务（延时：领导者设定为超时时间，跟随者设置超时时间~超时时间\*2之间的随机数）  
 

####  **接口 5.推送日志（nodeId，size）（newLog）**

 if 本节点非Leader 返回  
 提交日志推送线程  
 if 是新日志推送  
 初始化日志  
 appendEntries（本地）  
 appendEntries（推送所有节点（nextId匹配不上的不推））  
 else 按照nodeId和size推送现有日志

####  **接口 6.发起预投票**

 （在选举线程里）  
 lastVoteTime更新为当前时间  
             初始化preVoteSet并向所有节点推送预投票请求

####  **接口7.预投票请求处理（请求体：term，candidateId，lastLogIndex，lastLogTerm）**

 （在选举线程里）  
 if term小于本实例term 返回false  
 if 当前leader的心跳未超时 推送响应false  
 if votedFor为空或等于candidateId，并且lastLogIndex&gt;=自己的maxLogIndex  
 更新lastVoteTime，推送响应true  
   
 preVoteSet

####  **接口8.预投票响应处理（响应体：term，voteGranted）**

 （在选举线程里）  
 校验任期，若不相等则丢弃  
 if voteGranted  
 preVoteSet.add（响应节点NodeId）  
 if preVoteSet.size&gt;节点数量/2  
 预投票结果处理（成功）

####  **接口9.预投票结果处理**

 （在选举线程里）  
 校验任期，若不相等则丢弃  
 if 失败：无事发生  
 if 成功：发起正式投票

####  **接口10.发起投票**

 （在选举线程里）  
 状态变成候选人  
 term++  
 voteFor改为自己  
 设置候选定时任务（超时未成功则失败，记得设随机）  
 lastVoteTime更新为当前时间  
             初始化voteSet并向所有节点发送投票信息

####  **接口11.投票请求处理（请求体：term，candidateId，lastLogIndex，lastLogTerm）**

 （在选举线程里）  
 if term小于本实例term 返回false  
 if term 大于本实例term 或者votedFor为空或等于candidateId，并且lastLogIndex&gt;=自己的maxLogIndex  
 更新lastVoteTime、term、votedFor，返回true  
 

voteSet

####  **接口12.投票响应处理（响应体：term，voteGranted）**

 （在选举线程里）  
 校验任期，若不相等则丢弃  
 if voteGranted  
 VoteSet.add（响应节点NodeId）  
 if VoteSet.size&gt;节点数量/2  
 投票结果处理（成功）

####  **接口13.投票结果处理（term，result）**

 （在选举线程里）  
 校验任期，若不相等则丢弃  
 if 超时失败  
 退回跟随者状态，重新发起预投票  
 if 选举失败（收到新leader心跳）  
 退回跟随者状态  
 if 成功  
 当选leader

###  **4.LogEntry类（物理日志（心跳）实例）**

 Int coreId 实例Id  
 long logTerm  本日志任期  
 long leaderId 领导人Id  
 long prevLogTerm 紧邻新日志条目之前的那个日志条目的任期  
 long prevLogIndex 紧邻新日志条目之前的那个日志条目的索引  
 long leaderCommit 领导人已知已提交日志的Index  
 int size 本次日志数量（心跳填0）  
 size个：  
 int length 单条日志长度  
 byte\[\] data 单条日志数据
