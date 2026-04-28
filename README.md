# courseTrack-music (Garmin Connect IQ)

Base mínima para empezar una app Connect IQ (Monkey C) con scripts para simulador, watch y despliegue a dispositivo físico.


## Ejecutar en simulador
./scripts/dev.sh instinct2

## Hot-reload (watch mode)
./scripts/watch.sh instinct2

  Opcionalmente puedes ajustar el intervalo de sondeo (en segundos):
  POLL_SECONDS=0.5 ./scripts/watch.sh instinct2

## Despliegue a Garmin físico (USB)
./scripts/deploy-device.sh instinct2



