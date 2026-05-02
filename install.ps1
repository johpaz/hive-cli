#!/usr/bin/env pwsh
param(
  [string]$Repo = "johpaz/hive-cli",
  [string]$Version = "latest",
  [string]$InstallDir = (Get-Location).Path
)

function Get-OS {
  if ($PSVersionTable.PSEdition -eq "Core") {
    if ($IsWindows) { return "windows" }
    if ($IsLinux) { return "linux" }
    if ($IsMacOS) { return "darwin" }
    return "unknown"
  }
  if ($env:OS -eq "Windows_NT") { return "windows" }
  return "unknown"
}

function Get-Arch {
  if ($PSVersionTable.PSEdition -eq "Core" -and $IsWindows -eq $false) {
    $arch = & uname -m
  } else {
    $arch = $env:PROCESSOR_ARCHITECTURE.ToLower()
  }
  switch -regex ($arch) {
    'x86_64|amd64' { return "amd64" }
    'aarch64|arm64' { return "arm64" }
    default { return "unknown" }
  }
}

function Get-GPU {
  try {
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
    if ($gpu.Name -match "NVIDIA") { return "cuda" }
  } catch {}
  if ($IsMacOS) {
    return "metal"
  }
  return "cpu"
}

$os = Get-OS
$arch = Get-Arch
$gpu = Get-GPU

if ($os -eq "unknown" -or $arch -eq "unknown") {
  Write-Error "Unsupported platform"
  exit 1
}

$asset = "hive-cli-${os}-${arch}-${gpu}"
if ($os -eq "windows") { $asset += ".exe" }

if ($Version -eq "latest") {
  $url = "https://github.com/${Repo}/releases/latest/download/${asset}"
} else {
  $url = "https://github.com/${Repo}/releases/download/v${Version}/${asset}"
}

Write-Host "Detected: ${os}-${arch}-${gpu}"
Write-Host "Downloading: ${asset}"

$outPath = Join-Path $InstallDir "hive-cli.exe"
Invoke-WebRequest -Uri $url -OutFile $outPath

Write-Host "Downloaded to: ${outPath}"
Write-Host
Write-Host "Usage: .\hive-cli.exe --help"
