#!/usr/bin/env bash
# run-texto.sh - Modo texto rápido (E2B, máxima velocidad)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/run.sh" "$@" <<<'1'
