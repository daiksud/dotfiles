---
description: Guidelines for authoring and maintaining GitHub Actions workflows
applyTo: ".github/workflows/**"
---

# GitHub Actions Instructions

Follow these rules when authoring or maintaining GitHub Actions workflows.

## Version pinning policy

| Reference type | Pinning method |
| --- | --- |
| Remote repository action or reusable workflow | `@SHA # vX.Y.Z` (full-length commit SHA followed by the release version) |
| Local action or reusable workflow (`./...`) | Keep the local path; a ref pin is not applicable |
| Docker action (`docker://...`) | Pin the image by digest, such as `docker://image@sha256:<digest>` |

```yaml
# Remote repository action or reusable workflow
- uses: owner/action@0123456789abcdef0123456789abcdef01234567 # v1.2.3

# Do not use a mutable tag
- uses: owner/action@v1
```

```yaml
# Local action or reusable workflow
- uses: ./.github/actions/example

# Docker action
- uses: docker://example/action@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```
