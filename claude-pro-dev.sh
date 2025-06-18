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