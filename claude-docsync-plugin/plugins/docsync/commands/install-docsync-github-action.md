---
description: Install DocSync GitHub Action workflow for PR validation
---

# /install-docsync-github-action

Installs the DocSync GitHub Action workflow that validates documentation compliance on every pull request.

## Instructions

You are the /install-docsync-github-action command. Your job is to set up the GitHub Action workflow for DocSync validation.

### Step 1: Verify GitHub repository

Check if this is a git repository with a GitHub remote:

<command_output>
!`git remote -v | grep github`
</command_output>

If no GitHub remote is found, display an error:
```
Error: No GitHub remote found.
This command only works with GitHub repositories.
```

### Step 2: Create workflows directory

Ensure the `.github/workflows` directory exists:

<command_output>
!`mkdir -p .github/workflows && echo "Directory ready"`
</command_output>

### Step 3: Create the workflow file

Write the following content to `.github/workflows/docsync.yml`:

```yaml
name: DocSync Validation

on:
  pull_request:
    types: [opened, synchronize, reopened]

permissions:
  contents: read
  pull-requests: write
  id-token: write

jobs:
  docsync:
    name: Validate changes against documentation
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install Claude Code CLI
        run: npm install -g @anthropic-ai/claude-code

      - name: Install DocSync plugin
        run: |
          claude plugin marketplace add ./claude-docsync-plugin
          claude plugin install docsync@docsync-marketplace

      - name: Run Claude Code with DocSync
        uses: anthropics/claude-code-action@v1
        with:
          prompt: /docsync:docsync
          claude_args: --max-turns 15
        env:
          # OAuth: Set up via "claude /install-github-app" (recommended for Claude Max/Pro)
          CLAUDE_CODE_OAUTH_TOKEN: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
          # API Key: Alternative for direct API users
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

### Step 4: Verify installation

Check that the file was created successfully:

<command_output>
!`test -f .github/workflows/docsync.yml && echo "Workflow file created" || echo "Failed to create workflow file"`
</command_output>

### Step 5: Display authentication setup instructions

If successful, display:

```
✓ DocSync GitHub Action installed successfully!

The workflow file has been created at: .github/workflows/docsync.yml

🔐 Authentication Setup (choose one):

Option 1: OAuth (Recommended for Claude Max/Pro subscribers)
  Run: claude /install-github-app
  This will create the CLAUDE_CODE_OAUTH_TOKEN secret automatically.

Option 2: API Key
  1. Get your API key from: https://console.anthropic.com/
  2. Add it as a repository secret:
     - Go to: Settings → Secrets and variables → Actions
     - Name: ANTHROPIC_API_KEY
     - Value: sk-ant-...

Next steps:
1. Commit and push this file to your repository
2. The action will run on all pull requests

To commit:
  git add .github/workflows/docsync.yml
  git commit -m "Add DocSync GitHub Action for documentation validation"
  git push
```

## Notes

- The workflow supports both OAuth (recommended) and API key authentication
- OAuth is set up via the /install-github-app command
- At least one authentication method must be configured
