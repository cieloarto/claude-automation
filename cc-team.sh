#!/bin/bash

# Claude チーム開発環境 - 最小構成版
# 使用方法: ./cc-team.sh

SESSION_NAME="claude-team"
WORK_DIR="$(pwd)/team-workspace"

echo "🏢 Claude チーム環境セットアップ"

# 既存セッションの処理
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "既存セッションを削除します..."
    tmux kill-session -t "$SESSION_NAME"
fi

# 作業ディレクトリ作成
mkdir -p "$WORK_DIR"

# tmuxセッション作成（バックグラウンドで起動）
tmux new-session -d -s "$SESSION_NAME" -c "$WORK_DIR"

# 3ペイン構成
tmux split-window -h -t "$SESSION_NAME"
tmux split-window -v -t "$SESSION_NAME:0.1"

# 各ペインに名前を設定
tmux select-pane -t "$SESSION_NAME:0.0" -T "Manager"
tmux select-pane -t "$SESSION_NAME:0.1" -T "QA"
tmux select-pane -t "$SESSION_NAME:0.2" -T "Dev"

# 各ペインで初期メッセージ表示
tmux send-keys -t "$SESSION_NAME:0.0" "echo '=== マネージャーペイン ==='" C-m
tmux send-keys -t "$SESSION_NAME:0.0" "echo 'ここでコマンドを実行します'" C-m
tmux send-keys -t "$SESSION_NAME:0.0" "echo 'help.txt を参照してください'" C-m

tmux send-keys -t "$SESSION_NAME:0.1" "echo '=== QAペイン ==='" C-m
tmux send-keys -t "$SESSION_NAME:0.1" "echo 'Claude起動: claude'" C-m

tmux send-keys -t "$SESSION_NAME:0.2" "echo '=== 開発ペイン ==='" C-m
tmux send-keys -t "$SESSION_NAME:0.2" "echo 'Claude起動: claude'" C-m

# ヘルプファイル作成
cat > "$WORK_DIR/help.txt" << 'EOF'
Claude チーム開発環境 - ヘルプ

【基本操作】
- ペイン切り替え: Ctrl+b → 矢印キー
- ペイン拡大: Ctrl+b → z
- セッション終了: exit (全ペインで実行)

【QA/開発ペインでClaude起動】
claude

【マネージャーペインでのコマンド例】
# QAペインにコマンド送信
tmux send-keys -t claude-team:0.1 "要件を確認してください" C-m

# 開発ペインにコマンド送信  
tmux send-keys -t claude-team:0.2 "実装を開始してください" C-m

# 全ペインの履歴クリア
tmux clear-history -t claude-team

【作業フロー例】
1. QA/開発ペインでclaudeを起動
2. マネージャーペインから指示を送信
3. 各ペインで作業を実行
EOF

echo ""
echo "✅ セットアップ完了！"
echo ""
echo "📋 使い方:"
echo "1. 右上(QA)と右下(開発)のペインで 'claude' を実行"
echo "2. 左のマネージャーペインから指示を送信"
echo "3. 詳細は $WORK_DIR/help.txt を参照"
echo ""
echo "アタッチ中..."

# セッションにアタッチ
tmux attach-session -t "$SESSION_NAME"