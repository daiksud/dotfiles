#!/bin/bash
set -eux -o pipefail

FILE=$(readlink -f "$0")
DIR=$(dirname "${FILE}")

# set default shell to zsh
sudo chsh "$(id -un)" --shell "/usr/bin/zsh"

# make symlinks
for src in "${DIR}"/.*; do
	# Skip if it's . or .. or .git
	[ "${src}" = "${DIR}/." ] || [ "${src}" = "${DIR}/.." ] || [ "${src}" = "${DIR}/.git" ] && continue

	name=$(basename "${src}")
	dst="${HOME}/${name}"

	# Delete if it already exists
	if [[ -e "${dst}" ]]; then
		echo "Warning: ${dst} already exists, deleting"
		rm -rf "${dst}"
	fi

	echo "Make symlink ${src} -> ${dst}"
	ln -sf "${src}" "${dst}"
done

if [[ "$(uname -s)" != "Linux" ]]; then
	exit
fi

# Below codes for codespaces
# set timezone to Asia/Tokyo
sudo ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# Install fzf
git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
"$HOME/.fzf/install" --all --no-fish

# Install lazygit
mkdir -p "$HOME/.local/src/lazygit/"
cd "$HOME/.local/src/lazygit/"
LAZYGIT_VERSION=$(gh api repos/jesseduffield/lazygit/releases/latest | jq -r '.tag_name | ltrimstr("v")')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
