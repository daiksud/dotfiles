# Starship

This is the configuration reference for the cross-shell prompt (Starship).

## File

[`dotfiles/starship.toml`](https://github.com/daiksud/dotfiles/blob/main/dotfiles/starship.toml)
→ `~/.config/starship.toml`

## Prompt structure

The top-level format in the tracked configuration renders a two-line prompt
with Powerline-style gradient segments. The first line shows the icon, current
directory, Git information, detected language versions, and time in that
order. The second line contains the input character.

### Segments and colors

| Segment | Background | Foreground | Contents |
| ----------------------- | ---------- | ---------- | ---------------------------------------- |
| Icon | `#a3aed2` | `#090c0c` | Fixed icon ` ` |
| directory | `#769ff0` | `#e3e5e5` | Current directory |
| git_branch / git_status | `#394260` | `#769ff0` | Branch name + working-tree status |
| languages | `#212736` | `#769ff0` | Node.js / Bun / Rust / Go / PHP versions |
| time | `#1d2230` | `#a0a9cb` | Current time (`HH:MM`) |

## Module settings

### Current directory

The built-in `directory` module renders the directory segment. Only its colors
and format string are themed, so Starship's default truncation applies: the
last three path components are shown, a path inside a Git repository is
truncated to the repository root, and the home directory is displayed as `~`.
A read-only directory adds Starship's read-only indicator in the same colors.

### Git branch

The built-in `git_branch` module displays the Git icon followed by the branch
name of the current working tree, including a linked worktree created by
[gh-qw](./gh-qw.md). A detached HEAD displays `HEAD`. The neighboring
`git_status` module renders the working-tree status and the ahead/behind
counters in the same segment.

### Language modules

Displays the version of detected languages. All use the same unified style:

| Module | Symbol |
| -------- | ------ |
| `nodejs` | `` |
| `bun` | `` |
| `rust` | `` |
| `golang` | `` |
| `php` | `` |

### time

| Key | Value | Description |
| ------------- | ------- | -------------- |
| `disabled` | `false` | Enabled |
| `time_format` | `%R` | `HH:MM` format |
