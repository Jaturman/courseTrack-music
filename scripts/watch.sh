#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_ID="${1:-instinct2}"
POLL_SECONDS="${POLL_SECONDS:-1}"

cd "$ROOT_DIR"

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: Se necesita 'python3' para watch mode."
  exit 1
fi

snapshot() {
  python3 - <<'PY'
import hashlib
import os

files = []
for fixed in ("manifest.xml", "monkey.jungle"):
    if os.path.isfile(fixed):
        files.append(fixed)

for base in ("source", "resources"):
    if not os.path.isdir(base):
        continue
    for root, _, names in os.walk(base):
        for name in names:
            if name.endswith(".mc") or name.endswith(".xml"):
                files.append(os.path.join(root, name))

files = sorted(set(files))
payload = []
for path in files:
    try:
        mtime = int(os.path.getmtime(path))
    except OSError:
        mtime = 0
    payload.append(f"{path}:{mtime}")

print(hashlib.sha256("\n".join(payload).encode("utf-8")).hexdigest())
PY
}

echo "Watch mode activo para simulador: $DEVICE_ID"
echo "Monitoreando cambios en manifest, source y resources..."
echo "Pulsa Ctrl+C para detener."

last="$(snapshot)"

echo
echo "Build inicial..."
"$ROOT_DIR/scripts/dev.sh" "$DEVICE_ID" || true

while true; do
  sleep "$POLL_SECONDS"
  current="$(snapshot)"

  if [[ "$current" != "$last" ]]; then
    echo
    echo "Cambio detectado - recompilando y relanzando..."
    "$ROOT_DIR/scripts/dev.sh" "$DEVICE_ID" || true
    last="$current"
  fi
done

