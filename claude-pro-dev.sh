#!/bin/bash

# Claude プロフェッショナル開発環境
SESSION_NAME="claude-pro-dev"
WORK_DIR="$(pwd)/projects"

# ターミナルクリア
clear && printf '\033[3J'

echo "🏢 Claude プロフェッショナル開発環境セットアップ中..."

# 既存セッション削除
tmux kill-session -t "$SESSION_NAME" 2>/dev/null

# 作業ディレクトリ作成
mkdir -p "$WORK_DIR"
mkdir -p "$WORK_DIR/docs"/{requirements,design,tasks,tests,knowledge}

# tmuxセッション作成
tmux new-session -d -s "$SESSION_NAME" -c "$WORK_DIR"

# 正しい6ペイン構成（3x2グリッド）
# まず垂直に3分割
tmux split-window -h -t "$SESSION_NAME:0" -p 66  # 残り66%を分割
tmux split-window -h -t "$SESSION_NAME:0.1" -p 50  # 残り50%を分割

# 各列を水平に2分割
tmux select-pane -t "$SESSION_NAME:0.0"
tmux split-window -v -t "$SESSION_NAME:0.0" -p 70  # マネージャーは小さめ

tmux select-pane -t "$SESSION_NAME:0.2"
tmux split-window -v -t "$SESSION_NAME:0.2" -p 50

tmux select-pane -t "$SESSION_NAME:0.4"
tmux split-window -v -t "$SESSION_NAME:0.4" -p 50

# プロンプト設定
cat > "$WORK_DIR/.setup-manager.sh" << 'EOF'
export PS1='PM> '
source .commands.sh
EOF

cat > "$WORK_DIR/.setup-qa.sh" << 'EOF'
export PS1='QA> '
source .commands.sh
EOF

# コマンドスクリプト
cat > "$WORK_DIR/.commands.sh" << 'EOF'
# タスク管理用の変数
declare -a TASKS=()
declare -A TEAM_STATUS
declare -A TEAM_CURRENT_TASK
TASK_INDEX=0
MONITORING=false
MONITOR_PID=""

# チーム初期化
TEAM_STATUS[A]="idle"
TEAM_STATUS[B]="idle"
TEAM_STATUS[C]="idle"
TEAM_STATUS[D]="idle"

help() {
    echo "📚 Claude Pro Dev - コマンド一覧"
    echo ""
    echo "【Claude管理】"
    echo "  claude-all           - 全ペインでClaude起動"
    echo ""
    echo "【開発フェーズ】"
    echo "  requirements '<説明>' - 要件定義開始"
    echo "  design               - 設計フェーズ"
    echo "  implementation       - 実装フェーズ開始"
    echo ""
    echo "【タスク管理】"
    echo "  add-task '<タスク>'   - タスクをキューに追加"
    echo "  task-status          - 各チームの状況確認"
    echo "  team-done <チーム>   - チームのタスク完了報告"
    echo "  assign-next          - 次のタスクを自動割り当て"
    echo ""
    echo "【自動監視】"
    echo "  start-monitor        - 自動監視開始"
    echo "  stop-monitor         - 自動監視停止"
    echo "  monitor-status       - 監視状況確認"
    echo ""
    echo "【その他】"
    echo "  clear-all            - 全ペインクリア"
    echo "  exit-project         - 終了"
}

claude-all() {
    echo "🚀 各ペインでClaudeを起動します..."
    # QAペイン
    tmux send-keys -t "claude-pro-dev:0.1" "claude --dangerously-skip-permissions" C-m
    # 開発チーム
    for i in {2..5}; do
        tmux send-keys -t "claude-pro-dev:0.$i" "claude --dangerously-skip-permissions" C-m
    done
}

requirements() {
    local desc="$1"
    echo "[MANAGER] 要件定義: $desc"
    tmux send-keys -t "claude-pro-dev:0.1" "プロジェクト『$desc』の要件定義書を作成してください。機能を細かく分解して、実装タスクのリストも作成してください。" C-m
}

design() {
    echo "[MANAGER] 設計フェーズ開始"
    tmux send-keys -t "claude-pro-dev:0.1" "設計書を作成してください。また、各機能の実装優先度と想定工数も記載してください。" C-m
}

# タスク追加
add-task() {
    local task="$1"
    if [ -z "$task" ]; then
        echo "使用方法: add-task '<タスク説明>'"
        return 1
    fi
    TASKS+=("$task")
    echo "✅ タスク追加: $task"
    echo "📋 現在のタスク数: ${#TASKS[@]}"
}

# 実装フェーズ（改良版）
implementation() {
    echo "[MANAGER] 実装フェーズ開始"
    
    # デフォルトタスクを追加（必要に応じて）
    if [ ${#TASKS[@]} -eq 0 ]; then
        echo "📝 デフォルトタスクを設定します..."
        add-task "プロジェクトの初期セットアップ（package.json、tsconfig.json等）"
        add-task "基本的なディレクトリ構造の作成"
        add-task "共通コンポーネントの実装（Header、Footer、Layout）"
        add-task "ルーティング設定とページコンポーネントの作成"
        add-task "データモデルとAPIクライアントの実装"
        add-task "状態管理の設定（Context/Redux等）"
        add-task "スタイリングシステムの構築"
        add-task "テスト環境のセットアップ"
    fi
    
    # 各チームに最初のタスクを割り当て
    assign-all-teams
    
    # 少し待ってから各チームで実行開始
    echo "🔄 各チームでタスク実行を開始します..."
    sleep 3
    for i in {2..5}; do 
        tmux send-keys -t "claude-pro-dev:0.$i" C-m
        sleep 0.5
    done
}

# 全チームにタスクを割り当て
assign-all-teams() {
    local teams=(A B C D)
    for team in "${teams[@]}"; do
        if [ "${TEAM_STATUS[$team]}" = "idle" ] && [ $TASK_INDEX -lt ${#TASKS[@]} ]; then
            assign-task-to-team "$team"
        fi
    done
}

# 特定チームにタスクを割り当て
assign-task-to-team() {
    local team="$1"
    declare -A pane_map=([A]=2 [B]=3 [C]=4 [D]=5)
    local pane="${pane_map[$team]}"
    
    if [ $TASK_INDEX -lt ${#TASKS[@]} ]; then
        local task="${TASKS[$TASK_INDEX]}"
        
        # 空のタスクをスキップ
        if [ -z "$task" ]; then
            echo "⚠️ 空のタスクをスキップします（インデックス: $TASK_INDEX）"
            ((TASK_INDEX++))
            assign-task-to-team "$team"
            return
        fi
        
        TEAM_STATUS[$team]="working"
        TEAM_CURRENT_TASK[$team]="$task"
        
        echo "📌 チーム$team に割り当て: $task"
        sleep 1
        tmux send-keys -t "claude-pro-dev:0.$pane" "チーム$team: $task を実装してください。完了後'team-done $team'実行。" C-m
        sleep 1
        tmux send-keys -t "claude-pro-dev:0.$pane" C-m
        
        ((TASK_INDEX++))
    else
        echo "✅ 全てのタスクが割り当て済みです"
        TEAM_STATUS[$team]="idle"
    fi
}

# チームのタスク完了（QAフロー付き）
team-done() {
    local team="$1"
    if [ -z "$team" ]; then
        echo "使用方法: team-done <チーム名(A/B/C/D)>"
        return 1
    fi
    
    local completed_task="${TEAM_CURRENT_TASK[$team]}"
    
    # 空のタスクをチェック
    if [ -z "$completed_task" ]; then
        echo "⚠️ チーム$team: 現在のタスクが設定されていません"
        return 1
    fi
    
    echo "✅ チーム$team が開発完了: $completed_task"
    
    # QAチームにテスト依頼
    echo "🔍 QAチームにテスト確認を依頼"
    tmux send-keys -t "claude-pro-dev:0.1" "QAテスト依頼: チーム$team が『$completed_task』完了。テスト・レビュー後'qa-approve $team'実行してください。" C-m
    sleep 1
    tmux send-keys -t "claude-pro-dev:0.1" C-m
    
    # チームを一時的にQA待ち状態に
    TEAM_STATUS[$team]="qa_review"
    
    # 次のタスクがあれば他のアイドルチームに割り当て
    if [ $TASK_INDEX -lt ${#TASKS[@]} ]; then
        echo "🔄 他のチームに次のタスクを割り当てます..."
        # アイドル状態のチームを探して割り当て
        for idle_team in A B C D; do
            if [ "${TEAM_STATUS[$idle_team]}" = "idle" ] && [ $TASK_INDEX -lt ${#TASKS[@]} ]; then
                assign-task-to-team "$idle_team"
                break
            fi
        done
    fi
}

# タスク状況確認
task-status() {
    echo "📊 タスク進捗状況"
    echo "=================="
    echo "完了: $TASK_INDEX / ${#TASKS[@]} タスク"
    echo ""
    echo "チーム状況:"
    for team in A B C D; do
        echo -n "  チーム$team: ${TEAM_STATUS[$team]}"
        if [ "${TEAM_STATUS[$team]}" = "working" ]; then
            echo " - ${TEAM_CURRENT_TASK[$team]}"
        else
            echo ""
        fi
    done
    echo ""
    echo "残りタスク:"
    for ((i=$TASK_INDEX; i<${#TASKS[@]}; i++)); do
        echo "  - ${TASKS[$i]}"
    done
}

# 次のタスクを割り当て
assign-next() {
    assign-all-teams
}

# QA承認とPR作成フロー
qa-approve() {
    local team="$1"
    if [ -z "$team" ]; then
        echo "使用方法: qa-approve <チーム名(A/B/C/D)>"
        return 1
    fi
    
    local current_task="${TEAM_CURRENT_TASK[$team]}"
    echo "✅ QA承認: チーム$team の『$current_task』"
    
    # PR作成指示
    declare -A pane_map=([A]=2 [B]=3 [C]=4 [D]=5)
    local pane="${pane_map[$team]}"
    
    tmux send-keys -t "claude-pro-dev:0.$pane" "QA承認完了！PR作成手順: 1.git add . 2.git commit -m 'feat: $current_task' 3.git push 4.gh pr create 完了後'pr-created $team'実行" C-m
    
    # チームをPR作成待ち状態に
    TEAM_STATUS[$team]="pr_creation"
}

# PR作成完了
pr-created() {
    local team="$1"
    if [ -z "$team" ]; then
        echo "使用方法: pr-created <チーム名(A/B/C/D)>"
        return 1
    fi
    
    local current_task="${TEAM_CURRENT_TASK[$team]}"
    echo "🎉 PR作成完了: チーム$team の『$current_task』"
    echo "📊 タスク『$current_task』が完全に完了しました！"
    
    # チームをアイドル状態に戻し、次のタスクを割り当て
    TEAM_STATUS[$team]="idle"
    TEAM_CURRENT_TASK[$team]=""
    
    # 次のタスクがあれば割り当て
    if [ $TASK_INDEX -lt ${#TASKS[@]} ]; then
        echo "🔄 次のタスクを割り当てます..."
        assign-task-to-team "$team"
    else
        echo "🎉 チーム$team: 全タスク完了！"
    fi
}

# 完全なワークフロー状況確認
workflow-status() {
    echo "📊 完全なワークフロー進捗"
    echo "========================"
    echo "完了: $TASK_INDEX / ${#TASKS[@]} タスク"
    echo ""
    echo "チーム状況:"
    for team in A B C D; do
        echo -n "  チーム$team: ${TEAM_STATUS[$team]}"
        if [ "${TEAM_STATUS[$team]}" = "working" ]; then
            echo " - ${TEAM_CURRENT_TASK[$team]}"
        else
            echo ""
        fi
    done
    echo ""
    if [ ${#TASKS[@]} -gt 0 ]; then
        echo "残りタスク:"
        for ((i=$TASK_INDEX; i<${#TASKS[@]}; i++)); do
            echo "  $((i+1)). ${TASKS[$i]}"
        done
    fi
}

clear-all() {
    for i in {0..5}; do
        tmux send-keys -t "claude-pro-dev:0.$i" "clear" C-m
    done
}

# 自動監視開始
start-monitor() {
    if [ "$MONITORING" = true ]; then
        echo "⚠️  監視は既に実行中です (PID: $MONITOR_PID)"
        return
    fi
    
    echo "🔍 自動監視を開始します..."
    MONITORING=true
    
    # バックグラウンドで監視プロセスを開始
    {
        while [ "$MONITORING" = true ]; do
            # 各チームのペインを監視
            for team in A B C D; do
                declare -A pane_map=([A]=2 [B]=3 [C]=4 [D]=5)
                local pane="${pane_map[$team]}"
                
                # ペインの最後の行を取得
                local last_line=$(tmux capture-pane -t "claude-pro-dev:0.$pane" -p | tail -1)
                
                # 完了キーワードを検知
                if [[ "$last_line" =~ (完了|finished|done|ready|終了|完成) ]] && [ "${TEAM_STATUS[$team]}" = "working" ]; then
                    echo ""
                    echo "🎯 [自動検知] チーム$team のタスク完了を検知しました"
                    echo "📝 完了メッセージ: $last_line"
                    team-done-auto "$team"
                fi
                
                # アイドル状態の検知（プロンプトが表示されている）
                if [[ "$last_line" =~ (T$team\>|\>) ]] && [ "${TEAM_STATUS[$team]}" = "working" ]; then
                    # 30秒間同じ状態なら完了とみなす
                    sleep 30
                    local current_line=$(tmux capture-pane -t "claude-pro-dev:0.$pane" -p | tail -1)
                    if [ "$last_line" = "$current_line" ] && [ "${TEAM_STATUS[$team]}" = "working" ]; then
                        echo ""
                        echo "⏰ [自動検知] チーム$team が長時間アイドル状態です"
                        echo "💡 タスク完了の可能性があります。'team-done $team' で確認してください。"
                    fi
                fi
            done
            
            # 5秒ごとに監視
            sleep 5
        done
    } &
    
    MONITOR_PID=$!
    echo "✅ 監視開始 (PID: $MONITOR_PID)"
    echo "💡 チームが完了キーワード（完了、finished、done等）を出力すると自動検知します"
}

# 自動監視停止
stop-monitor() {
    if [ "$MONITORING" = false ]; then
        echo "⚠️  監視は実行されていません"
        return
    fi
    
    echo "⏹️  自動監視を停止します..."
    MONITORING=false
    
    if [ -n "$MONITOR_PID" ]; then
        kill $MONITOR_PID 2>/dev/null
    fi
    
    echo "✅ 監視停止完了"
}

# 監視状況確認
monitor-status() {
    echo "📊 監視システム状況"
    echo "=================="
    if [ "$MONITORING" = true ]; then
        echo "状態: 🔍 監視中 (PID: $MONITOR_PID)"
        echo "監視対象: チームA, B, C, D"
        echo "検知キーワード: 完了, finished, done, ready, 終了, 完成"
    else
        echo "状態: ⏸️  停止中"
        echo "💡 'start-monitor' で監視を開始してください"
    fi
}

# 自動完了処理（監視システム用）
team-done-auto() {
    local team="$1"
    echo "🤖 [自動処理] チーム$team のタスクを完了処理します"
    
    echo "✅ チーム$team がタスクを完了しました: ${TEAM_CURRENT_TASK[$team]}"
    TEAM_STATUS[$team]="idle"
    
    # 次のタスクがあれば自動で割り当て
    if [ $TASK_INDEX -lt ${#TASKS[@]} ]; then
        echo "🔄 [自動割り当て] 次のタスクを割り当てます..."
        sleep 2  # 少し待ってから割り当て
        assign-task-to-team "$team"
    else
        echo "🎉 チーム$team: 全タスク完了！"
    fi
}

exit-project() {
    # 監視を停止
    stop-monitor
    tmux kill-session -t "claude-pro-dev"
    exit 0
}
EOF

# バナー作成
cat > "$WORK_DIR/banner-manager.txt" << 'EOF'
╔════════════════════════════════════╗
║  プロジェクトマネージャー          ║
╚════════════════════════════════════╝
コマンド: help
EOF

cat > "$WORK_DIR/banner-qa.txt" << 'EOF'
╔════════════════════════════════════╗
║    QA & テストチーム               ║
╚════════════════════════════════════╝
EOF

# 各ペインの初期化
# マネージャー (左上)
tmux send-keys -t "$SESSION_NAME:0.0" "cd $WORK_DIR && source .setup-manager.sh && sleep 1 && clear && cat banner-manager.txt" C-m

# QA (左下)
tmux send-keys -t "$SESSION_NAME:0.1" "cd $WORK_DIR && source .setup-qa.sh && sleep 1 && clear && cat banner-qa.txt" C-m

# 開発チーム (中央上下、右上下)
for i in {2..5}; do
    team_letter=$(printf "\x$(printf %x $((65 + i - 2)))")
    
    cat > "$WORK_DIR/.setup-team-$i.sh" << EOF
export PS1='T$team_letter> '
source "$WORK_DIR/.commands.sh"
EOF

    cat > "$WORK_DIR/banner-team-$i.txt" << EOF
╔════════════════════════════════╗
║       開発チーム $team_letter              ║
╚════════════════════════════════════╝
EOF

    tmux send-keys -t "$SESSION_NAME:0.$i" "cd $WORK_DIR && source .setup-team-$i.sh && sleep 1 && clear && cat banner-team-$i.txt" C-m
done

# 自動でClaude起動（遅延実行）
{
    sleep 5
    echo "🚀 Claudeを自動起動中..."
    
    # QAペイン
    tmux send-keys -t "$SESSION_NAME:0.1" "claude --dangerously-skip-permissions" C-m
    
    # 開発チーム
    for i in {2..5}; do
        tmux send-keys -t "$SESSION_NAME:0.$i" "claude --dangerously-skip-permissions" C-m
        sleep 0.5
    done
} &

echo ""
echo "✅ セットアップ完了！"
echo ""
echo "📋 レイアウト:"
echo "  [マネージャー] [チームA] [チームC]"
echo "  [QAチーム   ] [チームB] [チームD]"
echo ""
echo "💡 使い方:"
echo "  - マネージャーペインで 'help' でコマンド確認"
echo "  - 'requirements プロジェクト名' で開始"
echo ""
echo "※ 3秒後にClaudeが自動起動します"
echo ""

# アタッチ
tmux attach-session -t "$SESSION_NAME"