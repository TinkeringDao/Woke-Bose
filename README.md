# Woke Bose (`bose-ultra-tuner`)

[![CI](https://github.com/TinkeringDao/Woke-Bose/actions/workflows/ci.yml/badge.svg)](https://github.com/TinkeringDao/Woke-Bose/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

macOS Bluetooth RFCOMM (`00000000-deca-fade-deca-deafdecacaff`) user-preference NVRAM/DSP client, CoreAudio `HFP SCO` input guard, read-only `APPUHDR5` container metadata inspector, and acoustic reference calibration suite for the Bose QuietComfort Ultra Headphones (1st Gen, `PID 0x4066` / `Lonestarr`, firmware `1.6.7+g6ebabd2`).

## Problem & Approach

Using Bose QuietComfort Ultra Headphones with a Mac hits three annoying stock defaults:

1. **Out-of-the-box tonal balance**: Coupler measurements (`B&K 5128` and `GRAS 43AG`) show a `+3.77 dB` upper-bass shelf (`90-180 Hz`), a `-2.22 dB` vocal dip around `1.63 kHz`, and a `+3.08 dB` ear-canal peak at `2.37 kHz`, normally adjustable only by installing the Bose mobile app and signing into a cloud account.
2. **macOS `HFP SCO` call-mode hijacks & ambient sidetone hiss**: Whenever a background macOS app touches the default audio input while the headphones are connected, macOS drops `2-ch Stereo A2DP` into `16 kHz` mono `HFP SCO` telephony mode and activates the exterior ambient call microphones (`[1.11]` Self Voice = `MEDIUM` by default).
3. **ActiveSense & WindBlock coloration**: Default mode slots leave dynamic ActiveSense ANC modulation or the `400 Hz` WindBlock high-pass gate active unless reconfigured in NVRAM.

`bose-ultra-tuner` talks directly over macOS `IOBluetooth` RFCOMM to the headphones' `BMAP` user-preference service (`Qualcomm QCC5181` Partition 6 `EXT_RW_FS`), programming persistent hardware EQ (`[1.7]` -> Kalimba `[5.17]` Q1.31 biquad bank), sidetone (`[1.11]`), multipoint (`[1.10]`), and custom mode slot `4` (`[31.6]` / `[31.3]`) while keeping `MacBook Pro Microphone` locked as the macOS `CoreAudio` default input device. Settings written to Partition 6 persist across power cycles and across host OSes without a mobile app or cloud account.

## Quick Start

With your Bose QuietComfort Ultra Headphones paired and connected to macOS:

```bash
# Build ./bose-ultra-tuner
make

# Apply full calibration (CoreAudio SCO input guard + hardware EQ -3/+1/+2 + Sidetone OFF + Slot 4 Full ANC)
make woke

# Or run the interactive terminal menu
./bose-ultra-wizard.sh

# Revert to factory stock registers at any time
make baseline
```

## Measured Register & Acoustic Changes

### 1. BMAP Register & Telemetry Summary

| Subsystem | BMAP Register | Factory Stock | Calibrated (`woke`) | Measured Effect |
| :--- | :--- | :--- | :--- | :--- |
| Hardware 3-Band EQ (`[1.7]`) | `01 07` (`SETGET 0x02`) | `0 / 0 / 0 dB` (`00 00 01 00 02 00`) | `-3 / +1 / +2 dB` (`00 fd 01 01 02 02`) | Trims `90-180 Hz` bass shelf and lifts `1.6 kHz` / `>6 kHz` inside the 24-bit Kalimba DSP |
| Kalimba Biquad Stage 0 (`[5.17]`) | `05 11` (`GET 0x01`, `2..17`) | `7fffffff` (`b0 = +1.0` bypass) | `fe08aefc 7ffc115c` (`a1 = -0.015349`, `b0 = +0.999881`) | Active Q1.31 low-shelf filter on `QCC5181` 240 MHz Kalimba DSP |
| Kalimba Biquad Stage 3 (`[5.17]`) | `05 11` (`GET 0x01`, `50..65`) | `7fffffff` (`b0 = +1.0` bypass) | `f315b575 fbc792d2 00000000 7f46dc5c` | Active Q1.31 midrange/treble filter (Stages 1, 2, 4, 5 stay unity bypass) |
| Self Voice / Sidetone (`[1.11]`) | `01 0B` (`SETGET 0x02`) | `MEDIUM` (`01 02 0f`) | `OFF` (`01 00 0f`, `Persist=1`) | Disables exterior mic loopback into earcups and HFP uplink |
| Multipoint (`[1.10]`) | `01 0A` (`SETGET 0x02`) | `ENABLED` (`0x07`) | `ENABLED` (`0x07`) or single-point via `multipoint off` | Retains dual-ACL Mac + Phone pairing while CoreAudio guard blocks macOS SCO hijacks |
| Custom Mode Slot 4 (`[31.6]`, `[31.3]`) | `1F 06` / `1F 03` | Inactive | `"Woke Studio"`: `ANC 10/10 (atten=0x00)`, `AutoCNC=0`, `Spatial=0`, `WindBlock=0` | Full static `ADI 71215 BCBZ` ANC without ActiveSense pumping or `400 Hz` WindBlock high-pass |
| macOS CoreAudio Input Guard | `DefaultInputDevice` | Bose QC Ultra (`16 kHz` mono `SCO`) | Built-in Mac Microphone | Keeps playback locked in 2-ch stereo A2DP when background apps query mic input |
| Stationary Mic Noise Floor (`48 kHz` PCM) | Voice Memo 10th pct RMS | `-58.7 dBFS` (`SNR 35.4 dB`) | `-78.8 dBFS` (`SNR 54.3 dB`) | `-20.1 dB` reduction in continuous room/HVAC floor with sidetone loopback disabled |

### 2. BMAP `[31.6]` (`AudioModes.ModeItem`) Byte Layout

Each audio mode slot on firmware `1.6.7` is written via a 39-byte `SETGET` payload on `Block 0x1F, Func 0x06` (read back as a 47-byte `STATUS` frame):

| Offset (Write / Status) | Field | Slot 0 (`"Quiet"`) | Slot 1 (`"Aware"`) | Slot 4 (`"Woke Studio"`) | Role |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `0` | `slot_id` | `0x00` | `0x01` | `0x04` | Mode slot index (`0..9`) in Partition 6 NVRAM |
| `1..2` | `prompt_id` | `0x0001` | `0x0002` | `0x000C` | Voice prompt category (`0x000C` = `"Music"`) |
| `3..34` | `mode_name[32]` | `"Quiet\0..."` | `"Aware\0..."` | `"Woke Studio\0..."` | Null-padded 32-byte UTF-8 label |
| `35` *(Status `42`)* | `anc_attenuation` | `0x00` (`10/10` ANC) | `0x0A` (`0/10` Aware) | `0x00` (`10/10` ANC) | `ADI 71215 BCBZ` attenuation (`0x00` = Full ANC, `0x0A` = Aware) |
| `36` *(Status `43`)* | `auto_cnc` | `0x00` | `0x00` / `0x01` | `0x00` | ActiveSense dynamic ANC modulation (`0` = Off) |
| `37` *(Status `44`)* | `spatial_mode` | `0x00` | `0x00` | `0x00` | Immersive Audio (`0` = Off, `1` = Still, `2` = Motion via `STM32U585OI`) |
| `38` *(Status `46`)* | `wind_block` | `0x00` | `0x00` | `0x00` | WindBlock `400 Hz` high-pass gate (`0x00` = Off) |

### 3. Coupler Frequency Response Deviation (`20 Hz - 15 kHz`)

Measured against `B&K 5128` Diffuse Field (`-1 dB/oct` tilt) and `GRAS 43AG` Harman Over-Ear 2018 targets:

| Freq (`Hz`) | Stock Error (`B&K 5128`) | Stock Error (`GRAS Harman`) | On-Chip EQ (`-3/+1/+2`) | On-Chip EQ + 10-Band Host PEQ |
| :---: | :---: | :---: | :---: | :---: |
| `20` | `+2.70 dB` | `+0.90 dB` | `-0.10 dB` | `0.00 dB` |
| `62` | `+2.96 dB` | `+2.50 dB` | `-0.04 dB` | `0.00 dB` |
| `120` | `+3.77 dB` | `+4.10 dB` | `+0.77 dB` | `+0.08 dB` |
| `180` | `+2.42 dB` | `+4.50 dB` | `-0.18 dB` | `-0.05 dB` |
| `500` | `+0.69 dB` | `+0.30 dB` | `+0.89 dB` | `+0.04 dB` |
| `1,000` | `+0.20 dB` | `+0.10 dB` | `+0.50 dB` | `0.00 dB` |
| `1,630` | `-2.22 dB` | `-2.90 dB` | `-1.12 dB` | `-0.06 dB` |
| `2,370` | `+3.08 dB` | `+2.20 dB` | `+2.18 dB` | `+0.05 dB` |
| `5,000` | `-2.95 dB` | `-4.80 dB` | `-1.15 dB` | `+0.10 dB` |
| `8,200` | `+3.02 dB` | `+2.70 dB` | `+1.85 dB` | `-0.08 dB` |
| `11,200` | `-2.19 dB` | `-1.90 dB` | `-0.19 dB` | `+0.05 dB` |

Host 10-band Parametric EQ presets for eqMac, SoundSource, Equalizer APO, EasyEffects, and Wavelet are in [`peq/bose_qc_ultra_bk5128_reference.txt`](peq/bose_qc_ultra_bk5128_reference.txt) and [`peq/bose_qc_ultra_gras_harman2018.txt`](peq/bose_qc_ultra_gras_harman2018.txt).

## CLI Subcommands

`bose-ultra-tuner` discovers paired `PID 0x4066` headphones via `IOBluetooth` (or accepts `--mac XX-XX-XX-XX-XX-XX`):

| Command | Action |
| :--- | :--- |
| `./bose-ultra-tuner woke` | Apply CoreAudio input guard, hardware EQ `-3/+1/+2`, Sidetone `OFF`, Multipoint `ON`, and Slot 4 `"Woke Studio"` (`CNC=10/10`) |
| `./bose-ultra-tuner baseline` | Restore stock defaults (`EQ 0/0/0`, `Sidetone MEDIUM`, `Multipoint ON`, Slot 0 `"Quiet"`) |
| `./bose-ultra-tuner status` | Read firmware revision, battery, active mode, 3-band EQ, sidetone, multipoint, and `[5.17]` Q1.31 biquad coefficients |
| `./bose-ultra-tuner fix-noise` | Route macOS input to built-in mic, disable sidetone, and activate Slot 4 Full ANC |
| `./bose-ultra-tuner use-phone` / `use-mac` | Hand Multipoint A2DP stream focus between Phone and Mac via `CoreAudio` output routing |
| `./bose-ultra-tuner eq <B> <M> <T>` | Set hardware 3-band EQ in integer dB (`-10..+10`) |
| `./bose-ultra-tuner sidetone <off\|low\|med\|high>` | Set Self Voice / Sidetone level |
| `./bose-ultra-tuner multipoint <on\|off>` | Toggle Bluetooth Multipoint (`[1.10]`) |
| `./bose-ultra-tuner mode <0-4>` | Switch active mode slot (`0`=Quiet, `1`=Aware, `2`=Immersion, `4`=Woke Studio) |
| `./bose-ultra-tuner scan` | Read accessible BMAP function blocks (`0x00..0x22`) |

## Known Limitations

- **Hardware & firmware scope**: Register offsets (`[5.17]` biquad readback and 39-byte `[31.6]` mode payloads) were verified on 1st-Gen Bose QuietComfort Ultra Headphones (`PID 0x4066`, firmware `1.6.7+g6ebabd2`); QC45, QC Ultra Earbuds, or newer firmware revisions may use different BMAP payload lengths.
- **macOS `IOBluetooth` & `CoreAudio` only**: `bose_ultra_tuner.m` links against macOS `IOBluetooth.framework` and `CoreAudio.framework`; Linux (`BlueZ`) and Windows hosts can still use the NVRAM settings once written, plus the `peq/` filter files.
- **3-band on-chip EQ granularity**: The `[1.7]` BMAP interface exposes 3 integer-dB bands rather than arbitrary user-supplied Q1.31 biquad coefficients (`[5.17]` is read-only over RFCOMM), so narrow-band `2.37 kHz` / `8.2 kHz` ear-canal peaks require the optional host `peq/` preset.

## Repository Files

- [`bose_ultra_tuner.m`](bose_ultra_tuner.m) — Objective-C `IOBluetooth` RFCOMM BMAP client, `CoreAudio` device router, and `[5.17]` biquad reader
- [`bose-ultra-wizard.sh`](bose-ultra-wizard.sh) — Interactive shell menu
- [`parse_appuhdr5.py`](parse_appuhdr5.py) — Read-only `APPUHDR5` TLV header and Shannon entropy inspector (zero decryption or OEM binaries)
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) & [`GLOSSARY.md`](GLOSSARY.md) — Silicon BOM, Partition 6 NVRAM boundary, and BMAP protocol notes

## License & Legal

Released under the [MIT License](LICENSE).
Independent non-commercial interoperability utility (not affiliated with Bose Corporation, Qualcomm, or Analog Devices); see [`LEGAL.md`](LEGAL.md) for statutory interoperability, trademark nominative fair use, and German statutory references.
