#!/usr/bin/env bash
if [[ -z $1 ]]; then
    echo "Point the path to the project to be covered as argument";
    exit 1;
fi;

PROJECT_PATH=$1

if [[ ! -d $PROJECT_PATH ]]; then
    echo "Given path (${PROJECT_PATH}) is incorrect/don't exist/isn't a directory!";
    exit 1;
fi;

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

cp -R "${SCRIPTPATH}/../scripts" "${PROJECT_PATH}"
