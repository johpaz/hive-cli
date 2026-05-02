#!/usr/bin/env bash
# run-imagen.sh - Modo imagen (E4B, visión multimodal)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/run.sh" "$@" <<<'2'
