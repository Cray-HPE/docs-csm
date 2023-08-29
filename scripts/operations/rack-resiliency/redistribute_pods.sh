#!/bin/bash
#
# MIT License
#
# (C) Copyright 2023 Hewlett Packard Enterprise Development LP
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


_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

# What we pass into grep -Ev to exclude from rollouts by default mostly cause
# restarting them is pointless.
SINGLETONS="${SINGLETONS:-nexus}"
DRYRUN=false
DRYRUN="${DRYRUN:-true}"

TMPDIR="${TMPDIR:-/tmp}"
RUNDIR="$(mktemp -d -t tnad-XXXXXXXX)"

cd ${RUNDIR?} || exit 126

trap "rm -fr ${RUNDIR}" EXIT

dryrun() {
  if $DRYRUN; then
    printf "dryrun: %s\n" "$*" >&2
  else
    printf "running: %s\n" "$*" >&2
    eval "$*"
  fi
}

striplines() {
  sed '/^[[:space:]]*$/d'
}

zones=$(kubectl get nodes --selector=topology.kubernetes.io/zone -o jsonpath='{range .items[*]}{.metadata.labels.topology\.kubernetes\.io\/zone}{"\n"}' | striplines | sort -u)
zones_count=$(echo ${zones} | wc -w)

if [ "${zones_count}" -eq 0 ]; then
  printf "no nodes with zone labels setup, refusing to continue\n" >&2
  exit 1
fi

# zone label with node name
zonesbyname=$(kubectl get nodes --selector=topology.kubernetes.io/zone -o jsonpath='{range .items[*]}{.metadata.labels.topology\.kubernetes\.io\/zone} {.metadata.name} {"\n"}' | cut -d "=" -f 2)

# Order is riskiest first then not, so first lets move postgres followers that violate zone constraints
for ns in $(kubectl get ns --no-headers -o custom-columns=":metadata.name" | grep -Ev "(${SINGLETONS})"); do
  for pg in $(kubectl get postgresql --namespace "${ns}" --no-headers -o custom-columns=":metadata.name"); do
    fin=false

    # Only do one at a time and get all data fresh until done
    until $fin; do
      members=$(kubectl get pod --namespace "${ns}" -l "cluster-name=${pg},application=spilo" -o custom-columns=NAME:.metadata.name --no-headers)
      count=$(echo ${members} | wc -w)

      echo "${zonesbyname}" | sort -k2 > zones

      if [ ${count} -gt 1 ]; then
        # only makes sense to move things with more than 1 postgres pod
        for pod in ${members}; do
          leader=$(kubectl --namespace "${ns}" exec "${pod}" --container postgres -- patronictl list --format json 2> /dev/null | jq -r '.[] | select(.Role=="Leader") | .Member')
          if [ "${leader}" != "" ]; then
            fin=true
            break
          fi
        done

        if [ "${leader}" = "" ]; then
          printf "no leader found for %s refusing to continue\n" "${pg}" >&2

          for pod in ${members}; do
            kubectl --namespace "${ns}" exec "${pod}" --container postgres -- patronictl list 2> /dev/null && break
          done
          if ! $DRYRUN; then
            exit 1
          fi
        fi
        # pod name with node name
        pgsbyname=$(kubectl get pod --namespace "${ns}" -l "cluster-name=${pg},application=spilo" --no-headers -o custom-columns="NAME:metadata.name,NODE:spec.nodeName")
        echo "${pgsbyname}" | sort -k2 > pods

        # abusing tempfiles to have join do the silly work for us
        join -j2 -o 1.1,1.2,2.1 pods zones > joined

        # Happy case 1: if zones on pods = zones, all good, nothing to do.
        if [ "$(awk '{print $3}' joined | sort -u | wc -l)" -eq "${zones_count}" ]; then
          if $DRYRUN; then
            printf "dryrun: pg pod#=zone# %s nothing to do\n" "${pg}" >&2
          fi
          fin=true
          # .... I need failure cases to validate logic with
        else
          # Non happy case 1: leader/master/whatever and non that on same zone, kill the non primary pod
          leaderzone=$(cat joined | awk "/${leader}/"' {print $3}')

          cat joined

          echo leader ${leader} zone is $leaderzone

          if [ "$(grep -c ${leaderzone} joined)" -gt 1 ]; then
            printf "dryrun: failure case 1 leader and member pg pods in zone %s, will kill a non leader pod\n" "${leaderzone}" >&2
            choppingblock=$(awk "!/${leader}/ && /${leaderzone}/"' {print $1}' joined | head -n 1)
            dryrun kubectl delete pod --namespace "${ns}" "${choppingblock}"

            if $DRYRUN; then
              fin=true
            fi
          else
            printf "dryrun: failure case 2 multiple member pg pods in a zone, will kill a non leader pod\n" >&2
            # pick a non leader pod to delete, for now lets just kill a random pod
            choppingblock=$(awk "!/${leaderzone}/"' {print $1}' joined | head -n 1)
            dryrun kubectl delete pod --namespace "${ns}" "${choppingblock}"

            if $DRYRUN; then
              fin=true
            fi
          fi

          if ! $DRYRUN; then
            sleep 30
          fi
        fi
      fi
    done
  done
done

# Then etcd cluster members
for ns in $(kubectl get ns --no-headers -o custom-columns=":metadata.name" | grep -Ev "(${SINGLETONS})"); do
  for etcd in $(kubectl get etcdclusters --namespace "${ns}" --no-headers -o custom-columns=":metadata.name"); do
    fin=false

    # Only do one at a time and get all data fresh until done
    until $fin; do
      members=$(kubectl get pod --namespace "${ns}" -l "etcd_cluster=${etcd}" -o custom-columns=NAME:.metadata.name --no-headers)
      count=$(echo ${members} | wc -w)

      echo "${zonesbyname}" | sort -k2 > zones

      if [ ${count} -gt 1 ]; then
        # only makes sense to move things with more than 1 postgres pod
        for pod in ${members}; do
          leader=$(kubectl exec -it --namespace "${ns}" "${pod}" -c etcd -- etcdctl member list 2> /dev/null | awk '/isLeader=true/ {print $2}' | cut -d "=" -f 2 )
          if [ "${leader}" != "" ]; then
            fin=true
            break
          fi
        done

        if [ "${leader}" = "" ]; then
          printf "no leader found for %s refusing to continue\n" "${etcd}" >&2
          for pod in ${members}; do
            kubectl exec -it --namespace "${ns}" "${pod}" -c etcd -- etcdctl member list 2> /dev/null && break
          done
          if ! $DRYRUN; then
            exit 1
          fi

        fi
        # pod name with node name
        etcdbyname=$(kubectl get pod --namespace "${ns}" -l "etcd_cluster=${etcd}" --no-headers -o custom-columns="NAME:metadata.name,NODE:spec.nodeName")
        echo "${etcdbyname}" | sort -k2 > pods

        # abusing tempfiles to have join do the silly work for us
        join -j2 -o 1.1,1.2,2.1 pods zones > joined

        # Happy case 1: if zones on pods = zones, all good, nothing to do.
        if [ "$(awk '{print $3}' joined | sort -u | wc -l)" -eq "${zones_count}" ]; then
          if $DRYRUN; then
            printf "dryrun: etcd pod#=zone# %s nothing to do\n" "${etcd}" >&2
          fi
          fin=true
          # .... I need failure cases to validate logic with
        else
          # Non happy case 1: leader/master/whatever and non that on same zone, kill the non primary pod
          leaderzone=$(cat joined | awk "/${leader}/"' {print $3}')

          cat joined

          echo leader ${leader} zone is $leaderzone

          if [ "$(grep -c ${leaderzone} joined)" -gt 1 ]; then
            printf "dryrun: failure case 1 leader and member etcd pods in zone %s, will kill a non leader pod\n" "${leaderzone}" >&2
            choppingblock=$(awk "!/${leader}/ && /${leaderzone}/"' {print $1}' joined | head -n 1)
            dryrun kubectl delete pod --namespace "${ns}" "${choppingblock}"

            if $DRYRUN; then
              fin=true
            fi
          else
            printf "dryrun: failure case 2 multiple member etcd pods in a zone, will kill a non leader pod\n" >&2
            # pick a non leader pod to delete, for now lets just kill a random pod
            choppingblock=$(awk "!/${leaderzone}/"' {print $1}' joined | head -n 1)
            dryrun kubectl delete pod --namespace "${ns}" "${choppingblock}"

            if $DRYRUN; then
              fin=true
            fi
          fi

          if ! $DRYRUN; then
            sleep 30
          fi
        fi
      else
        printf "dryrun: etcd %s doesn't have more than 1 instance, nothing to move\n" "${etcd}" >&2
        fin=true
      fi
    done
  done
done

# We redeploy all the rollouts last
for ns in $(kubectl get ns --no-headers -o custom-columns=":metadata.name" | grep -Ev '(nexus)'); do
  for deploy in $(kubectl get deployment --namespace "${ns}" --no-headers -o custom-columns=":metadata.name"); do
    dryrun kubectl rollout restart deployment --namespace "${ns}" "${deploy}"
    if ! $DRYRUN; then
      sleep 1 # don't spam everything all at once
    fi
  done
done

# We redeploy all the rollouts last
for ns in $(kubectl get ns --no-headers -o custom-columns=":metadata.name"); do
  for statefulset in $(kubectl get statefulset --namespace "${ns}" --no-headers -o custom-columns=":metadata.name"); do
    dryrun kubectl rollout restart statefulset --namespace "${ns}" "${statefulset}"
    if ! $DRYRUN; then
      sleep 1 # don't spam everything all at once
    fi
  done
done
