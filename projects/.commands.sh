#!/bin/bash
# Claude Pro Dev コマンド

export MANAGER_PANE="%0"
export QA_PANE="%3"
export TEAM_PANES=(%1 %4 %2 %5)
export WORKSPACE_DIR="/Users/masa/dev/claude-automation/projects"
export SCRIPT_DIR="/Users/masa/dev/claude-automation"
export SESSION_NAME="claude-pro-dev"
export PROJECT_NAME="my-project"
export DEVELOPMENT_PHASE="requirements"

# プロジェクト状態を保存
save_project_state() {
    local phase="$1"
    local details="$2"
    local state_file="$WORKSPACE_DIR/.project_state"
    
    {
        echo "PROJECT_NAME=$PROJECT_NAME"
        echo "DEVELOPMENT_PHASE=$phase"
        echo "LAST_UPDATE=$(date)"
        echo "DETAILS=$details"
    } > "$state_file"
}

# プロジェクト状態を読み込み
load_project_state() {
    local state_file="$WORKSPACE_DIR/.project_state"
    
    if [ -f "$state_file" ]; then
        source "$state_file"
        echo "📋 前回の状態を復元しました:"
        echo "  プロジェクト: $PROJECT_NAME"
        echo "  フェーズ: $DEVELOPMENT_PHASE"
        echo "  最終更新: $LAST_UPDATE"
        echo ""
        echo "💡 ヒント: resume で前回の続きから再開"
        return 0
    else
        echo "❌ 保存された状態が見つかりません"
        return 1
    fi
}

# 作業を再開
resume() {
    if load_project_state; then
        echo "🔄 作業を再開します..."
        
        case "$DEVELOPMENT_PHASE" in
            "requirements")
                echo "→ 要件定義フェーズから再開"
                echo "→ docs/requirements/ を確認してください"
                ;;
            "design")
                echo "→ 設計フェーズから再開"
                echo "→ docs/design/ を確認してください"
                ;;
            "implementation")
                echo "→ 実装フェーズから再開"
                echo "→ 各チームの成果物を確認してください"
                # 各チームに状況確認を送信
                progress
                ;;
            *)
                echo "→ 不明なフェーズ: $DEVELOPMENT_PHASE"
                ;;
        esac
    fi
}

# ヘルプ関数
help() {
    echo "📚 Claude Pro Dev - 利用可能なコマンド"
    echo ""
    echo "【初期設定】"
    echo "  start-claude - 全ペインでClaudeを起動（最初に実行）"
    echo ""
    echo "【開発フェーズ】"
    echo "  requirements '<説明>'     - 要件定義フェーズ開始"
    echo "  design                   - 設計フェーズ開始"
    echo "  implementation           - 実装フェーズ開始"
    echo "  integration-test         - 統合テストフェーズ"
    echo ""
    echo "【タスク管理】"
    echo "  task-assign <番号> '<説明>' '<ブランチ>' - タスク割り当て"
    echo "  qa-check <チーム> '<ブランチ>'          - QAチェック依頼"
    echo ""
    echo "【ナレッジ管理】"
    echo "  import-knowledge '<URL>' '<説明>' - 外部知識をインポート"
    echo ""
    echo "【その他】"
    echo "  status       - プロジェクト状況確認"
    echo "  progress     - 進捗確認"
    echo "  resume       - 前回の続きから再開"
    echo "  clear-all    - 全ペインクリア"
    echo "  exit-project - プロジェクト終了"
}

# 要件定義フェーズ
requirements() {
    local project_desc="$1"
    if [ -z "$project_desc" ]; then
        echo "使用方法: requirements '<プロジェクト説明>'"
        return 1
    fi
    
    export DEVELOPMENT_PHASE="requirements"
    echo "[MANAGER] 要件定義フェーズを開始: $project_desc"
    
    # 状態を保存
    save_project_state "requirements" "$project_desc"
    
    # QAペインでClaudeに指示を送信
    send_to_claude "%3" "プロジェクト『$project_desc』の要件定義書を作成してください。以下の形式でdocs/requirements/requirements.mdに保存してください：1. プロジェクト概要、2. 機能要件、3. 非機能要件、4. 制約事項"
}

# 設計フェーズ
design() {
    export DEVELOPMENT_PHASE="design"
    echo "[MANAGER] 設計フェーズを開始"
    
    # 状態を保存
    save_project_state "design" "設計フェーズ"
    
    # QAペインでClaudeに指示を送信
    send_to_claude "%3" "要件定義書を基に、以下の設計書を作成してください：1. docs/design/architecture.md - システムアーキテクチャ設計、2. docs/design/database.md - データベース設計（必要な場合）、3. docs/tasks/task-breakdown.md - タスク分解"
}

# 実装フェーズ
implementation() {
    export DEVELOPMENT_PHASE="implementation"
    echo "[MANAGER] 実装フェーズを開始"
    echo "→ タスクを自動的に各チームに割り当てます"
    
    # 状態を保存
    save_project_state "implementation" "実装フェーズ"
    
    # 各開発チームに自動的にタスクを割り当て
    local tasks=(
        "Next.jsプロジェクトのセットアップと基本構成を実装してください。package.json、tsconfig.json、next.config.jsなどの初期設定を含めてください。"
        "共通レイアウトコンポーネントとナビゲーションを実装してください。ヘッダー、フッター、サイドバーなどの基本UIコンポーネントを作成してください。"
        "ホームページとメインのページコンポーネントを実装してください。ルーティング設定も含めて実装してください。"
        "APIルートとデータ取得ロジックを実装してください。必要に応じてモックデータも作成してください。"
    )
    
    local i=0
    for pane in ${TEAM_PANES[@]}; do
        local team_letter=$(printf "\x$(printf %x $((65 + i)))")
        if [ $i -lt ${#tasks[@]} ]; then
            send_to_claude "$pane" "チーム$team_letter: ${tasks[$i]}"
            echo "  → チーム$team_letter: タスク$((i+1))を割り当て"
        else
            send_to_claude "$pane" "チーム$team_letter: 他のチームのサポートとコードレビューを担当してください。"
            echo "  → チーム$team_letter: サポート役を割り当て"
        fi
        ((i++))
    done
    
    echo ""
    echo "✅ タスク割り当て完了"
}

# タスク割り当て
task-assign() {
    local team_num="$1"
    local task_desc="$2"
    local branch_name="$3"
    
    if [ -z "$team_num" ] || [ -z "$task_desc" ] || [ -z "$branch_name" ]; then
        echo "使用方法: task-assign <チーム番号> '<タスク説明>' '<ブランチ名>'"
        return 1
    fi
    
    if [ "$team_num" -ge "${#TEAM_PANES[@]}" ]; then
        echo "エラー: チーム番号が範囲外です"
        return 1
    fi
    
    local team_letter=$(printf "\x$(printf %x $((65 + team_num)))")
    echo "[MANAGER] チーム$team_letter にタスク割り当て: $task_desc"
    
    # 開発チームに指示を送信
    send_to_claude "${TEAM_PANES[$team_num]}" "タスク: $task_desc\nブランチ: feature/$branch_name で作業してください。\ngit checkout -b feature/$branch_name を実行して開始してください。"
}

# QAチェック依頼
qa-check() {
    local team_letter="$1"
    local branch_name="$2"
    
    if [ -z "$team_letter" ] || [ -z "$branch_name" ]; then
        echo "使用方法: qa-check <チーム文字> '<ブランチ名>'"
        return 1
    fi
    
    echo "[MANAGER] QAチェック依頼: チーム$team_letter - $branch_name"
    
    # QAチームに指示を送信
    send_to_claude "%3" "QAチェック依頼: チーム$team_letter のブランチ feature/$branch_name をテストしてください。\n品質チェックを実施し、結果をdocs/tests/に記録してください。"
}

# ナレッジインポート
import-knowledge() {
    local url="$1"
    local desc="$2"
    
    if [ -z "$url" ]; then
        echo "使用方法: import-knowledge '<URL>' '<説明>'"
        return 1
    fi
    
    echo "[MANAGER] ナレッジインポート: $desc"
    echo "URL: $url"
    
    # QAチームに指示を送信
    send_to_claude "%3" "ナレッジインポート: $desc\nURL: $url の内容を分析して、プロジェクトに関連する重要な情報を抽出してください。\n分析結果をdocs/knowledge/に保存してください。"
}

# ステータス確認
status() {
    echo "📊 プロジェクトステータス"
    echo "  プロジェクト名: $PROJECT_NAME"
    echo "  現在のフェーズ: $DEVELOPMENT_PHASE"
    echo "  作業ディレクトリ: $WORKSPACE_DIR"
    echo "  開発チーム数: 4"
}

# 進捗確認（シンプル版）
progress() {
    echo "[MANAGER] 全チーム進捗確認"
    echo "→ 各チームに進捗報告を依頼しました"
    
    # QAペインに送信
    send_to_claude "%3" "現在の進捗状況を報告してください。"
    
    # 各開発チームに送信
    local num_teams=$(tmux list-panes -t "claude-pro-dev" -F "#{pane_id}" | wc -l)
    num_teams=$((num_teams - 2))  # マネージャーとQAを除く
    
    for i in $(seq 0 $((num_teams - 1))); do
        local team_letter=$(printf "\x$(printf %x $((65 + i)))")
        local pane_id="${TEAM_PANES[$i]}"
        if [ -n "$pane_id" ]; then
            send_to_claude "$pane_id" "チーム$team_letter: 現在の進捗状況を報告してください。"
        fi
    done
    
    echo ""
    echo "💡 各ペインで報告を確認: Ctrl+b → 矢印キー"
}

# 進捗報告の確認
check-progress() {
    local report_dir="$WORKSPACE_DIR/reports/progress"
    
    if [ ! -d "$report_dir" ]; then
        echo "❌ 進捗報告がまだありません"
        return 1
    fi
    
    echo "📊 進捗報告の状況:"
    echo ""
    
    # QAチームの報告確認
    if ls "$report_dir"/qa_*.txt 1> /dev/null 2>&1; then
        echo "✅ QAチーム: 報告済み"
    else
        echo "⏳ QAチーム: 報告待ち"
    fi
    
    # 各開発チームの報告確認
    for letter in A B C D; do
        if ls "$report_dir"/team${letter}_*.txt 1> /dev/null 2>&1; then
            echo "✅ チーム$letter: 報告済み"
        else
            echo "⏳ チーム$letter: 報告待ち"
        fi
    done
    
    echo ""
    
    # 全員の報告が揃ったか確認
    local total_files=$(ls "$report_dir"/*.txt 2>/dev/null | wc -l)
    local expected_files=$((1 + ${#TEAM_PANES[@]}))  # QA + 開発チーム数
    
    if [ "$total_files" -ge "$expected_files" ]; then
        echo "🎉 全チームの報告が揃いました！"
        echo ""
        echo "使用可能なコマンド:"
        echo "  summary-progress - 進捗サマリーを生成"
    fi
}

# 進捗サマリーの生成
summary-progress() {
    local report_dir="$WORKSPACE_DIR/reports/progress"
    
    if [ ! -d "$report_dir" ]; then
        echo "❌ 進捗報告がありません"
        return 1
    fi
    
    echo "📋 進捗サマリー"
    echo "=================="
    echo ""
    
    # QAチームの報告
    if ls "$report_dir"/qa_*.txt 1> /dev/null 2>&1; then
        echo "【QAチーム】"
        cat "$report_dir"/qa_*.txt | head -n 10
        echo ""
    fi
    
    # 各開発チームの報告
    for letter in A B C D; do
        if ls "$report_dir"/team${letter}_*.txt 1> /dev/null 2>&1; then
            echo "【チーム$letter】"
            cat "$report_dir"/team${letter}_*.txt | head -n 10
            echo ""
        fi
    done
    
    # サマリーファイルに保存
    local summary_file="$WORKSPACE_DIR/reports/progress_summary_$(date +%Y%m%d_%H%M%S).md"
    {
        echo "# 進捗報告サマリー"
        echo "日時: $(date)"
        echo ""
        
        if ls "$report_dir"/qa_*.txt 1> /dev/null 2>&1; then
            echo "## QAチーム"
            cat "$report_dir"/qa_*.txt
            echo ""
        fi
        
        for letter in A B C D; do
            if ls "$report_dir"/team${letter}_*.txt 1> /dev/null 2>&1; then
                echo "## チーム$letter"
                cat "$report_dir"/team${letter}_*.txt
                echo ""
            fi
        done
    } > "$summary_file"
    
    echo ""
    echo "✅ サマリーを保存しました: $summary_file"
}

# 全ペインクリア
clear-all() {
    for pane in "%0" "%3" ${TEAM_PANES[@]}; do
        tmux send-keys -t "$pane" "clear" C-m
    done
    echo "✅ 全ペインをクリアしました"
}

# プロジェクト終了
exit-project() {
    echo "🧹 プロジェクトを終了しています..."
    
    # 各ペインでexitを送信
    for pane in "%3" ${TEAM_PANES[@]}; do
        tmux send-keys -t "$pane" C-c 2>/dev/null
        sleep 0.2
        tmux send-keys -t "$pane" "exit" C-m 2>/dev/null
    done
    
    sleep 1
    tmux kill-session -t "claude-pro-dev" 2>/dev/null
    
    echo "✅ プロジェクト終了"
    exit 0
}

# エイリアス
alias st='status'
alias pg='progress'

# Claudeにメッセージを送信（エスケープ対応版）
send_to_claude() {
    local pane_id="$1"
    local message="$2"
    
    # メッセージをエスケープして送信
    tmux send-keys -t "$pane_id" -l "$message"
    tmux send-keys -t "$pane_id" C-m
}

# Claude起動コマンド（シンプル版）
start-claude() {
    echo "🚀 全ペインでClaudeを起動します..."
    
    # 全ペインで同時にclaudeを起動
    tmux send-keys -t "%3" "claude" C-m
    for pane in ${TEAM_PANES[@]}; do
        tmux send-keys -t "$pane" "claude" C-m
    done
    
    echo "✅ Claude起動完了"
}

echo "🎯 Claude Pro Dev 準備完了！"
echo "helpでコマンド一覧を表示"
echo ""
echo "💡 ヒント: start-claude で全ペインでClaudeを起動"
