#!/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"

#Dot env
if [[ ! -f "${SCRIPT_PATH}/.env" ]]; then
    echo ".env file not found! Installation was stopped";
    exit 1
else
  set -a
  . "${SCRIPT_PATH}/.env"
  set +a
fi;

#Args
POSITIONAL=()
WP_CONTENT_IGNORE=0
LARADOCK_EXISTS_IGNORE=0

while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -n|--no-theme-required)
        WP_CONTENT_IGNORE=1
        shift
        ;;
        -f|--force-reinstall)
        LARADOCK_EXISTS_IGNORE=1
        shift
        ;;
        *)
        POSITIONAL+=("$1")
        shift
        ;;
    esac
done

#Look around
cd "${SCRIPT_PATH}/..";

if [[ ! -d 'wp-content' ]]; then
    if [[ $WP_CONTENT_IGNORE < 1 ]]; then
        echo "wp-contnet not found";
        echo "Theme wasn't created yet? Run it again with -n flag"
        echo "Wrong call patch? Run it from site root!"
        exit 1
    fi;
fi;

if [[ -d 'laradock' ]]; then
    if [[ $LARADOCK_EXISTS_IGNORE < 1 ]]; then
        echo "Laradock folder already exists. Looks like it has been installed!"
        echo "To force reinstall run it again wit -f flag"
        exit 1
    else
        rm -Rf ./laradock
    fi;
fi;

#Laradock
git clone https://github.com/laradock/laradock.git \
	&& cd laradock \
	&& git checkout "${LARADOCK_VERSION}" \
	&& cat ./env-example | sed "s+DATA_PATH_HOST=~/\.laradock/data+DATA_PATH_HOST=\./data+" > ./.env

cp ../scripts/openssl-config/nginx-localhost.conf ./nginx/sites/default.conf

if [[ ${EMIT_LOCAL_SSL} < 1 ]]; then
    if hash winpty 2>/dev/null; then
        sed -i 's+ ssl_certificate+ #ssl_certificate+' ./nginx/sites/default.conf
    else
        sed -i '' 's+ ssl_certificate+ #ssl_certificate+' ./nginx/sites/default.conf
    fi;
else
    if hash winpty 2>/dev/null; then
        sed -i 's+ #ssl_certificate+ ssl_certificate+' ./nginx/sites/default.conf
    else
        sed -i '' 's+ #ssl_certificate+ ssl_certificate+' ./nginx/sites/default.conf
    fi;
fi;

if hash winpty 2>/dev/null; then
    cp ../scripts/mysql-config/my.cnf ./mysql/my.cnf
    sed -i 's+ARG MYSQL_VERSION=latest+ARG MYSQL_VERSION=8.0+' ./mysql/Dockerfile
fi;

#XDEBUG
if [[ ${XDEBUG} > 0 ]] && [[ ! -z ${XDEBUG_ARTIFACTS} ]]; then
    cp ../scripts/xdebug-config/xdebug.ini ./php-fpm/xdebug.ini
    mkdir -d "../${XDEBUG_ARTIFACTS}" \
        && chmod 777 "../${XDEBUG_ARTIFACTS}" \
        && mkdir "../${XDEBUG_ARTIFACTS}/profiling" \
        && chmod 777 "../${XDEBUG_ARTIFACTS}/profiling"

    if hash winpty 2>/dev/null; then
        sed -i 's+XDEBUG=false+XDEBUG=true+' ./.env
        sed -i 's+pecl install xdebug;+pecl install xdebug-2.6.0;+' ./php-fpm/Dockerfile
    else
        sed -i '' 's+XDEBUG=false+XDEBUG=true+' ./.env
        sed -i '' 's+pecl install xdebug;+pecl install xdebug-2.6.0;+' ./php-fpm/Dockerfile
    fi;
fi;

docker-compose build --no-cache php-fpm && docker-compose down

if [[ ${XDEBUG} > 0 ]]; then
     docker-compose up -d --build php-fpm \
         && ./php-fpm/xdebug start \
         && docker-compose down
fi;

cd ..

#OpenSSL for localhost
if hash winpty 2>/dev/null; then
    cd laradock \
            && docker-compose up -d --build php-fpm \
            && winpty docker-compose exec php-fpm bash -c "bash /var/www/scripts/openssl-config/emmit-certs.sh"
    docker-compose down
else
    cd laradock \
        && docker-compose up -d --build php-fpm \
        && docker-compose exec php-fpm /var/www/scripts/openssl-config/emmit-certs.sh
    docker-compose down
fi;
cd ..

#Wordpress
curl "https://wordpress.org/wordpress-${WP_VERSION}.zip" -o wp.zip \
    && unzip wp.zip \
    && yes | cp -rf ./wordpress/* ./ \
    && rm -rf ./wordpress/

#Front
cd "${SCRIPT_PATH}/..";

if [[ -e "package.json" ]] || [[ -e "package-lock.json" ]]; then
    npm i
fi;
