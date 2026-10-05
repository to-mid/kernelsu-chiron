#!/usr/bin/env python3
"""Check boot v0 payload layout, SHA-1 ID, and optional reference payloads."""

import argparse
import hashlib
import struct
from pathlib import Path

from repack_legacy_boot import align


def parse_boot(path, check_id=True):
    data = path.read_bytes()
    if len(data) < 608 or data[:8] != b"ANDROID!":
        raise ValueError(f"{path}: invalid boot header")
    sizes = [struct.unpack_from("<I", data, offset)[0] for offset in (8, 16, 24)]
    page = struct.unpack_from("<I", data, 36)[0]
    version = struct.unpack_from("<I", data, 40)[0]
    if version != 0 or page not in (2048, 4096, 8192, 16384):
        raise ValueError(f"{path}: unsupported header or page size")
    cursor = page
    payloads = []
    digest = hashlib.sha1()
    for size in sizes:
        end = cursor + size
        if end > len(data):
            raise ValueError(f"{path}: truncated payload")
        payload = data[cursor:end]
        payloads.append(payload)
        digest.update(payload)
        digest.update(struct.pack("<I", size))
        cursor = align(end, page)
    if cursor > len(data):
        raise ValueError(f"{path}: truncated padding")
    if check_id and data[576:608] != digest.digest().ljust(32, b"\0"):
        raise ValueError(f"{path}: boot SHA-1 ID mismatch")
    return payloads


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("boot", type=Path)
    parser.add_argument("--kernel", type=Path)
    parser.add_argument("--original", type=Path)
    args = parser.parse_args()
    try:
        payloads = parse_boot(args.boot)
        if args.kernel and payloads[0] != args.kernel.read_bytes():
            raise ValueError("kernel payload mismatch")
        if args.original and payloads[1:] != parse_boot(args.original, check_id=False)[1:]:
            raise ValueError("original ramdisk/second payload mismatch")
    except (OSError, ValueError) as error:
        raise SystemExit(str(error))
    print(f"OK: {args.boot.name}: boot v0 layout and SHA-1 ID verified")
    if args.kernel:
        print("OK: kernel payload matches")
    if args.original:
        print("OK: original ramdisk and second payload preserved")


if __name__ == "__main__":
    main()
