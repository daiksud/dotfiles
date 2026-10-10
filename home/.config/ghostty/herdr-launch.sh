#!/bin/sh

# Ghostty's GUI process does not inherit a login shell's PATH (no Homebrew),
# so `command = herdr` in dotfiles/ghostty/config could not resolve the
# binary directly. This wrapper adds the common Homebrew bin directories to
# PATH, then execs herdr so it replaces this process: herdr exiting (e.g. via
# prefix+q, or `herdr server stop`) closes the Ghostty window while the
# server and its panes keep running in the background.
#
# If a login shell should run instead (herdr not installed, or this shell is
# already inside a herdr pane, where HERDR_ENV=1 and herdr blocks nested
# launches), fall back to the user's shell as a login shell.
#
# HERDR_LAUNCH_BREW_BINS overrides the directories searched below with a
# space-separated list; tests use this to point at a sandboxed stub instead
# of real Homebrew paths.
for brew_bin in ${HERDR_LAUNCH_BREW_BINS:-/opt/homebrew/bin /usr/local/bin /home/linuxbrew/.linuxbrew/bin}; do
  [ -d "$brew_bin" ] && PATH="$brew_bin:$PATH"
done
export PATH

login_shell="${SHELL:-/bin/zsh}"

if [ "$HERDR_ENV" = "1" ]; then
  exec "$login_shell" -l
fi

if command -v herdr >/dev/null 2>&1; then
  exec herdr
fi

exec "$login_shell" -l
