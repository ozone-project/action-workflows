# Architecture — action-workflows

## Overview

`action-workflows` is a centralised library of reusable GitHub Actions workflows (all `workflow_call` trigger) for the Ozone project. Repos call these workflows instead of maintaining their own copies.

## Workflow Groups

### Code Review (AI-powered)
- **`code-review.yml`** — Core workflow. Runs on every PR. Checks out repo, installs Claude Code SDK, clones `ozone-project/synapse`, runs `/check-pr` via `claude -p`. Posts inline review comments via `post-review.py`. Supports `ignore_patterns` and `min_severity` inputs.
- **`code-review-label.yml`** — Wrapper around `code-review.yml`. Checks for a label (default: `ai-code-review`) before triggering review, then removes the label after success.

### Container Builds
- **`docker-build.yml`** — Authenticates to AWS CodeArtifact, builds Docker image, pushes to AWS ECR. Image tag: `{branch-slug}-{sha}`. Skips build if image already exists.
- **`docker-lint.yml`** — Downloads hadolint binary and lints `Dockerfile`.

### JVM / Gradle
- **`gradle-publish.yml`** — Authenticates to CodeArtifact, runs `./gradlew publish`. Configurable Java version (default: 18).
- **`gradle-test.yml`** — Runs `./gradlew build`, uploads JUnit XML results, renders them via `dorny/test-reporter`.

### Code Quality
- **`qlty-tool.yml`** — Installs and runs Qlty CLI: formatting checks and function-level metrics against upstream master.

## Key Dependencies

| Dependency | Used by | Notes |
|------------|---------|-------|
| `actions/checkout@v4` | All | Standard repo checkout |
| `actions/create-github-app-token@v1` | code-review* | Short-lived GitHub App tokens |
| `actions/setup-node@v4` | code-review* | Node 22 for Claude Code SDK |
| `actions/setup-java@v4` | gradle-* | Temurin JDK |
| `aws-actions/configure-aws-credentials@v1` | docker-build, gradle-* | AWS auth |
| `aws-actions/amazon-ecr-login@v1` | docker-build | ECR login |
| `dorny/test-reporter@v1` | gradle-test | JUnit rendering |
| Claude Code SDK (npm) | code-review* | `claude -p` CLI |
| `ozone-project/synapse` | code-review* | Plugins/core for check-pr skill |

## Code Review Data Flow

```
PR opened
  → code-review.yml triggered
  → GitHub App token generated (owner-scoped)
  → Claude Code installed, synapse cloned
  → /check-pr {PR_NUMBER} against {BASE_BRANCH} runs
  → check-pr skill invokes code-reviewer agent
  → post-review.py posts inline comments to GitHub API
  → code-review-report.json uploaded as artifact
```

## Secrets Architecture

All secrets are org-level. No repo-level secrets required.

- `CODE_REVIEW_APP_ID` + `CODE_REVIEW_APP_PRIVATE_KEY` — GitHub App for cross-repo access (replaces PAT `CODE_REVIEW_GH_TOKEN` as of AR-1012)
- `CODE_REVIEW_ANTHROPIC_API_KEY` — Claude API key for code review
- AWS credential set (`AWS_ACCESS_KEY`, `AWS_SECRET_KEY`, `AWS_REGION`, `AWS_CODEARTIFACT_DOMAIN`, `AWS_ACCOUNT_ID`) — for ECR and CodeArtifact
