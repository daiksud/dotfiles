# dotfiles

Minimal macOS (Apple Silicon) development configuration, organized by application.

## Layout

Each application directory at the repository root is a [GNU Stow](https://www.gnu.org/software/stow/) package mirroring the path beneath `$HOME`:

```text
apm/apm.yml                           # manually copied; not stowed
git/.gitconfig                        # ~/.gitconfig
ghostty/.config/ghostty/config        # ~/.config/ghostty/config
herdr/.config/herdr/config.toml       # ~/.config/herdr/config.toml
nvim/.config/nvim/                    # ~/.config/nvim/
rumdl/.config/rumdl/rumdl.toml
sheldon/.config/sheldon/plugins.toml
starship/.config/starship.toml        # ~/.config/starship.toml
zsh/.zshrc                            # ~/.zshrc
zsh/.zsh/gh-account.zsh               # ~/.zsh/gh-account.zsh
```

Stow packages: `git ghostty herdr nvim rumdl sheldon starship zsh`. Project-level configuration such as `Brewfile`, `mise.toml` and `.github/` stays at the root.

## Install

Install [Homebrew](https://brew.sh/), [Ghostty](https://ghostty.org/download) and the [Moralerspace Neon HW font](https://github.com/yuru7/moralerspace/releases) first. Homebrew manages CLI formulas, not apps or fonts. Install Xcode Command Line Tools if Neovim needs a C compiler.

```sh
git clone https://github.com/daiksud/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
brew bundle
stow --no-folding --simulate --verbose -t "$HOME" git ghostty herdr nvim rumdl sheldon starship zsh
stow --no-folding -t "$HOME" git ghostty herdr nvim rumdl sheldon starship zsh
```

Stow does not overwrite unmanaged configuration. Resolve conflicts explicitly; do **not** use `--adopt`. For a single app, run `stow --no-folding -t "$HOME" ghostty`, or `stow --delete --no-folding -t "$HOME" ghostty` to unlink it.

### Migrating from home/ and dotfiles/

**Before pulling this change** on a Stow-managed machine, unlink the old `home` package while its source still exists:

```sh
cd ~/.dotfiles
stow --delete --no-folding -t "$HOME" home
git pull --ff-only
brew bundle
stow --no-folding --simulate --verbose -t "$HOME" git ghostty herdr nvim rumdl sheldon starship zsh
stow --no-folding -t "$HOME" git ghostty herdr nvim rumdl sheldon starship zsh
```

If you've **already pulled**, or used the older `install.sh` instead of Stow, inspect old symlinks first. Remove **only** links proven to point into this checkout's deleted `home/` or `dotfiles/` paths; never delete regular files or unrelated links. Stow will report conflicts if those links remain. Inspect with `ls -l ~/.zshrc ~/.gitconfig ~/.zsh ~/.config/ghostty` and other paths shown above. Avoid `stow --adopt`.

This reorganization does not change Git credentials, SSH signing keys or Herdr sessions.

## One-time integrations

```sh
gh auth login
gh extension install daiksud/gh-qw
gh extension install babarot/gh-infra
brew services start herdr
```

`apm/apm.yml` is a source manifest, not an automatically stowed package: APM writes global state. Back up any existing `~/.apm/apm.yml` before updating it:

```sh
mkdir -p ~/.apm
cp -i apm/apm.yml ~/.apm/apm.yml
apm install --global
apm compile --global
```

## Daily environment

Zsh uses Sheldon (Git aliases, autosuggestions and syntax highlighting), Starship and mise. Neovim uses LazyVim. Ghostty starts Herdr at `/opt/homebrew/bin/herdr`; install Herdr before launching Ghostty.

The GitHub account plugin at `zsh/.zsh/gh-account.zsh` allows different shells to use different accounts. Authenticate via `gh auth login`, choose an owner default with `ghu`, or set a repository override with `gh-account-select --repo`. Account mappings live in `~/.config/gh/repos.json` without tokens. SSH signing expects `~/.ssh/<login>.pub` and maintains `~/.ssh/allowed_signers` for mapped identities.

Herdr sessions persist through its Homebrew service. If an upgrade requires recovery, save running panes before restarting the service **from a plain shell outside Herdr**; restarting may terminate processes.

## Checks

```sh
mise install
mise run markdown:lint
bats tests
```

CI validates config syntax, Stow installation/reinstallation/removal, and GitHub account behavior.
