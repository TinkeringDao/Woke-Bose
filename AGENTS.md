# AGENTS.md

Context pointers for agents operating in this repository. Read [`GLOSSARY.md`](GLOSSARY.md) for domain terms (`Lonestarr`, `BMAP`, `SETGET`, `Baseline`, `Woke`).

- **Modifying BMAP RFCOMM transport, packet framing, or NVRAM presets**: read [`bose_ultra_tuner.m`](bose_ultra_tuner.m) and run `make` to verify zero-warning compilation against macOS `IOBluetooth.framework` and `CoreAudio.framework`.
- **Inspecting `APPUHDR5` firmware containers, partition entropy, or silicon BOM (`QCC5181`, `71215 BCBZ`, `STM32U585OI`)**: read [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) and [`parse_appuhdr5.py`](parse_appuhdr5.py).
- **Updating acoustic target curves or 10-band Parametric EQ filters (B&K 5128 / GRAS 43AG Harman 2018)**: read [`peq/bose_qc_ultra_bk5128_reference.txt`](peq/bose_qc_ultra_bk5128_reference.txt) and [`peq/bose_qc_ultra_gras_harman2018.txt`](peq/bose_qc_ultra_gras_harman2018.txt).
- **Changing interactive user flows or macOS `BluetoothAudioAgent` bitpool tuning**: read [`bose-ultra-wizard.sh`](bose-ultra-wizard.sh).
- **Reviewing statutory interoperability, non-circumvention, or trademark notices**: read [`LEGAL.md`](LEGAL.md).

## Fully Autonomous Development Pipeline

All autonomous agent contributions, pull request reviews, remediations, and merges in this repository are governed by the 6-stage specification in [`docs/agents/autonomous-pipeline.md`](docs/agents/autonomous-pipeline.md) and enforced on every Pull Request by [`.github/workflows/autonomous-pr-review.yml`](.github/workflows/autonomous-pr-review.yml) and [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

### Project Verification Commands

Run these verification checks locally before pushing any commit:

```bash
make clean && make
./bose-ultra-tuner --help
bash -n bose-ultra-wizard.sh
python3 -m py_compile parse_appuhdr5.py
```

### Verification Checklist & Pre-Merge Gate Commands

| Gate | Requirement | Local Pre-Merge Command |
| :--- | :--- | :--- |
| **Gate 1: OPSEC & Zero-PII** | Zero personal identifiers, local usernames, postal codes, or coordinates in repo tree | `grep -rnI -iE "<FORBIDDEN_PII_PATTERN>" . --exclude-dir=.git --exclude="*autonomous-pr-review.yml"` (see workflow) |
| **Gate 2: Cryptographic Signatures** | Every commit signed with `ED25519` SSH key (`verified == true`) | `git log -1 --show-signature` |
| **Gate 3: Legal & Autonomous Spec** | `LEGAL.md` (with German Statutory Addendum), `LICENSE`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CODEOWNERS`, `AGENTS.md`, `CLAUDE.md`, `docs/agents/autonomous-pipeline.md` present | `grep -q "Addendum: German Statutory References" LEGAL.md && test -s docs/agents/autonomous-pipeline.md` |
| **Gate 4: Build & Syntax** | Zero-warning Objective-C compilation + Bash & Python syntax checks | `make && bash -n bose-ultra-wizard.sh && python3 -m py_compile parse_appuhdr5.py` |

## Agent skills

### Issue tracker

Issues and specs for this repo live in GitHub Issues. See [`docs/agents/issue-tracker.md`](docs/agents/issue-tracker.md).

### Triage labels

Uses the five default canonical triage labels (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See [`docs/agents/triage-labels.md`](docs/agents/triage-labels.md).

### Domain docs

Single-context (`GLOSSARY.md` + `docs/adr/` at the repo root). See [`docs/agents/domain.md`](docs/agents/domain.md).
