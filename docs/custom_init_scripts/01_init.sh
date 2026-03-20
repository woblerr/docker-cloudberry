#!/bin/bash
echo "Executing initialization shell script"
psql -U ${CLOUDBERRY_USER} -h $(hostname) -d ${CLOUDBERRY_DATABASE_NAME} -c "INSERT INTO test_initialization (name) VALUES ('Added via shell script');"
echo "Shell script executed successfully!"
