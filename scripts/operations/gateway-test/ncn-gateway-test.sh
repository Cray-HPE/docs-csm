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

function error() {
  echo "ERROR: $1"
  exit 1
}

if [ $# -ne 0 ]; then
  echo "usage: $0"
  exit 1
fi

# Make sure the craysys command is available

craysys type get > /dev/null 2>&1
if [ $? -ne 0 ]; then
  error "craysys command is not available"
fi

# Get the Base Directory
BASEDIR=$(dirname $0)

# Get the SYSTEM_DOMAIN from cloud-init 
SYSTEM_NAME=$(craysys metadata get system-name)
SITE_DOMAIN=$(craysys metadata get site-domain)

if [ -z ${SYSTEM_NAME} ]; then
  error "SYSTEM_NAME not found"
fi

if [ -z ${SITE_DOMAIN} ]; then
  error "SITE_DOMAIN not found"
fi

SYSTEM_DOMAIN=${SYSTEM_NAME}.${SITE_DOMAIN}
echo "System domain is ${SYSTEM_DOMAIN}"

printf "\nRunning tests on the NCN\n"
${BASEDIR}/gateway-test.py ${SYSTEM_DOMAIN} ncn
