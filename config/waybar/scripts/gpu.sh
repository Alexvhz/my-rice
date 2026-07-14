#!/usr/bin/env bash
# GPU usage for Waybar. Emits JSON: {"text":"..","tooltip":".."}
# Auto-detects NVIDIA, AMD, or Intel. Falls back gracefully if none found.

set -euo pipefail

# --- NVIDIA (nvidia-smi) ---
if command -v nvidia-smi >/dev/null 2>&1; then
    read -r util temp <<<"$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu \
        --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr ',' ' ')"
    if [[ -n "${util:-}" ]]; then
        printf '{"text":"%s%%","tooltip":"NVIDIA GPU\\nUsage: %s%%\\nTemp: %s°C"}\n' \
            "$util" "$util" "${temp:-?}"
        exit 0
    fi
fi

# --- AMD (amdgpu sysfs) ---
amd_busy="$(cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -n1 || true)"
if [[ -n "${amd_busy:-}" ]]; then
    temp=""
    if command -v sensors >/dev/null 2>&1; then
        temp="$(sensors 2>/dev/null | awk '/edge:/ {gsub(/[+°C]/,"",$2); print int($2); exit}')"
    fi
    printf '{"text":"%s%%","tooltip":"AMD GPU\\nUsage: %s%%\\nTemp: %s°C"}\n' \
        "$amd_busy" "$amd_busy" "${temp:-?}"
    exit 0
fi

# --- Intel (needs intel_gpu_top, root) — best-effort, else show label ---
if command -v intel_gpu_top >/dev/null 2>&1; then
    busy="$(timeout 2 intel_gpu_top -J -s 1000 2>/dev/null \
        | grep -m1 -oP '"Render/3D".*?"busy":\s*\K[0-9.]+' || true)"
    if [[ -n "${busy:-}" ]]; then
        printf '{"text":"%.0f%%","tooltip":"Intel GPU\\nRender busy: %.0f%%"}\n' "$busy" "$busy"
        exit 0
    fi
fi

# --- Fallback ---
printf '{"text":"n/a","tooltip":"No supported GPU sensor found"}\n'
