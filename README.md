# HAPI Hub Docker 部署

一键 Docker 部署 [HAPI](https://github.com/tiann/hapi) Hub，支持远程访问 AI 编程助手（Claude Code / Codex / Gemini / OpenCode）。

## GHCR 镜像

```
ghcr.io/arkylin/hapi-docker:latest
```

## 快速开始

### 1. 准备目录

```bash
mkdir hapi-hub && cd hapi-hub
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
      - CLI_API_TOKEN=你的令牌
      - HAPI_LISTEN_HOST=0.0.0.0
      - HAPI_LISTEN_PORT=3006
      - HAPI_PUBLIC_URL=http://你的服务器IP:3006
```

### 3. 启动

```bash
docker compose up -d
```

### 4. 查看日志

```bash
docker compose logs -f
```

浏览器打开 `http://你的服务器IP:3006` 即可看到 HAPI Web 界面。

## 环境变量

| 变量 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `CLI_API_TOKEN` | 是 | - | 认证令牌，CLI 连接时使用 |
| `HAPI_PUBLIC_URL` | 否 | - | Hub 公网地址 |
| `CORS_ORIGINS` | 否 | `*` | 允许的 CORS 域名 |
| `TZ` | 否 | `Asia/Shanghai` | 时区 |

## 客户端连接

在其他需要远程控制的机器上：

```bash
export HAPI_API_URL="http://你的服务器IP:3006"
export CLI_API_TOKEN="你的令牌"
hapi
```

## Runner 模式

在 Hub 容器内启动后台 Runner，支持远程拉起新会话：

```bash
docker exec hapi-hub hapi runner start --foreground
```

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
