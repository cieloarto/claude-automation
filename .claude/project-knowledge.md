# Project Knowledge

## Architecture Decisions

### Multi-Agent Architecture
- **Decision**: Use tmux panes to run multiple Claude Code instances in parallel
- **Rationale**: Simulates real development team dynamics with independent agents
- **Benefits**: True parallel execution, visual monitoring, session persistence

### Document-Driven Development
- **Decision**: Generate structured documentation before implementation
- **Structure**: requirements → design → tasks → tests → implementation
- **Benefits**: Clear specifications, traceability, automated quality checks

### Git Worktree Strategy
- **Decision**: Each team works in isolated worktree branches
- **Implementation**: `git worktree add` for each feature branch
- **Benefits**: No branch switching conflicts, parallel development, clean merges

## Implementation Patterns

### Function Naming Convention
```bash
# Phase management functions
requirements() { ... }
design() { ... }
implementation() { ... }

# Team management functions
task-assign() { ... }
qa-check() { ... }

# Utility functions
import-knowledge() { ... }
progress() { ... }
```

### Error Handling Pattern
```bash
if ! command; then
    echo "エラー: $task_description" >&2
    return 1
fi
```

### Session Management Pattern
```bash
# Always check for existing tmux session
tmux has-session -t "$session_name" 2>/dev/null
# Send commands with proper escaping
tmux send-keys -t "$session_name:$pane" "$command" C-m
```

## Patterns to Avoid

1. **Direct Claude Code Invocation**: Always use tmux for session management
2. **Synchronous Task Execution**: Leverage parallel execution capabilities
3. **Manual PR Creation**: Use GitHub CLI automation
4. **Hardcoded Paths**: Use variables for workspace and project paths
5. **English Documentation**: Maintain Japanese consistency

## Library and Tool Selection

### tmux Configuration
- **Version**: 3.0+ required for advanced pane management
- **Key Features**: send-keys, split-window, select-pane
- **Layout**: Custom 2x3 grid for optimal team visibility

### GitHub CLI Usage
```bash
# PR creation with automatic formatting
gh pr create --title "$title" --body "$body"
# Automated review approval
gh pr review --approve
```

### Image Analysis Integration
- **Purpose**: Analyze design mockups and error screenshots
- **Implementation**: Uses Claude's vision capabilities
- **Functions**: `analyze_design_image()`, `analyze_error_image()`

## Performance Optimizations

1. **Parallel Initialization**: All teams start simultaneously
2. **Lazy Document Generation**: Only create when needed
3. **Worktree Caching**: Reuse existing worktrees when possible
4. **Session Persistence**: Maintain tmux sessions across runs

## Security Considerations

1. **No Credentials in Scripts**: Use environment variables
2. **Git Config Isolation**: Each worktree has isolated config
3. **PR Permissions**: Rely on GitHub CLI authentication
4. **File Permissions**: Scripts require explicit execute permission