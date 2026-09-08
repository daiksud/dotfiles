# install_map.json

This is the specification for the ordinary symbolic-link mapping file.

## Location

`install_map.json` at the repository root

## Format

```json
{
  "links": {
    "<source>": "<target>",
    "<shared-source>": ["<target-a>", "<target-b>"]
  }
}
```

## Field definitions

### links

An object that defines symbolic link mappings.

| Key | Type | Description |
| ---------- | -------------------- | -------------------------------------------------------------------- |
| `<source>` | string | Relative name of a file or directory under the `dotfiles/` directory |
| value | string or string[] | One destination or a list of destinations; `~` expands to the home directory |

Use an array when multiple destinations must receive the same canonical file.
The current source-to-destination declarations live only in
[`install_map.json`](https://github.com/daiksud/dotfiles/blob/main/install_map.json).

## Processing specification

Behavior when `install.sh` processes `install_map.json`:

1. Parse and type-check `links` with Python3's `json` module before changing
   the filesystem. A syntax or schema error exits without changing any link
2. Expand `~` to `$HOME` in every link destination
3. Normalize each `links` value to one or more destinations
4. For each ordinary link destination:
   - Create the parent directory with `mkdir -p`
   - If an existing file/link is present, remove it with `rm -rf`
   - Create a symbolic link from `dotfiles/<source>` to `<target>`

## Constraints

- Must be valid JSON (no trailing commas)
- Every `links` value must be either a string or an array of strings
- Every source path is resolved relative to `dotfiles/`
