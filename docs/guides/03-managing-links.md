# Adding and changing links

This page explains how to manage symbolic link mappings by editing `install_map.json`.

## `install_map.json` format

```json
{
  "links": {
    "<source>": "<target>",
    ...
  }
}
```

| Field      | Description                                                   |
| ---------- | ------------------------------------------------------------- |
| `<source>` | File or directory name inside the `dotfiles/` directory       |
| `<target>` | Absolute destination path (`~` expands to the home directory) |

## Add a link

### Example: manage Copilot skills

1. Place the configuration files in `dotfiles/`:

```bash
cp -r ~/.copilot/skills dotfiles/skills
```

2. Add an entry to `install_map.json`:

```json
{
  "links": {
    "skills": "~/.copilot/skills"
  }
}
```

3. Re-run `install.sh`:

```bash
bash install.sh
```

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

## About destination parent directories

`install.sh` automatically creates the destination parent directory (`mkdir -p`). It is fine if `~/.config/` does not already exist.

If `~/.config` was a symbolic link in an older environment, it converts it to a real directory first and then migrates the contents.
