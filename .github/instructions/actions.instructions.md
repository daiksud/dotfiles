---
description: Guidelines for authoring and maintaining GitHub Actions workflows
applyTo: ".github/workflows/**"
---

# GitHub Actions Instructions

## Version Pinning Policy

| Category | Pinning method |
| --- | --- |
| GitHub-owned | `@vN` (major version pin) |
| Marketplace Verified Creator | `@vN` (major version pin) |
| All others (not GitHub-owned and not Verified) | `@SHA # vX.Y.Z` (SHA pin) |

```yaml
# ✅ Good — GitHub-owned / Verified provider
- uses: actions/checkout@v7
- uses: slackapi/slack-github-action@v3

# ✅ Good — Non-Verified provider
- uses: jdx/mise-action@e6a8b3978addb5a52f2b4cd9d91eafa7f0ab959d # v4.2.0

# ❌ Bad — SHA pin used for a GitHub-owned / Verified provider
- uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0

# ❌ Bad — Major-version pin used for a non-Verified provider
- uses: jdx/mise-action@v4
```
