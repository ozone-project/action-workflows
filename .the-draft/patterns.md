# Patterns — action-workflows

Solved problems mined from PRs and incidents.

---

## GitHub App Token Requires `owner` Scope for Cross-Repo Access

**Problem:** `actions/create-github-app-token@v1` without `owner` scope generates a token scoped to the current repo only. This caused "repository not found" errors when the code review workflow tried to clone `ozone-project/synapse`.
**Solution:** Always pass `owner: ${{ github.repository_owner }}` to `create-github-app-token`. This generates an installation token with org-wide read access.
**Where:** `.github/workflows/code-review.yml`, `.github/workflows/code-review-label.yml`
**Reuse:** Any workflow that needs to access other repos in the same org via a GitHub App token must include the `owner` parameter.

---

## Replace Static PATs with GitHub App Tokens

**Problem:** `CODE_REVIEW_GH_TOKEN` was a long-lived PAT tied to a service account. PATs expire, are linked to individuals, and cannot be scoped to specific permissions.
**Solution:** Switched to GitHub App installation tokens (`CODE_REVIEW_APP_ID` + `CODE_REVIEW_APP_PRIVATE_KEY`). Tokens are generated per-run, are short-lived, and carry only the permissions granted to the App.
**Where:** `.github/workflows/code-review.yml`, `.github/workflows/code-review-label.yml` (PR #7, AR-1012)
**Reuse:** Any new workflow that needs cross-repo GitHub access should use `create-github-app-token@v1` with App credentials, not a PAT.

---

## Label-Based Review as a Cost-Control Gate

**Problem:** Running AI code review on every PR is expensive. Some repos want opt-in control.
**Solution:** `code-review-label.yml` wraps `code-review.yml` behind a label check (`ai-code-review` by default). Review only fires when the label is present, then the label is removed after a successful run to prevent re-triggering.
**Where:** `.github/workflows/code-review-label.yml` (PR #1)
**Reuse:** Use `code-review-label.yml` in repos where on-demand review is preferred over always-on. Use `code-review.yml` directly for always-on review.

---

## Org-Level Secret Revert: Avoid org-wide Secrets for Workflow-Specific Keys

**Problem:** PR #2 moved `CODE_REVIEW_ANTHROPIC_API_KEY` to org-level, but PR #3 reverted it — org-level secrets expose the API key to all repos, which is a security risk for a billing-sensitive key.
**Solution:** Keep `CODE_REVIEW_ANTHROPIC_API_KEY` as a repo-level (or selective org) secret. Pass it explicitly in each workflow call rather than relying on inherited org context.
**Where:** `.github/workflows/code-review.yml` secrets block (PR #3)
**Reuse:** Be cautious promoting billing-sensitive API keys to org level. Prefer explicit `secrets:` pass-through so callers declare what they consume.

---

## Structured JSON Debug Report for CI Code Review

**Problem:** When code review failed silently in CI (`-p` mode), there was no artefact to diagnose why — no finding details, no posting diagnostics.
**Solution:** The review prompt includes a schema for `code-review-report.json` that Claude must write regardless of success/failure. The file is uploaded as a GitHub Actions artifact with 7-day retention.
**Where:** `.github/workflows/code-review.yml` — the `REPORT_TEMPLATE` block (PR #6, improved in later PRs)
**Reuse:** Any AI-driven CI step that might fail silently should produce a structured JSON report uploaded as an artifact.

---

## Configurable Java Version for Gradle Workflows

**Problem:** Gradle workflows hardcoded Java 18, blocking repos that need Java 21 or newer.
**Solution:** Added `java_version` input (default `'18'`) to both `gradle-test.yml` and `gradle-publish.yml`. Callers pass their target version.
**Where:** `.github/workflows/gradle-test.yml`, `.github/workflows/gradle-publish.yml` (PR #5)
**Reuse:** Any workflow that sets up a runtime (Java, Node, Python) should accept a version input with a sensible default rather than hardcoding.
