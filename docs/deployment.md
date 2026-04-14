# Deployment — action-workflows

## How to Use a Shared Workflow

Reference workflows from this repo using `uses: ozone-project/action-workflows/.github/workflows/{name}.yml@master`.

### Code Review (every PR)

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
    secrets:
      CODE_REVIEW_ANTHROPIC_API_KEY: ${{ secrets.CODE_REVIEW_ANTHROPIC_API_KEY }}
      CODE_REVIEW_APP_ID: ${{ secrets.CODE_REVIEW_APP_ID }}
      CODE_REVIEW_APP_PRIVATE_KEY: ${{ secrets.CODE_REVIEW_APP_PRIVATE_KEY }}
```

### Code Review (label-gated)

```yaml
name: Label-Gated Code Review

on:
  pull_request:
    types: [labeled]

jobs:
  review:
    uses: ozone-project/action-workflows/.github/workflows/code-review-label.yml@master
    with:
      label_name: ai-code-review          # default — omit to use this
      remove_label_after_review: true     # default
    secrets:
      CODE_REVIEW_ANTHROPIC_API_KEY: ${{ secrets.CODE_REVIEW_ANTHROPIC_API_KEY }}
      CODE_REVIEW_APP_ID: ${{ secrets.CODE_REVIEW_APP_ID }}
      CODE_REVIEW_APP_PRIVATE_KEY: ${{ secrets.CODE_REVIEW_APP_PRIVATE_KEY }}
```

### Docker Build

```yaml
jobs:
  build:
    uses: ozone-project/action-workflows/.github/workflows/docker-build.yml@master
    secrets:
      AWS_ACCESS_KEY: ${{ secrets.AWS_ACCESS_KEY }}
      AWS_SECRET_KEY: ${{ secrets.AWS_SECRET_KEY }}
      AWS_REGION: ${{ secrets.AWS_REGION }}
      AWS_CODEARTIFACT_DOMAIN: ${{ secrets.AWS_CODEARTIFACT_DOMAIN }}
      AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}
      AWS_ECR_REGISTRY: ${{ secrets.AWS_ECR_REGISTRY }}
```

### Gradle Test + Publish

```yaml
jobs:
  test:
    uses: ozone-project/action-workflows/.github/workflows/gradle-test.yml@master
    with:
      java_version: '21'    # optional, default '18'
    secrets:
      AWS_ACCESS_KEY: ${{ secrets.AWS_ACCESS_KEY }}
      AWS_SECRET_KEY: ${{ secrets.AWS_SECRET_KEY }}
      AWS_REGION: ${{ secrets.AWS_REGION }}
      AWS_CODEARTIFACT_DOMAIN: ${{ secrets.AWS_CODEARTIFACT_DOMAIN }}
      AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}

  publish:
    needs: test
    uses: ozone-project/action-workflows/.github/workflows/gradle-publish.yml@master
    with:
      java_version: '21'
    secrets:
      AWS_ACCESS_KEY: ${{ secrets.AWS_ACCESS_KEY }}
      # ... same as above
```

### Qlty

```yaml
jobs:
  quality:
    uses: ozone-project/action-workflows/.github/workflows/qlty-tool.yml@master
```

> **Note:** The qlty workflow hardcodes `origin/master` as upstream. If your repo uses `main`, override locally rather than calling this shared workflow.

## Required Secrets Setup

### Code Review Secrets

Set at org level (or repo level as fallback):

| Secret | Description |
|--------|-------------|
| `CODE_REVIEW_ANTHROPIC_API_KEY` | Anthropic API key for Claude Code |
| `CODE_REVIEW_APP_ID` | GitHub App ID (numeric) |
| `CODE_REVIEW_APP_PRIVATE_KEY` | GitHub App private key (PEM) |

The GitHub App must have:
- `contents: read`
- `pull-requests: write`  
- `issues: write`
- Access to `ozone-project/synapse` (for cloning the core plugin)
- **Owner scope** on the installation token (required for cross-repo access)

### AWS Secrets

Set at org or repo level:

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY` | IAM access key |
| `AWS_SECRET_KEY` | IAM secret key |
| `AWS_REGION` | AWS region (e.g. `eu-west-1`) |
| `AWS_CODEARTIFACT_DOMAIN` | CodeArtifact domain name |
| `AWS_ACCOUNT_ID` | AWS account ID |
| `AWS_ECR_REGISTRY` | ECR repository name |

## Version Pinning

All workflow references use `@master`. To pin to a specific commit for stability:

```yaml
uses: ozone-project/action-workflows/.github/workflows/code-review.yml@abc1234
```

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| "repository not found" when cloning synapse | GitHub App token missing owner scope | Ensure `owner: ${{ github.repository_owner }}` is set in `create-github-app-token` |
| Review not posted | Missing/invalid `CODE_REVIEW_ANTHROPIC_API_KEY` | Check GitHub Actions logs for Claude Code API errors |
| Axon MCP warnings in logs | Expected in CI — OAuth credentials not available | Ignore; review still completes |
| Gradle build fails | Wrong Java version or missing CodeArtifact auth | Check `java_version` input; verify AWS credentials |
| Qlty upstream mismatch | Hardcoded `origin/master` vs `main` | Use local qlty config instead of this shared workflow |
