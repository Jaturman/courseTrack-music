#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_ID="${1:-instinct2}"
OUT_FILE="$ROOT_DIR/bin/courseTrack-music.prg"
JUNGLE_FILE="$ROOT_DIR/monkey.jungle"

if [[ -z "${CIQ_SDK_HOME:-}" ]]; then
  if command -v monkeyc >/dev/null 2>&1; then
    CIQ_SDK_HOME="$(dirname "$(dirname "$(command -v monkeyc)")")"
  else
    mac_sdk_root="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks"
    if [[ -d "$mac_sdk_root" ]]; then
      latest_sdk="$(ls -td "$mac_sdk_root"/* 2>/dev/null | awk 'NR==1 {print; exit}')"
      if [[ -n "${latest_sdk:-}" ]]; then
        CIQ_SDK_HOME="$latest_sdk"
      fi
    fi
  fi
fi

if [[ -n "${CIQ_SDK_HOME:-}" ]]; then
  export CIQ_SDK_HOME
  export PATH="$CIQ_SDK_HOME/bin:$PATH"
fi

if [[ -n "${DEV_KEY_PATH:-}" ]]; then
  DEV_KEY="$DEV_KEY_PATH"
elif [[ -f "$ROOT_DIR/developer_key" ]]; then
  DEV_KEY="$ROOT_DIR/developer_key"
else
  DEV_KEY="$HOME/dev/garmin/developer_key.der"
fi

if [[ -z "${CIQ_SDK_HOME:-}" ]]; then
  echo "ERROR: No se pudo detectar CIQ_SDK_HOME automaticamente."
  echo "Define CIQ_SDK_HOME manualmente, por ejemplo:"
  echo "export CIQ_SDK_HOME=\"\$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/<tu-sdk>\""
  exit 1
fi

if [[ ! -f "$DEV_KEY" ]]; then
  echo "ERROR: No existe la clave de desarrollador en $DEV_KEY"
  echo "Puedes copiarla en $ROOT_DIR/developer_key o exportar DEV_KEY_PATH"
  exit 1
fi

echo "Compilando app..."
monkeyc -f "$JUNGLE_FILE" -o "$OUT_FILE" -y "$DEV_KEY"

if ! pgrep -f "ConnectIQ.app|/simulator" >/dev/null 2>&1; then
  echo "Iniciando Connect IQ Simulator..."
  connectiq >/dev/null 2>&1 || true
  sleep 5
fi

echo "Lanzando en simulador ($DEVICE_ID)..."
for attempt in 1 2 3 4; do
  set +e
  monkeydo_output="$(monkeydo "$OUT_FILE" "$DEVICE_ID" 2>&1)"
  monkeydo_code=$?
  set -e

  if [[ $monkeydo_code -eq 0 ]]; then
    exit 0
  fi

  if [[ "$monkeydo_output" == *"Unable to connect to simulator."* ]] && [[ $attempt -lt 4 ]]; then
    echo "Simulador aun no listo, reintentando ($attempt/4)..."
    sleep 2
    continue
  fi

  echo "$monkeydo_output"
  exit "$monkeydo_code"
done

