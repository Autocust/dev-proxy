#!/usr/bin/env sh
set -eu

command -v docker >/dev/null 2>&1 || { echo 'ERRORE: Docker non trovato.' >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo 'ERRORE: Docker Engine non raggiungibile.' >&2; exit 1; }
docker compose version >/dev/null 2>&1 || { echo 'ERRORE: Docker Compose v2 non disponibile.' >&2; exit 1; }
if docker network inspect dev-proxy >/dev/null 2>&1; then
  echo 'OK: rete dev-proxy presente'
else
  echo 'INFO: rete dev-proxy non ancora creata (avvia docker compose up -d)'
fi
if docker compose ps --status running --services 2>/dev/null | grep -qx traefik; then
  echo 'OK: Traefik in esecuzione'
else
  echo 'INFO: Traefik non risulta in esecuzione in questo progetto'
fi
