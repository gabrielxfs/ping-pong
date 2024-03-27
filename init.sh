#!/bin/bash

echo "Waiting for ${TARGET}..."
./wait-for-it.sh $TARGET:80 -t 0

ping $OPTS $TARGET
