# install_map.json

This is the specification for the symbolic link mapping file.

## Location

`install_map.json` at the repository root

## Format

```json
{
  "links": {
    "<source>": "<target>"
  }
}
```

## Field definitions

### links

An object that defines symbolic link mappings.

| Key        | Type   | Description                                                          |
| ---------- | ------ | -------------------------------------------------------------------- |
| `<source>` | string | Relative name of a file or directory under the `dotfiles/` directory |
| `<target>` | string | Absolute destination path. `~` is expanded to the home directory     |

## Current entries

| Source                    | Target                               | Contents                               |
| ------------------------- | ------------------------------------ | -------------------------------------- |
| `zshrc`                   | `~/.zshrc`                           | Zsh configuration file                 |
| `zsh`                     | `~/.zsh`                             | Zsh custom plugin directory            |
| `tmux.conf`               | `~/.tmux.conf`                       | tmux configuration                     |
| `gitconfig`               | `~/.gitconfig`                       | Global Git configuration               |
| `ghostty`                 | `~/.config/ghostty`                  | Ghostty terminal configuration         |
| `mise`                    | `~/.config/mise`                     | mise tool version configuration        |
| `nvim`                    | `~/.config/nvim`                     | Neovim configuration (LazyVim)         |
| `sheldon`                 | `~/.config/sheldon`                  | sheldon plugin configuration           |
| `starship.toml`           | `~/.config/starship.toml`            | Starship prompt configuration          |
| `skills`                  | `~/.copilot/skills`                  | Copilot CLI custom skills              |
| `copilot-instructions.md` | `~/.copilot/copilot-instructions.md` | Copilot CLI personal instructions file |

## Processing specification

Behavior when `install.sh` processes `install_map.json`:

1. Parse the file with Python3's `json` module
2. Expand `~` to `$HOME`
3. For each entry:
   - If the destination's parent directory is a symbolic link, convert it to a real directory and migrate the contents
   - If the parent directory does not exist, create it with `mkdir -p`
   - If an existing file/link is present, remove it with `rm -rf`
   - Create a symbolic link from `dotfiles/<source>` to `<target>`

## Constraints

- Must be valid JSON (no trailing commas)
