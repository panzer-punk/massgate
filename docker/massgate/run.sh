#!/bin/bash
set -euo pipefail

envsubst '${MYSQL_WRITE_PASSWORD} ${MYSQL_READ_PASSWORD}' \
  < /app/config.ini.template > /app/config.ini

if [[ ! -d "${WINEPREFIX:-/app/.wine}/drive_c" ]]; then
  wineboot --init
fi

exec wine /app/Massgate.exe live -noboom -all -dbname live -massgateport 3001 -logsql
