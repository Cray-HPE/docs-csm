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

printf "Looking for known istio issues"
istioissues=""
remediation=""

rc=0

for ns in $(kubectl get ns -A --no-headers=true 2> /dev/null | awk '/Active/ {print $1}'); do
  for pod in $(kubectl get pods -n "${ns}" --no-headers=true 2> /dev/null | awk '/Running/ {print $1}'); do
    for cont in $(kubectl get pods -n "${ns}" "${pod}" -o jsonpath='{.spec.containers[*].name}' 2> /dev/null | grep istio); do
      if kubectl logs -n "${ns}" "${pod}" -c "${cont}" 2> /dev/null | grep '[[:space:]]503[[:space:]]' | grep SDS > /dev/null 2>&1; then
        istioissues="${istioissues}\nistio http 503 issues found in namespace: ${ns} pod: ${pod} container: ${cont}"
        remediation="${remediation}\nkubectl delete pod --namespace ${ns} ${pod}"
      fi
    done
  done
done

if [ "${istioissues}" = "" ]; then
  printf " done, and none found\n"
else
  # This usage is fine in this instance with the newlines in the variable as
  # they're intentional.
  printf " done, and found known issues:"
  #shellcheck disable=SC2059
  printf "${istioissues}\n"

  if [ "" != "${remediation}" ]; then
    printf "To remediate run the following commands:\n"
    #shellcheck disable=SC2059
    printf "${remediation}\n"
  fi
  rc=$((rc + 1))
fi

exit ${rc}
