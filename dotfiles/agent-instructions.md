# Agent Personal Instructions

## Pull Request skills

If the user asks to create a Pull Request, always use the `pr-create` skill.
If the user asks to fix, improve, or make a Pull Request mergeable, always use
the `pr-fix` skill.
If the user asks to merge a Pull Request once review is clean, always use the
`pr-merge` skill.

Invoke the matching skill through the current agent's skill mechanism directly
from the checkout where the request was made. Do not create or select a
worktree first: each skill owns its `gh-qwt` workflow, and `pr-create` must
inspect and migrate the invoking checkout's dirty state.

## Worktree usage

For every other repository task, perform all work inside a `gh-qwt` worktree. Collect every probe whose output or exit status this workflow parses, compares, preserves for migration, or uses for a safety decision without RTK filtering, as specified in the raw-output exception below.

1. Treat the checkout where the request was made as the source. Before changing directories or provisioning a worktree:
   - Record its physically resolved absolute Git worktree root and current working directory. Require the working directory to equal the root or be its descendant using a path-component boundary, then derive and record that repository-relative working directory (`.` for the root). Do not derive it from raw `$PWD`, and reject an absolute or parent-traversing result.
   - Record the current branch, `HEAD`, staged and unstaged diffs, non-ignored untracked-file list, and `git status --porcelain=v1 -z`.
2. Resolve the selected source remote's expanded fetch URL through GitHub to obtain its canonical repository URL, lowercase host, canonical `<owner>/<repo>`, and default branch; do not infer `github.com` from an unqualified repository name. Also resolve the source branch and tracking ref and the intended `<branch>`, then calculate the primary checkout and target paths with `gh qwt path <host>/<owner>/<repo>` and `gh qwt path <host>/<owner>/<repo>/<branch>`. Always pass a host-qualified spec (`github.com/<owner>/<repo>[/<branch>]` for GitHub.com): `gh qwt path` reads a three-segment spec as `<host>/<owner>/<repo>`, so an unqualified `<owner>/<repo>/<branch>` resolves to the wrong identity and fails.
   - `gh qwt` keeps the primary checkout as an ordinary clone at `<ghq-root>/<host>/<owner>/<repo>` and every non-default branch as an external linked worktree at `<qwt.worktreeroot>/<host>/<owner>/<repo>/<branch>`, which defaults to `<ghq-root>-worktrees`. The default branch has no linked worktree: it is the primary checkout itself.
   - Treat the repository as existing only when `git -C <primary-checkout> config --get qwt.managed` prints exactly `true`; `gh qwt path` also prints deterministic planned paths for repositories and worktrees that do not exist yet. An occupied repository path that is not a `qwt.managed` repository is a collision: stop and report it instead of provisioning into it.
   - The paths are host-qualified, but the same `<owner>/<repo>` can still exist on several hosts and `path`, `list --exact`, `add --repo`, and `remove --repo` all accept short `<owner>/<repo>` specs that silently mean `github.com`. So, before listing, fetching, adding to, or reusing an existing repository, read the expanded fetch URL for `origin` from its primary checkout with `git -C "$(gh qwt path <host>/<owner>/<repo>)" remote get-url origin`, resolve that URL through GitHub, and require the resulting canonical URL and full `<host>/<owner>/<repo>` identity to equal the source repository. Additionally require `git -C <primary-checkout> config --get qwt.identity` to equal `<host>/<owner>/<repo>`. Stop if either identity cannot be verified or differs; do not fetch, rewrite `origin`, or reuse a repository belonging to another host. Use a separately configured ghq root (`GHQ_ROOT` or `ghq.root`) or resolve the collision manually.
3. Confirm whether the target is a registered worktree by requiring `gh qwt list --all <host>/<owner>/<repo>/<branch> --exact --full-path` to succeed without RTK filtering, then checking whether at least one stdout line equals the calculated target path byte-for-byte. Pass `--all` whenever the check covers a repository other than the one containing the current directory: an unqualified `gh qwt list` is scoped to the discovered repository and fails with `gh-qwt: repository is outside configured ghq roots` when the current directory is a Git repository outside those roots. Ignore other returned lines because `--exact` also matches a bare `<branch>`, `<repo>/<branch>`, and `<owner>/<repo>/<branch>` in every listed repository. Stop if the command fails; empty output or no exact target-path line means that the target is absent. If it exists, verify that its current branch equals the intended branch and stop on a mismatch, then record its staged, unstaged, untracked, and porcelain status before reuse. When `<branch>` is the default branch, the registered path is the primary checkout itself.
4. Compare the resolved source and target roots before doing any work:
   - If the target is registered and they are the same worktree, continue there without discarding its current state. Treat an unregistered target as absent even if its calculated path matches the source textually.
   - Otherwise, if the source or an existing target has uncommitted changes, do not silently leave the source or mix distinct states. Continue an existing dirty target only when the user explicitly identified its changes as the work to continue. Migrate source changes only when the user explicitly chose that outcome, after completing the committed-history check below, preserving staged, unstaged, and non-ignored untracked state and verifying the target before clearing the source. In all other cases, stop and ask how to proceed; never combine two dirty worktrees automatically.
   - Proceed without migration only when the source is clean and the target is absent or clean.
5. Whenever the source and target are different, fetch the remote that corresponds to the resolved `<host>/<owner>/<repo>` and compare committed history even when the source is dirty. Use a configured tracking ref only when it belongs to that full repository identity; otherwise use an existing matching `<remote>/<source-branch>`, or the fetched `<remote>/<default-branch>` as the creation base for an unpublished source branch. Compare that ref with the recorded source `HEAD`, for example with `git rev-list --left-right --count <source-ref>...<source-HEAD>`.
   - Equal commits, or a source that is only behind the ref, have no local-only source history.
   - A source that is ahead or diverged has local-only commits. Continue only when the user explicitly chose how to publish that exact history, deliberately transfer it to the target, or leave it out; otherwise stop and ask. Never keep working in the ordinary source, or push, rebase, reset, or omit those commits automatically.
   - Stop if no trustworthy matching remote/base ref can be established.
6. If the target is missing and the recorded state permits provisioning, use an explicit, host-aware repository. When the repository is missing, always pass the already resolved branch as well as the host: use `gh qwt get --host <host> --branch <default-branch> <owner>/<repo>`, which prints the primary checkout, or replace that branch argument with an existing remote `<branch>` to create its linked worktree. For a new branch, initialize a missing repository with the explicit host and resolved default branch, reverify the created primary checkout's `origin` and `qwt.identity` as described above, then use `gh qwt add --repo <host>/<owner>/<repo> --new --from origin/<default-branch> <branch>`. When the verified repository already exists, refresh `origin --prune` and record whether `refs/heads/<branch>` plus any `branch.<branch>.remote` and merge configuration already exist before running `gh qwt add --repo <host>/<owner>/<repo> <branch>`. `add` reattaches an existing local branch before considering the remote and uses `--from` only on the path where it creates the branch itself; combine `--new` with `--from` when the branch must be genuinely new, because `--new` fails instead of attaching an existing local or remote branch. `add` cannot create a worktree for the default branch, which is the primary checkout.
7. Before doing any work in a reused or newly attached target, require its expected status, fetch `origin --prune`, and compare target `HEAD` with `origin/<branch>` when that remote branch exists, otherwise with the fetched `origin/<default-branch>` creation base.
   - If the commits match, continue. If the remote/base is ahead with no target-only commits, fast-forward only when the target is clean by running `git -C <target> merge --ff-only <target-ref>`, then verify equality; if it is dirty, stop and ask instead.
   - If the target is ahead, diverged, or has local-only history relative to the selected ref, continue only when the user explicitly selected how to use, publish, or reconcile that history. Never reset, rebase, force-push, or overwrite it automatically.
   - If the remote target branch is missing but the local branch was configured to track it, treat this as a deleted-remote branch and stop for an explicit restore, publish, rename, or abandon decision even when target `HEAD` matches the default-branch base.
   - Only a branch without prior upstream configuration may be treated automatically as new when target `HEAD` matches the selected creation base; otherwise its local-only history requires the explicit choice above. Stop if no trustworthy target ref can be established.
8. Resolve the target path again and verify its registered worktree with the exact target-path line test above, then verify its branch, working state, and commit-history decision. Map the recorded source-relative working directory onto the target and require that counterpart to already exist as a directory. Physically resolve it and require the result to equal the resolved target root or be its descendant using a path-component boundary. Stop on a missing or non-directory counterpart, traversal, or symlink escape; do not create it or fall back to the target root. Change to the verified counterpart, confirm `pwd -P` still equals it, and run every subsequent repository command from that directory.

## Comments on Issues / Pull Requests

When posting a comment or reply on an Issue or Pull Request at the user's instruction, always prefix it with `:robot:`.

<!-- rtk-instructions v2 -->
## RTK — Token-Optimized CLI

**rtk** is a CLI proxy that filters and compresses command outputs, saving 60-90% tokens.

### Rule

Always prefix shell commands with `rtk`:

```bash
# Instead of:              Use:
git status                 rtk git status
git log -10                rtk git log -10
cargo test                 rtk cargo test
docker ps                  rtk docker ps
kubectl get pods           rtk kubectl get pods
```

### Meta commands (use directly)

```bash
rtk gain              # Token savings dashboard
rtk gain --history    # Per-command savings history
rtk discover          # Find missed rtk opportunities
rtk proxy <cmd>       # Run raw (no filtering) but track usage
```

<!-- /rtk-instructions -->

## Raw-output exception

The RTK rule above does not apply when command output or exit status will be parsed, compared for equality, preserved for migration, or otherwise used for a safety decision. Run those commands with `RTK_DISABLED=1 <command>` or, for a simple command, through `rtk proxy <command>`; make decisions only from the raw output and original exit status. For the worktree workflow, this includes every recorded status, diff, ref, path, and list probe; never parse or compare filtered RTK output.
