# dotfiles

Minimal macOS (Apple Silicon) development configuration, organized by application.

## Layout

Each application directory at the repository root is a [GNU Stow](https://www.gnu.org/software/stow/) package mirroring the path beneath `$HOME`:

```text
editorconfig/.editorconfig             # ~/.editorconfig (personal settings)
fonts/install.sh                       # Moralerspace HW font
homebrew/install.sh                   # Homebrew and CLI packages
homebrew/Brewfile                      # CLI packages (not stowed)
git/.gitconfig                        # ~/.gitconfig
ghostty/install.sh                    # Ghostty application
ghostty/.config/ghostty/config        # ~/.config/ghostty/config
herdr/.config/herdr/config.toml       # ~/.config/herdr/config.toml
nvim/.config/nvim/                    # ~/.config/nvim/
rumdl/.config/rumdl/rumdl.toml
sheldon/.config/sheldon/plugins.toml
starship/.config/starship.toml        # ~/.config/starship.toml
zsh/.zshrc                            # ~/.zshrc
zsh/.zsh/gh-account.zsh               # ~/.zsh/gh-account.zsh
```

Stow packages: `editorconfig git ghostty herdr nvim rumdl sheldon starship zsh`. The installer scripts are `homebrew/install.sh` (Homebrew and CLI packages), `ghostty/install.sh` (application), and `fonts/install.sh` (font). They are not Stow packages; `ghostty/.stow-local-ignore` excludes its installer from the `ghostty` configuration package. The root `.editorconfig` applies to this repository, independently of the personal `editorconfig/.editorconfig` linked to `~/.editorconfig`. Project-specific EditorConfig files can override the personal defaults. Project-level files such as `bootstrap.sh` and `.github/` stay at the root. The personal `rumdl/.config/rumdl/rumdl.toml` remains Stow-managed, but this repository no longer installs rumdl or runs Markdown lint.

## Install

On a fresh **Apple Silicon Mac**, open Terminal and run one command:

```sh
curl -fsSL https://raw.githubusercontent.com/daiksud/dotfiles/main/bootstrap.sh | bash
```

No tools need to be installed beforehand. The bootstrap uses macOS's built-in Bash and curl to provision Homebrew through `homebrew/install.sh` (downloading that helper before cloning, when necessary), then clones or fast-forwards `~/.dotfiles`. It runs the application installers in order: Homebrew formulas, **Ghostty**, and the **Moralerspace Neon HW** font, followed by Stow and global APM install/compile. Ghostty and the font are installed via Homebrew casks by their own scripts, without replacing manually installed copies.

macOS may ask for administrator approval or Xcode Command Line Tools installation. GitHub CLI authentication requires an interactive browser sign-in; these prompts happen **during** the same installation command. Internet access and a macOS administrator account are required.

To rerun the installer from a checkout:

```sh
cd ~/.dotfiles
./bootstrap.sh
```

Stow does not overwrite unmanaged configuration. Before installation, preview links with `stow --no-folding --simulate --verbose -t "$HOME" editorconfig git ghostty herdr nvim rumdl sheldon starship zsh`. Resolve conflicts explicitly; do **not** use `--adopt`. For a single app, run `stow --no-folding -t "$HOME" ghostty`, or `stow --delete --no-folding -t "$HOME" ghostty` to unlink it.

### Migrating from home/ and dotfiles/

**Before pulling this change** on a Stow-managed machine, unlink the old `home` package while its source still exists:

```sh
cd ~/.dotfiles
stow --delete --no-folding -t "$HOME" home
git pull --ff-only
./bootstrap.sh
```

If you've **already pulled**, or used the pre-Stow setup script, inspect old symlinks first. Remove **only** links proven to point into this checkout's deleted `home/` or `dotfiles/` paths; never delete regular files or unrelated links. Stow will report conflicts if those links remain. Inspect with `ls -l ~/.zshrc ~/.gitconfig ~/.zsh ~/.config/ghostty` and other paths shown above. Avoid `stow --adopt`.

This reorganization does not change Git credentials, SSH signing keys or Herdr sessions.

## GitHub integrations

The installer runs `gh auth login` if needed and installs the `gh-qw` and `gh-infra` extensions. Additional GitHub accounts, account-to-repository mappings and SSH signing keys require your personal identity or authorization, so they are not generated automatically.

`apm.yml` is not tracked here. During `./bootstrap.sh`, the APM CLI creates and manages the global manifest itself:

```sh
apm install --global daiksud/agents --target codex,copilot
apm compile --global
```

Compilation is a separate step: installation deploys the package, while compilation generates global instruction files such as `~/.codex/AGENTS.md`.

## Daily environment

Zsh uses Sheldon (Git aliases, autosuggestions and syntax highlighting), Starship and mise. Neovim uses LazyVim. Ghostty starts Herdr at `/opt/homebrew/bin/herdr`; install Herdr before launching Ghostty.

The GitHub account plugin at `zsh/.zsh/gh-account.zsh` allows different shells to use different accounts. Authenticate via `gh auth login`, choose an owner default with `ghu`, or set a repository override with `gh-account-select --repo`. Account mappings live in `~/.config/gh/repos.json` without tokens. SSH signing expects `~/.ssh/<login>.pub` and maintains `~/.ssh/allowed_signers` for mapped identities.

Ghostty launches Herdr directly, and Herdr manages its own persistent session server. The current Homebrew `herdr` formula has no `brew services` definition. Save running panes before restarting Herdr; stopping the server may terminate running processes.

## Checks

```sh
bash -n bootstrap.sh
bash bootstrap.test.sh
zsh -f zsh/.zsh/gh-account.test.zsh
```

The GitHub account tests live beside the Zsh plugin. The `zsh/.stow-local-ignore` rule keeps the test file out of `~/.zsh`; only `gh-account.zsh` is installed. CI validates config syntax, Stow installation/reinstallation/removal, and GitHub account behavior.
