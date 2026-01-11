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

### Step 1: Determine target directory and analyze existing docs

Set `ORGANIZATION_PROMPT` to `$ARGUMENTS` or empty if not provided.

The default target directory is `docs/`. If the user provided organization instructions, parse them to determine the target directory structure.

<command_output>
!`find docs -type f \( -name "*.md" -o -name "*.txt" -o -name "*.rst" -o -name "*.adoc" \) 2>/dev/null | head -20`
</command_output>

Store the output as `EXISTING_DOCS`.

### Step 2: Analyze existing documentation conventions

If `EXISTING_DOCS` is not empty (i.e., docs/ directory exists with documentation files), spawn an Explore subagent to understand existing conventions:

Use the Task tool with:
- `subagent_type`: "Explore"
- `prompt`: The following instructions

```
You are analyzing existing documentation to understand the current conventions and patterns used in this repository.

Your goal: Understand the existing documentation structure, format, and conventions so new docs will match.

Focus on:
- File naming patterns (e.g., "feature-name.md", "FeatureName.md", "feature_name.md")
- Directory structure (flat under docs/, or organized in subdirectories)
- Markdown section structure and heading hierarchy
- Tone and writing style (formal, casual, technical, user-facing)
- Common sections used (Overview, Usage, Examples, API, etc.)
- Code block formatting and language annotations
- Any special formatting or conventions

Read 5-10 representative documentation files to identify patterns.

Return a JSON object with:
{
  "conventions": {
    "naming_pattern": "kebab-case | PascalCase | snake_case | other (describe)",
    "directory_structure": "flat | hierarchical (describe subdirs if any)",
    "heading_style": "atx (# Header) | setext (Header\\n======)",
    "common_sections": ["Overview", "Usage", "Examples", ...],
    "tone_description": "brief description of writing style",
    "code_formatting": "description of how code blocks are formatted",
    "additional_conventions": "any other patterns observed"
  },
  "existing_topics": ["list", "of", "existing", "doc", "topics"],
  "sample_structure": "brief description of a typical doc's structure"
}
```

Store the result as `EXISTING_CONVENTIONS`.

If no existing docs are found, set `EXISTING_CONVENTIONS` to:
```json
{
  "conventions": {
    "naming_pattern": "kebab-case",
    "directory_structure": "flat",
    "heading_style": "atx",
    "common_sections": ["Overview", "Implementation", "Files", "Configuration", "Dependencies", "Notes"],
    "tone_description": "clear, concise, technical",
    "code_formatting": "standard markdown code blocks with language annotation",
    "additional_conventions": "none"
  },
  "existing_topics": [],
  "sample_structure": "flat structure with Overview, Implementation, Files, Configuration, Dependencies, Notes sections"
}
```

### Step 3: Create target directories

<command_output>
!`mkdir -p docs && echo "Directory ready"`
</command_output>

### Step 4: Discover architecture topics

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

### Step 5: Discover feature topics

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

### Step 6: Merge and deduplicate topics

Combine topics from both explorers, removing duplicates and conflicts. Each topic should have:
- A clear, concise name (use filename-safe format like "authentication", "cache-layer")
- A description
- List of relevant files

**IMPORTANT**: Before proceeding, check if any discovered topic names conflict with `EXISTING_CONVENTIONS.existing_topics`. If so, either:
- Skip the topic (already documented)
- Merge with existing topic
- Rename to avoid conflict

### Step 7: Confirm organization with user

After completing exploration and topic discovery, present findings to the user and ask for confirmation on organization preferences.

Use the AskUserQuestion tool with the following configuration:

```
{
  "questions": [
    {
      "question": "Found [N] topics to document and [M] existing docs. How should new docs be organized?",
      "header": "Organization",
      "multiSelect": false,
      "options": [
        {
          "label": "Match existing structure",
          "description": "Follow existing directory structure and naming conventions (detected: [EXISTING_CONVENTIONS.conventions.directory_structure] with [EXISTING_CONVENTIONS.conventions.naming_pattern] naming)"
        },
        {
          "label": "All in docs/ root",
          "description": "Place all new documentation files flat in the docs/ directory"
        },
        {
          "label": "Organize by type",
          "description": "Group architecture topics in docs/architecture/ and feature topics in docs/features/"
        }
      ]
    },
    {
      "question": "Should new docs follow existing formatting conventions?",
      "header": "Format",
      "multiSelect": false,
      "options": [
        {
          "label": "Yes, match existing style",
          "description": "Use detected conventions: [EXISTING_CONVENTIONS.conventions.tone_description] tone, [EXISTING_CONVENTIONS.conventions.heading_style] headings, and common sections like [EXISTING_CONVENTIONS.conventions.common_sections.join(', ')]"
        },
        {
          "label": "Use standard format",
          "description": "Apply a standard format with Overview, Implementation, Files, Configuration, Dependencies, and Notes sections"
        }
      ]
    }
  ]
}
```

Store user responses as `ORGANIZATION_CHOICE` and `FORMAT_CHOICE`.

Set `FINAL_CONVENTIONS` based on user choices:
- If user chose to match existing: use `EXISTING_CONVENTIONS`
- If user chose standard/default: use default conventions from Step 2

### Step 8: Spawn documentation subagents

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

## Documentation Conventions to Follow
Naming pattern: [FINAL_CONVENTIONS.conventions.naming_pattern]
Directory structure: [FINAL_CONVENTIONS.conventions.directory_structure]
Heading style: [FINAL_CONVENTIONS.conventions.heading_style]
Tone: [FINAL_CONVENTIONS.conventions.tone_description]
Common sections: [FINAL_CONVENTIONS.conventions.common_sections.join(', ')]
Code formatting: [FINAL_CONVENTIONS.conventions.code_formatting]
Additional conventions: [FINAL_CONVENTIONS.conventions.additional_conventions]

Sample structure: [FINAL_CONVENTIONS.sample_structure]

## Instructions

1. Read each related file using the Read tool
2. Understand the implementation and purpose
3. Determine the output path based on ORGANIZATION_CHOICE:
   - If "Match existing structure": Follow FINAL_CONVENTIONS.directory_structure
   - If "All in docs/ root": Use docs/[TOPIC_NAME].md
   - If "Organize by type": Use docs/architecture/[TOPIC_NAME].md or docs/features/[TOPIC_NAME].md
4. Format the filename using FINAL_CONVENTIONS.conventions.naming_pattern
5. Create the markdown document with sections matching FINAL_CONVENTIONS.conventions.common_sections

### Template Structure
# [TOPIC_NAME (formatted per naming convention)]

[Sections from FINAL_CONVENTIONS.conventions.common_sections - create each section if relevant]

## Overview
[2-3 sentences describing what this is and its purpose]

[Add other sections based on detected conventions or standard structure]

IMPORTANT:
- Keep documentation concise and focused (target 50-150 lines per file)
- Match the writing style: FINAL_CONVENTIONS.conventions.tone_description
- Use code examples from the actual implementation where helpful
- Format code blocks as: FINAL_CONVENTIONS.conventions.code_formatting
- Use headings in style: FINAL_CONVENTIONS.conventions.heading_style
- Be accurate - if you're uncertain, note it
```

### Step 9: Display summary

After all subagents complete, display a summary:

```
# Documentation Generation Complete

Topics documented: [N]
Existing docs found: [M]

---

## Generated Files
[LIST EACH GENERATED FILE WITH PATH]

---

## Organization Applied
[Describe organization choice and structure used]

## Conventions Applied
- Naming: [FINAL_CONVENTIONS.conventions.naming_pattern]
- Structure: [FINAL_CONVENTIONS.conventions.directory_structure]
- Style: [FINAL_CONVENTIONS.conventions.heading_style]
- Sections: [FINAL_CONVENTIONS.conventions.common_sections]

## Next Steps
- Review generated documentation for accuracy
- Edit as needed for clarity and completeness
- Commit docs/ to version control
```

## Notes

- All subagents run in parallel for efficiency
- Each subagent works independently on one topic
- Existing documentation is analyzed to preserve conventions
- User is prompted to confirm organization preferences after exploration
- Topics conflicting with existing docs are skipped, merged, or renamed
- No index.md is created - just individual topic files
- Docs are organized based on user choice or follow existing structure
