---
layout: post
title: "Vibe Coding 入门：用 AI 加速你的开发工作流"
date: 2026-02-21
categories: tools
---

> **Vibe Coding** 是一种以 AI 为核心驱动力的编程方式——你描述你的意图，AI 帮你把想法变成代码。它不是偷懒，而是让你更专注于解决问题本身，而不是被语法和样板代码拖累。

---

## 一、安装 GitHub Copilot CLI

Copilot CLI 是 GitHub Copilot 的命令行扩展，让你可以在终端中直接用自然语言提问和执行命令，是 Vibe Coding 工作流中不可或缺的利器。

### 前置条件

- Node.js >= 18
- 已订阅 GitHub Copilot（免费版或付费版均可）

### 安装步骤

**第一步：安装 GitHub CLI**

```bash
# macOS (Homebrew)
brew install gh

# Linux (Debian/Ubuntu)
sudo apt install gh

# Windows
winget install GitHub.cli
```

**第二步：登录并启用 Copilot 扩展**

```bash
# 登录 GitHub
gh auth login

# 安装 Copilot CLI 扩展
gh extension install github/gh-copilot
```

**第三步：验证安装**

```bash
gh copilot --version
```

### 核心命令速查

| 命令 | 用途 |
|------|------|
| `gh copilot suggest "..."` | 将自然语言转换为 Shell 命令 |
| `gh copilot explain "..."` | 解释一条命令的含义 |

**示例：**

```bash
# 让 Copilot 帮你找出占用磁盘最多的目录
gh copilot suggest "找出当前目录下体积最大的10个文件夹"

# 让 Copilot 解释一条你看不懂的命令
gh copilot explain "find . -name '*.log' -mtime +7 -exec rm {} \;"
```

---

## 二、Vibe Coding 核心工具链

一套完整的 Vibe Coding 工作流通常由以下几类工具组成：

### 1. IDE 内 AI 助手

**GitHub Copilot (VS Code)**
- 代码自动补全，支持上下文感知
- `Ctrl+I` 唤起 Inline Chat，直接用中文描述修改意图
- Copilot Chat 侧边栏，适合多轮对话式开发

```
# 在编辑器中的使用技巧
1. 写注释描述函数功能，Copilot 自动补全实现
2. 选中代码块 → Ctrl+I → 输入 "重构这段代码，提升可读性"
3. 在聊天框输入 "/fix" 自动修复报错
```

### 2. AI 驱动的代码编辑器

| 工具 | 特点 | 适合场景 |
|------|------|----------|
| **Cursor** | 基于 VS Code，深度集成 Claude/GPT | 大规模代码重构 |
| **Windsurf** | Cascade 多步骤任务执行 | 需要 AI 完成完整功能 |
| **VS Code + Copilot** | 生态完善，插件丰富 | 日常开发首选 |

### 3. 终端与命令行工具

```bash
# 用 Copilot CLI 生成复杂的 Git 命令
gh copilot suggest "将过去7天所有 feat 开头的 commit 合并为一个"

# 用 Copilot CLI 生成 Docker 命令
gh copilot suggest "运行一个 nginx 容器，将本地 ./html 目录挂载到默认网站目录"
```

---

## 三、Vibe Coding 实战教程

### 教程一：从零搭建一个 Jekyll 博客

这个博客本身就是 Vibe Coding 的成果！以下是整个流程：

**1. 描述需求，生成框架**

在 Copilot Chat 中输入：
```
帮我基于 Jekyll 设计一个学术风格的个人主页，
要求左侧固定导航栏，右侧内容区，支持博客功能
```

**2. 逐步填充内容**

```
把 index.html 中的占位符替换为真实的教育背景和研究方向
```

**3. 调试样式**

```
导航栏在移动端显示时被内容遮挡，帮我修复这个 CSS bug
```

### 教程二：用 AI 辅助写代码注释和文档

```python
# 原始代码（没有注释）
def dijkstra(graph, start):
    dist = {node: float('inf') for node in graph}
    dist[start] = 0
    pq = [(0, start)]
    while pq:
        d, u = heapq.heappop(pq)
        if d > dist[u]:
            continue
        for v, w in graph[u]:
            if dist[u] + w < dist[v]:
                dist[v] = dist[u] + w
                heapq.heappush(pq, (dist[v], v))
    return dist
```

在 VS Code 中选中这段代码，按 `Ctrl+I` 输入"为这个函数添加详细的中文文档注释"，Copilot 会自动生成：

```python
def dijkstra(graph: dict, start: str) -> dict:
    """
    使用 Dijkstra 算法计算从起点到所有节点的最短距离。

    Args:
        graph: 邻接表表示的有权图，格式为 {节点: [(邻居, 边权重), ...]}
        start: 起始节点

    Returns:
        dist: 字典，key 为节点，value 为从 start 到该节点的最短距离

    Time Complexity: O((V + E) log V)
    """
    ...
```

### 教程三：AI 辅助 Code Review

```bash
# 让 Copilot 审查你当前的 Git 变更
git diff HEAD | gh copilot explain "审查这些代码变更，找出潜在的问题"
```

---

## 四、Vibe Coding 的最佳实践

### ✅ 推荐做法

1. **描述意图，而非具体实现**：说"帮我写一个防抖函数"而不是"帮我写`setTimeout`那个逻辑"
2. **分解任务**：一次只让 AI 做一件事，便于验证和修改
3. **保持代码审查习惯**：AI 生成的代码不是完美的，要亲自阅读后再提交
4. **善用上下文**：在 Copilot Chat 中使用 `#file` 、`#codebase` 引用具体文件

### ❌ 避免的做法

1. 不加理解地全盘接受 AI 的输出
2. 将包含敏感信息的代码（密钥、密码）粘贴给 AI
3. 完全依赖 AI，忽视自身的算法和数据结构基础

---

## 五、总结

Vibe Coding 的本质是**人机协作**：你负责提供方向、判断和最终决策，AI 负责填充细节、处理重复劳动。掌握好这套工作流，可以让开发效率提升数倍，同时让你有更多精力专注于真正有创造力的工作。

---

*工具链仍在快速演进，欢迎在评论区留下你的推荐。*
