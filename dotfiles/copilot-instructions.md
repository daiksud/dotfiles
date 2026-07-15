# Copilot Personal Instructions

## Pull Request skills

If the user runs `/pr create` or asks to create a Pull Request, always use the `pr-create` skill.
If the user runs `/pr fix` or asks to fix, improve, or make a Pull Request mergeable, always use the `pr-fix` skill.
If the user runs `/pr merge` or asks to merge a Pull Request once review is clean, always use the `pr-merge` skill.

Invoke the matching skill directly from the checkout where the request was made. Do not create or select a worktree first: each skill owns its `gh-qwt` workflow, and `pr-create` must inspect and migrate the invoking checkout's dirty state.

## Worktree usage

For every other repository task, perform all work inside a `gh-qwt` worktree.

1. Treat the checkout where the request was made as the source. Before changing directories or provisioning a worktree, record its resolved absolute Git worktree root rather than the raw current directory, current branch, `HEAD`, staged and unstaged diffs, non-ignored untracked-file list, and `git status --porcelain=v1 -z`.
2. Resolve `<owner>/<repo>`, its default branch, the source branch and tracking ref, and the intended `<branch>`, then calculate the repository and target paths with `gh qwt path <owner>/<repo>` and `gh qwt path <owner>/<repo>/<branch>`. Treat the qwt repository as existing only when `<repository-path>/.bare` is a directory; `gh qwt path` also prints paths for missing repositories and worktrees.
3. Confirm whether the target is a registered worktree by requiring the output of `gh qwt list <owner>/<repo>/<branch> --exact --full-path` to equal the calculated target path; a successful exit with empty output does not prove that it exists. If it exists, verify that its current branch equals the intended branch and stop on a mismatch, then record its staged, unstaged, untracked, and porcelain status before reuse.
4. Compare the resolved source and target roots before doing any work:
   - If the target is registered and they are the same worktree, continue there without discarding its current state. Treat an unregistered target as absent even if its calculated path matches the source textually.
   - Otherwise, if the source or an existing target has uncommitted changes, do not silently leave the source or mix distinct states. Continue an existing dirty target only when the user explicitly identified its changes as the work to continue. Migrate source changes only when the user explicitly chose that outcome, after completing the committed-history check below, preserving staged, unstaged, and non-ignored untracked state and verifying the target before clearing the source. In all other cases, stop and ask how to proceed; never combine two dirty worktrees automatically.
   - Proceed without migration only when the source is clean and the target is absent or clean.
5. Whenever the source and target are different, fetch the remote that corresponds to the resolved `<owner>/<repo>` and compare committed history even when the source is dirty. Use a configured tracking ref only when it belongs to that repository; otherwise use an existing matching `<remote>/<source-branch>`, or the fetched `<remote>/<default-branch>` as the creation base for an unpublished source branch. Compare that ref with the recorded source `HEAD`, for example with `git rev-list --left-right --count <source-ref>...<source-HEAD>`.
   - Equal commits, or a source that is only behind the ref, have no local-only source history.
   - A source that is ahead or diverged has local-only commits. Continue only when the user explicitly chose how to publish that exact history, deliberately transfer it to the target, or leave it out; otherwise stop and ask. Never keep working in the ordinary source, or push, rebase, reset, or omit those commits automatically.
   - Stop if no trustworthy matching remote/base ref can be established.
6. If the target is missing and the recorded state permits provisioning, use an explicit repository. When the qwt repository is missing, use `gh qwt get <owner>/<repo>` for its default branch or `gh qwt get <owner>/<repo> --branch <branch>` for an existing remote branch. For a new branch, initialize a missing repository with `get`, then use `gh qwt add --repo <owner>/<repo> <branch> --from origin/<default-branch>`. When the repository already exists, refresh `origin --prune` and record whether `refs/heads/<branch>` plus any `branch.<branch>.remote` and merge configuration already exist before running `gh qwt add --repo <owner>/<repo> <branch>`. `add` reattaches an existing local branch before considering the remote and does not replace it with `--from`; add `--from` only when creating a genuinely new branch.
7. Before doing any work in a reused or newly attached target, require its expected status, fetch `origin --prune`, and compare target `HEAD` with `origin/<branch>` when that remote branch exists, otherwise with the fetched `origin/<default-branch>` creation base.
   - If the commits match, continue. If the remote/base is ahead with no target-only commits, fast-forward only when the target is clean by running `git -C <target> merge --ff-only <target-ref>`, then verify equality; if it is dirty, stop and ask instead.
   - If the target is ahead, diverged, or has local-only history relative to the selected ref, continue only when the user explicitly selected how to use, publish, or reconcile that history. Never reset, rebase, force-push, or overwrite it automatically.
   - If the remote target branch is missing but the local branch was configured to track it, treat this as a deleted-remote branch and stop for an explicit restore, publish, rename, or abandon decision even when target `HEAD` matches the default-branch base.
   - Only a branch without prior upstream configuration may be treated automatically as new when target `HEAD` matches the selected creation base; otherwise its local-only history requires the explicit choice above. Stop if no trustworthy target ref can be established.
8. Resolve the target path again, verify its registered worktree, branch, working state, and commit-history decision, and run every repository command from that worktree.

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
kubectl get pods           rtk kubectl get pods
```

## Meta commands (use directly)

```bash
rtk gain              # Token savings dashboard
rtk gain --history    # Per-command savings history
rtk discover          # Find missed rtk opportunities
rtk proxy <cmd>       # Run raw (no filtering) but track usage
```
<!-- /rtk-instructions -->
