# DocSync Plugin for Claude Code

Validate git changes against project documentation and automatically generate topic-based docs.

## Overview

DocSync provides two main capabilities:

1. **`/docsync`**: Validates git changes against existing documentation using parallel subagents
2. **`/docinit`**: Explores your repository and automatically generates topic-based documentation

## Features

- **Parallel Validation**: Multiple documentation files analyzed simultaneously
- **Auto-Documentation**: Generate docs from codebase using AI exploration
- **Git Integration**: Automatically detects staged and unstaged changes
- **Flexible Formats**: Supports `.md`, `.txt`, `.rst`, and `.adoc` documentation
- **Custom Paths**: Validate against any documentation directory
- **Structured Output**: Clear PASS/FAIL/WARNING status for each document
- **GitHub Actions**: Automated validation on pull requests
- **Project Agnostic**: Works for software, infrastructure, data, hardware, and more

## Installation

```bash
git clone <repository-url>
cd claude-docsync-plugin
./install.sh
```

## Usage

```bash
# Validate against default docs/ directory
/docsync

# Validate against custom directory
/docsync documentation/

# Validate against subdirectory
/docsync docs/api/
```

## Generate Documentation

The `/docinit` command analyzes your repository and automatically generates topic-based documentation:

```bash
# Generate docs in default docs/ directory
/docinit

# Custom organization
/docinit put architecture docs under docs/architecture/

# Organize by feature
/docinit organize by feature: docs/features/
```

**How it works:**
1. Two Explore subagents analyze your codebase:
   - **Architecture pass**: Identifies structural components, design patterns, organization
   - **Features pass**: Identifies concrete features, capabilities, user-facing outcomes
2. Parallel subagents document each topic in separate `.md` files
3. Works for any project type: software, infrastructure, data, hardware, etc.

**Each generated document includes:**
- Overview and purpose
- Implementation details
- Related files
- Configuration requirements
- Dependencies and integrations

## GitHub Actions Setup

To automatically validate documentation compliance on every pull request:

```bash
# Install the GitHub Action workflow
/install-docsync-github-action
```

This command creates `.github/workflows/docsync.yml` which:
- Runs on all pull requests
- Installs the DocSync plugin
- Validates changes against documentation
- Supports both OAuth and API key authentication

### Authentication

Choose one authentication method for the GitHub Action:

**Option 1: OAuth (Recommended for Claude Max/Pro)**
```bash
claude /install-github-app
```
This automatically sets up the `CLAUDE_CODE_OAUTH_TOKEN` secret.

**Option 2: API Key**
1. Get your API key from: https://console.anthropic.com/
2. Add it as a repository secret named `ANTHROPIC_API_KEY`

## How It Works

1. Discovers all documentation files in the specified directory
2. Gets the list of changed files from git (staged + unstaged)
3. Spawns one subagent per documentation file
4. Each subagent:
   - Reads its assigned documentation file
   - Extracts rules, conventions, and requirements
   - Analyzes each changed file against those requirements
5. Aggregates and displays all results

## Example Documentation

Your documentation files should clearly define rules and conventions. For example:

```markdown
# API Style Guide

## Naming Conventions
- Functions must use camelCase
- Constants must use UPPER_SNAKE_CASE
- Classes must use PascalCase

## Documentation Requirements
- All functions must have JSDoc comments
- Complex logic must have inline comments

## Code Style
- Maximum function length: 50 lines
- Maximum line length: 100 characters
- Use 2 spaces for indentation
```

## Example Output

```
# DocSync Validation Summary

Documentation files analyzed: 3
Git changes analyzed: 5
Subagents spawned: 3

---

## Document: docs/api-style.md

### Status: FAIL

### Findings:
- Function `get_user_data` uses snake_case instead of camelCase
- Function `processRequest` lacks JSDoc comment
- Function `handleData` is 67 lines (exceeds 50 line limit)

### Changed Files Analyzed:
- src/api/handlers.js: 3 violations found

### Recommendations:
- Rename `get_user_data` to `getUserData`
- Add JSDoc comment to `processRequest`
- Refactor `handleData` into smaller functions

---

## Overall Status: FAIL

1 of 3 documents found violations.
```

## Requirements

- Claude Code CLI
- Git repository
- Documentation in supported formats (`.md`, `.txt`, `.rst`, `.adoc`)

## Plugin Structure

```
claude-docsync-plugin/
├── install.sh                      # Installation script
├── README.md                       # This file
├── commands/
│   ├── docsync.md                  # /docsync slash command
│   ├── docinit.md                  # /docinit slash command
│   └── install-docsync-github-action.md  # Install GitHub Action
└── skills/
    └── docsync-validator.md        # Subagent instruction template
```

## License

MIT
