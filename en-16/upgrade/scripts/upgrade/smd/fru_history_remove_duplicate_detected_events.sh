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

# Capture start time
START_TIME=$(date +%s)

# Batch size for DELETE operations - tune based on available memory
# Smaller batches = slower but safer for memory-constrained environments
# Larger batches = faster but require more memory
# Set to a number to limit batch size (e.g., 250000)
# Default: ALL (process all duplicates in one batch)
BATCH_SIZE="${BATCH_SIZE:-ALL}"

# Maximum number of batches to process before exiting
# Useful for processing large datasets incrementally to avoid pod crashes
# Set to 0 for unlimited (process all duplicates)
# Default: 0 (unlimited)
MAX_BATCHES="${MAX_BATCHES:-0}"

# Sleep delay between batches to allow replication to catch up
# Increase if experiencing replication lag or resource contention
# Default: 1 second
REPLICATION_SLEEP_DELAY="${REPLICATION_SLEEP_DELAY:-1}"

# Vacuum type - controls disk space reclamation
# FULL: Returns disk space to OS, but requires up to 2x table size and blocks writes
# ANALYZE: Safer for large tables, frees space for reuse but doesn't return to OS
# Default: FULL
VACUUM_TYPE="${VACUUM_TYPE:-FULL}"

# Validate VACUUM_TYPE
case "$VACUUM_TYPE" in
  FULL | ANALYZE)
    # Valid option
    ;;
  *)
    echo "Error: Invalid VACUUM_TYPE='$VACUUM_TYPE'" >&2
    echo "Valid options: FULL or ANALYZE" >&2
    exit 1
    ;;
esac

echo "Batch size:        $BATCH_SIZE (ALL = unlimited)"
echo "Max batches:       $MAX_BATCHES (0 = unlimited)"
echo "Replication delay: $REPLICATION_SLEEP_DELAY seconds between batches"
echo "Vacuum type:       $VACUUM_TYPE"
echo ""
echo "Set BATCH_SIZE, MAX_BATCHES, REPLICATION_SLEEP_DELAY, and VACUUM_TYPE variables to override"
echo ""

# Dig into the secrets store to find all necessary connection data
#
# Update SECRET_KEY_REF if it was changed in the SMD chart!

SECRET_KEY_REF="hmsdsuser.cray-smd-postgres.credentials"

DB_USER=$(kubectl get secret -n services $SECRET_KEY_REF -o jsonpath='{.data.username}' | base64 -d)
PGPASSWORD=$(kubectl get secret -n services $SECRET_KEY_REF -o jsonpath='{.data.password}' | base64 -d)
export PGPASSWORD

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
echo ""

# Capture and print sizes before pruning and vacuuming

kubectl -n services exec "$POSTGRES_LEADER" -c postgres -it -- bash -c "
	psql \"$PSQL_OPTS\" -c \"
	DO \\\$\$
	DECLARE
		tbl_len_before     bigint := 0;   /* hwinv_history row count before pruning */
		tbl_size_before    bigint := 0;   /* hwinv_history size before pruning */
		db_size_before     bigint := 0;   /* DB size before pruning */
	BEGIN
		SELECT COUNT(*) FROM hwinv_hist INTO tbl_len_before;
		SELECT pg_total_relation_size('hwinv_hist') INTO tbl_size_before;
		SELECT pg_database_size(current_database()) INTO db_size_before;

		RAISE NOTICE 'hwinv_history row count before pruning:    %', to_char(tbl_len_before, 'FM999,999,999,999');
		RAISE NOTICE 'hwinv_history table size before pruning:   % mb', tbl_size_before / 1024 / 1024;
		RAISE NOTICE 'Database size before pruning:              % mb', db_size_before / 1024 / 1024;
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

# Run the pruning logic in batches to avoid memory exhaustion
# This approach processes data in chunks to prevent OOM issues

echo ""
echo -n "Pruning hwinv_hist table "

BATCH_COUNT=0
TOTAL_DELETED=0

while true; do
  BATCH_COUNT=$((BATCH_COUNT + 1))

  # Run the delete (limited to BATCH_SIZE) and capture full output
  OUTPUT=$(kubectl -n services exec "$POSTGRES_LEADER" -c postgres -it -- bash -c "
		psql \"$PSQL_OPTS\" -c \"
		DO \\\$\\\$
		DECLARE
			rows_deleted INTEGER;
		BEGIN
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
				LIMIT $BATCH_SIZE
			)
			DELETE FROM hwinv_hist
			WHERE ctid IN (SELECT ctid FROM dups);

			GET DIAGNOSTICS rows_deleted = ROW_COUNT;
			RAISE NOTICE '%', rows_deleted;
		END;
		\\\$\\\$;\"
	" 2>&1)

  # Check for errors
  if [[ $? -ne 0 ]]; then
    echo ""
    echo "$OUTPUT"
    echo ""
    echo "Error executing SQL command" >&2
    exit 1
  fi

  # Extract the row count from NOTICE output (last NOTICE line only)
  DELETED=$(echo "$OUTPUT" | grep "NOTICE:" | tail -1 | grep -oE '[0-9]+')

  # If nothing deleted then we're done
  if [[ -z $DELETED || $DELETED -eq 0 ]]; then
    BATCH_COUNT=$((BATCH_COUNT - 1))
    break
  fi

  TOTAL_DELETED=$((TOTAL_DELETED + DELETED))

  # Print progress indicator
  echo -n "."

  # If batch size is ALL, we are done after one iteration
  if [[ $BATCH_SIZE == "ALL" ]]; then
    break
  fi

  # Check if we've reached the maximum batch limit
  if [[ $MAX_BATCHES -gt 0 && $BATCH_COUNT -ge $MAX_BATCHES ]]; then
    echo ""
    echo "Reached maximum batch limit of $MAX_BATCHES batches"
    break
  fi

  # Small delay to allow replication to catch up and resources to be freed
  sleep $REPLICATION_SLEEP_DELAY
done

echo ""
if [[ $MAX_BATCHES -gt 0 && $TOTAL_DELETED -gt 0 && $BATCH_COUNT -ge $MAX_BATCHES ]]; then
  echo "Partial pruning complete: $TOTAL_DELETED rows deleted across $BATCH_COUNT batches (limit reached)"
  echo "Run script again to continue processing remaining duplicates"
else
  echo "Pruning complete: $TOTAL_DELETED total rows deleted across $BATCH_COUNT batches"
fi

# The pruning logic above removed a large part of the hwinv_hist table. This
# did not however change the table and database sizes.  In order to free
# space, a vacuum must be run.  Here are the options:
#
#     1. Do nothing
#            * Standard vacuum will eventually run but could be days or weeks
#     2. VACUUM ANALYZE
#            * Non-blocking
#            * Frees internal space for reuse
#            * Does not return disk space to the OS
#            * Much less memory-intensive than VACUUM FULL
#            * Safer for large tables
#     3. VACUUM FULL
#            * Blocking - no updates allowed to table until complete
#            * Frees internal space for reuse
#            * Returns disk space to the OS
#            * Requires up to 2x table size in free disk space
#            * Very memory-intensive and can crash pods on large tables
#
# The VACUUM_TYPE variable controls which approach is used

echo ""
echo "Running VACUUM $VACUUM_TYPE on hwinv_hist table..."

kubectl -n services exec "$POSTGRES_LEADER" -c postgres -it -- bash -c "
	psql \"$PSQL_OPTS\" -c \"VACUUM $VACUUM_TYPE hwinv_hist;\"
"

if [[ $? -ne 0 ]]; then
  echo "Error running VACUUM $VACUUM_TYPE" >&2
  exit 1
fi

# Capture and print sizes after pruning and vacuuming

echo ""

kubectl -n services exec "$POSTGRES_LEADER" -c postgres -it -- bash -c "
	psql \"$PSQL_OPTS\" -c \"
	DO \\\$\$
	DECLARE
		tbl_len_after     bigint := 0;   /* hwinv_history row count after pruning */
		tbl_size_after    bigint := 0;   /* hwinv_history size after pruning */
		db_size_after     bigint := 0;   /* DB size after pruning */
	BEGIN
		SELECT COUNT(*) FROM hwinv_hist INTO tbl_len_after;
		SELECT pg_total_relation_size('hwinv_hist') INTO tbl_size_after;
		SELECT pg_database_size(current_database()) INTO db_size_after;

		RAISE NOTICE 'hwinv_history row count after pruning:    %', to_char(tbl_len_after, 'FM999,999,999,999');
		RAISE NOTICE 'hwinv_history table size after pruning:   % mb', tbl_size_after / 1024 / 1024;
		RAISE NOTICE 'Database size after pruning:              % mb', db_size_after / 1024 / 1024;
	END;
	\\\$\$ LANGUAGE plpgsql;\"
"

# Calculate and display total execution time
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

HOURS=$((ELAPSED / 3600))
MINUTES=$(((ELAPSED % 3600) / 60))
SECONDS=$((ELAPSED % 60))

echo ""
echo "Total execution time: ${HOURS}h ${MINUTES}m ${SECONDS}s"
