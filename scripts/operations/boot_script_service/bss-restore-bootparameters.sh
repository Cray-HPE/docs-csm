#! /bin/bash
#  MIT License
#
#  (C) Copyright [2023] Hewlett Packard Enterprise Development LP
#
#  Permission is hereby granted, free of charge, to any person obtaining a
#  copy of this software and associated documentation files (the "Software"),
#  to deal in the Software without restriction, including without limitation
#  the rights to use, copy, modify, merge, publish, distribute, sublicense,
#  and/or sell copies of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included
#  in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
#  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
#  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#  OTHER DEALINGS IN THE SOFTWARE.

PROG=$(basename $0)
BSS_URL=https://api-gw-service-nmn.local/apis/bss/boot/v1/bootparameters
BACKUP_FILE=$1
shift

if ! jq -c '.[] | select(."cloud-init"."meta-data" != null) | .hosts' <$BACKUP_FILE | grep -q Global; then
  echo "$PROG: No Global data found in backup file" 1>&2
  exit 1
fi

# Get a token if we don't already have one.
if [ -z "$TOKEN" ]; then
  TOKEN=$(curl -k -s -S -d grant_type=client_credentials -d client_id=admin-client \
  -d client_secret="$(kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d)" \
  https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | jq -r '.access_token')
fi

bss-restore()
{
  local host
  host=$1
  local DATA
  DATA=$(jq -c '.[] | select(.hosts[0] == "'$host'")' <$BACKUP_FILE)
  local ncn
  ncn=$(jq -r '."cloud-init"."user-data".hostname' <<<"$DATA" | grep -v null)
  if [ "$DATA" ]; then
    echo "Restoring $ncn${ncn:+/}$host..."
    RESULT=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" -X POST -d "$DATA" $BSS_URL)
    STATUS=$(jq -r .status <<<"$RESULT")
    if [ "$STATUS" ] && (( STATUS >= 400 )); then
      # If the POST fails, then try a PUT instead
      curl -s -k -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" -X PUT -d "$DATA" $BSS_URL
    fi
  else
    echo "$PROG: Cannot find backup data for $host from $BACKUP_FILE" 1>&2
  fi
}

test $# = 0 && set -- $(jq -r '.[] | select(."cloud-init"."meta-data" != null) | .hosts[0]' <$BACKUP_FILE)

for i in "$@"; do
  bss-restore $i
done
