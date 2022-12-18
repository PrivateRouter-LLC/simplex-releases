# This step uses ubuntu to build the binaries
FROM ubuntu:22.04 AS build

# URL to the newest SimpleXMQ Tarball
ARG TARBALL_URL

# Install required packages to compile, then cleanup
RUN apt update; DEBIAN_FRONTEND=noninteractive apt install -y build-essential libgmp3-dev \
    zlib1g-dev libnuma1 libnuma-dev libncurses-dev libncurses5 libtinfo5 curl git llvm* \
    && rm -rf /var/lib/apt/lists/*

# Make our work directory and straight untar our source files
RUN mkdir /simplexmq && curl -L ${TARBALL_URL} | tar -xz -C /simplexmq --strip-components=1

# We tell Docker we are now working from /simplexmq
WORKDIR /simplexmq

# Find our arch and install ghcup, ghc, cabal, and compile SimpleXMQ
RUN dpkgArch="$(dpkg --print-architecture)"; ARCH=; \
  case "${dpkgArch##*-}" in \
    amd64) ARCH='x86_64';; \
    arm64) ARCH='aarch64';; \
    armhf) ARCH='armv7';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac; \
  curl https://downloads.haskell.org/~ghcup/0.1.17.8/${ARCH}-linux-ghcup-0.1.17.8 -o /usr/bin/ghcup && \
    chmod +x /usr/bin/ghcup \
  && ghcup install ghc 8.10.7 && ghcup install cabal \
  && ghcup set ghc 8.10.7 && ghcup set cabal \
  && export PATH="/root/.cabal/bin:/root/.ghcup/bin:$PATH" \
  && cabal update && cabal install

# Copy our binaries to /bins from /root/.local/bin
RUN mkdir /bins \
    && cp /root/.cabal/bin/* /bins
