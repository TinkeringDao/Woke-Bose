# CLAUDE.md

Entry point for Claude Code and autonomous coding agents operating in `TinkeringDao/Woke-Bose`.

## Mandatory Reading Before Any Action

1. **[`AGENTS.md`](AGENTS.md)** — Repository context pointers, domain glossary references, and project verification commands.
2. **[`docs/agents/autonomous-pipeline.md`](docs/agents/autonomous-pipeline.md)** — The 6-stage **Fully Autonomous Development Pipeline Specification** (Context & Hindsight Recall -> Signed Branch TDD -> PR Creation -> Dual 4-Gate CI & Subagent Review -> Autonomous Remediation -> Automated Approval & Squash Merge).
3. **[`LEGAL.md`](LEGAL.md)** — 8-pillar EU/US clean-room hardware interoperability framework and `Addendum: German Statutory References (Applicable to Residents of Germany)`.

## Non-Negotiable Constraints

- **Git Identity & Cryptographic Signing**: Author all commits as `TinkeringDao <203040288+TinkeringDao@users.noreply.github.com>` with `ED25519` SSH signing enabled (`commit.gpgsign=true`).
- **OPSEC & Zero-PII**: Never include personal names, local usernames, postal codes, geographic coordinates, or hardware MAC addresses/serial numbers in source files, documentation, or commit messages.
- **Zero-Warning Compilation & Script Checks**: Always run `make`, `bash -n bose-ultra-wizard.sh`, and `python3 -m py_compile parse_appuhdr5.py` before pushing to a PR branch.
