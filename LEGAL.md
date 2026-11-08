# Legal, Trademark, & Interoperability Notice

## 1. Independent Interoperability Project & Non-Affiliation (Trademark Notice)

**Woke Bose (`bose-ultra-tuner`)** is an **independent, unofficial, community-developed open-source software project** created solely to enable desktop interoperability and user-preference configuration on macOS (where no official desktop companion application exists).

- **No Affiliation or Endorsement:** This project is **not affiliated with, authorized by, sponsored by, or endorsed by Bose Corporation, Qualcomm Incorporated, Analog Devices, Inc., STMicroelectronics, Infineon Technologies AG, or Apple Inc.**
- **Nominative Fair Use (US Lanham Act / EU Regulation 2017/1001 Art. 14(1)(c) / German § 23 Nr. 3 MarkenG):**
  - "Bose", "QuietComfort", "CustomTune", "ActiveSense", and "Immersion" are registered trademarks or trademarks of **Bose Corporation**.
  - "Qualcomm", "QCC5181", "Kalimba", "Snapdragon Sound", and "aptX" are registered trademarks or trademarks of **Qualcomm Incorporated**.
  - "Analog Devices" is a registered trademark of **Analog Devices, Inc.**
  - "macOS" and "CoreAudio" are registered trademarks of **Apple Inc.**
  - All third-party product names, trademarks, and hardware identifiers (`PID 0x4066`) are referenced strictly for **nominative and descriptive fair use** to identify hardware compatibility. No third-party logos, trade dress, or brand assets are included in this repository.

---

## 2. Statutory Interoperability & Protocol Observation Rights

All source code and documentation in this repository were developed independently via clean-room, black-box observation of standard Bluetooth Serial Port Profile (SPP / RFCOMM) communication with lawfully owned hardware:

1. **European Union & Germany (`Directive 2009/24/EC` & `Directive (EU) 2016/943`):**
   - **Article 5(3) of Directive 2009/24/EC (`§ 69d Abs. 3 UrhG`):** Permits the lawful owner/user of a device or computer program to observe, study, and test its functioning without prior authorization in order to determine the underlying ideas, principles, and protocol framing.
   - **Article 6 of Directive 2009/24/EC (`§ 69e UrhG`):** Permits independent analysis necessary to achieve the **interoperability** of an independently created computer program (`bose-ultra-tuner` for macOS) with existing hardware and software.
   - **Mandatory Statutory Protection (`Article 8 of Directive 2009/24/EC` / `§ 69g Abs. 2 UrhG`):** Under European and German law, contractual or End-User License Agreement (EULA) provisions that purport to restrict observation or interoperability under `§ 69d Abs. 3` and `§ 69e UrhG` are **null and void by statute**.
   - **Article 3(1)(b) of Directive (EU) 2016/943 (`§ 3 Abs. 1 Nr. 2 GeschGehG`):** Explicitly recognizes the lawful acquisition of technical information through observation, study, and testing of a lawfully acquired product in the owner's possession.
2. **United States (`17 U.S.C. § 1201(f)` & Fair Use `17 U.S.C. § 107`):**
   - Developed exclusively for the purpose of achieving **interoperability** of an independently created computer program with lawfully owned consumer hardware under **17 U.S.C. § 1201(f)** and established federal precedent (*Sega Enterprises Ltd. v. Accolade, Inc.*, 977 F.2d 1510 (9th Cir. 1992)).

---

## 3. Non-Circumvention of Technological Protection Measures (TPMs)

This software **does not circumvent, bypass, decrypt, or defeat any Technological Protection Measure (TPM)** under `17 U.S.C. § 1201(a)` or `§ 95a UrhG`:

- **No Firmware Modification or Patching:** Executable boot, application, and DSP partitions (`Partitions 0..5`) on the `QCC5181` SoC are protected by hardware secure boot (`OTP_PROD = 0x0001`, `2048-bit` RSA-PSS signatures, and AES-128-CTR encryption). This project **never modifies, decrypts, patches, or flashes** any firmware partition.
- **No Cryptographic Key Extraction or Bypass:** This repository contains **zero cryptographic keys, certificates, seeds, or authentication bypasses**.
- **Standard Plaintext Bluetooth SPP User Preferences Only:** `bose-ultra-tuner` communicates exclusively over standard Bluetooth RFCOMM Channel 2 using the device's native, plaintext `GET (0x01)`, `SETGET (0x02)`, and `START (0x05)` user-preference messages (3-band EQ, sidetone level, multipoint toggle, and ANC mode selection)—the exact same user-configurable parameters exposed in everyday operation.

---

## 4. Zero Proprietary Code or Binary Distribution

- **100% Original Source Code:** Every line of Objective-C ([`bose_ultra_tuner.m`](bose_ultra_tuner.m)), Python ([`parse_appuhdr5.py`](parse_appuhdr5.py)), and Shell ([`bose-ultra-wizard.sh`](bose-ultra-wizard.sh)) in this repository is original work licensed under the [MIT License](LICENSE).
- **No OEM Binaries or Assets:** This repository does **not** host, redistribute, or link to any proprietary Bose firmware images (`.bin`, `.dfu`), mobile application packages (`.ipa`, `.apk`), or decompiled vendor source code.

---

## 5. Warranty, Hardware Risk, & Acoustic Safety Disclaimer

THE SOFTWARE AND DOCUMENTATION ARE PROVIDED **"AS IS"**, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT (SEE [`LICENSE`](LICENSE)).

- **Owner's Sole Risk:** Communicating with hardware registers over Bluetooth RFCOMM is performed entirely at the user's own risk. While all user-preference changes in Partition 6 (`EXT_RW_FS`) are reversible via `./bose-ultra-tuner baseline`, the authors assume no liability for hardware malfunction, unexpected firmware behavior, or warranty disputes.
- **Hearing & Acoustic Safety:** Modifying Equalizer (`EQ`) gain stages, Active Noise Cancellation (`CNC`), or Sidetone levels alters acoustic output. Always verify playback volume at a low level before placing headphones on your ears.
