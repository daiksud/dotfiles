# ref: https://github.com/devcontainers/images/blob/main/src/base-ubuntu/.devcontainer/Dockerfile
ARG VARIANT="noble"
FROM buildpack-deps:${VARIANT}-curl

# code style ref: https://github.com/docker-library/buildpack-deps/blob/master/ubuntu/noble/curl/Dockerfile
RUN set -ex; \
    apt-get update; \
    apt-get full-upgrade -y --no-install-recommends; \
    apt-get install -y --no-install-recommends \
        neovim \
    ; \
    rm -rf \
        /var/lib/apt/lists/* \
    ; \
    true
