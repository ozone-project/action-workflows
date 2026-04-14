# action-workflows

Reusable GitHub Actions workflow library for Ozone project repositories.

## Purpose

Centralised `workflow_call` workflows consumed by all Ozone service repos. Adding a new workflow here makes it available across the org without per-repo duplication.

## Workflows

| File | Purpose |
|------|---------|
| `code-review.yml` | AI code review via Claude Code + synapse `check-pr` skill |
| `code-review-label.yml` | Label-triggered variant of code-review (label: `ai-code-review`) |
| `docker-build.yml` | Build + push image to AWS ECR via CodeArtifact auth |
| `docker-lint.yml` | Lint Dockerfile with hadolint |
| `gradle-publish.yml` | Publish Gradle artifacts to AWS CodeArtifact |
| `gradle-test.yml` | Run Gradle tests, upload JUnit results |
| `qlty-tool.yml` | Qlty formatting checks + function metrics |

## Secrets Convention

- **Code review**: `CODE_REVIEW_APP_ID` + `CODE_REVIEW_APP_PRIVATE_KEY` (GitHub App, not PAT) + `CODE_REVIEW_ANTHROPIC_API_KEY`
- **Docker/Gradle**: AWS credentials (`AWS_ACCESS_KEY`, `AWS_SECRET_KEY`, `AWS_REGION`, `AWS_CODEARTIFACT_DOMAIN`, `AWS_ACCOUNT_ID`)
- All secrets are org-level — do not add repo-level copies

## GitHub App Token Pattern

Code review workflows generate short-lived GitHub App tokens at runtime:
```yaml
- uses: actions/create-github-app-token@v1
  with:
    app-id: ${{ secrets.CODE_REVIEW_APP_ID }}
    private-key: ${{ secrets.CODE_REVIEW_APP_PRIVATE_KEY }}
    owner: ${{ github.repository_owner }}   # owner scope required for cross-repo access
```

The `owner` scope is required — without it the token is scoped to the current repo only and cannot clone `ozone-project/synapse`.

## Calling a Workflow

```yaml
jobs:
  review:
    uses: ozone-project/action-workflows/.github/workflows/code-review.yml@master
    with:
      ignore_patterns: |
        *.generated.ts
        dist/**
    secrets:
      CODE_REVIEW_ANTHROPIC_API_KEY: ${{ secrets.CODE_REVIEW_ANTHROPIC_API_KEY }}
      CODE_REVIEW_APP_ID: ${{ secrets.CODE_REVIEW_APP_ID }}
      CODE_REVIEW_APP_PRIVATE_KEY: ${{ secrets.CODE_REVIEW_APP_PRIVATE_KEY }}
```

## Docs

@docs/architecture.md
@docs/deployment.md
@docs/CODE_REVIEW_WORKFLOW.md
