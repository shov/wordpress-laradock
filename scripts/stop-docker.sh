#!/bin/bash

if [ ! -d 'wp-content' ]; then
    echo "Wrong call patch, run it from site root!"
    exit 1
fi;

cd laradock \
    && docker-compose down
