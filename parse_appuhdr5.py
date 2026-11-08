#!/usr/bin/env python3
"""
Qualcomm APPUHDR5 / PARTDATA / APPUPFTR OTA Firmware Container Parser
Target: Bose QuietComfort Ultra Headphones (Lonestarr, PID 0x4066, OTG-QCC-384)
"""

import json
import math
import re
import struct
import sys
from collections import Counter
from pathlib import Path

# Standard Qualcomm ADK IMAGE_SECTION_ID mapping for QCC51xx / QCC30xx flash layouts
QCC_PARTITION_NAMES = {
    0x00: "nonce (IMAGE_SECTION_NONCE / 128-bit AES-CTR IV / Nonce)",
    0x01: "apps_p0_header / image_header (IMAGE_SECTION_APPS_P0_HEADER)",
    0x02: "apps_p1_header (IMAGE_SECTION_APPS_P1_HEADER)",
    0x03: "audio_header (IMAGE_SECTION_AUDIO_HEADER)",
    0x04: "curator_filesystem (IMAGE_SECTION_CURATOR_FILESYSTEM)",
    0x05: "apps_p0_image (IMAGE_SECTION_APPS_P0_IMAGE - System/BT Core)",
    0x06: "apps_ro_config_filesystem (IMAGE_SECTION_APPS_RO_CONFIG_FILESYSTEM)",
    0x07: "apps_ro_filesystem (IMAGE_SECTION_APPS_RO_FILESYSTEM - Prompts/DSP/Assets)",
    0x08: "apps_device_ro_filesystem (IMAGE_SECTION_APPS_DEVICE_RO_FILESYSTEM)",
    0x09: "apps_p1_image (IMAGE_SECTION_APPS_P1_IMAGE - Customer App Core / Kalimba)",
    0x0A: "audio_image (IMAGE_SECTION_AUDIO_IMAGE)",
}


def shannon_entropy(data: bytes) -> float:
    if not data:
        return 0.0
    length = len(data)
    counts = Counter(data)
    return -sum((count / length) * math.log2(count / length) for count in counts.values())


def extract_ascii_strings(data: bytes, min_len: int = 6) -> list[str]:
    pattern = re.compile(rb"[\x20-\x7e]{" + str(min_len).encode() + rb",}")
    return [m.group(0).decode("ascii", errors="replace") for m in pattern.finditer(data)]


def parse_appuhdr5_header(payload: bytes) -> dict:
    """
    Parse the inner payload of APPUHDR5.
    Layout observed in Bose QCC5181 containers:
      - 'VR:' + 3-byte version (major, minor, patch)
      - 'PRODUCT:' + null-terminated ASCII string
      - 'OTP_PROD' + 2-byte big-endian uint16 flag
    """
    info = {
        "raw_hex": payload.hex(),
        "raw_ascii": payload.decode("latin1"),
        "version": None,
        "product": None,
        "otp_prod_flag": None,
    }
    if payload.startswith(b"VR:") and len(payload) >= 6:
        maj, min_v, pat = payload[3], payload[4], payload[5]
        info["version"] = f"{maj}.{min_v}.{pat}"
        rest = payload[6:]
    else:
        rest = payload

    if rest.startswith(b"PRODUCT:"):
        nul_idx = rest.find(b"\x00", 8)
        if nul_idx != -1:
            info["product"] = rest[8:nul_idx].decode("ascii", errors="replace")
            rest = rest[nul_idx + 1 :]

    if rest.startswith(b"OTP_PROD") and len(rest) >= 10:
        flag = struct.unpack(">H", rest[8:10])[0]
        info["otp_prod_flag"] = flag

    return info


def parse_container(filepath: Path) -> dict:
    data = filepath.read_bytes()
    total_size = len(data)

    pos = 0
    header_info = None
    partitions = []
    footer_info = None
    extra_blocks = []

    while pos + 12 <= total_size:
        tag = data[pos : pos + 8].decode("ascii", errors="replace")
        length = struct.unpack(">I", data[pos + 8 : pos + 12])[0]
        block_start = pos
        payload_start = pos + 12
        payload_end = payload_start + length
        payload = data[payload_start:payload_end]

        if tag.startswith("APPUHDR"):
            parsed_hdr = parse_appuhdr5_header(payload)
            header_info = {
                "magic": tag,
                "offset": f"0x{block_start:06x}",
                "header_length": length,
                "total_block_bytes": 12 + length,
                **parsed_hdr,
            }
        elif tag == "PARTDATA":
            part_type, part_id = struct.unpack(">HH", payload[:4])
            part_u32 = struct.unpack(">I", payload[:4])[0]
            part_body = payload[4:]
            body_len = len(part_body)
            ent = shannon_entropy(part_body)
            strings_8 = extract_ascii_strings(part_body, min_len=8)
            partitions.append(
                {
                    "index": len(partitions),
                    "chunk_offset": f"0x{block_start:06x}",
                    "data_offset": f"0x{payload_start + 4:06x}",
                    "chunk_length_field": length,
                    "payload_bytes": body_len,
                    "aes_block_multiple": (body_len % 16 == 0),
                    "aes_16b_blocks": body_len // 16,
                    "part_type": part_type,
                    "part_id": part_id,
                    "part_header_u32": f"0x{part_u32:08x}",
                    "inferred_name": QCC_PARTITION_NAMES.get(part_id, f"unknown_0x{part_id:02x}"),
                    "shannon_entropy": round(ent, 6),
                    "first_16_bytes_hex": part_body[:16].hex(),
                    "last_16_bytes_hex": part_body[-16:].hex(),
                    "ascii_strings_len8_count": len(strings_8),
                    "ascii_strings_len8_sample": strings_8[:5],
                }
            )
        elif tag in ("APPUPFTR", "APPUFTR"):
            ent = shannon_entropy(payload)
            strings_6 = extract_ascii_strings(payload, min_len=6)
            footer_info = {
                "magic": tag,
                "offset": f"0x{block_start:06x}",
                "payload_offset": f"0x{payload_start:06x}",
                "length_field": length,
                "total_block_bytes": 12 + length,
                "shannon_entropy": round(ent, 6),
                "signature_bits": length * 8,
                "first_32_bytes_hex": payload[:32].hex(),
                "last_32_bytes_hex": payload[-32:].hex(),
                "full_signature_hex": payload.hex(),
                "ascii_strings_len6": strings_6,
            }
        else:
            extra_blocks.append(
                {
                    "magic": tag,
                    "offset": f"0x{block_start:06x}",
                    "length": length,
                }
            )

        pos = payload_end

    return {
        "file": str(filepath),
        "total_bytes": total_size,
        "total_bytes_hex": f"0x{total_size:06x}",
        "unparsed_trailing_bytes": total_size - pos,
        "header": header_info,
        "partitions": partitions,
        "footer": footer_info,
        "extra_blocks": extra_blocks,
    }


def main():
    target = Path(
        sys.argv[1]
        if len(sys.argv) > 1
        else "/Users/satori/.gemini/antigravity/brain/fb2e6858-b0cb-410a-b890-698878bb7cce/scratch/lonestarr_1.6.7.bin"
    )
    report = parse_container(target)
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
