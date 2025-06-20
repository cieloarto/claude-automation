#!/bin/bash

# Claude チーム環境 - シンプル版
SESSION_NAME="claude-team"
WORK_DIR="$(pwd)/team-workspace"

# ターミナルクリア
clear && printf '\033[3J'

echo "🏢 Claude チーム環境セットアップ中..."

# 既存セッション削除
tmux kill-session -t "$SESSION_NAME" 2>/dev/null

# 作業ディレクトリ作成
mkdir -p "$WORK_DIR"

# バナーファイル作成
cat > "$WORK_DIR/banner-manager.txt" << 'EOF'
╔════════════════════════════╗
║   マネージャーペイン       ║
╚════════════════════════════╝

コマンド例:
  cat help.txt
EOF

cat > "$WORK_DIR/banner-qa.txt" << 'EOF'
╔════════════════════════════╗
║      QAペイン              ║
╚════════════════════════════╝

実行: claude
EOF

cat > "$WORK_DIR/banner-dev.txt" << 'EOF'
╔════════════════════════════╗
║     開発ペイン             ║
╚════════════════════════════╝

実行: claude
EOF

# tmuxセッション作成
tmux new-session -d -s "$SESSION_NAME" -c "$WORK_DIR"
tmux split-window -h -t "$SESSION_NAME" -c "$WORK_DIR"
tmux split-window -v -t "$SESSION_NAME:0.1" -c "$WORK_DIR"

# 各ペインでバナー表示とプロンプト設定
# マネージャー: シアン（シンプル版）
tmux send-keys -t "$SESSION_NAME:0.0" "export PS1='M> '" C-m
tmux send-keys -t "$SESSION_NAME:0.0" "source $WORK_DIR/.commands.sh" C-m
tmux send-keys -t "$SESSION_NAME:0.0" "clear && cat banner-manager.txt" C-m

# QA: 黄色（シンプル版）
tmux send-keys -t "$SESSION_NAME:0.1" "export PS1='QA> '" C-m
tmux send-keys -t "$SESSION_NAME:0.1" "clear && cat banner-qa.txt" C-m

# 開発: 緑（シンプル版）
tmux send-keys -t "$SESSION_NAME:0.2" "export PS1='Dev> '" C-m
tmux send-keys -t "$SESSION_NAME:0.2" "clear && cat banner-dev.txt" C-m

# ヘルプ作成
cat > "$WORK_DIR/help.txt" << 'EOF'
Claude チーム開発環境

【ペイン操作】
  Ctrl+b → 矢印  : ペイン移動
  Ctrl+b → z     : ペイン拡大/縮小

【コマンド送信】
  tmux send-keys -t claude-team:0.1 "メッセージ" C-m
  tmux send-keys -t claude-team:0.2 "メッセージ" C-m

【便利なコマンド】
  help      : このヘルプを表示
  qa        : QAペインでclaudeを起動
  dev       : 開発ペインでclaudeを起動
  clear-all : 全ペインをクリア
  exit-team : セッションを終了して片付ける
EOF

# コマンドスクリプト作成
cat > "$WORK_DIR/.commands.sh" << 'EOF'
# ヘルプコマンド
alias help='cat ~/team-workspace/help.txt'

# QAペインでClaude起動
alias qa='tmux send-keys -t claude-team:0.1 "claude" C-m'

# 開発ペインでClaude起動
alias dev='tmux send-keys -t claude-team:0.2 "claude" C-m'

# 全ペインクリア
alias clear-all='tmux send-keys -t claude-team:0.0 "clear" C-m; tmux send-keys -t claude-team:0.1 "clear" C-m; tmux send-keys -t claude-team:0.2 "clear" C-m'

# QAにメッセージ送信
qa-msg() {
    tmux send-keys -t claude-team:0.1 "$*" C-m
}

# 開発にメッセージ送信
dev-msg() {
    tmux send-keys -t claude-team:0.2 "$*" C-m
}

# 終了コマンド
exit-team() {
    echo "🧹 Claude チーム環境を終了しています..."
    
    # Claudeプロセスを終了
    tmux send-keys -t claude-team:0.1 C-c C-m "exit" C-m 2>/dev/null
    tmux send-keys -t claude-team:0.2 C-c C-m "exit" C-m 2>/dev/null
    sleep 1
    
    # セッションを終了
    tmux kill-session -t claude-team 2>/dev/null
    
    # 作業ディレクトリをクリーンアップ（オプション）
    if [ -d ~/team-workspace ]; then
        echo "作業ディレクトリをクリーンアップしますか？ (y/n)"
        read -n 1 answer
        echo
        if [ "$answer" = "y" ]; then
            rm -rf ~/team-workspace
            echo "✅ クリーンアップ完了"
        fi
    fi
    
    echo "👋 終了しました"
    exit 0
}

echo "コマンド: help, qa, dev, clear-all, qa-msg, dev-msg, exit-team"
EOF

echo "✅ 準備完了！"
sleep 1

# アタッチ
clear && printf '\033[3J'
tmux attach-session -t "$SESSION_NAME"