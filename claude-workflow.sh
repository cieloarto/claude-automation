#!/bin/bash

# Claude ワークフロー管理スクリプト

# 要件定義開始
start_requirements() {
    local project_name="$1"
    CURRENT_PROJECT="$project_name"
    DEVELOPMENT_PHASE="requirements"

    local req_prompt="【要件定義フェーズ開始】
プロジェクト名: $project_name

以下の要件定義ドキュメントを docs/requirements/requirements.md に作成してください：

1. プロジェクト概要
2. 機能要件 (詳細な機能リスト)
3. 非機能要件 (パフォーマンス、セキュリティ、スケーラビリティ)
4. 技術要件 (技術スタック、アーキテクチャ方針)
5. 制約条件 (期間、リソース、技術的制約)
6. 成功基準 (KPI、品質基準)

要件定義完了後、設計フェーズに進む準備をしてください。"

    tmux send-keys -t "$MANAGER_PANE" "$req_prompt" C-m
    echo "📋 要件定義フェーズを開始: $project_name"
}

# 設計フェーズ開始
start_design() {
    DEVELOPMENT_PHASE="design"

    local design_prompt="【設計フェーズ開始】

要件定義書を基に、以下の設計ドキュメントを作成してください：

1. docs/design/architecture.md
   - システムアーキテクチャ図
   - コンポーネント構成
   - API設計
   - フロントエンド構成

2. docs/design/database.md  
   - ER図
   - テーブル設計
   - インデックス戦略

3. docs/tasks/task-breakdown.md
   - 開発タスクの詳細分解
   - 各チームへの割り当て案
   - ブランチ戦略
   - 依存関係マップ

設計完了後、QAチームにテスト要件定義を依頼してください。"

    tmux send-keys -t "$MANAGER_PANE" "$design_prompt" C-m
    tmux send-keys -t "$QA_PANE" "設計ドキュメントを基に、docs/tests/test-specifications.md にテスト要件を定義してください。単体テスト、統合テスト、E2Eテストの観点から包括的に計画してください。" C-m
    echo "📐 設計フェーズを開始"
}

# 実装フェーズ開始
start_implementation() {
    DEVELOPMENT_PHASE="implementation"

    local impl_prompt="【実装フェーズ開始】

タスク分解に基づいて、各チームに実装タスクを割り当ててください。
各タスクにはfeature/<task-name>ブランチを指定し、worktreeでの並行開発を指示してください。

Git初期化も含めて実行してください：
1. git init
2. README.md, .gitignore作成  
3. 初期コミット
4. develop ブランチ作成
5. main ブランチ保護

【改良されたワークフロー指示】
各チームには以下を伝えてください：
- 実装完了後、必ずQAチームに品質チェック依頼
- QAチェック合格後、自動でPR作成される
- 不合格の場合は修正対応が必要

その後、各チームへのタスク割り当てを開始してください。"

    tmux send-keys -t "$MANAGER_PANE" "$impl_prompt" C-m
    echo "⚙️ 実装フェーズを開始"
}

# プロ版タスク割り当て（改良版ワークフロー統合）
assign_pro_task() {
    local team_num="$1"
    local task="$2"
    local branch_name="$3"
    local team_letter=$(chr $((65 + team_num)))

    if [ "$team_num" -lt "${#TEAM_PANES[@]}" ]; then
        local full_task="cd '$WORKSPACE_DIR' && 

【実装タスク】$task
【ブランチ】feature/$branch_name

【改良されたワークフロー】
1. git worktree add ../$branch_name feature/$branch_name
2. cd ../$branch_name  
3. 実装 + 単体テスト作成
4. npm test で全テスト合格確認
5. QAチームに品質チェック依頼

【重要】
- 実装完了後、必ずQAチームに品質チェック依頼してください
- QAチェック合格後、自動でPR作成されます
- 不合格の場合は指摘事項を修正して再チェック依頼してください

【完了報告フォーマット】
'[チーム$team_letter] $task 実装完了、QAチームに品質チェック依頼します。ブランチ: feature/$branch_name'

実装を開始してください。"

        tmux send-keys -t "${TEAM_PANES[$team_num]}" "$full_task" C-m
        tmux send-keys -t "$MANAGER_PANE" "[MANAGER] チーム${team_letter}に「$task」(ブランチ: feature/$branch_name)を依頼しました" C-m
        echo "📋 タスク割り当て: チーム$team_letter → $task (feature/$branch_name)"
    else
        echo "❌ 無効なチーム番号: $team_num (0-$((${#TEAM_PANES[@]} - 1)))"
    fi
}

# 全体統合テストフェーズ開始
start_integration_testing() {
    DEVELOPMENT_PHASE="integration-testing"

    local test_prompt="【全体統合テストフェーズ開始】

develop branchに対して包括的な統合テストを実行してください。

QAチームに以下を指示してください：
1. develop branchの全体ビルドテスト
2. 統合テスト実行
3. E2Eテスト実行
4. パフォーマンステスト実行
5. セキュリティテスト実行
6. 統合テスト結果レポート作成

テスト結果を docs/tests/integration-test-report.md に整理してください。"

    tmux send-keys -t "$MANAGER_PANE" "$test_prompt" C-m
    tmux send-keys -t "$QA_PANE" "全体統合テストフェーズ開始。develop branchに対して包括的なテストを実行し、リリース可否を判定してください。" C-m
    echo "🧪 全体統合テストフェーズを開始"
}

# リリースフェーズ開始
start_release() {
    DEVELOPMENT_PHASE="release"

    local release_prompt="【リリースフェーズ開始】

統合テスト結果を基に、リリース準備を進めてください：

1. リリースノート作成
2. バージョンタグ付け
3. 本番環境デプロイ準備
4. ロールバック計画作成
5. 監視・アラート設定確認

QAチームと連携してリリース判定を行ってください。"

    tmux send-keys -t "$MANAGER_PANE" "$release_prompt" C-m
    echo "🚀 リリースフェーズを開始"
}

# ワークフロー専用エイリアス
alias requirements='start_requirements'
alias design='start_design'
alias implementation='start_implementation'
alias task-assign='assign_pro_task'
alias integration-testing='start_integration_testing'
alias release='start_release'
