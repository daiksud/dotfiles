# dotfiles

Personal development environment for macOS (Apple Silicon) and Ubuntu (GitHub Codespaces).

## Setup

On macOS, install [Ghostty](https://ghostty.org/download) and the
[Moralerspace Neon HW font](https://github.com/yuru7/moralerspace/releases)
manually. Homebrew manages CLI formulas only (no Casks).

~~~sh
git clone https://github.com/daiksud/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
bash install.sh
exec zsh
~~~

The installer creates symbolic links, installs or upgrades Homebrew CLI tools
from `Brewfile`, and configures plugins, GitHub CLI extensions, mise, and Herdr.
On Ubuntu, it also configures the login shell and time zone.

**Warning:** `install.sh` removes existing files or directories at destinations
listed in `install_map.json` before creating links. Back up any existing
configuration before the first run.

After changing Ghostty configuration, reload it with `⌘⇧,` or quit and
reopen Ghostty if a new window still uses the old settings.

## Included

- **Shell:** Zsh, Sheldon plugins, Starship, fzf and custom shortcuts
- **Editor:** Neovim with LazyVim
- **Terminal:** Ghostty and persistent Herdr sessions
- **Tools:** Homebrew, mise, GitHub CLI, gh-qw, gh-infra, lazygit, ripgrep, jq
- **Git:** SSH commit signing and repository-aware GitHub account selection
- **Agent configuration:** Global `apm` manifest referencing `daiksud/agents`

The root `mise.toml` provisions tooling used to maintain this repository
(Bats, ShellCheck, Python and rumdl). Node.js and Bun versions should be
managed by the projects that need them.

## Configuration

`install_map.json` maps sources under `dotfiles/` to locations in your home
directory. For example, `zshrc` becomes `~/.zshrc`, while `ghostty` becomes
`~/.config/ghostty`. Edit the map to add or remove managed links, then rerun
`bash install.sh`. Removing an entry does **not** remove an old installed link.

`Brewfile` is the source of truth for Homebrew CLI packages. Keep application
and font installations outside of Homebrew Cask.

### GitHub accounts and signing

Authenticate accounts with `gh auth login` (or `gh-account-login` inside Zsh).
The interactive shell chooses an identity per GitHub repository owner; use
`ghu` to change the owner default, or `gh-account-select --repo` for an
individual repository override. Mappings are stored in
`~/.config/gh/repos.json` without tokens; credentials remain managed by `gh`.
The selected token and Git identity apply to the current shell only.

SSH signing uses a public key at `~/.ssh/<login>.pub` for each mapped GitHub
login. The shell maintains `~/.ssh/allowed_signers` for verification; the
installer also initializes that file when a global Git email and
`~/.ssh/id_ed25519.pub` are available.

The `gh qw` extension manages repositories and linked worktrees.
`ggr` opens a fuzzy repository selector for `cd`; `egr` opens the selected
repository in Neovim.

### Herdr

Ghostty starts Herdr through `dotfiles/ghostty/herdr-launch.sh`. On macOS,
`install.sh` configures a persistent Homebrew service. To check it:

~~~sh
brew services list
herdr status server --json
~~~

If a Homebrew upgrade leaves an incompatible Herdr server, installation
attempts recovery. **Stopping the server terminates its running panes.**
If recovery is refused because the installer is inside Herdr, save your work
and rerun `bash install.sh` from a plain shell outside Herdr.

## Development checks

The repository retains shell lint, configuration validation and Bats tests
for macOS and Ubuntu. No documentation website or JavaScript build is needed.

~~~sh
mise install
mise run markdown:lint
shellcheck install.sh scripts/*.sh dotfiles/ghostty/herdr-launch.sh
bats tests
~~~
