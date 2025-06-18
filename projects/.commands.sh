#!/bin/bash

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

help() {
    echo "📚 Claude Pro Dev - コマンド一覧"
    echo ""
    echo "【タスク管理】"
    echo "  add-task '<タスク>'   - タスクをキューに追加"
    echo "  task-status          - 各チームの状況確認"
    echo "  team-done <チーム>   - チームのタスク完了報告"
    echo "  start-monitor        - 自動監視開始"
    echo ""
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
    else
        echo "✅ 全てのタスクが割り当て済みです"
    fi
}

# チームのタスク完了
team-done() {
    local team="$1"
    if [ -z "$team" ]; then
        echo "使用方法: team-done <チーム名(A/B/C/D)>"
        return 1
    fi
    
    echo "✅ チーム$team がタスクを完了しました: ${TEAM_CURRENT_TASK[$team]}"
    TEAM_STATUS[$team]="idle"
    
    # 次のタスクがあれば自動で割り当て
    if [ $TASK_INDEX -lt ${#TASKS[@]} ]; then
        echo "🔄 次のタスクを割り当てます..."
        assign-task-to-team "$team"
    else
        echo "🎉 チーム$team: 全タスク完了！"
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
    if [ ${#TASKS[@]} -gt 0 ]; then
        echo "残りタスク:"
        for ((i=$TASK_INDEX; i<${#TASKS[@]}; i++)); do
            echo "  - ${TASKS[$i]}"
        done
    fi
}

# 自動監視（簡易版）
start-monitor() {
    echo "🔍 自動監視機能"
    echo "💡 各チームの完了は 'team-done <チーム>' で報告してください"
    echo "💡 'task-status' で進捗を確認できます"
}

# 全チームにタスクを割り当て
assign-all() {
    local teams=(A B C D)
    for team in "${teams[@]}"; do
        if [ "${TEAM_STATUS[$team]}" = "idle" ] && [ $TASK_INDEX -lt ${#TASKS[@]} ]; then
            assign-task-to-team "$team"
        fi
    done
}

# 実装開始
implementation() {
    echo "[MANAGER] 実装フェーズ開始"
    
    # デフォルトタスクを追加（必要に応じて）
    if [ ${#TASKS[@]} -eq 0 ]; then
        echo "📝 デフォルトタスクを設定します..."
        add-task "共通レイアウトコンポーネントの実装"
        add-task "ナビゲーションシステムの構築"
        add-task "データ取得APIの実装"
        add-task "状態管理システムの構築"
        add-task "スタイリングシステムの実装"
        add-task "テスト環境のセットアップ"
    fi
    
    # 各チームに最初のタスクを割り当て
    assign-all
}

clear-all() {
    for i in {0..5}; do
        tmux send-keys -t "claude-pro-dev:0.$i" "clear" C-m
    done
}