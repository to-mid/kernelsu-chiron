#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VARIANT="${1:-next}"
case "${VARIANT}" in
    next|legacy) ;;
    *) printf 'Usage: %s [next|legacy]\n' "$0" >&2; exit 2 ;;
esac
IMAGE_NAME="kernelsu-chiron-build:22.04"
VOLUME_NAME="${KERNEL_BUILD_VOLUME:-kernelsu-chiron-published-${VARIANT}}"
ARTIFACTS_DIR="${ROOT_DIR}/artifacts/${VARIANT}"

docker build -t "${IMAGE_NAME}" -f "${ROOT_DIR}/build/Dockerfile" "${ROOT_DIR}/build"

docker volume create "${VOLUME_NAME}" >/dev/null
docker run --rm \
    --volume "${VOLUME_NAME}:/workspace" \
    "${IMAGE_NAME}" \
    chown "$(id -u):$(id -g)" /workspace

mkdir -p "${ARTIFACTS_DIR}"

docker run --rm \
    --user "$(id -u):$(id -g)" \
    --env "KSU_VARIANT=${VARIANT}" \
    --volume "${ROOT_DIR}:/host:ro" \
    --volume "${VOLUME_NAME}:/workspace" \
    --volume "${ARTIFACTS_DIR}:/artifacts" \
    "${IMAGE_NAME}" \
    bash -lc '
        set -euo pipefail

        if [[ ! -d /workspace/kernel ]]; then
            git clone https://github.com/LineageOS/android_kernel_xiaomi_msm8998.git /workspace/kernel
        fi

        cd /workspace/kernel
        git checkout --detach e0a1a7747eb61e1d77ebcdebbcd48af0dc3b6c21
        if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
            printf "Tracked kernel files are modified; use a fresh Docker volume.\n" >&2
            exit 1
        fi

        if [[ "${KSU_VARIANT}" == next ]]; then
            KSU_DIR=KernelSU-Next
            KSU_URL=https://github.com/KernelSU-Next/KernelSU-Next.git
            KSU_COMMIT=9b08e88862000d5c50fb2e43a5b75123cf472e54
            KERNEL_PATCH=kernel-next-built.patch
        else
            KSU_DIR=KernelSU
            KSU_URL=https://github.com/tiann/KernelSU.git
            KSU_COMMIT=b766b98513b5a7eb33bc1c4a76b5702bf1288f07
            KERNEL_PATCH=kernel-host.patch
        fi
        if [[ ! -d "/workspace/${KSU_DIR}" ]]; then
            git clone "${KSU_URL}" "/workspace/${KSU_DIR}"
        fi
        git -C "/workspace/${KSU_DIR}" checkout --detach "${KSU_COMMIT}"
        if [[ -n "$(git -C "/workspace/${KSU_DIR}" status --porcelain --untracked-files=no)" ]]; then
            printf "Tracked KSU files are modified; use a fresh Docker volume.\n" >&2
            exit 1
        fi

        git apply --check "/host/patches/${KERNEL_PATCH}"
        if [[ "${KSU_VARIANT}" == next ]]; then
            git -C "/workspace/${KSU_DIR}" apply --check /host/patches/kernelsu-next-linux44.patch
            git -C "/workspace/${KSU_DIR}" apply /host/patches/kernelsu-next-linux44.patch
        fi
        git apply "/host/patches/${KERNEL_PATCH}"
        ln -s "../../${KSU_DIR}/kernel" drivers/kernelsu

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
