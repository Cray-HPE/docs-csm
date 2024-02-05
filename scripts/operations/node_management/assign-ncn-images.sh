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
set -euo pipefail

function usage {

  cat << EOF
usage:

Updates boot parameters for a comma delimited list of hosts.

NOTE: This script requires that the rootfs, initrd, and kernel for the given host all reside at the same S3 path.

./$(basename "$0") [-k kernel_name] [-i initrd_name] [-r rootfs_name]
                   [-p S3_path] [-b bucket] [-msw]
                   xname1[,xnameN,...]

Positional:

<xnames>  A comma delimited list of XNAME(s)

Options:

-i [string]        Name of initrd file (default: initrd)
-k [string]        Name of kernel file (default: kernel)
-r [string]        Name of the rootfs (default: rootfs)
-p [string]        S3 Path, not including the bucket or filename (e.g. "foo" if the file exists at my-images/foo/kernel)
-b [string]        Bucket name (default: boot-images)
-m                 Auto-resolve all NCN master XNAME(s).
-s                 Auto-resolve all NCN storage XNAME(s).
-w                 Auto-resolve all NCN worker XNAME(s).

Examples:

# All masters and workers.
./$(basename "$0") -p 69bc17cb-da1d-412c-a43d-ab8cacf5ab2b -mw

# Two specific XNAMES.
./$(basename "$0") -p 69bc17cb-da1d-412c-a43d-ab8cacf5ab2b x3000c0s4b0n0,x3000c0s30b0n0

# All NCN masters, including two specific XNAMES.
./$(basename "$0") -p 69bc17cb-da1d-412c-a43d-ab8cacf5ab2b -m x3000c0s4b0n0,x3000c0s30b0n0

EOF
}

bucket="boot-images"
s3path=""
kernel="kernel"
initrd="initrd"
rootfs="rootfs"
masters=0
workers=0
storage=0
while getopts ":k:i:b:p:r:msw" o; do
  case "${o}" in
    p)
      s3path="${OPTARG}"
      ;;
    b)
      bucket="${OPTARG}"
      ;;
    i)
      initrd="${OPTARG}"
      ;;
    k)
      kernel="${OPTARG}"
      ;;
    r)
      rootfs="${OPTARG}"
      ;;
    m)
      masters=1
      ;;
    s)
      storage=1
      ;;
    w)
      workers=1
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done
if [ $OPTIND -eq 1 ]; then usage; fi
shift $((OPTIND - 1))

xnames=("$@")
subroles=()
if [ "$masters" -ne 0 ]; then
  subroles+=('Master')
fi
if [ "$workers" -ne 0 ]; then
  subroles+=('Worker')
fi
if [ "$storage" -ne 0 ]; then
  subroles+=('Storage')
fi
for subrole in "${subroles[@]}"; do
  if IFS=$'\n' read -rd '' -a found; then
    :
  fi <<< "$(cray hsm state components list --role Management --subrole "${subrole}" --type Node --format json | jq -r '.Components | map(.ID) | join("\n")')"
  xnames+=("${found[@]}")
done

if [ "${#xnames[@]}" -eq 0 ]; then
  echo >&2 'Provide an array of xnames, or use the auto-switches -m, -w, or -s.'
  exit 1
fi

echo "Updating [${#xnames[@]}] hosts with"
artifact_base="${bucket//\//}/${s3path//\//}"
rootfs_url="s3://${artifact_base}/${rootfs}"
initrd_url="s3://$artifact_base/${initrd}"
kernel_url="s3://$artifact_base/${kernel}"
printf "rootfs URL: % -30s\n" "$rootfs_url"
printf "initrd URL: % -30s\n" "$initrd_url"
printf "kernel URL: % -30s\n" "$kernel_url"

for xname in "${xnames[@]}"; do
  current_rootfs_url=""
  params=""
  error=0
  printf "% -15s: " "$xname"
  current_rootfs_url="$(cray bss bootparameters list --hosts "${xname}" --format json | jq '.[] |."params"' \
    | awk -F 'metal.server=' '{print $2}' \
    | awk -F ' ' '{print $1}')"
  if [ -z "$current_rootfs_url" ]; then
    echo "ERROR - Missing metal.server for $xname! Skipping ... "
    error=1
    continue
  fi
  params=$(cray bss bootparameters list --hosts "${xname}" --format json | jq '.[] |."params"' \
    | sed "/metal.server/ s|${current_rootfs_url}|${rootfs_url}|" \
    | tr -d \")
  if [ -z "$params" ]; then
    echo "ERROR - Failed to create new boot parameters for $xname! Skipping ... "
    error=1
    continue
  fi
  if ! cray bss bootparameters update --hosts "${xname}" \
    --kernel "$kernel_url" \
    --initrd "$initrd_url" \
    --params "${params}" > /dev/null 2>&1; then
    echo "ERROR - Failed to update boot parameters for $xname! Skipping ..."
    error=1
    continue
  fi
  echo 'OK'
done
if [ "$error" -ne 0 ]; then
  echo >&2 "Errors were detected, please inspect the scripts output."
else
  echo "Successfully updated boot parameters for [${#xnames[@]}] xname(s):"
  printf "\t%s\n" "${xnames[@]}"
fi
