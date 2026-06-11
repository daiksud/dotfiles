# Copilot Personal Instructions

## Pull Request 用スキル

ユーザーが `/pr create` を実行するか、Pull Request の作成を依頼した場合は、必ず `pr-create` スキルを使う。
ユーザーが `/pr fix` を実行するか、Pull Request を修正・改善・マージ可能な状態にするよう依頼した場合は、必ず `pr-fix` スキルを使う。

## Issue / Pull Request へのコメント

ユーザーの指示で Issue や Pull Request へコメントやリプライをする場合は、先頭に必ず `:robot:` を付ける。

<!-- rtk-instructions v2 -->
# RTK — Token-Optimized CLI

**rtk** is a CLI proxy that filters and compresses command outputs, saving 60-90% tokens.

## Rule

Always prefix shell commands with `rtk`:

```bash
# Instead of:              Use:
git status                 rtk git status
git log -10                rtk git log -10
cargo test                 rtk cargo test
docker ps                  rtk docker ps
kubectl get pods           rtk kubectl pods
```

## Meta commands (use directly)

```bash
rtk gain              # Token savings dashboard
rtk gain --history    # Per-command savings history
rtk discover          # Find missed rtk opportunities
rtk proxy <cmd>       # Run raw (no filtering) but track usage
```
<!-- /rtk-instructions -->