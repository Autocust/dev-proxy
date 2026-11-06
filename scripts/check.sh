#!/usr/bin/env sh
set -eu

command -v docker >/dev/null 2>&1 || { echo 'ERROR: Docker not found.' >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo 'ERROR: Docker Engine not reachable.' >&2; exit 1; }
docker compose version >/dev/null 2>&1 || { echo 'ERROR: Docker Compose v2 not available.' >&2; exit 1; }
if docker network inspect dev-proxy >/dev/null 2>&1; then
  echo 'OK: dev-proxy network present'
else
  echo 'INFO: dev-proxy network not created yet (run docker compose up -d)'
fi
if docker compose ps --status running --services 2>/dev/null | grep -qx traefik; then
  echo 'OK: Traefik is running'
else
  echo 'INFO: Traefik does not appear to be running in this project'
fi
