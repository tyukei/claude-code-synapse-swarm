# Synapse Swarm

A minimal multi-agent orchestrator for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).
Type a task → Claude decomposes it → parallel agents work in isolated git worktrees, each in its own [cmux](https://cmux.app) workspace.

## How It Works

```
$ cd /your/project && /path/to/swarm/bin/swarm

cmux opens a new workspace:

  どんな作業をしますか？ > ログイン機能を追加して

  タスクを分解中...

  サブタスク:
    1. [task-1] フロントエンドのログインUI実装
    2. [task-2] バックエンド認証APIの実装
    3. [task-3] テストの作成

  エージェントを起動中...
```

Three more cmux workspaces open automatically — one per subtask.
Each agent works in its own git branch and commits when done.

## Prerequisites

- [cmux](https://cmux.app)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI (`claude`)
- Git 2.15+, Bash 4+, Python 3

## Usage

```bash
cd /path/to/your/project
/path/to/swarm/bin/swarm
```

Switch between cmux workspaces (`swarm: task-1`, `swarm: task-2`, …) to watch each agent work.

**Worktrees** are created at `.worktrees/<session>/<task-id>/` inside your project.
Each agent commits its changes to `swarm/<session>/<task-id>` branch when done.

## Structure

```
bin/
  swarm           # entry point — opens orchestrator workspace in cmux
  _orchestrate    # task input → decompose → spawn workers (internal)
  _worker         # run one subtask in a worktree (internal)
lib/
  worktree.sh     # git worktree helpers
  log.sh          # logging utilities
roles/
  orchestrator.md # decomposition prompt (Japanese)
  worker.md       # worker execution prompt (Japanese)
```

## Customizing Prompts

Edit `roles/orchestrator.md` to change how tasks are decomposed.
Edit `roles/worker.md` to change how workers approach tasks.
The `{{TASK}}` placeholder is replaced at runtime.

## License

MIT
