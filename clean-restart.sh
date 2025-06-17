#!/bin/bash

echo "🧹 tmux環境を完全にクリーンアップします..."

# 全tmuxセッションを終了
echo "既存のtmuxセッションを終了中..."
tmux kill-server 2>/dev/null || true

# tmuxのキャッシュをクリア
echo "tmuxキャッシュをクリア中..."
rm -rf ~/.tmux/resurrect/* 2>/dev/null || true
rm -rf ~/.tmux/plugins/tmux-resurrect/last 2>/dev/null || true

# 一時ファイルをクリア
echo "一時ファイルをクリア中..."
rm -f /tmp/claude_* 2>/dev/null || true
rm -f /tmp/init_teams.sh 2>/dev/null || true
rm -f /tmp/team_*_init_prompt.txt 2>/dev/null || true
rm -f /tmp/qa_init_prompt.txt 2>/dev/null || true
rm -f /tmp/manager_init_prompt.txt 2>/dev/null || true

# ターミナルをクリア
clear

echo "✅ クリーンアップ完了！"
echo ""
echo "新しいセッションを開始するには："
echo "  cc-team"
echo ""