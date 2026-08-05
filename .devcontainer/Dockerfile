# ref: https://github.com/devcontainers/images/blob/main/src/base-ubuntu/.devcontainer/Dockerfile
ARG VARIANT="noble"
FROM buildpack-deps:${VARIANT}-curl

ENV MISE_DATA_DIR=/home/linuxbrew/mise

RUN <<EOF
apt-get update
apt-get full-upgrade -y --no-install-recommends

# Install Homebrew
apt-get install -y --no-install-recommends \
  build-essential \
  git
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install gcc
EOF

# Install packages via Brewfile
COPY Brewfile Brewfile
RUN eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && HOMEBREW_BUNDLE_NO_LOCK=1 brew bundle --file=Brewfile

# Install Vite+ for the eventual remote user
COPY scripts/003-vite-plus.sh /tmp/003-vite-plus.sh
RUN mkdir -p /home/codespace && HOME=/home/codespace /bin/bash /tmp/003-vite-plus.sh

# Install Ghostty
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"

# Pre-install tools via mise using repository config
COPY mise.toml /tmp/dotfiles/mise.toml
RUN eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && cd /tmp/dotfiles && mise install

RUN apt-get clean && rm -rf /var/lib/apt/lists/* && \
    rm -f /tmp/003-vite-plus.sh && rm -rf /tmp/dotfiles && \
    chown -R 1001:1001 /home/linuxbrew/ /home/codespace/
