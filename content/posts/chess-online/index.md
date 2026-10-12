{
  "title": "翻棋联机：Android、网页与 Docker 自动构建",
  "slug": "chess-online",
  "author": "LinHuiG",
  "draft": false,
  "original_date_text": "2026-10-12",
  "original_sort_key": 20261012,
  "original_year": 2026,
  "backfilled_at": "2026-10-12",
  "lastmod": "2026-10-12T00:00:00+08:00",
  "categories": [
    "项目实践"
  ],
  "tags": [
    "Android",
    "Rust",
    "Docker",
    "GitHub Actions"
  ],
  "description": "翻棋联机：Android、网页与 Docker 自动构建。原始时间：2026-10-12。",
  "date": "2026-10-12T00:00:00+08:00",
  "date_precision": "day"
}

> 原始写作：2026-10-12；本站整理：2026-10-12。

翻棋联机是一款可以和朋友直接开局的暗棋游戏：无需注册，一人创建房间，另一人加入，双方准备后开始对局。项目同时提供原生 Android 客户端和适配手机、电脑的网页版，两个端可以进入同一房间。

这篇文章介绍项目目前的联机方式、部署方法和自动构建流程。项目地址：[LinHuiG/chinese-chess-flipping](https://github.com/LinHuiG/chinese-chess-flipping)。

## 从一盘暗棋开始

棋盘采用 4×8 布局，包含翻棋、走子、特殊吃法和阵亡统计。每步可以选择 30、60、90 秒或不限时，游戏内可查看完整规则，重复棋面会被限制。房间名和昵称都可自行设置。

Android 客户端最低支持 Android 8.0，可以从服务器网页下载 APK，也可以从 GitHub Actions 最近一次成功发布的 `app-update` 附件获取安装包。网页版打开服务器网站即可游玩。[项目 README](https://github.com/LinHuiG/chinese-chess-flipping/blob/main/README.md)

## Android 直连，网页经服务器联机

服务端使用 Rust，Android 客户端使用原生 Java，网页资源随服务端一起提供。

Android 玩家之间可以尝试 UDP 直连；直连失败时自动回到服务器中转。网页版通过服务器联机。因此 P2P 的适用范围是 Android 玩家之间，跨端联机仍有服务器参与。

断线恢复依赖仍然有效的会话。会话保留到最后一次有效心跳后 60 秒，短暂断网、App 重启或网页刷新后可以恢复；断线期间回合倒计时继续。服务端重启会清空在线房间，需要重新创建或加入。这几个条件决定了“能恢复”与“需要重开”的边界。[项目 README](https://github.com/LinHuiG/chinese-chess-flipping/blob/main/README.md)

## 一个镜像带上服务端、网页和安装包

Docker 镜像同时包含 Rust 服务端、网页和 Android 安装包，支持 `linux/amd64` 与 `linux/arm64`。运行镜像不需要另装 Java，也不需要配置数据库。

下载项目的 [compose.yaml](https://github.com/LinHuiG/chinese-chess-flipping/blob/main/server/compose.yaml)，在同一目录创建 `.env`：

```dotenv
SERVER_IMAGE=ghcr.io/linhuig/chinese-chess-flipping:latest
TCP_PORT=8888
UDP_PORT=8888
HTTP_PORT=80
HTTP_BIND_ADDRESS=0.0.0.0
HTTP_PUBLISH_PORT=8080
TCP_WORKER_THREADS=2
```

然后拉取镜像并启动：

```sh
docker compose pull
docker compose up -d --no-build
docker compose logs --tail=50 server
```

浏览器访问 `http://服务器地址:8080`。Android 可以选 HTTP 并使用端口 `8080`，也可以选 TCP 并使用 `8888`。

| 对外端口 | 用途 |
| --- | --- |
| TCP 8080 | 网页、WebSocket 联机、App 更新 |
| TCP 8888 | Android TCP 连接 |
| UDP 8888 | 协助 Android 玩家建立直连 |

TCP 和 UDP 需要分别配置防火墙与安全组。UDP 不可达时仍可通过服务器中转；修改 UDP 端口时，容器内外端口应保持一致。公网部署可配置 HTTPS/WSS；同机反向代理场景下，将 `HTTP_BIND_ADDRESS` 改为 `127.0.0.1`，再由代理转发网页与 WebSocket 请求。[部署说明](https://github.com/LinHuiG/chinese-chess-flipping/blob/main/docs/DEPLOYMENT.md)

## 自动构建先检查，再发布

发布工作流分为客户端与服务端检查、两种架构的镜像发布，以及多架构清单合并。合并请求执行检查；满足范围条件的主分支推送或手动运行才发布镜像。

流程先准备 Android APK 与版本清单，执行客户端逻辑检查、Lint、Rust 测试与构建；随后启动服务端，检查网页资源、更新接口以及需要执行的客户端与服务端互通测试，并运行网页恢复与协议检查。发布包使用固定签名，合并请求使用调试签名。

工作流按构建输入缓存已经检查过的产物，缓存命中后还会核对 APK 清单、Rust 文件哈希和互通验证标记，再决定哪些构建与检查可以复用。网页与协议检查仍在流程中执行。

镜像分别在 amd64 和 arm64 运行器上构建。每种架构先按 digest 上传，再启动容器核对版本清单、网页脚本和 APK；验证完成后更新架构标签。两个架构都成功后，才把本次构建的两个 digest 合成多架构清单。合并时使用确定的 digest，避免从可变的 `latest` 标签取到别次构建的产物。[发布工作流](https://github.com/LinHuiG/chinese-chess-flipping/blob/main/.github/workflows/publish.yml)

## 本地开发和后续更新

本地开发需要 Rust 稳定版工具链，以及 README 指定的 Android Studio、JDK、SDK 和 Build Tools。服务端启动需要 APK 与版本清单，因此先构建 Android 客户端，再运行打包脚本，最后启动服务端。调试包与正式包签名不同，不能直接覆盖安装。

常用检查命令如下，在仓库根目录执行：

```powershell
cargo test --locked --manifest-path server/Cargo.toml
.\android_client\gradlew.bat -p android_client lintDebug testDebugUnitTest
node scripts/session-v2-test.mjs
```

互通测试需要先启动本地服务端并设置对应测试端口；未设置时会跳过互通测试。日常部署更新只需重新拉取镜像并运行 `docker compose up -d --no-build`，但更新会中断当前对局，应在无人游玩时进行。客户端开发与消息格式可继续阅读 [通信协议](https://github.com/LinHuiG/chinese-chess-flipping/blob/main/docs/PROTOCOL.md)。
