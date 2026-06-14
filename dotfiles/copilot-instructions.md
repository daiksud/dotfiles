# Copilot Personal Instructions

## Pull Request skills

If the user runs `/pr create` or asks to create a Pull Request, always use the `pr-create` skill.
If the user runs `/pr fix` or asks to fix, improve, or make a Pull Request mergeable, always use the `pr-fix` skill.

## Comments on Issues / Pull Requests

When posting a comment or reply on an Issue or Pull Request at the user's instruction, always prefix it with `:robot:`.

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
