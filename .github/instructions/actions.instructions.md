---
description: Guidelines for authoring and maintaining GitHub Actions workflows
applyTo: ".github/workflows/**"
---

# GitHub Actions Instructions

## Version Pinning Policy

| Category | Pinning method |
| --- | --- |
| All actions | `@SHA # vX.Y.Z` (full-length commit SHA followed by the release version) |

```yaml
# ✅ Good — Full-length SHA pin
- uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
- uses: jdx/mise-action@e6a8b3978addb5a52f2b4cd9d91eafa7f0ab959d # v4.2.0

# ❌ Bad — Mutable major-version tag
- uses: actions/checkout@v7
- uses: jdx/mise-action@v4
```
