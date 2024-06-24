#!/bin/bash
#
# MIT License
#
# (C) Copyright 2014-2024 Hewlett Packard Enterprise Development LP
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

set -eo pipefail
test -n "$DEBUG" && set -x

# Globals
CHANGE_PASSWORD="no"
CLEANUP_INVOKED="no"
TMPDIR=$(mktemp -p /tmp -d ncn-ssh-keygen.XXXXXXXXXX)
KEY_SOURCE=$TMPDIR # can override with -d
KEYTYPE=""
MODIFY_AUTHORIZED_KEYS="yes"
SQUASH_PATHS=()
SSH_KEYGEN_ARGS=()
SSH_KEY_DIR=""
START_DIR=$PWD
SUPPLIED_HASH="${SQUASHFS_ROOT_PW_HASH:-""}"
TIMEZONE=""
TZ_ONLY="no"

function tz_only() {
  [[ ${TZ_ONLY} == yes ]]
}

function cleanup() {
  local squashfs_root
  local squash

  # Depending on the error scenario, this can get invoked more than once. We want it to run only once.
  if [[ $CLEANUP_INVOKED == "yes" ]]; then
    return
  fi

  CLEANUP_INVOKED="yes"

  if [ -d "$TMPDIR" ]; then
    # don't use -v else -h output includes this detail
    rm -rf "$TMPDIR"
  fi

  echo "Cleaning up the unpacked squashfs"
  for squash in "${SQUASH_PATHS[@]}"; do
    squashfs_root=$(realpath "$(dirname "$squash")/squashfs-root")
    echo "Removing $squashfs_root if present"
    rm -rf "$squashfs_root"
  done

  cd "$START_DIR"
}

function err_report() {
  echo "Error on line $1"
  cleanup
}

# it's a trap!
trap 'err_report $LINENO' ERR TERM HUP INT
trap 'cleanup' EXIT

function usage() {
  echo -e "Usage: $(basename "$0") [-p] [-d dir] [ -z timezone] [-k kubernetes-squashfs-file] [-s storage-squashfs-file] [ssh-keygen arguments]\n"
  echo -e "Usage: $(basename "$0") [ -Z timezone] [-k kubernetes-squashfs-file] [-s storage-squashfs-file]\n"
  echo "       This script semi-automates the process of changing the timezone, root"
  echo "       password, and adding new ssh keys for the root user to the NCN squashfs"
  echo -e "       image(s).\n"
  echo "       The script will immediately prompt for a new passphrase for ssh-keygen."
  echo "       The script will then proceed to unsquash the supplied squash files and"
  echo "       then prompt for a password. Once the password of the last squash has been"
  echo -e "       provided, the script will continue to completion without interruption.\n"
  echo "       The process can be fully automated by using the SQUASHFS_ROOT_PW_HASH"
  echo -e "       environment variable (see below) along with either -d or -N\n"
  echo "       -a             Do *not* modify the authorized_keys file in the squashfs."
  echo "                      If modifying a previously modified image, or an"
  echo "                      authorized_keys file that contains the public key is already"
  echo "                      included in the directory used with the -d option, you may"
  echo -e "                      want to use this option.\n"
  echo "       -d dir         If provided, the contents will be copied into /root/.ssh/"
  echo "                      in the squashfs image. Do not supply ssh-keygen arguments"
  echo -e "                      when using -d. Assumes public keys have a .pub extension.\n"
  echo "       -p             Change or set the password in the squashfs. By default, the"
  echo "                      user prompted to enter the password after each squashfs file"
  echo "                      is unsquashed. Use the SQUASHFS_ROOT_PW_HASH environment"
  echo "                      variable (see below) to change or set the password without"
  echo -e "                      being prompted.\n"
  echo "       -z timezone    By default the timezone on NCNs is UTC. Use this option to"
  echo -e "                      override.\n"
  echo -e "       -Z timezone    Same as -z, except SSH keys and passwords are not modified in the image."
  echo -e "SUPPORTED SSH-KEYGEN ARGUMENTS\n"
  echo "       The following ssh-keygen(1) arguments are supported by this script:"
  echo "       [-b bits] [-t dsa | ecdsa | ecdsa-sk | ed25519 | ed25519-sk | rsa]"
  echo -e "       [-N new_passphrase] [-C comment]\n"
  echo -e "ENVIRONMENT VARIABLES\n"
  echo "       SQUASHFS_ROOT_PW_HASH    If set to the encrypted hash for a root password,"
  echo "                                this hash will be injected into /etc/shadow in the"
  echo "                                squashfs image and there will be no interactive prompt"
  echo "                                to set it. When setting this variable, be sure to use"
  echo "                                single quotes (') to ensure any '$' characters are not"
  echo -e "                                interpreted.\n"
  echo -e "       DEBUG                    If set, the script will be run with 'set -x'\n"
  echo -e "       CSM_RELEASE              If set, the script will apply any and all per-release adjustments."
  echo "NOTES"
  echo "       If it is desired to not have any ssh in the image, specify -d with an empty"
  echo "       directory along with -a"

}

function usage_exit() {
  echo "ERROR: $*" >&2
  usage
  exit 1
}

function err_exit() {
  echo "ERROR: $*" >&2
  exit 1
}

function preflight_sanity() {
  [ "$(whoami)" == "root" ] || err_exit "the script must be run by the root user"
  command -v mksquashfs >&/dev/null || err_exit "mksquashfs was not found on the system"
}

function verify_ssh_keys() {
  local key_dir=$1
  local private_keys
  local key

  # turn on extended pattern matching
  shopt -s extglob
  # only process private keys with standard naming (id_<key_type>)
  private_keys="$key_dir/id_!(*.*)"
  for key in $private_keys; do
    touch "$TMPDIR"/empty-file
    # we're only looking for malformed keys here vs ensuring private & public keys match, etc.
    ssh-keygen -Y sign -f "$key" -n file "$TMPDIR"/empty-file || err_exit "unable to verify private key: $key"
    # ensure we don't keep empty-file and empty-file.sig across iterations
    rm -f "$TMPDIR"/empty-file*
  done
}

function process_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -a)
        # Technically this is mutually exclusive with -Z, but practically -Z kind of implies -a anyway,
        # so the behavior should match what the person wants anyway. Therefore, not checking for that
        # combination.
        MODIFY_AUTHORIZED_KEYS="no"
        shift # past argument
        ;;
      -b)
        # Check for mutually exclusive combinations
        [[ -z ${SSH_KEY_DIR} ]] || usage_exit "-b cannot be specified with -d"
        [[ ${TZ_ONLY} != yes ]] || usage_exit "-b cannot be specified with -Z"

        SSH_KEYGEN_ARGS+=("-b $2")
        shift # past argument
        shift # past value
        ;;
      -C)
        # Check for mutually exclusive combinations
        [[ -z ${SSH_KEY_DIR} ]] || usage_exit "-C cannot be specified with -d"
        [[ ${TZ_ONLY} != yes ]] || usage_exit "-C cannot be specified with -Z"

        # ensure the comment is quoted in case it contains spaces
        SSH_KEYGEN_ARGS+=("-C \"$2\"")
        shift # past argument
        shift # past value
        ;;
      -d)
        # Check for mutually exclusive combinations
        [[ ${#SSH_KEYGEN_ARGS[*]} -eq 0 ]] || usage_exit "-d cannot be specified along with ssh-keygen arguments"
        [[ ${TZ_ONLY} != yes ]] || usage_exit "-d cannot be specified with -Z"

        SSH_KEY_DIR=$2
        [[ -d ${SSH_KEY_DIR} ]] || usage_exit "directory not found or not a directory: ${SSH_KEY_DIR}"

        # no longer using TMPDIR for keys
        KEY_SOURCE=$SSH_KEY_DIR
        verify_ssh_keys "$KEY_SOURCE"
        shift # past argument
        shift # past value
        ;;
      -h)
        usage
        exit 0
        ;;
      -N)
        # Check for mutually exclusive combinations
        [[ -z ${SSH_KEY_DIR} ]] || usage_exit "-N cannot be specified with -d"
        [[ ${TZ_ONLY} != yes ]] || usage_exit "-N cannot be specified with -Z"

        # escape quotes in case passphrase is empty
        SSH_KEYGEN_ARGS+=("-N \"$2\"")
        shift # past argument
        shift # past value
        ;;
      -k | -s)
        SQUASH_PATHS+=("$2")
        shift # past argument
        shift # past value
        ;;
      -p)
        # Check for mutually exclusive combinations
        [[ ${TZ_ONLY} != yes ]] || usage_exit "-p cannot be specified with -Z"

        CHANGE_PASSWORD="yes"
        shift # past argument
        ;;
      -t)
        # Check for mutually exclusive combinations
        [[ -z ${SSH_KEY_DIR} ]] || usage_exit "-t cannot be specified with -d"
        [[ ${TZ_ONLY} != yes ]] || usage_exit "-t cannot be specified with -Z"

        KEYTYPE=$2
        SSH_KEYGEN_ARGS+=("-t $2")
        shift # past argument
        shift # past value
        ;;
      -z)
        # Technically this is mutually exclusive with -Z, but practically -Z kind of implies -z anyway,
        # so the behavior should match what the person wants anyway. Therefore, not checking for that
        # combination.

        TIMEZONE="$2"
        shift # past argument
        shift # past value
        ;;
      -Z)
        # Check for mutually exclusive arguments
        [[ -z ${SSH_KEY_DIR} ]] || usage_exit "-Z cannot be specified with -d"
        [[ ${#SSH_KEYGEN_ARGS[*]} -eq 0 ]] || usage_exit "-Z cannot be specified along with ssh-keygen arguments"
        [[ ${CHANGE_PASSWORD} == no ]] || usage_exit "-Z cannot be specified with -p"

        TIMEZONE="$2"
        TZ_ONLY="yes"
        shift # past argument
        shift # past value
        ;;
      *)
        echo "Unknown or unsupported option $1"
        exit 1
        ;;
    esac
  done

  if [ -n "$TIMEZONE" ]; then
    if ! [ -f /usr/share/zoneinfo/"$TIMEZONE" ]; then
      echo "ERROR: can't find $TIMEZONE in /usr/share/zoneinfo"
      exit 1
    fi
  fi

  # Some things only need to be done if not in TZ-only mode
  if ! tz_only; then

    command -v ssh-keygen >&/dev/null || err_exit "ssh-keygen was not found on the system"

    if [ -z "$SSH_KEY_DIR" ] && [ ${#SSH_KEYGEN_ARGS[*]} -eq 0 ]; then
      echo "ERROR: refusing to create new images without ssh keys. Please use the -d option"
      echo "       or supply ssh-keygen arguments on the command line."
      usage
      exit 1
    fi

    if [ -n "$KEYTYPE" ]; then
      SSH_KEYGEN_ARGS+=("-f $KEY_SOURCE/id_$KEYTYPE")
    fi

  fi
}

function verify_and_unsquash() {
  local squash
  local type

  for squash in "${SQUASH_PATHS[@]}"; do
    if ! test -f "$squash"; then
      echo -e "\nERROR: $squash not found"
      exit 1
    fi

    type=$(file "$squash")
    if ! [[ $type =~ Squashfs ]]; then
      echo -e "\nERROR: $squash does not appear to be a squashfs filesystem"
      exit 1
    fi
    echo -e "\nvalidated squashfs path, unsquashing: $squash"
    unsquashfs -n -no -d "$(dirname "$squash")"/squashfs-root "$squash" 2> /dev/null || true

    # remove any character device files
    find "$(dirname "$squash")"/squashfs-root/ -type c -exec rm -f {} \;
  done
}

function update_etc_shadow() {
  local squashfs_root=$1
  local seconds_per_day=$((60 * 60 * 24))
  local days_since_1970=$(($(date +%s) / seconds_per_day))

  sed -i "/^root:/c\root:$SUPPLIED_HASH:$days_since_1970::::::" "$squashfs_root"/etc/shadow
}

function set_timezone() {
  local squashfs_root

  if [ -n "$TIMEZONE" ]; then
    for squash in "${SQUASH_PATHS[@]}"; do
      squashfs_root="$(dirname "$squash")"/squashfs-root

      pushd "$squashfs_root"
      if ! test -f usr/share/zoneinfo/"$TIMEZONE"; then
        echo >&2 "Timezone file /usr/share/zoneinfo/$TIMEZONE does not exist"
        exit 1
      fi

      # clean up any previous set values just in case.
      sed -i 's/^TZ.*//' etc/environment

      echo "TZ=$TIMEZONE" >> etc/environment
      rm -f etc/localtime

      ln -s usr/share/zoneinfo/"$TIMEZONE" etc/localtime
      popd

    done
  fi
}

# Technically, setup ssh and passwords
function setup_ssh() {
  local name
  local squash
  local squashfs_root

  # generate an ssh key if we were told to do so
  if [ ${#SSH_KEYGEN_ARGS[*]} -ne 0 ]; then
    echo -e "\ninvoking ssh-keygen ${SSH_KEYGEN_ARGS[*]}"
    eval ssh-keygen -q "${SSH_KEYGEN_ARGS[*]}"
  fi

  # set the password and set up passwordless ssh if appropriate; remove ssh host keys
  for squash in "${SQUASH_PATHS[@]}"; do
    squashfs_root=$(realpath "$(dirname "$squash")/squashfs-root")
    name=$(basename "$squash")

    echo -e "\nSetting the password for $name"
    # change password in the squash
    if [ "$CHANGE_PASSWORD" = "yes" ]; then
      if [ -n "$SUPPLIED_HASH" ]; then
        update_etc_shadow "$squashfs_root"
      else
        passwd --root "$squashfs_root"
      fi
    fi

    # copy ssh key to the squashfs
    mkdir -pv "$squashfs_root"/root/.ssh
    chmod 700 "$squashfs_root"/root/.ssh
    # host keys will change, don't propagate
    rsync -av --exclude known_hosts "$KEY_SOURCE"/* "$squashfs_root"/root/.ssh/

    # set up passwordless ssh between NCNs
    if [ "$MODIFY_AUTHORIZED_KEYS" = "yes" ]; then
      cat "$KEY_SOURCE"/*.pub >> "$squashfs_root"/root/.ssh/authorized_keys
      chmod 600 "$squashfs_root"/root/.ssh/authorized_keys
    fi

    rm -f "$squashfs_root"/etc/ssh/*key*
  done
}

function create_new_squashfs() {
  local name
  local new_name
  local squash

  for squash in "${SQUASH_PATHS[@]}"; do
    pushd "$(dirname "$squash")"
    name=$(basename "$squash")
    # prefix squashfs names with "secure-" so it's clear they have root keys
    # and credentials.  but don't keep prepending "secure-" in the case where
    # we're modifying a previously-modified squashfs.
    if [[ $name =~ secure- ]]; then
      new_name=$name
    else
      # first time modifying this image
      new_name=secure-"$name"
    fi

    echo -e "\nCreating new boot artifacts..."
    mksquashfs squashfs-root "$new_name" -no-xattrs -comp gzip -no-exports -noappend -no-recovery -processors "$(nproc)"

    # save original squashfs
    mkdir -vp old
    mv -vb "$name" old/

    echo -e "\nRemoving squashfs-root/"
    rm -rf squashfs-root
    popd
  done
}

function csm_144_patch {
  local name
  local rc
  local squash
  local kernel_version='5.14.21-150400.24.100.2.27359.1.PTF.1215587'
  local new_drivers=(
    'qed'
    'qede'
    'qedf'
    'qedi'
  )
  local add_drivers=()
  local omit_drivers=()
  local rpms=()
  local tar_path

  if [ -n "$CSM_PATH" ]; then
    if [ ! -d "${CSM_PATH}" ]; then
      echo >&2 "CSM_PATH was defined but does not exist [$CSM_PATH]"
    else
      tar_path="${CSM_PATH}"
    fi
  fi
  if [ -z "${tar_path}" ]; then
    if [ -n "${CSM_DISTDIR}" ]; then
      if [ ! -d "${CSM_DISTDIR}" ]; then
        echo >&2 "CSM_DISTDIR was defined but does not exist [$CSM_DISTDIR]"
      else
        tar_path="${CSM_DISTDIR}"
      fi
    fi
  fi
  if [ -z "${tar_path}" ]; then
    echo >&2 "Failed to resolve path to extracted tarball! CSM_PATH nor CSM_DISTDIR were found in the environment!"
    return 1
  fi
  if [ ! -d "${tar_path}" ]; then
    echo >&2 "Extracted tarball resolved to ${tar_path} but this path does not exist!"
    return 1
  fi
  rpms=(
    "${tar_path}/rpm/cray/csm/sle-15sp4/x86_64/qlgc-fastlinq-kmp-default-8.74.1.0_k5.14.21_150400.22-1.sles15sp4.x86_64.rpm"
    "${tar_path}/rpm/cray/csm/sle-15sp4/x86_64/kernel-default-devel-${kernel_version}.x86_64.rpm"
    "${tar_path}/rpm/cray/csm/sle-15sp4/x86_64/kernel-default-${kernel_version}.x86_64.rpm"
    "${tar_path}/rpm/cray/csm/sle-15sp4/noarch/kernel-devel-${kernel_version}.noarch.rpm"
    "${tar_path}/rpm/cray/csm/sle-15sp4/noarch/kernel-macros-${kernel_version}.noarch.rpm"
    "${tar_path}/rpm/cray/csm/sle-15sp4/x86_64/kernel-syms-${kernel_version}.x86_64.rpm"
  )

  echo "Patching images for CSM 1.4.4 ... "
  for squash in "${SQUASH_PATHS[@]}"; do
    (
      pushd "$(dirname "$squash")"
      name="$(basename "$squash")"

      if [[ $name =~ 'kubernetes' ]]; then
        # --nodeps is necessary to bypass any extra, old Kernel packages (e.g. kernel-source) throwing hands up at us upgrading their dependencies.
        # --root is necessary for installing our packages into the extracted squashfs.
        if rpm -Uvh --nodeps --root "$(pwd)/squashfs-root" "${rpms[@]}"; then
          :
        else
          rc=$?
          [ "$rc" -ne 127 ] && return "$rc"
        fi

        # Update the default kernel version.
        sed -i 's/^multiversion\.kernels =.*/multiversion.kernels = '"${kernel_version}"'/g' squashfs-root/etc/zypp/zypp.conf

        # Satisfy the start condition for the purge-kernels.service to clean up any left-over old kernel items.
        touch squashfs-root/boot/do_purge_kernels

        # Remove the QLogic Dracut module configuration.
        rm -f squashfs-root/etc/dracut.conf.d/fastlinq.conf
      fi

      # Blacklist qedr from rootfs.
      grep -qxF 'install qedr /bin/true' squashfs-root/etc/modprobe.d/disabled-modules.conf || echo 'install qedr /bin/true' >> squashfs-root/etc/modprobe.d/disabled-modules.conf

      # Blacklist qedr from dracut.
      if [ -f squashfs-root/etc/dracut.conf.d/99-csm-ansible.conf ]; then
        . squashfs-root/etc/dracut.conf.d/99-csm-ansible.conf
        if [[ ${omit_drivers[*]} =~ qedr ]]; then
          :
        else
          sed -i -E 's/^omit_drivers\+=" ?/omit_drivers+=" qedr /' squashfs-root/etc/dracut.conf.d/99-csm-ansible.conf
        fi

        if [[ $name =~ 'kubernetes' ]]; then

          for driver in "${new_drivers[@]}"; do
            if [[ ${add_drivers[*]} =~ $driver ]]; then
              :
            else
              add_drivers+=("$driver")
            fi
          done
          new_add_drivers_line="$(printf 'add_drivers+=" %s "' "${add_drivers[*]}")"
          sed -i -E 's/^add_drivers\+=.*/'"$new_add_drivers_line"'/' squashfs-root/etc/dracut.conf.d/99-csm-ansible.conf
        fi

      else

        if [[ $name =~ 'kubernetes' ]]; then
          new_add_drivers_line="$(printf 'add_drivers+=" %s "' "${new_drivers[*]}")"
          cat << EOF > squashfs-root/etc/dracut.conf.d/99-csm-ansible.conf
$new_add_drivers_line # Needs to start and end with a space to mitigate warnings.
EOF
        fi
        cat << EOF >> squashfs-root/etc/dracut.conf.d/99-csm-ansible.conf
omit_drivers+=" qedr " # Needs to start and end with a space to mitigate warnings.
EOF
      fi

      rm squashfs-root/squashfs/*
      if [ -f "squashfs-root/srv/cray/scripts/metal/create-kis-artifacts.sh" ] ; then
        chroot squashfs-root bash -c "/srv/cray/scripts/metal/create-kis-artifacts.sh kernel-initrd-only"
      elif [ -f "squashfs-root/srv/cray/scripts/common/create-kis-artifacts.sh" ] ; then
        chroot squashfs-root bash -c "/srv/cray/scripts/common/create-kis-artifacts.sh kernel-initrd-only"
      else
        echo >&2 "Fatal Error! Could not locate create-kis-artifacts.sh in $name's extracted squashFS."
        return 1
      fi
      mkdir -pv old
      mv -v ./*.kernel old/
      mv -v ./initrd* old/
      cp -pv squashfs-root/squashfs/* .
      popd
    )
  done
}

function csm_145_patch {
  local rpms=()
  local tar_path

  if [ -n "$CSM_PATH" ]; then
    if [ ! -d "${CSM_PATH}" ]; then
      echo >&2 "CSM_PATH was defined but does not exist [$CSM_PATH]"
    else
      tar_path="${CSM_PATH}"
    fi
  fi
  if [ -z "${tar_path}" ]; then
    if [ -n "${CSM_DISTDIR}" ]; then
      if [ ! -d "${CSM_DISTDIR}" ]; then
        echo >&2 "CSM_DISTDIR was defined but does not exist [$CSM_DISTDIR]"
      else
        tar_path="${CSM_DISTDIR}"
      fi
    fi
  fi
  if [ -z "${tar_path}" ]; then
    echo >&2 "Failed to resolve path to extracted tarball! CSM_PATH nor CSM_DISTDIR were found in the environment!"
    return 1
  fi
  if [ ! -d "${tar_path}" ]; then
    echo >&2 "Extracted tarball resolved to ${tar_path} but this path does not exist!"
    return 1
  fi

  rpms=(
    "${tar_path}/rpm/cray/csm/sle-15sp4/noarch/dracut-metal-mdsquash-2.3.2-1.noarch.rpm"
  )

  echo "Patching images for CSM 1.4.5 ... "
  for squash in "${SQUASH_PATHS[@]}"; do
    (
      pushd "$(dirname "$squash")" || exit

      if rpm -Uvh --nodeps --root "$(pwd)/squashfs-root" "${rpms[@]}"; then
        :
      else
        rc=$?
        [ "$rc" -ne 127 ] && return "$rc"
      fi

      sed -i -r -E 's|(.*)\[\s?LABEL=CONTAIN,\s+/var/lib/containers.*\]|\1[ LABEL=CONTAIN, /var/lib/containers, auto, defaults ]|g' \
        squashfs-root/etc/cloud/cloud.cfg.d/01_metalfs.cfg \
        squashfs-root/srv/cray/resources/metal/cloud.cfg.d/01_metalfs.cfg

      popd || exit
    )
  done
}

if [ "$#" -lt 2 ]; then
  usage
  exit 1
fi
preflight_sanity
process_args "$@"
verify_and_unsquash

if ! tz_only; then
  setup_ssh
fi

set_timezone
if [[ $CSM_RELEASE =~ ^1\.4\.4 ]]; then
  csm_144_patch
elif [[ $CSM_RELEASE =~ ^1\.4\.([5-9]|[1-9]0+|[1-9]{2,}) ]]; then
  csm_144_patch
  csm_145_patch
fi
create_new_squashfs
cleanup

echo -e "\nScript executed successfully"
