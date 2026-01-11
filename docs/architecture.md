# Bottle Architecture

## Overview

Bottle is a Claude Code plugin marketplace project focused on documentation synchronization and validation tools.

## Project Structure

```
bottle/
├── claude-docsync-plugin/    # DocSync plugin source
│   └── plugins/
│       └── docsync/
│           ├── commands/     # Slash commands
│           └── skills/       # Agent skills
└── docs/                     # Project documentation
```

## DocSync Plugin Architecture

### Purpose
Validate git changes against project documentation using parallel subagents.

### Components

1. **Slash Command** (`/docsync`)
   - Entry point for documentation validation
   - Spawns parallel subagents for each documentation file
   - Aggregates results into a summary report

2. **Subagent Validator** (`docsync-validator`)
   - Analyzes individual documentation files
   - Extracts rules, conventions, and requirements
   - Validates git changes against documented standards

### Workflow

```
User runs /docsync
    ↓
Discover documentation files (docs/**/*.md, .txt, .rst, .adoc)
    ↓
Get git changes (staged + unstaged)
    ↓
Spawn parallel subagents (one per doc file)
    ↓
Each subagent validates changes against its assigned documentation
    ↓
Aggregate and display results
```

### Design Principles

1. **Parallel Processing**: Multiple documentation files analyzed simultaneously
2. **Isolated Validation**: Each subagent works independently on one document
3. **Flexible Formats**: Supports common documentation file types
4. **Git Integration**: Automatically detects changes in working directory and staging area
5. **Naming Convention**: All slash command files MUST use kebab-case (e.g., `my-command.md`, not `MyCommand.md` or `my_command.md`)

### Technology Stack

- **Plugin Format**: Claude Code Plugin Marketplace
- **Command Type**: Slash Command
- **Subagent Type**: General-purpose agent
- **Tools**: Glob (file discovery), Read (file content), Task (subagent spawning)

## Installation

```bash
# Add local marketplace
/plugin marketplace add ./claude-docsync-plugin

# Install plugin
/plugin install docsync@docsync-marketplace
```

## Usage

```bash
/docsync                  # Validate against docs/
/docsync path/to/docs/    # Validate against custom directory
```

## Future Enhancements

- Support for additional file formats (PDF, Word docs)
- Configuration file for custom validation rules
- Auto-fix capability for common violations
- Integration with CI/CD pipelines
