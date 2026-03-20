#!/bin/bash
echo "Executing initialization shell script for wal-g"
USER=${CLOUDBERRY_USER} gpconfig -c archive_command -v "/usr/bin/timeout 60 wal-g seg wal-push %p --content-id=%c --config /tmp/wal-g.yaml"
USER=${CLOUDBERRY_USER} gpconfig -c archive_timeout -v 600 --skipvalidation
USER=${CLOUDBERRY_USER} gpstop -u
