---
description: Explore repository and create topic-based documentation
argument-hint: [organization-instructions]
---

# /docinit - Repository Documentation Generator

This command explores the entire repository and creates infrastructure and feature documentation. Documentation is separated into individual `.md` files by topic.

## Arguments

- `$ARGUMENTS` (optional): Organization instructions (e.g., "put architecture docs under docs/architecture/")

## Usage

```bash
# Default - creates docs in docs/
/docinit

# Custom organization
/docinit put architecture docs under docs/architecture/

# Organize by feature
/docinit organize by feature: docs/features/
```

## Instructions

You are the /docinit command. Your job is to explore the repository and create topic-based documentation.

### Step 1: Determine target directory

Set `ORGANIZATION_PROMPT` to `$ARGUMENTS` or empty if not provided.

The default target directory is `docs/`. If the user provided organization instructions, parse them to determine the target directory structure.

### Step 2: Create target directories

<command_output>
!`mkdir -p docs && echo "Directory ready"`
</command_output>

### Step 3: Discover architecture topics

Spawn an Explore subagent to discover architecture/structural topics:

Use the Task tool with:
- `subagent_type`: "Explore"
- `prompt`: The following instructions

```
You are exploring this repository to identify architecture and structural topics worth documenting.

Your goal: Find distinct structural components, design patterns, and organizational boundaries in this codebase.

Focus on:
- High-level architecture patterns
- Module/component organization
- Design patterns and conventions
- Infrastructure and tooling
- Configuration and setup

Return a JSON object with:
{
  "topics": [
    {
      "name": "topic-name",
      "description": "Brief description",
      "files": ["path/to/related/file1", "path/to/related/file2"]
    }
  ]
}

Be thorough but practical. Identify 3-8 distinct architectural topics.
```

### Step 4: Discover feature topics

Spawn an Explore subagent to discover concrete features/outcomes:

Use the Task tool with:
- `subagent_type`: "Explore"
- `prompt`: The following instructions

```
You are exploring this repository to identify concrete features and outcomes worth documenting.

Your goal: Find user-facing capabilities, features, and tangible outcomes this project provides.

Focus on:
- Core features and capabilities
- User-facing functionality
- APIs, interfaces, or entry points
- Data models and structures
- Key algorithms or processing logic

Return a JSON object with:
{
  "topics": [
    {
      "name": "topic-name",
      "description": "Brief description",
      "files": ["path/to/related/file1", "path/to/related/file2"]
    }
  ]
}

Be thorough but practical. Identify 3-8 distinct feature topics.
```

### Step 5: Merge and deduplicate topics

Combine topics from both explorers, removing duplicates and conflicts. Each topic should have:
- A clear, concise name (use filename-safe format like "authentication", "cache-layer")
- A description
- List of relevant files

### Step 6: Spawn documentation subagents

For EACH topic, spawn a subagent using the Task tool with:

- `subagent_type`: "general-purpose"
- `prompt`: The following instructions with topic details substituted

```
You are a documentation writer. Your job is to create a markdown document for a specific topic.

## Your Assigned Topic
Name: [TOPIC_NAME]
Description: [TOPIC_DESCRIPTION]

## Related Files to Analyze
[LIST_OF_FILES]

## Instructions

1. Read each related file using the Read tool
2. Understand the implementation and purpose
3. Create a markdown document at docs/[TOPIC_NAME].md with the following structure:

# [TOPIC_NAME]

## Overview
[2-3 sentences describing what this is and its purpose]

## Implementation
[Key implementation details - how it works, important patterns]

## Files
- List the main files involved with their paths

## Configuration
[Any configuration options, environment variables, or settings]

## Dependencies
[What this depends on or integrates with]

## Notes
[Any additional relevant information - edge cases, gotchas, future improvements]

IMPORTANT:
- Keep documentation concise and focused (target 50-150 lines per file)
- Use code examples from the actual implementation where helpful
- Be accurate - if you're uncertain, note it
- Use clear, simple language
```

### Step 7: Display summary

After all subagents complete, display a summary:

```
# Documentation Generation Complete

Topics documented: [N]

---

[LIST EACH GENERATED FILE]

---

## Organization
[Summary of how docs were organized based on user prompt]

## Next Steps
- Review generated documentation
- Edit as needed for clarity
- Commit docs/ to version control
```

## Notes

- All subagents run in parallel for efficiency
- Each subagent works independently on one topic
- No index.md is created - just individual topic files
- Docs are organized based on the organization prompt or default to docs/
