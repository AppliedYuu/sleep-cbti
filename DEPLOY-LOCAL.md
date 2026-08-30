# 部署指南：GitHub Pages 前端 + 本地电脑后端 + 自有域名

> 目标架构：**页面放 GitHub Pages（HTTPS 免费），后端和数据库继续跑在你自己的电脑上**，用你自己的域名 `appliedyu.cn` 对外提供服务。
> 已为你确认的选型：后端用 **Cloudflare 免费隧道**暴露（不需要公网 IP、不用改路由器）；`appliedyu.cn` 直接作为页面主域名，`api.appliedyu.cn` 作为后端接口域名。

```
浏览器
  │  https://appliedyu.cn         https://api.appliedyu.cn
  ▼                                ▼
GitHub Pages（静态前端）      Cloudflare 隧道（免费 HTTPS）
  │                                │  经 cfargotunnel.com CNAME
  ▼                                ▼
  └────────── 你家里的电脑 ←───────┘
                    │  后端 Node.js :3000
                    ▼
                MySQL :3306（XAMPP）
```

为什么必须用隧道：GitHub Pages 强制 HTTPS，而你电脑上的后端是裸 HTTP。HTTPS 页面直接请求 HTTP 接口会被浏览器判定为「混合内容」直接拦截，所以后端必须也走 HTTPS——Cloudflare 隧道免费帮你搞定，顺带解决了家宽动态 IP 和「运营商封 80/443 端口」两个问题。

---

## 域名分配（最终效果）

| 域名 | 指向 | 用途 |
|---|---|---|
| `appliedyu.cn` | GitHub Pages（4 条 A 记录） | 前端页面 |
| `api.appliedyu.cn` | Cloudflare 隧道（CNAME） | 后端接口 |
| `www.appliedyu.cn`（可选） | `AppliedYuu.github.io`（CNAME） | 顺手加一条备用 |

---

## 第 0 步：确认前置条件

- [x] GitHub 仓库 `AppliedYuu/sleep-cbti`（master 分支）——已有，且 Pages 流水线已配好
- [x] 腾讯云域名 `appliedyu.cn`，能登录 DNSPod 控制台——你有
- [ ] 注册一个免费 **Cloudflare** 账号（<https://dash.cloudflare.com>，邮箱注册即可）——需要你注册
- [x] 电脑上：Node、MySQL（XAMPP）、项目代码——都齐了

---

## 第 1 步：让 `api.appliedyu.cn` 隧道指向你的电脑

### 1.1 安装 cloudflared（Windows）

任选其一：

```powershell
# 方式一：winget（简单）
winget install --id Cloudflare.cloudflared

# 方式二：手动
# 去 https://github.com/cloudflare/cloudflared/releases
# 下载 cloudflared-windows-amd64.exe，改名为 cloudflared.exe，
# 放到 C:\cloudflared\ 文件夹
```

验证安装：新开终端执行 `cloudflared --version`。

### 1.2 创建隧道

1. 登录 <https://dash.cloudflare.com>；
2. 左侧进 **Zero Trust**（首次会引导你选计划，选免费 Free 即可）→ **Networks → Tunnels**；
3. 点 **Create a tunnel** → 选 **Cloudflared** → 命名（比如 `sleep-local`）；
4. 页面会给出**安装连接器**的命令（形如 `cloudflared service install <TOKEN>`）：
   - 用**管理员** PowerShell 执行这条命令 → 它会把隧道注册成 Windows 服务，电脑开机自启（推荐）；
   - 或者想先试跑：直接执行 `cloudflared tunnel run <TOKEN>`，保持窗口开着；
5. 回到页面点 **Next**，在 **Public Hostname** 里添加：
   - Subdomain: `api`，Domain: `appliedyu.cn`，Service: **HTTP**，URL: `localhost:3000`；
6. 保存。页面会显示一条 CNAME 记录提示：`api.appliedyu.cn → <隧道ID>.cfargotunnel.com` ——把这条记下来，第 2 步要用。

> 说明：用 Zero Trust 的隧道**不需要**把域名托管到 Cloudflare，你继续用腾讯云的 DNS，只加一条 CNAME 过去即可（cfargotunnel.com 是 Cloudflare 全球节点，哪家 DNS 都能指）。

### 1.3 立即验证隧道（先不依赖域名）

页面 Public Hostname 配好、连接器在线后，可以先试临时地址确认后端被成功暴露（可选）：

```powershell
curl https://api.appliedyu.cn/api/health
```

（此时域名 DNS 还没加，会失败属正常——先继续第 2 步，第 3 步加完 DNS 再回来验证。）

---

## 第 2 步：腾讯云（DNSPod）加 DNS 记录

登录 <https://console.cloud.tencent.com/dns>（或 dnspod.cn）→ 选择 `appliedyu.cn` → **添加记录**：

| 主机记录 | 记录类型 | 记录值 | 说明 |
|---|---|---|---|
| `@` | A | `185.199.108.153` | GitHub Pages 四个 IP 之一，4 条都要加 |
| `@` | A | `185.199.109.153` | |
| `@` | A | `185.199.110.153` | |
| `@` | A | `185.199.111.153` | |
| `api` | CNAME | `<隧道ID>.cfargotunnel.com` | 指向 Cloudflare 隧道（替换成你第 1.2 步记下的真实 ID） |
| `www`（可选） | CNAME | `AppliedYuu.github.io` | 备用，不加也不影响 |

保存后，用 <https://dnschecker.org> 查询或直接命令行验证：

```powershell
Resolve-DnsName appliedyu.cn
Resolve-DnsName api.appliedyu.cn
```

DNS 生效一般几分钟（腾讯云默认 TTL 600s；本机 DNS 缓存可用 `ipconfig /flushdns` 刷新）。

---

## 第 3 步：GitHub Pages 绑定自定义域名

1. 打开 GitHub 仓库 **Settings → Pages**；
2. 确认 **Build and deployment → Source** 是 **GitHub Actions**（仓库已配好流水线，无需改）；
3. 在 **Custom domain** 填入 `appliedyu.cn` → **Save**；
4. 等 DNS 校验通过、HTTPS 证书自动签发（通常几分钟，偶尔要等半小时到几小时）；
5. 证书就绪后勾选 **Enforce HTTPS**。

> 顺序提醒：最好**先加 DNS A 记录（第 2 步）再填自定义域名**，否则 GitHub 校验不过。

---

## 第 4 步：电脑端准备后端

仓库里的 `docs/api-config.json` 已改为 `{"apiBase": "https://api.appliedyu.cn/api"}`（前端页面启动时会读取它，把接口请求发到 `api.appliedyu.cn`，不用改代码）。

本地 `server/.env` 已加好（无需重复操作）：

```ini
# 允许 GitHub Pages 自定义域跨域访问后端
CORS_ORIGINS=https://appliedyu.cn,https://www.appliedyu.cn
```

上线前建议再检查两处（一旦隧道开通，你的后端就暴露在公网上了）：

1. **JWT_SECRET**：换成一长串随机字符（现在用的是开发值）；
2. **管理员密码**：`admin / 123456` 是公开默认值，知道的人都能登录后台。建议登录后到库里/注册页改掉，或后续加 Cloudflare Access 保护。

然后启动（保持运行）：

```bash
# 1) XAMPP Control Panel → MySQL → Start
# 2) 启动后端（任选）：
npm start                # 生产模式；或
double-click start-server.bat
```

本机自检：浏览器打开 `http://localhost:3000/api/health`，应返回 `{"status":"ok",...}`。

---

## 第 5 步：推送前端配置，触发 GitHub Pages 发布

在前端 `docs/` 里改的是 `api-config.json`，推送到 master 就会自动触发流水线（约 1 分钟发布）。

```bash
git add docs/api-config.json
git commit -m "chore: 前端接口指向 api.appliedyu.cn"
git push origin master
```

去 GitHub **Actions** 页确认 **Deploy to GitHub Pages** 变绿。

---

## 第 6 步：按顺序验证

| # | 操作 | 期望 |
|---|---|---|
| 1 | 电脑端 `http://localhost:3000/api/health` | `{"status":"ok",...}` |
| 2 | `https://api.appliedyu.cn/api/health`（手机流量也行） | 同上 → 说明隧道 + DNS + 后端全通 |
| 3 | 浏览器开 `https://appliedyu.cn` | 登录页 |
| 4 | 登录 `admin / 123456` | 进入首页 |
| 5 | 随便填一份睡眠测评并提交 | 数据落本地 MySQL（phpMyAdmin 里 `sleep_cbti` 库可查到） |
| 6 | 关掉电脑 WiFi，用手机流量再开 `https://appliedyu.cn` | 说明公网可用 |

---

## 日常使用 & 停机

- **要对外可用**，电脑必须同时满足：开机 + MySQL 运行 + 后端运行 + cloudflared 运行（用 `cloudflared service install` 装了服务的话开机自启，前两个仍需手动）。
- 全部停止：双击 `stop-all.bat`；隧道停止：管理员终端 `sc stop cloudflared`（或直接关掉前台窗口）。
- 前端以后改了代码：`npm run build:client` 后把 `client/dist/` 里的内容**覆盖**到 `docs/`，**并重新写一次 `docs/api-config.json`**（构建不会生成它，是手动维护的文件），再提交推送。

---

## 常见问题

| 现象 | 原因 | 解决 |
|---|---|---|
| `appliedyu.cn` 打不开 | DNS 还没生效 / Pages 证书未签发 | 查 <https://dnschecker.org>；等几分钟到半小时再试 |
| `api.appliedyu.cn` 超时 | 电脑关 / 后端没跑 / 隧道断了 | 先查本机 `:3000/api/health`；再 `cloudflared tunnel list` 看连接器在线状态 |
| 页面能开，登录/接口全部 401 或 CORS 报错 | 后端没加载新的 `CORS_ORIGINS` | 改了 `.env` 后**必须重启后端**才生效 |
| 控制台报 Mixed Content | 有人把 apiBase 写成了 http | 正常配置下两端都是 https，不会出现 |
| 接口 404 | `api-config.json` 没生效 | F12 → Network 看请求 URL 前缀是不是 `https://api.appliedyu.cn/api` |
| GitHub Actions 失败 | docs 目录有问题 | 看 Actions 日志；确认 `docs/index.html` 存在 |

---

## 以后想换成云服务器？

整个架构只有两处要动，前端和域名逻辑完全不变：

1. 云 MySQL：后端 `.env` 改用 `DATABASE_URL=mysql://...`（去掉本地 DB_*）；
2. 把 `api.appliedyu.cn` 的 CNAME 从隧道改为指向云服务器（或配好服务器后再删隧道）；
3. 后端代码原样部署到服务器上即可（参考 `DEPLOYMENT-PLAN.md`）。

---

## 安全提醒（重要）

隧道开通后，`api.appliedyu.cn` 是**全世界可访问**的：

- 任何访客都能调 `/api/auth/register` 注册账号——对试用阶段可接受；
- `/api/ai`（DeepSeek 问答）会消耗你在 `.env` 里配的 API Key 额度；
- 如需收紧，免费方案：Zero Trust → **Access** 应用策略，把 `/api/` 后面的管理端路径保护起来（免费 50 人内）；或在下个阶段直接换云服务器 + 云防火墙。