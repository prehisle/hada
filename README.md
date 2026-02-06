# HADA: High-concurrency AI Development Architecture
> 基于 Git Worktree 的单机高并发 AI 协同开发脚手架（One Human, Multiple Agents）

HADA 的目标很明确：在**一台机器**上，让你同时启动多个 AI Coding Agent 并行推进多个任务/多个项目，且做到：

- 文件系统互不干扰（每个 Agent 一个“永久环境目录”）
- 共享 Git 对象库（避免重复 clone 的磁盘/IO 浪费）
- 逻辑上都在主干开发（解决“多个目录不能同时 checkout main”的限制）

---

## 安装

在目标目录执行：

```bash
curl -fsSL https://raw.githubusercontent.com/prehisle/hada/main/scripts/install.sh | bash
```

说明：命令会下载 `main` 分支的 zip，去掉顶层目录后覆盖到当前目录（建议在一个新目录里执行）。

---

## 快速开始（面向单人多项目）

HADA 目录本身可以当作一个 workspace：把多个项目仓库放在这里，然后用 `make add/remove` 为每个项目创建并行环境。

### 1) 准备 workspace

```bash
mkdir -p ~/hada && cd ~/hada
curl -fsSL https://raw.githubusercontent.com/prehisle/hada/main/scripts/install.sh | bash
```

（可选）如果你使用 `direnv`，进入目录后执行一次：

```bash
direnv allow
```

### 2) 放入项目仓库

```bash
git clone <your-repo> project-a
```

### 3) 为项目创建一个并行环境（Worktree + Proxy 分支）

```bash
make add project-a env1
```

这会创建目录 `project-a-env1/`，并创建同名本地分支 `project-a-env1`：

- 该分支**追踪** `origin/main`（`git pull` 拉的是主干）
- 该目录会写入本地 Git 配置 `push.default=upstream`（`git push` 默认直推主干）

### 4) 给 AI Agent 的 SOP（标准作业流程）

当你把某个 Agent 指派到 `project-a-env1/` 目录时，直接给它这段即可：

1. 进入目录：`cd project-a-env1`
2. 开工前同步：`git pull`
3. 修改代码 + `git commit`
4. 推送成果：`git push`
5. 若 push 被拒（远端主干更新）：`git pull` 解决冲突后再 `git push`

### 5) 删除环境

```bash
make remove project-a env1
```

如需强制移除（会 `git branch -D` 且 `git worktree remove -f`）：

```bash
make remove project-a env1 FORCE=1
```

---

## 核心原理（Under the Hood）

本框架由三块核心拼起来：

### 1) Git Worktree（文件隔离 + 共享对象库）

- 不再 `git clone` 多份代码；所有 worktree 共享同一个 `.git` 对象数据库
- 创建新环境是毫秒级，磁盘开销主要来自你新写的文件和构建产物

### 2) Local Proxy Branch（逻辑隔离：多个目录“同时在主干”）

痛点：Git 不允许两个 worktree 同时 checkout 同一个分支名（例如 `main`）。

解法：每个环境创建一个“影子/代理分支”（例如 `project-a-env1`），但把它的上游指向 `origin/main`，并设置：

```bash
git config push.default upstream
```

效果：

- 对 Agent 来说，它在自己的目录里执行 `git pull` / `git push`，就像在主干上开发
- 当多个环境同时 push，Git 会用标准机制拒绝落后的 push，你只需要 `git pull` 解决冲突即可

### 3) 运行时隔离（可选：Docker Compose / 端口隔离）

如果你的项目用 `docker compose`，可以在每个环境目录放一份 `.env`，用不同的：

- `COMPOSE_PROJECT_NAME`
- 端口变量（例如 `APP_PORT=8081`）

这样多个环境的数据库/服务能同时运行，互不干扰。

---

## FAQ

### Q1: 为什么不让 Agent 自己 `checkout -b feature-xxx`？

你当然可以。但 HADA 更偏向 **Trunk-Based Development**：把“切分支/PR/合并”的流程成本压到最低，让并行迭代更顺滑。

### Q2: 磁盘空间真的不增加吗？

Git 历史记录几乎不增加（共享对象库）。但依赖安装目录（例如 `node_modules`、`.venv`）通常是每个环境一份；可以考虑：

- `pnpm` 共享 store
- Python 虚拟环境缓存/镜像
- 构建缓存目录挂载到公共位置

---

## 维护者提示

- 环境乱了：直接 `make remove ...` 然后重新 `make add ...`
- 更新 HADA：重新执行一次安装命令即可（会覆盖同名文件）
