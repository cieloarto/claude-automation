#!/bin/bash

# Claude プロフェッショナル開発環境
BASE_SESSION_NAME="claude-pro-dev"
WORK_DIR="$(pwd)/projects"

# 関数: 既存セッション表示
show_existing_sessions() {
    local sessions=$(tmux list-sessions 2>/dev/null | grep "^$BASE_SESSION_NAME" | cut -d: -f1)
    if [ -z "$sessions" ]; then
        return 1
    fi
    
    echo "🔍 既存のプロジェクトセッション:"
    echo "================================"
    local count=1
    while IFS= read -r session; do
        local project_name=$(echo "$session" | sed "s/^$BASE_SESSION_NAME-//")
        echo "  $count) $project_name"
        count=$((count + 1))
    done <<< "$sessions"
    echo "  $count) 新規プロジェクト作成"
    echo "  0) 終了"
    echo ""
    return 0
}

# 関数: セッション選択
select_session() {
    local sessions=($(tmux list-sessions 2>/dev/null | grep "^$BASE_SESSION_NAME" | cut -d: -f1))
    local session_count=${#sessions[@]}
    
    while true; do
        read -p "選択してください (0-$((session_count + 1))): " choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            if [ "$choice" -eq 0 ]; then
                echo "終了します。"
                exit 0
            elif [ "$choice" -eq $((session_count + 1)) ]; then
                return 1  # 新規作成
            elif [ "$choice" -ge 1 ] && [ "$choice" -le "$session_count" ]; then
                local selected_session="${sessions[$((choice - 1))]}"
                echo "📱 セッション '$selected_session' にアタッチします..."
                tmux attach-session -t "$selected_session"
                exit 0
            fi
        fi
        echo "❌ 無効な選択です。0-$((session_count + 1)) の数字を入力してください。"
    done
}

# 関数: プロジェクト名入力
get_project_name() {
    while true; do
        read -p "📝 プロジェクト名を入力してください: " project_name
        if [ -n "$project_name" ] && [[ "$project_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            echo "$project_name"
            return 0
        fi
        echo "❌ プロジェクト名は英数字、ハイフン、アンダースコアのみ使用可能です。"
    done
}

# 関数: チーム数入力
get_team_count() {
    echo "👥 開発チーム数を選択してください (偶数のみ):" >&2
    echo "  2, 4, 6, 8 のいずれかを入力 (デフォルト: 4)" >&2
    
    while true; do
        read -p "チーム数 [4]: " team_count
        
        # デフォルト値
        if [ -z "$team_count" ]; then
            team_count=4
        fi
        
        # 数値チェック
        if [[ "$team_count" =~ ^[0-9]+$ ]]; then
            case "$team_count" in
                2|4|6|8)
                    echo "$team_count"
                    return 0
                    ;;
                *)
                    echo "❌ 2, 4, 6, 8 のいずれかを入力してください。" >&2
                    ;;
            esac
        else
            echo "❌ 数字を入力してください。" >&2
        fi
    done
}

# 関数: 動的レイアウト作成
create_layout() {
    local session_name="$1"
    local team_count="$2"
    
    echo "📐 $team_count チーム用レイアウトを作成中..."
    
    # 基本セッション作成
    tmux new-session -d -s "$session_name" -c "$WORK_DIR"
    
    case "$team_count" in
        2)
            # 2チーム: [PM][TeamA]
            #         [QA][TeamB]
            tmux split-window -h -t "$session_name:0" -p 50
            tmux select-pane -t "$session_name:0.0"
            tmux split-window -v -t "$session_name:0.0" -p 70
            tmux select-pane -t "$session_name:0.2"
            tmux split-window -v -t "$session_name:0.2" -p 50
            ;;
        4)
            # 4チーム: [PM][TeamA][TeamC]
            #         [QA][TeamB][TeamD]
            tmux split-window -h -t "$session_name:0" -p 66
            tmux split-window -h -t "$session_name:0.1" -p 50
            tmux select-pane -t "$session_name:0.0"
            tmux split-window -v -t "$session_name:0.0" -p 70
            tmux select-pane -t "$session_name:0.2"
            tmux split-window -v -t "$session_name:0.2" -p 50
            tmux select-pane -t "$session_name:0.4"
            tmux split-window -v -t "$session_name:0.4" -p 50
            ;;
        6)
            # 6チーム: [PM][TeamA][TeamC][TeamE]
            #         [QA][TeamB][TeamD][TeamF]
            tmux split-window -h -t "$session_name:0" -p 75
            tmux split-window -h -t "$session_name:0.1" -p 66
            tmux split-window -h -t "$session_name:0.2" -p 50
            tmux select-pane -t "$session_name:0.0"
            tmux split-window -v -t "$session_name:0.0" -p 70
            tmux select-pane -t "$session_name:0.2"
            tmux split-window -v -t "$session_name:0.2" -p 50
            tmux select-pane -t "$session_name:0.4"
            tmux split-window -v -t "$session_name:0.4" -p 50
            tmux select-pane -t "$session_name:0.6"
            tmux split-window -v -t "$session_name:0.6" -p 50
            ;;
        8)
            # 8チーム: [PM][TeamA][TeamC][TeamE][TeamG]
            #         [QA][TeamB][TeamD][TeamF][TeamH]
            tmux split-window -h -t "$session_name:0" -p 80
            tmux split-window -h -t "$session_name:0.1" -p 75
            tmux split-window -h -t "$session_name:0.2" -p 66
            tmux split-window -h -t "$session_name:0.3" -p 50
            tmux select-pane -t "$session_name:0.0"
            tmux split-window -v -t "$session_name:0.0" -p 70
            tmux select-pane -t "$session_name:0.2"
            tmux split-window -v -t "$session_name:0.2" -p 50
            tmux select-pane -t "$session_name:0.4"
            tmux split-window -v -t "$session_name:0.4" -p 50
            tmux select-pane -t "$session_name:0.6"
            tmux split-window -v -t "$session_name:0.6" -p 50
            tmux select-pane -t "$session_name:0.8"
            tmux split-window -v -t "$session_name:0.8" -p 50
            ;;
    esac
}

# 関数: 環境設定
setup_environment() {
    local session_name="$1"
    local team_count="$2"
    local project_name="$3"
    
    # 作業ディレクトリ作成
    local project_dir="$WORK_DIR/$project_name"
    mkdir -p "$project_dir"
    mkdir -p "$project_dir/docs"/{requirements,design,tasks,tests,knowledge}
    
    # プロンプト設定
    cat > "$project_dir/.setup-manager.sh" << 'EOF'
export PS1='PM> '
source .commands.sh
EOF

    cat > "$project_dir/.setup-qa.sh" << 'EOF'
export PS1='QA> '
source .commands.sh
EOF

    # コマンドスクリプト作成（チーム数に応じて動的に調整）
    create_commands_script "$project_dir" "$team_count"
    
    # バナー作成
    create_banners "$project_dir" "$team_count"
    
    # 各ペインの初期化
    initialize_panes "$session_name" "$team_count" "$project_dir"
    
    # 自動Claude起動
    auto_start_claude "$session_name" "$team_count"
}

# 関数: コマンドスクリプト作成
create_commands_script() {
    local project_dir="$1"
    local team_count="$2"
    
    # チーム文字配列を動的に生成
    local teams=""
    for ((i=0; i<team_count; i++)); do
        teams="$teams $(printf "\\x$(printf %x $((65 + i)))")"
    done
    
    cat > "$project_dir/.commands.sh" << EOF
# タスク管理用の変数
declare -a TASKS=()
declare -A TEAM_STATUS
declare -A TEAM_CURRENT_TASK
TASK_INDEX=0
MONITORING=false
MONITOR_PID=""
TEAM_COUNT=$team_count

# チーム初期化
$(for ((i=0; i<team_count; i++)); do
    team_letter=$(printf "\\x$(printf %x $((65 + i)))")
    echo "TEAM_STATUS[$team_letter]=\"idle\""
done)

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
    echo "  team-done <チーム> \"<タスク名>\" - チームのタスク完了処理"
    echo "  assign-next          - 次のタスクを自動割り当て"
    echo ""
    echo "【QA・PR管理】"
    echo "  qa-approve <チーム> \"<タスク名>\" - QA承認とPR作成指示"
    echo "  pr-created <チーム>  - PR作成完了報告"
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
    tmux send-keys -t "\$SESSION_NAME:0.1" "claude --dangerously-skip-permissions" C-m
    # 開発チーム
    for ((i=2; i<=\$((TEAM_COUNT+1)); i++)); do
        tmux send-keys -t "\$SESSION_NAME:0.\$i" "claude --dangerously-skip-permissions" C-m
    done
}

requirements() {
    local desc="\$1"
    echo "[MANAGER] 要件定義: \$desc"
    tmux send-keys -t "\$SESSION_NAME:0.1" "プロジェクト『\$desc』の要件定義書を作成してください。機能を細かく分解して、実装タスクのリストも作成してください。" C-m
}

design() {
    echo "[MANAGER] 設計フェーズ開始"
    tmux send-keys -t "\$SESSION_NAME:0.1" "設計書を作成してください。また、各機能の実装優先度と想定工数も記載してください。" C-m
}

# タスク追加
add-task() {
    local task="\$1"
    if [ -z "\$task" ]; then
        echo "使用方法: add-task '<タスク説明>'"
        return 1
    fi
    TASKS+=("\$task")
    echo "✅ タスク追加: \$task"
    echo "📋 現在のタスク数: \${#TASKS[@]}"
}

# 実装フェーズ（改良版）
implementation() {
    echo "[MANAGER] 実装フェーズ開始"
    
    # デフォルトタスクを追加（必要に応じて）
    if [ \${#TASKS[@]} -eq 0 ]; then
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
    for ((i=2; i<=\$((TEAM_COUNT+1)); i++)); do 
        tmux send-keys -t "\$SESSION_NAME:0.\$i" C-m
        sleep 0.5
    done
}

# 全チームにタスクを割り当て
assign-all-teams() {
    local teams=($teams)
    for team in "\${teams[@]}"; do
        if [ "\${TEAM_STATUS[\$team]}" = "idle" ] && [ \$TASK_INDEX -lt \${#TASKS[@]} ]; then
            assign-task-to-team "\$team"
        fi
    done
}

# 特定チームにタスクを割り当て
assign-task-to-team() {
    local team="\$1"
    declare -A pane_map
    $(for ((i=0; i<team_count; i++)); do
        team_letter=$(printf "\\x$(printf %x $((65 + i)))")
        pane_num=$((i+2))
        echo "pane_map[$team_letter]=$pane_num"
    done)
    local pane="\${pane_map[\$team]}"
    
    if [ \$TASK_INDEX -lt \${#TASKS[@]} ]; then
        local task="\${TASKS[\$TASK_INDEX]}"
        
        # 空のタスクをスキップ
        if [ -z "\$task" ]; then
            echo "⚠️ 空のタスクをスキップします（インデックス: \$TASK_INDEX）"
            ((TASK_INDEX++))
            assign-task-to-team "\$team"
            return
        fi
        
        TEAM_STATUS[\$team]="working"
        TEAM_CURRENT_TASK[\$team]="\$task"
        
        echo "📌 チーム\$team に割り当て: \$task"
        sleep 1
        tmux send-keys -t "\$SESSION_NAME:0.\$pane" "チーム\$team: \$task を実装してください。完了後マネージャーペインで'team-done \$team \\\"\$task\\\"'実行。" C-m
        sleep 1
        tmux send-keys -t "\$SESSION_NAME:0.\$pane" C-m
        
        ((TASK_INDEX++))
    else
        echo "✅ 全てのタスクが割り当て済みです"
        TEAM_STATUS[\$team]="idle"
    fi
}

# チームのタスク完了（QAフロー付き）
team-done() {
    local team="\$1"
    local task_name="\$2"
    
    if [ -z "\$team" ]; then
        echo "使用方法: team-done <チーム名> [タスク名]"
        return 1
    fi
    
    # タスク名が引数で渡されていない場合は、配列から取得を試みる
    local completed_task
    if [ -n "\$task_name" ]; then
        completed_task="\$task_name"
    else
        completed_task="\${TEAM_CURRENT_TASK[\$team]}"
    fi
    
    # 空のタスクをチェック
    if [ -z "\$completed_task" ]; then
        echo "⚠️ チーム\$team: タスク名が指定されていません"
        echo "使用方法: team-done \$team \\\"タスク名\\\""
        return 1
    fi
    
    echo "✅ チーム\$team が開発完了: \$completed_task"
    
    # QAチームにテスト依頼
    echo "🔍 QAチームにテスト確認を依頼"
    tmux send-keys -t "\$SESSION_NAME:0.1" "QAテスト依頼: チーム\$team が『\$completed_task』完了。テスト・レビュー後マネージャーペインで'qa-approve \$team \\\"\$completed_task\\\"'実行してください。" C-m
    sleep 2
    tmux send-keys -t "\$SESSION_NAME:0.1" C-m
    
    # チームを一時的にQA待ち状態に
    TEAM_STATUS[\$team]="qa_review"
    
    # 次のタスクがあれば他のアイドルチームに割り当て
    if [ \$TASK_INDEX -lt \${#TASKS[@]} ]; then
        echo "🔄 他のチームに次のタスクを割り当てます..."
        local teams=($teams)
        for idle_team in "\${teams[@]}"; do
            if [ "\${TEAM_STATUS[\$idle_team]}" = "idle" ] && [ \$TASK_INDEX -lt \${#TASKS[@]} ]; then
                assign-task-to-team "\$idle_team"
                break
            fi
        done
    fi
}

# タスク状況確認
task-status() {
    echo "📊 タスク進捗状況"
    echo "=================="
    echo "完了: \$TASK_INDEX / \${#TASKS[@]} タスク"
    echo ""
    echo "チーム状況:"
    local teams=($teams)
    for team in "\${teams[@]}"; do
        echo -n "  チーム\$team: \${TEAM_STATUS[\$team]}"
        if [ "\${TEAM_STATUS[\$team]}" = "working" ]; then
            echo " - \${TEAM_CURRENT_TASK[\$team]}"
        else
            echo ""
        fi
    done
    echo ""
    echo "残りタスク:"
    for ((i=\$TASK_INDEX; i<\${#TASKS[@]}; i++)); do
        echo "  - \${TASKS[\$i]}"
    done
}

# 次のタスクを割り当て
assign-next() {
    assign-all-teams
}

# QA承認とPR作成フロー
qa-approve() {
    local team="\$1"
    local task_name="\$2"
    
    if [ -z "\$team" ]; then
        echo "使用方法: qa-approve <チーム名> [タスク名]"
        return 1
    fi
    
    # タスク名が引数で渡されていない場合は、配列から取得を試みる
    local current_task
    if [ -n "\$task_name" ]; then
        current_task="\$task_name"
    else
        current_task="\${TEAM_CURRENT_TASK[\$team]}"
    fi
    
    echo "✅ QA承認: チーム\$team の『\$current_task』"
    
    # PR作成指示
    declare -A pane_map
    $(for ((i=0; i<team_count; i++)); do
        team_letter=$(printf "\\x$(printf %x $((65 + i)))")
        pane_num=$((i+2))
        echo "pane_map[$team_letter]=$pane_num"
    done)
    local pane="\${pane_map[\$team]}"
    
    tmux send-keys -t "\$SESSION_NAME:0.\$pane" "QA承認完了！PR作成手順: 1.git add . 2.git commit -m 'feat: チーム\$team の \$current_task' 3.git push 4.gh pr create 完了後マネージャーペインで'pr-created \$team'実行" C-m
    sleep 2
    tmux send-keys -t "\$SESSION_NAME:0.\$pane" C-m
    
    # チームをPR作成待ち状態に
    TEAM_STATUS[\$team]="pr_creation"
}

# PR作成完了
pr-created() {
    local team="\$1"
    if [ -z "\$team" ]; then
        echo "使用方法: pr-created <チーム名>"
        return 1
    fi
    
    local current_task="\${TEAM_CURRENT_TASK[\$team]}"
    echo "🎉 PR作成完了: チーム\$team の『\$current_task』"
    echo "📊 タスク『\$current_task』が完全に完了しました！"
    
    # チームをアイドル状態に戻し、次のタスクを割り当て
    TEAM_STATUS[\$team]="idle"
    TEAM_CURRENT_TASK[\$team]=""
    
    # 次のタスクがあれば割り当て
    if [ \$TASK_INDEX -lt \${#TASKS[@]} ]; then
        echo "🔄 次のタスクを割り当てます..."
        assign-task-to-team "\$team"
    else
        echo "🎉 チーム\$team: 全タスク完了！"
    fi
}

clear-all() {
    for ((i=0; i<=\$((TEAM_COUNT+1)); i++)); do
        tmux send-keys -t "\$SESSION_NAME:0.\$i" "clear" C-m
    done
}

exit-project() {
    tmux kill-session -t "\$SESSION_NAME"
    exit 0
}
EOF
}

# 関数: バナー作成
create_banners() {
    local project_dir="$1"
    local team_count="$2"
    
    cat > "$project_dir/banner-manager.txt" << 'EOF'
╔════════════════════════════════════╗
║  プロジェクトマネージャー          ║
╚════════════════════════════════════╝
コマンド: help
EOF

    cat > "$project_dir/banner-qa.txt" << 'EOF'
╔════════════════════════════════════╗
║    QA & テストチーム               ║
╚════════════════════════════════════╝
EOF

    for ((i=0; i<team_count; i++)); do
        local team_letter=$(printf "\\x$(printf %x $((65 + i)))")
        local pane_num=$((i+2))
        
        cat > "$project_dir/banner-team-$pane_num.txt" << EOF
╔════════════════════════════════╗
║       開発チーム $team_letter              ║
╚════════════════════════════════════╝
EOF
    done
}

# 関数: ペイン初期化
initialize_panes() {
    local session_name="$1"
    local team_count="$2"
    local project_dir="$3"
    
    # マネージャー (左上)
    tmux send-keys -t "$session_name:0.0" "cd $project_dir && source .setup-manager.sh && SESSION_NAME=$session_name && sleep 1 && clear && cat banner-manager.txt" C-m
    
    # QA (左下)
    tmux send-keys -t "$session_name:0.1" "cd $project_dir && source .setup-qa.sh && SESSION_NAME=$session_name && sleep 1 && clear && cat banner-qa.txt" C-m
    
    # 開発チーム
    for ((i=0; i<team_count; i++)); do
        local team_letter=$(printf "\\x$(printf %x $((65 + i)))")
        local pane_num=$((i+2))
        
        cat > "$project_dir/.setup-team-$pane_num.sh" << EOF
export PS1='T$team_letter> '
source "$project_dir/.commands.sh"
EOF
        
        tmux send-keys -t "$session_name:0.$pane_num" "cd $project_dir && source .setup-team-$pane_num.sh && SESSION_NAME=$session_name && sleep 1 && clear && cat banner-team-$pane_num.txt" C-m
    done
}

# 関数: 自動Claude起動
auto_start_claude() {
    local session_name="$1"
    local team_count="$2"
    
    {
        sleep 5
        echo "🚀 Claudeを自動起動中..."
        
        # QAペイン
        tmux send-keys -t "$session_name:0.1" "claude --dangerously-skip-permissions" C-m
        
        # 開発チーム
        for ((i=2; i<=$((team_count+1)); i++)); do
            tmux send-keys -t "$session_name:0.$i" "claude --dangerously-skip-permissions" C-m
            sleep 0.5
        done
    } &
}

# メイン処理
main() {
    clear && printf '\033[3J'
    echo "🏢 Claude プロフェッショナル開発環境"
    echo "===================================="
    echo ""
    
    # 既存セッションの確認と表示
    if show_existing_sessions; then
        select_session
        # 新規作成が選択された場合、ここに到達
    fi
    
    # 新規プロジェクト作成
    echo "🆕 新規プロジェクトを作成します"
    echo ""
    
    local project_name=$(get_project_name)
    local team_count=$(get_team_count)
    local session_name="$BASE_SESSION_NAME-$project_name"
    
    # 既存の同名セッションがあれば削除
    tmux kill-session -t "$session_name" 2>/dev/null
    
    echo ""
    echo "🚀 プロジェクト '$project_name' を $team_count チームで起動中..."
    echo ""
    
    # レイアウト作成
    create_layout "$session_name" "$team_count"
    
    # 環境設定
    setup_environment "$session_name" "$team_count" "$project_name"
    
    echo "✅ セットアップ完了！"
    echo ""
    echo "📋 レイアウト: $team_count チーム構成"
    echo "💡 使い方:"
    echo "  - マネージャーペインで 'help' でコマンド確認"
    echo "  - 'requirements プロジェクト名' で開始"
    echo ""
    echo "※ 3秒後にClaudeが自動起動します"
    echo ""
    
    # アタッチ
    tmux attach-session -t "$session_name"
}

# スクリプト実行
main "$@"