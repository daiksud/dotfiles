# Adding and changing links

This page explains how to manage ordinary and Agent Skills symbolic links by
editing `install_map.json`.

## `install_map.json` format

```json
{
  "links": {
    "<source>": "<target>",
    "<shared-source>": ["<target-a>", "<target-b>"]
  },
  "skill_targets": ["<skill-root-a>", "<skill-root-b>"]
}
```

| Field              | Description                                                                  |
| ------------------ | ---------------------------------------------------------------------------- |
| `<source>`         | File or directory name inside the `dotfiles/` directory                      |
| `<target>`         | One absolute destination path (`~` expands to the home directory)            |
| `<shared-source>`  | A source that must be linked to more than one destination                    |
| `skill_targets`    | Destination directories that receive one link per directory in `dotfiles/skills/` |

## Add a link

### Example: share one configuration file

1. Place the canonical file in `dotfiles/`:

```bash
cp ~/.example-agent/instructions.md dotfiles/agent-instructions.md
```

2. Give its `links` entry an array of destinations:

```json
{
  "links": {
    "agent-instructions.md": [
      "~/.example-agent-a/instructions.md",
      "~/.example-agent-b/instructions.md"
    ]
  }
}
```

3. Re-run `install.sh`:

```bash
bash install.sh
```

Each destination receives a symbolic link to the same canonical source file.

### Add an Agent Skill

Create one directory under `dotfiles/skills/` and place its `SKILL.md` there.
The configured `skill_targets` already distribute every skill directory when
`install.sh` runs, so adding a skill does not require another mapping entry.

```bash
mkdir -p dotfiles/skills/example-skill
${EDITOR:-vi} dotfiles/skills/example-skill/SKILL.md
```

Add the required `name` and `description` frontmatter plus the operating
procedure before installing it. See
[Skill Development](../development/03-skills-development.md) for a complete
sample structure. Then run:

```bash
bash install.sh
```

The installer creates `example-skill` links under both shared agent skill
roots. It preserves the roots themselves and any unrelated installed skills.
See [Using skills](./06-skills.md) for the destinations used by GitHub Copilot,
Codex, and Claude Code.

### Example: add an application under `~/.config`

```bash
cp -r ~/.config/lazygit dotfiles/lazygit
```

```json
{
  "links": {
    "lazygit": "~/.config/lazygit"
  }
}
```

## Remove a link

Remove the relevant entry from `install_map.json`, and remove the file in `dotfiles/` as needed.

> [!NOTE]
> `install.sh` does not automatically remove links that are no longer in the entries. Remove existing symbolic links manually with `rm`.

For a skill, remove its directory from `dotfiles/skills/` and remove the old
per-skill links from each configured skill target. The installer does not
delete links for skills that no longer exist in the canonical directory.

## About destination parent directories

`install.sh` automatically creates the destination parent directory (`mkdir -p`). It is fine if `~/.config/` does not already exist.

If `~/.config` was a symbolic link in an older environment, it converts it to a real directory first and then migrates the contents.
Relative link targets are resolved from the directory containing the link. If
the target is missing or is not a directory, installation stops without
removing the original link.

The agent configuration roots `~/.copilot`, `~/.codex`, and `~/.claude` are
an exception. Existing links for those roots are preserved, and managed files
are installed through them into the relocated configuration directories. This
keeps synced or externally managed agent settings in place. A dangling root
link or one that resolves to a non-directory remains untouched and stops the
installation.

Missing skill target directories are created as real directories. The
installer replaces an existing entry only at
`<skill-target>/<skill-name>`; it never replaces the entire skill target. An
existing target-root symlink is preserved, including a whole-directory alias
to the canonical skills source.

## Migration from the Copilot-only skill link

Earlier versions linked all of `dotfiles/skills/` to `~/.copilot/skills`.
After all replacement links are installed successfully, the installer removes
that legacy path only when it is a symbolic link that resolves to this
repository's canonical skills directory. It leaves real directories and links
to any other source untouched. If ordinary or replacement-skill link
installation fails before cleanup, the legacy link stays in place.

This ordering and exact-target check prevent migration from deleting either
the last working discovery path, canonical skills, or independently managed
Copilot content.

Older installations may also have
`~/.copilot/copilot-instructions.md` linked to
`dotfiles/copilot-instructions.md`. That source remains as a thin compatibility
adapter, so pulling this change does not break the active Copilot instructions
before installation. The next successful `install.sh` run relinks the
destination directly to canonical `dotfiles/agent-instructions.md`.
