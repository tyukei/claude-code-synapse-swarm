# Synapse Swarm

A multi-agent orchestration framework for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Spawns specialized AI agents in parallel — each in its own git worktree, each with a distinct role — coordinated through tmux.

Inspired by **brain-like functional specialization**: rather than running identical workers, Synapse Swarm assigns bounded responsibilities (planning, architecture, coding, testing, review) to purpose-built agents that collaborate through shared artifacts.

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│                    Synapse Swarm                        │
│                                                         │
│  Phase 1          Phase 2          Phase 3              │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐          │
│  │ Planner  │───▶│ Architect│───▶│ Tester   │          │
│  │          │    │          │    │          │          │
│  └──────────┘    ├──────────┤    ├──────────┤          │
│  ┌──────────┐    │  Coder   │    │ Reviewer │          │
│  │ Memory   │    │          │    │          │          │
│  │          │    └──────────┘    ├──────────┤          │
│  └──────────┘                    │   Docs   │          │
│                                  └──────────┘          │
│                                                         │
│  Each agent runs in its own git worktree + tmux pane    │
└─────────────────────────────────────────────────────────┘
```

**Key mechanics:**
1. **Task decomposition** — Planner breaks work into subtasks for each role
2. **Isolated execution** — Each agent works in a separate git worktree (no conflicts)
3. **Phase ordering** — Agents run in phases; phase 2 starts after phase 1 completes
4. **Artifact handoff** — Agents communicate through markdown files (PLAN.md, ARCHITECTURE.md, etc.)
5. **Safe merging** — Results are merged branch-by-branch with conflict detection

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI (`claude`)
- **cmux** or **tmux** for parallel mode (auto-detected; sequential mode needs neither)
- Git 2.15+ (for worktree support)
- Bash 4+

```bash
# tmux (macOS)
brew install tmux

# cmux is bundled with the cmux terminal app
# https://cmux.app

# Verify
claude --version
tmux -V   # or: cmux ping
git --version
```

The swarm auto-detects the available backend: **cmux takes priority** if its daemon is running, then tmux, then sequential fallback.

## Quick Start

```bash
# Clone the repo into your project (or use as a template)
git clone <this-repo> .synapse
cd .synapse

# Run with an inline task (auto-detects cmux or tmux)
bin/swarm --task "Build a REST API with user authentication" --roles planner,architect,coder,tester

# Force a specific backend
bin/swarm --task "..." --mux cmux    # cmux workspaces + sidebar
bin/swarm --task "..." --mux tmux    # tmux windows

# Or use a task file
cp tasks/example.yaml tasks/my-task.yaml
# Edit tasks/my-task.yaml with your task description
bin/swarm tasks/my-task.yaml

# Sequential mode (no multiplexer required)
bin/swarm --task "Fix the login bug" --roles coder,tester --no-mux
```

## Agent Roles

| Role | Brain Analogy | Responsibility | Phase |
|------|--------------|----------------|-------|
| **Planner** | Prefrontal cortex | Task decomposition, sequencing | 1 |
| **Memory** | Hippocampus | Project context, decisions, patterns | 1 |
| **Architect** | Parietal lobe | System design, interfaces, data flow | 2 |
| **Coder** | Motor cortex | Implementation | 2 |
| **Tester** | Anterior cingulate | Test writing, error detection | 3 |
| **Reviewer** | Evaluative system | Code review, security, quality | 3 |
| **Docs** | Broca's area | Documentation, communication | 3 |

## Repository Structure

```
synapse-swarm/
├── bin/
│   ├── swarm           # Main orchestrator
│   ├── spawn-agent     # Spawn a single agent in a worktree
│   ├── collect         # Gather results from all agents
│   ├── merge           # Safely merge agent branches
│   └── teardown        # Clean up worktrees and tmux
├── lib/
│   ├── log.sh          # Logging utilities
│   ├── worktree.sh     # Git worktree management
│   ├── tmux.sh         # tmux session/pane management
│   └── task.sh         # Task parsing and prompt rendering
├── roles/
│   ├── planner.md      # Prompt template for planner
│   ├── architect.md    # Prompt template for architect
│   ├── coder.md        # Prompt template for coder
│   ├── tester.md       # Prompt template for tester
│   ├── reviewer.md     # Prompt template for reviewer
│   ├── docs.md         # Prompt template for docs
│   └── memory.md       # Prompt template for memory
├── config/
│   ├── swarm.yaml      # Main configuration
│   └── roles.yaml      # Role definitions and phases
├── tasks/
│   └── example.yaml    # Example task definition
├── output/             # Collected agent outputs
├── CLAUDE.md           # Claude Code context file
└── README.md
```

## Workflow

### 1. Define a Task

```yaml
# tasks/my-feature.yaml
description: >
  Add rate limiting middleware to the API server.
  Use a token bucket algorithm with configurable limits per endpoint.

roles:
  - planner
  - architect
  - coder
  - tester
  - reviewer
```

### 2. Launch the Swarm

```bash
bin/swarm tasks/my-feature.yaml
```

This will:
- Create a tmux session with one pane per agent
- Create a git worktree per agent (isolated branches)
- Run agents in phase order (planner/memory first, then architect/coder, then tester/reviewer/docs)
- Each agent gets its role-specific prompt + your task description

### 3. Monitor Progress

**With cmux:**
- Switch to the cmux terminal window
- Each agent runs in its own workspace named `<session>/<role>`
- Live status badges appear in the sidebar per agent (running → done ✓ / error ✗)
- Progress bar shows each agent's phase (starting → running → committing → done)

**With tmux:**
```bash
tmux attach -t synapse-YYYYMMDD-HHMMSS

# Navigate between agent panes
# Ctrl-b n  — next window
# Ctrl-b p  — previous window
# Ctrl-b w  — list all windows
```

### 4. Collect and Merge Results

```bash
# Gather all agent outputs into output/<session>/
bin/collect <session>

# Review the summary
cat output/<session>/SUMMARY.md

# Merge agent branches (sequential, with conflict detection)
bin/merge <session>

# Or try octopus merge (all at once)
bin/merge <session> octopus
```

### 5. Clean Up

```bash
# Remove worktrees, branches, and tmux session
bin/teardown <session>

# Keep the branches for reference
bin/teardown <session> --keep-branches
```

## Customization

### Adding a New Role

1. Create `roles/my-role.md` with the prompt template (use `{{TASK_DESCRIPTION}}` placeholder)
2. Add the role to `config/roles.yaml` with a phase number
3. Include it in your task file or `--roles` flag

### Modifying Prompts

Edit any file in `roles/`. The `{{TASK_DESCRIPTION}}` placeholder is replaced with the task description at runtime.

### Configuration

Edit `config/swarm.yaml` to change defaults like model, timeout, merge strategy, or Claude Code flags.

## Design Philosophy

**Why specialized agents instead of parallel clones?**

Undifferentiated parallelism (N copies doing the same thing) leads to redundant work and merge chaos. Synapse Swarm uses **bounded responsibility** — each agent has a clear scope, defined inputs/outputs, and a specific phase in the pipeline. This mirrors how the brain works: specialized regions collaborating through well-defined interfaces.

**Why worktrees?**

Git worktrees give each agent a full, independent working copy without the overhead of cloning. Agents can freely modify files without stepping on each other. Merging is handled after all agents complete.

**Why tmux?**

tmux provides real-time visibility into what each agent is doing, easy navigation between agents, and persistent sessions that survive terminal disconnects.

## License

MIT
