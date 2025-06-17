#!/bin/bash

# Claude プロフェッショナル開発環境 - メインスクリプト
# 使用方法: ./claude-pro-dev.sh [セッション名] [チーム数] [作業ディレクトリ]

SESSION_NAME=${1:-"claude-pro-dev"}
TEAM_COUNT=${2:-4}
WORKSPACE_DIR=${3:-"$(pwd)/projects"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# tmuxのバッファオーバーフロー対策
export TMUX_HISTORY_LIMIT=50000
export TMUX_BUFFER_LIMIT=20

# バッファクリア関数
clear_tmux_buffers() {
    echo "🧹 tmuxバッファをクリアしています..."
    
    # 全ペインのヒストリをクリア
    local panes=$(tmux list-panes -t "$SESSION_NAME" -F "#{pane_id}")
    for pane in $panes; do
        tmux clear-history -t "$pane"
    done
    
    # バッファリストをクリア
    tmux delete-buffer -b 0 2>/dev/null || true
    
    echo "✅ バッファクリア完了"
}

# 特定のペインのバッファをクリア
clear_pane_buffer() {
    local pane_id="$1"
    if [ -z "$pane_id" ]; then
        echo "使用方法: clear_pane_buffer <pane_id>"
        return 1
    fi
    
    tmux clear-history -t "$pane_id"
    echo "✅ ペイン $pane_id のバッファをクリア"
}

# メモリ使用状況の確認
check_tmux_memory() {
    echo "📊 tmuxメモリ使用状況:"
    ps aux | grep tmux | grep -v grep
    echo ""
    echo "📜 バッファ数:"
    tmux list-buffers 2>/dev/null | wc -l || echo "0"
}

echo "🏢 Claude プロフェッショナル開発環境セットアップ開始..."
echo "セッション名: $SESSION_NAME"
echo "開発チーム数: $TEAM_COUNT"
echo "作業ディレクトリ: $WORKSPACE_DIR"
echo "スクリプトディレクトリ: $SCRIPT_DIR"

# 既存セッションチェック
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "⚠️  セッション '$SESSION_NAME' は既に存在します。"
    read -p "アタッチしますか？ (y/n): " -n 1 -r
    echo# Claude Code 画像分析ワークフロー用関数
    # claude-functions.sh に追加可能

    # デザイン分析
    analyze_design() {
        local image_path="$1"
        local description="$2"

        if [ -z "$image_path" ]; then
            echo "使用方法: analyze-design <画像パス> [説明]"
            return 1
        fi

        local design_prompt="この画像を分析して、以下の観点から設計書を作成してください：

【分析観点】
1. UI/UXデザイン要素
2. レイアウト構造
3. コンポーネント分解
4. 実装すべき機能一覧
5. 技術要件

【出力先】
docs/design/ui-analysis.md

画像: $image_path
説明: ${description:-'デザイン分析'}

詳細な分析をお願いします。"

        tmux send-keys -t "$MANAGER_PANE" "echo '$design_prompt' | claude '$image_path'" C-m
        echo "🎨 デザイン分析を開始: $image_path"
    }

    # 要件画像分析
    analyze_requirements() {
        local image_path="$1"
        local description="$2"

        if [ -z "$image_path" ]; then
            echo "使用方法: analyze-requirements <画像パス> [説明]"
            return 1
        fi

        local req_prompt="この画像から要件を抽出して、docs/requirements/requirements.md を作成してください：

【抽出する要件】
1. 機能要件（画像から読み取れる機能）
2. 非機能要件（パフォーマンス、ユーザビリティ）
3. 技術要件（推奨技術スタック）
4. UI/UX要件（デザインガイドライン）

画像: $image_path
説明: ${description:-'要件画像分析'}

要件定義書を作成してください。"

        tmux send-keys -t "$MANAGER_PANE" "echo '$req_prompt' | claude '$image_path'" C-m
        echo "📋 要件画像分析を開始: $image_path"
    }

    # エラー画面分析
    analyze_error() {
        local image_path="$1"
        local team_num="$2"

        if [ -z "$image_path" ] || [ -z "$team_num" ]; then
            echo "使用方法: analyze-error <画像パス> <チーム番号>"
            return 1
        fi

        if [ "$team_num" -ge 0 ] && [ "$team_num" -lt "${#TEAM_PANES[@]}" ]; then
            local error_prompt="このエラー画面を分析して、解決方法を提案してください：

【分析項目】
1. エラーの原因特定
2. 修正方法の提案
3. 予防策の提案
4. テストケースの追加

【対応手順】
1. 即座に修正可能な項目
2. 中長期的な改善項目
3. 関連する他の修正必要箇所

エラー画像を詳細に分析してください。"

            tmux send-keys -t "${TEAM_PANES[$team_num]}" "echo '$error_prompt' | claude '$image_path'" C-m
            echo "🐛 エラー分析を開始: チーム$((team_num + 1)) → $image_path"
        else
            echo "❌ 無効なチーム番号: $team_num"
        fi
    }

    # スクリーンショット自動撮影（macOS）
    capture_and_analyze() {
        local analysis_type="$1" # design, requirements, error
        local team_num="$2"

        echo "📸 スクリーンショットを撮影してください（3秒後開始）"
        sleep 3

        local timestamp=$(date +%Y%m%d_%H%M%S)
        local screenshot_path="/tmp/claude_screenshot_${timestamp}.png"

        # macOSでスクリーンショット撮影
        screencapture -s "$screenshot_path"

        if [ -f "$screenshot_path" ]; then
            echo "✅ スクリーンショット保存: $screenshot_path"

            case "$analysis_type" in
            "design")
                analyze_design "$screenshot_path" "スクリーンショット分析"
                ;;
            "requirements")
                analyze_requirements "$screenshot_path" "スクリーンショット要件分析"
                ;;
            "error")
                if [ -n "$team_num" ]; then
                    analyze_error "$screenshot_path" "$team_num"
                else
                    echo "❌ エラー分析にはチーム番号が必要です"
                fi
                ;;
            *)
                echo "❌ 不明な分析タイプ: $analysis_type"
                echo "利用可能: design, requirements, error"
                ;;
            esac
        else
            echo "❌ スクリーンショットの撮影に失敗しました"
        fi
    }

    # QAテスト画面分析
    qa_analyze_screen() {
        local image_path="$1"
        local test_type="$2" # ui, performance, accessibility

        if [ -z "$image_path" ] || [ -z "$test_type" ]; then
            echo "使用方法: qa-analyze-screen <画像パス> <テストタイプ>"
            echo "テストタイプ: ui, performance, accessibility"
            return 1
        fi

        local qa_prompt="この画面を${test_type}テストの観点から分析してください：

【${test_type}テスト分析】"

        case "$test_type" in
        "ui")
            qa_prompt="$qa_prompt
1. レイアウトの妥当性
2. ユーザビリティの問題
3. デザインガイドライン準拠
4. レスポンシブ対応"
            ;;
        "performance")
            qa_prompt="$qa_prompt
1. 表示速度の問題
2. リソース使用量
3. 最適化ポイント
4. パフォーマンス改善提案"
            ;;
        "accessibility")
            qa_prompt="$qa_prompt
1. アクセシビリティ準拠
2. 色彩対比の確認
3. キーボード操作対応
4. スクリーンリーダー対応"
            ;;
        esac

        qa_prompt="$qa_prompt

【出力】
- 問題点の特定
- 改善提案
- テストケース追加
- 品質基準への適合状況

テスト結果をdocs/tests/に記録してください。"

        tmux send-keys -t "$QA_PANE" "echo '$qa_prompt' | claude '$image_path'" C-m
        echo "🔍 QA画面分析を開始: $test_type → $image_path"
    }

    # エイリアス追加
    alias analyze-design='analyze_design'
    alias analyze-requirements='analyze_requirements'
    alias analyze-error='analyze_error'
    alias capture-analyze='capture_and_analyze'
    alias qa-analyze='qa_analyze_screen' # Claude Code 画像分析ワークフロー用関数
    # claude-functions.sh に追加可能

    # デザイン分析
    analyze_design() {
        local image_path="$1"
        local description="$2"

        if [ -z "$image_path" ]; then
            echo "使用方法: analyze-design <画像パス> [説明]"
            return 1
        fi

        local design_prompt="この画像を分析して、以下の観点から設計書を作成してください：

【分析観点】
1. UI/UXデザイン要素
2. レイアウト構造
3. コンポーネント分解
4. 実装すべき機能一覧
5. 技術要件

【出力先】
docs/design/ui-analysis.md

画像: $image_path
説明: ${description:-'デザイン分析'}

詳細な分析をお願いします。"

        tmux send-keys -t "$MANAGER_PANE" "echo '$design_prompt' | claude '$image_path'" C-m
        echo "🎨 デザイン分析を開始: $image_path"
    }

    # 要件画像分析
    analyze_requirements() {
        local image_path="$1"
        local description="$2"

        if [ -z "$image_path" ]; then
            echo "使用方法: analyze-requirements <画像パス> [説明]"
            return 1
        fi

        local req_prompt="この画像から要件を抽出して、docs/requirements/requirements.md を作成してください：

【抽出する要件】
1. 機能要件（画像から読み取れる機能）
2. 非機能要件（パフォーマンス、ユーザビリティ）
3. 技術要件（推奨技術スタック）
4. UI/UX要件（デザインガイドライン）

画像: $image_path
説明: ${description:-'要件画像分析'}

要件定義書を作成してください。"

        tmux send-keys -t "$MANAGER_PANE" "echo '$req_prompt' | claude '$image_path'" C-m
        echo "📋 要件画像分析を開始: $image_path"
    }

    # エラー画面分析
    analyze_error() {
        local image_path="$1"
        local team_num="$2"

        if [ -z "$image_path" ] || [ -z "$team_num" ]; then
            echo "使用方法: analyze-error <画像パス> <チーム番号>"
            return 1
        fi

        if [ "$team_num" -ge 0 ] && [ "$team_num" -lt "${#TEAM_PANES[@]}" ]; then
            local error_prompt="このエラー画面を分析して、解決方法を提案してください：

【分析項目】
1. エラーの原因特定
2. 修正方法の提案
3. 予防策の提案
4. テストケースの追加

【対応手順】
1. 即座に修正可能な項目
2. 中長期的な改善項目
3. 関連する他の修正必要箇所

エラー画像を詳細に分析してください。"

            tmux send-keys -t "${TEAM_PANES[$team_num]}" "echo '$error_prompt' | claude '$image_path'" C-m
            echo "🐛 エラー分析を開始: チーム$((team_num + 1)) → $image_path"
        else
            echo "❌ 無効なチーム番号: $team_num"
        fi
    }

    # スクリーンショット自動撮影（macOS）
    capture_and_analyze() {
        local analysis_type="$1" # design, requirements, error
        local team_num="$2"

        echo "📸 スクリーンショットを撮影してください（3秒後開始）"
        sleep 3

        local timestamp=$(date +%Y%m%d_%H%M%S)
        local screenshot_path="/tmp/claude_screenshot_${timestamp}.png"

        # macOSでスクリーンショット撮影
        screencapture -s "$screenshot_path"

        if [ -f "$screenshot_path" ]; then
            echo "✅ スクリーンショット保存: $screenshot_path"

            case "$analysis_type" in
            "design")
                analyze_design "$screenshot_path" "スクリーンショット分析"
                ;;
            "requirements")
                analyze_requirements "$screenshot_path" "スクリーンショット要件分析"
                ;;
            "error")
                if [ -n "$team_num" ]; then
                    analyze_error "$screenshot_path" "$team_num"
                else
                    echo "❌ エラー分析にはチーム番号が必要です"
                fi
                ;;
            *)
                echo "❌ 不明な分析タイプ: $analysis_type"
                echo "利用可能: design, requirements, error"
                ;;
            esac
        else
            echo "❌ スクリーンショットの撮影に失敗しました"
        fi
    }

    # QAテスト画面分析
    qa_analyze_screen() {
        local image_path="$1"
        local test_type="$2" # ui, performance, accessibility

        if [ -z "$image_path" ] || [ -z "$test_type" ]; then
            echo "使用方法: qa-analyze-screen <画像パス> <テストタイプ>"
            echo "テストタイプ: ui, performance, accessibility"
            return 1
        fi

        local qa_prompt="この画面を${test_type}テストの観点から分析してください：

【${test_type}テスト分析】"

        case "$test_type" in
        "ui")
            qa_prompt="$qa_prompt
1. レイアウトの妥当性
2. ユーザビリティの問題
3. デザインガイドライン準拠
4. レスポンシブ対応"
            ;;
        "performance")
            qa_prompt="$qa_prompt
1. 表示速度の問題
2. リソース使用量
3. 最適化ポイント
4. パフォーマンス改善提案"
            ;;
        "accessibility")
            qa_prompt="$qa_prompt
1. アクセシビリティ準拠
2. 色彩対比の確認
3. キーボード操作対応
4. スクリーンリーダー対応"
            ;;
        esac

        qa_prompt="$qa_prompt

【出力】
- 問題点の特定
- 改善提案
- テストケース追加
- 品質基準への適合状況

テスト結果をdocs/tests/に記録してください。"

        tmux send-keys -t "$QA_PANE" "echo '$qa_prompt' | claude '$image_path'" C-m
        echo "🔍 QA画面分析を開始: $test_type → $image_path"
    }

    # エイリアス追加
    alias analyze-design='analyze_design'
    alias analyze-requirements='analyze_requirements'
    alias analyze-error='analyze_error'
    alias capture-analyze='capture_and_analyze'
    alias qa-analyze='qa_analyze_screen'
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

# tmuxセッション作成と画面分割（バッファオーバーフロー対策付き）
tmux new-session -d -s "$SESSION_NAME" \
    -c "$WORKSPACE_DIR" \
    \; set-option -g history-limit $TMUX_HISTORY_LIMIT \
    \; set-option -g buffer-limit 20
# 各ペインにもバッファ制限を適用
tmux split-window -h -t "$SESSION_NAME" \; set-option -p history-limit $TMUX_HISTORY_LIMIT
tmux select-pane -t 0
tmux split-window -v \; set-option -p history-limit $TMUX_HISTORY_LIMIT
tmux select-pane -t 2
for ((i = 1; i < TEAM_COUNT; i++)); do
    tmux split-window -v \; set-option -p history-limit $TMUX_HISTORY_LIMIT
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

# Claude Code起動（マネージャー以外）
echo "🚀 各チームでClaude Code起動中..."
for pane in "$QA_PANE" "${TEAM_PANES[@]}"; do
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

# バッファ管理関数をエクスポート
export -f clear_tmux_buffers
export -f clear_pane_buffer
export -f check_tmux_memory

# 共通関数読み込み
source "$SCRIPT_DIR/claude-functions.sh"
source "$SCRIPT_DIR/claude-qa.sh"  
source "$SCRIPT_DIR/claude-workflow.sh"

# エイリアス定義
alias clear-buffers='clear_tmux_buffers'
alias clear-pane='clear_pane_buffer'
alias tmux-memory='check_tmux_memory'

# チーム初期化をバックグラウンドで実行（Claude Code起動後）
(
    sleep 5  # Claude Codeの起動を待つ
    init_all_teams
) &

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
echo "🧹 バッファ管理コマンド:"
echo "  - clear-buffers: 全ペインのバッファをクリア"
echo "  - clear-pane <pane_id>: 特定ペインのバッファをクリア"
echo "  - tmux-memory: メモリ使用状況を確認"
echo ""
EOF

chmod +x /tmp/claude_pro_dev_integrated.sh

# マネージャーペインで統合スクリプトを実行
tmux send-keys -t "$MANAGER_PANE" "source /tmp/claude_pro_dev_integrated.sh" C-m
sleep 1

# 初期プロンプトを表示
tmux send-keys -t "$MANAGER_PANE" "echo ''" C-m
tmux send-keys -t "$MANAGER_PANE" "echo '🎯 Claude Development Manager Ready!'" C-m
tmux send-keys -t "$MANAGER_PANE" "echo 'コマンドを入力してください (help でヘルプ表示)'" C-m
tmux send-keys -t "$MANAGER_PANE" "echo ''" C-m

tmux select-pane -t 0

echo "🎯 セッションにアタッチします..."
tmux attach-session -t "$SESSION_NAME"
