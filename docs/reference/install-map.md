# install_map.json

This is the specification for the ordinary-link and Agent Skills destination
mapping file.

## Location

`install_map.json` at the repository root

## Format

```json
{
  "links": {
    "<source>": "<target>",
    "<shared-source>": ["<target-a>", "<target-b>"]
  },
  "skill_targets": ["<skill-root-a>", "<skill-root-b>"]
}
```

## Field definitions

### links

An object that defines symbolic link mappings.

| Key | Type | Description |
| ---------- | -------------------- | -------------------------------------------------------------------- |
| `<source>` | string | Relative name of a file or directory under the `dotfiles/` directory |
| value | string or string[] | One destination or a list of destinations; `~` expands to the home directory |

Use an array when GitHub Copilot, Codex, Claude Code, or other tools must read
the same canonical file from different product-specific paths. The current
source-to-destination declarations live only in
[`install_map.json`](https://github.com/daiksud/dotfiles/blob/main/install_map.json).

### skill_targets

An array of directories that receive the skills under `dotfiles/skills/`.
Every direct child directory that contains `SKILL.md` is treated as one skill,
and the installer links that child into each target using the same directory
name.

Missing targets are created as real directories, while an existing target root
is not replaced. This per-skill layout preserves unrelated built-in or
independently installed skills and avoids replacing a tool's entire skill root.

## Processing specification

Behavior when `install.sh` processes `install_map.json`:

1. Parse and type-check both `links` and `skill_targets` with Python3's `json`
   module, materializing both normalized result sets before changing the
   filesystem. A syntax or schema error exits without changing any link
2. Expand `~` to `$HOME` in every link and skill destination
3. Normalize each `links` value to one or more destinations
4. For each ordinary link destination:
   - If the destination's parent directory is a symbolic link, resolve relative targets from the link's directory, verify that the target is an existing directory, then convert the parent to a real directory and migrate the contents
   - Preserve symlinked `~/.copilot`, `~/.codex`, and `~/.claude` parents and create the managed file through the link instead; this protects relocated or synced agent configuration roots
   - If that parent link is dangling or points to a non-directory, leave it intact and stop the installation
   - If the parent directory does not exist, create it with `mkdir -p`
   - If an existing file/link is present, remove it with `rm -rf`
   - Create a symbolic link from `dotfiles/<source>` to `<target>`
5. For each direct child of `dotfiles/skills/` that contains `SKILL.md`, and
   each `skill_targets` entry:
   - Create a missing skill target as a real directory; preserve an existing
     target root, including a symbolic-link root
   - Replace only `<skill-target>/<skill-name>` if it already exists
   - Link that path to the canonical skill directory
   - Remove a symbolic-link entry when it resolves strictly under the
     canonical skills directory but the resolved directory no longer contains
     `SKILL.md`
   - Preserve real directories and links to other sources; skip a target root
     that itself resolves to the canonical skills directory

When at least one skill target is configured, the installer checks the legacy
`~/.copilot/skills` path after every ordinary link and replacement skill link
succeeds. It removes that path only when it is a symbolic link that resolves
to this repository's `dotfiles/skills/`; unrelated links and real directories
are preserved. Before removal, every configured target root that is itself a
symbolic link is resolved. If any such whole-directory alias resolves to the
canonical skills, the legacy path is retained because the alias may traverse
it and would become dangling after removal. An empty `skill_targets` array
provides no replacement discovery path, so it does not trigger cleanup. If
link installation fails before cleanup, the legacy discovery path remains
available. The installer also avoids deleting entries through a
whole-directory alias. Failure to resolve an existing or canonical path is
treated as an installation error, not as evidence that two paths are equal.

## Constraints

- Must be valid JSON (no trailing commas)
- Every `links` value must be either a string or an array of strings
- `skill_targets` must be an array of strings
- Every source path is resolved relative to `dotfiles/`
