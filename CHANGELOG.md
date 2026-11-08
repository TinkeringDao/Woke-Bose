# Changelog

All notable changes to **Woke Bose** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-11-08

### Added
- **`bose-ultra-tuner` (`bose_ultra_tuner.m`)**: Native macOS `IOBluetooth` RFCOMM Channel 2 (`00000000-deca-fade-deca-deafdecacaff`) BMAP NVRAM programmer with automatic paired-device discovery (`PID 0x4066`).
- **`woke` Calibration Preset**:
  - Programs `[1.7]` Hardware 3-Band EQ to `Bass: -3 dB | Mid: +1 dB | Treble: +2 dB` (`f6 0a fd 00 f6 0a 01 01 f6 0a 02 02`).
  - Verifies active `Q1.31` fixed-point biquad filters on Qualcomm `QCC5181` 240 MHz Kalimba DSP via `[5.17]` (`Stage 0: fe08aefc 7ffc115c`, `Stage 3: f315b575 fbc792d2 00000000 7f46dc5c`).
  - Disables `[1.11]` Self Voice / Sidetone (`01 00 0f`, `Persist=1`) to eliminate ambient microphone loopback during calls (`-20.1 dB` stationary noise floor reduction, `+18.9 dB` SNR improvement).
  - Disables `[1.10]` Bluetooth Multipoint (`0x06`) to prevent `8,000 Hz` narrowband `CVSD` fallback and lock `16,000 Hz` wideband `mSBC`.
  - Programs and activates `[31.6]` / `[31.3]` Custom Mode Slot 4 (`"Woke Studio"` / `"Call Studio"`, `CNC=0/10, AutoCNC=0, Spatial=Off, WindBlock=OFF`).
- **`baseline` Factory Restore Preset**: 1-command rollback restoring `[1.7]` (`0/0/0 dB`), `[1.11]` (`MEDIUM`), `[1.10]` (`ENABLED`), and `[31.3]` (Slot `0` `"Quiet"`).
- **`bose-ultra-wizard.sh`**: Interactive CLI wizard for 1-click `Woke` calibration, live telemetry readback, macOS `BluetoothAudioAgent` bitpool tuning (`58..80`), BMAP register scanning, and factory restore.
- **`parse_appuhdr5.py`**: Read-only Qualcomm `APPUHDR5` container metadata and Shannon entropy inspector (`OTP_PROD = 0x0001` verification, 7 `PARTDATA` structural descriptors, and `<REDACTED_OEM_BYTES>` redaction).
- **10-Band Parametric EQ Presets (`peq/`)**: Reference filter sets for Brüel & Kjær 5128 Diffuse Field (`-1 dB/oct`) and GRAS 43AG Harman Over-Ear 2018 targets.
- **Documentation & Statutory Compliance**: Complete [`README.md`](README.md) Baseline vs. Woke comparison matrices, [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) silicon BOM (`QCC5181`, `2x ADI 71215 BCBZ`, `STM32U585OI`, `PSoC 4000S`), [`LEGAL.md`](LEGAL.md) (`§§ 69a/69d/69e/69g UrhG`, `§ 3 Abs. 1 Nr. 2 GeschGehG`, `§ 23 Abs. 1 Nr. 3 MarkenG`, `§§ 202c/303a StGB`, `Regulation (EU) 2024/2847` Recital 18, `17 U.S.C. §§ 102(b) & 1201(f)`, `EU RED 2014/53/EU` / `FCC Part 15`), [`GLOSSARY.md`](GLOSSARY.md), and [`AGENTS.md`](AGENTS.md).
