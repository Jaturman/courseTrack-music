#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_ID="${1:-instinct2}"
OUT_FILE="$ROOT_DIR/bin/COURSETRACK-MUSIC.PRG"
JUNGLE_FILE="$ROOT_DIR/monkey.jungle"
GARMIN_MOUNT="${GARMIN_MOUNT_PATH:-/Volumes/GARMIN}"
GARMIN_APPS_DIR="$GARMIN_MOUNT/GARMIN/APPS"

detect_garmin_apps_dir() {
  if [[ -d "$GARMIN_APPS_DIR" ]]; then
    return
  fi

  local candidate=""
  while IFS= read -r candidate; do
    if [[ -d "$candidate/GARMIN/APPS" ]]; then
      GARMIN_MOUNT="$candidate"
      GARMIN_APPS_DIR="$GARMIN_MOUNT/GARMIN/APPS"
      return
    fi
  done < <(ls -d /Volumes/GARMIN* 2>/dev/null || true)
}

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
  exit 1
fi

if [[ ! -f "$DEV_KEY" ]]; then
  echo "ERROR: No existe la clave de desarrollador en $DEV_KEY"
  exit 1
fi

detect_garmin_apps_dir

if [[ ! -d "$GARMIN_APPS_DIR" ]]; then
  echo "ERROR: No se encuentra el reloj montado en '$GARMIN_APPS_DIR'."
  echo "Conecta el Garmin por cable de datos y espera a que monte como unidad."
  echo "Volumenes detectados en /Volumes:"
  ls -1 /Volumes 2>/dev/null || true
  echo "Si monta en otra ruta, usa GARMIN_MOUNT_PATH=/ruta ./scripts/deploy-device.sh"
  exit 1
fi

echo "Compilando app para dispositivo fisico..."
monkeyc -f "$JUNGLE_FILE" -o "$OUT_FILE" -y "$DEV_KEY" -d "$DEVICE_ID" -r

echo "Copiando app a $GARMIN_APPS_DIR..."
export COPYFILE_DISABLE=1
cp -f "$OUT_FILE" "$GARMIN_APPS_DIR/"

if command -v xattr >/dev/null 2>&1; then
  xattr -c "$GARMIN_APPS_DIR/$(basename "$OUT_FILE")" >/dev/null 2>&1 || true
fi

rm -f "$GARMIN_APPS_DIR/._$(basename "$OUT_FILE")" >/dev/null 2>&1 || true

sync || true
echo "Despliegue completado para $DEVICE_ID: $(basename "$OUT_FILE") copiado en $GARMIN_APPS_DIR"

