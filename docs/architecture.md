# Architecture — action-workflows

## Purpose

Central library of reusable GitHub Actions workflows for `ozone-project`. Consumer repos call these via `workflow_call` to avoid duplicating CI/CD logic.

## Workflow Inventory

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `code-review.yml` | `workflow_call` | Claude Code PR review — posts inline comments via synapse `check-pr` skill |
| `code-review-label.yml` | `workflow_call` | Same review, gated behind a PR label (`ai-code-review` by default) |
| `docker-build.yml` | `workflow_call` | Builds Docker image + pushes to AWS ECR; skips build if image tag already exists |
| `docker-lint.yml` | `workflow_call` | Lints `Dockerfile` via hadolint v2.10.0 |
| `gradle-publish.yml` | `workflow_call` | Builds and publishes a Gradle project to AWS CodeArtifact |
| `gradle-test.yml` | `workflow_call` | Runs Gradle tests; publishes JUnit XML results via `dorny/test-reporter` |
| `qlty-tool.yml` | `workflow_call` | Runs Qlty formatter checks and function metrics against upstream |

## Code Review Pipeline

```
Consumer repo PR opened
        │
        ▼
code-review-label.yml (optional label gate)
        │
        ▼
code-review.yml
  ├── Generate GitHub App token (create-github-app-token@v1)
  ├── Checkout repo (fetch-depth: 0 for full diff context)
  ├── Install Claude Code SDK (Node.js 22)
  ├── Clone ozone-project/synapse (core plugin)
  ├── Setup python3 shim at ~/.synapse/.venv/bin/python3
  └── Run /check-pr via `claude -p --dangerously-skip-permissions`
             │
             ▼
      check-pr skill → code-reviewer agent
             │
             ▼
      post-review.py → GitHub PR review API (inline comments)
```

## Authentication Model

The code-review workflows use a GitHub App instead of a PAT. This provides:
- Short-lived tokens (no rotation risk)
- Fine-grained permissions (contents: read, pull-requests: write)
- Cross-repo access (owner scope) required for cloning `ozone-project/synapse`

Required secrets: `CODE_REVIEW_APP_ID`, `CODE_REVIEW_APP_PRIVATE_KEY`, `CODE_REVIEW_ANTHROPIC_API_KEY`.

## AWS/Gradle Workflows

Docker and Gradle workflows require AWS credentials (`AWS_ACCESS_KEY`, `AWS_SECRET_KEY`, `AWS_REGION`, `AWS_CODEARTIFACT_DOMAIN`, `AWS_ACCOUNT_ID`). These are passed through `secrets:` from the calling workflow. ECR registry name is passed as `AWS_ECR_REGISTRY`.

## Dependencies

| Dependency | Version | Used by |
|-----------|---------|---------|
| `actions/checkout` | v4 | All |
| `actions/setup-node` | v4 | code-review |
| `actions/setup-java` | v4 | gradle-* |
| `actions/cache` | v4 | gradle-* |
| `aws-actions/configure-aws-credentials` | v1 | docker-build, gradle-* |
| `aws-actions/amazon-ecr-login` | v1 | docker-build |
| `actions/create-github-app-token` | v1 | code-review* |
| `dorny/test-reporter` | v1 | gradle-test |
| `actions/upload-artifact` | v4 | gradle-test, code-review |
| `@anthropic-ai/claude-code` | latest | code-review |
| `hadolint` | v2.10.0 | docker-lint |
| `qlty` | latest | qlty-tool |
