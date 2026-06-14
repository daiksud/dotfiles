# 0001: Adopt a JSON mapping table for symbolic link management

Manage the source→target mapping for symbolic links declaratively in `install_map.json`.

## Status

Accepted

## Context

Previously, all dotfiles under `dotfiles/` were linked uniformly to `~/` using a shell glob (`dotfiles/.*`). This approach had the following issues:

- There was no way to link to nested paths such as `~/.config/X`
- It could not support links to arbitrary paths such as `~/.copilot/skills`
- Because file names under `dotfiles/` became link names as-is, naming flexibility was limited
- Special handling for files like `.gitconfig` kept increasing, making the script more complex

## Decision

Place `install_map.json` at the repository root and define the mapping as key-value pairs in a JSON object.

```json
{
  "links": {
    "zshrc": "~/.zshrc",
    "nvim": "~/.config/nvim",
    "starship.toml": "~/.config/starship.toml"
  }
}
```

Use Python3's `json` module for parsing (preinstalled on both macOS and Ubuntu).

## Alternatives Considered

### Simple line format (`source:target`)

- Easiest to implement
- Difficult to add comments or structure
- No editor support (lint, schema validation)

### TOML

- Highly readable
- No parser is preinstalled on macOS / Ubuntu (`tomllib` in Python3 is only available in 3.11+)

### YAML

- Highly readable
- Python3 standard library does not include a parser (`PyYAML` is required)

### bash associative arrays

- Zero external dependencies
- Poor support for comments inside the array and lower maintainability
- Requires bash 4.0+ (the default bash on macOS is 3.2)

## Consequences

- Adding or removing entries is completed simply by editing the JSON file
- File names under `dotfiles/` no longer need a `.` prefix, making the file list easier to read
- This introduces a dependency on Python3, but it is available by default on the target platforms (macOS and Ubuntu)
- JSON does not allow comments, but that is not a problem because the entries are self-explanatory
