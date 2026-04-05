# codex-dotfiles

<p align="center">
  Portable Codex configuration for primary and secondary machines.
</p>

<p align="center">
  <a href="./README.zh-CN.md">简体中文</a>
</p>

## Overview

`codex-dotfiles` keeps shared Codex configuration in Git while preserving machine-local overrides outside the tracked surface.

## Highlights

- Single entrypoint: `./codexctl`
- Shared Codex assets: `AGENTS.md`, `instruction.md`, `rules/`, `skills/`, `config.shared.toml`
- Machine-local archive: `${CODEX_HOME:-~/.codex}/config.local.toml`
- Generated runtime config: `${CODEX_HOME:-~/.codex}/config.toml`
- Multi-machine workflow: primary publish, secondary sync
- Windows secondary support: `init` / `install` / manual `sync` only
- Strict allowlist for tracked files
- Hourly cron jobs for `sync` or `publish`

## Requirements

- `bash`
- `git`
- `rsync`
- `flock`
- `crontab` for scheduled jobs

Windows secondary:

- Run through Git Bash
- Not supported as a primary/publish host
- No cron install; use `./codexctl sync` manually
- Missing `rsync` / `flock` falls back to portable behavior

## Quick Start

```bash
./codexctl init
./codexctl install
./codexctl sync
```

HTTPS auth:

```bash
git config --global credential.helper store
```

## Commands

| Command | Purpose |
| --- | --- |
| `./codexctl init` | Initialize repository state and machine role |
| `./codexctl install` | Apply tracked shared config to `${CODEX_HOME:-~/.codex}` |
| `./codexctl render-config` | Regenerate `${CODEX_HOME:-~/.codex}/config.toml` |
| `./codexctl sync` | Fast-forward pull and reinstall shared config |
| `./codexctl publish` | Commit tracked changes and push current branch |
| `./codexctl commit` | Commit tracked changes |
| `./codexctl commit --push "message"` | Commit and push tracked changes |
| `./codexctl install-cron sync` | Install hourly sync job |
| `./codexctl install-cron publish` | Install hourly publish job |
| `./codexctl install-cron none` | Remove managed cron job |

## Configuration Model

| Layer | Location |
| --- | --- |
| Shared | `codex/config.shared.toml` |
| Local archive | `${CODEX_HOME:-~/.codex}/config.local.toml` |
| Runtime | `${CODEX_HOME:-~/.codex}/config.toml` |

```toml
[projects."/absolute/path"]
trust_level = "trusted"
```

## Tracked Layout

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

## Managed Paths

- `codex/AGENTS.md`
- `codex/instruction.md`
- `codex/config.shared.toml`
- `codex/rules/`
- `codex/skills/`

## Git Surface

- Tracked root files: `.gitignore`, `LICENSE`, `README.md`, `README.zh-CN.md`, `codexctl`, `.codex-dotfiles-id`
- Tracked directories: `bootstrap/`, `codex/`
- Commit scope: tracked allowlist only

## Logs

- Sync log: `~/.local/state/codex-dotfiles/sync.log`
- Publish log: `~/.local/state/codex-dotfiles/publish.log`

## License

AGPL-3.0-only. See `LICENSE`.
