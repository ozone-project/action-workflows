# Code Review Workflow Documentation

## Overview

This GitHub Actions workflow provides automated code review for pull requests using Claude Code and the synapse core plugin. The review is powered by synapse's `code-reviewer` agent, which checks conventions, framework best practices, and applies structured review criteria. Results are posted as **inline review comments** directly on the PR diff, not as a single sticky comment.

File ignore patterns are supported to exclude generated or vendored files from review.

## How It Works

1. Checks out the repository
2. Installs the Claude Code SDK
3. Clones `ozone-project/synapse` and installs the core plugin (`claude plugin install ./synapse-temp/plugins/core`)
4. Creates a `python3` symlink at `~/.synapse/.venv/bin/python3` (required by `post-review.py`, which uses only stdlib)
5. Runs `/check-pr` via `claude -p --dangerously-skip-permissions`
6. The `check-pr` skill invokes the `code-reviewer` agent, transforms findings into inline comments, and posts them as a GitHub pull request review

## What the Review Checks

- Security vulnerabilities (XSS, SQL injection, credential exposure, etc.)
- Error handling and crash risks
- Code complexity and reuse opportunities
- Test coverage gaps
- Framework and library best practices (looked up via web search)
- Project conventions from `.claude/skills/conv-*` files, if present in the repository

## Setup Instructions

### 1. Configure Secrets

Add these secrets at the organization or repository level:

- `CODE_REVIEW_ANTHROPIC_API_KEY` - Anthropic API key
- `CODE_REVIEW_GH_TOKEN` - GitHub token with PR write permissions and read access to `ozone-project/synapse`

### 2. Use the Workflow

Call the shared workflow from a workflow in your repository:

```yaml
name: PR Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    uses: ozone-project/action-workflows/.github/workflows/code-review.yml@master
    with:
      ignore_patterns: |
        *.generated.ts
        dist/**
        *.min.js
    secrets:
      CODE_REVIEW_ANTHROPIC_API_KEY: ${{ secrets.CODE_REVIEW_ANTHROPIC_API_KEY }}
      CODE_REVIEW_GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

The `ignore_patterns` input is optional. Omit it to review all changed files.

## File Structure During CI

```
repo/
├── synapse-temp/              # Cloned temporarily, deleted after plugin install
│   └── plugins/core/          # Source of the core plugin
└── .claude/                   # Created by plugin install
    ├── agents/
    │   └── code-reviewer.md   # Review agent
    ├── skills/
    │   ├── check-pr/          # PR review orchestration
    │   └── comment-pr/        # Comment formatting + post-review.py
    └── commands/
```

## Troubleshooting

**Plugin install fails**

The `CODE_REVIEW_GH_TOKEN` must have read access to `ozone-project/synapse`. Verify the token's permissions and that it is not expired.

**Review not posted**

Check the "Run code review" step logs in GitHub Actions. The most common cause is an invalid or missing `CODE_REVIEW_ANTHROPIC_API_KEY`. Claude Code logs will show any API errors.

**Axon MCP warnings in logs**

Expected in CI. The Axon MCP proxy requires OAuth credentials that are not available in the CI environment. The review completes normally without Jira or other Axon context.

## Version History

- **v3.0** - Switched to synapse core plugin; inline review comments; convention checking and framework best practices via `code-reviewer` agent
- **v2.0** - Fixed broken paths using dynamic `find` command, improved error handling
- **v1.0** - Initial implementation with hard-coded paths
