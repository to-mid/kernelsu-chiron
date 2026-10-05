#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="kernelsu-chiron-build:22.04"
VOLUME_NAME="kernelsu-chiron-build-workspace"
ARTIFACTS_DIR="${ROOT_DIR}/artifacts"

docker build -t "${IMAGE_NAME}" -f "${ROOT_DIR}/build/Dockerfile" "${ROOT_DIR}/build"

docker volume create "${VOLUME_NAME}" >/dev/null
docker run --rm \
    --volume "${VOLUME_NAME}:/workspace" \
    "${IMAGE_NAME}" \
    chown "$(id -u):$(id -g)" /workspace

mkdir -p "${ARTIFACTS_DIR}"

docker run --rm \
    --user "$(id -u):$(id -g)" \
    --volume "${ROOT_DIR}:/host:ro" \
    --volume "${VOLUME_NAME}:/workspace" \
    --volume "${ARTIFACTS_DIR}:/artifacts" \
    "${IMAGE_NAME}" \
    bash -lc '
        set -euo pipefail

        if [[ ! -d /workspace/kernel/.git ]]; then
            git clone --no-local /host/src/kernel /workspace/kernel
        fi

        cd /workspace/kernel
        git reset --hard HEAD

        while IFS= read -r file; do
            mkdir -p "$(dirname "${file}")"
            cp "/host/src/kernel/${file}" "${file}"
        done < <(git -C /host/src/kernel diff --name-only --diff-filter=ACMRTUXB)

        rm -rf /workspace/KernelSU-Next drivers/kernelsu
        cp -a /host/src/KernelSU-Next /workspace/KernelSU-Next
        ln -s ../../KernelSU-Next/kernel drivers/kernelsu

        export ARCH=arm64
        export SUBARCH=arm64
        export CC=clang
        export HOSTCC=clang
        export HOSTCXX=clang++
        export LD=ld.lld
        export CLANG_TRIPLE=aarch64-linux-gnu-
        export CROSS_COMPILE=aarch64-linux-gnu-
        export CROSS_COMPILE_ARM32=arm-linux-gnueabi-

        mkdir -p out
        make O=out chiron_defconfig
        make O=out -j"$(nproc)" KCFLAGS=-Wno-error

        cp out/arch/arm64/boot/Image.gz-dtb /artifacts/
        cp out/.config /artifacts/kernel.config
    '
