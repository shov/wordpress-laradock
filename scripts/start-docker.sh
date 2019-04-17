#!/bin/bash

if [ ! -d 'wp-content' ]; then
    echo "Wrong call patch, run it from site root!"
    exit 1
fi;

DBSERVER=mariadb
if hash winpty 2>/dev/null; then
    DBSERVER=mysql
fi;

cd laradock \
    && docker-compose up -d --build nginx ${DBSERVER}
