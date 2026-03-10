# Synapse Swarm

A minimal multi-agent orchestrator for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).
Type a task → Claude decomposes it → parallel agents work in isolated git worktrees.

## How It Works

```
$ cd /your/project
$ /path/to/swarm/bin/swarm

┌─────────────────────────────────────────────────┐
│  Synapse Swarm                                  │
│  Target: /your/project                          │
│                                                 │
│  どんな作業をしますか？ > ログイン機能を追加して  │
│                                                 │
│  Decomposing task...                            │
│    1. [task-1] フロントエンドのログインUI実装    │
│    2. [task-2] バックエンド認証APIの実装         │
│    3. [task-3] テストの作成                     │
│                                                 │
│  Launching agents...                            │
└─────────────────────────────────────────────────┘

tmux windows:
  [0] orchestrator   ← you typed the task here
  [1] task-1         ← Claude working in worktree
  [2] task-2         ← Claude working in worktree
  [3] task-3         ← Claude working in worktree
```

Each agent gets its own git branch (`swarm/<session>/<task-id>`) and works independently.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI (`claude`)
- tmux (`brew install tmux`)
- Git 2.15+, Bash 4+, Python 3

## Usage

```bash
cd /path/to/your/project
/path/to/swarm/bin/swarm
```

Type your task in the orchestrator pane. Claude decomposes it and launches workers automatically.

**Navigate workers:**
- `Ctrl-b n / p` — next / previous window
- `Ctrl-b <number>` — jump to window
- `Ctrl-b d` — detach session

**Worktrees** are created at `.worktrees/<session>/<task-id>/` inside your project.
Each agent commits its changes to its own branch when done.

## Structure

```
bin/
  swarm           # entry point
  _orchestrate    # task input → decompose → spawn (internal)
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
The `{{TASK}}` placeholder is replaced with the actual task at runtime.

## License

MIT
