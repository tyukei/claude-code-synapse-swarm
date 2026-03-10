# Synapse Swarm

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) 向けのシンプルな並列エージェントツール。
タスクを入力すると Claude が分解し、[cmux](https://cmux.app) の各ワークスペースで git worktree を使って並列実行します。

## 動作イメージ

```
$ cd /your/project && /path/to/swarm/bin/swarm

cmux に新しいワークスペースが開く:

  どんな作業をしますか？ > ログイン機能を追加して

  タスクを分解中...

  サブタスク:
    1. [task-1] フロントエンドのログインUI実装
    2. [task-2] バックエンド認証APIの実装
    3. [task-3] テストの作成

  エージェントを起動中...
```

サブタスクの数だけ cmux ワークスペースが自動で開き、各エージェントが独立して作業します。

## 前提条件

- [cmux](https://cmux.app)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI（`claude`）
- Git 2.15+、Bash 4+、Python 3

## 使い方

```bash
cd /作業したいプロジェクト
/path/to/swarm/bin/swarm
```

cmux のワークスペース（`swarm: task-1`、`swarm: task-2` …）を切り替えて各エージェントの作業を確認できます。

**worktree** はプロジェクト内の `.worktrees/<session>/<task-id>/` に作成されます。
各エージェントは作業完了時に `swarm/<session>/<task-id>` ブランチにコミットします。

## 構成

```
bin/
  swarm           # エントリーポイント — cmux にオーケストレーターを開く
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
