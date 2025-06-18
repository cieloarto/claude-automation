help() {
    echo "📚 Claude Pro Dev - コマンド一覧"
    echo ""
    echo "【Claude管理】"
    echo "  claude-all           - 全ペインでClaude起動"
    echo ""
    echo "【開発フェーズ】"
    echo "  requirements '<説明>' - 要件定義開始"
    echo "  design               - 設計フェーズ"
    echo "  implementation       - 実装フェーズ"
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
    tmux send-keys -t "claude-pro-dev:0.1" "プロジェクト『$desc』の要件定義書を作成してください" C-m
}

design() {
    echo "[MANAGER] 設計フェーズ開始"
    tmux send-keys -t "claude-pro-dev:0.1" "設計書を作成してください" C-m
}

implementation() {
    echo "[MANAGER] 実装フェーズ開始"
    local teams=(A B C D)
    for i in {0..3}; do
        local pane=$((i + 2))
        tmux send-keys -t "claude-pro-dev:0.$pane" "チーム${teams[$i]}: 実装を開始してください" C-m
    done
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
