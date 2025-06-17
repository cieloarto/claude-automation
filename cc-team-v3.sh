#!/bin/bash

# Claude チーム環境 - v3（改良版）
SESSION_NAME="claude-team"
WORK_DIR="$(pwd)/team-workspace"

# ターミナルクリア
clear && printf '\033[3J'

echo "🏢 Claude チーム環境セットアップ中..."

# 既存セッション削除
tmux kill-session -t "$SESSION_NAME" 2>/dev/null

# 作業ディレクトリ作成
mkdir -p "$WORK_DIR"

# プロンプト設定スクリプト作成
cat > "$WORK_DIR/.setup.sh" << 'EOF'
# zsh用のプロンプト設定
if [ -n "$ZSH_VERSION" ]; then
    export PS1='%F{cyan}M>%f '
else
    export PS1='M> '
fi
EOF

cat > "$WORK_DIR/.setup-qa.sh" << 'EOF'
# zsh用のプロンプト設定
if [ -n "$ZSH_VERSION" ]; then
    export PS1='%F{yellow}QA>%f '
else
    export PS1='QA> '
fi
EOF

cat > "$WORK_DIR/.setup-dev.sh" << 'EOF'
# zsh用のプロンプト設定
if [ -n "$ZSH_VERSION" ]; then
    export PS1='%F{green}Dev>%f '
else
    export PS1='Dev> '
fi
EOF

# バナーファイル作成
cat > "$WORK_DIR/banner-manager.txt" << 'EOF'
╔════════════════════════════╗
║   マネージャーペイン       ║
╚════════════════════════════╝

コマンド: help
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

# コマンドスクリプト作成
cat > "$WORK_DIR/.commands.sh" << 'EOF'
# ヘルプコマンド
alias help='cat ~/team-workspace/help.txt'

# QAペインでClaude起動
alias qa='tmux send-keys -t claude-team:0.1 "claude" C-m'

# 開発ペインでClaude起動
alias dev='tmux send-keys -t claude-team:0.2 "claude" C-m'

# 全ペインクリア
alias clear-all='
    tmux send-keys -t claude-team:0.0 "clear" C-m
    tmux send-keys -t claude-team:0.1 "clear" C-m
    tmux send-keys -t claude-team:0.2 "clear" C-m
'

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
    tmux send-keys -t claude-team:0.1 C-c 2>/dev/null
    tmux send-keys -t claude-team:0.2 C-c 2>/dev/null
    sleep 0.5
    tmux send-keys -t claude-team:0.1 "exit" C-m 2>/dev/null
    tmux send-keys -t claude-team:0.2 "exit" C-m 2>/dev/null
    sleep 0.5
    
    # セッションを終了
    tmux kill-session -t claude-team 2>/dev/null
    
    # クリーンアップ
    echo "✅ 終了しました"
    exit 0
}

echo "利用可能: help, qa, dev, clear-all, qa-msg, dev-msg, exit-team"
EOF

# ヘルプ作成
cat > "$WORK_DIR/help.txt" << 'EOF'
Claude チーム開発環境

【ペイン操作】
  Ctrl+b → 矢印  : ペイン移動
  Ctrl+b → z     : ペイン拡大/縮小

【便利なコマンド】
  help      : このヘルプを表示
  qa        : QAペインでclaudeを起動
  dev       : 開発ペインでclaudeを起動
  clear-all : 全ペインをクリア
  exit-team : セッションを終了

【メッセージ送信】
  qa-msg "テストしてください"
  dev-msg "実装してください"
EOF

# 各ペインでセットアップ
tmux send-keys -t "$SESSION_NAME:0.0" "source .setup.sh && source .commands.sh && clear && cat banner-manager.txt" C-m
tmux send-keys -t "$SESSION_NAME:0.1" "source .setup-qa.sh && clear && cat banner-qa.txt" C-m
tmux send-keys -t "$SESSION_NAME:0.2" "source .setup-dev.sh && clear && cat banner-dev.txt" C-m

echo "✅ 準備完了！"
sleep 1

# アタッチ
clear && printf '\033[3J'
tmux attach-session -t "$SESSION_NAME"