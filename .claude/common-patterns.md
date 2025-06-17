# Common Patterns

## Tmux Display Fix Patterns

### Terminal Size Mismatch Fix
```bash
# Force tmux to redraw
tmux refresh-client -t "$session_name"

# Resize panes to fit current terminal
tmux resize-pane -t "$session_name" -x $(tput cols) -y $(tput lines)
```

### Character Encoding Fix
```bash
# Set proper UTF-8 encoding
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8
tmux set-option -g status-utf8 on
```

### Pane Layout Reset
```bash
# Reset to default layout
tmux select-layout -t "$session_name" tiled

# Custom layout for claude-pro-dev
tmux select-layout -t "$session_name" "5a7f,238x57,0,0{119x57,0,0[119x28,0,0,0,119x28,0,29,2],118x57,120,0[118x18,120,0,1,118x18,120,19,3,118x19,120,38,4]}"
```

## Tmux Command Patterns

### Send Complex Commands
```bash
# Escape quotes and variables properly
tmux send-keys -t "${session_name}:${pane}" "claude-code '${escaped_prompt}'" C-m

# Multi-line commands
tmux send-keys -t "${session_name}:${pane}" \
    "cd ${project_dir} && " \
    "git checkout -b feature/${branch_name} && " \
    "npm install" C-m
```

### Pane Selection
```bash
# Select by name
tmux select-pane -t "${session_name}:manager"

# Select by index
tmux select-pane -t "${session_name}.${pane_index}"
```

## Claude Code Invocation Patterns

### Requirements Generation
```bash
claude-code "
プロジェクト: ${project_name}
要件: ${requirements}

以下の形式でrequirements.mdを作成してください：
1. 機能要件
2. 非機能要件
3. 制約事項
4. 成功基準
"
```

### Task Assignment
```bash
claude-code "
タスク: ${task_description}
ブランチ: feature/${branch_name}

以下を実行してください：
1. ブランチの作成
2. 実装
3. テストの作成
4. コミット
"
```

## Git Worktree Patterns

### Setup New Worktree
```bash
worktree_path="${workspace_dir}/${branch_name}"
git worktree add "$worktree_path" -b "feature/${branch_name}"
cd "$worktree_path"
```

### Cleanup Worktree
```bash
git worktree remove "$worktree_path" --force
git branch -D "feature/${branch_name}"
```

## Error Handling Patterns

### Command Validation
```bash
validate_command() {
    local cmd=$1
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd is not installed" >&2
        return 1
    fi
}
```

### Safe Execution
```bash
safe_execute() {
    local cmd=$1
    if ! eval "$cmd"; then
        echo "Failed to execute: $cmd" >&2
        return 1
    fi
}
```

## Progress Tracking Patterns

### Status Update
```bash
update_status() {
    local team=$1
    local status=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Team $team: $status" >> progress.log
}
```

### Progress Report
```bash
generate_progress_report() {
    echo "=== 進捗レポート ==="
    grep -E "Team [A-Z]:" progress.log | tail -20
}
```

## Quality Check Patterns

### Test Coverage Check
```bash
check_coverage() {
    local coverage=$(npm test -- --coverage | grep "All files" | awk '{print $10}' | sed 's/%//')
    if (( $(echo "$coverage < 80" | bc -l) )); then
        echo "Coverage $coverage% is below 80% threshold"
        return 1
    fi
}
```

### Security Scan
```bash
run_security_scan() {
    npm audit --production
    if [ $? -ne 0 ]; then
        echo "Security vulnerabilities found"
        return 1
    fi
}
```

## Documentation Generation Patterns

### Markdown Table Generation
```bash
generate_task_table() {
    cat << EOF
| チーム | タスク | ステータス | ブランチ |
|--------|--------|------------|----------|
| A | $task_a | 実装中 | feature/task-a |
| B | $task_b | 完了 | feature/task-b |
EOF
}
```

### Auto-formatted Lists
```bash
generate_bullet_list() {
    local items=("$@")
    for item in "${items[@]}"; do
        echo "- $item"
    done
}
```

## GitHub CLI Patterns

### PR Creation with Template
```bash
create_pr() {
    local title=$1
    local body=$2
    gh pr create \
        --title "$title" \
        --body "$body" \
        --base main \
        --label "automated" \
        --assignee "@me"
}
```

### Automated Approval
```bash
approve_pr() {
    local pr_number=$1
    gh pr review $pr_number --approve --body "自動QAチェック合格 ✅"
}
```