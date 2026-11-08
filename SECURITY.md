# Security Policy

## Supported Hardware & Firmware Versions

| Product | USB PID | Internal Codename | Firmware Version | Supported |
| :--- | :--- | :--- | :--- | :--- |
| Bose QuietComfort Ultra Headphones (1st Gen) | `0x4066` (`16486`) | `Lonestarr` (`OTG-QCC-384`) | `1.6.7+g6ebabd2` | Yes |
| Bose QuietComfort Ultra Headphones (2nd Gen) | `0x408C` | `2nd Gen` | `1.x` | Partial (Read-only `GET`) |

## Hardware & NVRAM Safety Boundaries

`Woke-Bose` operates strictly within user-configurable Partition 6 (`EXT_RW_FS`) NVRAM registers over Bluetooth RFCOMM Channel 2 (`00000000-deca-fade-deca-deafdecacaff`):
- **Never modifies boot/DSP code partitions (`0..5`)**: All executable partitions are hardware-enforced by Qualcomm `QCC5181` `OTP_PROD = 0x0001` (`2048-bit` RSA-PSS + AES-128-CTR).
- **Two-way reversible**: Every register modified by `./bose-ultra-tuner woke` (`[1.7]`, `[1.10]`, `[1.11]`, `[31.3]`, `[31.6]`) can be restored to factory stock at any time via `./bose-ultra-tuner baseline` (`make baseline`).
- **Zero telemetry or cloud credentials**: No Bose Music account, token, or network traffic is transmitted.

## Reporting a Vulnerability

If you discover a BMAP framing bug or a register payload that causes unexpected DSP/NVRAM behavior on a specific firmware revision:
1. Open a private security advisory via [GitHub Security Advisories](https://github.com/acid9burn/Woke-Bose/security/advisories/new).
2. Include your firmware string (`./bose-ultra-tuner status`), product ID (`0x4066`), and raw hexadecimal BMAP `TX` / `RX` dump.
