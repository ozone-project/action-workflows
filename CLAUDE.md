# action-workflows

Shared GitHub Actions reusable workflows for `ozone-project`. Called via `workflow_call` from consumer repos.

@docs/architecture.md
@docs/deployment.md

## What's here

Seven reusable workflows live in `.github/workflows/`:

- `code-review.yml` — Claude Code automated PR review (synapse core plugin)
- `code-review-label.yml` — same review, triggered by a PR label instead of push
- `docker-build.yml` — Docker build + push to AWS ECR
- `docker-lint.yml` — Dockerfile linting via hadolint
- `gradle-publish.yml` — Gradle build + publish to AWS CodeArtifact
- `gradle-test.yml` — Gradle test run with JUnit XML report upload
- `qlty-tool.yml` — Qlty format checks and function metrics

## Key gotchas

<secrets_auth>
The code-review workflows use a GitHub App (not a PAT). Required secrets are `CODE_REVIEW_APP_ID` and `CODE_REVIEW_APP_PRIVATE_KEY` (plus `CODE_REVIEW_ANTHROPIC_API_KEY`). The owner scope must be set on the app token to allow cross-repo clone of `ozone-project/synapse`.
</secrets_auth>

<gradle_java_version>
Java version is configurable via `java_version` input (default `'18'`). Pass `java_version: '21'` or `'25'` to migrate incrementally. The string type is intentional — GitHub Actions coerces it.
</gradle_java_version>

<qlty_upstream>
The qlty workflow uses `origin/master` as upstream hardcoded. If a consumer repo uses `main`, the check will fail silently. Use `github.event.repository.default_branch` instead.
</qlty_upstream>
