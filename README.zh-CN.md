# codex-dotfiles

<p align="center">
  面向主力机与从属机器的可移植 Codex 配置仓库。
</p>

<p align="center">
  <a href="./README.md">English</a>
</p>

## 概览

`codex-dotfiles` 使用 Git 管理共享的 Codex 配置，同时将机器私有覆盖项保留在追踪范围之外。

## 特性

- 单一入口：`./codexctl`
- 共享配置资产：`AGENTS.md`、`instruction.md`、`rules/`、`skills/`、`config.shared.toml`
- 机器本地归档：`${CODEX_HOME:-~/.codex}/config.local.toml`
- 运行时配置：`${CODEX_HOME:-~/.codex}/config.toml`
- 多机协作：主力机发布，从属机器同步
- Windows 从端兼容：仅支持 `init` / `install` / 手动 `sync`
- 严格的 Git 白名单追踪面
- `sync` / `publish` 小时级 cron 任务

## 依赖

- `bash`
- `git`
- `rsync`
- `flock`
- `crontab`，用于定时任务

Windows 从端：

- 建议在 Git Bash 下运行
- 不作为主力机，不执行 `publish`
- 不安装 cron，默认只手动执行 `./codexctl sync`
- 若缺少 `rsync` / `flock`，会自动走降级路径

## 快速开始

```bash
./codexctl init
./codexctl install
./codexctl sync
```

HTTPS 凭据持久化：

```bash
git config --global credential.helper store
```

## 命令

| 命令 | 用途 |
| --- | --- |
| `./codexctl init` | 初始化仓库状态与机器角色 |
| `./codexctl install` | 将共享配置应用到 `${CODEX_HOME:-~/.codex}` |
| `./codexctl render-config` | 重新生成 `${CODEX_HOME:-~/.codex}/config.toml` |
| `./codexctl sync` | 快进拉取并重新安装共享配置 |
| `./codexctl publish` | 提交受管变更并推送当前分支 |
| `./codexctl commit` | 提交受管变更 |
| `./codexctl commit --push "message"` | 提交并推送受管变更 |
| `./codexctl install-cron sync` | 安装每小时同步任务 |
| `./codexctl install-cron publish` | 安装每小时发布任务 |
| `./codexctl install-cron none` | 移除受管 cron 任务 |

## 配置模型

| 层级 | 位置 |
| --- | --- |
| 共享层 | `codex/config.shared.toml` |
| 本地归档层 | `${CODEX_HOME:-~/.codex}/config.local.toml` |
| 运行时层 | `${CODEX_HOME:-~/.codex}/config.toml` |

```toml
[projects."/absolute/path"]
trust_level = "trusted"
```

## 追踪结构

```text
.
|-- codexctl
|-- README.md
|-- README.zh-CN.md
|-- bootstrap/
`-- codex/
    |-- AGENTS.md
    |-- instruction.md
    |-- config.shared.toml
    |-- rules/
    `-- skills/
```

## 受管路径

- `codex/AGENTS.md`
- `codex/instruction.md`
- `codex/config.shared.toml`
- `codex/rules/`
- `codex/skills/`

## Git 追踪面

- 根目录追踪文件：`.gitignore`、`LICENSE`、`README.md`、`README.zh-CN.md`、`codexctl`、`.codex-dotfiles-id`
- 追踪目录：`bootstrap/`、`codex/`
- 提交范围：仅限白名单内路径

## 日志

- 同步日志：`~/.local/state/codex-dotfiles/sync.log`
- 发布日志：`~/.local/state/codex-dotfiles/publish.log`

## 许可证

AGPL-3.0-only。详见 `LICENSE`。
