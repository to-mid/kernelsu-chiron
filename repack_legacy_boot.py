#!/usr/bin/env python3
"""Replace the kernel payload in an Android boot image header v0 image."""

import argparse
import hashlib
import struct
from pathlib import Path


MAGIC = b"ANDROID!"
KERNEL_SIZE_OFFSET = 8
RAMDISK_SIZE_OFFSET = 16
SECOND_SIZE_OFFSET = 24
PAGE_SIZE_OFFSET = 36
HEADER_VERSION_OFFSET = 40
OS_VERSION_OFFSET = 44
ID_OFFSET = 576
ID_SIZE = 32


def align(value: int, page_size: int) -> int:
    return (value + page_size - 1) // page_size * page_size


def read_u32(data: bytes, offset: int) -> int:
    return struct.unpack_from("<I", data, offset)[0]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("boot_image", type=Path)
    parser.add_argument("kernel_image", type=Path)
    parser.add_argument("output_image", type=Path)
    args = parser.parse_args()

    source = args.boot_image.read_bytes()
    kernel = args.kernel_image.read_bytes()

    if source[:8] != MAGIC:
        raise SystemExit("input is not an Android boot image")

    old_kernel_size = read_u32(source, KERNEL_SIZE_OFFSET)
    ramdisk_size = read_u32(source, RAMDISK_SIZE_OFFSET)
    second_size = read_u32(source, SECOND_SIZE_OFFSET)
    page_size = read_u32(source, PAGE_SIZE_OFFSET)
    os_version = read_u32(source, OS_VERSION_OFFSET)
    header_version = read_u32(source, HEADER_VERSION_OFFSET)

    if page_size not in (2048, 4096, 8192, 16384):
        raise SystemExit(f"unsupported page size: {page_size}")
    if header_version != 0:
        raise SystemExit(
            f"expected boot header v0, found header version {header_version}"
        )
    if len(source) < page_size:
        raise SystemExit("truncated boot image header")

    kernel_start = page_size
    ramdisk_start = align(kernel_start + old_kernel_size, page_size)
    second_start = align(ramdisk_start + ramdisk_size, page_size)
    end_of_payloads = align(second_start + second_size, page_size)
    if end_of_payloads > len(source):
        raise SystemExit("truncated boot image payload")

    ramdisk = source[ramdisk_start : ramdisk_start + ramdisk_size]
    second = source[second_start : second_start + second_size]
    trailing_data = source[end_of_payloads:]

    header_page = bytearray(source[:page_size])
    struct.pack_into("<I", header_page, KERNEL_SIZE_OFFSET, len(kernel))

    digest = hashlib.sha1()
    for payload in (kernel, ramdisk, second):
        digest.update(payload)
        digest.update(struct.pack("<I", len(payload)))
    header_page[ID_OFFSET : ID_OFFSET + ID_SIZE] = digest.digest().ljust(ID_SIZE, b"\0")

    output = bytearray(header_page)
    output.extend(kernel)
    output.extend(b"\0" * (align(len(output), page_size) - len(output)))
    output.extend(ramdisk)
    output.extend(b"\0" * (align(len(output), page_size) - len(output)))
    output.extend(second)
    output.extend(b"\0" * (align(len(output), page_size) - len(output)))
    output.extend(trailing_data)

    args.output_image.write_bytes(output)
    print(f"boot header: v{header_version}, page size {page_size}, os version 0x{os_version:08x}")
    print(f"kernel: {old_kernel_size} -> {len(kernel)} bytes")
    print(f"output: {args.output_image} ({len(output)} bytes)")
    print(f"sha1: {digest.hexdigest()}")


if __name__ == "__main__":
    main()
