# DocSync Plugin for Claude Code

Validate git changes against project documentation using parallel subagents.

## Overview

DocSync spawns one subagent per documentation file in your `docs/` directory. Each subagent independently analyzes your git changes to ensure they comply with the rules and conventions defined in its assigned documentation.

## Features

- **Parallel Validation**: Multiple documentation files analyzed simultaneously
- **Git Integration**: Automatically detects staged and unstaged changes
- **Flexible Formats**: Supports `.md`, `.txt`, `.rst`, and `.adoc` documentation
- **Custom Paths**: Validate against any documentation directory
- **Structured Output**: Clear PASS/FAIL/WARNING status for each document

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
├── install.sh              # Installation script
├── README.md               # This file
├── commands/
│   └── docsync.md          # /docsync slash command
└── skills/
    └── docsync-validator.md # Subagent instruction template
```

## License

MIT
