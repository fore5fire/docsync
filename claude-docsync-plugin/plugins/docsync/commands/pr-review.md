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

**Important**: This command only works in a GitHub Actions pull_request context. For local development, use `/docsync` instead.

### Step 0: Verify GitHub Actions context

Check if running in GitHub Actions PR context:

<command_output>
!`echo "GITHUB_EVENT_NAME: $GITHUB_EVENT_NAME" && echo "GITHUB_EVENT_PATH: $GITHUB_EVENT_PATH" && echo "GITHUB_REF_NAME: $GITHUB_REF_NAME"`
</command_output>

If `GITHUB_EVENT_NAME` is not `pull_request`, display error and exit:
```
ERROR: This command only works in a GitHub Actions pull_request context.
Current event: $GITHUB_EVENT_NAME

For local validation, use /docsync instead.
```

Verify `gh` CLI is installed:

<command_output>
!`which gh && gh --version`
</command_output>

If `gh` is not found, display an error and exit:
```
ERROR: GitHub CLI (gh) is not installed.

In GitHub Actions, add this step before the action:
  - name: Install GitHub CLI
    run: |
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
      sudo apt-get update && sudo apt-get install -y gh
```

### Step 1: Determine the docs directory

Set `DOCS_DIR` to:
- `$1` if provided (first argument)
- `docs/` if no argument provided

### Step 2: Get PR information from environment

In GitHub Actions, PR information is available in the event JSON file. Read it using the Bash tool:

```bash
# Get PR number from event JSON
PR_NUMBER=$(jq -r '.pull_request.number' "$GITHUB_EVENT_PATH")
PR_TITLE=$(jq -r '.pull_request.title' "$GITHUB_EVENT_PATH")
BASE_REF=$(jq -r '.pull_request.base.ref' "$GITHUB_EVENT_PATH")
HEAD_REF=$(jq -r '.pull_request.head.ref' "$GITHUB_EVENT_PATH")

echo "PR_NUMBER=$PR_NUMBER"
echo "PR_TITLE=$PR_TITLE"
echo "BASE_REF=$BASE_REF"
echo "HEAD_REF=$HEAD_REF"
```

Store these values for later use.

### Step 3: Find all documentation files

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

### Step 4: Get git changes

Use the Bash tool to get changed files:

```bash
# Get the list of changed files between base and head
git diff --name-status origin/$BASE_REF...HEAD
```

Parse the output to get the list of changed files with their status (added, modified, deleted).

If no changes found, display:
```
No git changes detected to validate.
Both working directory and staging area are clean.
```

### Step 5: Spawn parallel subagents

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
- For inline comments, estimate the line number from the file content
- The "suggestion" field will be formatted as a GitHub suggestion if provided
- Use PASS if all changes comply
- Use WARNING for minor issues or unclear rules
- Use FAIL for clear violations
- Return ONLY the JSON object, no other text
```

### Step 6: Aggregate results and determine review status

After all subagents complete, parse all JSON responses and determine:

- `OVERALL_STATUS`: "APPROVE" if all PASS, "REQUEST_CHANGES" if any FAIL, "COMMENT" if any WARNING but no FAIL
- `INLINE_COMMENTS`: Array of all findings with file/line information
- `BODY_SUMMARY`: Aggregated summary of all findings

### Step 7: Build and post the PR review

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

Post the review using the Bash tool:

```bash
# Set review status
REVIEW_STATUS="[OVERALL_STATUS]"  # APPROVE, REQUEST_CHANGES, or COMMENT

# Post review with body
gh pr review "$PR_NUMBER" --$REVIEW_STATUS --body-file <(cat <<'REVIEW_BODY'
[REVIEW_BODY_CONTENT]
REVIEW_BODY
)
```

For inline comments with file and line information, post them separately using the GitHub API:

```bash
# Get current commit SHA
COMMIT_SHA=$(git rev-parse HEAD)

# For each inline comment
for comment in "${INLINE_COMMENTS[@]}"; do
  # Parse comment variables: FILE_PATH, LINE_NUMBER, COMMENT_BODY
  gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    /repos/$GITHUB_REPOSITORY/pulls/$PR_NUMBER/comments \
    -f "body=$COMMENT_BODY" \
    -f "commit_id=$COMMIT_SHA" \
    -f "path=$FILE_PATH" \
    -f "line=$LINE_NUMBER" \
    -f "side=RIGHT"
done
```

### Step 8: Display confirmation

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

## Environment Variables

In GitHub Actions PR context, these variables are available:

- `GITHUB_EVENT_NAME` - Event type (should be `pull_request`)
- `GITHUB_EVENT_PATH` - Path to event JSON file
- `GITHUB_REPOSITORY` - Owner/repo format
- `GITHUB_REF_NAME` - Branch name
- `GITHUB_SHA` - Commit SHA

From the event JSON (`$GITHUB_EVENT_PATH`):
- `.pull_request.number` - PR number
- `.pull_request.title` - PR title
- `.pull_request.base.ref` - Base branch
- `.pull_request.head.ref` - Head branch

## Notes

- All subagents run in parallel for efficiency
- Each subagent works independently on one documentation file
- Reviews use `gh` CLI which must be installed and authenticated
- In GitHub Actions, `GITHUB_TOKEN` provides authentication automatically
- REQUEST_CHANGES status can block PR merge if branch protection is configured
- Inline comments with line numbers are posted separately for better visibility
