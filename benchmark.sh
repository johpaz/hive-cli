#!/usr/bin/env bash
# benchmark.sh - Tests de rendimiento Hive CLI (tokens/segundo)
# Compara configuraciones de KV Cache y modelos Gemma 4 E2B/E4B

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCH_BIN="${SCRIPT_DIR}/bin/llama-bench"
RESULTS_DIR="${SCRIPT_DIR}/results"
MODELS_DIR="${SCRIPT_DIR}/models"

mkdir -p "$RESULTS_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="${RESULTS_DIR}/benchmark_${TIMESTAMP}.log"

# Configuración base
THREADS=$(nproc)
NGL=999
FA=1
NPROMPT=512
NGEN=128

# Modelos a probar
declare -a MODELS=(
    "${MODELS_DIR}/gemma-4-E4B-it-UD-IQ3_XXS.gguf"
    "${MODELS_DIR}/gemma-4-E2B-it-UD-IQ3_XXS.gguf"
)

# Tipos de KV Cache a comparar
declare -a CACHE_TYPES=(
    "f16"
    "q8_0"
    "turbo4"
)

echo "=========================================="
echo "  Hive CLI Benchmark - $(date)"
echo "  CPU: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
echo "=========================================="

for MODEL in "${MODELS[@]}"; do
    MODEL_NAME=$(basename "$MODEL")
    echo ""
    echo "=========================================="
    echo "Benchmarking: $MODEL_NAME"
    echo "=========================================="

    if [[ ! -f "$MODEL" ]]; then
        echo "Modelo no encontrado: $MODEL, saltando..."
        continue
    fi

    for CACHE in "${CACHE_TYPES[@]}"; do
        echo ""
        echo "-> Cache type: $CACHE"

        # Ejecutar benchmark y guardar output completo
        $BENCH_BIN \
            -m "$MODEL" \
            -t "$THREADS" \
            -ngl "$NGL" \
            -fa "$FA" \
            -p "$NPROMPT" \
            -n "$NGEN" \
            -ctk "$CACHE" \
            -ctv "$CACHE" \
            -o md \
            --progress \
            2>&1 | tee -a "$RESULTS_FILE" || true
    done
done

echo ""
echo "=========================================="
echo "Benchmark completado. Resultados en:"
echo "$RESULTS_FILE"
echo "=========================================="