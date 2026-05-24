# HAPI Hub Docker 部署

一键 Docker 部署 [HAPI](https://github.com/tiann/hapi) Hub，在服务器上运行 Hub，本地开发机通过 CLI 连接，手机通过 Web/PWA 远程控制。

支持 Claude Code / Codex / Cursor / Gemini / OpenCode。

---

## 目录

- [服务端部署](#服务端部署)
- [客户端配置](#客户端配置)
  - [安装 CLI](#安装-cli)
  - [连接 Hub](#连接-hub)
  - [启动 AI 会话](#启动-ai-会话)
- [开机自启 Runner](#开机自启-runner)
- [构建方式](#构建方式)
- [使用指南](#使用指南)
- [参考](#参考)

---

## 服务端部署

在服务器上执行以下步骤。

### 1. 准备

```bash
mkdir -p /opt/hapi-hub && cd /opt/hapi-hub
```

### 2. 创建 `docker-compose.yml`

```yaml
services:
  hapi-hub:
    # image: ghcr.io/arkylin/hapi-docker:latest  # 默认：从 npm 安装
    image: ghcr.io/arkylin/hapi-docker:latest     # 可选：origin（官方仓库构建）、self（fork 构建）
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

### 4. 查看日志

```bash
docker compose logs -f
```

启动后浏览器访问 `http://服务器IP:3006` 即可看到 HAPI Web 界面。

---

## 客户端配置

在本地电脑上执行。

### 安装 CLI

| 平台 | 命令 |
|------|------|
| Windows / macOS / Linux (npm) | `npm install -g @twsxtd/hapi --registry=https://registry.npmjs.org` |
| macOS (brew) | `brew install tiann/tap/hapi` |

### 连接 Hub

`hapi auth login` 只录入 token，服务器地址仍需单独配置。

**推荐方式：配置文件**

编辑 `~/.hapi/settings.json`：

```json
{
  "apiUrl": "http://服务器IP:3006",
  "cliApiToken": "你在 docker-compose.yml 里填的令牌"
}
```

然后用 `hapi auth login` 验证（或直接保存后生效）。

<details>
<summary>其他方式：交互式录入 / 环境变量</summary>

**交互式录入 token**

```bash
hapi auth login
```

按提示粘贴 CLI_API_TOKEN 即可，Token 自动保存到 settings.json。但 `HAPI_API_URL` 仍需通过配置文件或环境变量设置。

**环境变量**

Windows (PowerShell):
```powershell
$env:HAPI_API_URL="http://服务器IP:3006"
$env:CLI_API_TOKEN="你在 docker-compose.yml 里填的令牌"
```
> 将以上加入 `$PROFILE` 避免重复设置。

Windows (CMD):
```cmd
set HAPI_API_URL=http://服务器IP:3006
set CLI_API_TOKEN=你在 docker-compose.yml 里填的令牌
```

macOS / Linux:
```bash
export HAPI_API_URL="http://服务器IP:3006"
export CLI_API_TOKEN="你在 docker-compose.yml 里填的令牌"
```
> 建议写入 `~/.bashrc` 或 `~/.zshrc`。

</details>

其他命令：

```bash
hapi auth status   # 查看登录状态
hapi auth logout   # 退出登录
```

### 启动 AI 会话

```bash
hapi        # Claude Code
hapi codex  # Codex
hapi cursor # Cursor Agent
hapi gemini # Gemini
hapi opencode # OpenCode
```

会话启动后会在 Hub 注册，Web 端和手机上都能看到。

---

## 开机自启 Runner

Runner 在后台运行后，Web 端可随时创建新会话，无需保持终端打开。

### Windows

<details>
<summary>一键安装脚本（点击展开）</summary>

在 PowerShell 中执行（普通用户权限即可）：

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
}

# 如果任务已存在，先删除
$existing = Get-ScheduledTask -TaskName "HAPI Runner" -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "[信息] 发现已存在的任务，正在重新创建..." -ForegroundColor Cyan
    Unregister-ScheduledTask -TaskName "HAPI Runner" -Confirm:$false
}

$trigger = New-ScheduledTaskTrigger -AtLogon
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-WindowStyle Hidden -Command "hapi runner start"'
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 72) -MultipleInstances IgnoreNew

Register-ScheduledTask -TaskName "HAPI Runner" -Trigger $trigger -Action $action -Principal $principal -Settings $settings -Force | Out-Null
Write-Host "[成功] HAPI Runner 计划任务已创建！" -ForegroundColor Green
```

**卸载**

```powershell
Unregister-ScheduledTask -TaskName "HAPI Runner" -Confirm:$false
```

**手动控制**

```powershell
Start-ScheduledTask -TaskName "HAPI Runner"     # 启动
Get-ScheduledTask -TaskName "HAPI Runner" | Get-ScheduledTaskInfo  # 查看状态
Stop-ScheduledTask -TaskName "HAPI Runner"      # 停止
```

</details>

### Linux

<details>
<summary>systemd 用户服务（点击展开）</summary>

```bash
# 1. 创建服务文件
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/hapi-runner.service << 'EOF'
[Unit]
Description=HAPI Runner
After=network.target

[Service]
Type=forking
ExecStart=/usr/bin/hapi runner start
Restart=always
RestartSec=5
TimeoutStopSec=10

[Install]
WantedBy=default.target
EOF

# 2. 启用并启动
systemctl --user daemon-reload
systemctl --user enable hapi-runner.service
systemctl --user start hapi-runner.service

# 3. 查看状态
systemctl --user status hapi-runner.service
```

> 如果 hapi 不在 `/usr/bin/hapi`，请修改为实际路径（如 `/home/用户名/.local/bin/hapi`）。

**手动控制**

```bash
systemctl --user start hapi-runner.service    # 启动
systemctl --user stop hapi-runner.service     # 停止
systemctl --user restart hapi-runner.service  # 重启
systemctl --user disable hapi-runner.service  # 禁用开机自启
```

</details>

---

## 构建方式

以下方式按复杂度从低到高排列，日常使用推荐[默认方式](#默认方式npm)。

### 默认方式（npm）

根目录 `Dockerfile` 从 npm 安装 `@twsxtd/hapi`，无需编译：

```bash
docker compose up -d
```

### 预构建镜像

CI 自动推送的镜像，可直接替换 `docker-compose.yml` 中的 `image`：

| 标签 | 来源 | 说明 |
|------|------|------|
| `latest` | npm registry | 与默认方式等价 |
| `origin` | `tiann/hapi@main` | 官方仓库最新 main 分支编译 |
| `self` | `arkylin/hapi@self` | Fork 的 self 分支编译 |

```yaml
services:
  hapi-hub:
    image: ghcr.io/arkylin/hapi-docker:origin
    # ... 其余配置不变
```

### 本地构建 origin

从官方仓库 `tiann/hapi@main` 克隆并编译：

```bash
cd origin
./build.sh
```

编译完成后生成本地镜像 `hapi:origin`。

### 本地构建 self

从本地 `../hapi`（需提前克隆 [arkylin/hapi](https://github.com/arkylin/hapi) 的 `self` 分支并编译）复制二进制：

```bash
cd hapi
bun install
bun run build:single-exe

cd ../Hapi-Docker/self
./build.sh
```

编译完成后生成本地镜像 `hapi:self`。

### CI 自动构建

使用统一的 GitHub Actions workflow（`.github/workflows/build-and-release.yml`），手动触发时填写参数：

| 参数 | 说明 | 示例 |
|------|------|------|
| `repository` | 源码仓库 | `tiann/hapi`、`arkylin/hapi` |
| `ref` | 分支 / tag / commit | `main`、`self`、`v1.0.0` |
| `docker_tag` | Docker 镜像标签 | `origin`、`self` |
| `release_tag` | 二进制发布标签（留空则跳过） | `v1.0.0-origin` |
| `build_docker` | 是否构建并推送 Docker 镜像 | `true` / `false` |
| `release_binaries` | 是否发布二进制 | `true` / `false` |

---

## 使用指南

### 手机 / 网页端访问

- **Web**: 浏览器打开 `http://服务器IP:3006`，输入 `CLI_API_TOKEN` 登录。
- **PWA**: 浏览器地址栏点击安装图标（Chrome/Edge）或添加到主屏幕（iOS Safari / Android Chrome）。

登录后可以查看活动会话、发送消息、审批工具调用、浏览文件差异。

### 无缝切换（Seamless Handoff）

| 操作 | 效果 |
|------|------|
| 本地键入 | 终端直接输入 |
| 手机收到消息 | 自动切换到远程模式，终端显示 "Remote mode" |
| 终端按两次空格 | 切回本地模式 |

同一会话，同一状态，无需重启。

### 在 Hub 容器内启动 Runner

```bash
docker exec hapi-hub hapi runner start --foreground
```

启动后 Web 界面的 "Machines" 列表会出现这台机器，点击即可远程创建新会话。

---

## 参考

### 环境变量

| 变量 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `CLI_API_TOKEN` | 是 | - | 认证令牌，CLI 和 Web 登录使用 |
| `HAPI_PUBLIC_URL` | 否 | - | Hub 公网地址（用于 Telegram 等回调） |
| `CORS_ORIGINS` | 否 | `*` | 允许的 CORS 域名。反向代理场景下 WebSocket 终端必设 `*` |
| `TZ` | 否 | `Asia/Shanghai` | 时区 |

### 持久化数据

`./hapi-data/` 挂载到容器内 `/root/.hapi/`：

- `settings.json` — 配置文件
- `hapi.db` — SQLite 数据库

### 本地克隆仓库（可选）

```bash
git clone https://github.com/arkylin/Hapi-Docker.git
cd Hapi-Docker
# 编辑 docker-compose.yml
docker compose up -d
```
