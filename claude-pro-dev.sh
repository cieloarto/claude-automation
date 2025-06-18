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
EOF

cat > "$WORK_DIR/.setup-qa.sh" << 'EOF'
export PS1='QA> '
EOF

# コマンドスクリプト
cat > "$WORK_DIR/.commands.sh" << 'EOF'
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
    echo "【その他】"
    echo "  clear-all            - 全ペインクリア"
    echo "  exit-project         - 終了"
}

claude-all() {
    echo "🚀 各ペインでClaudeを起動します..."
    # QAペイン
    tmux send-keys -t "claude-pro-dev:0.1" "claude" C-m
    # 開発チーム
    for i in {2..5}; do
        tmux send-keys -t "claude-pro-dev:0.$i" "claude" C-m
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
    local pane_map=(["A"]=2 ["B"]=3 ["C"]=4 ["D"]=5)
    local pane="${pane_map[$team]}"
    
    if [ $TASK_INDEX -lt ${#TASKS[@]} ]; then
        local task="${TASKS[$TASK_INDEX]}"
        TEAM_STATUS[$team]="working"
        TEAM_CURRENT_TASK[$team]="$task"
        
        echo "📌 チーム$team に割り当て: $task"
        tmux send-keys -t "claude-pro-dev:0.$pane" "チーム$team: 次のタスクを実装してください: $task" C-m
        tmux send-keys -t "claude-pro-dev:0.$pane" "完了したら、マネージャーペインで 'team-done $team' を実行してください。" C-m
        
        ((TASK_INDEX++))
    else
        echo "✅ 全てのタスクが割り当て済みです"
        TEAM_STATUS[$team]="idle"
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
    echo "残りタスク:"
    for ((i=$TASK_INDEX; i<${#TASKS[@]}; i++)); do
        echo "  - ${TASKS[$i]}"
    done
}

# 次のタスクを割り当て
assign-next() {
    assign-all-teams
}

clear-all() {
    for i in {0..5}; do
        tmux send-keys -t "claude-pro-dev:0.$i" "clear" C-m
    done
}

exit-project() {
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
tmux send-keys -t "$SESSION_NAME:0.0" "cd $WORK_DIR && source .setup-manager.sh && source .commands.sh && clear && cat banner-manager.txt" C-m

# QA (左下)
tmux send-keys -t "$SESSION_NAME:0.1" "cd $WORK_DIR && source .setup-qa.sh && clear && cat banner-qa.txt" C-m

# 開発チーム (中央上下、右上下)
for i in {2..5}; do
    team_letter=$(printf "\x$(printf %x $((65 + i - 2)))")
    
    cat > "$WORK_DIR/.setup-team-$i.sh" << EOF
export PS1='T$team_letter> '
EOF

    cat > "$WORK_DIR/banner-team-$i.txt" << EOF
╔════════════════════════════════╗
║       開発チーム $team_letter              ║
╚════════════════════════════════════╝
EOF

    tmux send-keys -t "$SESSION_NAME:0.$i" "cd $WORK_DIR && source .setup-team-$i.sh && clear && cat banner-team-$i.txt" C-m
done

# 自動でClaude起動（遅延実行）
{
    sleep 3
    echo "🚀 Claudeを自動起動中..."
    
    # QAペイン
    tmux send-keys -t "$SESSION_NAME:0.1" "claude" C-m
    
    # 開発チーム
    for i in {2..5}; do
        tmux send-keys -t "$SESSION_NAME:0.$i" "claude" C-m
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