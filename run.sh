#!/usr/bin/env bash
# Script lanzador interactivo para Hive CLI
# Soporta 3 modos: Texto, Imagen y Audio

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HIVE_BIN="${SCRIPT_DIR}/bin/hive-cli"
MODELS_DIR="${SCRIPT_DIR}/models"

# Verificar binario
if [[ ! -x "$HIVE_BIN" ]]; then
    echo "Error: No se encontró el binario hive-cli en ${HIVE_BIN}" >&2
    exit 1
fi

# Modelos disponibles
MODEL_E2B_IQ3="${MODELS_DIR}/gemma-4-E2B-it-UD-IQ3_XXS.gguf"
MODEL_E2B_Q8="${MODELS_DIR}/gemma-4-E2B-it-UD-Q8_K_XL.gguf"
MODEL_E4B_IQ3="${MODELS_DIR}/gemma-4-E4B-it-UD-IQ3_XXS.gguf"
MODEL_E4B_Q8="${MODELS_DIR}/gemma-4-E4B-it-UD-Q8_K_XL.gguf"
MMPROJ="${MODELS_DIR}/mmproj-BF16.gguf"

# Variables de entorno Vulkan
export GGML_VULKAN_CHECK_RESULTS=0
export GGML_VULKAN_DEBUG=0

# Parámetros base
THREADS=$(nproc)
CTX_SIZE=8192
NGL=999
BATCH_SIZE=2048
UBATCH_SIZE=512
CACHE_TYPE_K="f16"
CACHE_TYPE_V="f16"
FLASH_ATTN="on"

# Mostrar menú
echo "=================================="
echo "      Hive CLI - Launcher         "
echo "=================================="
echo ""
echo "Selecciona el modo de operación:"
echo ""
echo "  [1] Texto        (E2B - más rápido, ~55 t/s)"
echo "  [2] Imagen       (E4B - multimodal, ~30 t/s)"
echo "  [3] Audio        (E2B - multimodal, ~55 t/s)"
echo "  [4] Texto+Imagen (E4B - ambos, ~30 t/s)"
echo "  [5] Texto+Audio  (E2B - ambos, ~55 t/s)"
echo ""
read -rp "Opción [1-5]: " OPCION

# Configurar según modo
case "$OPCION" in
    1)
        echo ""
        echo "Modo: TEXTO (E2B - máxima velocidad)"
        MODEL="$MODEL_E2B_IQ3"
        ARGS=(
            -m "$MODEL"
            -t "$THREADS" -c "$CTX_SIZE" -ngl "$NGL"
            -b "$BATCH_SIZE" -ub "$UBATCH_SIZE"
            --cache-type-k "$CACHE_TYPE_K" --cache-type-v "$CACHE_TYPE_V"
            --flash-attn "$FLASH_ATTN"
            "$@"
        )
        ;;
    2)
        echo ""
        echo "Modo: IMAGEN (E4B - visión multimodal)"
        MODEL="$MODEL_E4B_IQ3"
        read -rp "Ruta de la imagen: " IMG_PATH
        if [[ ! -f "$IMG_PATH" ]]; then
            echo "Error: Imagen no encontrada: $IMG_PATH" >&2
            exit 1
        fi
        ARGS=(
            -m "$MODEL" --mmproj "$MMPROJ"
            --image "$IMG_PATH"
            -t "$THREADS" -c "$CTX_SIZE" -ngl "$NGL"
            -b "$BATCH_SIZE" -ub "$UBATCH_SIZE"
            --cache-type-k "$CACHE_TYPE_K" --cache-type-v "$CACHE_TYPE_V"
            --flash-attn "$FLASH_ATTN"
            "$@"
        )
        ;;
    3)
        echo ""
        echo "Modo: AUDIO (E2B - audio multimodal)"
        MODEL="$MODEL_E2B_IQ3"
        read -rp "Ruta del archivo de audio: " AUDIO_PATH
        if [[ ! -f "$AUDIO_PATH" ]]; then
            echo "Error: Audio no encontrado: $AUDIO_PATH" >&2
            exit 1
        fi
        ARGS=(
            -m "$MODEL" --mmproj "$MMPROJ"
            --audio "$AUDIO_PATH"
            -t "$THREADS" -c "$CTX_SIZE" -ngl "$NGL"
            -b "$BATCH_SIZE" -ub "$UBATCH_SIZE"
            --cache-type-k "$CACHE_TYPE_K" --cache-type-v "$CACHE_TYPE_V"
            --flash-attn "$FLASH_ATTN"
            "$@"
        )
        ;;
    4)
        echo ""
        echo "Modo: TEXTO + IMAGEN (E4B - completo)"
        MODEL="$MODEL_E4B_IQ3"
        read -rp "Ruta de la imagen (opcional, Enter para saltar): " IMG_PATH
        ARGS=(
            -m "$MODEL" --mmproj "$MMPROJ"
            -t "$THREADS" -c "$CTX_SIZE" -ngl "$NGL"
            -b "$BATCH_SIZE" -ub "$UBATCH_SIZE"
            --cache-type-k "$CACHE_TYPE_K" --cache-type-v "$CACHE_TYPE_V"
            --flash-attn "$FLASH_ATTN"
        )
        if [[ -n "$IMG_PATH" && -f "$IMG_PATH" ]]; then
            ARGS+=(--image "$IMG_PATH")
        fi
        ARGS+=("$@")
        ;;
    5)
        echo ""
        echo "Modo: TEXTO + AUDIO (E2B - completo)"
        MODEL="$MODEL_E2B_IQ3"
        read -rp "Ruta del audio (opcional, Enter para saltar): " AUDIO_PATH
        ARGS=(
            -m "$MODEL" --mmproj "$MMPROJ"
            -t "$THREADS" -c "$CTX_SIZE" -ngl "$NGL"
            -b "$BATCH_SIZE" -ub "$UBATCH_SIZE"
            --cache-type-k "$CACHE_TYPE_K" --cache-type-v "$CACHE_TYPE_V"
            --flash-attn "$FLASH_ATTN"
        )
        if [[ -n "$AUDIO_PATH" && -f "$AUDIO_PATH" ]]; then
            ARGS+=(--audio "$AUDIO_PATH")
        fi
        ARGS+=("$@")
        ;;
    *)
        echo "Opción inválida. Usando modo TEXTO por defecto."
        MODEL="$MODEL_E2B_IQ3"
        ARGS=(
            -m "$MODEL"
            -t "$THREADS" -c "$CTX_SIZE" -ngl "$NGL"
            -b "$BATCH_SIZE" -ub "$UBATCH_SIZE"
            --cache-type-k "$CACHE_TYPE_K" --cache-type-v "$CACHE_TYPE_V"
            --flash-attn "$FLASH_ATTN"
            "$@"
        )
        ;;
esac

echo ""
echo "=================================="
echo "  Hive CLI - Iniciando            "
echo "=================================="
echo "Modelo : $(basename "$MODEL")"
echo "GPU    : Vulkan (offload completo)"
echo "Hilos  : $THREADS"
echo "CTX    : $CTX_SIZE"
echo "=================================="
echo ""

exec "$HIVE_BIN" "${ARGS[@]}"