#!/bin/bash

exec node /app/server.js $IN &

echo "Waiting for ${TARGET} on ${OUT}..."
./wait-for-it.sh $TARGET:$OUT -t 0

ping $OPTS $TARGET
