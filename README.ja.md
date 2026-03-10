# Synapse Swarm

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) 向けのシンプルな並列エージェントツール。
タスクを入力すると Claude が分解し、独立した git worktree で並列実行します。

## 動作イメージ

```
$ cd /your/project
$ /path/to/swarm/bin/swarm

┌─────────────────────────────────────────────────┐
│  Synapse Swarm                                  │
│  対象リポジトリ: /your/project                  │
│                                                 │
│  どんな作業をしますか？ > ログイン機能を追加して  │
│                                                 │
│  タスクを分解中...                               │
│    1. [task-1] フロントエンドのログインUI実装    │
│    2. [task-2] バックエンド認証APIの実装         │
│    3. [task-3] テストの作成                     │
│                                                 │
│  エージェントを起動中...                         │
└─────────────────────────────────────────────────┘

tmux ウィンドウ:
  [0] orchestrator   ← タスクを入力したペイン
  [1] task-1         ← worktree で Claude が作業中
  [2] task-2         ← worktree で Claude が作業中
  [3] task-3         ← worktree で Claude が作業中
```

各エージェントは専用の git ブランチ（`swarm/<session>/<task-id>`）を持ち、独立して作業します。

## 前提条件

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI（`claude`）
- tmux（`brew install tmux`）
- Git 2.15+、Bash 4+、Python 3

## 使い方

```bash
cd /作業したいプロジェクト
/path/to/swarm/bin/swarm
```

オーケストレーターペインにタスクを入力するだけ。
Claude が自動でサブタスクに分解し、各ワーカーを起動します。

**ウィンドウ操作:**
- `Ctrl-b n / p` — 次 / 前のウィンドウ
- `Ctrl-b <数字>` — ウィンドウに直接ジャンプ
- `Ctrl-b d` — セッションをデタッチ

**worktree** はプロジェクト内の `.worktrees/<session>/<task-id>/` に作成されます。
各エージェントは作業完了時に変更を自分のブランチにコミットします。

## 構成

```
bin/
  swarm           # エントリーポイント（これだけ実行する）
  _orchestrate    # タスク入力→分解→worker起動（内部用）
  _worker         # 単一サブタスクを worktree で実行（内部用）
lib/
  worktree.sh     # git worktree ヘルパー
  log.sh          # ログユーティリティ
roles/
  orchestrator.md # タスク分解プロンプト（日本語）
  worker.md       # ワーカー実行プロンプト（日本語）
```

## プロンプトのカスタマイズ

- `roles/orchestrator.md` — タスクの分解方法を変更
- `roles/worker.md` — ワーカーの作業アプローチを変更

`{{TASK}}` プレースホルダーは実行時にタスク内容で置き換えられます。

## ライセンス

MIT
