---
id: shell-scripts
title: Shell Script Conventions
---

This document describes the conventions for shell scripts in the workspace template.

## Required Header

All scripts must start with:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

**Explanation:**

- `#!/usr/bin/env bash` - Use bash via env for portability
- `set -e` - Exit immediately if a command exits with non-zero status (errexit)
- `set -u` - Treat unset variables as an error (nounset)
- `set -o pipefail` - Pipeline fails if any command in it fails

## Style Principles

### Linear and Procedural

- Avoid functions - keep scripts linear and readable
- Execute commands sequentially
- Use comments for section separation

### POSIX-Compatible

- Prefer POSIX-compliant syntax over bash-specific features
- Use `$(command)` for command substitution, not backticks
- Use `[[ ]]` for tests, not `[ ]`

### No Coloring

- Keep output simple and readable
- Avoid ANSI color codes

### Emoji-Prefixed Echo Statements

- Use emoji prefixes before/after each major task
- Format: `echo "⚙️ Doing something..."`
- Follow with: `echo "✅ Done!"`

## Emoji Convention

| Purpose       | Emoji |
| ------------- | ----- |
| Setup/Install | ⬇️    |
| Building      | 🔨    |
| Testing       | 🧪    |
| Linting       | 🔍    |
| Cleaning      | 🧹    |
| Running       | ▶️    |
| Done/Success  | ✅    |
| Warning/Info  | ℹ️    |
| Error         | ❌    |

## Template

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "⚙️ Setting up..."
bun install

echo "🔨 Building..."
bun run build

echo "✅ Done!"
```

## File Location

All shell scripts live in `scripts/` at the project root and are invoked via `pls <command>` defined in `Taskfile.yaml`.

```text
scripts/
├── setup.sh          # Install dependencies
├── build.sh          # Build project
├── clean.sh          # Clean artifacts
├── test.sh           # Run tests
├── lint.sh           # Run pre-commit
├── dev.sh            # Run in dev mode
└── ci/
    ├── pre-commit.sh     # CI: pre-commit hooks
    ├── test-unit.sh      # CI: unit tests
    ├── test-int.sh       # CI: integration tests
    └── build.sh          # CI: build
```

## Summary

| Aspect       | Pattern                                     |
| ------------ | ------------------------------------------- |
| **Header**   | `#!/usr/bin/env bash` + `set -euo pipefail` |
| **Style**    | Linear, POSIX-compatible, no colors         |
| **Progress** | Emoji-prefixed echo statements              |
| **Location** | `scripts/` directory                        |
