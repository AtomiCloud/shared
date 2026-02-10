#!/usr/bin/env bash
set -eou pipefail

# install dependencies
echo "⬇️ Installing Dependencies..."

cd cyan && bun install && cd ..

echo "✅ Done!"

# run precommit
echo "🏃‍➡️ Running Pre-Commit..."
pre-commit run --all -v
echo "✅ Done!"
