# dotfiles

Personal development environment for macOS (Apple Silicon) and Ubuntu (GitHub Codespaces).

## Setup

Install [Homebrew](https://brew.sh/) first. On macOS, install
[Ghostty](https://ghostty.org/download) and the
[Moralerspace Neon HW font](https://github.com/yuru7/moralerspace/releases)
manually (no Homebrew Casks). Codespaces already installs the CLI packages
from the Brewfile in its container image.

```sh
git clone https://github.com/daiksud/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
brew bundle
stow --no-folding --simulate --verbose --target="$HOME" home
stow --no-folding --target="$HOME" home
```

Stow links the actual config files under `home/` into `$HOME`. It reports
conflicts instead of overwriting existing personal files; review them and
back up unmanaged files before retrying. Do **not** use `stow --adopt`, which
can modify the repository's source files. `--no-folding` keeps shared
configuration directories real so unrelated files can coexist.

### Migrating from install.sh

After pulling these changes, existing `install.sh` links remain functional
through compatibility symlinks under `dotfiles/`. To replace only the
**old managed symlinks** with Stow links, from your local repository root run:

```sh
cd ~/.dotfiles
repo="$(pwd -P)"
for rel in .zshrc .zsh .gitconfig \
  .config/ghostty .config/herdr/config.toml .config/nvim \
  .config/rumdl/rumdl.toml .config/sheldon .config/starship.toml; do
  target="$HOME/$rel"
  if [ -L "$target" ]; then
    case "$(readlink "$target")" in
      "$repo"/dotfiles/*) rm "$target" ;;
    esac
  fi
done
stow --no-folding --simulate --verbose --target="$HOME" home
stow --no-folding --target="$HOME" home
```

This removes symlinks only when their destination is inside this checkout's
old `dotfiles/` directory; it leaves regular files and unrelated symlinks
untouched. If Stow reports a conflict, inspect and resolve it manually.
The compatibility symlinks can be removed in a future cleanup **after**
existing machines have migrated.

### One-time tool setup

```sh
gh auth login
gh extension install daiksud/gh-qw
gh extension install babarot/gh-infra
```

The `apm` manifest is deliberately copied rather than symlinked because
APM manages writable global state. If a manifest already exists, inspect
and back it up before replacing it:

```sh
mkdir -p ~/.apm
cp -i dotfiles/apm/apm.yml ~/.apm/apm.yml
apm install --global
apm compile --global
```

On macOS, start Herdr's persistent server once with
`brew services start herdr`; Ghostty will start its client through
`~/.config/ghostty/herdr-launch.sh`. After changing terminal settings,
reload Ghostty with `⌘⇧,` or restart the application.

The Zsh configuration initializes Sheldon plugins automatically on first
use. Run `mise install` from this repository to provision its validation
tools (Bats, ShellCheck, Python and rumdl).

## Included

- **Shell:** Zsh, Sheldon, Starship, fzf and custom shortcuts
- **Editor:** Neovim with LazyVim
- **Terminal:** Ghostty and persistent Herdr sessions
- **Tools:** Homebrew, mise, gh/gh-qw/gh-infra, lazygit, ripgrep, jq
- **Git:** SSH commit signing and repository-aware GitHub account selection
- **Agent configuration:** APM global manifest referencing `daiksud/agents`

## Configuration

`home/` mirrors the filesystem locations under your home directory.
Edit files there, then rerun `stow --no-folding -t "$HOME" home` to
manage links. Updates to already-linked files take effect without reinstalling.

`Brewfile` is the single source of truth for Homebrew CLI formulas,
including `stow` and `fd`. It does not manage applications or fonts.
Homebrew tools are not upgraded or restarted by Stow.

### GitHub accounts and SSH signing

Authenticate each account with `gh auth login` (or `gh-account-login` in Zsh).
The interactive shell selects a GitHub account per repository owner. Use
`ghu` for the owner default or `gh-account-select --repo` for an override.
Mappings live in `~/.config/gh/repos.json` without tokens; `gh` owns
credentials. The selected token and Git identity apply only to the shell.

Per-account SSH signing keys are expected at `~/.ssh/<login>.pub`;
`gh-account.zsh` updates `~/.ssh/allowed_signers` for mapped identities.
For a standalone global Git identity, configure `user.name`, `user.email`,
and `user.signingkey` explicitly, and add its public key to
`~/.ssh/allowed_signers` if signature verification is required.
No installer generates signing configuration anymore.

`gh qw` handles repository checkouts and worktrees. `ggr` selects a
repository to `cd` into; `egr` opens it in Neovim.

### Herdr recovery

A Herdr server installed as a Homebrew service survives terminal windows
closing. After an incompatible Herdr upgrade, first save work in its panes.
From a **plain shell outside Herdr**, stop any stale server and restart the
Homebrew service if needed. Stopping the server terminates running panes:

```sh
herdr status server --json
brew services list
# Only when a restart is necessary, outside an active Herdr pane:
brew services restart herdr
```

Ghostty's launcher falls back to a login shell if Herdr is unavailable.
Codespaces configures Zsh using its Dev Container features; its image also
installs Homebrew tools and Ghostty.

## Development checks

```sh
mise install
mise run markdown:lint
shellcheck home/.config/ghostty/herdr-launch.sh
bats tests
```

CI validates the Stow layout and runs the remaining shell tests on Ubuntu
and macOS.
