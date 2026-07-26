# World in Conflict Massgate

This repository focuses on **containerizing** Massgate so the server is easy to
run on modern hardware and infrastructure. It is not an attempt to rewrite or
modernize the game logic itself. **Windows container images are not supported
yet** (`MASSGATE_OS=linux` only).

Massgate is the central online server for *World in Conflict* (accounts, clans,
ladders, dedicated server tracking, etc.). The official service was shut down in
2016; this stack lets you host your own with Docker Compose.

The upstream Massgate code is largely as it was around the original release,
with small changes so it builds on a modern toolchain and no longer requires
CD-key management.

## Quick start

```bash
cp .env.example .env
# fill MYSQL_ROOT_PASSWORD, MYSQL_WRITE_PASSWORD, MYSQL_READ_PASSWORD

docker compose up -d --build
```

Services:

| Service    | Port | Role                                       |
|------------|------|--------------------------------------------|
| `massgate` | 3001 | Massgate server                            |
| `web`      | 80   | Patch / www-root static files              |
| `mysql`    | —    | MySQL 5.7                                  |

On first start MySQL applies `docker/mysql/00-users.sh` and
`docker/mysql/databasestructure.sql` into an empty volume. Changing passwords
later requires recreating `mysql_data` (or updating users manually).

Healthy startup ends with `Server startup sequence OK` in the massgate logs.

## Game / dedicated server

Point the game or `Wic_ds.exe` at your Docker host by adding to the machine
`hosts` file (replace `<docker-host-ip>` with the host’s IP):

```
<docker-host-ip> liveaccount.massgate.net
<docker-host-ip> liveaccountbackup.massgate.net
<docker-host-ip> stats.massgate.net
<docker-host-ip> www.massgate.net
```

For the dedicated server, set in `Wic_ds.ini`:

```
[ReportToMassgate]
1
```

## Contributing

PRs are welcome. The goal of this project is to keep Massgate easy to deploy on
current machines and infra (Docker, Compose, config via `.env`), not to ship a
new game-server rewrite. Improvements to packaging, docs, ops, and small fixes
that help that goal are especially appreciated.
