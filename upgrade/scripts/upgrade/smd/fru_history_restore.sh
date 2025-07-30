#! /usr/bin/env bash
#
# MIT License
#
# (C) Copyright 2025 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# This script fully replaces the contents of the hwinv_hist table in the
# SMD postgres database with the hwinv_hist backup file that was created
# with the fru_history_backup.sh script.  The BACKUP_FILE env variable must
# be set to the location of the backup.
#
# WARNING: Any hardware events generated between when the backup file was
#          created and the restore operation is performed will be lost!

set -eo pipefail

# Dig into the secrets store to find all necessary connection data
#
# Update SECRET_KEY_REF if it was changed in the SMD chart!

SECRET_KEY_REF="hmsdsuser.cray-smd-postgres.credentials"

DB_USER=$(kubectl get secret -n services $SECRET_KEY_REF -o jsonpath='{.data.username}' | base64 -d)
PGPASSWORD=$(kubectl get secret -n services $SECRET_KEY_REF -o jsonpath='{.data.password}' | base64 -d)

# Additional postgres connection details that should mirror what is set in
# the SMD's chart values.yaml file:

DB_NAME="hmsds"
DB_PORT="5432"
DB_TABLE="hwinv_hist"

# Check that a backup file was specified, exists, and is readable

if [[ -z ${BACKUP_FILE} ]]; then
  echo "Error: BACKUP_FILE environment variable was not defined"
  exit 1
fi

if [[ ! -r "${BACKUP_FILE}" ]]; then
  echo "Error: $BACKUP_FILE does not exist or is not readable" >&2
  exit 1
fi

# Determine the postgres leader

echo "Determining the postgres leader..."

POSTGRES_LEADER=$(kubectl exec cray-smd-postgres-0 -n services -c postgres -t -- patronictl list -f json | jq -r '.[] | select(.Role == "Leader").Member')

echo "The SMD postgres leader is $POSTGRES_LEADER"

# Copy the backup into the container

BACKUP_FILE_BASENAME=$(basename $BACKUP_FILE)

echo "Copying $BACKUP_FILE to /tmp/$BACKUP_FILE_BASENAME in the postgres leader pod"

kubectl cp $BACKUP_FILE services/$POSTGRES_LEADER:/tmp/$BACKUP_FILE_BASENAME -c postgres

# Replace the contents of the hwinv_hist table with the backup

echo "Using psql to restore the $DB_TABLE table usign specified backup"

kubectl -n services exec "$POSTGRES_LEADER" -c postgres -it -- bash -c "psql -U $DB_USER -d $DB_NAME -p $DB_PORT -f /tmp/$BACKUP_FILE_BASENAME"

# Remove the backup from the container to free up space

echo "Removing /tmp/$BACKUP_FILE_BASENAME in the postgres leader pod"

kubectl -n services exec "$POSTGRES_LEADER" -c postgres -it -- bash -c "rm /tmp/$BACKUP_FILE_BASENAME"

echo "Restore complete."

