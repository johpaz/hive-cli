#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-johpaz/hive-cli}"
VERSION="${VERSION:-latest}"
INSTALL_DIR="${INSTALL_DIR:-$(pwd)}"

detect_os() {
  case "$(uname -s)" in
    Linux) echo "linux" ;;
    Darwin) echo "darwin" ;;
    CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
    *) echo "unknown" ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) echo "unknown" ;;
  esac
}

detect_gpu() {
  if command -v nvidia-smi &>/dev/null; then
    echo "cuda"; return
  fi

  if command -v vulkaninfo &>/dev/null; then
    echo "vulkan"; return
  fi

  if ldconfig -p 2>/dev/null | grep -q "libvulkan.so"; then
    echo "vulkan"; return
  fi

  for icd in /usr/share/vulkan/icd.d/*.json; do
    if [ -f "$icd" ]; then
      echo "vulkan"; return
    fi
  done

  if [ "$(uname)" = "Darwin" ] && [ -f /System/Library/Frameworks/Metal.framework/Metal ]; then
    echo "metal"; return
  fi

  echo "cpu"
}

main() {
  local os arch gpu asset url

  os=$(detect_os)
  arch=$(detect_arch)
  gpu=$(detect_gpu)

  if [ "$os" = "unknown" ] || [ "$arch" = "unknown" ]; then
    echo "Error: unsupported platform ($(uname -s) $(uname -m))" >&2
    exit 1
  fi

  asset="hive-cli-${os}-${arch}-${gpu}"
  [ "$os" = "windows" ] && asset="${asset}.exe"

  if [ "$VERSION" = "latest" ]; then
    url="https://github.com/${REPO}/releases/latest/download/${asset}"
  else
    url="https://github.com/${REPO}/releases/download/v${VERSION}/${asset}"
  fi

  echo "Detected: ${os}-${arch}-${gpu}"
  echo "Downloading: ${asset}"

  if command -v curl &>/dev/null; then
    curl -sSL -o "${INSTALL_DIR}/hive-cli" "$url"
  elif command -v wget &>/dev/null; then
    wget -q -O "${INSTALL_DIR}/hive-cli" "$url"
  else
    echo "Error: curl or wget required" >&2
    exit 1
  fi

  chmod +x "${INSTALL_DIR}/hive-cli"

  echo "Downloaded to: ${INSTALL_DIR}/hive-cli"
  echo
  echo "Usage: ./hive-cli --help"
  echo
  echo "Optional — install globally:"
  echo "  sudo mv ${INSTALL_DIR}/hive-cli /usr/local/bin/"
}

main "$@"
