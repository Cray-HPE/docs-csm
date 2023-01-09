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

tmpfiles=
cleanup() {
  if [ "" != "${tmpfiles}" ]; then
    rm -fr "${tmpfiles}"
  fi
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
  identok=0
  encryptionsetup=
  ok=0

  if [ $# -eq 0 ]; then
    printf "fatal: bug? no args passed to encryptionconfig()\n" >&2
    return 1
  fi

  # Non odd number of args is definitely wrong
  if [ $(($# % 2)) -ne 1 ]; then
    printf "fatal: bug? even number of args for encryptionconfig()\n" >&2
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
        encryptionsetup=" ${encryptionsetup} ${input} ${key}"
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
    printf "fatal: bug? no identity provider provided for encryptionconfig()\n" >&2
    return 1
  elif [ ${identok} -ne 1 ]; then
    printf "fatal: bug? more than one identity arg provided to identityconfig()\n" >&2
    return 1
  fi

  (
    cat << FIN
---
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
FIN
    curr=""
    for x in ${encryptionsetup}; do
      if [ "identity" = "${x}" ]; then
        cat << FIN
      - identity: {}
FIN
      elif [ "aescbc" = "${x}" ] || [ "aesgcm" = "${x}" ]; then
        curr="${x}"
      else
        sha=$(echo "${x}" | sha256sum | awk '{print $1}')
        name="${curr}-${sha}"
        # Note: printf to ensure we're not passing in newlines no matter what
        # shell we're run against.
        b64secret=$(printf "%s" "${x}" | base64)
        cat << FIN
      - ${curr}:
          keys:
            - name: "${name}"
              secret: "${b64secret}"
FIN
      fi
    done
  )
}

# Write out a configfile to PREFIX, note PREFIX *MUST* exist
PREFIX=${PREFIX:-/etc/cray/kubernetes/encryption}
writeconfig() {
  if [ ! -d "${PREFIX}" ]; then
    printf "fatal: %s does not exist or is not a directory\n" "${PREFIX}" >&2
    return 1
  fi

  tmpfile=$(mktemp sha256sum.XXXXXXXX)

  tmpfiles="${tmpfiles} ${tmpfile}"

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
  if sutkubectldelete "${file}"; then
    apiserver="kube-apiserver-$(uname -n)"
    # kubectl wait for the pod to come back for 60 seconds or bail
    if ! sutkubectlwait; then
      printf "fatal: kubectl wait on %s timed out\n" "${apiserver}" >&2
      return $?
    fi
  else
    printf "fatal: kubectl delete on %s timed out\n" "${apiserver}" >&2
    return $?
  fi
  if ! sutpgrep "${file}"; then
    printf "fatal: kubeapi args do not contain expected arg %s\n" "%{file}" >&2
    return $?
  fi
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
#
# Additionally, just have kubectl wait for one minute to delete the pod if not give up and let caller decide on actions.
sutkubectldelete() {
  kubectl delete pod --namespace kube-system "kube-apiserver-$(uname -n)" --timeout=60s > /dev/null 2>&1
}

# Similarly just wrapping:
# kubectl delete pod --namespace kube-system kube-apiserver-$(uname -n)
# Note as we're expecting to be run on the node in question $(uname -n) should
# be ok to use, not dealing with that being different in this instance.
#
# Additionally, just have kubectl wait for one minute to delete the pod if not give up and let caller decide on actions.
sutkubectlwait() {
  kubectl wait pod --namespace kube-system --for condition=ready "kube-apiserver-$(uname -n)" --timeout=60s > /dev/null 2>&1
}

# Logic is simply write out our new encryption config
# iff thats ok restart k8s apiserver pod
# iff that was ok then symlink the new config to current.yaml so daemon can pickup the new setup in k8s.
main() {
  curr="${PREFIX}/current.yaml"
  src=$(writeconfig "$@")
  if [ $? ]; then
    if restartk8s "${src}"; then
      if [ -e "${src}" ]; then
        ln -sf "${src}" "${curr}"
      else
        printf "fatal: cannot symlink %s as it does not exist?\n" "${src}" >&2
        exit 1
      fi
    else
      printf "fatal: could not restart k8s to update encryption configuration\n" >&2
      exit 1
    fi
  else
    printf "fatal: could not write config file\n" >&2
    exit 1
  fi
  printf "encryption configuration updated\n" >&2
}

# Note: this line allows shellspec to source this script for unit testing functions above.
# DO NOT REMOVE IT!
# Ref: https://github.com/shellspec/shellspec#testing-shell-functions
${__SOURCED__:+return}

usage() {
  cat << FIN
usage: $0 [-h|--help] [--enable|--disable] --aescbc VALUE --aesgcm VALUE ...
FIN
}

# Main() related stuff here/arg parsing etc...
encryptionopts=
enabled=false
disabled=false
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

if ${enabled} && ${disabled}; then
  printf "fatal: --enable and --disable cannot be used together\n" 2>&1
  usage
  exit 1
elif ${enabled}; then
  if [ ${ciphers} -lt 1 ]; then
    printf "fatal: --enable requires at least one cipher to be provided\n" 2>&1
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
