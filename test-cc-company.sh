#!/bin/bash

# Claude Pro Dev環境のテストスクリプト
# 簡略化したバージョンで動作確認

SESSION_NAME="test-claude"
WORKSPACE_DIR="$(pwd)/test-workspace"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🧪 テスト環境セットアップ"
echo "セッション: $SESSION_NAME"
echo "作業ディレクトリ: $WORKSPACE_DIR"

# 作業ディレクトリ作成
mkdir -p "$WORKSPACE_DIR"

# tmuxセッション作成
tmux new-session -d -s "$SESSION_NAME" -c "$WORKSPACE_DIR"

# 画面分割
tmux split-window -h -t "$SESSION_NAME"
tmux select-pane -t 0
tmux split-window -v
tmux select-pane -t 2

# ペイン情報取得
PANE_INFO=$(tmux list-panes -t "$SESSION_NAME" -F "#{pane_index}:#{pane_id}")
declare -a PANE_IDS
while IFS=':' read -r index id; do
    PANE_IDS[$index]="$id"
done <<<"$PANE_INFO"

MANAGER_PANE="${PANE_IDS[0]}"
QA_PANE="${PANE_IDS[1]}"
TEAM_PANE="${PANE_IDS[2]}"

echo "マネージャー: $MANAGER_PANE"
echo "QA: $QA_PANE"
echo "チームA: $TEAM_PANE"

# 環境変数ファイル作成
cat > "$WORKSPACE_DIR/env.sh" << 'EOF'
export MANAGER_PANE="%0"
export QA_PANE="%1"
export TEAM_PANE="%2"
export WORKSPACE_DIR="$(pwd)"
export SESSION_NAME="test-claude"

# シンプルなコマンド定義
help() {
    echo "利用可能なコマンド:"
    echo "  help - このヘルプを表示"
    echo "  status - 現在の状態を表示"
    echo "  clear-all - 全バッファをクリア"
}

status() {
    echo "現在のディレクトリ: $(pwd)"
    echo "セッション: $SESSION_NAME"
}

clear-all() {
    tmux clear-history -t "$SESSION_NAME"
    echo "バッファをクリアしました"
}
EOF

# QAとチームでClaude起動
tmux send-keys -t "$QA_PANE" "echo 'QAチーム準備中...'" C-m
tmux send-keys -t "$TEAM_PANE" "echo 'チームA準備中...'" C-m

# マネージャーペインで環境設定
tmux send-keys -t "$MANAGER_PANE" "cd $WORKSPACE_DIR" C-m
tmux send-keys -t "$MANAGER_PANE" "source env.sh" C-m
tmux send-keys -t "$MANAGER_PANE" "echo '🎯 テスト環境準備完了!'" C-m
tmux send-keys -t "$MANAGER_PANE" "echo 'help でコマンド一覧表示'" C-m

# アタッチ
echo "アタッチします..."
tmux attach-session -t "$SESSION_NAME"