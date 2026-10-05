FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bc \
    bison \
    build-essential \
    ca-certificates \
    clang \
    cpio \
    device-tree-compiler \
    flex \
    gcc-aarch64-linux-gnu \
    gcc-arm-linux-gnueabi \
    git \
    kmod \
    libelf-dev \
    libncurses-dev \
    libssl-dev \
    lld \
    lz4 \
    python3 \
    rsync \
    unzip \
    xz-utils \
    zip \
    && rm -rf /var/lib/apt/lists/*
