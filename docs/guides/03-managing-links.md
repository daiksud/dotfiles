# Adding and changing links

This page explains how to manage ordinary symbolic links by editing
`install_map.json`.

## `install_map.json` format

```json
{
  "links": {
    "<source>": "<target>",
    "<shared-source>": ["<target-a>", "<target-b>"]
  }
}
```

| Field | Description |
| ------------------ | ---------------------------------------------------------------------------- |
| `<source>` | File or directory name inside the `dotfiles/` directory |
| `<target>` | One absolute destination path (`~` expands to the home directory) |
| `<shared-source>` | A source that must be linked to more than one destination |

## Add a link

1. Place the canonical file or directory under `dotfiles/`.
2. Add its source and destination to the `links` object.
3. Re-run `bash install.sh`.

Each destination receives a symbolic link to the canonical source.

## Remove a link

Remove the relevant entry from `install_map.json`, and remove the file in
`dotfiles/` as needed.

> [!NOTE]
> `install.sh` does not automatically remove links that are no longer in the
> entries. Remove existing symbolic links manually with `rm`.

## About destination parent directories

`install.sh` automatically creates the destination parent directory
(`mkdir -p`). It is fine if `~/.config/` does not already exist.
