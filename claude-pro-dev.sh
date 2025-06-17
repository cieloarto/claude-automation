#!/bin/bash

# Claude プロフェッショナル開発環境 - メインスクリプト
# 使用方法: ./claude-pro-dev.sh [セッション名] [チーム数] [作業ディレクトリ]

SESSION_NAME=${1:-"claude-pro-dev"}
TEAM_COUNT=${2:-4}
WORKSPACE_DIR=${3:-"$(pwd)/projects"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🏢 Claude プロフェッショナル開発環境セットアップ開始..."
echo "セッション名: $SESSION_NAME"
echo "開発チーム数: $TEAM_COUNT"
echo "作業ディレクトリ: $WORKSPACE_DIR"
echo "スクリプトディレクトリ: $SCRIPT_DIR"

# 既存セッションチェック
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "⚠️  セッション '$SESSION_NAME' は既に存在します。"
    read -p "アタッチしますか？ (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        tmux attach-session -t "$SESSION_NAME"
        exit 0
    fi
fi

# 依存スクリプト確認
for script in "claude-functions.sh" "claude-qa.sh" "claude-workflow.sh"; do
    if [ ! -f "$SCRIPT_DIR/$script" ]; then
        echo "❌ 必要なスクリプトが見つかりません: $script"
        echo "全てのスクリプトファイルを同じディレクトリに配置してください。"
        exit 1
    fi
done

# 作業ディレクトリとドキュメント構造を作成
mkdir -p "$WORKSPACE_DIR"
mkdir -p "$WORKSPACE_DIR/docs"/{requirements,design,tasks,tests,knowledge}

# tmuxセッション作成と画面分割
tmux new-session -d -s "$SESSION_NAME"
tmux split-window -h -t "$SESSION_NAME"
tmux select-pane -t 0
tmux split-window -v
tmux select-pane -t 2
for ((i = 1; i < TEAM_COUNT; i++)); do
    tmux split-window -v
done

# レイアウト調整
tmux select-pane -t 0
tmux resize-pane -R 10
tmux select-pane -t 1
tmux resize-pane -R 10

# pane情報取得と役割定義
PANE_INFO=$(tmux list-panes -t "$SESSION_NAME" -F "#{pane_index}:#{pane_id}")
declare -a PANE_IDS
while IFS=':' read -r index id; do
    PANE_IDS[$index]="$id"
done <<<"$PANE_INFO"

MANAGER_PANE="${PANE_IDS[0]}"
QA_PANE="${PANE_IDS[1]}"
TEAM_PANES=()
for ((i = 2; i < $((2 + TEAM_COUNT)); i++)); do
    TEAM_PANES+=("${PANE_IDS[$i]}")
done

echo "👔 プロジェクトマネージャー: $MANAGER_PANE"
echo "🔍 QA & テストチーム: $QA_PANE"
echo "👨‍💻 開発チーム: ${TEAM_PANES[*]}"

# Claude Code起動
echo "🚀 各チームでClaude Code起動中..."
for pane in "$MANAGER_PANE" "$QA_PANE" "${TEAM_PANES[@]}"; do
    tmux send-keys -t "$pane" "claude --dangerously-skip-permissions" C-m &
    sleep 0.3
done
wait

# 統合スクリプト作成
cat <<EOF >/tmp/claude_pro_dev_integrated.sh
#!/bin/bash

# 環境変数設定
export MANAGER_PANE="$MANAGER_PANE"
export QA_PANE="$QA_PANE"
export TEAM_PANES=(${TEAM_PANES[*]})
export WORKSPACE_DIR="$WORKSPACE_DIR"
export SCRIPT_DIR="$SCRIPT_DIR"
export DEVELOPMENT_PHASE="requirements"
export CURRENT_PROJECT=""

# 共通関数読み込み
source "$SCRIPT_DIR/claude-functions.sh"
source "$SCRIPT_DIR/claude-qa.sh"  
source "$SCRIPT_DIR/claude-workflow.sh"

# チーム初期化
init_all_teams

echo ""
echo "🎉 Claude プロフェッショナル開発環境セットアップ完了！"
echo ""
echo "🚀 開始手順:"
echo "  1. import-knowledge 'https://zenn.dev/driller/articles/2a23ef94f1d603' '参考アーキテクチャ'"
echo "  2. requirements 'あなたのプロジェクト名'"
echo "  3. design"
echo "  4. implementation"
echo "  5. task-assign 0 'タスク内容' 'ブランチ名'"
echo ""
echo "💡 詳細は 'help' コマンドで確認してください"
echo ""
EOF

chmod +x /tmp/claude_pro_dev_integrated.sh

# 統合スクリプトを実行
tmux send-keys -t "$MANAGER_PANE" "source /tmp/claude_pro_dev_integrated.sh" C-m
tmux select-pane -t 0

echo "🎯 セッションにアタッチします..."
tmux attach-session -t "$SESSION_NAME"
