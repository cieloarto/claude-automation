# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the claude-automation project - a sophisticated multi-agent development workflow automation framework that orchestrates Claude Code instances to simulate a complete development team with project managers, developers, and QA engineers.

## Commands

### Setting Up and Running
```bash
# Grant execute permissions to all scripts
chmod +x *.sh
# OR use the helper script
./claudeexe.sh

# Start the development environment with default 4 teams
./claude-pro-dev.sh <project-name>

# Start with custom team count (e.g., 6 teams)
./claude-pro-dev.sh <project-name> 6

# Start with custom workspace directory
./claude-pro-dev.sh <project-name> 4 /path/to/workspace
```

### Development Workflow Commands
```bash
# Import external knowledge/documentation
import-knowledge '<url>' '<description>'

# Execute development phases
requirements '<project-description>'
design
implementation
integration-test

# Assign tasks to teams
task-assign <team-number> '<task-description>' '<branch-name>'

# Run QA quality checks
qa-check <team-letter> '<branch-name>'

# Check progress and status
progress
status
help
```

### Git Operations
```bash
# The scripts use git worktree for parallel development
# Branches follow the pattern: feature/<task-name>
# PRs are created automatically after QA approval using GitHub CLI
```

## Architecture

### Core Scripts
- **claude-pro-dev.sh**: Main entry point that sets up tmux sessions with multiple panes for project manager, QA team, and development teams
- **claude-functions.sh**: Core helper functions including project initialization, phase management, document structure definitions, and image analysis capabilities
- **claude-qa.sh**: QA functionality including quality gates, PR creation/review automation, and integration testing workflows
- **claude-workflow.sh**: Workflow orchestration for requirements, design, implementation, integration testing, and release phases
- **claudeexe.sh**: Simple utility to set execute permissions on all .sh files

### Development Phases Flow
1. **Requirements Definition** → Generates `docs/requirements/requirements.md`
2. **Design** → Creates `docs/design/architecture.md` and `docs/design/database.md`
3. **Implementation** → Distributed task execution across teams
4. **Quality Gates** → Automated checks (80% test coverage, security scans, etc.)
5. **Integration Testing** → Full system validation
6. **Release** → Automated PR creation and approval

### Project Structure
```
projects/
└── docs/
    ├── design/       # Architecture and UI design documents
    ├── knowledge/    # Technical knowledge base
    ├── requirements/ # Project requirements documents
    ├── tasks/        # Task breakdown and assignments
    └── tests/        # Test specifications
```

### Quality Gate Criteria
- 80% test coverage requirement
- Security vulnerability scanning
- Performance benchmarks
- Code review standards
- Automated PR creation upon passing all checks

## Important Notes

- This is a bash-based automation framework, not a Node.js project (despite .tool-versions specifying Node.js)
- Uses tmux for managing multiple Claude Code instances in parallel
- Requires GitHub CLI (`gh`) for automated PR operations
- All development happens in the `projects/` workspace directory
- The framework simulates a complete development team workflow with automatic task distribution and quality enforcement