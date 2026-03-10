# Synapse Swarm

A minimal multi-agent orchestrator for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).
One command opens a [cmux](https://cmux.app) workspace with a split layout — type a task, agents spin up in parallel.

## Layout

```
┌──────────────────────┬──────────────────────┐
│                      │  [task-1][task-2]...  │
│    Orchestrator      ├──────────────────────┤
│                      │                      │
│  どんな作業をしますか │   workers run here   │
│  ？ > ___            │   as surface tabs     │
│                      │                      │
└──────────────────────┴──────────────────────┘
```

Left pane: orchestrator — you type the task here
Right pane: workers appear as tabs as they're spawned

## Prerequisites

- [cmux](https://cmux.app)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI (`claude`)
- Git 2.15+, Bash 4+, Python 3

## Usage

```bash
# Run in current directory
bin/swarm

# Specify a project path
bin/swarm ~/path/to/project
```

1. A `swarm` workspace opens in cmux
2. Type your task in the left pane
3. Claude decomposes it; workers appear as tabs in the right pane
4. Each worker runs Claude in its own git worktree and commits when done

**Worktrees** are created at `.worktrees/<session>/<task-id>/` inside your project.
Branch names follow the pattern `swarm/<session>/<task-id>`.

## Structure

```
bin/
  swarm           # entry point
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

Edit files in `roles/`. The `{{TASK}}` placeholder is replaced at runtime.

## License

MIT
