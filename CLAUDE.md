# Synapse Swarm — CLAUDE.md

タスクを複数の Claude Code エージェントに分解して並列実行するツール。
tmux + git worktree で各エージェントが独立した環境で作業する。

## 構造
- `bin/swarm`        — エントリーポイント。tmux セッションを作成して起動
- `bin/_orchestrate` — タスク入力・分解・エージェント起動（内部用）
- `bin/_worker`      — 単一サブタスクを worktree で実行（内部用）
- `lib/worktree.sh`  — git worktree の作成ヘルパー
- `lib/log.sh`       — ログユーティリティ
- `roles/orchestrator.md` — タスク分解プロンプト（日本語）
- `roles/worker.md`       — ワーカー実行プロンプト（日本語）

## 使い方
```bash
cd /path/to/your/project
/path/to/swarm/bin/swarm
```

## 規約
- スクリプトは `bash` + `set -euo pipefail`
- worktree は `TARGET/.worktrees/SESSION/TASK_ID/` に作成
- ブランチ名は `swarm/SESSION/TASK_ID`
