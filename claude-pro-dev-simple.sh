#!/bin/bash

# Claude プロフェッショナル開発環境 - シンプル版
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

# Claudeの設定ファイルを確実に作成
mkdir -p ~/.config/claude
if [ ! -f ~/.config/claude/config.json ]; then
    cat > ~/.config/claude/config.json << 'CEOF'
{
  "theme": "dark",
  "analytics": false,
  "hasAcceptedAnalytics": true,
  "hasCompletedOnboarding": true,
  "hasTrustDialogAccepted": "true",
  "hasCompletedProjectOnboarding": "true",
  "allowedTools": ["*"],
  "skipInitialSetup": true,
  "initialSetupComplete": true,
  "themeSelected": true,
  "userPreferences": {
    "theme": "dark",
    "skipWelcome": true
  }
}
CEOF
fi

# プロンプト設定スクリプト作成
cat > "$WORK_DIR/.setup-manager.sh" << 'EOF'
export PS1='PM> '
EOF

cat > "$WORK_DIR/.setup-qa.sh" << 'EOF'
export PS1='QA> '
EOF

# tmuxセッション作成
tmux new-session -d -s "$SESSION_NAME" -c "$WORK_DIR"

# 横3列のレイアウトを作成
# まず2つの縦分割を作成（3列にする）
tmux split-window -h -t "$SESSION_NAME" -c "$WORK_DIR"
tmux split-window -h -t "$SESSION_NAME:0.1" -c "$WORK_DIR"

# 左列をさらに横に分割（上：マネージャー、下：QA）
tmux select-pane -t 0
tmux split-window -v -t "$SESSION_NAME" -c "$WORK_DIR"

# 中央列を横に分割（上：チームA、下：チームB）
tmux select-pane -t 2
tmux split-window -v -t "$SESSION_NAME" -c "$WORK_DIR"

# 右列を横に分割（上：チームC、下：チームD）
tmux select-pane -t 4
tmux split-window -v -t "$SESSION_NAME" -c "$WORK_DIR"

# コマンドスクリプト作成
cat > "$WORK_DIR/.commands.sh" << 'EOF'
# ヘルプ関数
help() {
    echo "📚 Claude Pro Dev - 利用可能なコマンド"
    echo ""
    echo "【開発フェーズ】"
    echo "  requirements '<説明>' - 要件定義フェーズ開始"
    echo "  design               - 設計フェーズ開始"
    echo "  implementation       - 実装フェーズ開始"
    echo ""
    echo "【Claude起動】"
    echo "  start-claude         - 全ペインでClaude起動"
    echo ""
    echo "【その他】"
    echo "  clear-all            - 全ペインクリア"
    echo "  exit-project         - プロジェクト終了"
}

# Claude起動（自動）
start-claude() {
    echo "🚀 全ペインでClaudeを自動起動します..."
    
    # QAペインでClaude起動
    tmux send-keys -t "$SESSION_NAME:0.1" "claude" C-m
    
    # 開発チームペインでClaude起動
    for i in {2..5}; do
        tmux send-keys -t "$SESSION_NAME:0.$i" "claude" C-m
    done
    
    echo "✅ Claude起動完了"
}

# 要件定義
requirements() {
    local desc="$1"
    echo "[MANAGER] 要件定義フェーズ開始: $desc"
    # QAペインにメッセージ送信
    tmux send-keys -t "$SESSION_NAME:0.1" "プロジェクト『$desc』の要件定義書を作成してください" C-m
}

# 設計フェーズ
design() {
    echo "[MANAGER] 設計フェーズ開始"
    tmux send-keys -t "$SESSION_NAME:0.1" "要件定義書を基に設計書を作成してください" C-m
}

# 実装フェーズ
implementation() {
    echo "[MANAGER] 実装フェーズ開始"
    echo "各チームにタスクを割り当てます"
}

# 全ペインクリア
clear-all() {
    for i in {0..5}; do
        tmux send-keys -t "$SESSION_NAME:0.$i" "clear" C-m
    done
    echo "✅ 全ペインをクリアしました"
}

# 終了
exit-project() {
    echo "🧹 プロジェクトを終了しています..."
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null
    echo "✅ 終了しました"
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

準備完了
EOF

# 各ペインでセットアップ（シンプルに）
tmux send-keys -t "$SESSION_NAME:0.0" "source .setup-manager.sh && source .commands.sh && clear && cat banner-manager.txt" C-m
tmux send-keys -t "$SESSION_NAME:0.1" "source .setup-qa.sh && clear && cat banner-qa.txt" C-m

# 開発チームのセットアップ
for i in {2..5}; do
    team_letter=$(printf "\x$(printf %x $((65 + i - 2)))")
    
    cat > "$WORK_DIR/.setup-team-$i.sh" << EOF
export PS1='T$team_letter> '
EOF

    cat > "$WORK_DIR/banner-team-$i.txt" << EOF
╔════════════════════════════════════╗
║       開発チーム $team_letter              ║
╚════════════════════════════════════╝

準備完了
EOF

    tmux send-keys -t "$SESSION_NAME:0.$i" "source .setup-team-$i.sh && clear && cat banner-team-$i.txt" C-m
done

echo "✅ 準備完了！"
echo ""
echo "🚀 Claudeを自動起動中..."

# 2秒待ってから自動でClaude起動
sleep 2

# QAペインでClaude起動
tmux send-keys -t "$SESSION_NAME:0.1" "claude" C-m

# 開発チームペインでClaude起動
for i in {2..5}; do
    tmux send-keys -t "$SESSION_NAME:0.$i" "claude" C-m
    sleep 0.5
done

echo ""
echo "📋 使用可能なコマンド:"
echo "   - requirements '<プロジェクト説明>'"
echo "   - design"
echo "   - implementation"
echo ""
sleep 1

# アタッチ
clear && printf '\033[3J'
tmux attach-session -t "$SESSION_NAME"