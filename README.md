# 良扑 · 内网团队评分

给你身边的团队和同事打分。复刻虎扑评分体系（1-10 分、评分趋势、分布、亮评、深色模式），
支持带图动态、评论点赞与回复、用户主页，内网部署，Android / Windows 双端。

## 目录结构

```
liangpu/
├─ docs/prototype/      高保真 UI 原型（单文件 HTML，最终视觉基准）
├─ server/              后端：Fastify + Prisma + SQLite（单端口 7001）
├─ admin/               管理后台：Vue3 + Vite + Element Plus（构建后由后端托管）
└─ app/                 客户端：Flutter（Android + Windows）
```

## 快速启动

### 1. 后端

```powershell
cd server
npm install
npm run db:push      # 初始化 SQLite 表结构
npm run seed         # 写入演示数据（12 团队 / 31 员工 / 4 需求）
npm run build
npm start            # http://10.28.13.214:7001
```

- 健康检查：`GET /api/health`
- 管理后台：浏览器打开 `http://<服务器IP>:7001/`（读取 `admin/dist`，已托管）
- UI 原型：`http://<服务器IP>:7001/prototype/`
- 默认账号：`admin / admin123`（管理员）、`demo / demo123`（演示用户）

管理后台可对**团队、员工、需求**做增删改查，管理**平台动态**（审核删除），并可管理**图标池**：
团队图标、员工图标（用户不可改）、用户人像（用户可在 App 内自选）。

### 2. Docker 一键部署（推荐）

后端、管理后台、原型站全部打进一个镜像、一个容器，只暴露 7001 端口，统一走 HTTPS：

```powershell
cd D:\code\liangpu
cp .env.example .env                     # 首次部署：填入随机 JWT_SECRET（见文件内说明）
bash scripts/gen-certs.sh 10.28.13.214   # 首次部署：生成内部 CA 和服务器证书
docker compose up -d --build
```

- 证书在 `docker-data\certs\`；管理电脑安装根证书（任选其一）：
  - 解压 `dist\良扑-管理端证书.zip`，双击 `安装证书.cmd`（当前用户级，无需管理员权限）
  - 或手动执行 `certutil -addstore -user Root "D:\code\liangpu\docker-data\certs\ca.pem"`
  - 下载页也提供 `/downloads/liangpu-admin-cert.zip`，配置过一次后可在网页直接重新下载
- 管理后台 `https://<服务器IP>:7001/`，原型 `https://<服务器IP>:7001/prototype/`，
  健康检查 `GET /api/health`
- 官网/客户端下载页 `http://<服务器IP>:7003/download/`：独立明文端口，公开访问，
  手机浏览器无需安装内部 CA 即可直接打开；只托管官网页面与安装包，不暴露 API 或管理端。
  页面提供 Windows（zip）、Android（arm64 APK + 全机型 zip）与 iOS（未签名 ipa）下载
- 7001 仍保留 `/download/`（已信任内部 CA 的电脑可继续访问），对外分发请使用 7003 入口
- 下载页的安装包放在 `docker-data/downloads/`（只读挂载到容器 `/app/downloads`）：
  `liangpu-windows-0.1.0.zip`、`liangpu-android-arm64-v8a-0.1.0.apk`、`liangpu-android-0.1.0.zip`、
  `liangpu-ios-0.1.0-unsigned.ipa`、`liangpu-admin-cert.zip`。重新执行 `powershell scripts/refresh-dist.ps1`
  会刷新 dist 并同步这些文件（iOS ipa 需先下载到 `dist/`），
  替换后无需重建容器
- 动态图片保存在 `docker-data/uploads/`（挂载到容器 `/app/data/uploads`，静态路径 `/uploads/`），
  备份时请与 `liangpu.db`、`certs/` 一起备份整个 `docker-data` 目录
- 容器已设置 `TZ=Asia/Shanghai`；数据库存 UTC 时间戳，接口返回 ISO 时间，客户端本地化显示为北京时间
- 明文 HTTP 已关闭，旧版客户端需要重新安装新版 APK / exe
- 浏览器直接输入 `<IP>:7001` 也可以：同一端口会检测明文请求并 308 跳转到 HTTPS
  （TLS 流量原样透传给内部端口，不影响 App 与健康检查）
- 首次启动自动建表并写入演示数据（数据库在 `docker-data/liangpu.db`，与 `certs\` 一起备份）
- 更新代码后重新构建：`docker compose up -d --build`
- 查看日志：`docker compose logs -f`；停止：`docker compose down`（不会删除数据卷）
- 部署前请确认宿主机 7001、7003 端口没有被其他进程占用，防火墙需同时放行两个端口
  （7002 是容器内部的 HTTPS 端口，不对外映射）
- `JWT_SECRET` 从 `.env` 读取（该文件已被 `.gitignore` 排除，不会进仓库）；
  部署到其他机器时按 `.env.example` 里的命令重新生成，改后所有人需重新登录
- 证书 825 天到期后重跑 `scripts/gen-certs.sh` 重签（复用 CA，客户端无需更新）

### 3. 管理后台开发

```powershell
cd admin
npm install
npm run dev          # 前端热更新；/api 代理到 localhost:7001
npm run build        # 产物输出到 admin/dist，后端启动时自动托管
```

### 4. 客户端

```powershell
cd app
flutter pub get

# 大陆网络建议先设置 Flutter 官方镜像，否则 Gradle 拉取引擎产物会失败
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'

flutter build apk --release --split-per-abi   # 产物在 build/app/outputs/flutter-apk/
```

已构建好的安装包（三个 ABI 均 ≈17–21MB）在 `dist/`：

| 文件 | 适用 |
| --- | --- |
| `良扑-0.1.0-arm64-v8a.apk` | 绝大多数现代安卓手机（首选） |
| `良扑-0.1.0-armeabi-v7a.apk` | 老旧 32 位设备 |
| `良扑-0.1.0-x86_64.apk` | 安卓模拟器 |

打包分发版：`dist/良扑-Android-0.1.0.zip`（三个 APK + 安装说明，约 27 MB）。
Windows 分发版：`dist/良扑-Windows-0.1.0.zip`（解压后双击 `良扑.exe`，约 12 MB）。
服务端部署包：`dist/良扑-服务端-Docker-0.1.0.zip`（Dockerfile / compose / 源码，约 0.6 MB）。

- 不预置服务器地址：首次启动显示「连接服务器」引导页，填写运维提供的地址后记住；
  登录页底部与「我的」页可随时修改（见 `app/lib/core/state.dart`）。
- App 内置 `assets/certs/ca.pem` 并只信任该 CA（证书固定），Android 已禁止明文 HTTP。
- 本机 Flutter SDK 位于 `D:\develop\flutter`，若 `flutter` 不在 PATH，用完整路径
  `D:\develop\flutter\bin\flutter.bat` 调用。
- Gradle 使用本机 `GRADLE_USER_HOME=D:\develop\gradle-home`，其中的
  `init.d\cn-mirror.gradle` 已配置华为 / 腾讯 / 阿里云 Maven 镜像。
- Windows 端工具链已装好：Visual Studio Build Tools 2022（`C:\BuildTools`，
  MSVC 14.44 + Windows 10 SDK 10.0.26100 + CMake），Windows 开发者模式已开启。
- Windows 构建（产物在 `app\build\windows\x64\runner\Release\`）：

```powershell
cd app
flutter build windows
```

- 分发时需携带整个 `Release` 目录（`data\` 与全部 DLL 不能缺），
  首次启动同样需要填写运维提供的服务器地址。
- 刷新 `dist` 下的 Windows / Android 分发目录与 zip：
  `powershell scripts\refresh-dist.ps1`（同时更新官网下载用的 Windows 包）。
- iOS：`app/ios` 工程已生成（Bundle ID `com.liangpu.liangpuapp`、显示名「良扑」、
  图标与客户端小狮子一致）。**iOS 只能在 macOS + Xcode 上编译，Windows 无法产出 ipa**。
  在 Mac 上执行：

```bash
bash scripts/build-ios-unsigned.sh
```

  会得到 `dist/liangpu-ios-0.1.0-unsigned.ipa`。未签名 IPA 不能直接装到未越狱 iPhone：
  需用 Sideloadly / AltStore 以用户自己的 Apple ID 重签名后安装，再到
  「设置 → 通用 → VPN与设备管理」信任描述文件（个人签名 7 天有效，到期需重签）。

  手边没有 Mac 时，推到 GitHub 后由 `.github/workflows/ios-unsigned.yml` 在 macOS runner
  上自动构建：Actions 页面进入「iOS 未签名包」→ Run workflow，或直接推送 `app/` 的改动。
  构建完成后 ipa 会同时挂到固定 Release（免登录下载：
  `https://github.com/wrui8/liangpu/releases/download/ios-latest/liangpu-ios-0.1.0-unsigned.ipa`）
  和该次运行的 Artifacts。下载后放回 `dist/`，再执行 `refresh-dist.ps1` 即可同步到官网下载目录。

## 安全设计

- 服务端 HTTPS-only（TLS 1.3），证书由内部 CA 签发，明文 HTTP 无法连接
- 客户端内置 CA 并只信任它（证书固定），不信任系统根证书，防中间人
- 登录态为 7 天过期的 JWT；token 不落明文：Windows 用 DPAPI，Android 用 Keystore AES/GCM
- 管理后台需信任 `ca.pem`；证书续期复用 CA，客户端无需发版
- 抓包只能看到连接的目标 IP 和端口，看不到账号、token、评分与评论内容

## 评分规则（与虎扑一致）

- 每个对象一人一票，重复打分覆盖旧分（`评分成功` / `已更新你的评分`）
- **团队分为合并平均**：团队分 = 团队直接评分 + 该团队全部员工评分（仅全局维度）的
  算术平均（每条评分计一次），给员工打分后团队分即时重算；容器启动时也会校正历史数据
- **需求评分为两个维度、互不污染**：
  - 需求自身评分：直接给需求打分，进入需求总分主体
  - 需求内成员表现分：在某个需求详情里给相关员工打分，只属于该需求，
    不写入员工全局分、不影响团队分；每个成员的平均分先算出来，再对所有成员等权平均
  - 需求总分 = 自身评分 × 70% + 成员表现分 × 30%（仅一侧有评分时取该侧），
    权重可用容器环境变量 `NEED_SELF_WEIGHT` 调整（默认 `0.7`）
  - 删除需求或把成员移出需求时，对应的维度评分与短评会一并清理并立即重算
- 分数展示保留一位小数，10 档分布以百分比展示
- 评分时可附 100 字短评，热评按点赞排序进入「亮评」
- 首页「今日热门」按评分人数排序，「团队评分」展示 10 档迷你分布与趋势图

## AI 助手（Agent）配置

- 管理后台「Agent 助手」页维护助手的名称、别名（用于评论区 `@` 识别）、头像（上传图片，
  未上传时用 emoji 兜底）、简介、问候语、快捷指令、启用开关、是否可发评论，以及
  人设 prompt / 模型名 / 温度（接入模型网关前的预留项）
- 客户端登录后、打开面板或切回前台时拉取 `GET /api/agent/meta`，管理端改完下一次拉取即生效，
  不需要重新发安装包；停用后客户端不再显示悬浮球与 `@` 入口
- 服务端只负责下发配置与保存头像（`/uploads/`），**聊天回复目前仍是客户端内置的演示脚本**，
  接入内网模型网关后再把对话与工具调用接到服务端
- 管理接口（需管理员 token）：`GET/PUT /api/admin/agent`、`POST/DELETE /api/admin/agent/avatar`

## 已实现

- 首页（热门横滑 + 团队评分卡 + c/中分类筛选）
- 团队评分（搜索 / 热度·高分·最新排序）
- 团队详情（大分数、星级、趋势/分布切换、员工网格、亮评、我要打分）
- 员工详情（所属团队、亮评、我要打分）
- 需求广场（状态筛选、支持度 / 最新发布切换排序、需求详情、相关员工、支持打分）
- 用户发布需求：登录后点需求页右上角「+」即可发布（标题、描述、分类、标签、归属团队、
  相关员工、最多 4 张配图自动压缩后上传）；发布者可在详情页编辑 / 删除自己的需求，
  配图随编辑增删自动清理；每用户每小时最多发布 5 条，离开发布页未保存会二次确认
- 需求评分维度隔离：需求详情的成员卡片展示「本需求表现分」，点击可查看主页或直接
  在该需求中评分（与员工全局分、团队分互不影响）；员工主页新增「在需求中的表现」区块，
  可按需求查看平均分、评分人数与自己打的分并跳转需求详情
- 管理后台需求列表展示首张配图缩略图（可点开大图）与「用户发布」标识
- 动态：发布文字 + 图片（最多 4 张，客户端压缩后上传），平台广场按
  `likes desc, createdAt desc` 排序，点赞 / 取消点赞 / 删除自己的动态；
  动态详情页支持评论，评论复用点赞与多层级回复体系（不打分、不显示分数标签）
- 用户主页：点击任意头像跨用户查看资料、动态数与获赞数
  （获赞 = 动态点赞 + 评论/回复点赞合计）
- 评论互动：评论与回复点赞（按登录态返回初始状态）、多层级回复（回复的回复，
  界面按根评论平铺并显示「A 回复 @B」，@ 可点进主页）、回复数统计全部后代；
  回复弹窗与打分短评支持 Enter 发送、Shift+Enter 换行
- 消息通知：评论/回复被点赞、被回复、动态被点赞、动态被评论时写入通知
  （自己操作自己不通知）；首页右上角铃铛显示未读红点，登录后 30 秒轮询、
  切回前台立即刷新；消息中心点开自动标记已读，可跳转到对应详情
- 登录 / 注册、我的（我的动态、头像池自选人像、我的评分、深色模式、服务器地址）
- 管理后台：统计、团队 / 员工 / 需求 CRUD、动态管理、图标池管理、删改级联清理
- AI 助手「小狮」：客户端悬浮球 + 迷你聊天面板 + 名片 + 评论 `@`，名称 / 形象 / 文案由
  管理后台「Agent 助手」页实时下发（对话回复暂为客户端演示脚本）
