# Synapse Swarm

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) 向けのマルチエージェント・オーケストレーションフレームワーク。専門化された AI エージェントを並列実行します — 各エージェントは独自の git worktree を持ち、固有のロールを担い、tmux で統合されます。

**脳の機能的専門化**にインスパイアされた設計: 同一のワーカーを並列実行するのではなく、Synapse Swarm は計画・設計・実装・テスト・レビューといった責任範囲を専門エージェントに割り当て、共有アーティファクトを通じて協調させます。

## 動作の仕組み

```
┌─────────────────────────────────────────────────────────┐
│                    Synapse Swarm                        │
│                                                         │
│  フェーズ1        フェーズ2        フェーズ3             │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐          │
│  │ Planner  │───▶│Architect │───▶│ Tester   │          │
│  │          │    │          │    │          │          │
│  └──────────┘    ├──────────┤    ├──────────┤          │
│  ┌──────────┐    │  Coder   │    │ Reviewer │          │
│  │ Memory   │    │          │    │          │          │
│  │          │    └──────────┘    ├──────────┤          │
│  └──────────┘                    │   Docs   │          │
│                                  └──────────┘          │
│                                                         │
│  各エージェントは独自の git worktree + tmux ペインで動作  │
└─────────────────────────────────────────────────────────┘
```

**主要な仕組み:**
1. **タスク分解** — Planner がタスクを各ロール向けのサブタスクに分解
2. **分離実行** — 各エージェントが独立した git worktree で動作（コンフリクトなし）
3. **フェーズ順序** — エージェントはフェーズ単位で実行（フェーズ1完了後にフェーズ2開始）
4. **アーティファクト連携** — マークダウンファイル（PLAN.md、ARCHITECTURE.md 等）を通じて情報を共有
5. **安全なマージ** — コンフリクト検知付きでブランチを順次マージ

## 前提条件

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI (`claude`)
- **cmux** または **tmux**（並列モード使用時 — 自動検出）
- Git 2.15+（worktree サポート）
- Bash 4+

```bash
# tmux (macOS)
brew install tmux

# cmux は cmux ターミナルアプリに付属
# https://cmux.app

# 確認
claude --version
tmux -V   # または: cmux ping
git --version
```

スウォームは利用可能なバックエンドを自動検出します: **cmux のデーモンが起動中なら cmux を優先**、次に tmux、最後にシーケンシャルモードへフォールバックします。

## クイックスタート

```bash
# リポジトリをクローン（またはテンプレートとして使用）
git clone <this-repo> .synapse
cd .synapse

# インラインタスクで実行（cmux または tmux を自動検出）
bin/swarm --task "ユーザー認証付き REST API を構築する" --roles planner,architect,coder,tester

# バックエンドを明示的に指定
bin/swarm --task "..." --mux cmux    # cmux ワークスペース + サイドバー
bin/swarm --task "..." --mux tmux    # tmux ウィンドウ

# タスクファイルを使用する場合
cp tasks/example.yaml tasks/my-task.yaml
# tasks/my-task.yaml をタスク内容に合わせて編集
bin/swarm tasks/my-task.yaml

# シーケンシャルモード（マルチプレクサ不要）
bin/swarm --task "ログインバグを修正する" --roles coder,tester --no-mux
```

## エージェントロール

| ロール | 脳との対応 | 担当 | フェーズ |
|--------|-----------|------|---------|
| **Planner** | 前頭前野 | タスク分解、順序決定 | 1 |
| **Memory** | 海馬 | プロジェクトの文脈・決定事項・パターン管理 | 1 |
| **Architect** | 頭頂葉 | システム設計、インターフェース、データフロー | 2 |
| **Coder** | 運動皮質 | 実装 | 2 |
| **Tester** | 前帯状皮質 | テスト作成、エラー検出 | 3 |
| **Reviewer** | 評価系 | コードレビュー、セキュリティ、品質確認 | 3 |
| **Docs** | ブローカ野 | ドキュメント作成、コミュニケーション | 3 |

## リポジトリ構成

```
synapse-swarm/
├── bin/
│   ├── swarm           # メインオーケストレーター
│   ├── spawn-agent     # 単一エージェントを worktree で起動
│   ├── collect         # 全エージェントの結果を収集
│   ├── merge           # エージェントブランチを安全にマージ
│   └── teardown        # worktree とマルチプレクサのクリーンアップ
├── lib/
│   ├── log.sh          # ログユーティリティ
│   ├── worktree.sh     # git worktree 管理
│   ├── mux.sh          # マルチプレクサ自動検出・統一インターフェース
│   ├── tmux.sh         # tmux バックエンド
│   ├── cmux.sh         # cmux バックエンド（ワークスペース・サイドバー対応）
│   └── task.sh         # タスク解析とプロンプト描画
├── roles/
│   ├── planner.md      # planner 用プロンプトテンプレート
│   ├── architect.md    # architect 用プロンプトテンプレート
│   ├── coder.md        # coder 用プロンプトテンプレート
│   ├── tester.md       # tester 用プロンプトテンプレート
│   ├── reviewer.md     # reviewer 用プロンプトテンプレート
│   ├── docs.md         # docs 用プロンプトテンプレート
│   └── memory.md       # memory 用プロンプトテンプレート
├── config/
│   ├── swarm.yaml      # メイン設定
│   └── roles.yaml      # ロール定義とフェーズ設定
├── tasks/
│   └── example.yaml    # タスク定義のサンプル
├── output/             # 収集されたエージェントの出力
├── CLAUDE.md           # Claude Code コンテキストファイル
└── README.md
```

## ワークフロー

### 1. タスクを定義する

```yaml
# tasks/my-feature.yaml
description: >
  API サーバーにレート制限ミドルウェアを追加する。
  トークンバケットアルゴリズムを使用し、エンドポイントごとに設定可能にする。

roles:
  - planner
  - architect
  - coder
  - tester
  - reviewer
```

### 2. スウォームを起動する

```bash
bin/swarm tasks/my-feature.yaml
```

実行内容:
- エージェントごとにマルチプレクサのペイン/ワークスペースを作成（cmux または tmux を自動検出）
- エージェントごとに git worktree を作成（独立したブランチ）
- フェーズ順でエージェントを実行（planner/memory → architect/coder → tester/reviewer/docs）
- 各エージェントにロール別プロンプト + タスク説明を渡す

### 3. 進捗を確認する

**cmux を使用している場合:**
- cmux ターミナルウィンドウに切り替える
- 各エージェントは `<session>/<role>` という名前のワークスペースで動作
- サイドバーにエージェントごとのライブステータスバッジが表示（running → done ✓ / error ✗）
- プログレスバーで各エージェントのフェーズを確認（starting → running → committing → done）

**tmux を使用している場合:**
```bash
# tmux セッションにアタッチ
tmux attach -t synapse-YYYYMMDD-HHMMSS

# エージェントのペイン間を移動
# Ctrl-b n  — 次のウィンドウ
# Ctrl-b p  — 前のウィンドウ
# Ctrl-b w  — 全ウィンドウ一覧
```

### 4. 結果を収集・マージする

```bash
# 全エージェントの出力を output/<session>/ に収集
bin/collect <session>

# サマリーを確認
cat output/<session>/SUMMARY.md

# エージェントブランチをマージ（逐次、コンフリクト検知あり）
bin/merge <session>

# またはオクトパスマージ（一括）
bin/merge <session> octopus
```

### 5. クリーンアップ

```bash
# worktree、ブランチ、tmux セッションを削除
bin/teardown <session>

# ブランチを参照用に残す
bin/teardown <session> --keep-branches
```

## カスタマイズ

### 新しいロールを追加する

1. `roles/my-role.md` を作成（`{{TASK_DESCRIPTION}}` プレースホルダーを使用）
2. `config/roles.yaml` にフェーズ番号付きでロールを追加
3. タスクファイルまたは `--roles` フラグで指定

### プロンプトを変更する

`roles/` 内の任意のファイルを編集してください。`{{TASK_DESCRIPTION}}` プレースホルダーは実行時にタスク説明で置き換えられます。

### 設定を変更する

`config/swarm.yaml` を編集してモデル、タイムアウト、マージ戦略、Claude Code フラグなどのデフォルト値を変更できます。

## 設計思想

**なぜ並列クローンではなく専門エージェントなのか？**

同一のワーカーを単純に並列化すると（N個のコピーが同じことをする）、重複した作業とマージの混乱が生じます。Synapse Swarm は**責任の境界**を明確にします — 各エージェントはスコープ、入出力、パイプライン内のフェーズが定義されています。これは脳の仕組みを模倣しています: 専門化された領域が明確に定義されたインターフェースを通じて協調します。

**なぜ worktree なのか？**

git worktree は、クローンのオーバーヘッドなしに各エージェントに完全で独立した作業コピーを提供します。エージェントは互いに干渉することなく自由にファイルを変更できます。マージは全エージェントの完了後に行います。

**なぜ tmux なのか？**

tmux は各エージェントの動作をリアルタイムで可視化し、エージェント間を簡単に移動でき、ターミナルが切断されても永続するセッションを提供します。

## ライセンス

MIT
