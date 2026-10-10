# dotfiles

Minimal personal development configuration for **macOS (Apple Silicon)**.

## Setup

Install [Homebrew](https://brew.sh/), [Ghostty](https://ghostty.org/download)
and the [Moralerspace Neon HW font](https://github.com/yuru7/moralerspace/releases).
Homebrew manages CLI tools only, not apps or fonts. Install the Xcode Command
Line Tools if a C compiler is not already available for Neovim plugins.

```sh
git clone https://github.com/daiksud/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
brew bundle
stow --no-folding --simulate --verbose --target="$HOME" home
stow --no-folding --target="$HOME" home
```

GNU Stow creates symlinks and refuses to overwrite unmanaged configuration.
Review and back up any conflicts manually. Don't use `stow --adopt`.

## Upgrading from the old installer

Legacy links in `dotfiles/` remain so existing setups keep working after
`git pull`. To migrate the *old managed symlinks* to Stow:

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

Older Stow installations may leave links to **removed files** under
`~/.zsh/` or `~/.config/ghostty/herdr-launch.sh`. They are no longer loaded,
but inspect and remove any stale symlinks manually if desired. A subsequent
`stow` invocation does not automatically remove retired source paths.

## Daily environment

- **Zsh:** native completion/history, Oh My Zsh Git aliases, autosuggestions,
  syntax highlighting, Starship and mise.
- **Neovim:** LazyVim with personal keymaps and Tokyo Night.
- **Ghostty:** launches the Homebrew Herdr client directly at
  `/opt/homebrew/bin/herdr`; this requires Herdr to be installed there.
- **Git:** SSH commit signing and shell-scoped GitHub account selection.
- **CLI:** gh (including gh-qw), fzf, lazygit, ripgrep and other Brewfile tools.
- **AI agents:** an APM manifest tracking `daiksud/agents`.

One-time services and tools:

```sh
gh auth login
gh extension install daiksud/gh-qw
gh extension install babarot/gh-infra
brew services start herdr
```

The APM manifest cannot be managed as a regular link because APM writes
global state. Inspect and back up an existing manifest first, then:

```sh
mkdir -p ~/.apm
cp -i dotfiles/apm/apm.yml ~/.apm/apm.yml
apm install --global
apm compile --global
```

### GitHub identities and SSH signing

The existing `gh-account.zsh` remains because independent shells must be
able to use different GitHub accounts without globally running
`gh auth switch`. Log in to each account through `gh auth login`, then
select the owner default using `ghu` or override a repository using
`gh-account-select --repo`.

The mapping file is `~/.config/gh/repos.json`; it contains metadata, not
tokens. SSH signing expects `~/.ssh/<login>.pub` for the selected account and
maintains `~/.ssh/allowed_signers`. Global Git identity/signing settings
must be configured separately for repositories without a mapped account.

### Deliberately removed features

This repo no longer provisions Codespaces/Ubuntu, provides interactive
`ggr`/`egr` repository jumpers or `bgn` notification browsing, or
automatically falls back to a login shell when Herdr is missing. Use
`gh qw list`, `gh`, `nvim` and `lazygit` directly instead. Shell
shortcuts `esf`, `olg`, custom history search and related wrappers are gone.
Ghostty keeps its Herdr-first behavior on the supported macOS installation.

Herdr persists its sessions via the Homebrew service. If an upgrade leaves
an incompatible server, **save your panes** and restart the service from
a plain shell outside Herdr; restarting can terminate processes in its panes.

## Checks

```sh
mise install
mise run markdown:lint
bats tests
```

CI validates the Stow layout and tests the remaining GitHub identity logic.
