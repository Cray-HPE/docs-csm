#! /usr/bin/env bash
#
# MIT License
#
# (C) Copyright 2021-2023 Hewlett Packard Enterprise Development LP
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

if [[ -z "${POSTGRES_SQL_FILE}" ]]; then
    echo "POSTGRES_SQL_FILE environment variable was not defined"
    exit 1
fi

if [[ ! -f "$POSTGRES_SQL_FILE" ]]; then
    echo "POSTGRES_SQL_FILE is not a file: $POSTGRES_SQL_FILE "
    exit 1
fi

if [[ ! $POSTGRES_SQL_FILE =~ \.psql$ ]]; then
    echo "POSTGRES_SQL_FILE does not end with .psql: $POSTGRES_SQL_FILE "
    exit 1
fi

if [[ -z "${POSTGRES_SECRET_MANIFEST}" ]]; then
    echo "POSTGRES_SECRET_MANIFEST environment variable was not defined"
    exit 1
fi

if [[ ! -f "$POSTGRES_SECRET_MANIFEST" ]]; then
    echo "POSTGRES_SECRET_MANIFEST is not a file: $POSTGRES_SECRET_MANIFEST "
    exit 1
fi

if [[ ! $POSTGRES_SECRET_MANIFEST =~ \.manifest$ ]]; then
    echo "POSTGRES_SECRET_MANIFEST does not end with .manifest: $POSTGRES_SECRET_MANIFEST "
    exit 1
fi

# Scale the SLS service down to 0 replicas
echo "Scaling SLS to 0 replicas"
kubectl -n services scale deployment cray-sls --replicas=0
for i in {1..300}; do
    replica_count=$(kubectl -n services get pods -l app.kubernetes.io/name=cray-sls -o json | jq '.items | length')

    echo "Waiting for 0 SLS replicas, currently at $replica_count"

    if [[ "$replica_count" -eq 0 ]]; then
        echo "No SLS replicas are currently running"
        break
    fi

    sleep 1

    if [[ $i -eq 300 ]]; then
        "Error: $c after 5 minutes there are $replica_count replicas remaining"
        exit 1
    fi
done

# Determine the postgres leader
#shellcheck disable=SC2155
export POSTGRES_LEADER=$(kubectl exec cray-sls-postgres-0 -n services -c postgres -t -- patronictl list -f json | jq  -r '.[] | select(.Role == "Leader").Member')
echo "The SLS postgres leader is $POSTGRES_LEADER"

# Temporarily revoke connections to the sls and service_db databases to they can be dropped.
echo "Temporarily revoking connections to the sls and service_db databases"
echo "REVOKE CONNECT ON DATABASE sls FROM public;
REVOKE CONNECT ON DATABASE service_db FROM public;
SELECT pid, pg_terminate_backend(pid)
    FROM pg_stat_activity
    WHERE (datname = 'sls' or datname = 'service_db')  AND pid <> pg_backend_pid();
DROP DATABASE sls;
DROP DATABASE service_db;
" | kubectl exec $POSTGRES_LEADER -n services -c postgres -it -- bash -c "psql -U postgres"

# Restore the sls and service_db databases using the .psql file.
echo "Restoring database from $POSTGRES_SQL_FILE"
cat $POSTGRES_SQL_FILE | kubectl exec $POSTGRES_LEADER -n services -c postgres -it -- bash -c "psql -U postgres"

# Regrant connections to the databases
echo "Regrant connections to the sls and service_db databases"
echo "GRANT CONNECT ON DATABASE sls TO public;
GRANT CONNECT ON DATABASE service_db TO public
" | kubectl exec $POSTGRES_LEADER -n services -c postgres -it -- bash -c "psql -U postgres"


# Delete and reapply secrets for the postgres database.
echo "Removing secrets contains postgres credentials"
kubectl -n services delete secret \
    service-account.cray-sls-postgres.credentials \
    postgres.cray-sls-postgres.credentials \
    standby.cray-sls-postgres.credentials \
    slsuser.cray-sls-postgres.credentials

echo "Apply secrets containing postgres credentials from the backup"
kubectl apply -f "$POSTGRES_SECRET_MANIFEST"

# Restart the postgres pods
echo "Restarting postgres pods"
kubectl -n services delete pods cray-sls-postgres-0 cray-sls-postgres-1 cray-sls-postgres-2

for c in cray-sls-postgres-0 cray-sls-postgres-1 cray-sls-postgres-2; do
    for i in {1..300}; do
        exit_code=0
        echo "Waiting for $c to become ready..."
        kubectl -n services wait "pod/$c" --for condition=ready || exit_code=$?
        if [[ "$exit_code" -eq 0 ]]; then
            break
        fi
        sleep 1

        if [[ $i -eq 300 ]]; then
            "Error: The pod $c was not created within 5 minutes"
            exit 1
        fi
    done
done

echo "Scaling SLS backup to 3 replicas"
kubectl -n services scale deployment cray-sls --replicas=3
kubectl -n services rollout status deployment cray-sls

echo "SLS Postgres has been restored from backup"
