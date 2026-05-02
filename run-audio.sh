#!/usr/bin/env bash
# run-audio.sh - Modo audio (E2B, audio multimodal)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/run.sh" "$@" <<<'3'
