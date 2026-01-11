---
description: Spawn parallel subagents to validate git changes against documentation
argument-hint: [docs-directory-path]
---

# /docsync - Documentation Synchronization Validator

This command validates that all git changes comply with project documentation by spawning parallel subagents - one per documentation file.

## Arguments

- `$1` (optional): Custom docs directory path (default: `docs/`)

## Usage

```bash
/docsync
/docsync documentation/
/docsync docs/api/
```

## Instructions

You are the /docsync command. Your job is to validate that git changes comply with project documentation.

### Step 1: Determine the docs directory

Set `DOCS_DIR` to:
- `$1` if provided (first argument)
- `docs/` if no argument provided

### Step 2: Find all documentation files

Use the Glob tool to find documentation files:
- Pattern: `$DOCS_DIR/**/*.md`
- Pattern: `$DOCS_DIR/**/*.txt`
- Pattern: `$DOCS_DIR/**/*.rst`
- Pattern: `$DOCS_DIR/**/*.adoc`

Store the list of files. If no documentation files found, display:
```
No documentation files found in: $DOCS_DIR
Supported formats: .md, .txt, .rst, .adoc
```

### Step 3: Get git changes

Use the Bash tool to get changed files:
```bash
git status --porcelain
```

Parse the output to get the list of changed files (both staged and unstaged).

If no changes found, display:
```
No git changes detected to validate.
Both working directory and staging area are clean.
```

### Step 4: Spawn parallel subagents

For EACH documentation file, spawn a subagent using the Task tool with:

- `subagent_type`: "general-purpose"
- `prompt`: The following instructions with the doc file path and changed files substituted

```
You are a documentation validator subagent. Your job is to validate that git changes comply with a specific documentation file.

## Your Assigned Documentation File
[DOCUMENT_FILE_PATH]

## Changed Files to Analyze
[CHANGED_FILES_LIST - comma separated]

## Instructions

1. Read the documentation file at [DOCUMENT_FILE_PATH] using the Read tool
2. Extract all rules, conventions, guidelines, and requirements from the documentation
3. For each changed file in [CHANGED_FILES_LIST]:
   - Read the file content using the Read tool
   - Analyze if the changes comply with documentation requirements
   - Identify violations, inconsistencies, or missing implementations

## Output Format

Return your findings in EXACTLY this format:

## Document: [filename]

### Status: PASS/FAIL/WARNING

### Findings:
- [Specific violation or alignment check - one per line]
- [Another check...]

### Changed Files Analyzed:
- [filename]: [brief summary of findings]

### Recommendations:
[Optional suggestions for fixing violations - can be empty]

---

IMPORTANT:
- Be thorough but practical - focus on meaningful violations
- Use PASS if all changes comply
- Use WARNING for minor issues or unclear rules
- Use FAIL for clear violations
- Include the EXACT documentation filename in the header
```

### Step 5: Aggregate and display results

After all subagents complete, display a summary:

```
# DocSync Validation Summary

Documentation files analyzed: [N]
Git changes analyzed: [N]
Subagents spawned: [N]

---

[AGGREGATE ALL SUBAGENT OUTPUTS HERE]

---

## Overall Status: [PASS/FAIL/WARNING]

[Summary of results - e.g., "3 documents validated, 1 found violations"]
```

## Notes

- All subagents run in parallel for efficiency
- Each subagent works independently on one documentation file
- The command aggregates all results at the end
