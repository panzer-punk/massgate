# World in Conflict Massgate

This repository focuses on **containerizing** Massgate so the server is easy to
run on modern hardware and infrastructure. It is not an attempt to rewrite or
modernize the game logic itself.

Massgate is the central online server for *World in Conflict* (accounts, clans,
ladders, dedicated server tracking, etc.). The official service was shut down in
2016; this stack lets you host your own with Docker Compose.

The upstream Massgate code is largely as it was around the original release,
with small changes so it builds on a modern toolchain and no longer requires
CD-key management.

This build speaks the **original Massgate protocol version 140** (vanilla /
unpatched clients and dedicated servers). Community “fan” patches bump the
protocol to **150** and break compatibility with this server. Support for the
fan patch is planned but **not guaranteed** — follow
[issues](https://github.com/panzer-punk/massgate/issues) for status.

## Quick start

```bash
cp .env.example .env
# fill MYSQL_ROOT_PASSWORD, MYSQL_WRITE_PASSWORD, MYSQL_READ_PASSWORD
# optional: MASSGATE_OS=linux (default) — see Runners below

docker compose up -d --build
```

Services:

| Service    | Port | Role                                       |
|------------|------|--------------------------------------------|
| `massgate` | 3001 | Massgate server                            |
| `web`      | 80   | Patch / `www-root` static files            |
| `mysql`    | —    | MySQL 5.7                                  |

On first start MySQL applies `docker/mysql/00-users.sh` and
`docker/mysql/databasestructure.sql` into an empty volume. Changing passwords
later requires recreating `mysql_data` (or updating users manually).

Healthy startup ends with `Server startup sequence OK` in the massgate logs.

## Runners

The `massgate` image target is selected with **`MASSGATE_OS`** (see `.env.example`).
Compose builds `target: ${MASSGATE_OS}-runner`.

| Value / target     | Status | Notes |
|--------------------|--------|-------|
| `linux` → `linux-runner` | Available | Default. Cross-builds the Win32 Massgate binary and runs it under Wine on Ubuntu. |
| `windows` → `windows-runner` | **Not implemented yet** (**recommended** long-term) | Native Windows container runner. Planned for the **1.0** release. |

Until `windows-runner` ships, use `MASSGATE_OS=linux`.

## Game / dedicated server

Point the game or `Wic_ds.exe` at your Docker host by adding to the machine
`hosts` file (replace `<docker-host-ip>` with the host’s IP):

```
<docker-host-ip> liveaccount.massgate.net
<docker-host-ip> liveaccountbackup.massgate.net
<docker-host-ip> stats.massgate.net
<docker-host-ip> www.massgate.net
```

For the community fan patch, use the same hostnames with **`.org`** instead of
**`.net`** (for example `liveaccount.massgate.org`). That only redirects the
client; this server still speaks protocol **140**, so a patched (**150**) client
will not work until fan-patch support lands.

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
