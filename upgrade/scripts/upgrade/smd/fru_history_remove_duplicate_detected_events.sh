#!/usr/bin/env bash
# MIT License
#
# (C) Copyright [2025] Hewlett Packard Enterprise Development LP
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

# This script manually applies the SMD pruning changes in:
#
#     migrations/postgres/23_fru_history_remove_duplicate_detected_events.up.sql
#
# This is provided outside of a migration so that databases can be pruned
# outside the scope of an SMD upgrade.
#
# If any issues occur, uncomment the following line to aid in debug:
#set -x

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

# Bundle them all into one psql options string

PSQL_OPTS="dbname=$DB_NAME user=$DB_USER port=$DB_PORT"

# Determine the SMD postgres leader

echo "Determining the postgres leader..."

POSTGRES_LEADER=$(kubectl exec cray-smd-postgres-0 -n services -c postgres -t -- patronictl list -f json | jq -r '.[] | select(.Role == "Leader").Member')

echo "The SMD postgres leader is $POSTGRES_LEADER"

# Capture and print sizes before pruning and vacuuming

kubectl -n services exec "$POSTGRES_LEADER" -c postgres -it -- bash -c "
	psql \"$PSQL_OPTS\" -c \"
	DO \\\$\$
	DECLARE
		tbl_size_before    bigint := 0;   /* hwinv_history size before pruning */
		db_size_before     bigint := 0;   /* DB size before pruning */
	BEGIN
		SELECT pg_total_relation_size('hwinv_hist') INTO tbl_size_before;
		SELECT pg_database_size(current_database()) INTO db_size_before;

		RAISE NOTICE 'hwinv_history table size before pruning:  % mb', tbl_size_before / 1024 / 1024;
		RAISE NOTICE 'Database size before pruning:             % mb', db_size_before / 1024 / 1024;
	END;
	\\\$\$ LANGUAGE plpgsql;\"
"

echo ""
echo "Operations may take considerable time - please do not interrupt"

# Creating this index speeds up execution by several orders of magnitude.

echo ""
echo "Creating hwinvhist_id_ts_idx index on hwinv_hist table..."

kubectl -n services exec "$POSTGRES_LEADER" -c postgres -it -- bash -c "
	psql \"$PSQL_OPTS\" -c \
		\"CREATE INDEX IF NOT EXISTS hwinvhist_id_ts_idx ON hwinv_hist (id, \"timestamp\");\"
"

if [[ $? -ne 0 ]]; then
	echo "Error creating temporary timestamp index" >&2
	exit 1
fi

# Run the pruning logic

echo ""
echo "Pruning hwinv_hist table... "

kubectl -n services exec "$POSTGRES_LEADER" -c postgres -it -- bash -c "
	psql \"$PSQL_OPTS\" -c \"
	WITH ordered AS (
		SELECT ctid, id, \"timestamp\", event_type,
			LAG(event_type) OVER (PARTITION BY id ORDER BY \"timestamp\") AS prev_type
		FROM hwinv_hist
		WHERE id IN (
			SELECT loc.id
			FROM hwinv_by_loc loc
			WHERE loc.type IN ('Processor', 'NodeAccel')
		)
	),
	dups AS (
		SELECT ctid
		FROM ordered
		WHERE event_type = 'Detected' AND prev_type = 'Detected'
	)
	DELETE FROM hwinv_hist
	WHERE ctid IN (SELECT ctid FROM dups);\"
"

if [[ $? -ne 0 ]]; then
	echo "Error executing SQL command" >&2
	exit 1
fi

# The pruning logic above removed a large part of the hwinv_hist table. This
# did not however change the teble and database sizes.  In order to free
# space, a vacuum must be run.  Here are the options:
#
#     1. Do nothing
#            * Standard vacuum will eventually run but could be days or weeks
#     2. Standard vacuum
#            * Non-blocking
#            * Frees internal space
#            * Does not return disk space to the OS
#     3. Full vacuum
#            * Blocking - no updates allowed to table until complete
#            * Frees internal space
#            * Returns disk space to the OS
#
# So, run a full vacuum

echo ""
echo "Running VACUUM FULL on hwinv_hist table to reclaim disk space..."

kubectl -n services exec "$POSTGRES_LEADER" -c postgres -it -- bash -c "
	psql \"$PSQL_OPTS\" -c \"VACUUM FULL hwinv_hist;\"
"

if [[ $? -ne 0 ]]; then
	echo "Error running VACUUM FULL" >&2
	exit 1
fi

# Capture and print sizes after pruning and vacuuming

echo ""

kubectl -n services exec "$POSTGRES_LEADER" -c postgres -it -- bash -c "
	psql \"$PSQL_OPTS\" -c \"
	DO \\\$\$
	DECLARE
		tbl_size_after    bigint := 0;   /* hwinv_history size after pruning */
		db_size_after     bigint := 0;   /* DB size after pruning */
	BEGIN
		SELECT pg_total_relation_size('hwinv_hist') INTO tbl_size_after;
		SELECT pg_database_size(current_database()) INTO db_size_after;

		RAISE NOTICE 'hwinv_history table size after pruning:  % mb', tbl_size_after / 1024 / 1024;
		RAISE NOTICE 'Database size after pruning:             % mb', db_size_after / 1024 / 1024;
	END;
	\\\$\$ LANGUAGE plpgsql;\"
"
