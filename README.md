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

> `hapi auth login` 只录入 token，服务器地址仍需单独配置。

**方式一：配置文件（推荐）**

编辑 `~/.hapi/settings.json`：

```json
{
  "apiUrl": "http://服务器IP:3006",
  "cliApiToken": "你在 docker-compose.yml 里填的令牌"
}
```

然后用 `hapi auth login` 验证（或直接保存后生效）。

**方式二：交互式录入 token**

```bash
hapi auth login
```

按提示粘贴 CLI_API_TOKEN 即可，Token 自动保存到 settings.json。  
但 `HAPI_API_URL` 仍需通过方式一写入 settings.json 或通过方式三设置环境变量。

**方式三：环境变量**

<details>
<summary>Windows (PowerShell)</summary>

```powershell
$env:HAPI_API_URL="http://服务器IP:3006"
$env:CLI_API_TOKEN="你在 docker-compose.yml 里填的令牌"
```

> 将以上两行加入 `$PROFILE` 避免重复设置：
> ```powershell
> notepad $PROFILE
> ```
</details>

<details>
<summary>Windows (CMD)</summary>

```cmd
set HAPI_API_URL=http://服务器IP:3006
set CLI_API_TOKEN=你在 docker-compose.yml 里填的令牌
```
</details>

<details>
<summary>macOS / Linux</summary>

```bash
export HAPI_API_URL="http://服务器IP:3006"
export CLI_API_TOKEN="你在 docker-compose.yml 里填的令牌"
```

> 建议将这两行写入 `~/.bashrc` 或 `~/.zshrc` 避免重复设置。
</details>

其他认证命令：

```bash
hapi auth status   # 查看当前登录状态
hapi auth logout   # 退出登录
```

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

## Windows 开机自启 Runner（可选）

如果你希望每次登录 Windows 后 **Runner 自动在后台启动**（无需保持终端打开，Web 端可随时创建新会话），可以使用以下一键脚本：

### 一键安装脚本

在 PowerShell 中执行（管理员权限**不需要**，普通用户权限即可）：

```powershell
# 检查 hapi CLI 是否已安装
$hapi = Get-Command "hapi" -ErrorAction SilentlyContinue
if (-not $hapi) {
    Write-Host "[错误] 未找到 hapi CLI，请先执行：npm install -g @twsxtd/hapi" -ForegroundColor Red
    exit 1
}

# 检查 settings.json 是否已配置
$hapiHome = Join-Path $env:USERPROFILE ".hapi"
$settingsPath = Join-Path $hapiHome "settings.json"
if (-not (Test-Path $settingsPath)) {
    Write-Host "[警告] 未找到 ~/.hapi/settings.json，请先配置 Hub 连接地址和 Token" -ForegroundColor Yellow
    Write-Host "配置路径: $settingsPath" -ForegroundColor Yellow
}

# 如果任务已存在，先删除
$existing = Get-ScheduledTask -TaskName "HAPI Runner" -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "[信息] 发现已存在的 HAPI Runner 任务，正在重新创建..." -ForegroundColor Cyan
    Unregister-ScheduledTask -TaskName "HAPI Runner" -Confirm:$false
}

# 创建触发器：用户登录时触发
$trigger = New-ScheduledTaskTrigger -Logon

# 创建操作：隐藏窗口启动 runner
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument '-WindowStyle Hidden -Command "hapi runner start"'

# 创建运行主体：当前用户
$principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive

# 任务设置
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Hours 72) `
    -MultipleInstances IgnoreNew

# 注册任务
Register-ScheduledTask `
    -TaskName "HAPI Runner" `
    -Trigger $trigger `
    -Action $action `
    -Principal $principal `
    -Settings $settings `
    -Force | Out-Null

# 验证
$task = Get-ScheduledTask -TaskName "HAPI Runner" -ErrorAction SilentlyContinue
if ($task) {
    Write-Host "[成功] HAPI Runner 计划任务已创建！" -ForegroundColor Green
    Write-Host "  任务名: HAPI Runner" -ForegroundColor Gray
    Write-Host "  触发器: 用户登录时自动启动" -ForegroundColor Gray
    Write-Host "  命令  : powershell -WindowStyle Hidden -Command `"hapi runner start`"" -ForegroundColor Gray
    Write-Host "  执行  : $env:USERNAME" -ForegroundColor Gray
    Write-Host "" -ForegroundColor Gray
    Write-Host "下次登录 Windows 时 Runner 将自动启动。" -ForegroundColor Green
    Write-Host "你也可以手动启动: Start-ScheduledTask -TaskName `"HAPI Runner`"" -ForegroundColor DarkGray
} else {
    Write-Host "[失败] 任务创建失败，请检查权限或手动排查。" -ForegroundColor Red
}
```

### 卸载/移除任务

```powershell
Unregister-ScheduledTask -TaskName "HAPI Runner" -Confirm:$false
Write-Host "HAPI Runner 计划任务已删除。"
```

### 手动控制

```powershell
# 立即启动
Start-ScheduledTask -TaskName "HAPI Runner"

# 查看状态
Get-ScheduledTask -TaskName "HAPI Runner" | Get-ScheduledTaskInfo

# 停止任务（会停止 runner 进程）
Stop-ScheduledTask -TaskName "HAPI Runner"
```

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
