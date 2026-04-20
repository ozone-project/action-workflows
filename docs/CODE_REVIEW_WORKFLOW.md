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
- `CODE_REVIEW_APP_ID` - GitHub App ID for PR access
- `CODE_REVIEW_APP_PRIVATE_KEY` - GitHub App private key
- `VMETRICS_PUSH_URL` - (Optional) VictoriaMetrics push endpoint for review metrics
- `VMETRICS_PUSH_TOKEN` - (Optional) Bearer token for VictoriaMetrics authentication

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

## Observability

When `VMETRICS_PUSH_URL` and `VMETRICS_PUSH_TOKEN` secrets are configured, the workflow pushes review metrics to VictoriaMetrics in Prometheus text exposition format. Metrics push is best-effort and never fails the workflow.

### Metrics

All metrics include a `repository` label. Several also carry a second dimension label (`phase`, `type`, `severity`, or `verdict`) as shown below.

**Cost & Performance:**
- `gh_code_reviewer_cost_usd` - Claude API cost per review
- `gh_code_reviewer_duration_seconds{phase="total|claude|api"}` - Wall-clock, Claude, and API durations
- `gh_code_reviewer_turns` - Number of Claude conversation turns
- `gh_code_reviewer_tokens{type="input|output|cache_read|cache_creation"}` - Token breakdown

**Review Quality:**
- `gh_code_reviewer_findings{severity="blocker|major|minor",posted="true|false"}` - Finding counts by severity and posting status
- `gh_code_reviewer_verdict_info{verdict="..."}` - Review verdict (info metric, always 1)

**PR Scope:**
- `gh_code_reviewer_files_in_diff` - Number of files in the PR diff
- `gh_code_reviewer_lines_changed{depth="..."}` - Lines changed per file-depth group

**Posting:**
- `gh_code_reviewer_errors` - Number of errors during the review
- `gh_code_reviewer_exit_code` - Claude process exit code

### Enabling Metrics

Add the secrets to your organization or repository, then pass them to the workflow:

```yaml
jobs:
  review:
    uses: ozone-project/action-workflows/.github/workflows/code-review.yml@master
    secrets:
      CODE_REVIEW_ANTHROPIC_API_KEY: ${{ secrets.CODE_REVIEW_ANTHROPIC_API_KEY }}
      CODE_REVIEW_APP_ID: ${{ secrets.CODE_REVIEW_APP_ID }}
      CODE_REVIEW_APP_PRIVATE_KEY: ${{ secrets.CODE_REVIEW_APP_PRIVATE_KEY }}
      VMETRICS_PUSH_URL: ${{ secrets.VMETRICS_PUSH_URL }}
      VMETRICS_PUSH_TOKEN: ${{ secrets.VMETRICS_PUSH_TOKEN }}
```

Without the secrets, the metrics step is skipped and the workflow behaves identically to before.

### Artifacts

The workflow uploads `claude-output.json` alongside `code-review-report.json` as a 7-day retention artifact. This contains Claude's full output envelope (cost, tokens, duration) and can be used for per-PR debugging.

### Example Queries

```promql
# Average review cost over 7 days
avg_over_time(gh_code_reviewer_cost_usd{repository="ozone-project/foo"}[7d])

# Review duration trend
gh_code_reviewer_duration_seconds{repository="ozone-project/foo",phase="total"}

# Finding rate by severity
sum by (severity) (gh_code_reviewer_findings{repository="ozone-project/foo"})
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
