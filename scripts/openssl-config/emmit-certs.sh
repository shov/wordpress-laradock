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
if [[ ${EMIT_LOCAL_SSL} < 1 ]]; then
    echo "Emitting local SSL certs was canceled by env config";
    exit 0;
fi;

mkdir -p /var/www/certs-local
cd /var/www/certs-local

if [[ ! -f rootCA.key ]]; then
    openssl genrsa -des3 -passout pass:1234 -out rootCA.key 2048
fi;

if [[ ! -f rootCA.pem ]]; then
    openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 \
        -out rootCA.pem \
        -subj "/C=US/ST=NA/L=NA/commonName=${PROJECT_NAME}" \
        -passin pass:1234
fi;

if [[ ! -f server.csr ]]; then
    openssl req -new -sha256 -nodes \
        -out server.csr -newkey rsa:2048 \
        -keyout server.key \
        -config /var/www/scripts/openssl-config/server.csr.cnf
fi;

if [[ ! -f server.crt ]]; then
    openssl x509 -req -in server.csr \
        -CA rootCA.pem \
        -CAkey rootCA.key \
        -CAcreateserial -out server.crt \
        -days 500 -sha256 -extfile /var/www/scripts/openssl-config/v3.ext \
        -passin pass:1234
fi;