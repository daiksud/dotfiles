# Copilot Personal Instructions

## Pull Request skills

If the user runs `/pr create` or asks to create a Pull Request, always use the `pr-create` skill.
If the user runs `/pr fix` or asks to fix, improve, or make a Pull Request mergeable, always use the `pr-fix` skill.
If the user runs `/pr merge` or asks to merge a Pull Request once review is clean, always use the `pr-merge` skill.

Invoke the matching skill directly from the checkout where the request was made. Do not create or select a worktree first: each skill owns its `gh-qwt` workflow, and `pr-create` must inspect and migrate the invoking checkout's dirty state.

## Worktree usage

For every other repository task, perform all work inside a `gh-qwt` worktree.

1. Resolve `<owner>/<repo>` and the intended `<branch>`, then calculate the target with `gh qwt path <owner>/<repo>/<branch>`.
2. Confirm that the target is a registered worktree, for example by matching it against `gh qwt list <owner>/<repo>/<branch> --exact --full-path`; `gh qwt path` also prints paths for missing targets. If the worktree exists, reuse it without running `get` or `add`.
3. If the target is missing, provision it with an explicit repository. When the qwt repository is missing, use `gh qwt get <owner>/<repo>` for its default branch or `gh qwt get <owner>/<repo> --branch <branch>` for an existing remote branch. For a new branch, initialize a missing repository with `get`, then use `gh qwt add --repo <owner>/<repo> <branch> --from origin/<default-branch>`. When the repository already exists, refresh `origin --prune` before `gh qwt add --repo <owner>/<repo> <branch>`, adding `--from` only for a new branch.
4. Resolve the target path again, verify its branch, and run every repository command from that worktree.

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
