# Dev Proxy

Reverse proxy HTTP locale e condiviso per progetti **Docker Compose (non Swarm)**. Ogni sviluppatore avvia una sola istanza di Traefik; tutti i repository applicativi possono essere accesi contemporaneamente senza contendersi la porta 80.

**Piattaforme:** macOS e Windows con Docker Desktop + WSL2. **Protocollo:** solo HTTP, nessun certificato e nessuna configurazione HTTPS. Non è destinato alla produzione.

## Architettura

```text
Browser macOS / Windows
       |
       | http://app.progetto-a.localhost
       | http://app.progetto-b.localhost
       v
127.0.0.1:80  ->  Traefik (questo repository)
                        |
                 rete Docker dev-proxy
                    /           \
            Nginx stack A    Nginx stack B
             :80 interno     :80 interno
```

Traefik scopre i servizi tramite le **label Docker**. I singoli progetti mantengono la propria rete `default`; si collega alla rete condivisa soltanto il servizio di ingresso (es. Nginx).

## Requisiti

- Docker Desktop o Docker Engine funzionante, con `docker compose` (Compose v2).
- Porta TCP **80** del computer libera.
- Su Windows: Docker Desktop con backend WSL2 e integrazione abilitata nella distro Linux in cui si lavora. Usare lo **stesso Docker Engine** per proxy e stack applicativi.

## Avvio (Mac / WSL2)

Clona questo repository ed esegui dalla sua directory:

```bash
docker compose up -d
docker compose ps
sh scripts/check.sh
```

La rete `dev-proxy` viene creata automaticamente al primo avvio e rimane utilizzabile dagli stack applicativi mentre il proxy è attivo.

> Non avviare un secondo Traefik per ogni repository applicativo: il proxy locale è **uno per computer**, non uno per stack.

## Test immediato

In una seconda shell:

```bash
docker compose -f examples/compose.yaml up -d
curl -i -H 'Host: demo.docker.localhost' http://127.0.0.1/
```

Se funziona, otterrai una risposta HTTP del container `whoami`, con informazioni sulla richiesta. Prova anche nel browser `http://demo.docker.localhost`.

In Windows PowerShell puoi usare:

```powershell
curl.exe -i -H "Host: demo.docker.localhost" http://127.0.0.1/
```

**Perché il test con `Host`?** Verifica il routing anche se il browser o il resolver locale non risolvono ancora i sottodomini `.localhost`.

Per spegnere la demo:

```bash
docker compose -f examples/compose.yaml down
```

## Collegare un progetto esistente

Nel `compose.yaml` del **progetto applicativo**:

1. Rimuovi dal servizio Nginx la pubblicazione di porta `80:80` (`ports`). Nginx resta in ascolto sulla porta **80 interna** al container.
2. Collega **Nginx** sia alla rete del suo progetto (`default`) sia a `dev-proxy`.
3. Aggiungi al servizio Nginx le label Traefik. Scegli nomi univoci per router e service in tutta la macchina.
4. Dichiara `dev-proxy` come rete `external: true`.

Frammento di riferimento in [`examples/project-nginx.compose.example.yaml`](examples/project-nginx.compose.example.yaml): **non è un Compose avviabile da solo**, va integrato nel Compose reale mantenendo immagini, volumi, servizi e dipendenze già presenti.

Esempio minimo di label sul servizio Nginx:

```yaml
labels:
  - traefik.enable=true
  - traefik.docker.network=dev-proxy
  - traefik.http.routers.progetto-a.rule=Host(`app.progetto-a.localhost`)
  - traefik.http.routers.progetto-a.entrypoints=web
  - traefik.http.routers.progetto-a.service=progetto-a
  - traefik.http.services.progetto-a.loadbalancer.server.port=80
```

Con due stack:

- `http://app.progetto-a.localhost` -> Nginx del progetto A
- `http://app.progetto-b.localhost` -> Nginx del progetto B

Le regole `Host(...)` indirizzano il traffico. **Traefik inoltra l'header Host originale**: se Nginx usa `server_name`, aggiornalo per far corrispondere gli hostname oppure aggiungi il nuovo nome al virtual host appropriato.

### Più virtual host nello stesso Nginx

Puoi creare più router che puntano allo **stesso service Traefik** usando label con nomi distinti, oppure una singola regola con OR:

```yaml
- traefik.http.routers.progetto-a.rule=Host(`app.progetto-a.localhost`) || Host(`api.progetto-a.localhost`)
```

Assicurati che Nginx abbia configurato entrambi i `server_name` se deve distinguerli.

## Risoluzione dei domini `.localhost`

I browser moderni trattano normalmente `.localhost` e i relativi sottodomini come indirizzi locali, ma non tutti gli strumenti CLI o resolver di sistema garantiscono lo stesso comportamento. **Non fare affidamento su una wildcard universale.**

Se un hostname non si risolve, inserisci una voce esplicita nel file hosts della macchina **da cui si apre il browser**:

```text
127.0.0.1 app.progetto-a.localhost
127.0.0.1 api.progetto-a.localhost
127.0.0.1 app.progetto-b.localhost
```

- **macOS:** `/etc/hosts` (modifica con privilegi amministrativi).
- **Windows (browser Windows):** `C:\Windows\System32\drivers\etc\hosts` (editor avviato come amministratore).
- **WSL2:** `/etc/hosts` dentro la distro, se la richiesta proviene dagli strumenti Linux; può essere rigenerato da WSL in alcune configurazioni.

Non usare `.local` per i nuovi nomi: su macOS può interferire con Bonjour/mDNS.

## Comandi quotidiani

```bash
# Avvio proxy (dalla root di questo repository)
docker compose up -d

# Stato e log
docker compose ps
docker compose logs -f traefik

# Arresto senza cancellare la rete
docker compose stop

# Riavvio
docker compose start
```

Nei repository applicativi il team continua a usare i normali `docker compose up -d` e `docker compose down`.

**Attenzione:** `docker compose down` eseguito *qui* può rimuovere la rete `dev-proxy` solo quando non è più utilizzata da altri container; se la rete è ancora usata, Docker può segnalare errore e lasciarla intatta. Per l'uso quotidiano preferisci `stop` / `start`.

## Risoluzione problemi

| Sintomo | Verifica / soluzione |
| --- | --- |
| `port is already allocated` su 80 | Un vecchio Nginx, Apache, IIS o un altro proxy pubblica già la porta 80. Libera la porta. |
| `404 page not found` da Traefik | Il router non corrisponde all'header `Host`, oppure le label non sono state applicate. Controlla hostname e `docker compose logs traefik`. |
| `502 Bad Gateway` / `504` | Verifica che Nginx sia in esecuzione, ascolti davvero sulla porta interna configurata e sia collegato a `dev-proxy`. |
| Il browser non apre `*.localhost` | Prova prima `curl -H 'Host: ...' http://127.0.0.1`; poi aggiungi una voce hosts esplicita. Controlla anche eventuali proxy/VPN del browser. |
| Nginx restituisce il sito sbagliato | Correggi i `server_name` di Nginx: riceve il `Host` originale. |
| WSL2 funziona, browser Windows no | Verifica la pubblicazione porta di Docker Desktop, Docker context, il file hosts **di Windows** e possibili proxy/firewall. |

Verifica rete e servizio:

```bash
docker network inspect dev-proxy
docker compose ps
docker compose logs --tail=100 traefik
```

## Sicurezza e limiti

- **Solo sviluppo locale:** `127.0.0.1:80:80` limita la pubblicazione all'host locale; non aprire il proxy alla LAN senza valutare le implicazioni.
- **Niente HTTPS:** non usare questa configurazione per servizi che richiedono cookie `Secure`, login OAuth con redirect HTTPS obbligatorio o scenari che richiedono TLS.
- **Docker socket:** il mount `:ro` impedisce modifiche al file socket dal container, **non** rende l'API Docker priva di rischi. Chi accede all'API Docker può disporre di privilegi molto elevati; utilizzare solo in workstation fidate. Un Docker socket proxy con permessi limitati è un possibile miglioramento futuro.
- **Discovery:** `exposedbydefault=false` richiede `traefik.enable=true`; non considerarlo un confine di sicurezza tra container nello stesso Docker Engine.
- Nessuna configurazione Docker Swarm, nessun dashboard amministrativo esposto, nessun servizio pubblico.

## Contribuire

Per modifiche al proxy: crea un branch, apri una pull request, verifica `docker compose config --quiet` e prova la demo su almeno una workstation. Le label dei singoli progetti vanno mantenute nei rispettivi repository, non qui.

## Riferimenti

- [Traefik — Docker provider](https://doc.traefik.io/traefik/reference/install-configuration/providers/docker/)
- [Docker — Compose networking](https://docs.docker.com/compose/how-tos/networking/)
- [Docker Desktop — WSL2](https://docs.docker.com/desktop/features/wsl/)
