# Contributing to Woke Bose

Contributions adding support for additional Bose BMAP registers, firmware revisions, or coupler measurements are welcome.

## Development Workflow

1. **Fork & Branch**: Create a feature branch from `main` (`git checkout -b feat/your-feature`).
2. **Zero-Warning Compilation**: All Objective-C changes in [`bose_ultra_tuner.m`](bose_ultra_tuner.m) must compile cleanly under `-Wall -Wextra -Werror`:
   ```bash
   clang -fobjc-arc -Wall -Wextra -Werror -Wno-deprecated-declarations -O2 \
     -framework Foundation -framework IOBluetooth -framework CoreAudio \
     bose_ultra_tuner.m -o bose-ultra-tuner
   ```
3. **Script Verification**:
   ```bash
   bash -n bose-ultra-wizard.sh
   python3 -m py_compile parse_appuhdr5.py
   ```
4. **Clean-Room, DMCA Immunity, & Privacy Hygiene (`Gadgetbridge` / `Asahi Linux` Standards)**:
   - Include `# SPDX-License-Identifier: MIT` and the repository clean-room interoperability header at the top of every source file and script.
   - Never hardcode personal Bluetooth MAC addresses or hardware serial numbers in source files.
   - Never commit or upload proprietary firmware binaries (`.bin`, `.dfu`, `.kap`), mobile application packages (`.ipa`, `.apk`), decompiled vendor source code, or **screenshots of proprietary OEM mobile applications** in Issues or Pull Requests.
   - Never commit verbatim hexadecimal slices of OEM firmware partitions, cryptographic Initialization Vectors (IVs/nonces), or RSA signature blocks; always use structural field descriptions and `<REDACTED_OEM_BYTES>` (see [`LEGAL.md`](LEGAL.md)).
   - Document any newly discovered BMAP Function Blocks or opcodes functionally in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) and [`GLOSSARY.md`](GLOSSARY.md).

## Pull Request Standards

All Pull Requests must follow the repository [PR Template](.github/PULL_REQUEST_TEMPLATE.md):
- **`## Summary`**: Architectural context and control-flow diagram where applicable.
- **`## Evidence`**: Raw BMAP `TX`/`RX` hex dumps or acoustic telemetry proving `Before` vs. `After` behavior on hardware.
- **`## Merge Danger`**: Explicit `**Door:** two-way | one-way` and `**Blast Radius:** local | module | system` classification.

### Verification Checklist & Pre-Merge Gate Commands

Every Pull Request is automatically audited by [`.github/workflows/autonomous-pr-review.yml`](.github/workflows/autonomous-pr-review.yml) and [`docs/agents/autonomous-pipeline.md`](docs/agents/autonomous-pipeline.md). Run these commands locally before opening or updating a PR:

| Gate | Requirement | Local Pre-Merge Command |
| :--- | :--- | :--- |
| **Gate 1: OPSEC & Zero-PII** | Zero personal identifiers, local usernames, postal codes, or coordinates in repo tree | `grep -rnI -iE "<FORBIDDEN_PII_PATTERN>" . --exclude-dir=.git --exclude="*autonomous-pr-review.yml"` (see workflow) |
| **Gate 2: Cryptographic Signatures** | Every commit signed with `ED25519` SSH key (`verified == true`) | `git log -1 --show-signature` |
| **Gate 3: Legal & Autonomous Spec** | `LEGAL.md` (with German Statutory Addendum), `LICENSE`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CODEOWNERS`, `AGENTS.md`, `CLAUDE.md`, `docs/agents/autonomous-pipeline.md` present | `grep -q "Addendum: German Statutory References" LEGAL.md && test -s docs/agents/autonomous-pipeline.md` |
| **Gate 4: Build & Syntax** | Zero-warning Objective-C compilation + Bash & Python syntax checks | `make && bash -n bose-ultra-wizard.sh && python3 -m py_compile parse_appuhdr5.py` |
