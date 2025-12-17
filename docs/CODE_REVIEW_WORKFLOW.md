# Code Review Workflow Documentation

## Overview

This GitHub Actions workflow provides automated code review for pull requests using Claude Code. The workflow analyzes code changes, provides feedback, and posts review comments directly on PRs.

## How It Works

1. **Clones ozone-ai repository** - Fetches the latest Claude Code agent and command files
2. **Finds required files** - Uses `find` command to locate files regardless of directory structure
3. **Copies files** - Places them in `.claude/agents/` and `.claude/commands/`
4. **Runs code review** - Executes the review-branch command
5. **Posts comment** - Adds review as a sticky PR comment

## Workflow Features

- **Dynamic file discovery**: Uses `find` command to locate files in any directory structure
- **Branch comparison**: Reviews changes against the base branch (or main)
- **Ignore patterns**: Supports excluding files from review
- **PR comments**: Automatically posts review as a sticky PR comment
- **Error handling**: Clear error messages if something goes wrong

## Setup Instructions

### 1. Configure Secrets

The workflow requires these GitHub secrets:
- `CODE_REVIEW_ANTHROPIC_API_KEY` - Your Anthropic API key for Claude
- `CODE_REVIEW_GH_TOKEN` - GitHub token with PR write permissions

Add these at the organization or repository level.

### 2. Use the Workflow

The workflow is designed to be called from other workflows:

```yaml
name: PR Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    uses: ozone-project/action-workflows/.github/workflows/code-review.yml@main
    with:
      ignore_patterns: |
        *.generated.ts
        dist/**
        *.min.js
    secrets:
      CODE_REVIEW_ANTHROPIC_API_KEY: ${{ secrets.CODE_REVIEW_ANTHROPIC_API_KEY }}
      CODE_REVIEW_GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Workflow Steps

### `code-review` job
1. Checks out the repository code
2. Installs Claude Code SDK
3. Clones ozone-ai repository to get latest agent/command files
4. Uses `find` to locate required files (resilient to directory changes)
5. Copies files to `.claude/` directories
6. Runs the review command
7. Posts results as PR comment

## Troubleshooting

### File Not Found Error

```
ERROR: Could not find code-reviewer.md in ozone-ai repository
```

**Possible causes**:
1. ozone-ai repository structure changed
2. Files were renamed or moved
3. Network/permission issues cloning the repo

**Solution**: Check the ozone-ai repository for the current location of these files.

### Review Not Generated

```
ERROR: Code review failed - review.md was not generated
```

**Possible causes**:
1. Invalid API key - Check `CODE_REVIEW_ANTHROPIC_API_KEY` secret
2. Claude Code SDK installation failed - Check workflow logs
3. Command execution error - Check the Run Claude Code Review step logs

## File Structure

During workflow execution:

```
action-workflows/                     # Your repository
├── .github/
│   └── workflows/
│       └── code-review.yml          # Main workflow file
├── ozone-ai-temp/                   # Temporarily cloned (during CI)
│   └── claude-code/
│       └── marketplace-plugins/
│           └── core/
│               ├── agents/
│               │   └── code-reviewer.md
│               └── commands/
│                   └── review-branch.md
└── .claude/                         # Created by workflow
    ├── agents/
    │   └── code-reviewer.md         # Copied from ozone-ai-temp
    ├── commands/
    │   └── review-branch.md         # Copied from ozone-ai-temp
    └── tmp/
        └── review.md                # Generated review output
```

## Testing the Workflow

1. Make code changes in a feature branch
2. Commit and push changes
3. Create a pull request
4. Verify the workflow:
   - Successfully clones ozone-ai
   - Finds and copies required files
   - Generates a review
   - Posts comment on the PR

## Advanced Configuration

### Ignore Patterns

Pass file patterns to exclude from review:

```yaml
with:
  ignore_patterns: |
    *.generated.ts
    node_modules/**
    dist/**
    *.min.js
    vendor/**
```

### Custom Base Branch

The workflow automatically detects the base branch from the PR context. For non-PR triggers, it defaults to `main`.

## Maintenance

### Updating Claude Code Files

The workflow always fetches the latest files from the ozone-ai repository's main branch. If the files are updated there, the workflow will automatically use the new versions.

### Monitoring

Check workflow runs at: Actions tab > Code Review workflow

Common metrics to monitor:
- Success rate
- Run duration
- Error patterns
- API usage

## Support

For issues:
1. Check workflow logs in GitHub Actions
2. Verify the "Setup Claude Code agents and commands" step finds the files
3. Verify secrets are configured correctly
4. Check that ozone-ai repository is accessible

## Version History

- **v2.0** - Fixed broken paths using dynamic `find` command, improved error handling
- **v1.0** - Initial implementation with hard-coded paths