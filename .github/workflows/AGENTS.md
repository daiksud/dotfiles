# GitHub Actions Instructions

Follow these rules when authoring or maintaining GitHub Actions workflows.

## Version pinning policy

| Reference type | Pinning method |
| --- | --- |
| Remote repository action or reusable workflow | `@SHA # vX.Y.Z` (full-length commit SHA followed by the release version) |
| Local action or reusable workflow (`./...`) | Keep the local path; a ref pin is not applicable |
| Docker action (`docker://...`) | Pin the image by digest, such as `docker://image@sha256:<digest>` |

```yaml
# ✅ Good — Remote repository action
- uses: owner/action@0123456789abcdef0123456789abcdef01234567 # v1.2.3
# ❌ Bad — Mutable remote tag
- uses: owner/action@v1
```

```yaml
# ✅ Good — Remote reusable workflow
jobs:
  call-reusable:
    uses: owner/repository/.github/workflows/reusable.yml@0123456789abcdef0123456789abcdef01234567 # v1.2.3
```

```yaml
# ✅ Good — Local action
steps:
  - uses: ./.github/actions/example
```

```yaml
# ✅ Good — Local reusable workflow
jobs:
  call-reusable:
    uses: ./.github/workflows/reusable.yml
```

```yaml
# ✅ Good — Docker action
- uses: docker://example/action@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
# ❌ Bad — Mutable Docker tag
- uses: docker://example/action:latest
```
