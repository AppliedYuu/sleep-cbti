# 新手本地运行指南

> 本指南面向**第一次接触这个项目**的人。跟着做，10 分钟内能在你自己的电脑上把「睡眠良方 · CBT-I」跑起来。
> 官方 README 偏简略，本文件补全了新手需要的细节（依赖清单、环境要求、建库步骤、常见报错）。

---

## 0. 这是什么项目？

一个「大学生睡眠健康管理平台」：前端页面（测评、睡眠日记、干预、周报、社区）+ 后端接口 + MySQL 数据库。
数据流如下：

```
浏览器 (Vue 页面)
   │  请求 /api/xxx
   ▼
后端 (Node.js + Express，端口 3000)
   │  读写数据
   ▼
MySQL 数据库 (端口 3306，库名 sleep_cbti)
```

- 前端代码在 `client/`，后端代码在 `server/`，两个子项目各自有独立的 `package.json`。
- 后端会**自动建表和创建管理员账号**，但**不会自动建数据库**——首次运行必须先手动把 `sleep_cbti` 这个库建出来（见第 4.3 步，这是新手最容易卡住的地方）。

---

## 1. 依赖清单

### 1.1 运行环境（机器上要装的软件）

| 软件 | 版本要求 | 作用 | 是否必装 |
|---|---|---|---|
| **Node.js** | **≥ 20.19**（推荐 22 LTS 或更新） | 运行前后端代码、npm 命令 | ✅ 必装 |
| **npm** | 随 Node 自带 | 安装 JS 依赖包 | ✅ 必装 |
| **MySQL** | 8.x / MariaDB 均可 | 项目数据库 | ✅ 必装 |
| DeepSeek API Key | — | 页面里的 AI 睡眠助手 | ⭕ 可选（不配则 AI 功能不可用，其余一切正常） |

> ⚠️ **版本坑**：前端用了 Vite 8，官方要求 **Node ≥ 20.19 或 ≥ 22.12**。根目录 README 写的 "Node ≥ 18" 已经过时——装 Node 18 启动前端会直接报错。
> Windows 推荐直接装 MySQL（XAMPP 自带）：<https://www.apachefriends.org/>。本机已有 XAMPP 的忽略这条。

### 1.2 前端依赖 `client/package.json`（npm 会自动装，不用手动装）

| 包 | 版本 | 用途 |
|---|---|---|
| vue | ^3.5.38 | 前端框架 |
| vue-router | ^5.1.0 | 页面路由 |
| pinia | ^3.0.4 | 全局状态管理 |
| axios | ^1.18.0 | 调用后端接口 |
| vite | ^8.0.16 | 前端构建 / 开发服务器（devDependencies，但也直接影响能否跑起来） |
| @vitejs/plugin-vue | ^6.0.7 | Vite 解析 .vue 文件（dev） |
| @vitejs/plugin-legacy | ^8.0.2 | 兼容老浏览器（Android 5 / iOS 10）的构建插件 |
| terser | ^5.48.0 | 构建时压缩代码 |
| vitest / jsdom / @vue/test-utils | 最新 | 前端测试（可选，开发用） |

### 1.3 后端依赖 `server/package.json`

| 包 | 版本 | 用途 |
|---|---|---|
| express | ^5.2.1 | Web 服务器框架 |
| mysql2 | ^3.22.5 | 连接 MySQL、执行 SQL |
| jsonwebtoken | ^9.0.3 | 登录令牌（JWT）签发/校验 |
| bcryptjs | ^3.0.3 | 密码加密存储 |
| cors | ^2.8.6 | 跨域请求许可 |
| dotenv | ^17.4.2 | 读取 `server/.env` 配置 |
| nodemon | ^3.1.14 | 开发模式改代码自动重启（dev） |
| jest / supertest | 最新 | 后端测试（可选） |

### 1.4 首次安装全部依赖（一条命令）

项目根目录执行（会依次进入 `client/` 和 `server/` 用 `npm ci` 按锁文件安装）：

```bash
npm run install:all
```

> 提示：`npm ci` 依赖仓库里的 `package-lock.json`，装出来的版本与开发时完全一致，不会装错。

---

## 2. 需要准备的软件长什么样？

- **Node.js**：去 <https://nodejs.org> 下载 LTS 版安装。装完后打开终端（Win 按 `Win+R` 输入 `cmd` 回车），输入 `node -v` 看到版本号即成功。
- **MySQL（XAMPP）**：安装 XAMPP 后打开 **XAMPP Control Panel**（开始菜单搜索），点 MySQL 一行的 **Start** 按钮，绿色表示数据库已启动。XAMPP 的 MySQL 默认账号 `root`、**密码为空**。
  - 若你用的是独立安装的 MySQL 而非 XAMPP，记住你自己设的 root 密码，第 4.2 步要填。

---

## 3. 一分钟看懂启动逻辑

| 方式 | 干什么 | 适合谁 |
|---|---|---|
| 一键脚本 `start-server.bat` | 自动启动 MySQL + 后端，访问 :3000 | 只想看成品效果 |
| 手动生产模式 | 先构建前端再启动后端，访问 :3000 | 部署前验证 |
| **开发模式（推荐开发用）** | 后端 :3000 + 前端热更新 :5173 | 改代码调试 |

三种方式**都需要先**完成第 4.1–4.3 步（装依赖、配 .env、建数据库）。

---

## 4. 首次运行完整步骤

### 4.1 安装依赖

```bash
npm run install:all
```

### 4.2 配置后端环境变量

```bash
cd server
copy .env.example .env     # Windows
# 或 Linux/macOS: cp .env.example .env
```

用记事本打开 `server/.env`，确认这几项（其余保持默认即可）：

```ini
DB_HOST=localhost          # 数据库地址
DB_PORT=3306               # 数据库端口
DB_USER=root               # 账号（XAMPP 默认 root）
DB_PASSWORD=               # 密码（XAMPP 默认空；独立安装的填你自己的）
DB_NAME=sleep_cbti         # 库名，别改
JWT_SECRET=随便改成一长串随机字符   # 登录密钥，至少别用默认值
# DEEPSEEK_API_KEY=sk-xxx # 可选：要 AI 助手就填 DeepSeek 的 Key
```

> `.env` 已被 `.gitignore` 忽略，不会提交到仓库，放心填写。

### 4.3 创建数据库（关键一步！）

后端只会自动**建表**，不会自动**建库**。库不存在时后端启动会报 `数据库连接失败 / Unknown database 'sleep_cbti'`。

**方式 a：命令行（最快）**

先用 XAMPP 把 MySQL 启动（第 2 步），再执行：

```bash
C:\xampp\mysql\bin\mysql -u root -e "CREATE DATABASE IF NOT EXISTS sleep_cbti CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

若你的 root 有密码，加 `-p` 回车后输入密码。

**方式 b：phpMyAdmin（图形界面，适合不想敲命令的人）**

1. XAMPP Control Panel 里把 MySQL 和 Apache 都 Start；
2. 浏览器打开 <http://localhost/phpmyadmin>；
3. 左侧点「新建」，库名填 `sleep_cbti`，排序规则选 `utf8mb4_unicode_ci`，点「创建」；
4. 选中左侧的 `sleep_cbti` → 顶部「导入」→ 选择文件 `server/src/config/init.sql` → 执行。

> 两种方式任选其一即可。建好库后，后端启动时会自动执行建表 + 创建管理员账号 `admin / 123456`。

### 4.4 方式 A：一键脚本启动（Windows，最简单）

1. 确认已完成 4.1–4.3；
2. 先构建前端产物（一键脚本托管的是构建后的页面，不构建会 404）：
   ```bash
   npm run build:client
   ```
3. 双击项目根目录的 **`start-server.bat`**。

脚本会自动检测并启动 MySQL 和后端，等看到 `backend healthy` 后，浏览器打开 **http://localhost:3000**。

> ⚠️ 脚本里写死了 MySQL 路径 `C:\xampp\mysql\bin`。如果你的 XAMPP 装在其他盘（比如 D 盘），直接改脚本前两行的 `MYSQL_BIN`、`MYSQL_DATA` 路径，或改用方式 B 手动启动 MySQL。
> 停止服务：双击 `stop-all.bat`（只停 3000 和 3306，不影响其他程序）。

### 4.5 方式 B：手动生产模式（不用脚本）

```bash
# 1. 启动 MySQL：XAMPP Control Panel → MySQL → Start

# 2. 构建前端（只需做一次，之后代码不变就不用重复）
npm run build:client

# 3. 启动后端（保持窗口开着）
npm start

# 4. 浏览器打开
#    http://localhost:3000
```

看到这两行日志就是成功：

```
✅ 数据库连接成功
🚀 睡益良方 CBT-I 服务已启动 → http://localhost:3000
```

登录账号：`admin / 123456`。

### 4.6 方式 C：开发模式（前后端分离 + 热更新，改代码即时生效）

需要**两个终端窗口**：

```bash
# 终端 1：启动后端 API（nodemon 自动重启）
cd server
npm run dev

# 终端 2：启动前端开发服务器（Vite 热更新）
cd client
npm run dev
```

浏览器打开 **http://localhost:5173**（Vite 把 `/api` 请求自动转发到 3000 后端，已配好代理）。
前端文件保存即刷新，后端代码保存自动重启。**日常开发用这个方式。**

---

## 5. 怎么确认跑起来了？

| 检查项 | 命令 / 操作 | 期望结果 |
|---|---|---|
| 后端健康 | 浏览器开 `http://localhost:3000/api/health` | 返回 JSON `{"status":"ok",...}` |
| 页面 | 开 `http://localhost:3000`（生产）或 `:5173`（开发） | 看到登录页 |
| 登录 | 账号 `admin` 密码 `123456` | 进入管理后台 |
| 数据库 | phpMyAdmin 里看 `sleep_cbti` 库 | 有 users / assessments / sleep_diaries 等表 |

---

## 6. 常见问题排查

| 现象 | 原因 | 解决 |
|---|---|---|
| `❌ 数据库连接失败: Unknown database 'sleep_cbti'` | 忘了建库 | 做第 4.3 步，建好库再启动后端 |
| `Access denied for user 'root'` | .env 里密码不对 | XAMPP 默认密码留空；独立 MySQL 填你自己的 root 密码 |
| `Can't connect to MySQL server (111)` / `ECONNREFUSED 3306` | MySQL 没启动 | XAMPP Control Panel 里 Start MySQL |
| 页面能开但接口报错 / 白屏 | 端口 3000 被占用或后端起失败 | 看 `server/server.log`；`stop-all.bat` 后重试 |
| `http://localhost:3000` 打开只有 JSON 或 404 | 前端没构建 | 执行 `npm run build:client` 后再启动后端 |
| Vite 启动时报 Node 版本不支持 | Node 太老 | 装 Node 20.19+（推荐 22 LTS），重开终端 |
| `CORS 策略禁止该来源` | 用了白名单外的域名 | 前端端口必须是 5173；或给 `server/.env` 加 `CORS_ORIGINS=http://你的域名` |
| 一键脚本没反应 / 找不到 mysqld | XAMPP 不在 C 盘 | 改 `start-server.bat` 里的 `MYSQL_BIN` 路径，或用方式 B |
| AI 助手报「未配置」 | 没填 DeepSeek Key | 可选：填 `server/.env` 的 `DEEPSEEK_API_KEY` 后重启后端 |

---

## 7. 常用命令速查

```bash
npm run install:all          # 安装全部依赖
npm run build:client         # 构建前端（production 模式必需）
npm start                    # 启动后端（生产，托管前端页面）
cd server && npm run dev     # 后端开发模式（热重启）
cd server && npm test        # 后端测试
cd client && npm run dev     # 前端开发模式（热更新）
cd client && npm test        # 前端测试
```

---

## 8. 可选：后端接口不想要数据库时怎么跑测试

后端单元/接口测试不需要真实数据库（测试里会 mock），随时可跑：

```bash
cd server
npm test
```