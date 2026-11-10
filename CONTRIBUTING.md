# Contributing to Woke Bose

Contributions adding support for additional Bose BMAP registers, firmware revisions, test coverage, or acoustic coupler measurements are welcome.

## Ground Rules

- Read and follow [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) in all issues, pull requests, commit messages, and discussions.
- Review [`LEGAL.md`](LEGAL.md) before submitting protocol, container-inspection, or hardware-interoperability changes:
  - Include `# SPDX-License-Identifier: MIT` and the repository clean-room interoperability header at the top of every source file and script.
  - Never commit or upload proprietary firmware binaries (`.bin`, `.dfu`, `.kap`), mobile application packages (`.ipa`, `.apk`), decompiled vendor code, verbatim hexadecimal OEM firmware slices, cryptographic IVs/nonces, or screenshots of proprietary OEM applications. Always use structural field descriptions and `<REDACTED_OEM_BYTES>`.
  - Document newly characterized BMAP Function Blocks or opcodes functionally in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) and [`GLOSSARY.md`](GLOSSARY.md).
- Do not include personal data, private network addresses, device serial numbers, Bluetooth MAC addresses, or credentials in code, tests, logs, or fixtures.
- Report security vulnerabilities privately via [`SECURITY.md`](SECURITY.md) rather than public issues.

## Pull Request Workflow

1. Create a focused topic branch from `main` (`feat/...`, `fix/...`, `docs/...`, `chore/...`, `ci/...`).
2. Keep commits atomic, use Conventional Commit headers (`feat:`, `fix:`, `docs:`, `ci:`, `refactor:`, `test:`), and sign all commits (`git config commit.gpgsign true`).
3. Run the local build, compiler-warning, and syntax verification suite before opening a pull request:

```bash
make clean && make CFLAGS="-fobjc-arc -Wall -Wextra -Werror -Wno-deprecated-declarations -O2"
./bose-ultra-tuner --help
bash -n bose-ultra-wizard.sh
python3 -m py_compile parse_appuhdr5.py
```

4. Open a pull request against `main` summarizing the problem, root cause or design choice, and verification output. All pull requests are licensed under the MIT License ([`LICENSE`](LICENSE)) and squash-merge onto `main` once `ci` and `security` checks pass.
