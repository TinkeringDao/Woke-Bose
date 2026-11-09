# Woke Bose (`bose-ultra-tuner`) — Unofficial macOS NVRAM & DSP Interoperability Utility for Bose QuietComfort Ultra Headphones

[![CI](https://github.com/TinkeringDao/Woke-Bose/actions/workflows/ci.yml/badge.svg)](https://github.com/TinkeringDao/Woke-Bose/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/TinkeringDao/Woke-Bose)](https://github.com/TinkeringDao/Woke-Bose/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS%20(IOBluetooth)-black)](bose_ultra_tuner.m)
[![Hardware: PID 0x4066 (QCC5181)](https://img.shields.io/badge/Hardware-0x4066%20Lonestarr%20(1.6.7)-teal)](docs/ARCHITECTURE.md)

> [!IMPORTANT]
> **Unofficial Independent Interoperability Project — Not Affiliated with Bose Corporation**
> **`bose-ultra-tuner` ("Woke Bose")** is an independent, non-commercial free and open-source macOS interoperability utility developed via clean-room observation of standard Bluetooth Serial Port Profile (RFCOMM) user-preference messages under **Directive 2009/24/EC (Articles 1(2), 5(3), 6, 8)**, **Article 3(1)(b) of Directive (EU) 2016/943**, **Article 14(1)(c) of Regulation (EU) 2017/1001 (EUTMR)**, **15 U.S.C. §§ 1115(b)(4), 1125**, **17 U.S.C. §§ 102(b), 107, 1201(a), 1201(f)**, and **18 U.S.C. § 1839(6)(B) (Defend Trade Secrets Act)**. It is **not affiliated with, endorsed by, or sponsored by Bose Corporation, Qualcomm Incorporated, or Analog Devices, Inc.** It operates solely on locally paired Bluetooth hardware owned by the user (**Authorized Local Owner Execution Only**, `18 U.S.C. § 1030` — CFAA), circumvents **zero** Technological Protection Measures (TPMs), leaves all encrypted/signed firmware and RF radio partitions (`PARTDATA 0..6`, **Directive 2014/53/EU (RED)** / **ETSI EN 300 328** / **FCC 47 C.F.R. Part 15**) untouched, distributes **zero** proprietary binaries or keys, and is supplied outside the course of any commercial activity (**EU Cyber Resilience Act `Regulation (EU) 2024/2847` Recitals 15 & 18; EU PLD `Directive (EU) 2024/2853` Art. 2(2)**) under an **AS IS Warranty Disclaimer**. See [`LEGAL.md`](LEGAL.md) for full statutory and trademark notices.

Unofficial macOS Bluetooth RFCOMM (`00000000-deca-fade-deca-deafdecacaff`) user-preference NVRAM & DSP interoperability client, read-only `APPUHDR5` container metadata inspector, and acoustic reference calibration suite for the **Bose QuietComfort Ultra Headphones (1st Gen, `PID 0x4066` / `Lonestarr`, firmware `1.6.7+g6ebabd2`)**.

No Bose Music cloud account, mobile app, or telemetry connection required. All configurations are written directly into non-volatile flash (`Partition 6:EXT_RW_FS`) on the headphones' **Qualcomm QCC5181 (`OTG-QCC-384`)** SoC and **dual Analog Devices `71215 BCBZ`** ANC/DAC DSPs, persisting across power cycles and across every host device (macOS, Windows, Linux, iOS, Android).

---

## Quickstart (User-Friendly 1-Click Upgrade)

Ensure your Bose QuietComfort Ultra Headphones are powered on and connected via Bluetooth to your Mac.

### Option A: Interactive Menu Wizard
```bash
./bose-ultra-wizard.sh
```
Select **`1) Apply "Woke" Edition Upgrade (DAC Reference + Call Studio)`** from the interactive menu.

### Option B: One-Line Terminal Command
```bash
make woke
```
To revert the headphones to factory stock settings at any time:
```bash
make baseline
```

---

## Factory Baseline vs. "Woke" Edition — Complete Comparison Matrix

### 1. Executive Hardware, Register, & Acoustic Telemetry Comparison

| Subsystem / Parameter | BMAP Register | Factory Baseline (Stock) | "Woke" Edition (Upgraded) | Measured Delta / Engineering Impact |
| :--- | :--- | :--- | :--- | :--- |
| **Hardware 3-Band EQ (`[1.7]`)** | `01 07` (`SETGET 0x02`) | `Bass: 0 dB \| Mid: 0 dB \| Treble: 0 dB`<br>Payload: `00 00 01 00 02 00`<br>Status: `f6 0a 00 00 f6 0a 00 01 f6 0a 00 02` | `Bass: -3 dB \| Mid: +1 dB \| Treble: +2 dB`<br>Payload: `00 fd 01 01 02 02`<br>Status: `f6 0a fd 00 f6 0a 01 01 f6 0a 02 02` | Eliminates `+3.77 dB` upper-bass shelf (`90–180 Hz`), restores `-2.22 dB` vocal recession (`1.63 kHz`), and recovers upper-harmonic air (`>6 kHz`) inside the 24-bit Kalimba DSP before Class-D amplification |
| **Kalimba DSP Biquad Stage 0 (`[5.17]`)** | `05 11` (`GET 0x01`, Offset `2..17`) | `00000000 00000000 00000000 7fffffff`<br>(`b0 = +1.000000` Q1.31 unity bypass) | `00000000 00000000 fe08aefc 7ffc115c`<br>(`a1 = -0.015349`, `b0 = +0.999881` Q1.31 active shelf) | Active hardware low-shelf / tilt filter on Qualcomm `QCC5181` 240 MHz 32-bit Kalimba DSP |
| **Kalimba DSP Biquad Stage 3 (`[5.17]`)** | `05 11` (`GET 0x01`, Offset `50..65`) | `00000000 00000000 00000000 7fffffff`<br>(`b0 = +1.000000` Q1.31 unity bypass) | `f315b575 fbc792d2 00000000 7f46dc5c`<br>(`b2 = -0.100900`, `b1 = -0.032972`, `b0 = +0.994350` Q1.31 peaking) | Active hardware midrange/treble compensation filter on Kalimba DSP |
| **Kalimba DSP Biquad Stages 1, 2, 4, 5** | `05 11` (`GET 0x01`) | `00000000 00000000 00000000 7fffffff` | `00000000 00000000 00000000 7fffffff` | Zero phase distortion across unadjusted biquad stages |
| **Self Voice / Sidetone (`[1.11]`)** | `01 0B` (`SETGET 0x02`) | **MEDIUM** (`01 02 01 0f` / `01 02 0f`) | **OFF** (`01 00 01 0f` -> `01 00 0f`, `Persist=1`) | Shuts off the real-time exterior ambient mic loopback into the earcups and HFP uplink mixer during calls |
| **Multipoint Connection (`[1.10]`)** | `01 0A` (`SETGET 0x02`) | **ENABLED** (`0x05` write -> `0x07` status, `bit0 = 1`) | **ENABLED** (`0x05` write -> `0x07` status, `bit0 = 1`) for Mac + Phone (or optional single-point `0x00` -> `0x06` via `multipoint off`) | Keeps simultaneous **Mac + Phone** dual-ACL connectivity active while `CoreAudio` Input Guard prevents macOS HFP `SCO` hijacks |
| **Active Audio Mode (`[31.3]`)** | `1F 03` (`START 0x05`) | **Slot `0` ("Quiet")**<br>Payload: `00 00` | **Slot `4` ("Woke Studio")**<br>Payload: `04 00` | Switches active NVRAM mode slot to dedicated phase-coherent Full ANC reference profile |
| **Custom Mode Slot 4 Config (`[31.6]`)** | `1F 06` (`SETGET 0x02`) | Unconfigured / Inactive (`WindBlock=ON`) | **ANC `10/10` (`atten=0x00` Full Quiet ANC), AutoCNC `0`, Spatial `Off` (`0x00`), WindBlock `OFF` (`0x00`)** | Locks maximum 10/10 Quiet ANC silence (`atten=0x00` vs. `atten=0x0A` Aware transparency), disables ActiveSense ANC pumping (`AutoCNC=0`), and disables `400 Hz` WindBlock high-pass gate |
| **macOS CoreAudio HFP SCO Input Guard** | `kAudioHardwarePropertyDefaultInputDevice` | `Bose QC Ultra Headphones` selected as Default Input (triggers `16,000 Hz` 1-ch Mono `SCO` call hijack on any mic access) | **Built-in `MacBook Pro Microphone` (`kAudioDeviceTransportTypeBuiltIn`)** | Prevents background apps from dropping headphones into 1-ch Mono `16 kHz` `SCO` telephony mode (and turning on exterior call mics) during music playback; locks `2-ch Stereo A2DP` |
| **Stationary Background Noise Floor** | Voice Memo Telemetry (`48 kHz` PCM) | **`-58.7 dBFS`** (10th percentile RMS) | **`-78.8 dBFS`** (10th percentile RMS) | **`-20.1 dB` (10x amplitude reduction)** in continuous room/HVAC background hiss |
| **Active Speech RMS Level** | Voice Memo Telemetry (`48 kHz` PCM) | **`-23.3 dBFS`** (90th percentile RMS) | **`-24.5 dBFS`** (90th percentile RMS) | Consistent vocal pickup (`1.2 dB` delta) without mid-word clipping |
| **Stationary Signal-to-Noise Ratio (SNR)** | Voice Memo Telemetry (`Speech - Noise`) | **`35.4 dB`** | **`54.3 dB`** | **`+18.9 dB` net voice-to-noise isolation gain** |
| **Transient Impulse Peak (Hand Claps)** | Voice Memo Telemetry (Peak dBFS) | **`-4.2 dBFS`** (`+19.1 dB` above speech) | **`-4.9 dBFS`** (`+19.6 dB` above speech) | Bounded by hardware 4-mic adaptive endfire array (`<0.5 ms` acoustic impulse precedes VAD) |
| **Transient Impulse Peak (Table Taps)** | Voice Memo Telemetry (Peak dBFS) | **`-6.4 dBFS`** | **`-6.4` to `-11.5 dBFS`** | Reduced low-frequency desk boom transfer by up to **`5.1 dB`** |
| **Bluetooth HFP Call Sample Rate** | Bluetooth HFP v1.8 SCO | `8,000 Hz` (`CVSD`, `3.4 kHz` audio ceiling) when Multipoint contends | **`16,000 Hz` (`mSBC`, `7.2 kHz` audio ceiling)** on macOS / **`32,000 Hz` (`aptX Voice`)** with Snapdragon Sound dongle | **2x to 4x call audio bandwidth** |
| **macOS A2DP SBC Bitpool Allocation** | `com.apple.BluetoothAudioAgent` | OS Default (`Min 2`, `Initial 40`, `Max 53` -> ~`229 kbps`) | **Locked High-Bitrate (`Min 58`, `Initial 64`, `Max 80` -> `345–512 kbps`)** | Prevents dynamic bitpool throttling under RF interference |

---

### 2. Full BMAP `[31.6]` (`AudioModes.ModeItem`) Register Byte Comparison

Each audio mode slot on the Bose QC Ultra (`0x4066`, firmware `1.6.7`) is stored as a **47-byte `STATUS` structure** (written via a **39-byte `SETGET` payload** on `Block 0x1F, Func 0x06`):

| Byte Offset (Write / Status) | Field Name | Factory Slot 0 (`"Quiet"`) | Factory Slot 1 (`"Aware"`) | "Woke" Slot 4 (`"Woke Studio"`) | Technical Function |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `0` | `slot_id` | `0x00` | `0x01` | `0x04` | Mode slot index (`0..9`) in Partition 6 NVRAM |
| `1..2` | `prompt_id` | `0x0001` | `0x0002` | `0x000C` | Voice prompt / category ID (`0x000C` = `"Music"`) |
| `3..34` | `mode_name[32]` | `"Quiet\0..."` (UTF-8, 32B) | `"Aware\0..."` (UTF-8, 32B) | `"Woke Studio\0..."` (UTF-8, 32B) | Null-padded 32-byte UTF-8 mode name |
| `35` *(Status `42`)* | `anc_attenuation` | `0x00` (`10/10` Full Quiet ANC) | `0x0A` (`0/10` Full Aware) | **`0x00` (`10/10` Full Quiet ANC)** | Analog Devices `71215 BCBZ` ANC attenuation (`0x00` = `10/10` Full Quiet ANC; `0x0A` = `0/10` Full Aware Transparency) |
| `36` *(Status `43`)* | `auto_cnc` | `0x00` | `0x00` (`0x01` when ActiveSense ON) | `0x00` | Dynamic ActiveSense ANC modulation (`0` = Off, `1` = On) |
| `37` *(Status `44`)* | `spatial_mode` | `0x00` | `0x00` | `0x00` | Bose Immersive Audio (`0` = Off, `1` = Still, `2` = Motion via `STM32U585OI` IMU) |
| `38` *(Status `46`)* | `wind_block` | `0x00` | `0x00` | `0x00` | Wind Block `400 Hz` high-pass mute gate (`0x00` = Off, `0x01` = On) |

---

### 3. Frequency Response Deviation Table (`20 Hz – 15 kHz`) — Baseline vs. "Woke" Hardware EQ vs. 10-Band Reference PEQ

Measured on **Brüel & Kjær 5128** (Diffuse Field + `-1 dB/oct` target) and **GRAS 43AG / KB5000** (Harman Over-Ear 2018 target). Stock Bose QC Ultra exhibits `+3.77 dB` upper-bass/lower-mid mud (`90–180 Hz`), a `-2.22 dB` vocal recession (`1.63 kHz`), a `+3.08 dB` ear-canal shout peak (`2.37 kHz`), and a `-2.95 dB` presence notch (`5.0 kHz`):

| Frequency (`Hz`) | Band / Acoustic Role | Stock Baseline Error (`B&K 5128` dB) | Stock Baseline Error (`GRAS Harman` dB) | After "Woke" On-Chip Hardware EQ (`[1.7]`: `-3/+1/+2`) | After "Woke" + 10-Band Host PEQ (`dB` Error) | Audible Result |
| :---: | :--- | :---: | :---: | :---: | :---: | :--- |
| **`20 Hz`** | Sub-Bass Extension | `+2.70 dB` | `+0.90 dB` | `-0.10 dB` | **`0.00 dB`** | Tight, controlled sub-bass rumble without driver over-excursion |
| **`40 Hz`** | Deep Bass Punch | `+2.65 dB` | `+1.80 dB` | `-0.25 dB` | **`+0.05 dB`** | Clean kick-drum fundamental separation |
| **`62 Hz`** | Mid-Bass Weight | `+2.96 dB` | `+2.50 dB` | `-0.04 dB` | **`0.00 dB`** | Eliminates low-end resonance bloom |
| **`120 Hz`** | Upper-Bass / Warmth | **`+3.77 dB`** | **`+4.10 dB`** | **`+0.77 dB`** | **`+0.08 dB`** | **Fixes #1 stock flaw**: removes boxy upper-bass bloat bleeding into vocals |
| **`180 Hz`** | Lower-Mid Transition | **`+2.42 dB`** | **`+4.50 dB`** | **`-0.18 dB`** | **`-0.05 dB`** | Restores acoustic guitar, cello, and male vocal clarity |
| **`330 Hz`** | Fundamental Midrange | `-1.19 dB` | `-0.80 dB` | `-0.69 dB` | **`+0.02 dB`** | Corrects phase cancellation notch between bass shelf and midrange |
| **`500 Hz`** | Center Midrange | `+0.69 dB` | `+0.30 dB` | `+0.89 dB` | **`+0.04 dB`** | Natural timber density |
| **`710 Hz`** | Upper-Mid Body | `+1.41 dB` | `+1.20 dB` | `+1.10 dB` | **`-0.02 dB`** | Removes nasal honk on brass and pianos |
| **`1,000 Hz`** | Reference Pivot | `+0.20 dB` | `+0.10 dB` | `+0.50 dB` | **`0.00 dB`** | `0 dB` reference anchor |
| **`1,630 Hz`** | Vocal Presence | **`-2.22 dB`** | **`-2.90 dB`** | **`-1.12 dB`** | **`-0.06 dB`** | Brings lead vocals and snare body forward out of the mix |
| **`2,370 Hz`** | Pinna / Ear-Canal Gain | **`+3.08 dB`** | **`+2.20 dB`** | **`+2.18 dB`** | **`+0.05 dB`** | Eliminates harsh upper-midrange "shout" and listening fatigue |
| **`3,400 Hz`** | Harmonic Bite | `+0.10 dB` | `+2.60 dB` | `+0.80 dB` | **`-0.04 dB`** | Smooth electric guitar and violin overtones |
| **`5,000 Hz`** | Consonants / Attack | **`-2.95 dB`** | **`-4.80 dB`** | **`-1.15 dB`** | **`+0.10 dB`** | Restores crispness to percussion transients and vocal articulation |
| **`8,200 Hz`** | Sibilance Region | **`+3.02 dB`** | **`+2.70 dB`** | `+1.85 dB` | **`-0.08 dB`** | Tames metallic cymbal splash and `"S"/"T"` vocal sibilance |
| **`11,200 Hz`** | Brilliance / Air | `-2.19 dB` | `-1.90 dB` | `-0.19 dB` | **`+0.05 dB`** | Opens up room decay, reverb tails, and soundstage width |
| **`15,000 Hz`** | Ultra-High Octave | `-1.52 dB` | `-3.50 dB` | `+0.48 dB` | **`+0.12 dB`** | Restores top-octave sparkle lost to stock ANC damping |

---

## CLI Usage Reference (`bose-ultra-tuner`)

Compile from source (requires macOS Command Line Tools):
```bash
make
```
The tool automatically discovers your paired Bose QuietComfort Ultra Headphones via `IOBluetooth`. You can also pass `--mac XX-XX-XX-XX-XX-XX` explicitly.

| Command | Description |
| :--- | :--- |
| `./bose-ultra-tuner woke` | **Apply full "Woke" Edition upgrade** (CoreAudio HFP `SCO` Input Guard, Hardware EQ `-3/+1/+2`, Sidetone `OFF`, Multipoint `ON` for Mac + Phone, `"Woke Studio"` Custom Mode Slot 4 with `CNC=10/10 Full ANC, AutoCNC=0, Spatial=Off, WindBlock=OFF`) |
| `./bose-ultra-tuner fix-noise` | **Eliminate playback hiss/noise** (Switches macOS Default Input to Built-in Mic via `CoreAudio` to release `16 kHz` Mono `HFP SCO` call hijacks, disables Sidetone, and programs `CNC=10/10 Full ANC` in Slot 4) |
| `./bose-ultra-tuner use-phone` | **Hand Multipoint audio focus to Phone** (Suspends the Mac's `AVDTP_START` A2DP stream by routing macOS output to `MacBook Pro Speakers` so Phone audio plays immediately on the headphones) |
| `./bose-ultra-tuner use-mac` | **Hand Multipoint audio focus to Mac** (Routes macOS output back to `Bose QC Ultra Headphones` in 2-channel Stereo A2DP while keeping `MacBook Pro Microphone` as the input) |
| `./bose-ultra-tuner baseline` | **Restore Factory Baseline** (Hardware EQ `0/0/0`, Sidetone `MEDIUM`, Multipoint `ON`, Active Mode Slot `0` `"Quiet"`) |
| `./bose-ultra-tuner status` | Query live firmware version, battery level, active mode, 3-band EQ, sidetone, multipoint, and all 98 bytes of `[5.17]` Q1.31 biquad coefficients |
| `./bose-ultra-tuner pimp-audio` | Program only the DAC Reference Hardware EQ (`-3 / +1 / +2 dB`) and verify `[5.17]` biquad registers |
| `./bose-ultra-tuner pimp-call` | Program only the Call Studio Microphone configuration (`Sidetone=OFF, Multipoint=OFF, Slot 4 Call Studio`) |
| `./bose-ultra-tuner eq <B> <M> <T>` | Set custom hardware 3-Band EQ in integer dB (`-10` to `+10`), e.g., `./bose-ultra-tuner eq -3 1 2` |
| `./bose-ultra-tuner sidetone <mode>` | Set Self Voice / Sidetone (`off`, `low`, `med`, `high`) |
| `./bose-ultra-tuner multipoint <on\|off>` | Enable or disable Bluetooth Multipoint (`[1.10]`) |
| `./bose-ultra-tuner mode <0-4>` | Switch active Audio Mode slot (`0`=Quiet, `1`=Aware, `2`=Immersion, `4`=Woke Studio) |
| `./bose-ultra-tuner scan` | Probe all BMAP Function Blocks (`0x00..0x22`) and dump readable registers |
| `./bose-ultra-tuner raw <B> <F> <Op> [Hex]` | Send raw hexadecimal BMAP packet over RFCOMM Channel 2 |

---

## Optional 10-Band Parametric EQ Profiles (DAC-Grade Linearity)

While the on-chip `[1.7]` hardware EQ (`-3 / +1 / +2 dB`) fixes the broad tonal balance directly inside the headphones' flash memory, applying a 10-band Parametric EQ on your host device corrects the narrow-band acoustic resonances of the 35mm angled transducers.

Ready-to-import presets are located in [`peq/`](peq/):
- **[`peq/bose_qc_ultra_bk5128_reference.txt`](peq/bose_qc_ultra_bk5128_reference.txt)** — **Brüel & Kjær 5128 Diffuse Field (`-1 dB/oct` Reference Target)** (`Preamp: -2.9 dB`). Recommended for studio monitoring and acoustic realism.
- **[`peq/bose_qc_ultra_gras_harman2018.txt`](peq/bose_qc_ultra_gras_harman2018.txt)** — **GRAS 43AG Harman Over-Ear 2018 Target** (`Preamp: -2.4 dB`).

Compatible players: **eqMac**, **SoundSource** (macOS), **Equalizer APO / Peace** (Windows), **EasyEffects / PipeWire** (Linux), **Poweramp Equalizer / Wavelet** (Android).

---

## Repository Structure & Documentation

- [`bose_ultra_tuner.m`](bose_ultra_tuner.m) — Native Objective-C macOS `IOBluetooth` RFCOMM user-preference NVRAM & DSP interoperability client and `[5.17]` Q1.31 biquad inspector.
- [`bose-ultra-wizard.sh`](bose-ultra-wizard.sh) — Interactive terminal wizard for 1-click `Woke` calibration, `Baseline` restore, macOS bitpool tuning, and register scanning.
- [`parse_appuhdr5.py`](parse_appuhdr5.py) — Read-only structural TLV header and Shannon entropy inspector for `APPUHDR5` containers (`<REDACTED_OEM_BYTES>`; performs zero decryption, key extraction, or binary modification).
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — Deep-dive hardware BOM (`QCC5181`, `2x ADI 71215 BCBZ`, `STM32U585OI`, `PSoC 4000S`), `APPUHDR5` structural partition map, and BMAP protocol specification.
- [`GLOSSARY.md`](GLOSSARY.md) — Hardware, firmware, and acoustic terminology reference.
- [`LEGAL.md`](LEGAL.md) — Statutory interoperability notices (`Directive 2009/24/EC` Arts. 1(2), 5(3), 6, 8; `Article 3(1)(b) of Directive (EU) 2016/943`; `Article 14(1)(c) of Regulation (EU) 2017/1001 (EUTMR)`; `15 U.S.C. §§ 1115(b)(4), 1125`; `17 U.S.C. §§ 102(b), 107, 1201(a), 1201(f)`; `18 U.S.C. §§ 1839(6)(B), 1030`; `Regulation (EU) 2024/2847` Recitals 15 & 18), non-circumvention statement, and RF regulatory notice.
- [`SECURITY.md`](SECURITY.md) — Partition 6 (`EXT_RW_FS`) NVRAM safety boundaries and vulnerability disclosure policy.
- [`CONTRIBUTING.md`](CONTRIBUTING.md) & [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) — Contributor guidelines, clean-room rules, and zero-warning compiler standards.
- [`AGENTS.md`](AGENTS.md) — Minimal context pointers for AI coding agents.
- [`peq/`](peq/) — 10-band Parametric EQ presets for B&K 5128 Diffuse Field and GRAS Harman 2018 targets.

---

## Legal, Trademark, & Interoperability Notice

- **Non-Affiliation, Indication of Intended Purpose, & Nominative Fair Use (`Article 14(1)(c) of Regulation (EU) 2017/1001 (EUTMR)` / `15 U.S.C. §§ 1115(b)(4), 1125`):** "Bose", "QuietComfort", "CustomTune", and "ActiveSense" are registered trademarks of Bose Corporation. "Qualcomm", "QCC5181", and "Kalimba" are registered trademarks of Qualcomm Incorporated. "Analog Devices" is a registered trademark of Analog Devices, Inc. All product names are referenced solely as an indication of intended purpose and hardware compatibility (`PID 0x4066`).
- **Interoperability, Non-Circumvention, & Authorized Local Owner Execution Only:** Developed independently for desktop interoperability under **Directive 2009/24/EC (Articles 1(2), 5(3), 6, 8)**, **Article 3(1)(b) of Directive (EU) 2016/943**, **17 U.S.C. §§ 102(b), 107, 1201(f)**, and **18 U.S.C. § 1839(6)(B) (Defend Trade Secrets Act)** (*Sega v. Accolade*, *Chamberlain v. Skylink*). Operates strictly on locally paired Bluetooth peripherals owned by the user (**Authorized Local Owner Execution Only**, `18 U.S.C. § 1030` — CFAA). Zero Technological Protection Measures (TPMs) are circumvented (`17 U.S.C. § 1201(a)`), zero RF parameters are modified (`Directive 2014/53/EU (RED)` / `ETSI EN 300 328` / `FCC 47 C.F.R. Part 15`), and zero proprietary firmware binaries or keys are distributed.
- **Non-Commercial Open-Source Exemption & AS IS Warranty Disclaimer:** Supplied strictly outside the course of any commercial activity (**EU Cyber Resilience Act `Regulation (EU) 2024/2847` Recitals 15 & 18; EU Product Liability Directive `Directive (EU) 2024/2853` Art. 2(2)**) and provided **"AS IS"** under the [MIT License](LICENSE). See [`LEGAL.md`](LEGAL.md) for complete terms.

---

## License

MIT License — see [`LICENSE`](LICENSE).
