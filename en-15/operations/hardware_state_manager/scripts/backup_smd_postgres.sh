#! /usr/bin/env bash
#
# MIT License
#
# (C) Copyright 2021-2024 Hewlett Packard Enterprise Development LP
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
#
set -eo pipefail

if [[ -z ${BACKUP_FOLDER} ]]; then
  echo "BACKUP_FOLDER environment variable was not defined"
  exit 1
fi
if [[ -z ${BACKUP_NAME} ]]; then
  echo "BACKUP_NAME environment variable was not defined"
  exit 1
fi

mkdir -p "$BACKUP_FOLDER"
pushd "${BACKUP_FOLDER}"
echo "HSM postgres backup file will land in ${BACKUP_FOLDER}"

# Determine the postgres leader
echo "Determining the postgres leader..."
POSTGRES_LEADER=$(kubectl exec cray-smd-postgres-0 -n services -c postgres -t -- patronictl list -f json | jq -r '.[] | select(.Role == "Leader").Member')
echo "The HSM postgres leader is $POSTGRES_LEADER"

# Create PSQL dump of the HSM database
echo "Using pg_dumpall to dump the contents of the HSM database..."
kubectl -n services exec "$POSTGRES_LEADER" -c postgres -it -- bash -c "pg_dumpall --clean -U postgres" > "$BACKUP_NAME.psql"
echo "PSQL dump is available at ${BACKUP_FOLDER}/$BACKUP_NAME.psql"

# Save off k8s secrets needed to restore the postgres database
secrets=(
  service-account.cray-smd-postgres.credentials
  hmsdsuser.cray-smd-postgres.credentials
  postgres.cray-smd-postgres.credentials
  standby.cray-smd-postgres.credentials
)
#shellcheck disable=SC2068
for secret in ${secrets[@]}; do
  filename="${secret}.yaml"
  echo "Saving Kubernetes secret ${secret}"
  kubectl -n services get secret $secret -o yaml > "${filename}"
done

#shellcheck disable=SC2068
for secret in ${secrets[@]}; do
  filename="${secret}.yaml"

  echo "Removing extra fields from ${filename}"
  yq d -i "${filename}" metadata.managedFields
  yq d -i "${filename}" metadata.creationTimestamp
  yq d -i "${filename}" metadata.resourceVersion
  yq d -i "${filename}" metadata.selfLink
  yq d -i "${filename}" metadata.uid
done

#shellcheck disable=SC2068
for secret in ${secrets[@]}; do
  filename="${secret}.yaml"

  echo "Adding Kubernetes secret ${secret} to secret manifest"
  echo '---' >> "${BACKUP_NAME}.manifest"
  cat "${filename}" >> "${BACKUP_NAME}.manifest"
done
echo "Secret manifest is located at ${BACKUP_FOLDER}/${BACKUP_NAME}.manifest"

echo "HSM Postgres backup is available at: ${BACKUP_FOLDER}"
