# Security Policy

## Supported Hardware & Firmware Versions

| Product | USB PID | Internal Codename | Firmware Version | Supported |
| :--- | :--- | :--- | :--- | :--- |
| Bose QuietComfort Ultra Headphones (1st Gen) | `0x4066` (`16486`) | `Lonestarr` (`OTG-QCC-384`) | `1.6.7+g6ebabd2` | Yes |
| Bose QuietComfort Ultra Headphones (2nd Gen) | `0x408C` | `2nd Gen` | `1.x` | Partial (Read-only `GET`) |

## Hardware, NVRAM, & RF Safety Boundaries

`Woke Bose` (`bose-ultra-tuner` — Unofficial macOS NVRAM & DSP Interoperability Utility for Bose QuietComfort Ultra Headphones) operates strictly within user-configurable Partition 6 (`EXT_RW_FS`) NVRAM registers over Bluetooth RFCOMM Channel 2 (`00000000-deca-fade-deca-deafdecacaff`):
- **Never modifies boot, radio, or DSP code partitions (`0..5`)**: All executable and RF calibration partitions (`PARTDATA 2:CURATOR_FILESYSTEM`, `PARTDATA 3:APPS_P0_IMAGE`) are hardware-enforced by Qualcomm `QCC5181` `OTP_PROD = 0x0001` (`2048-bit` RSA-PSS + AES-128-CTR) and remain 100% unmodified (`EU RED 2014/53/EU` / `FCC 47 C.F.R. Part 15`).
- **Authorized Local Owner Execution Only (`18 U.S.C. § 1030` — CFAA)**: Operates solely on Bluetooth peripherals locally paired and owned by the user via standard plaintext user-preference commands (`GET 0x01`, `SETGET 0x02`, `START 0x05`).
- **Two-way reversible**: Every register modified by `./bose-ultra-tuner woke` (`[1.7]`, `[1.10]`, `[1.11]`, `[31.3]`, `[31.6]`) can be restored to factory stock at any time via `./bose-ultra-tuner baseline` (`make baseline`).
- **Zero telemetry or cloud credentials**: No Bose Music account, token, or network traffic is transmitted.

## Reporting a Vulnerability

If you discover a BMAP framing bug or a register payload that causes unexpected DSP/NVRAM behavior on a specific firmware revision:
1. Open a private security advisory via [GitHub Security Advisories](https://github.com/TinkeringDao/Woke-Bose/security/advisories/new).
2. Include your firmware string (`./bose-ultra-tuner status`), product ID (`0x4066`), and raw hexadecimal BMAP `TX` / `RX` dump.
