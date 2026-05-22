# HAPI Hub Docker 部署

一键 Docker 部署 [HAPI](https://github.com/tiann/hapi) Hub，在服务器上运行 Hub，本地开发机通过 CLI 连接，手机通过 Web/PWA 远程控制。

支持 Claude Code / Codex / Cursor / Gemini / OpenCode。

---

## 服务端部署（在服务器上执行）

### 1. 准备

```bash
mkdir -p /opt/hapi-hub && cd /opt/hapi-hub
```

### 2. 创建 `docker-compose.yml`

```yaml
services:
  hapi-hub:
    image: ghcr.io/arkylin/hapi-docker:latest
    container_name: hapi-hub
    restart: unless-stopped
    ports:
      - "3006:3006"
    volumes:
      - ./hapi-data:/root/.hapi
    environment:
      - CLI_API_TOKEN=这里填一个只有你知道的随机字符串
      - HAPI_LISTEN_HOST=0.0.0.0
      - HAPI_LISTEN_PORT=3006
      - CORS_ORIGINS=*
```

> 如果使用 nginx 反向代理，必须设置 `CORS_ORIGINS=*`，否则 Web 终端（Socket.IO WebSocket）会因 CORS 校验失败返回 403。

### 3. 启动

```bash
docker compose up -d
```

### 4. 查看日志（确认启动成功）

```bash
docker compose logs -f
```

启动后浏览器访问 `http://服务器IP:3006` 即可看到 HAPI Web 界面。

---

## 本地开发机配置（在本地电脑上执行）

### 1. 安装 HAPI CLI

**Windows (npm):**

```powershell
npm install -g @twsxtd/hapi --registry=https://registry.npmjs.org
```

**macOS / Linux:**

```bash
npm install -g @twsxtd/hapi --registry=https://registry.npmjs.org
# 或
brew install tiann/tap/hapi
```

### 2. 配置连接 Hub

**Windows (PowerShell):**

```powershell
$env:HAPI_API_URL="http://服务器IP:3006"
$env:CLI_API_TOKEN="你在 docker-compose.yml 里填的令牌"
```

> 将以上两行加入 `$PROFILE`（PowerShell 配置文件）避免重复设置：
> ```powershell
> notepad $PROFILE
> ```

**Windows (CMD):**

```cmd
set HAPI_API_URL=http://服务器IP:3006
set CLI_API_TOKEN=你在 docker-compose.yml 里填的令牌
```

**macOS / Linux:**

```bash
export HAPI_API_URL="http://服务器IP:3006"
export CLI_API_TOKEN="你在 docker-compose.yml 里填的令牌"
```

> 建议将这两行写入 `~/.bashrc` 或 `~/.zshrc` 避免重复设置。

### 3. 启动 AI 会话

```bash
# Claude Code
hapi

# Codex
hapi codex

# Cursor Agent
hapi cursor

# Gemini
hapi gemini

# OpenCode
hapi opencode
```

会话启动后，会在 Hub 注册，Web 端和手机上都能看到。

---

## 手机 / 网页端访问

### Web

浏览器打开 `http://服务器IP:3006`，输入 `CLI_API_TOKEN` 登录。

### PWA（添加到桌面）

**Android (Chrome):** 底部弹出 "Install HAPI" 横幅 → 点击安装。  
**iOS (Safari):** 分享按钮 → "添加到主屏幕"。  
**Desktop (Chrome/Edge):** 地址栏安装图标 (⊕)。

登录后即可在手机上：

- 查看所有活动会话
- 发送消息给 AI
- 审批工具调用请求（文件读写、命令执行等）
- 浏览文件差异

---

## Runner 模式（远程拉起新会话）

在 Hub 容器内启动 Runner，就可以从 Web 端直接创建新会话，无需保持终端打开：

```bash
docker exec hapi-hub hapi runner start --foreground
```

启动后 Web 界面的 "Machines" 列表会出现这台机器，点击即可远程创建新会话。

---

## Seamless Handoff（无缝切换）

- **本地键入** = 终端直接输入
- **手机收到消息** = 自动切换到远程模式，终端显示 "Remote mode"
- **终端按两次空格** = 切回本地模式

同一会话，同一状态，无需重启。

---

## 环境变量

| 变量 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `CLI_API_TOKEN` | 是 | - | 认证令牌，CLI 和 Web 登录使用 |
| `HAPI_PUBLIC_URL` | 否 | - | Hub 公网地址（用于 Telegram 等回调） |
| `CORS_ORIGINS` | 否 | `*` | 允许的 CORS 域名。反向代理（如 nginx）场景下 WebSocket 终端必设 `*` |
| `TZ` | 否 | `Asia/Shanghai` | 时区 |

## 持久化数据

`./hapi-data/` 挂载到容器内 `/root/.hapi/`：

- `settings.json` — 配置文件
- `hapi.db` — SQLite 数据库

## 本地构建（可选）

```bash
git clone https://github.com/arkylin/Hapi-Docker.git
cd Hapi-Docker
# 编辑 .env
docker compose up -d
```
