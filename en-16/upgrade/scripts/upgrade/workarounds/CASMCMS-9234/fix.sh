#!/bin/bash
#
# MIT License
#
# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
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

# In CSM 1.6.0, there is a bug in the BOS migration code which runs automatically after the
# service is upgraded. The result is that some session templates may be rendered unusable.
# Running this tool after the service upgrade corrects the problem. It does not hurt to
# run it unnecessarily (it will do nothing if the problem is not detected).

# Usage: fix.sh <target directory for BOS data export, if any templates are renamed>

set -euo pipefail

locOfScript=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
pyScriptBase=fix_template_db_keys.py
pyScriptPath="${locOfScript}/${pyScriptBase}"
pyScriptPodPath="/tmp/${pyScriptBase}"
bosExportScriptPath="/usr/share/doc/csm/scripts/operations/configuration/export_bos_data.sh"

function err_exit {
  echo "ERROR: $*" >&2
  exit 1
}

function run_cmd {
  "$@" || err_exit "Command failed with rc $?: $*"
}

[[ $# -eq 1 ]] || err_exit "$0: Script requires exactly 1 argument but received $#: $*"
[[ -n $1 ]] || err_exit "$0: Argument to script may not be blank"
[[ -e $1 ]] || err_exit "$0: Directory does not exist: '$1'"
[[ -d $1 ]] || err_exit "$0: Exists but is not a directory: '$1'"
OUTDIR="$1"

pod=$(run_cmd kubectl get pods -n services -l 'app.kubernetes.io/name=cray-bos' --no-headers | grep Running | head -1 | awk '{ print $1 }') \
  || err_exit "Unable to find Running BOS server pod"

echo "Copying repair script to BOS server pod ${pod}"
run_cmd kubectl -n services cp "${pyScriptPath}" "${pod}:${pyScriptPodPath}"
kubectl -n services exec "${pod}" -- python3 "${pyScriptPodPath}" && exit 0 || rc=$?
[[ $rc -eq 57 ]] || err_exit "Unexpected failure trying to apply BOS session template fix for CASMCMS-9234"
echo "Exit code 57 means that at least one template needed its database key fixed. Taking a fresh export of BOS data to ${OUTDIR}"
run_cmd "${bosExportScriptPath}" "${OUTDIR}"
echo "SUCCESS"
