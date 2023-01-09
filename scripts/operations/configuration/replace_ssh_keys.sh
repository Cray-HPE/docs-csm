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
   echo "Replaces the SSH keys in Kubernetes"
   echo "At least one option must be specified"
   echo "NOTE: This does not update deployed keys"
   echo
   echo "Usage: replace_ssh_keys.sh [ --public-key-file file ]"
   echo "                           [ --private-key-file file ]"
   echo
   echo "Options:"
   echo "public-key-file      File path for a public key."
   echo "private-key-file     File path for a private key."
   echo
}

if [[ $# -eq 0 ]]; then
  usage
fi

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    --public-key-file)
      PUBLIC_KEY_FILE="$2"
      shift # past argument
      shift # past value
      ;;
    --private-key-file)
      PRIVATE_KEY_FILE="$2"
      shift # past argument
      shift # past value
      ;;
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

if [[ -n "${PUBLIC_KEY_FILE}" ]]; then
  PUBLIC_KEY=$(cat $PUBLIC_KEY_FILE)
  if [[ -z "${PUBLIC_KEY}" ]]; then
    echo "Public key not found in specified file"
    exit 1
  fi
fi

if [[ -n "${PRIVATE_KEY_FILE}" ]]; then
  PRIVATE_KEY=$(cat $PRIVATE_KEY_FILE)
  if [[ -z "${PRIVATE_KEY}" ]]; then
    echo "Private key not found in specified file"
    exit 1
  fi
fi

if [[ -n "${PUBLIC_KEY}" ]]; then
  echo "Updating public key..."
  kubectl delete configmap -n services csm-public-key
  cat ${PUBLIC_KEY_FILE} | \
    base64 > ./value && kubectl create configmap --from-file \
    value csm-public-key --namespace services && rm ./value
fi

if [[ -n "${PRIVATE_KEY}" ]]; then
  echo "Updating private key..."
  kubectl get secret -n services csm-private-key -o json | \
    jq --arg value "$(cat ${PRIVATE_KEY_FILE} | base64)" \
    '.data["value"]=$value' | kubectl apply -f -
fi
