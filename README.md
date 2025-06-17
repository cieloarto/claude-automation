# claude-automation

Claude Professional Development Environment
Claude Code を使用したプロフェッショナルな開発環境の自動化ツールセット
🎯 概要
このツールセットは、Claude Code を使用して本格的なソフトウェア開発ワークフローを自動化します：

要件定義 → 設計 → 実装 → テスト → PR 作成 の完全自動化
品質ゲート による堅牢な品質管理
tmux による複数チーム並行開発
Git ワークフロー の自動化

🚀 主な機能
✨ 自動化されるワークフロー

ナレッジインポート: 外部技術情報の自動取り込み
要件定義: 自動ドキュメント生成
設計フェーズ: アーキテクチャ・DB 設計の自動化
実装管理: チーム別タスク分散と進捗管理
品質管理: PR 作成前の自動品質チェック
PR 自動化: GitHub PR 作成とレビュー承認

🏢 組織構成

プロジェクトマネージャー: タスク分解・進捗管理
QA チーム: 品質ゲート・テスト管理・PR 作成
開発チーム: 実装・単体テスト・品質対応

📦 インストール
前提条件

tmux: セッション管理
Claude Code: AI 開発アシスタント
GitHub CLI (推奨): PR 自動作成
Node.js/npm: プロジェクト管理 (optional)

bash# macOS
brew install tmux gh

# Claude Code インストール (公式サイトから)

# https://claude.ai/

セットアップ
bash# 1. リポジトリクローン
git clone https://github.com/your-username/claude-pro-dev.git
cd claude-pro-dev

# 2. 実行権限付与

chmod +x \*.sh

# 3. GitHub 認証 (PR 自動作成用)

gh auth login
🎯 使用方法
基本的な開発フロー
bash# 1. 開発環境起動
./claude-pro-dev.sh my-project 4

# 2. ナレッジインポート

import-knowledge 'https://example.com/tech-doc' '技術スタック情報'

# 3. 開発フェーズ実行

requirements 'e コマースサイト構築'
design
implementation

# 4. タスク割り当て

task-assign 0 'ユーザー認証機能実装' 'user-auth'
task-assign 1 '商品管理 API 実装' 'product-api'

# 5. 品質チェック (チーム完了後)

qa-check A user-auth

# 6. 全体統合テスト

integration-test
利用可能なコマンド
📋 開発フェーズ

requirements '<プロジェクト名>' - 要件定義開始
design - 設計フェーズ開始
implementation - 実装フェーズ開始
integration-test - 全体統合テスト

⚙️ タスク管理

task-assign <チーム番号> '<タスク>' '<ブランチ名>' - タスク割り当て
qa-check <チーム> '<ブランチ名>' - QA 品質チェック

📊 進捗管理

progress - 全体進捗確認
status - 現在の状況確認
help - コマンド一覧表示

🔄 ワークフロー詳細

1. 品質ゲートシステム
   開発チーム実装完了
   ↓
   QA 品質チェック
   ↓
   ✅ 合格 → 自動 PR 作成 + レビュー承認
   ❌ 不合格 → 具体的修正指示で差し戻し
2. 自動生成されるドキュメント

docs/requirements/requirements.md - 要件定義書
docs/design/architecture.md - アーキテクチャ設計
docs/design/database.md - データベース設計
docs/tasks/task-breakdown.md - タスク分解
docs/tests/test-specifications.md - テスト仕様
docs/knowledge/claude.md - 技術ナレッジ

3. Git ワークフロー

feature/<task-name> ブランチでの開発
git worktree による並行開発
品質ゲート合格後の自動 PR 作成
QA レビュー承認の自動化

🏗️ アーキテクチャ
スクリプト構成
claude-pro-dev.sh # メインスクリプト (tmux セットアップ)
├── claude-functions.sh # 基本機能 (初期化、進捗管理)
├── claude-qa.sh # QA 機能 (品質チェック、PR 管理)  
└── claude-workflow.sh # ワークフロー管理 (フェーズ管理)
tmux 画面構成
┌─────────────────┬─────────────────┐
│ マネージャー │ 開発チーム A │
│ (左上) │ (右上) │
├─────────────────┼─────────────────┤
│ QA チーム │ 開発チーム B │
│ (左下) │ (右中) │
│ │─────────────────│
│ │ 開発チーム C │
│ │ (右下) │
└─────────────────┴─────────────────┘
🔧 カスタマイズ
チーム数の変更
bash# 6 チームで起動
./claude-pro-dev.sh my-project 6
作業ディレクトリの指定
bash# カスタムディレクトリで起動
./claude-pro-dev.sh my-project 4 /path/to/workspace
🤝 コントリビューション

Fork the repository
Create your feature branch (git checkout -b feature/amazing-feature)
Commit your changes (git commit -m 'Add some amazing feature')
Push to the branch (git push origin feature/amazing-feature)
Open a Pull Request

📄 ライセンス
This project is licensed under the MIT License - see the LICENSE file for details.
🙏 謝辞

Claude AI - AI 開発アシスタント
tmux - ターミナルマルチプレクサー
GitHub CLI - GitHub コマンドラインツール

📚 関連リンク

Claude Code 公式ドキュメント
tmux 使用方法
GitHub CLI 使用方法

⭐ このプロジェクトが役に立ったら、ぜひスターをお願いします！
