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

if ! [ -x "$(command -v git)" ]; then
  echo 'Error: git is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v unzip)" ]; then
  echo 'Error: unzip is not installed.' >&2
  exit 1
fi

#Args
POSITIONAL=()
WP_CONTENT_IGNORE=0
LARADOCK_EXISTS_IGNORE=0
SKIP_WP_INSTALL=0
SKIP_COMPOSER_I=0
SKIP_NPM_I=0

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
        --skip-wp-install)
        SKIP_WP_INSTALL=1
        shift
        ;;
        --skip-composer-install)
        SKIP_COMPOSER_I=1
        shift
        ;;
        --skip-npm-install)
        SKIP_NPM_I=1
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
    if [[ $WP_CONTENT_IGNORE -lt 1 ]]; then
        echo "wp-contnet not found";
        echo "Theme wasn't created yet? Run it again with -n flag"
        echo "Wrong call patch? Run it from site root!"
        exit 1
    fi;
fi;

if [[ -d 'laradock' ]]; then
    if [[ $LARADOCK_EXISTS_IGNORE -lt 1 ]]; then
        echo "Laradock folder already exists. Looks like it has been installed!"
        echo "To force reinstall run it again wit -f flag"
        exit 1
    else
        rm -Rf ./laradock
    fi;
fi;

#Laradock
git clone -b master --single-branch https://github.com/laradock/laradock.git \
	&& cd laradock \
	&& git checkout "${LARADOCK_VERSION}" \
  && < ./env-example sed "s+DATA_PATH_HOST=~/\.laradock/data+DATA_PATH_HOST=\./data+" > ./.env

if hash winpty 2>/dev/null; then
    sed -i "s+COMPOSE_PROJECT_NAME=laradock+COMPOSE_PROJECT_NAME=${PROJECT_NAME}+" ./.env
else
    sed -i '' "s+COMPOSE_PROJECT_NAME=laradock+COMPOSE_PROJECT_NAME=${PROJECT_NAME}+" ./.env
fi;

cp ../scripts/openssl-config/nginx-localhost.conf ./nginx/sites/default.conf

if [[ ${EMIT_LOCAL_SSL} -lt 1 ]]; then
    if hash winpty 2>/dev/null; then
        sed -i 's+ ssl_certificate+ #ssl_certificate+' ./nginx/sites/default.conf
        sed -i 's+ listen 443 ssl+ #listen 443 ssl+' ./nginx/sites/default.conf
    else
        sed -i '' 's+ ssl_certificate+ #ssl_certificate+' ./nginx/sites/default.conf
        sed -i '' 's+ listen 443 ssl+ #listen 443 ssl+' ./nginx/sites/default.conf
    fi;
else
    if hash winpty 2>/dev/null; then
        sed -i 's+ #ssl_certificate+ ssl_certificate+' ./nginx/sites/default.conf
        sed -i 's+ #listen 443 ssl+ listen 443 ssl+' ./nginx/sites/default.conf
    else
        sed -i '' 's+ #ssl_certificate+ ssl_certificate+' ./nginx/sites/default.conf
        sed -i '' 's+ #listen 443 ssl+ listen 443 ssl+' ./nginx/sites/default.conf
    fi;
fi;

if hash winpty 2>/dev/null; then
    cp ../scripts/mysql-config/my.cnf ./mysql/my.cnf
    sed -i 's+ARG MYSQL_VERSION=latest+ARG MYSQL_VERSION=8.0+' ./mysql/Dockerfile
fi;

#XDEBUG
if [[ ${XDEBUG} -gt 0 ]] && [[ -n ${XDEBUG_ARTIFACTS} ]]; then
    cp ../scripts/xdebug-config/xdebug.ini ./php-fpm/xdebug.ini
    mkdir -p "../${XDEBUG_ARTIFACTS}" \
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

if [[ ${XDEBUG} -gt 0 ]]; then
     docker-compose up -d --build php-fpm \
         && ./php-fpm/xdebug start \
         && docker-compose down
fi;

#Build workspace without cache
docker-compose build --no-cache workspace && docker-compose down

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
if [[ $SKIP_WP_INSTALL -lt 1 ]]; then
    curl "https://wordpress.org/wordpress-${WP_VERSION}.zip" -o wp.zip \
        && unzip wp.zip \
        && yes | cp -rf ./wordpress/* ./ \
        && rm -rf ./wordpress/ \
        && rm wp.zip \
        && echo "√ WP ${WP_VERSION} has been installed"
else
    echo "√ WP Installation is skipped"
fi;

cd "${SCRIPT_PATH}/..";

#Composer
if [[ $SKIP_COMPOSER_I -lt 1 ]]; then
    if [[ -e "composer.json"  ||  -e "composer.lock" ]]; then
        if hash winpty 2>/dev/null; then
            cd laradock \
                    && docker-compose up -d --build workspace \
                    && winpty docker-compose exec workspace bash -c "composer install" \
                    && echo "√ Composer dependencies installation is done"
            docker-compose down
        else
            cd laradock \
                && docker-compose up -d --build workspace \
                && docker-compose exec workspace composer install \
                    && echo "√ Composer dependencies installation is done"
            docker-compose down
        fi;
    else
        echo "√ Cant perform composer install, skipped. There is no composer or composer files."
    fi;
else
    echo "√ Composer is skipped"
fi;
cd "${SCRIPT_PATH}/..";

#Front
if [[ $SKIP_NPM_I -lt 1 ]]; then
    if hash npm 2>/dev/null && [[ -e "package.json" ||  -e "package-lock.json" ]]; then
        npm i \
            && echo "√ NPM dependencies installation is done"
    else
        echo "√ Cant perform npm i, skipped. There is no npm or package files."
    fi;
else
    echo "√ NPM is skipped"
fi;
