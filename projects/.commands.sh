help() {
    echo "📚 Claude Pro Dev - コマンド一覧"
    echo ""
    echo "【タスク管理】"
    echo "  add-task '<タスク>'   - タスクをキューに追加"
    echo "  task-status          - 各チームの状況確認"
    echo "  team-done <チーム>   - チームのタスク完了報告"
    echo "  start-monitor        - 自動監視開始"
    echo "  stop-monitor         - 自動監視停止"
    echo ""
}

# タスク管理用の変数
declare -a TASKS=()
declare -A TEAM_STATUS
declare -A TEAM_CURRENT_TASK
TASK_INDEX=0

# チーム初期化
TEAM_STATUS[A]="idle"
TEAM_STATUS[B]="idle" 
TEAM_STATUS[C]="idle"
TEAM_STATUS[D]="idle"

# タスク追加
add-task() {
    local task="$1"
    TASKS+=("$task")
    echo "✅ タスク追加: $task"
}

# 特定チームにタスクを割り当て
assign-task-to-team() {
    local team="$1"
    local pane_map=(["A"]=2 ["B"]=3 ["C"]=4 ["D"]=5)
    local pane="${pane_map[$team]}"
    
    if [ $TASK_INDEX -lt ${#TASKS[@]} ]; then
        local task="${TASKS[$TASK_INDEX]}"
        TEAM_STATUS[$team]="working"
        TEAM_CURRENT_TASK[$team]="$task"
        
        echo "📌 チーム$team に割り当て: $task"
        tmux send-keys -t "claude-pro-dev:0.$pane" "チーム$team: 次のタスクを実装してください: $task" C-m
        
        ((TASK_INDEX++))
    fi
}

# チームのタスク完了
team-done() {
    local team="$1"
    echo "✅ チーム$team がタスクを完了しました"
    TEAM_STATUS[$team]="idle"
    
    if [ $TASK_INDEX -lt ${#TASKS[@]} ]; then
        assign-task-to-team "$team"
    fi
}

# タスク状況確認
task-status() {
    echo "📊 タスク進捗状況"
    echo "完了: $TASK_INDEX / ${#TASKS[@]} タスク"
    echo ""
    for team in A B C D; do
        echo "チーム$team: ${TEAM_STATUS[$team]}"
    done
}

# 自動監視（簡易版）
start-monitor() {
    echo "🔍 自動監視を開始します..."
    echo "💡 各チームの完了は 'team-done <チーム>' で報告してください"
}

stop-monitor() {
    echo "⏹️ 監視停止"
}
EOF < /dev/null