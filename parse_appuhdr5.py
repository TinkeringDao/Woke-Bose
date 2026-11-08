#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 acid9burn
"""
Qualcomm APPUHDR5 / PARTDATA / APPUPFTR Container Metadata & Entropy Inspector.

Clean-room interoperability and hardware security boundary verification utility
developed under EU Directive 2009/24/EC Arts. 5(3) & 6 (§§ 69d Abs. 3, 69e UrhG),
§ 3 Abs. 1 Nr. 2 GeschGehG, and 17 U.S.C. § 1201(f). Supplied strictly as
non-commercial free and open-source software (Regulation (EU) 2024/2847 Recitals
15 & 18; Directive (EU) 2024/2853 Art. 2(2)).

Inspects outer TLV container geometry, partition block alignment, and Shannon
entropy to verify OTP_PROD hardware encryption boundaries. Performs zero
decryption, zero key extraction, and zero binary modification, and redacts all
proprietary payload/signature bytes (<REDACTED_OEM_BYTES>). See LEGAL.md.
"""

import json
import math
import struct
import sys
from collections import Counter
from pathlib import Path

QCC_PARTITION_MAP = {
    0x0000: "IMAGE_SECTION_NONCE / IV_SEED (16B Crypto Initialization Vector)",
    0x0001: "IMAGE_SECTION_APPS_P0_HEADER / FLASH_HEADER (Partition Table & Hash Header)",
    0x0002: "IMAGE_SECTION_APPS_P1_HEADER",
    0x0003: "IMAGE_SECTION_AUDIO_HEADER (Kalimba DSP Header)",
    0x0004: "IMAGE_SECTION_CURATOR_FILESYSTEM (Subsystem Boot / Radio Patches)",
    0x0005: "IMAGE_SECTION_APPS_P0_IMAGE (Qualcomm System / BT Stack Firmware)",
    0x0006: "IMAGE_SECTION_APPS_RO_CONFIG_FILESYSTEM (Read-Only Config / PS Keys)",
    0x0007: "IMAGE_SECTION_APPS_RO_FILESYSTEM (Customer RO FS / DSP .kap / Voice Prompts)",
    0x0008: "IMAGE_SECTION_APPS_DEVICE_CONFIG_FILESYSTEM",
    0x0009: "IMAGE_SECTION_APPS_P1_IMAGE (Application Core P1 Firmware)",
    0x000A: "IMAGE_SECTION_APPS_RW_FILESYSTEM (Writable Config / NVRAM)",
    0x000B: "IMAGE_SECTION_AUDIO_IMAGE (Kalimba Audio DSP Image)",
}


def shannon_entropy(data: bytes) -> float:
    if not data:
        return 0.0
    counts = Counter(data)
    n = len(data)
    return -sum((c / n) * math.log2(c / n) for c in counts.values())


def parse_appuhdr5_header(payload: bytes) -> dict:
    """Parse the 34-byte APPUHDR5 metadata payload without emitting raw OEM bytes."""
    info = {
        "payload_redacted": "<REDACTED_OEM_BYTES>",
    }
    if payload.startswith(b"VR:") and len(payload) >= 6:
        ver_bytes = payload[3:6]
        info["version_tuple"] = list(ver_bytes)
        info["version_str"] = f"{ver_bytes[0]}.{ver_bytes[1]}.{ver_bytes[2]}"
    if b"PRODUCT:" in payload:
        idx = payload.index(b"PRODUCT:") + len(b"PRODUCT:")
        end = payload.index(b"\x00", idx) if b"\x00" in payload[idx:] else len(payload)
        info["product_codename"] = payload[idx:end].decode("ascii", errors="replace")
    if b"OTP_PROD" in payload:
        idx = payload.index(b"OTP_PROD") + len(b"OTP_PROD")
        otp_val = payload[idx : idx + 2]
        info["otp_prod_flag"] = int.from_bytes(otp_val, "big") if len(otp_val) == 2 else None
    return info


def parse_container(bin_path: Path) -> dict:
    raw = bin_path.read_bytes()
    total_len = len(raw)

    offset = 0
    header_info = {}
    partitions = []
    footer_info = {}
    extra_blocks = []

    if raw[offset : offset + 8] == b"APPUHDR5":
        hdr_len = struct.unpack(">I", raw[offset + 8 : offset + 12])[0]
        hdr_payload = raw[offset + 12 : offset + 12 + hdr_len]
        header_info = {
            "magic": "APPUHDR5",
            "offset": f"0x{offset:08x}",
            "header_payload_len": hdr_len,
            "parsed": parse_appuhdr5_header(hdr_payload),
        }
        offset += 12 + hdr_len

    part_idx = 0
    while offset + 12 <= total_len:
        tag = raw[offset : offset + 8]
        tag_str = tag.decode("ascii", errors="replace")
        blk_len = struct.unpack(">I", raw[offset + 8 : offset + 12])[0]
        payload_start = offset + 12
        payload_end = payload_start + blk_len
        payload = raw[payload_start:payload_end]

        if tag == b"PARTDATA":
            part_type = struct.unpack(">H", payload[0:2])[0] if len(payload) >= 4 else None
            part_id = struct.unpack(">H", payload[2:4])[0] if len(payload) >= 4 else None
            body = payload[4:]
            ent = shannon_entropy(body)

            partitions.append(
                {
                    "index": part_idx,
                    "chunk_offset": f"0x{offset:08x}",
                    "data_offset": f"0x{payload_start + 4:08x}",
                    "chunk_len": blk_len,
                    "body_bytes": len(body),
                    "aes_block_multiple": (len(body) % 16 == 0),
                    "aes_16b_blocks": len(body) // 16,
                    "part_type": f"0x{part_type:04x}" if part_type is not None else None,
                    "part_id": f"0x{part_id:04x}" if part_id is not None else None,
                    "inferred_name": QCC_PARTITION_MAP.get(part_id, f"UNKNOWN_SECTION_0x{part_id:04x}"),
                    "shannon_entropy": round(ent, 6),
                    "payload_bytes_redacted": "<REDACTED_OEM_BYTES>",
                }
            )
            part_idx += 1

        elif tag == b"APPUPFTR":
            ent = shannon_entropy(payload)
            footer_info = {
                "magic": "APPUPFTR",
                "chunk_offset": f"0x{offset:08x}",
                "data_offset": f"0x{payload_start:08x}",
                "signature_len_bytes": blk_len,
                "signature_bits": blk_len * 8,
                "shannon_entropy": round(ent, 6),
                "signature_bytes_redacted": "<REDACTED_OEM_SIGNATURE>",
            }
        else:
            extra_blocks.append(
                {
                    "tag": tag_str,
                    "offset": f"0x{offset:08x}",
                    "length": blk_len,
                }
            )

        offset = payload_end

    return {
        "file_size_bytes": total_len,
        "file_size_hex": f"0x{total_len:x}",
        "bytes_accounted_for": offset,
        "trailing_unparsed_bytes": total_len - offset,
        "header": header_info,
        "partitions": partitions,
        "footer": footer_info,
        "extra_blocks": extra_blocks,
    }


def main():
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(f"Usage: {sys.argv[0]} <path-to-appuhdr5-container.bin>")
        sys.exit(0)
    target = Path(sys.argv[1])
    report = parse_container(target)
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
