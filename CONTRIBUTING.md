# Contributing to Dev Proxy

1. Open an issue or describe the change in a pull request.
2. Keep compatibility with Docker Compose v2, macOS and Docker Desktop/WSL2.
3. Do not introduce HTTPS or publishing on LAN interfaces without discussing it with the team first.
4. Verify `docker compose -f compose.yaml config --quiet` and `docker compose -f examples/compose.yaml config --quiet`.
5. Start the demo and check `curl -i -H 'Host: demo.docker.localhost' http://127.0.0.1/`.
6. Do not add credentials, tokens or personal `.env` files.
