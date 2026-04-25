# Deployment — action-workflows

## Adding a Workflow to a Repo

All workflows use `workflow_call`. Call them from a `.github/workflows/` file in the consuming repo:

### Code Review (on every PR)

```yaml
# .github/workflows/code-review.yml
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
      min_severity: minor   # minor | major | blocker
    secrets:
      CODE_REVIEW_ANTHROPIC_API_KEY: ${{ secrets.CODE_REVIEW_ANTHROPIC_API_KEY }}
      CODE_REVIEW_APP_ID: ${{ secrets.CODE_REVIEW_APP_ID }}
      CODE_REVIEW_APP_PRIVATE_KEY: ${{ secrets.CODE_REVIEW_APP_PRIVATE_KEY }}
```

### Label-Triggered Code Review

```yaml
# .github/workflows/code-review-label.yml
name: Label-Triggered Code Review
on:
  pull_request:
    types: [labeled]
jobs:
  review:
    uses: ozone-project/action-workflows/.github/workflows/code-review-label.yml@master
    with:
      label_name: ai-code-review
      remove_label_after_review: true
    secrets:
      CODE_REVIEW_ANTHROPIC_API_KEY: ${{ secrets.CODE_REVIEW_ANTHROPIC_API_KEY }}
      CODE_REVIEW_APP_ID: ${{ secrets.CODE_REVIEW_APP_ID }}
      CODE_REVIEW_APP_PRIVATE_KEY: ${{ secrets.CODE_REVIEW_APP_PRIVATE_KEY }}
```

### Docker Build

```yaml
# .github/workflows/docker-build.yml
name: Docker Build
on: [push]
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
      java_version: '21'
    secrets:
      AWS_ACCESS_KEY: ${{ secrets.AWS_ACCESS_KEY }}
      # ... other AWS secrets
  publish:
    needs: test
    uses: ozone-project/action-workflows/.github/workflows/gradle-publish.yml@master
    with:
      java_version: '21'
    secrets:
      AWS_ACCESS_KEY: ${{ secrets.AWS_ACCESS_KEY }}
      # ... other AWS secrets
```

## Required Org Secrets

Ensure these exist at org level before using workflows:

| Secret | Required by |
|--------|------------|
| `CODE_REVIEW_ANTHROPIC_API_KEY` | code-review* |
| `CODE_REVIEW_APP_ID` | code-review* |
| `CODE_REVIEW_APP_PRIVATE_KEY` | code-review* |
| `AWS_ACCESS_KEY` | docker-build, gradle-* |
| `AWS_SECRET_KEY` | docker-build, gradle-* |
| `AWS_REGION` | docker-build, gradle-* |
| `AWS_CODEARTIFACT_DOMAIN` | docker-build, gradle-* |
| `AWS_ACCOUNT_ID` | docker-build, gradle-* |

## Updating a Workflow

1. Branch from `master`, edit the workflow YAML
2. Test by calling the workflow from a test repo at your branch: `uses: ozone-project/action-workflows/.github/workflows/code-review.yml@your-branch`
3. Open a PR — the PR bot will auto-review via the code-review workflow
4. Merge to `master` — all consuming repos pick up the change immediately (they pin `@master`)

## Pinning a Version

To avoid unexpected changes, pin to a commit SHA instead of `@master`:

```yaml
uses: ozone-project/action-workflows/.github/workflows/code-review.yml@abc1234
```

## Debugging Code Review

1. Check the "Run code review" step in GitHub Actions logs
2. Download `code-review-report` artifact for the structured JSON debug report
3. Common failures:
   - `CODE_REVIEW_APP_ID` / `CODE_REVIEW_APP_PRIVATE_KEY` missing or wrong → token generation fails
   - `CODE_REVIEW_ANTHROPIC_API_KEY` invalid → Claude API call fails
   - GitHub App missing `owner` scope → cannot clone `ozone-project/synapse`

See `docs/CODE_REVIEW_WORKFLOW.md` for full troubleshooting guide.
