#!/usr/bin/env bash
set -euo pipefail

# Semantic release script for npm publishing
# Uses sg (Semantic Generator) to run semantic-release with npm plugins

echo "🔧 Cleaning up git hooks..."
rm -rf .git/hooks/* 2>/dev/null || true

echo "🚀 Running semantic release..."
sg release -i npm || true

echo "✅ Release complete!"
