#!/bin/bash

if [ $# -ne 0 ]; then
  echo "usage: $0"
  exit 1
fi

# Make sure the craysys command is available

craysys type get > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR: craysys command is not available"
  exit 1
fi

# Get the Base Directory
BASEDIR=$(dirname $0)

# Get the SYSTEM_DOMAIN from cloud-init 
SYSTEM_NAME=$(craysys metadata get system-name)
SITE_DOMAIN=$(craysys metadata get site-domain)
SYSTEM_DOMAIN=${SYSTEM_NAME}.${SITE_DOMAIN}
echo "System domain is ${SYSTEM_DOMAIN}"

printf "\nRunning tests on the NCN\n"
${BASEDIR}/gateway-test.py ${SYSTEM_DOMAIN} ncn

