#!/bin/bash

# Claude シンプル開発環境
# 使用方法: ./claude-simple.sh

SESSION_NAME="claude-dev"
WORKSPACE_DIR="$(pwd)/workspace"

echo "🏢 Claude開発環境セットアップ"

# 既存セッションチェック
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "既存セッションにアタッチします..."
    tmux attach-session -t "$SESSION_NAME"
    exit 0
fi

# 作業ディレクトリ作成
mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

# tmuxセッション作成（シンプル版）
tmux new-session -d -s "$SESSION_NAME" -n "dev"

# 画面を3分割
tmux split-window -h -t "$SESSION_NAME"
tmux split-window -v -t "$SESSION_NAME:0.1"

# 各ペインにラベルを表示
tmux send-keys -t "$SESSION_NAME:0.0" "echo '=== マネージャー ===' && echo 'ここでコマンドを実行します'" C-m
tmux send-keys -t "$SESSION_NAME:0.1" "echo '=== QAチーム ===' && echo 'claude と入力してClaude Codeを起動'" C-m
tmux send-keys -t "$SESSION_NAME:0.2" "echo '=== 開発チーム ===' && echo 'claude と入力してClaude Codeを起動'" C-m

# 簡単なコマンドファイルを作成
cat > "$WORKSPACE_DIR/commands.sh" << 'EOF'
#!/bin/bash

# 利用可能なコマンド
help() {
    echo "📚 コマンド一覧:"
    echo "  help     - このヘルプを表示"
    echo "  status   - 現在の状態"
    echo "  clear    - 画面クリア"
    echo "  qa-msg   - QAチームにメッセージ送信"
    echo "  dev-msg  - 開発チームにメッセージ送信"
}

status() {
    echo "📊 現在の状態:"
    echo "  作業ディレクトリ: $(pwd)"
    echo "  セッション: $SESSION_NAME"
}

qa-msg() {
    local msg="$1"
    if [ -z "$msg" ]; then
        echo "使用方法: qa-msg 'メッセージ'"
        return
    fi
    tmux send-keys -t "$SESSION_NAME:0.1" "$msg" C-m
    echo "✅ QAチームに送信: $msg"
}

dev-msg() {
    local msg="$1"
    if [ -z "$msg" ]; then
        echo "使用方法: dev-msg 'メッセージ'"
        return
    fi
    tmux send-keys -t "$SESSION_NAME:0.2" "$msg" C-m
    echo "✅ 開発チームに送信: $msg"
}

echo "🎯 準備完了！helpでコマンド一覧を表示"
EOF

# マネージャーペインでコマンドを読み込み
tmux send-keys -t "$SESSION_NAME:0.0" "source $WORKSPACE_DIR/commands.sh" C-m

echo "✅ セットアップ完了！"
echo ""
echo "📋 次の手順:"
echo "1. QAチームと開発チームのペインで 'claude' を実行"
echo "2. マネージャーペインで 'help' を実行"
echo ""

# アタッチ
tmux attach-session -t "$SESSION_NAME"