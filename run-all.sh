#!/usr/bin/env bash
# run-all.sh - Modo completo: Texto + Imagen + Audio simultáneamente
# Usa E4B como modelo base multimodal (soporta imagen nativamente)
# Para audio, se pasa el flag --audio aunque el modelo E4B esté optimizado para visión
# En el futuro, Google podría lanzar un modelo E4B+E2B unificado

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HIVE_BIN="${SCRIPT_DIR}/bin/hive-cli"
MODELS_DIR="${SCRIPT_DIR}/models"

# Verificar binario
if [[ ! -x "$HIVE_BIN" ]]; then
    echo "Error: No se encontró el binario hive-cli en ${HIVE_BIN}" >&2
    exit 1
fi

# Modelo E4B (multimodal visión) como base
MODEL="${MODELS_DIR}/gemma-4-E4B-it-UD-IQ3_XXS.gguf"
MMPROJ="${MODELS_DIR}/mmproj-BF16.gguf"

# Alternativa: E2B si el usuario prefiere audio nativo
MODEL_E2B="${MODELS_DIR}/gemma-4-E2B-it-UD-IQ3_XXS.gguf"

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

echo "=================================="
echo "   Hive CLI - Modo COMPLETO       "
echo "   (Texto + Imagen + Audio)       "
echo "=================================="
echo ""
echo "Este modo permite combinar las 3 modalidades:"
echo "  - Texto: prompt escrito"
echo "  - Imagen: archivo de imagen (jpg, png)"
echo "  - Audio: archivo de audio (wav, mp3)"
echo ""
echo "Nota: E4B soporta imagen nativamente."
echo "      E2B soporta audio nativamente."
echo "      Actualmente usamos E4B como base."
echo ""

# Preguntar por modelo base
echo "Selecciona el modelo base:"
echo "  [1] E4B - Optimizado para Imagen + Texto (~30 t/s)"
echo "  [2] E2B - Optimizado para Audio + Texto (~55 t/s)"
echo ""
read -rp "Opción [1-2, default=1]: " MODEL_CHOICE
MODEL_CHOICE=${MODEL_CHOICE:-1}

case "$MODEL_CHOICE" in
    2)
        MODEL="$MODEL_E2B"
        MODEL_NAME="E2B (Audio + Texto)"
        ;;
    *)
        MODEL="$MODEL"
        MODEL_NAME="E4B (Imagen + Texto)"
        ;;
esac

echo ""
echo "Modelo seleccionado: $MODEL_NAME"
echo ""

# Preguntar por imagen
read -rp "Ruta de la imagen (opcional, Enter para omitir): " IMG_PATH

# Preguntar por audio
read -rp "Ruta del audio (opcional, Enter para omitir): " AUDIO_PATH

# Preguntar por prompt de texto
read -rp "Prompt de texto: " PROMPT

# Construir argumentos
ARGS=(
    -m "$MODEL"
    --mmproj "$MMPROJ"
    -t "$THREADS" -c "$CTX_SIZE" -ngl "$NGL"
    -b "$BATCH_SIZE" -ub "$UBATCH_SIZE"
    --cache-type-k "$CACHE_TYPE_K" --cache-type-v "$CACHE_TYPE_V"
    --flash-attn "$FLASH_ATTN"
)

# Agregar imagen si se proporcionó
if [[ -n "$IMG_PATH" ]]; then
    if [[ ! -f "$IMG_PATH" ]]; then
        echo "Advertencia: Imagen no encontrada: $IMG_PATH" >&2
    else
        ARGS+=(--image "$IMG_PATH")
        echo "✓ Imagen agregada: $IMG_PATH"
    fi
fi

# Agregar audio si se proporcionó
if [[ -n "$AUDIO_PATH" ]]; then
    if [[ ! -f "$AUDIO_PATH" ]]; then
        echo "Advertencia: Audio no encontrado: $AUDIO_PATH" >&2
    else
        ARGS+=(--audio "$AUDIO_PATH")
        echo "✓ Audio agregado: $AUDIO_PATH"
    fi
fi

# Agregar prompt si se proporcionó
if [[ -n "$PROMPT" ]]; then
    ARGS+=(-p "$PROMPT")
else
    ARGS+=(-i)  # Modo interactivo si no hay prompt
fi

echo ""
echo "=================================="
echo "  Hive CLI - Iniciando            "
echo "=================================="
echo "Modelo : $(basename "$MODEL")"
echo "Modo   : Texto + Imagen + Audio"
echo "GPU    : Vulkan (offload completo)"
echo "Hilos  : $THREADS"
echo "CTX    : $CTX_SIZE"
echo "=================================="
echo ""

exec "$HIVE_BIN" "${ARGS[@]}"
