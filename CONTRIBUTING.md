# Contribuire a Dev Proxy

1. Apri una issue o descrivi la modifica in una pull request.
2. Mantieni la compatibilità con Docker Compose v2, macOS e Docker Desktop/WSL2.
3. Non introdurre HTTPS o pubblicazione su interfacce LAN senza discuterne nel team.
4. Verifica `docker compose -f compose.yaml config --quiet` e `docker compose -f examples/compose.yaml config --quiet`.
5. Avvia demo e controlla `curl -i -H 'Host: demo.docker.localhost' http://127.0.0.1/`.
6. Non aggiungere credenziali, token o file `.env` personali.
