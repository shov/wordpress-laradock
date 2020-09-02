#!/bin/bash

#Dot env
if [[ ! -f /var/www/scripts/.env ]]; then
    echo ".env file not found! SSL Certs emitting is stopped";
    exit 1
else
  set -a
  . /var/www/scripts/.env
  set +a
fi;

#Certs emit process
if [[ ${EMIT_LOCAL_SSL} -lt 1 ]]; then
    echo "Emitting local SSL certs was canceled by env config";
    exit 0;
fi;

mkdir -p /var/www/laradock/nginx/ssl
cd /var/www/laradock/nginx/ssl

if [[ ! -f rootCA.key ]]; then
    openssl genrsa -des3 -passout pass:1234 -out rootCA.key 2048
fi;

if [[ ! -f rootCA.pem ]]; then
    openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 \
        -out rootCA.pem \
        -subj "/C=US/ST=NA/L=NA/commonName=${PROJECT_NAME}" \
        -passin pass:1234
fi;

if [[ ! -f default.csr ]]; then
    openssl req -new -sha256 -nodes \
        -out default.csr -newkey rsa:2048 \
        -keyout default.key \
        -config /var/www/scripts/openssl-config/server.csr.cnf
fi;

if [[ ! -f default.crt ]]; then
    openssl x509 -req -in default.csr \
        -CA rootCA.pem \
        -CAkey rootCA.key \
        -CAcreateserial -out default.crt \
        -days 500 -sha256 -extfile /var/www/scripts/openssl-config/v3.ext \
        -passin pass:1234
fi;