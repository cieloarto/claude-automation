# Debug Log

## Critical Issues and Resolutions

### 2024-01-18: Tmux Pane Communication Failure

**Issue Duration**: 2 hours
**Severity**: High
**Recurrence Risk**: Medium

**Problem**:
Commands sent to tmux panes were being truncated when containing special characters.

**Root Cause**:
Shell expansion occurring before tmux command processing.

**Solution**:
```bash
# Before (problematic)
tmux send-keys -t "$pane" "claude-code \"$prompt\"" C-m

# After (fixed)
escaped_prompt=$(printf '%q' "$prompt")
tmux send-keys -t "$pane" "claude-code $escaped_prompt" C-m
```

**Prevention**:
Always use `printf '%q'` for escaping complex strings passed to tmux.

---

### 2024-01-17: Git Worktree Permission Denied

**Issue Duration**: 45 minutes
**Severity**: Medium
**Recurrence Risk**: High

**Problem**:
Git worktree creation failed with "permission denied" in projects directory.

**Root Cause**:
Workspace directory created without proper permissions for git operations.

**Solution**:
```bash
# Ensure workspace has correct permissions
mkdir -p "$workspace_dir"
chmod 755 "$workspace_dir"
```

**Prevention**:
Added permission check to initialization routine.

---

### 2024-01-16: Claude Code Context Overflow

**Issue Duration**: 3 hours
**Severity**: High
**Recurrence Risk**: Low

**Problem**:
Claude Code stopped responding when given extremely large context.

**Root Cause**:
Entire project documentation passed in single prompt exceeded token limits.

**Solution**:
Implemented chunked document processing:
```bash
# Split large documents
split_and_process() {
    local file=$1
    local chunk_size=1000
    split -l $chunk_size "$file" temp_chunk_
    for chunk in temp_chunk_*; do
        process_chunk "$chunk"
    done
}
```

**Prevention**:
Monitor document sizes and implement automatic chunking.

---

### 2024-01-15: Race Condition in Team Initialization

**Issue Duration**: 1.5 hours
**Severity**: High
**Recurrence Risk**: Medium

**Problem**:
Teams occasionally failed to initialize when started simultaneously.

**Root Cause**:
Tmux pane creation commands overlapping during parallel execution.

**Solution**:
```bash
# Add small delay between pane creations
for i in $(seq 0 $((team_count - 1))); do
    setup_team "$i" &
    sleep 0.1  # Prevent race condition
done
wait
```

**Prevention**:
Implemented mutex-like locking for critical tmux operations.

---

### 2024-01-14: GitHub CLI Authentication Loop

**Issue Duration**: 2.5 hours
**Severity**: Critical
**Recurrence Risk**: Low

**Problem**:
`gh pr create` entering infinite authentication loop in tmux session.

**Root Cause**:
SSH agent not properly forwarded to tmux session.

**Solution**:
```bash
# Ensure SSH agent forwarding
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval $(ssh-agent -s)
    ssh-add ~/.ssh/id_rsa
fi
export SSH_AUTH_SOCK
```

**Prevention**:
Added SSH agent check to session initialization.

---

## Debugging Techniques

### Tmux Session Debugging
```bash
# Log all tmux pane output
tmux pipe-pane -t "$session_name:$pane" "cat >> /tmp/tmux-$pane.log"

# Monitor specific pane
tmux capture-pane -t "$session_name:$pane" -p
```

### Process Tracing
```bash
# Trace script execution
set -x  # Enable debug mode
PS4='+ ${BASH_SOURCE}:${LINENO}: '  # Show file and line
```

### Git Worktree Diagnostics
```bash
# List all worktrees with status
git worktree list --porcelain

# Verify worktree health
git worktree prune --dry-run
```

---

## Common Error Patterns

1. **"command not found" in tmux**: Check PATH inheritance
2. **"worktree already exists"**: Run cleanup before retry
3. **"cannot create directory"**: Verify permissions and disk space
4. **"gh: authentication required"**: Check SSH agent and gh auth status
5. **"tmux: session not found"**: Verify session name and existence