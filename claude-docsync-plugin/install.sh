#!/bin/bash

# DocSync Plugin Installer for Claude Code
# Validates git changes against project documentation

set -e

INSTALL_DIR="$HOME/.claude"
COMMANDS_DIR="$INSTALL_DIR/commands"
SKILLS_DIR="$INSTALL_DIR/skills"

PLUGIN_NAME="docsync"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing $PLUGIN_NAME plugin for Claude Code..."
echo ""

# Create directories if they don't exist
mkdir -p "$COMMANDS_DIR"
mkdir -p "$SKILLS_DIR"

# Install command
echo "Installing command: /docsync"
cp "$SCRIPT_DIR/commands/docsync.md" "$COMMANDS_DIR/docsync.md"

# Install skill
echo "Installing skill: docsync-validator"
cp "$SCRIPT_DIR/skills/docsync-validator.md" "$SKILLS_DIR/docsync-validator.md"

echo ""
echo "✓ Installation complete!"
echo ""
echo "The /docsync command is now available in Claude Code."
echo ""
echo "Usage:"
echo "  /docsync                  # Validate against docs/ directory"
echo "  /docsync path/to/docs/    # Validate against custom directory"
