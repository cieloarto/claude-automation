# Tmux Buffer Overflow Solutions

## 即座の対処法

### 1. 現在のセッションのバッファをクリア
```bash
# すべてのペインのバッファをクリア
tmux clear-history -t claude-dev

# 特定のペインのバッファをクリア
tmux clear-history -t claude-dev:0.0  # マネージャー
tmux clear-history -t claude-dev:0.1  # チームA
tmux clear-history -t claude-dev:0.2  # QA
tmux clear-history -t claude-dev:0.3  # チームB
tmux clear-history -t claude-dev:0.4  # チームC
```

### 2. バッファサイズの確認と設定
```bash
# 現在の設定を確認
tmux show-options -g | grep history-limit

# バッファサイズを増やす（現在のセッション）
tmux set-option -g history-limit 50000

# より大きなバッファサイズに設定
tmux set-option -g history-limit 100000
```

## 永続的な解決策

### ~/.tmux.conf に追加
```bash
# バッファサイズを大きく設定
set-option -g history-limit 100000

# バッファオーバーフロー時の動作設定
set-option -g buffer-limit 20

# ペインごとのバッファ管理
set-option -g remain-on-exit off

# 自動的に古い出力を削除
set-option -g destroy-unattached on
```

## claude-pro-dev.sh の改善案

### スクリプトに追加すべき設定
```bash
# tmuxセッション開始時にバッファ設定を追加
setup_tmux_session() {
    local session_name=$1
    
    # セッション作成
    tmux new-session -d -s "$session_name"
    
    # バッファ設定
    tmux set-option -t "$session_name" history-limit 100000
    tmux set-option -t "$session_name" buffer-limit 50
    
    # 定期的なバッファクリア設定
    tmux set-option -t "$session_name" @scroll-speed-num-lines-per-scroll 5
}

# 各ペインに出力制限を設定
setup_pane_with_limits() {
    local pane_id=$1
    
    # ペインごとのバッファ制限
    tmux pipe-pane -t "$pane_id" "cat | head -n 10000 >> /tmp/tmux-${pane_id}.log"
    
    # 定期的なクリア
    tmux send-keys -t "$pane_id" "clear" C-m
}
```

## 出力を制御する関数

### claude-functions.sh に追加
```bash
# 大量出力を防ぐラッパー関数
controlled_output() {
    local command=$1
    local max_lines=${2:-1000}
    
    # 出力を制限して実行
    eval "$command" | head -n "$max_lines"
}

# ログローテーション機能
rotate_logs() {
    local log_dir="/tmp/claude-logs"
    local max_size="10M"
    
    mkdir -p "$log_dir"
    
    # 大きくなったログをローテート
    find "$log_dir" -name "*.log" -size +${max_size} -exec mv {} {}.old \;
}

# バッファモニタリング
monitor_buffer_usage() {
    local session_name=$1
    
    # 各ペインのバッファサイズを確認
    tmux list-panes -t "$session_name" -F "#{pane_id}: #{history_size}/#{history_limit}"
}
```

## トラブルシューティング

### バッファオーバーフローの兆候
1. tmuxが遅くなる
2. 出力が途切れる
3. スクロールができない
4. ペインがフリーズする

### 診断コマンド
```bash
# tmuxのメモリ使用量確認
ps aux | grep tmux | awk '{print $2, $11, $5}'

# バッファサイズの確認
tmux display-message -p "#{history_size}/#{history_limit}"

# 全ペインのバッファ状況
tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{history_size}/#{history_limit}"
```

### 緊急時の対処
```bash
# すべてのバッファをクリア
tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}" | \
    xargs -I {} tmux clear-history -t {}

# tmuxサーバーの再起動（最終手段）
tmux kill-server
tmux start-server
```

## 推奨設定

### 開発環境用の最適化設定
```bash
# ~/.tmux.conf
# Claude automation 用の設定
set-option -g history-limit 50000          # 適度なバッファサイズ
set-option -g display-time 3000           # メッセージ表示時間
set-option -g status-interval 5           # ステータス更新間隔
set-option -g automatic-rename off        # 自動リネーム無効化

# パフォーマンス設定
set-option -sg escape-time 1              # エスケープ時間短縮
set-option -g focus-events on             # フォーカスイベント有効化
```