# courseTrack-music (Garmin Connect IQ)

Base mínima para empezar una app Connect IQ (Monkey C) con scripts para simulador, watch y despliegue a dispositivo físico.

## Requisitos

- Java 17+
- Connect IQ SDK instalado
- Variables de entorno (recomendado):
  - `CIQ_SDK_HOME`
  - `PATH` incluyendo `$CIQ_SDK_HOME/bin`
- Developer key en `./developer_key` (raíz del proyecto), o en `~/dev/garmin/developer_key.der`, o vía `DEV_KEY_PATH`

## Configuración rápida (zsh)

```bash
echo 'export CIQ_SDK_HOME="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/<tu-sdk>"' >> ~/.zshrc
echo 'export PATH="$CIQ_SDK_HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Generar key (opción 1, en raíz del proyecto):

```bash
monkeyc -y "./developer_key"
```

## Ejecutar en simulador

```bash
./scripts/dev.sh instinct2
```

Puedes reemplazar `instinct2` por otro target compatible (por ejemplo `venu2` o `fenix7`).

## Hot-reload (watch mode)

```bash
./scripts/watch.sh instinct2
```

Opcionalmente puedes ajustar el intervalo de sondeo (en segundos):

```bash
POLL_SECONDS=0.5 ./scripts/watch.sh instinct2
```

## Despliegue a Garmin físico (USB)

```bash
./scripts/deploy-device.sh instinct2
```

Si el volumen monta en otra ruta:

```bash
GARMIN_MOUNT_PATH="/ruta/del/volumen" ./scripts/deploy-device.sh instinct2
```

