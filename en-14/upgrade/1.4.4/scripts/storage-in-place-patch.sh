#!/usr/bin/env bash
#
#  MIT License
#
#  (C) Copyright 2024 Hewlett Packard Enterprise Development LP
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
#
LOG_DIR=/var/log/csm/1.4.4/storage-in-place-patch
CURRENT_LOG_DIR="${LOG_DIR}/$(date '+%Y-%m-%d_%H:%M:%S')"
mkdir -p "${CURRENT_LOG_DIR}"
exec 19> "${CURRENT_LOG_DIR}/patch.xtrace"
export BASH_XTRACEFD="19"
trap 'echo "See ${CURRENT_LOG_DIR}/patch.xtrace for debug output."' ERR INT
set -eu
set -o errexit
set -o pipefail
set -o xtrace

function usage {
  cat << 'EOF'
usage:

Run without arguments to run the full script.

-p      Only run the PDSH commands to patch the live node
-u      Only run the upload and BSS steps.
EOF
}

run_pdsh=1
upload_artifacts=1
while getopts ":pu" o; do
  case "${o}" in
    p)
      upload_artifacts=0
      ;;
    u)
      run_pdsh=0
      ;;
    *)
      usage
      exit 0
      ;;
  esac
done
shift $((OPTIND - 1))

regex='ncn-s\d{3}'
if [ -f /etc/pit-release ]; then
  echo >&2 'Can not run this from the PIT node.'
  exit 1
else
  readarray -t EXPECTED_NCNS < <(grep -oP "$regex" /etc/hosts | sort -u)
  if [ ${#EXPECTED_NCNS[@]} = 0 ]; then
    echo >&2 "No NCNs found in /etc/hosts that matched regex [$regex]! This NCN is not initialized, /etc/hosts should have content."
    exit 1
  fi
fi

export NCNS=()
for ncn in "${EXPECTED_NCNS[@]}"; do
  if ping -c 1 "$ncn" > /dev/null 2>&1; then
    NCNS+=("$ncn")
  else
    echo >&2 "Failed to ping [$ncn]; skipping patch for [$ncn]"
  fi
done

function update-bss() {
  local kernel
  local initrd
  local ncn_xnames
  kernel="${1}"
  shift
  initrd="${1}"
  shift
  ncn_xnames=("$@")
  mkdir -p "${CURRENT_LOG_DIR}"
  echo "Patching BSS bootparameters for [${#ncn_xnames[@]}] NCNs."

  for ncn_xname in "${ncn_xnames[@]}"; do
    printf '%-16s Current kernel and initrd settings:\n' "$ncn_xname"
    cray bss bootparameters list --hosts "${ncn_xname}" --format json | jq '.[] | .initrd, .kernel'
    echo "----------------"
  done

  for ncn_xname in "${ncn_xnames[@]}"; do
    printf "%-16s - Backing up BSS bootparameters to %s/%s.bss.backup.json ... " "${ncn_xname}" "${CURRENT_LOG_DIR}" "${ncn_xname}"
    cray bss bootparameters list --hosts "${ncn_xname}" --format json | jq '.[]' > "${CURRENT_LOG_DIR}/${ncn_xname}.bss.backup.json"
    echo 'Done'
    printf '%-16s - Patching BSS bootparameters ... ' "${ncn_xname}"
    cray bss bootparameters update --hosts "${ncn_xname}" --kernel "s3://${bucket}/${kernel}" > /dev/null 2>&1
    cray bss bootparameters update --hosts "${ncn_xname}" --initrd "s3://${bucket}/${initrd}" > /dev/null 2>&1
    echo 'Done'
  done

  for ncn_xname in "${ncn_xnames[@]}"; do
    printf '%-16s New kernel and initrd settings:\n' "$ncn_xname"
    cray bss bootparameters list --hosts "${ncn_xname}" --format json | jq '.[] | .initrd, .kernel'
    echo "----------------"
  done
}

printf "Running patch for [%2s] storage nodes ... \n" "${#NCNS[@]}"

if [ "$run_pdsh" -ne 0 ]; then
  pdsh -S -b -w "$(printf '%s,' "${NCNS[@]}")" '

# Unload qedr from the running system.
lsmod | grep -qE '\''^qedr'\'' && rmmod qedr

# Blacklist qedr from rootfs.
grep -qxF '\''install qedr /bin/true'\'' /etc/modprobe.d/disabled-modules.conf || echo '\''install qedr /bin/true'\'' >> /etc/modprobe.d/disabled-modules.conf

# Blacklist qedr from dracut.
omit_drivers=()
if [ -f /etc/dracut.conf.d/99-csm-ansible.conf ]; then
  . /etc/dracut.conf.d/99-csm-ansible.conf
  if [[ "${omit_drivers[*]}" =~ qedr ]]; then
    :
  else
    sed -i -E '\''s/^omit_drivers\+=" ?/omit_drivers+=" qedr /'\'' /etc/dracut.conf.d/99-csm-ansible.conf
  fi
else
  cat << EOF > /etc/dracut.conf.d/99-csm-ansible.conf
omit_drivers+=" qedr " # Needs to start and end with a space to mitigate warnings.
EOF
fi
'
else
  echo "in-place patch skip requested"
fi

if [ "$upload_artifacts" -ne 0 ]; then
  pdsh -S -b -w "$(printf '%s,' "${NCNS[@]}")" '
# Create new initrd.
/srv/cray/scripts/common/create-ims-initrd.sh >/squashfs/build.log 2>/dev/build.error.log

# Mount the disk bootloader.
if ! mount -L BOOTRAID 2>/dev/null; then
  echo "BOOTRAID already mounted"
fi

# Update the local disk bootloader.
BOOTRAID="$(lsblk -o MOUNTPOINT -nr /dev/disk/by-label/BOOTRAID)"
initrd_name="$(awk -F"/" "/initrdefi/{print \$NF}" "$BOOTRAID/boot/grub2/grub.cfg")"
cp -pv /squashfs/initrd.img.xz "$BOOTRAID/boot/$initrd_name"
cp -pv /squashfs/*.kernel "$BOOTRAID/boot/kernel"
' | dshbak -c
  upload_error=0
  TEMP="$(mktemp -d)"
  target_ncn=''
  for ncn in "${NCNS[@]}"; do
    if [[ $ncn =~ ^ncn-s ]]; then
      target_ncn="$ncn"
      break
    fi
  done
  if [ "$target_ncn" = '' ]; then
    echo >&2 'No storage NCN available.'
    exit 1
  fi
  rsync -rltDv "${target_ncn}:/squashfs/" "${TEMP}/"

  bucket=boot-images
  fixed_kernel_object_ceph=ceph/1.4.4/kernel
  fixed_initrd_object_ceph=ceph/1.4.4/initrd
  echo -n "Uploading new kernel from $target_ncn to s3://${bucket}/${fixed_kernel_object_ceph} ... "
  if ! cray artifacts create "$bucket" "$fixed_kernel_object_ceph" "${TEMP}/"*.kernel > "${CURRENT_LOG_DIR}/kernel.upload.log" 2>&1; then
    upload_error=1
    echo >&2 'Failed!'
  else
    echo 'Done'
  fi
  echo -n "Uploading new initrd from $target_ncn to s3://${bucket}/${fixed_initrd_object_ceph} ... "
  if ! cray artifacts create "$bucket" "$fixed_initrd_object_ceph" "$TEMP/initrd.img.xz" > "${CURRENT_LOG_DIR}/initrd.upload.log" 2>&1; then
    upload_error=1
    echo >&2 'Failed!'
  else
    echo 'Done'
  fi

  rm -rf "${TEMP}"

  if [ "$upload_error" -ne 0 ]; then
    echo >&2 'CrayCLI failed to upload artifacts. Please verify craycli is authenticated, and then re-run this script as "./install-hotfix.sh upload-only" to resume at the failed step.'
    echo >&2 "For insight into the failure, see CrayCLI upload logs at ${CURRENT_LOG_DIR}/{kernel,initrd}.upload.log"
    exit 1
  fi

  if IFS=$'\n' read -rd '' -a NCN_XNAMES; then
    :
  fi <<< "$(cray hsm state components list --role Management --subrole Storage --type Node --format json | jq -r '.Components | map(.ID) | join("\n")')"
  update-bss "$fixed_kernel_object_ceph" "$fixed_initrd_object_ceph" "${NCN_XNAMES[@]}"
else
  echo "Artifact upload skip requested."
fi
echo "The following NCN storage nodes were live patched:"
printf "\t%s\n" "${NCNS[@]}"
