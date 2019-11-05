#!/bin/bash

if [ ! -d 'wp-content' ]; then
    echo "Wrong call patch, run it from site root!"
    exit 1
fi;

#Dot env
if [[ ! -f "${SCRIPT_PATH}/.env" ]]; then
    echo ".env file not found! The script will use default settings";
else
  set -a
  . "${SCRIPT_PATH}/.env"
  set +a
fi;

DBSERVER=mariadb
if hash winpty 2>/dev/null; then
    DBSERVER=mysql
fi;

if [[ -z ${WEB_SERVER_ENGINE} ]]; then
  WEB_SERVER_ENGINE='nginx'
fi;

SERVICES=(${WEB_SERVER_ENGINE} ${DBSERVER})

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --phpmyadmin)
        SERVICES+=("phpmyadmin")
        if hash winpty 2>/dev/null; then
          sed -i "s+PMA_DB_ENGINE=.*+PMA_DB_ENGINE=${DBSERVER}+" "${SCRIPT_PATH}/../laradock/.env"
        else
          sed -i '' "s+PMA_DB_ENGINE=.*+PMA_DB_ENGINE=${DBSERVER}+" "${SCRIPT_PATH}/../laradock/.env"
        fi;
        shift
        ;;
        *)
        POSITIONAL+=("$1")
        shift
        ;;
    esac
done

cd laradock \
    && docker-compose up -d --build ${SERVICES[*]}
