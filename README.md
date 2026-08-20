# 睡眠良方 · 大学生 CBT-I 数字疗法助手

面向大学生的睡眠健康管理平台，基于 **认知行为疗法（CBT-I）** 提供睡眠评估、睡眠日记、个性化干预、周报与社区功能。

## 技术栈

| 端 | 技术 |
|---|---|
| 前端 `client/` | Vue 3 · Vite · Pinia · Vue Router |
| 后端 `server/` | Node.js · Express 5 · MySQL (mysql2) · JWT |
| AI 助手 | DeepSeek API（可选） |
| 移动端 `android/` | Capacitor 8（Android 原生壳） |
| 部署 | Railway（后端）+ GitHub Pages（`docs/` 前端静态站） |

## 目录结构

```
client/          前端源码（Vue 3）
  src/           页面 / 组件 / 路由 / 状态
  public/        静态资源
server/          后端源码（Express）
  src/           路由 / 控制器 / 服务 / 中间件
  src/config/    数据库连接与量表配置（init.sql）
android/         Capacitor Android 原生工程
docs/            GitHub Pages 部署产物（由构建生成）
```

## 快速开始

需要 Node.js ≥ 18。

```bash
# 1. 安装依赖
npm run install:all

# 2. 配置后端环境变量
cp server/.env.example server/.env
#    编辑 server/.env，填写数据库连接与 JWT 密钥

# 3. 初始化数据库
#    执行 server/src/config/init.sql（见文件内注释）

# 4. 生成客户端 API 地址配置
#    client/public/api-config.json：{"apiBase": "http://localhost:3000/api"}

# 5. 启动后端（前端可在浏览器直接访问 dev server）
npm start
# 前端开发模式（可选）：
cd client && npm run dev
```

## 可用脚本

| 命令 | 说明 |
|---|---|
| `npm start` | 启动后端（生产模式同时托管前端构建产物） |
| `npm run build:client` | 构建前端 |
| `npm run install:all` | 安装前后端依赖 |
| `cd server && npm test` | 运行后端测试（Jest + supertest） |
| `cd client && npm run dev` | 前端开发服务器 |

## 主要功能模块

- **睡眠评估**：PSQI / SHPS / DBAS-16 三大量表在线测评与自动计分
- **睡眠日记**：记录上床/熄灯/入睡/夜醒等，自动计算睡眠效率
- **CBT-I 干预**：睡眠限制、刺激控制、认知重塑、放松训练、睡眠卫生
- **周报**：周睡眠数据汇总与趋势
- **成就体系**：连续记录 / 达标等徽章
- **AI 助手**：基于 DeepSeek 的睡眠答疑（需配置 API Key）

## 部署

- **后端**：`railway.json` 配置 Railway 部署；数据库使用云 MySQL（`DATABASE_URL`）。敏感值请通过平台环境变量 / Secret 注入，不要写进仓库。
- **前端站点**：`.github/workflows/deploy.yml` 将 `docs/` 发布到 GitHub Pages。

## 安全约定

- `server/.env` 已被 `.gitignore` 忽略，切勿提交真实密钥。
- 部署密钥（数据库密码、JWT、AI Key）一律使用平台 Secret 注入。
- 若历史提交中曾泄露过密钥，请务必在相关平台**轮换**这些凭据。

## 测试

```bash
cd server && npm test        # 后端单元/接口测试
cd server && npm run test:coverage
```

> 注：`client/public/sleep-h5` 目前为空目录，测评页 iframe 引用的独立 H5 子应用源码已不在仓库（如需可自 `git` 历史找回）。
