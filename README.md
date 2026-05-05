# Dejintime.github.io

基于 [Jekyll](https://jekyllrb.com/) 的 GitHub Pages 博客。

若更想用**通俗比喻**把「镜像 / 容器 / 挂载」和日常命令串起来，可先读：[开发工作流说明.md](./开发工作流说明.md)。

## 为何使用 Docker 构建本地环境

在本仓库中，依赖由 `Gemfile` / `Gemfile.lock` 固定，需要 **Ruby 3.x** 与 **Bundler 2.6.x**（见 lock 文件末尾 `BUNDLED WITH`）。

常见本机问题：

- **macOS 自带的 Ruby 2.6** 过旧，无法安装或运行当前 lock 所需的 Bundler / Jekyll 4.3。
- 部分较新的 macOS 版本上 **Homebrew 可能暂时无法识别系统版本**，不便用 `brew install ruby` 快速升级本机 Ruby。

因此本地推荐用 **Docker**：镜像为 **`ruby:3.2-bookworm`**（在 Apple Silicon 上使用 **原生 linux/arm64**，避免使用仅 amd64 的旧版 `jekyll/jekyll` 镜像在模拟架构下崩溃）。

Gem 统一安装到项目目录下的 **`vendor/bundle`**（已在 `.gitignore` 中忽略），与宿主机 Ruby 互不干扰。

## 前置条件

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)（或兼容的 Docker 引擎）
- 可选：[VS Code](https://code.visualstudio.com/) + [Dev Containers 扩展](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)，用于在容器内开发

## 使用 Docker 构建与运行环境的详细说明

下面按「镜像怎么来的」「容器起来后发生什么」「和本机目录如何对应」三部分说明。

### 1. 整体思路

- **镜像（Image）**：只负责提供「对的」操作系统 + Ruby + 编译工具 + Bundler，**不把整站代码 bake 进镜像**（代码通过卷挂载进容器，改代码立刻生效）。
- **容器（Container）**：每次 `docker compose up` 时，在镜像之上启动一个进程空间，在 `/srv/jekyll` 里执行 `bundle install` 和 `jekyll serve`。
- **卷（Volume）**：把**你 Mac 上的项目根目录**挂到容器里的 `/srv/jekyll`，这样 `_posts`、`_config.yml` 等和宿主机是同一份文件。

可以理解为：**Ruby 环境在 Linux 容器里，博客源码仍在你的磁盘上，两者通过挂载目录拼在一起。**

### 2. `Dockerfile` 在做什么（构建镜像）

执行 `docker compose build`（或第一次 `docker compose up` 若需先构建）时，Docker 会按 `Dockerfile` 自上而下执行指令，生成一层层文件系统：

| 步骤 | 指令含义 |
|------|----------|
| 基础系统 | `FROM ruby:3.2-bookworm`：以官方 **Ruby 3.2 + Debian Bookworm** 为基础镜像，多架构（含 **arm64**），与 Apple Silicon 匹配时走原生 Linux，不做 x86 模拟。 |
| 系统依赖 | `apt-get install …`：安装编译 **含 C 扩展的 gem**（如 `eventmachine`、`json`、`sass-embedded` 等）所需的头文件与工具链，例如 `build-essential`、`zlib1g-dev` 等。装完后删除 apt 缓存以减小镜像体积。 |
| Bundler 版本 | `gem install bundler -v 2.6.7`：与 `Gemfile.lock` 里 `BUNDLED WITH` 一致，避免本机 Bundler 与 lock 不匹配。 |
| 工作目录 | `WORKDIR /srv/jekyll`：之后容器内默认在此目录执行命令（与 Compose 挂载目标一致）。 |
| 入口脚本 | `COPY docker-entrypoint.sh` + `chmod`：把启动脚本放进镜像并赋予执行权限。 |
| 默认行为 | `ENTRYPOINT` + `CMD ["serve"]`：容器启动时先跑入口脚本；未额外指定命令时，等价于执行 `serve`（即启动 Jekyll 预览）。 |

**注意**：镜像构建阶段**没有**执行 `bundle install` 安装项目 gem。原因是 `Gemfile` 随你开发会改，且 gem 应落在挂载目录下的 `vendor/bundle`，便于复用与清理；若把 `bundle install` 写死在镜像构建里且再挂载宿主机目录，容易和「宿主机上的 lock / vendor」逻辑打架。因此依赖安装放在**容器每次启动时的入口脚本**里（见下一节）。

### 3. `docker-compose.yml` 与运行时行为

```yaml
services:
  jekyll:
    build: .
    ports:
      - "4000:4000"
    volumes:
      - .:/srv/jekyll
    command: ["serve", "--livereload"]
```

- **`build: .`**：在当前目录（博客根目录）找 `Dockerfile` 构建服务所用镜像。
- **`volumes: - .:/srv/jekyll`**：绑定挂载——宿主机的**当前目录**映射为容器内 `/srv/jekyll`。你在编辑器里保存的 Markdown、SCSS 等，容器内立刻可见；Jekyll 生成的 `_site` 也会写回宿主机（便于排查构建结果）。
- **`ports: "4000:4000"`**：把容器内 Jekyll 监听的 **4000** 转到本机 **4000**，浏览器访问 `http://localhost:4000` 即可。
- **`command: ["serve", "--livereload"]`**：覆盖镜像默认的 `CMD`，把参数传给 `ENTRYPOINT`。最终由入口脚本解析为：先装依赖，再执行 `jekyll serve …`，并带上 LiveReload 相关参数。

### 4. `docker-entrypoint.sh` 执行顺序

容器的主进程会执行该脚本，逻辑可以概括为：

1. `cd /srv/jekyll`（即挂载后的项目根）。
2. `bundle config set --local path vendor/bundle`：告诉 Bundler **把 gem 安装到项目内的 `vendor/bundle`**，而不是装进镜像的全局 Ruby 目录。这样：
   - 依赖落在**你磁盘上**（与挂载一致），下次起容器可复用，不必每次全量下载；
   - `.gitignore` 已忽略 `vendor/`，不会误提交大量二进制。
3. `bundle install`：按 `Gemfile.lock` 解析并安装/校验版本。
4. 根据第一个参数分支：
   - `serve` → `bundle exec jekyll serve --host 0.0.0.0 --force_polling`（`0.0.0.0` 保证端口在容器内可从宿主机访问；`force_polling` 在部分挂载文件系统上更可靠地检测文件变化）。
   - `build` → `bundle exec jekyll build`。
   - 其他 → 透传为 `bundle exec jekyll <子命令>`。

因此 **`docker compose run --rm jekyll build`** 会走 `build` 分支，只做静态构建。

### 5. 与 Dev Container 的关系

`.devcontainer/devcontainer.json` 里配置了 **`build.dockerfile` 指向仓库根目录的 `Dockerfile`**，与 Compose **共用同一套环境定义**，避免「容器里一套 Ruby、Compose 里另一套」的分裂。

区别仅在于：

- **Compose**：侧重一条命令起预览服务（`docker compose up`）。
- **Dev Container**：在编辑器里打开远程开发，容器创建后执行 `postCreateCommand` 做一次 `bundle config` + `bundle install`；你在集成终端里自己跑 `jekyll serve` 或调试即可。

### 6. 常见操作与排错提示

- **改动了 `Dockerfile`**：需要 `docker compose build --no-cache`（或至少 `docker compose build`）重新构建镜像。
- **改动了 `Gemfile` / `Gemfile.lock`**：一般只需重启容器（或再执行一次 `bundle install`）；若依赖解析异常，可删除本地 `vendor/bundle` 后重新 `docker compose up` 让脚本重新安装。
- **端口被占用**：修改 `docker-compose.yml` 里左侧宿主机端口，例如 `"4001:4000"`，然后访问 `http://localhost:4001`。
- **Apple Silicon 上不要用仅 amd64 的旧 Jekyll 官方镜像硬跑**：模拟层下 native 扩展（如 sass）易崩溃；本仓库选用 **多架构的 `ruby:3.2-bookworm`** 正是为了避免这类问题。

## 常用启动命令

在仓库根目录（本文件所在目录）执行：

### 本地预览（开发最常用）

```bash
docker compose up
```

浏览器访问：**http://localhost:4000/**

默认会启用 **LiveReload**（`--livereload`）。若浏览器自动刷新异常，可在 `docker-compose.yml` 中为服务增加 `35729:35729` 端口映射后再试。

停止服务：在运行 `docker compose up` 的终端按 `Ctrl+C`，或另开终端执行：

```bash
docker compose down
```

### 仅生成静态站点（不启动服务）

```bash
docker compose run --rm jekyll build
```

生成结果在 `_site/` 目录。

### 进入容器 Shell（调试依赖）

```bash
docker compose run --rm jekyll sh
```

进入后工作目录为 `/srv/jekyll`，可手动执行 `bundle exec jekyll …` 等命令。

### 首次构建镜像

```bash
docker compose build
```

修改 `Dockerfile` 后需要重新执行上述命令。

## Dev Container（在 Cursor / VS Code 里开发）

仓库内含 `.devcontainer/devcontainer.json`：

- 使用项目根目录的 **`Dockerfile`** 构建开发环境（Ruby 3.2 + 编译依赖 + Bundler 2.6.7）。
- 创建容器后会执行：`bundle config set --local path vendor/bundle && bundle install`。
- 转发端口 **4000**。

在编辑器中选择 **「在 Dev Container 中重新打开」** 后，在集成终端中可执行：

```bash
bundle exec jekyll serve --host 0.0.0.0
```

（若未自动打开端口，请确认已转发 4000。）

## 与本机 Ruby 的关系（可选）

若你本机已安装 **Ruby 3.2+** 且 `gem install bundler -v 2.6.7` 可用，也可不使用 Docker，在仓库根目录执行：

```bash
bundle config set --local path vendor/bundle
bundle install
bundle exec jekyll serve
```

在 Apple Silicon 上请勿依赖 **仅 amd64** 且需 QEMU 模拟的 Jekyll 镜像做日常开发，易出现进程异常退出。

## 仓库内相关文件

| 文件 | 说明 |
|------|------|
| `Dockerfile` | 开发/预览用 Ruby 3.2 镜像定义 |
| `docker-compose.yml` | 一键 `jekyll serve` 与卷挂载 |
| `docker-entrypoint.sh` | 容器入口：`bundle install` + 子命令 `serve` / `build` |
| `.devcontainer/devcontainer.json` | Dev Container 配置 |
| `Gemfile` / `Gemfile.lock` | Ruby 依赖锁定 |
