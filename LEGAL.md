# Legal, Trademark, & Interoperability Notice

## 1. Independent Interoperability Project & Non-Affiliation (Trademark Notice)

**`bose-ultra-tuner` ("Woke" Edition) — Unofficial macOS NVRAM & DSP Interoperability Utility for Bose QuietComfort Ultra Headphones** is an **independent, non-commercial, community-developed free and open-source software project** created solely to enable desktop host interoperability and user-preference configuration on macOS (where no official desktop companion application is provided).

- **No Affiliation or Endorsement:** This project is **not affiliated with, authorized by, sponsored by, or endorsed by Bose Corporation, Qualcomm Incorporated, Analog Devices, Inc., STMicroelectronics, Infineon Technologies AG, or Apple Inc.**
- **Indication of Intended Purpose & Nominative Fair Use:**
  - Pursuant to **Article 14(1)(c) of Regulation (EU) 2017/1001 (EU Trade Mark Regulation — EUTMR)**, settled Court of Justice of the European Union jurisprudence (*Case C-228/03 — Gillette v. LA-Laboratories*; *Case C-63/97 — BMW v. Deenik*), and **US Nominative Fair Use (`15 U.S.C. §§ 1115(b)(4), 1125`**, *New Kids on the Block v. News America Publishing, Inc.*, 971 F.2d 302 (9th Cir. 1992)), third-party trademarks are referenced strictly as a necessary indication of intended purpose, nominative fair use, and hardware compatibility of this independent utility:
    - "Bose", "QuietComfort", "CustomTune", "ActiveSense", and "Immersion" are registered trademarks or trademarks of **Bose Corporation**.
    - "Qualcomm", "QCC5181", "Kalimba", "Snapdragon Sound", and "aptX" are registered trademarks or trademarks of **Qualcomm Incorporated**.
    - "Analog Devices" is a registered trademark of **Analog Devices, Inc.**
    - "macOS" and "CoreAudio" are registered trademarks of **Apple Inc.**
  - Zero corporate logos, icons, mobile application screenshots, or proprietary trade dress are included in this repository.

---

## 2. Statutory Interoperability, Uncopyrightable Functional Facts, & Trade Secret Law

All source code and protocol documentation in this repository were developed independently via clean-room, black-box observation of standard Bluetooth Serial Port Profile (SPP / RFCOMM) communication with lawfully acquired hardware owned by the user:

### 2.1 European Union (`Directive 2009/24/EC` & `Directive (EU) 2016/943`)
1. **Exclusion of Functional Protocols & Interfaces from Copyright (`Article 1(2) of Directive 2009/24/EC`):**
   - Under `Article 1(2) of Directive 2009/24/EC` and settled Court of Justice of the European Union precedent (*SAS Institute Inc. v. World Programming Ltd*, Case `C-406/10`, paras. 39–46), ideas, principles, functional interfaces, data formats, and command protocols (`[FunctionBlock, FunctionId, Operator, Length, Payload]`) are **excluded from copyright protection**.
2. **Right to Observe, Study, and Test (`Article 5(3) of Directive 2009/24/EC`):**
   - Permits the lawful owner or user of a device or computer program to observe, study, and test its functioning without prior authorization in order to determine the underlying ideas, principles, and packet framing during normal use.
3. **Mandatory Right of Interoperability (`Article 6 of Directive 2009/24/EC`):**
   - Permits independent analysis necessary to achieve the **interoperability** of an independently created computer program (`bose-ultra-tuner` for macOS) with existing hardware and software where interface specifications were not previously published.
4. **Statutory Nullity of Contrary EULA Provisions (`Article 8 of Directive 2009/24/EC`):**
   - Under mandatory European Union law (`Article 8 of Directive 2009/24/EC`), any contractual or End-User License Agreement (EULA) clauses purporting to waive or restrict rights under `Article 5(3)` or `Article 6 of Directive 2009/24/EC` are **statutorily null and void**.
5. **Lawful Hardware Reverse Engineering (`Article 3(1)(b) of Directive (EU) 2016/943`):**
   - Under **Article 3(1)(b) of Directive (EU) 2016/943**, obtaining technical information by observing, studying, disassembling, or testing a product that has been made available to the public or that is lawfully in the possession of the acquirer of the information (who is free from any legally valid duty to limit the acquisition of the trade secret) is expressly declared a **lawful acquisition**.

### 2.2 United States (`17 U.S.C. §§ 102(b), 107, 1201(f)` & `18 U.S.C. §§ 1839(6)(B), 1030`)
1. **Uncopyrightable Methods of Operation & Merger (`17 U.S.C. § 102(b)`):**
   - Numeric BMAP function blocks, opcodes, register offsets, and Q1.31 biquad filter coefficients constitute uncopyrightable systems, methods of operation, and functional facts necessary for compatibility (*Baker v. Selden*, 101 U.S. 99 (1879); *Google LLC v. Oracle America, Inc.*, 593 U.S. 1 (2021); *Lexmark Int'l, Inc. v. Static Control Components, Inc.*, 387 F.3d 522 (6th Cir. 2004)).
2. **Interoperability Exemptions (`17 U.S.C. § 1201(f)`, `17 U.S.C. § 107`, & `37 C.F.R. § 201.40`):**
   - Developed exclusively for achieving interoperability of an independently created computer program with lawfully owned consumer hardware (*Sega Enterprises Ltd. v. Accolade, Inc.*, 977 F.2d 1510 (9th Cir. 1992); *Sony Computer Entertainment, Inc. v. Connectix Corp.*, 203 F.3d 596 (9th Cir. 2000); *The Chamberlain Group, Inc. v. Skylink Technologies, Inc.*, 381 F.3d 1178 (Fed. Cir. 2004)).
3. **Defend Trade Secrets Act Reverse-Engineering Safe Harbor (`18 U.S.C. § 1839(6)(B)`):**
   - Under the Defend Trade Secrets Act (`18 U.S.C. § 1839(6)(B)`), reverse engineering, independent derivation, and clean-room observation of a lawfully acquired product on the open market are explicitly excluded from the definition of "improper means".
4. **Authorized Local Owner Execution (`18 U.S.C. § 1030` — CFAA):**
   - Under *Van Buren v. United States*, 593 U.S. 374 (2021), this utility executes 100% locally on the hardware owner's computer and communicates over personal Bluetooth with the owner's own peripheral. Zero manufacturer cloud servers, remote APIs, or restricted network endpoints are accessed.

---

## 3. Non-Circumvention of Technological Protection Measures (`Directive 2009/24/EC` & `17 U.S.C. §§ 1201(a), 1201(f)`)

Under **Directive 2009/24/EC (Articles 1(2), 5(3), 6, 8)** and **17 U.S.C. §§ 1201(a), 1201(f)**, this software **does not circumvent, bypass, decrypt, or defeat any Technological Protection Measure (TPM)**:

- **Zero Firmware Modification or Patching:** Executable boot, radio, application, and DSP partitions (`Partitions 0..5`) on the `QCC5181` SoC are protected by hardware secure boot (`OTP_PROD = 0x0001`, `2048-bit` RSA-PSS signatures, and AES-128-CTR encryption). This project **never modifies, decrypts, patches, or flashes** any firmware partition.
- **Zero Cryptographic Key Extraction or Handshake Bypass:** This repository contains **zero cryptographic keys, nonces, certificates, seeds, or authentication bypasses**, and never interacts with `FunctionBlock 0x12` (cloud ECDH).
- **Standard Plaintext Bluetooth SPP User Preferences Only:** `bose-ultra-tuner` communicates exclusively over standard Bluetooth RFCOMM Channel 2 using the device's native, plaintext `GET (0x01)`, `SETGET (0x02)`, and `START (0x05)` user-preference messages (3-band EQ, sidetone level, multipoint toggle, and ANC mode selection)—the exact same user-configurable parameters exposed in everyday operation.

---

## 4. Zero Proprietary Code, Verbatim Firmware Bytes, or Binary Distribution

- **100% Original Clean-Room Source Code:** Every line of Objective-C ([`bose_ultra_tuner.m`](bose_ultra_tuner.m)), Python ([`parse_appuhdr5.py`](parse_appuhdr5.py)), and Shell ([`bose-ultra-wizard.sh`](bose-ultra-wizard.sh)) in this repository is original work licensed under the [MIT License](LICENSE).
- **No OEM Binaries, Hex Slices, or Assets:** This repository does **not** host, redistribute, or link to any proprietary firmware images (`.bin`, `.dfu`), mobile application packages (`.ipa`, `.apk`), app screenshots, decompiled vendor source code, or verbatim firmware hex slices (`<REDACTED_OEM_BYTES>`).
- **Read-Only Structural Format Inspector (`parse_appuhdr5.py`):** [`parse_appuhdr5.py`](parse_appuhdr5.py) is a passive diagnostic script that inspects outer TLV container geometry, partition alignment, and Shannon entropy on a user-supplied file to verify `OTP_PROD` hardware encryption boundaries; it redacts all payload/signature bytes (`<REDACTED_OEM_BYTES>`) and performs zero decryption or modification.

---

## 5. Authorized Local Owner Execution Only (`18 U.S.C. § 1030` — CFAA)

In accordance with the **Computer Fraud and Abuse Act (`18 U.S.C. § 1030` — CFAA)** (*Van Buren v. United States*, 593 U.S. 374 (2021)):

- **No Access-Security Circumvention:** This software is neither designed nor adapted to bypass any authentication barrier or intercept non-public transmissions. It operates exclusively on Bluetooth devices that have already been locally paired and authorized by the physical hardware owner via standard macOS `IOBluetooth` pairing.
- **Authorized Local Owner Execution Only:** All BMAP `SETGET (0x02)` and `START (0x05)` commands sent by this utility modify only the user-preference NVRAM settings (`Partition 6:EXT_RW_FS`) of hardware owned or lawfully controlled by the operator. Executing this software against third-party devices without the explicit authorization of the hardware owner is strictly prohibited.

---

## 6. Non-Commercial Open-Source Software Notice (EU CRA `Regulation (EU) 2024/2847` & EU PLD `Directive (EU) 2024/2853` Exemption)

- **EU Cyber Resilience Act Exemption (`Regulation (EU) 2024/2847`, Recitals 15 & 18; `Art. 2(5)`):** This repository is developed, maintained, and supplied strictly as **non-commercial free and open-source software outside the course of any commercial activity**. No fee is charged, no paid support or commercial services are offered, and no personal data is collected or monetized. Accordingly, the authors are neither "manufacturers" (`Art. 3(13)`) nor "open-source software stewards" (`Art. 3(14)`), and CE-marking (`Art. 28`) and commercial manufacturer obligations under Regulation (EU) 2024/2847 do not apply.
- **EU Product Liability Directive Exemption (`Directive (EU) 2024/2853`, `Art. 2(2)` & Recitals 14, 15, 24):** Pursuant to **Article 2(2)** and **Recitals 14–15 of Directive (EU) 2024/2853**, this Directive does not apply to free and open-source software developed or supplied outside the course of a commercial activity. Any third party who integrates, bundles, or redistributes this software in the course of a commercial activity does so solely under their own legal and regulatory responsibility as a manufacturer.

---

## 7. Radio Frequency (RF) & Regulatory Compliance (`Directive 2014/53/EU (RED)` / `ETSI EN 300 328` / `FCC 47 C.F.R. Part 15`)

This software **does not modify, recalibrate, or override any radio frequency (RF) parameters**, Bluetooth transmit power tables (EIRP), carrier frequencies (`2.402–2.480 GHz`), frequency-hopping algorithms (`FHSS`), or spectral masks governed by **Directive 2014/53/EU (RED)**, **ETSI EN 300 328**, **ERC/REC 70-03**, **Decision (EU) 2017/1483**, or **FCC 47 C.F.R. Part 15**:

- On the Qualcomm `QCC5181` (`OTG-QCC-384`), all RF subsystem patches and Bluetooth 5.3 baseband parameters reside inside cryptographically signed, hardware-encrypted partitions **`PARTDATA 2` (`IMAGE_SECTION_CURATOR_FILESYSTEM`, Part ID `0x0004`)** and **`PARTDATA 3` (`IMAGE_SECTION_APPS_P0_IMAGE`, Part ID `0x0005`)**.
- `bose-ultra-tuner` communicates exclusively with the `Apps P1` user-preference server via standard macOS `IOBluetooth` APIs, leaving the certified RF characteristics of both the host computer and the headphones completely unmodified.

---

## 8. AS IS Warranty Disclaimer, Hardware Risk, & Acoustic Safety Notice

THE SOFTWARE AND DOCUMENTATION ARE PROVIDED **"AS IS"**, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT (SEE [`LICENSE`](LICENSE)).

- **Owner's Sole Risk:** Communicating with hardware registers over Bluetooth RFCOMM is performed entirely at the user's own risk. While all user-preference changes in Partition 6 (`EXT_RW_FS`) are reversible via `./bose-ultra-tuner baseline`, the authors assume no liability for hardware malfunction, unexpected behavior, or warranty disputes.
- **Hearing & Acoustic Safety:** Modifying Equalizer (`EQ`) gain stages, Active Noise Cancellation (`CNC`), or Sidetone levels alters acoustic output. Always verify playback volume at a low level before placing headphones on your ears.

---

## Addendum: German Statutory References (Applicable to Residents of Germany)

Where German national law applies alongside European Union regulations and directives, the following national statutory provisions govern this repository:

- **Trademark Indication of Intended Purpose (`§ 23 Abs. 1 Nr. 3 MarkenG` — *Bestimmungsangabe*):** Section 23(1) No. 3 of the German Trademark Act (*Markengesetz*, implementing `Art. 14(1)(c) EUTMR`; BGH `I ZR 6/10`) permits the use of third-party trademarks and product designations where necessary to indicate the intended purpose of accessories or interoperable software, provided such use accords with honest practices in industrial or commercial matters.
- **Software Interoperability & Uncopyrightable Interfaces (`§§ 69a Abs. 2 & 5, 69d Abs. 3, 69e, 69f Abs. 2, 69g Abs. 2, 95a UrhG`):** Under the German Copyright Act (*Urheberrechtsgesetz*, implementing `Directive 2009/24/EC`):
  - `§ 69a Abs. 2 Satz 2 UrhG` excludes ideas, principles, and functional interfaces underlying a computer program from copyright protection.
  - `§ 69d Abs. 3 UrhG` entitles the lawful user to observe, study, or test the functioning of a program to determine its underlying ideas and principles.
  - `§ 69e UrhG` authorizes independent analysis necessary to achieve the interoperability of an independently created computer program.
  - `§ 69g Abs. 2 UrhG` renders any contractual or EULA clauses contrary to `§ 69d Abs. 2, 3` or `§ 69e UrhG` statutorily null and void (*nichtig*).
  - `§ 69a Abs. 5 UrhG` (*lex specialis*) excludes computer programs from general technological protection measure rules (`§ 95a UrhG`), and this project circumvents zero technical protection mechanisms (`§ 69f Abs. 2 UrhG`).
- **Reverse Engineering of Lawfully Acquired Hardware (`§ 3 Abs. 1 Nr. 2 lit. a & b GeschGehG`):** Section 3(1) No. 2 of the German Trade Secrets Act (*Geschäftsgeheimnisgesetz*, implementing `Article 3(1)(b) of Directive (EU) 2016/943`) expressly authorizes obtaining technical information by observing, examining, disassembling, or testing a product that has been made publicly available (`lit. a`) or is in the lawful possession of the observer (`lit. b`).
- **German IT Criminal Law & Property Ownership (`§§ 202a–202c, 303a StGB`, `§ 903 BGB`):** Under the German Criminal Code (*Strafgesetzbuch*, as interpreted by the Federal Constitutional Court, *BVerfG, 2 BvR 2233/07*) and Section 903 of the German Civil Code (*Bürgerliches Gesetzbuch*):
  - No access security mechanism (*Zugangssicherung*) is bypassed (`§§ 202a, 202c StGB`) and no non-public transmission is intercepted (`§ 202b StGB`).
  - All configuration operations modify exclusively the physical owner's (`§ 903 BGB`) own local device data (*eigene Daten*, `§ 303a StGB`).
- **Radio Equipment & Spectrum Regulations (`FuAG`, `BNetzA Vfg 99/2022`, `AFuG` / `AFuV`):** Under the German Radio Equipment Act (*Funkanlagengesetz* — `FuAG`, implementing `Directive 2014/53/EU (RED)`), Federal Network Agency general allocations (*Allgemeinzuteilungen*, including `BNetzA Vfg 99/2022`), and the Amateur Radio Act/Ordinance (`AFuG` / `AFuV`), this software leaves all certified Bluetooth 2.4 GHz radio parameters and hardware-encrypted baseband partitions unmodified.
- **Gratuitous Open-Source Liability Standard (`§§ 521, 523, 524, 599, 600 BGB`):** Because this free and open-source software and documentation are provided gratuitously (*unentgeltlich*) outside the course of commercial activity, statutory liability under the German Civil Code (`§§ 521, 523, 524, 599, 600 BGB`) is limited strictly to intent (*Vorsatz*) and gross negligence (*grobe Fahrlässigkeit*).
