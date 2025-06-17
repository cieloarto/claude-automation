#!/bin/bash

# Claude プロフェッショナル開発環境 - 簡略版
# 使用方法: ./claude-pro-dev-v2.sh [プロジェクト名] [チーム数] [作業ディレクトリ]

PROJECT_NAME=${1:-"my-project"}
TEAM_COUNT=${2:-4}
WORKSPACE_DIR=${3:-"$(pwd)/projects"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_NAME="claude-dev"

echo "🏢 Claude プロフェッショナル開発環境セットアップ開始..."
echo "プロジェクト: $PROJECT_NAME"
echo "チーム数: $TEAM_COUNT"
echo "作業ディレクトリ: $WORKSPACE_DIR"

# 既存セッションチェック
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "⚠️  セッション '$SESSION_NAME' は既に存在します。"
    read -p "削除して再作成しますか？ (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        tmux kill-session -t "$SESSION_NAME"
    else
        echo "既存セッションにアタッチします..."
        tmux attach-session -t "$SESSION_NAME"
        exit 0
    fi
fi

# 作業ディレクトリ作成
mkdir -p "$WORKSPACE_DIR"
mkdir -p "$WORKSPACE_DIR/docs"/{requirements,design,tasks,tests,knowledge}

# tmuxセッション作成（シンプルな方法）
tmux new-session -d -s "$SESSION_NAME" -n "$PROJECT_NAME" -c "$WORKSPACE_DIR"

# 画面分割
tmux split-window -h -t "$SESSION_NAME:0"
tmux select-pane -t "$SESSION_NAME:0.0"
tmux split-window -v -t "$SESSION_NAME:0"
tmux select-pane -t "$SESSION_NAME:0.2"

# 追加の開発チーム用ペイン作成
for ((i = 1; i < TEAM_COUNT; i++)); do
    tmux split-window -v -t "$SESSION_NAME:0"
    tmux select-layout -t "$SESSION_NAME:0" tiled
done

# レイアウト調整
tmux select-layout -t "$SESSION_NAME:0" main-vertical

# 設定ファイル作成
cat > "$WORKSPACE_DIR/claude-env.sh" << EOF
#!/bin/bash
# Claude Pro Dev環境設定

export PROJECT_NAME="$PROJECT_NAME"
export WORKSPACE_DIR="$WORKSPACE_DIR"
export SCRIPT_DIR="$SCRIPT_DIR"
export SESSION_NAME="$SESSION_NAME"

# 関数読み込み
source "$SCRIPT_DIR/claude-functions.sh" 2>/dev/null || true
source "$SCRIPT_DIR/claude-qa.sh" 2>/dev/null || true
source "$SCRIPT_DIR/claude-workflow.sh" 2>/dev/null || true

# ヘルプ表示
show_help() {
    echo "📚 利用可能なコマンド:"
    echo ""
    echo "【開発フロー】"
    echo "  requirements '<プロジェクト説明>'  - 要件定義開始"
    echo "  design                            - 設計フェーズ開始"
    echo "  implementation                    - 実装フェーズ開始"
    echo ""
    echo "【タスク管理】"
    echo "  task-assign <番号> '<説明>' '<ブランチ>' - タスク割り当て"
    echo "  qa-check <チーム> '<ブランチ>'          - QAチェック"
    echo ""
    echo "【その他】"
    echo "  status    - 現在の状態表示"
    echo "  clear-all - 全バッファクリア"
    echo "  help      - このヘルプ表示"
}

# 簡易コマンド
status() {
    echo "📊 現在の状態:"
    echo "  プロジェクト: $PROJECT_NAME"
    echo "  作業ディレクトリ: $WORKSPACE_DIR"
    echo "  セッション: $SESSION_NAME"
}

clear-all() {
    tmux list-panes -t "$SESSION_NAME" -F "#{pane_id}" | while read -r pane; do
        tmux clear-history -t "$SESSION_NAME:\$pane"
    done
    echo "✅ 全バッファをクリアしました"
}

# エイリアス
alias help='show_help'

echo "🎯 Claude Development Manager Ready!"
echo "コマンドを入力してください (help でヘルプ表示)"
echo ""
EOF

# マネージャーペイン（0番）で環境設定
tmux send-keys -t "$SESSION_NAME:0.0" "source $WORKSPACE_DIR/claude-env.sh" C-m

# 他のペインでClaude起動メッセージ
tmux send-keys -t "$SESSION_NAME:0.1" "echo '🔍 QAチーム準備中...'" C-m
tmux send-keys -t "$SESSION_NAME:0.1" "echo 'Claude Codeを起動してください: claude --dangerously-skip-permissions'" C-m

for ((i = 2; i < $((TEAM_COUNT + 2)); i++)); do
    team_letter=$(printf "\x$(printf %x $((65 + i - 2)))")
    tmux send-keys -t "$SESSION_NAME:0.$i" "echo '👨‍💻 チーム$team_letter 準備中...'" C-m
    tmux send-keys -t "$SESSION_NAME:0.$i" "echo 'Claude Codeを起動してください: claude --dangerously-skip-permissions'" C-m
done

# 初期化スクリプト作成（各チームで手動実行用）
cat > "$WORKSPACE_DIR/init-teams.sh" << 'EOF'
#!/bin/bash
echo "🔧 チーム初期化スクリプト"
echo "各チームのClaude Codeペインで以下を実行してください:"
echo ""
echo "【QAチーム】"
cat << 'QATEXT'
あなたはQA & テストチームリーダーです。
品質ゲートチェック、PR作成、統合テストを担当します。
QATEXT
echo ""
echo "【開発チーム】"
cat << 'DEVTEXT'
あなたは開発チームのシニアエンジニアです。
高品質な実装とテスト作成を担当します。
DEVTEXT
EOF

chmod +x "$WORKSPACE_DIR/init-teams.sh"

echo ""
echo "🎉 セットアップ完了！"
echo ""
echo "📋 次のステップ:"
echo "1. 各ペインでClaude Codeを起動: claude --dangerously-skip-permissions"
echo "2. マネージャーペイン（左上）でコマンドを実行"
echo "3. help コマンドで利用可能な機能を確認"
echo ""
echo "🎯 セッションにアタッチします..."
sleep 1

# アタッチ
tmux attach-session -t "$SESSION_NAME"