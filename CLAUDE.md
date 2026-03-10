# Synapse Swarm — CLAUDE.md

This repository is a multi-agent orchestration framework for Claude Code.
It uses tmux + git worktrees to run specialized agents in parallel.

## Structure
- `bin/` — Executable scripts (swarm, spawn-agent, collect, merge, teardown)
- `lib/` — Shared shell libraries (worktree, tmux, task, log helpers)
- `roles/` — Prompt templates for each agent role (markdown files)
- `config/` — YAML configuration for swarm behavior and role definitions
- `tasks/` — Task definition files (user-created)
- `output/` — Collected agent outputs

## Conventions
- All scripts use bash with `set -euo pipefail`
- Scripts are meant to be run from the repository root
- Agent branches follow the pattern `swarm/<session>/<role>`
- Worktrees are created under `.worktrees/`
