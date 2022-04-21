#!/bin/bash
#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
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


while [[ $# -gt 0 ]]; do
  key="$1"

   case $key in
       --imagename)
         GATEWAY_IMAGE_NAME="$2"
         shift # past argument
         shift # past value
         ;;
       --publickey)
         PUBKEY="$2"
         shift # past argument
         shift # past value
         ;;
       *)    # unknown option
         echo "[ERROR] - unknown options"
         echo "usage: $0 [--imagename <image-name>] [--publickey <path-to-key>]"
         exit 1
         ;;
  esac
done

# Make sure the cray, craysys, kubectl, and jq commands are available

cray --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "cray command is not available"
  exit 1
fi

craysys type get > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "craysys command is not available"
  exit 1
fi

kubectl version > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "kubectl command is not available"
  exit 1
fi

which jq > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "jq command is not available"
  exit 1
fi


# Find gateway image if one was not specified
if [[ -z ${GATEWAY_IMAGE_NAME} ]]; then
  GATEWAY_IMAGE_NAME=$(cray uas images list --format json | jq '.image_list' | jq .[] | grep gateway |  sed -e 's/"//g' | head -1)
  if [[ -z ${GATEWAY_IMAGE_NAME} ]]; then
    echo "Could not find a cray-gateway-test image" >2
    exit 1 
  fi
else
  cray uas images list --format json | jq '.image_list' | jq .[] | grep -q -v ${GATEWAY_IMAGE_NAME}
  if [ $? -eq 0 ]; then
    echo "${GATEWAY_IMAGE_NAME} not found"
    exit 1
  fi
fi

# If public key file was not specified, use ~/.ssh/id_rsa.pub as default
if [[ -z ${PUBKEY} ]]; then
  PUBKEY=~/.ssh/id_rsa.pub
else
  if [ ! -r $PUBKEY ]; then
    echo "${PUBKEY} not found"
    exit 1
  fi
fi

# Create the UAI pod
echo "Creating Gateway Test UAI with image ${GATEWAY_IMAGE_NAME}"
UAI_NAME=$(cray uas create --publickey ~/.ssh/id_rsa.pub --imagename ${GATEWAY_IMAGE_NAME} | grep uai_name | awk '{print $3}' | sed -e 's/"//g')

if [[ -z ${UAI_NAME} ]]; then
  echo "Failure creating UAI"
  exit 1
fi

# Wait for it pod to become ready
echo "Waiting for ${UAI_NAME} to be ready"
UAI_READY=0
for i in `seq 1 10`;do 
  UAI_STATUS=$(cray uas list --format json | jq --arg n "${UAI_NAME}" '.[] | select(.uai_name == $n) | .uai_status' | sed -e 's/"//g')
  echo "status = $UAI_STATUS"
  if [ "$UAI_STATUS" == "Running: Ready" ]; then
    UAI_READY=1
    break
  fi
  sleep 5
done 

if [ ${UAI_READY} -eq 0 ]; then
  echo "UAI ${UAI_NAME} is not ready"
  exit 1
fi

# Find the UAI pod name
UAI_POD=$(kubectl -n user get pods | grep ${UAI_NAME} | awk '{print $1}')
if [[ -z ${UAI_POD} ]]; then
  echo "Could not find pod for UAI ${UAI_NAME}"
  exit 1
fi

# Get a token to talk to SLS
export TOKEN=$(curl -s -k -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=`kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d` https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')

# Get the SYSTEM_DOMAIN from SLS
SYSTEM_NAME=$(craysys metadata get system-name)
SITE_DOMAIN=$(craysys metadata get site-domain)
SYSTEM_DOMAIN=${SYSTEM_NAME}.${SITE_DOMAIN}
echo "System domain is ${SYSTEM_DOMAIN}"

# Get the USER_NETWORK from SLS
USER_NETWORK=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" https://api-gw-service-nmn.local/apis/sls/v1/dumpstate | jq -r '.Networks.BICAN.ExtraProperties.SystemDefaultRoute' | tr '[:upper:]' '[:lower:]')
echo "User Network on ${SYSTEM_NAME} is ${USER_NETWORK}"

# Get the ADMIN_CLIENT_SECRET
ADMIN_CLIENT_SECRET=$(kubectl get secrets admin-client-auth -ojsonpath='{.data.client-secret}' | base64 -d)
if [[ -z ${ADMIN_CLIENT_SECRET} ]]; then
    echo "Failed to retrieve admin client secret" >2
    exit 1
fi
echo "Got admin client secret"

# Set the variables in the UAI 
kubectl -n user exec ${UAI_POD} -- sh -c "echo 'export ADMIN_CLIENT_SECRET=$ADMIN_CLIENT_SECRET' > /test/vars.sh"
kubectl -n user exec ${UAI_POD} -- sh -c "echo 'export SYSTEM_DOMAIN=$SYSTEM_DOMAIN' >> /test/vars.sh"
kubectl -n user exec ${UAI_POD} -- sh -c "echo 'export USER_NETWORK=$USER_NETWORK' >> /test/vars.sh"

# Run the gateway tests in the UAI
echo "Running gateway tests on the UAI...(this may take 1-2 minutes)"
kubectl -n user exec ${UAI_POD} -- sh -c /test/run-test.sh

# Remove the UAI pod
printf "\nDeleting UAI ${UAI_NAME}\n"
cray uas delete --uai-list ${UAI_NAME}

