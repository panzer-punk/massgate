#!/bin/bash
set -e

mysql -u root -p${DB_ROOT_PASSWORD} <<EOF
create database live;
grant all on live.* to '${DB_USER}'@'localhost' identified by '${DB_PASSWORD}';
grant all on live.* to '${DB_USER}'@'localhost' identified by '${DB_PASSWORD}';
EOF