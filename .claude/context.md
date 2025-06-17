# Project Context

## Project Overview

**claude-automation** is a meta-automation framework that orchestrates multiple Claude Code instances to simulate a complete software development team. It automates the entire software development lifecycle from requirements gathering to PR creation.

## Technical Stack

- **Shell Scripts (Bash)**: Core automation logic
- **tmux**: Terminal multiplexer for managing parallel Claude Code sessions
- **Git + Git Worktree**: Version control and parallel branch development
- **GitHub CLI (gh)**: Automated PR creation and management
- **Claude Code**: AI development assistant (the primary execution engine)

## Constraints

1. **Environment Requirements**:
   - macOS or Linux environment (uses bash-specific features)
   - tmux must be installed and configured
   - Claude Code must be accessible via command line
   - GitHub CLI required for PR automation

2. **Development Constraints**:
   - Each development team works in isolated git worktree branches
   - Quality gates must pass before PR creation (80% test coverage)
   - All documentation must be in Japanese (as per current implementation)
   - Parallel development limited by available system resources

3. **Workflow Constraints**:
   - Sequential phase execution (requirements → design → implementation → test → release)
   - QA approval required before PR creation
   - Task assignment must specify branch names for git worktree isolation

## Technology Selection Rationale

### Why tmux?
- Enables true parallel execution of multiple Claude Code instances
- Provides visual monitoring of all teams simultaneously
- Maintains session persistence across disconnections
- Allows inter-pane communication for coordination

### Why Git Worktree?
- Enables parallel development without branch switching conflicts
- Each team has isolated working directory
- Simplifies merge conflict resolution
- Maintains clean git history

### Why Shell Scripts?
- Direct system integration without runtime dependencies
- Simple execution model for AI agents
- Easy debugging and modification
- Universal availability on Unix-like systems

### Why Claude Code as the Engine?
- Advanced code understanding and generation capabilities
- Contextual awareness for complex tasks
- Ability to execute system commands
- Natural language task interpretation

## Project-Specific Considerations

1. **Team Scaling**: Default 4 teams, but scalable based on project complexity
2. **Documentation Language**: Japanese for all generated documentation
3. **Quality Standards**: Enforced through automated quality gates
4. **Workflow Automation**: Complete hands-off operation after initial setup