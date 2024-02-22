#!/usr/bin/env sh
#
# MIT License
#
# (C) Copyright 2022-2023 Hewlett Packard Enterprise Development LP
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

# Where we store all our temp dirs/files
RUNDIR="${TMPDIR:-/tmp}/encryption-tmp-$$"

# Let us control how long we wait for deletes or other kubectl ... --timeout actions
KUBETIMEOUT="${KUBETIMEOUT:-300s}"

cleanup() {
  rm -fr "${RUNDIR}"
}

trap cleanup EXIT

# Secret data length must be 16, 24, or 32 bytes long or it is invalid. A valid
# secret's data can only be 16, 24, or 32 bytes long, according to the k8s documentation and testing.
# If we provide data of any length that isn't these lengths, k8s will *not* start.
validatelen() {
  len=$(echo "$@" | awk '{print length}')
  if [ 16 -eq "${len}" ] \
    || [ 24 -eq "${len}" ] \
    || [ 32 -eq "${len}" ]; then
    return "${len}"
  fi
  return 0
}

# Allow aescbc or aesgcm provider types only
validprovider() {
  provider=${1:-invalid}
  if [ "aesgcm" = "${provider}" ] || [ "aescbc" = "${provider}" ]; then
    return 1
  fi
  return 0
}

validateinput() {
  identok=0
  ok=0
  encryptionsetup=""

  if [ $# -eq 0 ]; then
    printf "fatal: bug? no args passed to validateinput()\n" >&2
    return 1
  fi

  # Non odd number of args is definitely wrong
  if [ $(($# % 2)) -ne 1 ]; then
    printf "fatal: bug? even number of args for validateinput()\n" >&2
    return 1
  fi

  # Shift through args to find identity string and build up the encryption setup
  until [ $# -eq 0 ]; do
    input=${1:-nothing}
    shift > /dev/null 2>&1 || :

    if [ "identity" = "${input}" ]; then
      identok=$((identok + 1))
      encryptionsetup="${encryptionsetup-}${encryptionsetup:+ }identity"
      continue
    fi

    if ! validprovider "${input}"; then
      key=${1:-none}
      shift || :

      if ! validatelen "${key}"; then
        sha=$(echo "${key}" | sha256sum | awk '{print $1}')
        name="${input}-${sha}"
        # Note: printf to ensure we're not passing in newlines no matter what
        # shell we're run against.
        b64secret=$(printf "%s" "${key}" | base64)

        encryptionsetup="${encryptionsetup-}${encryptionsetup:+ }${name} ${b64secret}"
      else
        printf "fatal: invalid key length\n" >&2
        ok=$((ok + 1))
      fi
    else
      printf "fatal: invalid provider specified %s\n" "${input}" >&2
      ok=$((ok + 1))
      shift > /dev/null 2>&1 || :
    fi
  done

  if [ ${ok} -ne 0 ]; then
    return 1
  fi

  if [ ${identok} -eq 0 ]; then
    printf "fatal: bug? no identity provider provided for validateinput()\n" >&2
    return 1
  elif [ ${identok} -ne 1 ]; then
    printf "fatal: bug? more than one identity arg provided to validateinput()\n" >&2
    return 1
  fi

  printf "%s" "${encryptionsetup}"
  return ${ok}
}

# Note identity is a "special" secret allowing a caller to control where/when
# the identity provider shows up in the list
#
# Called like so:
# - encryptionconfig identity aescbc:keydata aesgcm:keydata
# - encryptionconfig identity aescbc:keydata aescbc:keydata
# - encryptionconfig aescbc:keydata aescbc:keydata identity
# - encryptionconfig identity
# - etc.....
# - Note that a call of encryptionconfig identity should only occur when turning encryption off entirely after it was on.
# - Identity is *always* required, it controls where in the provider array the identity provider shows up. This is used for key rotation and to bring k8s up when switching to a new encryption key. As any data is not encrypted at that point in etcd we need to be able to read the data to re-encrypt later.
# - Note: identity is an internal only thing, users don't specify this directly but implicitly by turning encryption on or off.
# - Order of callers determines what will/can be used for encryption.
# - Note: This encryptionconfig could use some cleaning up in how it lays out providers less redundantly. But an added bonus is it makes positional keys easy to specify.
encryptionconfig() {
  # we do not want this here actually
  #shellcheck disable=SC2086
  cat << FIN
---
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
$(sutencryptionconfig "$@")
FIN
}

sutencryptionconfig() {
  curr=""
  until [ $# -eq 0 ]; do
    curr="${1}"
    shift

    if [ "identity" = "${curr}" ]; then
      cat << FIN
      - identity: {}
FIN
    else
      val="${1:-bug}"
      shift || break
      sha=$(echo "${val}" | sha256sum | awk '{print $1}')
      name="${curr}-${sha}"
      b64secret=$(printf "%s" "${val}" | base64)

      cat << FIN
      - ${curr}:
          keys:
            - name: "${name}"
              secret: "${b64secret}"
FIN
    fi
  done
}

mkrundir() {
  install -dm755 "${RUNDIR}"
}

# Write out a configfile to PREFIX, note PREFIX *MUST* exist
PREFIX=${PREFIX:-/etc/cray/kubernetes/encryption}
writeconfig() {
  if [ ! -d "${PREFIX}" ]; then
    printf "fatal: %s does not exist or is not a directory\n" "${PREFIX}" >&2
    return 1
  fi

  mkrundir
  tmpfile=$(mktemp -p "${RUNDIR}" sha256sum.XXXXXXXX)

  # Write out whatever we got passed into a tempfile so we can get the sha256sum
  # of the contents to move it into PREFIX
  encryptionconfig "$@" > "${tmpfile?}"
  shasum=$(sha256sum "${tmpfile?}" | awk '{print $1}')

  curr="${PREFIX}/current.yaml"

  # The sha256sum of the default.yaml file the ncn image has, used as a bit of a
  # fix point.
  if [ "a4bc1911a877c9c28b5f4493ca314ba2f26f759cc8d9e7ac3ebf2c3d752c25a8" = "${shasum}" ]; then
    reset=true
  else
    reset=false
    mv "${tmpfile?}" "${PREFIX?}/${shasum?}.yaml"
  fi

  # This function is here for mostly unit testing reasons but replaces the
  # encryption configuration line in the kubeadm config file to the file we just
  # created. If kubeadm then restarts/updates OK then we symlink current.yaml to point to that file. Logic in here is rather simple. The encryption pods will read current.yaml and decide if/when to update/replace secrets.

  if ${reset}; then
    # Default source is the default.yaml file
    src="${PREFIX}/default.yaml"
  else
    src="${PREFIX?}/${shasum?}.yaml"
  fi

  if ! updatek8sconfig "${src}" /etc/kubernetes/manifests/kube-apiserver.yaml /srv/cray/resources/common/kubeadm.cfg /etc/cray/kubernetes/kubeadm.yaml; then
    printf "fatal: Update of k8s config to use %s failed\n" "${src}" >&2
    return 1
  fi

  # For callers to know what the new config file is supposed to be.
  printf "%s\n" "${src}"

  return 0
}

# This is largely the only thing that can't easily be unit tested only
# mocked/mimic'd, basically this is responsible for updating the following files:
# /etc/kubernetes/manifests/kube-apiserver.yaml
# /srv/cray/resources/common/kubeadm.cfg
# /etc/cray/kubernetes/kubeadm.yaml
#
# Might pay off to fake this somehow...
updatek8sconfig() {
  config=$1
  shift
  kubeapiyaml=$1
  shift
  kubeadmcfg=$1
  shift
  kubeadmyaml=$1

  # Note kubeadmyaml isn't on every master node
  sed -i -e "s|--encryption-provider-config=.*|--encryption-provider-config=${config}|" "${kubeapiyaml}"
  sed -i -e "s|encryption-provider-config:.*|encryption-provider-config: ${config}|" "${kubeadmcfg}"
  if [ -e "${kubeadmyaml}" ]; then
    sed -i -e "s|encryption-provider-config:.*|encryption-provider-config: ${config}|" "${kubeadmyaml}"
  fi
}

# Note as I'm modifying all the same files that kubeadm upgrade apply does we
# can skip that and modify the input file as well as the runtime files.
#
# Whilst not perhaps ideal it saves on the chances that the kubeadm config
# file has deviated from the running config and I would rather not have turning
# on encryption breaking anything that it didn't setup.
#
# So instead of kubeadm upgrade .. to restart the kubeadm containers, we simply
# kubectl delete the local nodes kubeapi pod. Then validate that we have the
# encryption config file passed into kubeapi's process args list. If yes, yatta,
# we can then symlink current.yaml to that file; if not, we abort because something is
# amiss.
#
# Arg is simply the full encryption filename path that we'll pass to pgrep -lif
# in a real boy system.
restartk8s() {
  file="${1:-invalid}"
  apiserver="kube-apiserver-$(uname -n)"

  if ! sutkubectlwait; then
    printf "fatal: local kubeapiserver process is not ready, refusing to do work\n" >&2
    kubeapiblurb
    return 1
  fi

  if sutkubectldelete "${file}"; then
    # kubectl wait for the pod to come back for 60 seconds or bail
    if ! sutkubectlwait; then
      printf "fatal: kubectl wait on %s timed out\n" "${apiserver}" >&2
      kubeapiblurb
      return 1
    fi
  else
    printf "fatal: kubectl delete on %s timed out\n" "${apiserver}" >&2
    kubeapiblurb
    return 1
  fi
  if ! sutpgrep "${file}"; then
    printf "fatal: kubeapi args do not contain expected arg %s\n" "${file}" >&2
    kubeapiblurb
    return 1
  fi
}

# I've been entirely unable to understand/debug why a 5 minute timeout fails,
# but eventually works for this....
kubeapiblurb() {
  apiserver="kube-apiserver-$(uname -n)"

  cat << EOF >&2
check logs for details why via:
kubectl logs -f --namespace kube-system ${apiserver}
kubectl get pod --namespace kube-system ${apiserver}
kubectl describe pod --namespace kube-system ${apiserver}
you will need to re-run this command again
EOF
}

# Glorified wrapper functions for unit tests.

# Simply wrapping around:
# pgrep -lif process.*something in the arg list
sutpgrep() {
  pgrep -lif "kube-apiserver.*${1:-invalid}" > /dev/null 2>&1
}

# Similarly just wrapping:
# kubectl delete pod --namespace kube-system kube-apiserver-$(uname -n)
# Note as we're expecting to be run on the node in question $(uname -n) should
# be ok to use, not dealing with that being different in this instance.
sutkubectldelete() {
  kubectl delete pod --namespace kube-system "kube-apiserver-$(uname -n)" --timeout="${KUBETIMEOUT}"
}

# Similarly just wrapping:
# kubectl wait pod --namespace kube-system kube-apiserver-$(uname -n) ...
sutkubectlwait() {
  kubectl wait pod --namespace kube-system --for condition=ready "kube-apiserver-$(uname -n)" --timeout="${KUBETIMEOUT}"
}

# Etcd related functions, here to let us peek into the etcd db directly to get
# at if a secret key (namely the cray-k8s-encryption key by default) is
# encrypted or not. We (ab)use that as an indicator of what keys are in use in etcd
# and what the user may be requesting to say yea/nay to the configuration requested.
#
# Mostly here to prevent a user from trying to swap a key from A -> B without
# going through a 2 phase commit of A && B (rewrite) and then just A (removal of
# B requires no rewrite of secret data)
#
# Note etcdctl has no sut prefix to make usage of the commands equal what you
# would type at a shell commandline.

# Wrap up etcdctl calls in a function with all the needed env vars.
etcdprefix="/etc/kubernetes/pki"
export ETCDCTL_ENDPOINTS='https://127.0.0.1:2381'
export ETCDCTL_CACERT="${etcdprefix}/etcd/ca.crt"
export ETCDCTL_CERT="${etcdprefix}/apiserver-etcd-client.crt"
export ETCDCTL_KEY="${etcdprefix}/apiserver-etcd-client.key"
export ETCDCTL_API=3

sutetcdctl() {
  ${ETCDCTL} "$@"
}

# Before running any etcdctl commands run etcdctl version to establish if we can
# even get at data from etcd.
sutetcdok() {
  sutetcdctl version
}

# Just a wrapper around etcdctl get ... that handles unencrypted and encrypted
# contents of a k8s secret in etcd db.
#
# args are namespace then keyname
sutkeyencryption() {
  keyval=$(sutetcdctlkeyval "$@" 2>&1)
  rc=$?

  encryptionval="unknown"

  # etcdctl get ... has a horrible interface
  #
  # If you do a get on a nonexistent key, it returns 0 and no output
  # So special case that so we can know if we are looking for a nonexistent key or not
  #
  # Special case this to string dne (Does Not Exist)
  if [ 0 -eq "${rc}" ] && [ "" = "${keyval}" ]; then
    printf "dne"
    return 1
  fi

  # Non zero return code is special case etcderror and etcdtimeout
  if [ 0 -ne "${rc}" ]; then
    if echo "${keyval}" | grep DeadlineExceeded > /dev/null 2>&1; then
      printf "etcdtimeout"
    else
      printf "etcderror"
    fi
    return 1
  fi

  # Ok as there are any number of secret types, the real logic here is simply:
  # If we can detect the "this is totes encrypted" string, its encrypted we return the name of that encryption provider
  # Otherwise we call it identity cause it probably is
  # as long as etcdctl returned 0 if it was 1 we call it unknown
  if echo "${keyval}" | grep 'k8s:enc' > /dev/null 2>&1; then
    # Overly pedantic nit not applicable here or rather isn't an issue
    #shellcheck disable=SC2086
    encryptionval="$(echo ${keyval} | awk -F: '{print $5}')"
  else
    encryptionval="identity"
  fi

  printf "%s" "${encryptionval}"
  if [ "unknown" = "${encryptionval}" ]; then
    return 1
  fi

  return 0
}

# For unit testing ^^^^ Just wraps
# etcdctl get --print-value-only /registry/secrets/$namespace/$name
#
# args are namespace then keyname
sutetcdctlkeyval() {
  namespace="${1}"
  shift
  name="${1}"

  # Note we have to strip off null bytes as this is raw binary data and if bash
  # is running us prints a useless warning
  sutetcdctl get --print-value-only "/registry/secrets/${namespace}/${name}" | head -n 2 | tr -d '\0'
}

# Just wraps etcdctl get ... /registry/secrets so we get just the keys
sutallkeys() {
  sutetcdctl get --keys-only=true --prefix /registry/secrets | awk '/\/registry/ {print}'
}

# Loop through all secrets and find any/all names in use and sorted/uniqued
sutexistingetcdencryption() {
  existing=""

  rc=0

  baton=0

  if [ -t 1 ]; then
    printf "reading all etcd keys this takes a while please wait\n" >&2
  fi

  for secret in $(sutallkeys); do
    # Print a baton to stderr if we are on a tty
    if [ -t 1 ]; then
      baton=$((baton + 1))
      if [ 1 -eq "${baton}" ]; then
        printf "\b|" >&2
      elif [ 2 -eq "${baton}" ]; then
        printf "\b/" >&2
      elif [ 3 -eq "${baton}" ]; then
        printf "\b-" >&2
      else
        baton=0
      fi
    fi

    ns=$(echo "${secret?}" | awk -F/ '{print $4}')
    name=$(echo "${secret?}" | awk -F/ '{print $5}')

    # Not great but if/since we're running in set -e the return 1 can bite us
    val=$(sutkeyencryption "${ns}" "${name}")
    # This is intentional shellcheck, no other way to avoid re-running this and
    # saving its output and using/abusing $? too.
    #shellcheck disable=SC2181
    if [ "${?}" -eq 0 ]; then
      existing="${val}${existing:+ }${existing-}"
    else
      printf "\ndebug: key %s %s cannot be determined\n" "${ns}" "${name}" >&2
      existing="etcderror${existing:+ }${existing-}"
    fi
  done

  if [ -t 1 ]; then
    printf "\b\b\b" >&2
  fi
  echo "${existing?}" | spacetonewline | sort -u | tr '\n' ' '
}

# Note lhs is the input (quote it if spaces!) as well as rhs Internally this
# function creates files for awk to use to calculate the seet operation, cause
# this is shell and thats the easiest way to leverage existing programs.
complement() {
  dlhs="${1}"
  shift
  drhs="${1}"
  mkrundir
  lhsf=$(mktemp -p "${RUNDIR}" lhs-XXXXXXXX)
  rhsf=$(mktemp -p "${RUNDIR}" rhs-XXXXXXXX)
  echo "${dlhs}" | spacetonewline | sort -u > "${lhsf}"
  echo "${drhs}" | spacetonewline | sort -u > "${rhsf}"
  comm -23 "${lhsf}" "${rhsf}"
}

# Same applies here as complement
difference() {
  elhs="${1}"
  shift
  erhs="${1}"
  mkrundir
  lhsf=$(mktemp -p "${RUNDIR}" lhs-XXXXXXXX)
  rhsf=$(mktemp -p "${RUNDIR}" rhs-XXXXXXXX)
  echo "${elhs}" | spacetonewline | sort -u > "${lhsf}"
  echo "${erhs}" | spacetonewline | sort -u > "${rhsf}"
  comm -3 "${lhsf}" "${rhsf}" | tr -d '\t'
}

# Everything in complement applies here too
subset() {
  subsetlhs="${1}"
  shift
  subsetrhs="${1}"
  mkrundir
  lhsf=$(mktemp -p "${RUNDIR}" lhs-XXXXXXXX)
  rhsf=$(mktemp -p "${RUNDIR}" rhs-XXXXXXXX)
  echo "${subsetlhs}" | spacetonewline | sort -u > "${lhsf}"
  echo "${subsetrhs}" | spacetonewline | sort -u > "${rhsf}"
  comm -23 "${lhsf}" "${rhsf}" | grep -q '^'
}

# This is slightly unique compared to above
#
# For now instead of newline delimited its space delimited to make comparisons
# simpler. If we need a more general set operation we can deal with that later.
union() {
  unionlhs="${1}"
  shift
  unionrhs="${1}"
  mkrundir
  lhsf=$(mktemp -p "${RUNDIR}" lhs-XXXXXXXX)
  rhsf=$(mktemp -p "${RUNDIR}" rhs-XXXXXXXX)
  echo "${unionlhs}" | spacetonewline | sort -u > "${lhsf}"
  echo "${unionrhs}" | spacetonewline | sort -u > "${rhsf}"
  sort -u "${lhsf}" "${rhsf}" | newlinetospace | sed -e 's/ $//g'
}

# Take the inputs the user has given, compare it to what we have found, and yea/nay it.
#
# Just a bunch of set operations to determine if what we found is covered by
# what they have specified.
#
# lhs is what we found, rhs is what the user entered/hopes for.
#
# Current is what the existing encryption key is known to be
# Goal similarly is the upcoming goal of encryption
usergoalvalid() {
  lhs="${1}"
  shift
  rhs="${1}"
  shift
  curr="${1}"

  ok=0
  nok=0

  # Special case when both inputs are equal count it as valid
  if [ "${lhs}" = "${rhs}" ]; then
    ok=$((ok + 1))
  fi

  # Validate case where what we the user is requesting is a subset of what is
  # wanted (adding a new goal)
  if subset "${rhs}" "${lhs}"; then
    ok=$((ok + 1))
  fi

  # mostly add use cases
  if subset "${curr}" "${rhs}"; then
    if subset "${lhs}" "${rhs}"; then
      ok=$((ok + 1))
    fi
  fi

  # Mostly removal of written/committed to etcd ciphers
  if subset "${curr}" "${lhs}"; then
    if subset "${rhs}" "${lhs}"; then
      ok=$((ok + 1))
    fi
  fi

  diff=$(difference "${lhs}" "${rhs}")
  comp=$(complement "${lhs}" "${rhs}")

  # If we have differences thats generally OK due to addition or removal but if
  # the complement and differences don't match we have input ciphers missing
  # existing on disk ciphers.
  if [ "" != "${diff}" ] && [ "" != "${comp}" ]; then
    # Not ok difference != complement
    if [ "${diff}" != "${comp}" ]; then
      nok=$((nok + 1))
    fi
  else
    # If we can union both lhs and rhs and its the same as what we found this
    # is ok this handles the case of removing something and midstream having
    # the new value be used for writes. It may not be correct for every node
    # technically to use the new value before but we're constrained by k8s
    # using the first array element for any/all new writes.
    union=$(union "${lhs}" "${rhs}")
    ulhs=$(union "${union}" "${lhs}")
    urhs=$(union "${union}" "${rhs}")
    if [ "${ulhs}" = "${urhs}" ]; then
      ok=$((ok + 1))
    fi
  fi

  if [ "${ok}" -gt 0 ]; then
    if [ "${nok}" -gt 0 ]; then
      return 1
    fi
    return 0
  else
    return 1
  fi
}

# Just strips off the b64 encoded strings from a string of space delimted "things"
# internal helper function.
tovalid() {
  out=""
  until [ $# -eq 0 ]; do
    x="${1}"
    shift

    provider=$(echo "${x}" | awk -F- '{print $1}')
    if [ "identity" = "${x}" ] || [ "aesgcm" = "${provider}" ] || [ "aescbc" = "${provider}" ]; then
      out="${out-}${out:+ }${x}"
    fi
  done
  echo "${out}"
}

# The goal of encryption aka what encryption key name we want things to be rewritten with
secret_goal() {
  kubectl get secret -n kube-system cray-k8s-encryption -o jsonpath='{range .items[*]}{.metadata.annotations.goal}'
}

# Current encryption configuration, or rather last known configuration based off last rewrite of data in k8s
secret_current() {
  kubectl get secret -n kube-system cray-k8s-encryption -o jsonpath='{range.items[*]}{.metadata.annotations.current}'
}

# Last known time that secrets were rewritten
secret_changed() {
  kubectl get secret -n kube-system cray-k8s-encryption -o jsonpath='{range .items[*]}{.metadata.annotations.changed}'
}

# Glorified wrapper that removes aescbc: or aesgcm: from the above two "functions"
stripetcdprefix() {
  echo "$@" | sed -e "s|aescbc:||g" -e 's|aesgcm:||g'
}

# Used to determine if a running system is synced.
issynced() {
  echo "$@" | spacetonewline | sort -u | wc -l
}

# Since code is read more than written...
newlinetospace() {
  tr '\n' ' '
}

spacetonewline() {
  tr ' ' '\n '
}

commatospace() {
  tr ',' ' '
}
# Prints out only control plane node names based on the node-role label. Only
# controlplane nodes have the encryption file so no sense in annotating anything
# that isn't a control-plane.
kubectl_get_controlplane_nodes() {
  kubectl get nodes --selector=node-role.kubernetes.io/master --no-headers=true -o custom-columns=NAME:.metadata.name
}

# Get the current node annotation values
get_node_annotation() {
  node="${1:-invalid}"

  stripetcdprefix "$(kubectl get node "${node}" -o jsonpath='{range .items[*]}{.metadata.annotations.'"cray-k8s-encryption"'}{"\n"}' | commatospace)"
}

# Logic is simply write out our new encryption config
# iff thats ok restart k8s apiserver pod
# iff that was ok then symlink the new config to current.yaml so daemon can pickup the new setup in k8s.
main() {
  if $restart; then
    kubectl annotate secret --namespace kube-system cray-k8s-encryption current=rewrite --overwrite
    kubectl rollout restart daemonset --namespace kube-system cray-k8s-encryption
    kubectl rollout status --namespace kube-system ds/cray-k8s-encryption --timeout="${KUBETIMEOUT}"
    exit $?
  fi

  curr="$(stripetcdprefix "$(secret_current)")"
  goal="$(stripetcdprefix "$(secret_goal)")"
  changed="$(secret_changed)"

  if $status; then
    printf "k8s encryption status\nchanged: %s\n" "${changed?}"

    for node in $(kubectl_get_controlplane_nodes); do
      # not really applicable here
      #shellcheck disable=SC2086
      printf "%s: %s\n" "${node}" "$(get_node_annotation ${node})"
    done

    synced=false
    etcd="$(sutexistingetcdencryption | newlinetospace)"
    printf "current: %s\ngoal: %s\netcd: %s\n" "${curr?}" "${goal?}" "${etcd?}"

    # not really applicable here
    #shellcheck disable=SC2086
    if [ "$(issynced ${curr} ${goal} ${etcd})" = 1 ]; then
      synced=true
    fi

    if ${synced}; then
      exit 0
    else
      if [ -t 1 ]; then
        printf "interim state detected, ensure all control plane nodes are in sync\n" >&2
      fi
      exit 1
    fi
  fi

  # General validation for --enable/disable, if this doesn't pass we don't allow
  # the input at all to go any further

  usergoal=$(validateinput "$@")
  #shellcheck disable=SC2181
  if [ "${?}" -ne 0 ]; then
    exit 1
  fi

  # Grab the current configuration off of etcd, then we use the usergoal above
  # to call usergoalvalid to see if the request makes sense from a logical
  # perspective.

  # We can't quote this call
  #shellcheck disable=SC2086
  usersgoal=$(tovalid ${usergoal})

  # Bit of an edge case to detect, but see if someone is trying to go from
  # "encrypted" straight to "not encrypted", the set logic below *will* catch it
  # but lets try to spit out a better message in this instance.
  if ${disabled} && [ "identity" = "$*" ] && [ "identity" != "${curr}" ]; then
    printf "fatal: trying to disable encryption before etcd has rewritten secrets is not supported\nensure you run %s --disable (--aescbc|--aesgcm) KEYVALUE ...\non all control plane nodes before you run %s --disable\n" "$0" "$0" >&2
    exit 1
  fi

  etcd="$(sutexistingetcdencryption)"

  if ! usergoalvalid "${etcd}" "${usersgoal}" "${curr}"; then
    printf "fatal: requested goal conflicts with existing etcd encryption\netcd: %s\nrequested: %s\n" "${etcd}" "${usersgoal}" >&2
    printf "Ensure that you include all encryption secrets present in etcd or kubernetes will not be able to read those secrets or restart.\n" >&2
    exit 1
  fi

  mkrundir
  cd "${RUNDIR}" || exit 126

  curr="${PREFIX}/current.yaml"

  src=$(writeconfig "$@")
  # Needed as we are using stdout and don't want to run things twice.
  #shellcheck disable=SC2181
  if [ $? -eq 0 ]; then
    if restartk8s "${src}"; then
      if [ -e "${src}" ]; then
        cd "${PREFIX}" || exit 126
        # not really applicable
        #shellcheck disable=SC2086
        ln -sf "$(basename ${src})" "$(basename ${curr})"
      else
        printf "fatal: cannot symlink %s as it does not exist?\n" "${src}" >&2
        exit 1
      fi
    else
      printf "fatal: could not restart kubeapi to update encryption configuration\n" >&2
      exit 1
    fi
  else
    printf "fatal: could not write config file\n" >&2
    exit 1
  fi
  printf "%s configuration updated ensure all control plane nodes run this same command\n" "$(uname -n)" >&2
}

# Note: this line allows shellspec to source this script for unit testing functions above.
# DO NOT REMOVE IT!
# Ref: https://github.com/shellspec/shellspec#testing-shell-functions
${__SOURCED__:+return}

# If needed at runtime to specify what etcdctl to (ab)use, note after
# __SOURCED__ to allow for runtime detection
ETCDCTL=${ETCDCTL:-$(command -v etcdctl)}

usage() {
  cat << FIN
usage: $0 [-h|--help] [--enable|--disable|--status|--restart] [--aescbc|aesgcm] VALUE ...
FIN
}

# Main() related stuff here/arg parsing etc...
encryptionopts=
enabled=false
disabled=false
restart=false
status=false
ciphers=0
help=true

while true; do
  case "${1:-}" in
    -e | --enable)
      help=false
      enabled=true
      shift
      ;;
    -d | --disable)
      help=false
      disabled=true
      shift
      ;;
    -r | --restart)
      help=false
      restart=true
      shift
      ;;
    -s | --status)
      help=false
      status=true
      shift
      ;;
    --aescbc)
      help=false
      ciphers=$((ciphers + 1))
      encryptionopts="${encryptionopts-}${encryptionopts:+ }aescbc ${2}"
      shift 2
      ;;
    --aesgcm)
      help=false
      ciphers=$((ciphers + 1))
      encryptionopts="${encryptionopts-}${encryptionopts:+ }aesgcm ${2}"
      shift 2
      ;;
    -h | --help)
      break
      ;;
    *)
      break
      ;;
  esac
done

if ${help}; then
  usage
  exit 1
fi

if (${enabled} && ${disabled}) || (${enabled} && ${status}) || (${enabled} && ${restart}) \
  || (${disabled} && ${status}) || (${disabled} && ${restart}) \
  || (${status} && ${restart}); then
  printf "fatal: --enable, --disable, --status, and --restart cannot be used together\n" >&2
  usage
  exit 1
elif ${enabled}; then
  if [ ${ciphers} -lt 1 ]; then
    printf "fatal: --enable requires at least one cipher to be provided\n" >&2
    usage
    exit 1
  fi
  encryptionopts="${encryptionopts-}${encryptionopts:+ }identity"
elif ${disabled}; then
  encryptionopts="identity${encryptionopts:+ }${encryptionopts-}"
fi

# Not really applicable for this, if we quote here we send every arg as a single
# arg, we need word splitting. Shellcheck is being over pedantic.
#shellcheck disable=SC2086
main ${encryptionopts}
