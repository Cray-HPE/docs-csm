#!/bin/bash
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
usage()
{
   # Display Help
   echo "Removes the SSH keys in Kubernetes to restore their value from vault"
   echo "NOTE: This does not update deployed keys"
   echo
   echo "Usage: restore_ssh_keys.sh"
   echo
}

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -h|--help) # help option
      usage
      exit 0
      ;;
    *) # unknown option
      usage
      exit 1
      ;;
  esac
done


kubectl delete configmap -n services csm-public-key
kubectl delete secret -n services csm-private-key
echo "Keys removed.  Waiting for defaults to be populated."
echo "csm-ssh-keys will be restarted to force the keys to be restored sooner."
kubectl -n services rollout restart deployment csm-ssh-keys

until kubectl get configmap -n services csm-public-key >/dev/null 2>&1 && \
      kubectl get secret -n services csm-private-key >/dev/null 2>&1; do
  echo "Waiting for defaults to be populated..."
  sleep 10
done

echo "Defaults have been restored"
