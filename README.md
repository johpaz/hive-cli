# Hive CLI

CLI multimodal de `llama.cpp` (fork TurboQuant) con soporte cross-platform: Linux, macOS y Windows.

## Instalación rápida

### Linux / macOS
```bash
curl -sSL https://github.com/johpaz/hive-cli/releases/latest/download/install.sh | bash
```
Detecta automáticamente tu OS, arquitectura y backend óptimo (CUDA > Vulkan > Metal > CPU).

### Windows (PowerShell)
```powershell
iwr -Uri https://github.com/johpaz/hive-cli/releases/latest/download/install.ps1 -OutFile install.ps1
.\install.ps1
```

### Descarga manual
Descarga el binario para tu plataforma desde [Releases](https://github.com/johpaz/hive-cli/releases).

| Asset | Backend | Plataforma |
|-------|---------|------------|
| `hive-cli-linux-amd64-cpu` | CPU | Linux x86_64 |
| `hive-cli-linux-amd64-vulkan` | Vulkan | Linux x86_64 |
| `hive-cli-linux-amd64-cuda` | CUDA | Linux x86_64 (NVIDIA) |
| `hive-cli-linux-arm64-cpu` | CPU | Linux ARM64 |
| `hive-cli-darwin-amd64-cpu` | CPU | macOS Intel |
| `hive-cli-darwin-amd64-metal` | Metal | macOS Intel |
| `hive-cli-darwin-arm64-cpu` | CPU | macOS Apple Silicon |
| `hive-cli-darwin-arm64-metal` | Metal | macOS Apple Silicon |
| `hive-cli-windows-amd64-cpu.exe` | CPU | Windows x86_64 |
| `hive-cli-windows-amd64-vulkan.exe` | Vulkan | Windows x86_64 |
| `hive-cli-windows-amd64-cuda.exe` | CUDA | Windows x86_64 (NVIDIA) |

## Requisitos

- **CPU/cpu**: cualquier sistema
- **Vulkan**: drivers Vulkan funcionales
- **CUDA**: GPU NVIDIA con drivers CUDA
- **Metal**: macOS 10.14+ (Intel) o macOS 11+ (Apple Silicon)
- ~71 MB libres para el binario + espacio para modelos (~4-8 GB por modelo)

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

Los releases se generan automáticamente via GitHub Actions. Ejecutar manualmente desde el repo:

```bash
cd llama-cpp-turboquant

# CPU only
cmake -B build -DCMAKE_BUILD_TYPE=Release -DGGML_NATIVE=OFF
cmake --build build --config Release -j$(nproc)

# Con backend específico
cmake -B build -DCMAKE_BUILD_TYPE=Release -DGGML_VULKAN=ON # o CUDA/Metal
cmake --build build --config Release -j$(nproc)
```

El binario se genera como `build/bin/hive-cli`.

Para crear un release con todas las plataformas, ve a **Actions → Release** y ejecuta el workflow con el número de versión deseado.

## Licencia

Ver licencias originales en el repositorio fuente de llama.cpp.