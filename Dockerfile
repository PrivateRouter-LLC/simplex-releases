# This step uses debian to build the binaries
FROM ubuntu:22.04 AS build

# URL to the newest SimpleXMQ Tarball
ARG TARBALL_URL

# Install required packages to compile, then cleanup
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update \
    && apt install -y haskell-platform haskell-stack \
       libncurses-dev libncurses5 libtinfo5 curl git \
       libnuma1 libnuma-dev \
    && rm -rf /var/lib/apt/lists/*

# Make our work directory and straight untar our source files
RUN mkdir /simplexmq && curl -L ${TARBALL_URL} | tar -xz -C /simplexmq --strip-components=1

# We tell Docker we are now working from /simplexmq
WORKDIR /simplexmq

# Use stack to build SimpleXMQ and copy our compiled binaries
# --copy-bins moves the binaries to /root/.local/bin
RUN stack build --copy-bins --ghc-options -j$(nproc)

# Copy our binaries to /bins from /root/.local/bin
RUN mkdir /bins \
    && cp /root/.local/bin/* /bins

# Scratch is a special slim docker pointer that allows us to export the binaries to the host
FROM scratch AS export
COPY --from=build /bins .
