# Bose QuietComfort Ultra (`0x4066` `Lonestarr`) — Hardware, Firmware & BMAP Architecture

See [`GLOSSARY.md`](../GLOSSARY.md) for canonical domain definitions.

---

## 1. Silicon Bill of Materials & End-to-End Audio Pipeline

The Bose QuietComfort Ultra Headphones (`PID 0x4066` / `16486`, codename `Lonestarr`, platform `OTG-QCC-384`) split processing across four distinct ICs:

```text
[Bluetooth 5.3 A2DP (aptX Lossless 16/44.1, aptX Adaptive 24/48, AAC, SBC)]
   OR [2.5mm Analog Line-In -> Integrated 24-bit/48kHz ADC (Clips > 1.0 Vrms)]
       │
       ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 1. Qualcomm QCC5181 (S5 Gen 2 Sound Platform — "OTG-QCC-384")           │
│    ├─ Apps P0 (80 MHz 32-bit): Bluetooth 5.3 baseband, A2DP/eSCO TDM    │
│    ├─ Apps P1 (80 MHz 32-bit): Bose BMAP server, NVRAM PS Keys (Part 6) │
│    └─ Dual 240 MHz 32-bit Kalimba DSPs (1.4 MB Data RAM / 384 KB PRAM): │
│        ├─ 6-Stage Q1.31 Hardware Biquad Bank ([5.17] driven by [1.7])   │
│        ├─ CustomTune ear-canal transfer-function calibration            │
│        ├─ 3-Mic Qualcomm cVc uplink beamformer & spectral subtraction   │
│        └─ Bose Immersive Audio HRTF convolution (fed by STM32U585OI)    │
└──────┬──────────────────────────────────────────────────────────────────┘
       │ 24-bit / 48 kHz Digital TDM / I2S Bus
       ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 2. Dual Analog Devices Custom ANC DSPs (2x ADI "71215 BCBZ")            │
│    ├─ Ingests 12 MEMS Microphones (6 per earcup: FF, FB, & voice array) │
│    ├─ Microsecond-latency Feedforward + Feedback anti-noise synthesis   │
│    ├─ Aware Mode / ActiveSense dynamic transparency mixing              │
│    └─ 24-bit Differential DAC + Class-D Amplification                   │
└──────┬──────────────────────────────────────────────────────────────────┘
       │ Differential Analog Drive
       ▼
[Left & Right 35mm Angled Dynamic Transducers]

Supporting Controllers:
  3. STMicroelectronics STM32U585OI (ARM Cortex-M33 + FPU + TrustZone):
     Power rail sequencing & 6-axis IMU sensor fusion for Immersive Audio.
  4. Infineon PSoC 4000S:
     Capacitive volume strip (button_id = 0x80) & on-head proximity sensing.
```

---

## 2. `APPUHDR5` Firmware Container Anatomy (`1.6.7+g6ebabd2`)

Clean-room structural specification of the Qualcomm `APPUHDR5` TLV container layout (total container size `7,075,178` bytes / `0x6bf56a`; all proprietary payload bytes, cryptographic nonces, and signature bytes are redacted as `<REDACTED_OEM_BYTES>` — zero proprietary binaries are hosted or distributed in this repository).

Structural geometry verified via [`parse_appuhdr5.py`](../parse_appuhdr5.py):

| Chunk / Index | File Offset | Part ID | Qualcomm ADK Role (`IMAGE_SECTION_ID`) | Payload Bytes | 16B AES Blocks | Shannon Entropy | Structural Layout & Security Boundary (`<REDACTED_OEM_BYTES>`) |
| :--- | :--- | :--- | :--- | ---: | ---: | ---: | :--- |
| **`APPUHDR5`** | `0x000000` | Header | `"VR:" + [u8x3] + "PRODUCT:" + [ASCIIZ] + "OTP_PROD" + [u16be=0x0001]` | `34` | N/A | Plaintext | `[8B Magic "APPUHDR5"][4B Len] <REDACTED_OEM_BYTES>` |
| **`PARTDATA` 0** | `0x00002e` | `0x0000` | `IMAGE_SECTION_NONCE` (128-bit AES-CTR IV) | `16` | `1` | `3.875000` | `[2B Type][2B PartID] <REDACTED_OEM_NONCE>` |
| **`PARTDATA` 1** | `0x00004e` | `0x0001` | `IMAGE_SECTION_APPS_P0_HEADER` (Flash layout & hash table) | `560` | `35` | `7.669410` | `[2B Type][2B PartID] <REDACTED_OEM_BYTES>` (AES-128-CTR) |
| **`PARTDATA` 2** | `0x00028e` | `0x0004` | `IMAGE_SECTION_CURATOR_FILESYSTEM` (Radio/boot patches) | `4,672` | `292` | `7.959534` | `[2B Type][2B PartID] <REDACTED_OEM_BYTES>` (AES-128-CTR) |
| **`PARTDATA` 3** | `0x0014de` | `0x0005` | `IMAGE_SECTION_APPS_P0_IMAGE` (Qualcomm BT/system stack) | `592,256` | `37,016` | `7.999712` | `[2B Type][2B PartID] <REDACTED_OEM_BYTES>` (AES-128-CTR) |
| **`PARTDATA` 4** | `0x091e6e` | `0x0006` | `IMAGE_SECTION_APPS_RO_CONFIG_FILESYSTEM` (PS Keys / config) | `93,712` | `5,857` | `7.997897` | `[2B Type][2B PartID] <REDACTED_OEM_BYTES>` (AES-128-CTR) |
| **`PARTDATA` 5** | `0x0a8c8e` | `0x0007` | `IMAGE_SECTION_APPS_RO_FILESYSTEM` (Kalimba `.kap` DSP & ANC) | `4,266,464` | `266,654` | `7.999958` | `[2B Type][2B PartID] <REDACTED_OEM_BYTES>` (AES-128-CTR) |
| **`PARTDATA` 6** | `0x4ba67e` | `0x0009` | `IMAGE_SECTION_APPS_P1_IMAGE` (Bose application & BMAP server) | `2,117,072` | `132,317` | `7.999904` | `[2B Type][2B PartID] <REDACTED_OEM_BYTES>` (AES-128-CTR) |
| **`APPUPFTR`** | `0x6bf45e` | Footer | 2048-bit (`256 B`) RSA-PSS signature verified against OTP eFuse | `256` | N/A | `7.197566` | `[8B Magic "APPUPFTR"][4B Len] <REDACTED_OEM_SIGNATURE>` |

### Why Direct Bluetooth SPP User-Preference Configuration Leaves Signed Firmware Untouched
Because `OTP_PROD = 0x0001` enforces hardware AES-128-CTR encryption across all `442,172` blocks (`7.9999` bits/byte entropy) and verifies the `2048-bit` RSA-PSS footer inside the `QCC5181` Mask ROM before commit, executable code partitions (`0..5`) are cryptographically immutable. For host interoperability, the running `Apps P1` firmware exposes standard plaintext `GET` (`0x01`), `SETGET` (`0x02`), and `START` (`0x05`) user-preference messages over Bluetooth RFCOMM Channel 2 (`00000000-deca-fade-deca-deafdecacaff`), configuring the headphone's persistent user-settings NVRAM (`Partition 6` PS Keys) and active Kalimba DSP EQ registers without modifying or circumventing any signed firmware partition.

---

## 3. On-Device BMAP Function Blocks & Register Map (`0x4066` `Lonestarr`)

Enumerated live from hardware via `./bose-ultra-tuner scan`:

### 3.1 Supported Function Blocks (`0x00`–`0x1F`)
- `0x00` (`ProductInfo` v1.1.0)
- `0x01` (`Settings` v1.1.0)
- `0x02` (`Status` v1.1.0)
- `0x03` (`FirmwareUpdate` v1.2.0)
- `0x04` (`DeviceManagement` v1.1.0)
- `0x05` (`AudioManagement` v1.1.0)
- `0x06` (`CallManagement` v1.1.0)
- `0x07` (`Control` v1.1.0)
- `0x09` (`Notification` v1.1.0)
- `0x0D` (`DataCollection` v1.1.0)
- `0x12` (`Authentication` v1.1.0 — Cloud ECDH P-384)
- `0x1F` (`AudioModes` v1.0.0)

### 3.2 `AudioManagement [5.17]` (`0x05, 0x11`) — 6-Stage Q1.31 Hardware Biquad Table
`GET` `05 11 01 00` returns `98` bytes (`00 06` header + `6 x 16-byte` signed Q1.31 fixed-point biquad stages where `0x7fffffff` = `+1.0` unity gain):

```text
Header : 00 06 (6 Biquad Stages)
Stage 0: 00000000 00000000 fe08aefc 7ffc115c  <- Low-shelf biquad driven by [1.7] Bass
Stage 1: 00000000 00000000 00000000 7fffffff  <- Unity bypass (1.0)
Stage 2: 00000000 00000000 00000000 7fffffff  <- Unity bypass (1.0)
Stage 3: f315b575 fbc792d2 00000000 7f46dc5c  <- Mid/High biquad driven by [1.7] Mid/Treble
Stage 4: 00000000 00000000 00000000 7fffffff  <- Unity bypass (1.0)
Stage 5: 00000000 00000000 00000000 7fffffff  <- Unity bypass (1.0)
```
*(Direct `SETGET` writes to `[5.17]` return `BMAP ERROR 0x05 OpNotSupp`; the Kalimba DSP recomputes `[5.17]` automatically whenever `[1.7]` `Settings.RangeControl` is updated via `01 07 02 02 <val:i8> <band:u8>`).*
