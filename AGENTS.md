# AGENTS.md

Context pointers for agents operating in this repository. Read [`GLOSSARY.md`](GLOSSARY.md) for domain terms (`Lonestarr`, `BMAP`, `SETGET`, `Baseline`, `Woke`).

- **Modifying BMAP RFCOMM transport, packet framing, or NVRAM presets**: read [`bose_ultra_tuner.m`](bose_ultra_tuner.m) and run `make` to verify zero-warning compilation against macOS `IOBluetooth.framework`.
- **Inspecting `APPUHDR5` firmware containers, partition entropy, or silicon BOM (`QCC5181`, `71215 BCBZ`, `STM32U585OI`)**: read [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) and [`parse_appuhdr5.py`](parse_appuhdr5.py).
- **Updating acoustic target curves or 10-band Parametric EQ filters (B&K 5128 / GRAS 43AG Harman 2018)**: read [`peq/bose_qc_ultra_bk5128_reference.txt`](peq/bose_qc_ultra_bk5128_reference.txt) and [`peq/bose_qc_ultra_gras_harman2018.txt`](peq/bose_qc_ultra_gras_harman2018.txt).
- **Changing interactive user flows or macOS `BluetoothAudioAgent` bitpool tuning**: read [`bose-ultra-wizard.sh`](bose-ultra-wizard.sh).
- **Reviewing statutory interoperability, non-circumvention, or trademark notices**: read [`LEGAL.md`](LEGAL.md).

## Agent skills

### Issue tracker

Issues and specs for this repo live in GitHub Issues. See `docs/agents/issue-tracker.md`.

### Triage labels

Uses the five default canonical triage labels (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context (`GLOSSARY.md` + `docs/adr/` at the repo root). See `docs/agents/domain.md`.

