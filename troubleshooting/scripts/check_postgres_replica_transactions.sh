#!/usr/bin/bash
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
#

# Workaround for CASMTRIAGE-7443
# When a control plane (master) node is rebooted services observe a temporary loss of access to the Kubernetes API via the
# kubernetes service.
#
# Each Postgres cluster maintains its leader lock in the Kubernetes endpoint, when the interruption to the API occurs the lock
# can't be maintained so the leader demotes itself and forces a leadership election. This can result in a different instance taking over
#
# Patroni/Kubernetes does what is it supposed to and updates the database ClusterIP load balancer to point to the new leader
# HOWEVER existing connections are unaffected resulting in clients sending update/read-write transactions to the former leader
# which is now a replica and can't handle them (this is expected PostgreSQL behaviour).
#
# The workaround is to restart any database replica pod to break the connection with it and the database client to force the client
# to connect to the correct IP address.

pg_logdir=/home/postgres/pgdata/pgroot/pg_log

while read namespace pod
do
echo "INFO: Checking ${pod} in namespace ${namespace}"
last_log=$(kubectl -n ${namespace} exec ${pod} -- sh -c "ls -tr1 ${pg_logdir}/*.csv | tail -1")
found=$(kubectl -n ${namespace} exec ${pod}  -- sh -c "tail -50 ${last_log} | egrep -c 'cannot set transaction read-write mode during recovery|cannot execute UPDATE in a read-only transaction'" 2>/dev/null)
if (( found > 0 )); then
	echo "WARN: Restarting PostgreSQL replica Pod ${pod} that is receiving UPDATE transactions"
	kubectl -n ${namespace} delete pod ${pod} >/dev/null
fi
done < <(kubectl get pod -A -l spilo-role=replica -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers)
