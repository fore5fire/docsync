# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Latest Changes

- Added `/docsync:pr-review` command for GitHub PR integration
- Added `additional_permissions` to bypass bash approval checks

## Project Overview

Bottle is a Claude Code plugin marketplace project focused on documentation synchronization and validation tools. The main product is the **DocSync plugin** - a tool that validates git changes against project documentation using parallel subagents.

## Project Structure

```
bottle/
├── claude-docsync-plugin/          # Main plugin source code
│   ├── install.sh                  # Installation script
│   ├── .claude-plugin/
│   │   └── marketplace.json        # Plugin marketplace configuration
│   └── plugins/docsync/
│       ├── commands/               # Slash commands (.md files)
│       │   ├── docsync.md          # /docsync: Validate changes against docs (console output)
│       │   ├── pr-review.md        # /docsync:pr-review: Validate and post PR review
│       │   └── docinit.md          # /docinit: Auto-generate topic-based docs
│       └── skills/                 # Agent skills
│           └── docsync-validator.md # Subagent template for validation
├── docs/                           # Project documentation
│   └── architecture.md             # Architecture documentation
└── .github/workflows/
    ├── docsync.yml                 # DocSync validation for PRs
    ├── claude.yml                  # General Claude Code integration
    └── claude-code-review.yml      # Code review workflow
```

## Common Commands

### Plugin Installation

```bash
# Install the plugin locally
cd claude-docsync-plugin
./install.sh

# Or install via marketplace
claude plugin marketplace add ./claude-docsync-plugin
claude plugin install docsync@docsync-marketplace
```

### Running DocSync

```bash
# Validate against default docs/ directory (console output)
/docsync

# Validate against custom directory
/docsync documentation/

# Validate against subdirectory
/docsync docs/api/
```

### Running DocSync PR Review

```bash
# Validate and post PR review with inline comments
/docsync:pr-review

# With custom docs directory
/docsync:pr-review documentation/
```

**PR Review Behavior:**
- **APPROVE**: All changes comply with documentation
- **REQUEST_CHANGES**: Violations found - posts inline comments and blocks merge if branch protection enabled
- **COMMENT**: Minor issues/suggestions - posts comments but doesn't block

The GitHub Actions workflow uses `/docsync:pr-review` for automated PR validation.

### Auto-generating Documentation

```bash
# Generate docs in default docs/ directory
/docinit

# Custom organization
/docinit put architecture docs under docs/architecture/

# Organize by feature
/docinit organize by feature: docs/features/
```

### GitHub Actions

The `.github/workflows/docsync.yml` workflow automatically runs on pull requests to validate changes against documentation. It uses `/docsync:pr-review` which posts a GitHub PR review with:

- **REQUEST_CHANGES** for violations (can block merge)
- Inline comments with file/line references
- Applyable code suggestions

The workflow supports two authentication methods:

1. **OAuth** (recommended for Claude Max/Pro): Set up via `claude /install-github-app` - sets `CLAUDE_CODE_OAUTH_TOKEN` secret
2. **API Key**: Add `ANTHROPIC_API_KEY` repository secret from https://console.anthropic.com/

## Architecture

### DocSync Plugin

**Console Mode (`/docsync`)** - outputs to terminal:

1. **Discovery**: Finds all documentation files (`.md`, `.txt`, `.rst`, `.adoc`) in the target directory
2. **Change Detection**: Gets git changes (staged + unstaged) via `git status --porcelain`
3. **Parallel Processing**: Spawns one `general-purpose` subagent per documentation file using the `Task` tool
4. **Validation**: Each subagent independently validates changes against its assigned documentation
5. **Aggregation**: Combines all results into a summary report with PASS/FAIL/WARNING status

**PR Review Mode (`/docsync:pr-review`)** - posts GitHub review:

1. **Discovery**: Same as console mode
2. **Change Detection**: Uses `git diff` to get PR-specific changes
3. **Parallel Processing**: Same as console mode, but subagents return JSON with file/line info
4. **Validation**: Same as console mode
5. **Review Posting**: Uses `gh` CLI to post:
   - PR review with APPROVE/REQUEST_CHANGES/COMMENT status
   - Inline comments at specific file/line locations
   - Applyable code suggestions using GitHub's suggestion format

### DocInit Plugin

DocInit uses a **two-phase exploration + parallel documentation** architecture:

1. **Architecture Discovery**: Explore subagent identifies structural topics (patterns, modules, infrastructure)
2. **Feature Discovery**: Explore subagent identifies concrete features (capabilities, APIs, outcomes)
3. **Topic Deduplication**: Merges and removes duplicates between both exploration passes
4. **Parallel Documentation**: Spawns `general-purpose` subagents to create individual `.md` files per topic

### Slash Command Format

Commands are markdown files with YAML frontmatter:

```yaml
---
description: Command description
argument-hint: [optional-argument]
---
```

The command body contains instructions that Claude Code follows when the slash command is invoked.

### Marketplace Configuration

The `.claude-plugin/marketplace.json` file defines:
- Marketplace metadata (name, owner, description)
- Plugin list with version, author, keywords, category
- Source paths for each plugin

## Key Technologies

- **Plugin Format**: Claude Code Plugin Marketplace
- **Subagent Types**: `general-purpose` (validation/docs), `Explore` (codebase exploration)
- **Tools Used**: Glob (file discovery), Read (file content), Task (subagent spawning), Bash (git commands)
- **PR Integration**: GitHub CLI (`gh`) for posting reviews and inline comments
- **Authentication**: OAuth (`CLAUDE_CODE_OAUTH_TOKEN`) or API key (`ANTHROPIC_API_KEY`)

## File Formats Supported

DocSync validates against documentation in these formats:
- `.md` (Markdown)
- `.txt` (Plain text)
- `.rst` (reStructuredText)
- `.adoc` (AsciiDoc)

## Testing DocSync Changes

When modifying the DocSync plugin:

1. Test locally: `/docsync` in a test repository with documentation
2. Verify parallel subagent spawning works correctly
3. Test with custom documentation directories
4. For PR review testing, use `/docsync:pr-review` in a PR context
5. Verify `gh` CLI is installed and authenticated
6. Test inline comment formatting with GitHub's suggestion syntax
7. Verify GitHub Actions workflow if modifying `.github/workflows/docsync.yml`
8. Ensure OAuth token is passed as `with` parameter, not `env` (see commit 23d20f9)
