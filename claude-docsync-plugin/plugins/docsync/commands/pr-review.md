---
description: Validate git changes against docs and post PR review with inline comments
argument-hint: [docs-directory-path]
---

# /docsync:pr-review - PR Documentation Validator

This command validates that all git changes comply with project documentation and posts a GitHub PR review with inline comments and change requests for violations.

## Arguments

- `$1` (optional): Custom docs directory path (default: `docs/`)

## Usage

```bash
/docsync:pr-review
/docsync:pr-review documentation/
/docsync:pr-review docs/api/
```

## Instructions

You are the /docsync:pr-review command. Your job is to validate that git changes comply with project documentation and post a GitHub PR review.

### Prerequisites

This command requires GitHub CLI (`gh`) to be installed and authenticated. When running in GitHub Actions, authentication is automatically provided via `GITHUB_TOKEN`.

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

Store the list of files. If no documentation files found, post a review comment and exit:
```
No documentation files found in: $DOCS_DIR
Supported formats: .md, .txt, .rst, .adoc
```

### Step 3: Get PR information and git changes

<command_output>
!`gh pr view --json number,title,headRefName,baseRefName --jq '{number: .number, title: .title, head: .headRefName, base: .baseRefName}'`
</command_output>

Store the PR info. If not in a PR context, display:
```
Error: Not in a pull request context. Use /docsync instead.
```

Get the base branch for diff comparison:

<command_output>
!`git log --pretty=format:'%H' --no-patch`
</command_output>

Get git changes using the Bash tool:
```bash
git diff --name-status origin/$(gh pr view --json baseRefName --jq .baseRefName)...HEAD
```

Parse the output to get the list of changed files with their status (added, modified, deleted).

If no changes found, post an approving review:
```
No git changes detected to validate.
Both working directory and staging area are clean.
```

### Step 4: Spawn parallel subagents

For EACH documentation file, spawn a subagent using the Task tool with:

- `subagent_type`: "general-purpose"
- `prompt`: The following instructions with the doc file path and changed files substituted

```
You are a documentation validator subagent for PR review. Your job is to validate that git changes comply with a specific documentation file.

## Your Assigned Documentation File
[DOCUMENT_FILE_PATH]

## Changed Files to Analyze
[CHANGED_FILES_LIST - comma separated with status]

## Instructions

1. Read the documentation file at [DOCUMENT_FILE_PATH] using the Read tool
2. Extract all rules, conventions, guidelines, and requirements from the documentation
3. For each changed file in [CHANGED_FILES_LIST]:
   - Read the file content using the Read tool
   - Get the diff for the file using: git diff [BASE_REF]...HEAD -- [FILE_PATH]
   - Analyze if the changes comply with documentation requirements
   - Identify violations, inconsistencies, or missing implementations

## Output Format - JSON ONLY

Return a VALID JSON object (no markdown, no code blocks, just raw JSON):

{
  "document": "filename.md",
  "status": "PASS|FAIL|WARNING",
  "findings": [
    {
      "file": "path/to/file.js",
      "line": 42,
      "severity": "error|warning|info",
      "message": "Description of the issue",
      "suggestion": "Optional: suggested fix code"
    }
  ],
  "summary": "Brief summary of findings",
  "recommendations": ["List of recommendations"]
}

IMPORTANT:
- For inline comments, include the line number from the diff
- The "suggestion" field will be formatted as a GitHub suggestion if provided
- Use PASS if all changes comply
- Use WARNING for minor issues or unclear rules
- Use FAIL for clear violations
- Return ONLY the JSON object, no other text
```

### Step 5: Aggregate results and determine review status

After all subagents complete, parse all JSON responses and determine:

- `OVERALL_STATUS`: "APPROVE" if all PASS, "REQUEST_CHANGES" if any FAIL, "COMMENT" if any WARNING but no FAIL
- `INLINE_COMMENTS`: Array of all findings with file/line information
- `BODY_SUMMARY`: Aggregated summary of all findings

### Step 6: Build and post the PR review

Create the review body using this template:

```
## DocSync Validation Report

**Overall Status**: [OVERALL_STATUS]

- Documentation files analyzed: [N]
- Changed files analyzed: [N]
- Issues found: [N]

---

### Summary

[AGGREGATED_SUMMARY]

---

### Details by Document

[FOR EACH DOCUMENT]
**[DOCUMENT_NAME]**: [STATUS]

[Document-specific findings and recommendations]

---

### Review Policy

- **APPROVE**: All changes comply with documentation
- **REQUEST_CHANGES**: One or more violations found - please address before merging
- **COMMENT**: Minor issues or suggestions provided

_This review was generated by the DocSync plugin for Claude Code._
```

Build inline comments in JSON format for `gh pr review`:

For each finding with a file and line number, create an inline comment:
```json
{
  "path": "path/to/file.js",
  "line": 42,
  "body": "message\n\n```suggestion\nsuggested code\n```"
}
```

Post the review using the Bash tool:

```bash
# Build review command based on overall status
REVIEW_STATUS="[OVERALL_STATUS]"  # APPROVE, REQUEST_CHANGES, or COMMENT

# Post review with body
gh pr review --$REVIEW_STATUS --body-file <(cat <<'REVIEW_BODY'
[REVIEW_BODY_CONTENT]
REVIEW_BODY
)

# Post inline comments separately if there are any
if [ ${#INLINE_COMMENTS[@]} -gt 0 ]; then
  for comment in "${INLINE_COMMENTS[@]}"; do
    gh pr comment "$comment" --repo "$GITHUB_REPOSITORY"
  done
fi
```

For inline comments with suggestions, use the GitHub API directly for proper formatting:

```bash
# For each inline comment, use gh api
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /repos/${GITHUB_REPOSITORY}/pulls/${PR_NUMBER}/comments \
  -f "body=$COMMENT_BODY" \
  -f "commit_id=$(git log --pretty=format:'%H' --no-patch)" \
  -f "path=$FILE_PATH" \
  -f "line=$LINE_NUMBER" \
  -f "side=RIGHT"
```

### Step 7: Display confirmation

After posting the review, display:

```
# PR Review Posted

Status: [OVERALL_STATUS]
PR: #[PR_NUMBER] - [PR_TITLE]

Inline comments posted: [N]
Body summary: [TRUNCATED_PREVIEW]
```

## GitHub Suggestion Format

For inline code suggestions, use GitHub's supported format:

```
This code violates the documented convention.

```suggestion
def correct_function():
    """Correct implementation following docs."""
    return documented_pattern
```
```

GitHub will render this as an applyable suggestion in the PR UI.

## Notes

- All subagents run in parallel for efficiency
- Each subagent works independently on one documentation file
- Reviews use `gh` CLI which must be installed and authenticated
- In GitHub Actions, `GITHUB_TOKEN` provides authentication automatically
- REQUEST_CHANGES status can block PR merge if branch protection is configured
- Inline comments with line numbers are posted separately for better visibility
