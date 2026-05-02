# Hive CLI - Entrega Hackathon

Binario optimizado de `llama.cpp` (fork TurboQuant) con backend Vulkan, compilado para Linux x86_64 con optimizaciones nativas (`-march=znver3 -mtune=znver3 -O3 -flto`) para Ryzen 680M.

## Requisitos

- Linux x86_64
- Drivers Vulkan funcionales (mesa-vulkan-drivers, AMDVLK, etc.)
- ~71 MB libres para el binario + espacio para modelos

## Estructura

```
.
├── bin/
│   ├── hive-cli          ← Ejecutable principal
│   └── llama-bench       ← Herramienta de benchmark
├── models/
│   ├── gemma-4-E4B-it-UD-IQ3_XXS.gguf   ← Texto + Imagen (rápido)
│   ├── gemma-4-E4B-it-UD-Q8_K_XL.gguf   ← Texto + Imagen (calidad)
│   ├── gemma-4-E2B-it-UD-IQ3_XXS.gguf   ← Texto + Audio (más rápido)
│   ├── gemma-4-E2B-it-UD-Q8_K_XL.gguf   ← Texto + Audio (calidad)
│   └── mmproj-BF16.gguf                 ← Proyector multimodal
├── run.sh                ← Script interactivo (5 modos)
├── run-texto.sh          ← Modo texto directo
├── run-imagen.sh         ← Modo imagen directo
├── run-audio.sh          ← Modo audio directo
├── run-all.sh            ← Modo completo: texto + imagen + audio
├── benchmark.sh          ← Script de benchmark
├── README.md             ← Este archivo
└── results/
    └── benchmark_summary.md   ← Resultados de rendimiento
```

## Uso rápido (Interactivo)

```bash
chmod +x run.sh
./run.sh
```

El script mostrará un menú para elegir entre:
1. **Texto** - E2B, máxima velocidad (~55 t/s)
2. **Imagen** - E4B, visión multimodal (~30 t/s)
3. **Audio** - E2B, audio multimodal (~55 t/s)
4. **Texto+Imagen** - E4B, ambos modos
5. **Texto+Audio** - E2B, ambos modos

## Uso directo por modo

### Modo Texto (E2B - más rápido)
```bash
./run-texto.sh
# o manualmente:
./bin/hive-cli -m models/gemma-4-E2B-it-UD-IQ3_XXS.gguf -ngl 999 -fa -p "Tu prompt"
```

### Modo Imagen (E4B - visión)
```bash
./run-imagen.sh
# o manualmente:
./bin/hive-cli -m models/gemma-4-E4B-it-UD-IQ3_XXS.gguf \
  --mmproj models/mmproj-BF16.gguf \
  --image foto.jpg -p "Describe esta imagen"
```

### Modo Audio (E2B - audio)
```bash
./run-audio.sh
# o manualmente:
./bin/hive-cli -m models/gemma-4-E2B-it-UD-IQ3_XXS.gguf \
  --mmproj models/mmproj-BF16.gguf \
  --audio audio.wav -p "Transcribe este audio"
```

### Modo Completo (Texto + Imagen + Audio)
```bash
./run-all.sh
```
Este modo interactivo permite combinar las 3 modalidades simultáneamente:
- Pregunta por modelo base (E4B para imagen, E2B para audio)
- Solicita ruta de imagen (opcional)
- Solicita ruta de audio (opcional)
- Solicita prompt de texto
- Pasa todos los inputs al modelo multimodal

## Rendimiento real medido (Ryzen 680M)

| Modelo | Cuantización | Prompt 512 | Generación 128 | Uso |
|--------|-------------|-----------|----------------|-----|
| **E2B** | IQ3_XXS | 452 t/s | **55.7 t/s** | Texto rápido |
| **E2B** | Q8_K_XL | 697 t/s | 27.9 t/s | Texto calidad |
| **E4B** | IQ3_XXS | 193 t/s | **30.8 t/s** | Texto + Imagen |
| **E4B** | Q8_K_XL | 341 t/s | 13.7 t/s | Texto + Imagen (calidad) |

**Nota:** TurboQuant (turbo3/turbo4) NO acelera en Ryzen 680M porque esta iGPU no tiene Tensor/MMA Cores. Solo sirve para ahorrar VRAM en GPUs dedicadas.

## Flags clave de rendimiento

| Flag | Descripción |
|------|-------------|
| `-ngl 999` | Offload máximo de capas a GPU |
| `-fa / --flash-attn on` | Flash Attention (menor uso de memoria + más rápido) |
| `--cache-type-k f16` | KV cache K en f16 (máxima velocidad en 680M) |
| `--cache-type-v f16` | KV cache V en f16 |
| `-t $(nproc)` | Usa todos los hilos CPU |

## Benchmark

```bash
./benchmark.sh
```

## Compilación

El binario fue compilado desde el fork `TheTom/llama-cpp-turboquant` con:
- Backend Vulkan activado
- `-march=znver3 -mtune=znver3 -O3 -flto`
- Sin CUDA, Metal, OpenCL, SYCL, HIP
- Sin tests, ejemplos, servidor, webui
- `OUTPUT_NAME=hive-cli` en el target principal

## Licencia

Ver licencias originales en el repositorio fuente de llama.cpp.