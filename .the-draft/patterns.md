# Patterns — action-workflows

Solved problems mined from PRs.

---

## GitHub App token requires owner scope for cross-repo access

**Problem:** Short-lived GitHub App installation tokens are scoped to the current repo by default. When the code-review workflow clones `ozone-project/synapse`, it got "repository not found" even with a valid token.

**Solution:** Pass `owner: ${{ github.repository_owner }}` to `actions/create-github-app-token@v1`. This grants an installation token with access to all repos in the org the app is installed on.

**Where:** `.github/workflows/code-review.yml`, step `Generate GitHub App token`.

**Reuse:** Any workflow that needs to clone a different repo in the same org using a GitHub App token — always set `owner:`.

---

## PAT → GitHub App migration for CI tokens

**Problem:** Static user-linked Personal Access Tokens for CI are fragile — they expire, get revoked when the user leaves, and don't support fine-grained permissions.

**Solution:** Replace PATs with GitHub App installation tokens using `actions/create-github-app-token@v1`. Secrets needed: `CODE_REVIEW_APP_ID` and `CODE_REVIEW_APP_PRIVATE_KEY`. Token is generated fresh at runtime per workflow run.

**Where:** Both `code-review.yml` and `code-review-label.yml`.

**Reuse:** Any org-wide CI workflow that previously used a PAT should be migrated to a GitHub App token. The pattern is now established and the App exists in the org.

---

## Java version configurable, not hardcoded

**Problem:** Gradle workflows hardcoded JDK 18 with a manual wget-based download, making Java version upgrades require PRs to this central repo.

**Solution:** Added `java_version` input (string, default `'18'`) and switched to `actions/setup-java@v4` with `temurin` distribution. Consumer repos can now pass `java_version: '21'` or `'25'` to migrate incrementally without touching this repo.

**Where:** `gradle-test.yml`, `gradle-publish.yml`.

**Reuse:** Any shared workflow with a version-pinned runtime (Node, Python, Java) should expose it as an input with a sensible default.

---

## Organization-level secrets: revert required before org rollout

**Problem:** PR #2 moved `CODE_REVIEW_ANTHROPIC_API_KEY` to an org-level secret. PR #3 reverted it. The org-level secret wasn't available to all repos at time of merge.

**Solution:** Revert to per-repo (or passed-through) secrets until the org-level secret is confirmed available in all consumer repos.

**Where:** `code-review.yml` secrets block.

**Reuse:** When promoting a secret to org level, verify availability in all consuming repos before merging. Otherwise revert and coordinate rollout.

---

## `claude -p --dangerously-skip-permissions` in CI

**Problem:** Claude Code's interactive permission prompts break non-interactive CI environments.

**Solution:** Use `claude -p --dangerously-skip-permissions` with an explicit "Do not use AskUserQuestion" instruction in the prompt. The prompt also tells Claude not to post test/probe reviews and not to work around `post-review.py` failures by calling `gh api` directly.

**Where:** `code-review.yml`, "Run code review" step.

**Reuse:** Any CI invocation of Claude Code should use `-p --dangerously-skip-permissions` and include explicit instructions about interactive tools being unavailable.

---

## Docker image idempotency check before build

**Problem:** Re-running a workflow for the same commit would rebuild and push a Docker image that already exists, wasting time and potentially overwriting a good image.

**Solution:** `docker manifest inspect $ECR_REGISTRY/$ECR_REPOSITORY:$GIT_BRANCH_SLUG-$GITHUB_SHA` before building. If the tag exists, log and exit 0.

**Where:** `docker-build.yml`.

**Reuse:** Any Docker build workflow — always check for existing image tag before building.

---

## Branch slug normalization for Docker tags

**Problem:** Git branch names can contain uppercase, slashes, and special characters that are invalid in Docker image tags.

**Solution:** `tr "[:upper:]" "[:lower:]" | tr -c '[:alnum:]' '-' | sed 's/^-*//' | cut -c1-25 | sed 's/-*$//'` — lowercase, replace non-alphanumeric with `-`, trim leading/trailing dashes, cap at 25 chars.

**Where:** `docker-build.yml`, `GIT_BRANCH_SLUG` env var.

**Reuse:** Copy this pipeline verbatim whenever a branch name needs to become a valid Docker tag.
