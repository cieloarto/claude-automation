#!/bin/bash

# Claude 基本機能スクリプト

# 文字変換ヘルパー
chr() {
    printf "\\$(printf '%03o' "$1")"
}

# バッファクリア関数
clear_buffers() {
    local target="${1:-all}"
    
    case "$target" in
        "all")
            echo "🧹 全ペインのバッファをクリア中..."
            tmux list-panes -t "$SESSION_NAME" -F "#{pane_id}" | while read -r pane_id; do
                tmux clear-history -t "$SESSION_NAME:$pane_id"
            done
            echo "✅ 全バッファクリア完了"
            ;;
        "manager")
            tmux clear-history -t "$MANAGER_PANE"
            echo "✅ マネージャーバッファクリア完了"
            ;;
        "qa")
            tmux clear-history -t "$QA_PANE"
            echo "✅ QAバッファクリア完了"
            ;;
        [0-9]*)
            if [ "$target" -lt "${#TEAM_PANES[@]}" ]; then
                tmux clear-history -t "${TEAM_PANES[$target]}"
                echo "✅ チーム$(chr $((65 + target)))バッファクリア完了"
            else
                echo "❌ 無効なチーム番号: $target"
            fi
            ;;
        *)
            echo "使用方法: clear-buffers [all|manager|qa|<チーム番号>]"
            ;;
    esac
}

# バッファ使用状況確認
check_buffer_usage() {
    echo "📊 バッファ使用状況:"
    tmux list-panes -t "$SESSION_NAME" -F "#{pane_title}: #{history_size}/#{history_limit}" | while read -r line; do
        echo "  $line"
    done
}

# tmux再描画
refresh_display() {
    echo "🔄 tmux表示を再描画中..."
    tmux refresh-client -t "$SESSION_NAME"
    echo "✅ 再描画完了"
}

# プロジェクトマネージャーを初期化
init_manager() {
    # プロンプトをファイルに書き出してから送信
    cat > /tmp/manager_init_prompt.txt << 'MANAGEREOF'
あなたはシニアプロジェクトマネージャーです。

【作業ディレクトリ】
$WORKSPACE_DIR

【重要】全ての作業は以下で開始してください：
cd '$WORKSPACE_DIR' && 

【開発フェーズ】
- 要件定義フェーズ (requirements)
- 設計フェーズ (design) 
- 実装フェーズ (implementation)
- 全体テストフェーズ (integration-testing)
- リリースフェーズ (release)

【ドキュメント管理】
- 要件定義: docs/requirements/requirements.md
- 設計書: docs/design/architecture.md, docs/design/database.md
- タスク管理: docs/tasks/task-breakdown.md
- テスト仕様: docs/tests/test-specifications.md
- ナレッジ: docs/knowledge/claude.md (指示ファイル)

【チーム構成】
MANAGEREOF

    # チーム構成を動的に追加
    for i in ${!TEAM_PANES[@]}; do
        echo "- チーム$(chr $((65 + i))): 開発担当" >> /tmp/manager_init_prompt.txt
    done
    
    # 残りの部分を追加
    cat >> /tmp/manager_init_prompt.txt << 'MANAGEREOF2'
- QA & テストチーム: 品質ゲート・PR管理・全体テスト

【改良されたワークフロー】
- 開発チーム実装完了 → QAに品質チェック依頼
- QA品質チェック → 合格なら自動PR作成 / 不合格なら差し戻し
- PR作成後 → QAが自動レビュー承認
- 全体テスト → develop branchの統合品質確認

【報告形式】
'[MANAGER] ○○フェーズを開始' の形式で報告してください。

初期化完了です。プロジェクトの要件をお待ちしています。
MANAGEREOF2

    # ファイルから読み込んで送信
    tmux send-keys -t "$MANAGER_PANE" "cat /tmp/manager_init_prompt.txt" C-m
    sleep 0.5
    rm -f /tmp/manager_init_prompt.txt
}

# 開発チームを初期化
init_teams() {
    for i in ${!TEAM_PANES[@]}; do
        local team_letter=$(chr $((65 + i)))
        
        # プロンプトをファイルに書き出してから送信
        cat > "/tmp/team_${i}_init_prompt.txt" << TEAMEOF
あなたはチーム${team_letter}のシニア開発者です。

【役割】
- 要件に基づく高品質な実装
- 単体テストの作成・実行 (必須)
- Git ワークフロー管理

【改良されたワークフロー】
- 実装完了後、必ずQAチームに品質チェック依頼
- QAチェック不合格時は修正対応
- QAチェック合格後、自動でPR作成される

【Git ワークフロー】
- feature/<task-name> ブランチ作成
- git worktree でブランチ分離
- 実装 + 単体テスト作成
- テスト実行確認 (npm test / yarn test)
- QAチームに品質チェック依頼

【品質基準】
- 単体テストカバレッジ 80%以上
- ESLint / Prettier準拠
- TypeScript型安全性確保
- セキュリティベストプラクティス遵守

【報告形式】
- 作業開始: '[チーム${team_letter}] ブランチ○○で○○の実装開始'
- 完了報告: '[チーム${team_letter}] ○○実装完了、QAチームに品質チェック依頼'
- 修正対応: '[チーム${team_letter}] QA指摘事項修正完了、再チェック依頼'
- 質問・相談: '[チーム${team_letter}] 技術相談: ○○について'

チーム${team_letter}準備完了です。
TEAMEOF

        # ファイルから読み込んで送信
        tmux send-keys -t "${TEAM_PANES[$i]}" "cat /tmp/team_${i}_init_prompt.txt" C-m
        sleep 0.5
        rm -f "/tmp/team_${i}_init_prompt.txt"
    done
}

# 全チーム初期化
init_all_teams() {
    echo "🔧 開発組織を初期化中..."
    init_manager
    sleep 1
    init_qa_team # claude-qa.sh から
    sleep 1
    init_teams
}

# ナレッジインポート
import_knowledge() {
    local url="$1"
    local description="$2"
    local knowledge_prompt="echo '$url $description' | claude

上記コマンドを実行して、得られた知識を docs/knowledge/claude.md に追記してください。
このプロジェクトで使用する技術スタック、ベストプラクティス、コーディング規約などを整理してください。"

    tmux send-keys -t "$MANAGER_PANE" "$knowledge_prompt" C-m
    echo "📚 ナレッジインポートを開始: $url"
}

# 進捗確認
check_pro_progress() {
    tmux send-keys -t "$MANAGER_PANE" "現在のプロジェクト進捗状況を以下の観点から報告してください：
1. 現在のフェーズ（$DEVELOPMENT_PHASE）
2. 各チームの作業状況
3. 完了したタスク
4. 残りのタスク
5. 品質状況（テスト結果等）
6. 次のアクション

詳細な進捗レポートをお願いします。" C-m
    echo "📊 プロジェクト進捗確認を依頼しました"
}

# 組織全体の状況確認
org_status() {
    echo "🏢 Claude組織 現在の状況"
    echo "========================"
    echo "👔 マネージャー:"
    tmux capture-pane -t "$MANAGER_PANE" -p | tail -3
    echo ""
    echo "🔍 QAチーム:"
    tmux capture-pane -t "$QA_PANE" -p | tail -3
    echo ""
    for i in ${!TEAM_PANES[@]}; do
        local team_letter=$(chr $((65 + i)))
        echo "👨‍💻 チーム$team_letter:"
        tmux capture-pane -t "${TEAM_PANES[$i]}" -p | tail -3
        echo ""
    done
}

# 組織全体クリア
org_clear_all() {
    echo "🧹 全チームをクリア中..."
    for pane in "$MANAGER_PANE" "$QA_PANE" "${TEAM_PANES[@]}"; do
        tmux send-keys -t "$pane" "/clear" C-m &
    done
    wait
    echo "✅ 全チームクリア完了"
}

# ヘルプ表示
show_pro_help() {
    echo "🏢 Claude プロフェッショナル開発環境 - コマンド一覧"
    echo "=========================================================="
    echo ""
    echo "📚 ナレッジ管理:"
    echo "  import-knowledge '<URL>' '<説明>'  - 外部知識のインポート"
    echo ""
    echo "📋 開発フェーズ:"
    echo "  requirements '<プロジェクト名>'     - 要件定義フェーズ開始"
    echo "  design                           - 設計フェーズ開始"
    echo "  implementation                   - 実装フェーズ開始"
    echo "  integration-test                 - 全体テスト実行"
    echo ""
    echo "⚙️ タスク管理:"
    echo "  task-assign <チーム番号> '<タスク>' '<ブランチ名>' - タスク割り当て"
    echo "  qa-check <チーム> '<ブランチ名>'    - QA品質チェック"
    echo ""
    echo "📊 進捗管理:"
    echo "  progress                         - 全体進捗確認"
    echo "  status                           - 現在の状況確認"
    echo "  phase                            - 現在のフェーズ確認"
    echo ""
    echo "🧹 管理:"
    echo "  clear-all                        - 全チームクリア"
    echo "  help                             - このヘルプ表示"
    echo ""
    echo "💡 改良されたワークフロー:"
    echo "  1. task-assign 0 'ユーザー認証実装' 'user-auth'"
    echo "  2. [チームA] 実装完了、QAチェック依頼"
    echo "  3. qa-check A user-auth"
    echo "  4. [QA] ✅合格 → 自動PR作成 / ❌不合格 → 差し戻し"
    echo "  5. integration-test (develop branch統合テスト)"
    echo ""
    echo "📂 現在の作業ディレクトリ: $WORKSPACE_DIR"
    echo "📊 現在のフェーズ: $DEVELOPMENT_PHASE"
}

# エイリアス設定
alias import-knowledge='import_knowledge'
alias progress='check_pro_progress'
alias status='org_status'
alias phase='echo "現在のフェーズ: $DEVELOPMENT_PHASE"'
alias clear-all='org_clear_all'
alias help='show_pro_help'
