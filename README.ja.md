# Synapse Swarm

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) 向けのシンプルな並列エージェントツール。
コマンド一発でレイアウトが展開し、タスクを入力すると並列で実行します。

## レイアウト

```
┌──────────────────────┬──────────────────────┐
│                      │  [task-1][task-2]...  │
│    Orchestrator      ├──────────────────────┤
│                      │                      │
│  どんな作業をしますか │   各ワーカーが        │
│  ？ > ___            │   ここで動作          │
│                      │                      │
└──────────────────────┴──────────────────────┘
```

左ペイン: タスクを入力するオーケストレーター
右ペイン: ワーカーがタブ（サーフェス）として並ぶ

## 前提条件

- [cmux](https://cmux.app)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI（`claude`）
- Git 2.15+、Bash 4+、Python 3

## 使い方

```bash
# カレントディレクトリで実行
bin/swarm

# プロジェクトを指定して実行
bin/swarm ~/path/to/project
```

1. cmux に `swarm` ワークスペースが開く
2. 左ペインにタスクを入力
3. Claude が分解し、右ペインにワーカーがタブとして現れる
4. 各タブで Claude が worktree 内で作業・コミット

**worktree** はプロジェクト内の `.worktrees/<session>/<task-id>/` に作成されます。
ブランチ名は `swarm/<session>/<task-id>` です。

## 構成

```
bin/
  swarm           # エントリーポイント
  _orchestrate    # タスク入力→分解→ワーカー起動（内部用）
  _worker         # 単一サブタスクを worktree で実行（内部用）
lib/
  worktree.sh     # git worktree ヘルパー
  log.sh          # ログユーティリティ
roles/
  orchestrator.md # タスク分解プロンプト（日本語）
  worker.md       # ワーカー実行プロンプト（日本語）
```

## プロンプトのカスタマイズ

`roles/` 以下のファイルを編集してください。`{{TASK}}` は実行時に置き換えられます。

## ライセンス

MIT
