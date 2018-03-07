#!/bin/bash

HARBOR_ADDR=192.168.0.1
PROJECT=library
IMAGE_NAME=crontab-cleanup-ela-data
VERSON=1.0

docker build --network=host -t $HARBOR_ADDR/$PROJECT/$IMAGE_NAME:$VERSON ./
