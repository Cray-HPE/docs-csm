#!/bin/bash

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
  XNAMES=$(cray hsm state components list --type node $ROLE_PARAMETER $SUBROLE_PARAMETER --format json \
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

