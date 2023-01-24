#!/bin/bash
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

usage()
{
   # Display Help
   echo "Waits for components to complete CFS configuration"
   echo
   echo "Usage: deploy_ssh_keys.sh [ --xnames xname1,xname2... ]"
   echo "                            [ --role role ] [ --subrole subrole ]"
   echo
   echo "Options:"
   echo "xnames      A comma-separated list xnames to watch."
   echo "role        An hsm node role to watch."
   echo "subrole     An hsm node subrole to watch."
   echo
}

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    --xnames)
      XNAMES="$2"
      shift # past argument
      shift # past value
      ;;
    --role)
      ROLE="$2"
      shift # past argument
      shift # past value
      ;;
    --subrole)
      SUBROLE="$2"
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

## RUNNING CFS ##
XNAME_PARAMETER=""
if [[ -n $XNAMES ]]; then
  XNAME_PARAMETER="--ids ${XNAMES}"
elif [[ -n $ROLE ]] || [[ -n $SUBROLE ]]; then
  ROLE_PARAMETER=""
  SUBROLE_PARAMETER=""
  if [[ -n $ROLE ]]; then
    ROLE_PARAMETER="--role $ROLE"
  fi
  if [[ -n $SUBROLE ]]; then
    SUBROLE_PARAMETER="--subrole $SUBROLE"
  fi
  XNAMES=$(cray hsm state components list --type Node $ROLE_PARAMETER $SUBROLE_PARAMETER --format json \
    | jq -r '.Components | map(.ID) | join(",")')
  XNAME_PARAMETER="--ids ${XNAMES}"
fi

while true; do
  RESULT=$(cray cfs components list --status pending $XNAME_PARAMETER --format json | jq length)
  if [[ "$RESULT" -eq 0 ]]; then
    break
  fi
  echo "Waiting for configuration to complete.  ${RESULT} components remaining."
  sleep 30
done

CONFIGURED=$(cray cfs components list --status configured ${XNAME_PARAMETER} --format json  | jq length)
FAILED=$(cray cfs components list --status failed ${XNAME_PARAMETER} --format json | jq length)
echo "Configuration complete. $CONFIGURED component(s) completed successfully.  $FAILED component(s) failed."
if [ "$FAILED" -ne "0" ]; then
   echo "The following components failed: $(cray cfs components list --status failed ${XNAME_PARAMETER} --format json  | jq -r '. | map(.id) | join(",")')"
   exit 1
fi
