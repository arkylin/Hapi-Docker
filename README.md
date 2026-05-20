# HAPI Hub Docker 部署

一键 Docker 部署 [HAPI](https://github.com/tiann/hapi) Hub，支持远程访问 AI 编程助手（Claude Code / Codex / Gemini / OpenCode）。

## GHCR 镜像

每次推送 `main` 分支或 `v*` 标签时，GitHub Actions 自动构建多架构镜像（linux/amd64, linux/arm64）并推送至 GHCR：

```
ghcr.io/<你的 GitHub 用户名>/hapi-docker:main
ghcr.io/<你的 GitHub 用户名>/hapi-docker:<sha>
ghcr.io/<你的 GitHub 用户名>/hapi-docker:<tag>
```

## 快速开始

### 1. 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env`，填写必要参数。

### 2. 构建并启动

```bash
docker compose up -d
```

### 3. 查看状态

```bash
docker compose logs -f
```

### 使用预构建镜像（跳过本地构建）

编辑 `docker-compose.yml`，将 `build` 替换为 `image`：

```yaml
services:
  hapi-hub:
    image: ghcr.io/your-username/hapi-docker:main
    container_name: hapi-hub
    ...
```

然后：

```bash
docker compose pull
docker compose up -d
```

## 环境变量

| 变量 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `CLI_API_TOKEN` | 是 | - | 认证令牌，CLI 连接时使用 |
| `HAPI_PUBLIC_URL` | 否 | - | Hub 公网地址，如 `http://1.2.3.4:3006` |
| `CORS_ORIGINS` | 否 | `*` | 允许的 CORS 域名 |
| `TZ` | 否 | `Asia/Shanghai` | 时区 |

## 客户端连接

在其他机器上配置 CLI 连接：

```bash
export HAPI_API_URL="http://your-server-ip:3006"
export CLI_API_TOKEN="your-token"

hapi
```

支持 Runner 模式：

```bash
docker exec hapi-hub hapi runner start --foreground
```

## 持久化数据

Hub 数据存储在当前目录 `./hapi-data/` 中，对应容器内 `/root/.hapi/`：

- `settings.json` — 配置文件
- `hapi.db` — SQLite 数据库
