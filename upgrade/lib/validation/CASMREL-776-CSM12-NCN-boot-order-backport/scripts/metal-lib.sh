#!/bin/bash
# Copyright 2020-2021 Hewlett Packard Enterprise Development LP
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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# (MIT License)
# Permalink to original lib: https://github.com/Cray-HPE/node-image-build/blob/cfad25b84431cfc5c3b8935df78a7ce68d4a8be4/boxes/ncn-common/files/scripts/metal/metal-lib.sh
fslabel=BOOTRAID
type mprint >/dev/null 2>&1 || . /srv/cray/scripts/common/lib.sh

set -e

# initrd - fetched from /proc/cmdline ; grab the horse we rode in on, not what the API aliens say.
export initrd=$(grep -Po 'initrd=([\w\.]+)' /proc/cmdline | cut -d '=' -f2)
[ -z "$initrd" ] && initrd=initrd.img.xz

trim() {
    local var="$*"
    var="${var#${var%%[![:space:]]*}}"   # remove leading whitespace characters
    printf "%s" "$var"
}

install_grub2() {
    local working_path=${1:-/metal/recovery}
    mount -v -L $fslabel $working_path 2>/dev/null || echo 'continuing ...'
    # Remove all existing ones; this script installs the only bootloader.
    for entry in $(efibootmgr | awk -F '*' '/CRAY/ {print $1}'); do
         efibootmgr -q -b ${entry:4:8} -B
    done

    # Install grub2.
    local name=$(grep PRETTY_NAME /etc/*release* | cut -d '=' -f2 | tr -d '"')
    local index=0
    [ -z "$name" ] && name='CRAY Linux'
    for disk in $(mdadm --detail $(blkid -L $fslabel) | grep /dev/sd | awk '{print $NF}'); do
        # Add '--suse-enable-tpm' to grub2-install once we need TPM.
        grub2-install --no-rs-codes --suse-force-signed --root-directory $working_path --removable "$disk"
        efibootmgr -c -D -d "$disk" -p 1 -L "CRAY UEFI OS $index" -l '\efi\boot\bootx64.efi' | grep CRAY
        index=$(($index + 1))
    done

    # Get the kernel command we used to boot.
    local init_cmdline=$(cat /proc/cmdline)
    local disk_cmdline=''
    for cmd in $init_cmdline; do
        # cleans up first argument when running this script on a disk-booted system
        if [[ $cmd =~ kernel$ ]]; then
            cmd=$(basename "$(echo $cmd  | awk '{print $1}')")
        fi
        if [[ $cmd =~ ^rd.live.overlay.reset ]] ; then :
        elif [[ $cmd =~ ^rd.debug ]] ; then :
        # removes all metal vars, and escapes anything that iPXE was escaping
        # metal vars are used for customizing nodes on deployment, they don't need
        # to stick around for runtime.
        # (i.e. ds=nocloud-net;s=http://$url will get the ; escaped)
        # removes netboot vars
        elif [[ ! $cmd =~ ^metal. ]] && [[ ! $cmd =~ ^ip=.*:dhcp ]] && [[ ! $cmd =~ ^bootdev= ]]; then
            disk_cmdline="$(trim $disk_cmdline) ${cmd//;/\\;}"
        fi
    done

    # ensure no-wipe is now set for disk-boots.
    disk_cmdline="$disk_cmdline metal.no-wipe=1"

    # Make our grub.cfg file.
    # TODO: Add disk-rebuild option
    cat << EOF > $working_path/boot/grub2/grub.cfg
set timeout=10
set default=0 # Set the default menu entry
menuentry "$name" --class sles --class gnu-linux --class gnu {
    set gfxpayload=keep
    # needed for compression
    insmod gzio
    # needed for partition manipulation
    insmod part_gpt
    # needed for block device handles
    insmod diskfilter
    # needed for RAID (this does not always load despite this entry)
    insmod mdraid1x
    # verbosely define accepted formats (ext2/3/4 & xfs)
    insmod ext2
    insmod xfs
    echo    'Loading kernel ...'
    linuxefi \$prefix/../$disk_cmdline
    echo    'Loading initial ramdisk ...'
    initrdefi \$prefix/../$initrd
}
EOF
}

function update_auxiliary_fstab {
    local working_path=${1:-/metal/recovery}

    # Mount at boot
    if [ -f /etc/fstab.metal ] && grep -q "${fslabel^^}" /etc/fstab.metal; then :
    else
        mkdir -pv $working_path
        printf '# \nLABEL=%s\t%s\t%s\t%s\t%d\t%d\n' "${fslabel^^}" $working_path vfat defaults 0 0 >> /etc/fstab.metal
    fi
}

function get_boot_artifacts {
    local squashfs_storage
    local base_dir
    local live_dir
    local working_path=${1:-/metal/recovery}
    local artifact_error=0

    mount -L BOOTRAID -T /etc/fstab.metal && echo 'continuing ...'
    mkdir -pv $working_path/boot

    squashfs_storage=$(grep -Po 'root=\w+:?\w+=\w+' /proc/cmdline | cut -d '=' -f3)
    [ -z "$squashfs_storage" ] && squashfs_storage=SQFSRAID

    # rd.live.dir - fetched from /proc/cmdline ; grab any customization or deviation from the default preference, aling with dracut.
    live_dir=$(grep -Eo 'rd.live.dir=.* ' /proc/cmdline | cut -d '=' -f2 | sed 's![^/]$!&/!')
    [ -z "$live_dir" ] && live_dir=LiveOS/

    # pull the loaded items from the mounted squashFS storage into the fallback bootloader
    base_dir="$(lsblk $(blkid -L $squashfs_storage) -o MOUNTPOINT -n)/$live_dir"
    [ -d $base_dir ] || echo >&2 'SQFSRAID was not mounted!' return 1
    cp -pv "${base_dir}kernel" "$working_path/boot/" || echo >&2 "Kernel file NOT found in $base_dir!" || artifact_error=1
    cp -pv "${base_dir}${initrd}" "$working_path/boot/" || echo >&2 "${initrd} file NOT found in $base_dir!" || artifact_error=1

    [ "$artifact_error" = 0 ] && return 0 || return 1
}

function configure_lldp() {
    local interfaces
    interfaces=`ls /sys/class/net/ | grep mgmt`
    for i in $interfaces; do
      echo "enabling and configuring LLDP for interface: $i"
      lldptool set-lldp -i $i adminStatus=rxtx
      lldptool -T -i $i -V  sysName enableTx=yes
      lldptool -T -i $i -V  portDesc enableTx=yes
      lldptool -T -i $i -V  sysDesc enableTx=yes
      lldptool -T -i $i -V sysCap enableTx=yes
      lldptool -T -i $i -V mngAddr enableTx=yes
    done
    echo 'enabling and configuring of LLDP is complete'
}

function set_static_fallback() {

    #
    ## Set static IP; assign the current IP as static.
    #

    local defgw
    local ipaddr
    local lan
    local netmask
    local netconf=/tmp/netconf

    # BMCs either run dedicated on lan3 (last LAN channel as is the case with Intel's),
    # or lan1 (when there's only one channel).
    if ipmi_output_3=$(ipmitool lan print 3 2>/dev/null); then
        lan=3
        echo "$ipmi_output_3" > $netconf
    elif [ -z $lan ] && ipmi_output_1=$(ipmitool lan print 1 2>/dev/null); then
        lan=1
        echo "$ipmi_output_1" > $netconf
    elif [ -z $lan ]; then
        echo "Failed to determine which LAN channel to use!"
    fi

    ipaddr=$(grep -Ei 'IP Address\s+\:' $netconf | awk '{print $NF}')
    netmask=$(grep -Ei 'Subnet Mask\s+\:' $netconf | awk '{print $NF}')
    defgw=$(grep -Ei 'Default Gateway IP\s+\:' $netconf | awk '{print $NF}')
    ipmitool lan set $lan ipsrc static || :
    ipmitool lan set $lan ipaddr $ipaddr || :
    ipmitool lan set $lan netmask $netmask || :
    ipmitool lan set $lan defgw ipaddr $defgw || :
    ipmitool lan print $lan || :
    rm -f $netconf
}

function reset_bmc() {
    local reset=${1:-'cold'}
    ipmitool mc reset "$reset"
    sleep 5 # Allow the BMC to go offline to prevent false-positive for connectivity checks.
}

function enable_amsd() {
    if ! rpm -qi amsd >/dev/null 2>&1 ; then
        echo 'amsd is not installed, ignoring amsd services'
        return 0
    fi
    echo scanning vendor ... && vendor=$(ipmitool fru | grep -i 'board mfg' | tail -n 1 | cut -d ':' -f2 | tr -d ' ')
    case $vendor in
        *Marvell*|HP|HPE)
            echo Enabling iLO services for detected vendor: $vendor
            systemctl enable ahslog
            systemctl enable amsd
            systemctl enable smad

            # Not needed; SCSI, IDE, nor FCA are used
            # systemctl enable cpqFca
            # systemctl enable cpqIde
            # systemctl enable cpqScsi

            systemctl start ahslog
            systemctl start amsd
            systemctl start smad

            # Not needed; SCSI, IDE, nor FCA are used
            # systemctl start cpqFca
            # systemctl start cpqIde
            # systemctl start cpqScsi
            ;;
        *)
        echo >&2 not enabling iLO services for detected vendor: $vendor
        ;;
    esac
}

function clean_bogies {
    # removing eth0 configs
    # ALWAYS DO THIS; THESE SHOULD NOT EXIST IN METAL
    # Any interface file that exists is tracked by wicked, if the interface does
    # not actually exist in reality then wicked will complain. Remove the needless files.
    rm -rfv /etc/sysconfig/network/*eth*
}

function drop_metal_tcp_ip {
    local nic=$1
    [ -z "$nic" ] && return 0
    local ip4addr
    local ip6addr
    ip4addr=$(ip a s $nic | grep 'inet '| head -n 1 | awk '{print $2}')
    ip6addr=$(ip a s $nic | grep inet6 | head -n 1 | awk '{print $2}')
    if [ -n "$ip4addr" ]; then
        echo "Deleting ephemeral bootstrap IP $ip4addr from $nic"
        ip a d $ip4addr dev $nic
    fi
    if [ -n "$ip6addr" ]; then
        echo "Deleting ephemeral bootstrap IP $ip6addr from $nic"
        ip a d $ip6addr dev $nic
    fi
}

function write_default_route {
    # Setup the route
    # ALWAYS CLOBBER; ROUTE SHOULD ALWAYS BE THE SAME
    # CLOBBER=UPDATE; ALWAYS UPDATE.
    local gw
    local nic=bond0.cmn0
    gw=$(craysys metadata get --level node ipam | jq .cmn.gateway | tr -d '"')
    echo "default ${gw} - $nic" >/etc/sysconfig/network/ifroute-$nic && wicked ifreload all || systemctl restart wickedd && sleep 3
}

# This will let the order fall into however the BIOS wants it; grouping netboot, disk, and removable options.

# Set to 1 to skip enforcing the order, but still cleanup the boot menu.
[ -z "$no_enforce" ] && export no_enforce=0
[ -z "$efibootmgr_prefix" ] && export efibootmgr_prefix=''

function efi_fail_host {
    echo >&2 "no prefix-driver for hostname: $hostname"
    return 1
}

function efi_trim {
    echo disabling undesired boot entries $(cat /tmp/rbbs*) && cat /tmp/rbbs* | sort | sed 's/^Boot//g' | awk '{print $1}' | tr -d '*' | xargs -r -i efibootmgr -b {} -A
}

function efi_remove {
    echo removing undesired boot entries $(cat /tmp/sbbs*) && cat /tmp/sbbs* | sort | sed 's/^Boot//g' | awk '{print $1}' | tr -d '*' | xargs -r -i efibootmgr -b {} -B
}

function efi_enforce {
    # IMPORTANT: The ENTIRE list of entries needs to exist, otherwise iLO/HPE servers will undo any changes.
    # both /tmp/bbs* and /tmp/rbbs* are concatenated together; the ordinal order of the /tmp/bbsNUM files
    # will enforce NICs first.
    echo enforcing boot order $(cat /tmp/bbs*) && efibootmgr -o $efibootmgr_prefix$(cat /tmp/bbs* | sed 's/^Boot//g' | awk '{print $1} ' | tr -d '*' | tr -d '\n' | sed -r 's/(.{4})/\1,/g;s/,$//'),$(cat /tmp/rbbs* | sed 's/^Boot//g' | awk '{print $1} ' | tr -d '*' | tr -d '\n' | sed -r 's/(.{4})/\1,/g;s/,$//') | grep -i bootorder
    echo activating boot entries && cat /tmp/bbs* | awk '!x[$0]++' | sed 's/^Boot//g' | tr -d '*' | awk '{print $1}' | xargs -r -i efibootmgr -b {} -a
}

# uses /tmp/rbbs99
function efi_specials {
    # TODO: If Marvell; then ensure PXE retries only once per NIC.
    echo 'removing Shasta V1.3 items' && efibootmgr | grep -iP '(crayinstall|sles-secureboot)' | tee /tmp/sbbs
}

function setup_uefi_bootorder() {
cat << EOM
Configuring UEFI boot-order...
these use the same commands from the manual page:
    https://github.com/Cray-HPE/docs-csm/blob/main/background/ncn_boot_workflow.md#setting-order
EOM
    echo scanning vendor ... && vendor=$(ipmitool fru | grep -i 'board mfg' | tail -n 1 | cut -d ':' -f2 | tr -d ' ')
    hostname=${hostname:-$(hostname)}
    # Add vendors here; add like-vendors on the same case statement.
    # "like-vendors" means their efibootmgr outboot matches

    # formatting:
    # if another vendor is identical then it should live with another.
    # vendors may have differing hostnames, depending where this script runs
    # vendor)
    #   hostname_prefix_1)
    #     file1)
    #     fileN)
    #   hostname_prefix_2)
    #     file1)
    #     fileN)
    #   hostname_prefix_N)
    #     file1)
    #     fileN)
    #   error)
    #   remove_file_1
    #   remove_file_N
    # done
    case $vendor in
        *GIGABYTE*)
            # Removal file(s) ...
            efibootmgr | grep -ivP '(pxe ipv?4.*)' | grep -iP '(adapter|connection|nvme|sata)' | tee /tmp/rbbs1
            efibootmgr | grep -iP '(pxe ipv?4.*)' | grep -i connection | tee /tmp/rbbs2
            efibootmgr_prefix=''
            efi_trim
            efi_specials
            efi_remove
            case $hostname in
                ncn-m*)
                    efibootmgr | grep -iP '(pxe ipv?(4|6).*adapter)' | tee /tmp/bbs1
                    efibootmgr | grep cray | tee /tmp/bbs2
                    efibootmgr | grep 'UEFI OS' | tee /tmp/bbs3
                    ;;
                ncn-s*)
                    efibootmgr | grep -iP '(pxe ipv?(4|6).*adapter)' | tee /tmp/bbs1
                    efibootmgr | grep cray | tee /tmp/bbs2
                    efibootmgr | grep 'UEFI OS' | tee /tmp/bbs3
                    ;;
                ncn-w*)
                    efibootmgr | grep -iP '(pxe ipv?(4|6).*adapter)' | tee /tmp/bbs1
                    efibootmgr | grep cray | tee /tmp/bbs2
                    efibootmgr | grep 'UEFI OS' | tee /tmp/bbs3
                    ;;
                *)
                    efi_fail_host
                    ;;
            esac
            ;;
        *Marvell*|HP|HPE)
            # Removal file(s) ...
            efibootmgr | grep -vi 'pxe ipv4' | grep -i adapter |tee /tmp/rbbs1
            efibootmgr | grep -iP '(sata|nvme)' | tee /tmp/rbbs2
            efibootmgr_prefix='0000,'
            efi_trim
            efi_specials
            efi_remove
            case $hostname in
                ncn-m*)
                    efibootmgr | grep -i 'port 1' | grep -i 'pxe ipv4' | tee /tmp/bbs1
                    efibootmgr | grep cray | tee /tmp/bbs2
                    ;;
                ncn-s*)
                    efibootmgr | grep -i 'port 1' | grep -i 'pxe ipv4' | tee /tmp/bbs1
                    efibootmgr | grep cray | tee /tmp/bbs2
                    ;;
                ncn-w*)
                    efibootmgr | grep -i 'port 1' | grep -i 'pxe ipv4' | tee /tmp/bbs1
                    efibootmgr | grep cray | tee /tmp/bbs2
                    ;;
                *)
                    efi_fail_host
                    ;;
            esac
            ;;
        *'Intel'*'Corporation'*)
            # Removal file(s) ...
            efibootmgr | grep -vi 'ipv4' | grep -iP '(sata|nvme|uefi)' | tee /tmp/rbbs1
            efibootmgr | grep -i baseboard | tee /tmp/rbbs2
            efibootmgr_prefix=''
            efi_trim
            efi_specials
            efi_remove
            case $hostname in
                ncn-m*)
                    efibootmgr | grep -i 'ipv4' | grep -iv 'baseboard' | tee /tmp/bbs1
                    efibootmgr | grep -i 'cray' | tee /tmp/bbs2
                    ;;
                ncn-s*)
                    efibootmgr | grep -i 'ipv4' | grep -iv 'baseboard' | tee /tmp/bbs1
                    efibootmgr | grep -i 'cray' | tee /tmp/bbs2
                    ;;
                ncn-w*)
                    efibootmgr | grep -i 'ipv4' | grep -iv 'baseboard' | tee /tmp/bbs1
                    efibootmgr | grep -i 'cray' | tee /tmp/bbs2
                    ;;
                *)
                    echo >&2 $0 Unsupported node name $hostname
                    return 1
                    ;;
            esac
            ;;
        *)
            echo >&2 not modifying unknown vendor: $vendor
            return 1
            ;;
    esac

    [ "$no_enforce" = 0 ] && efi_enforce

    mprint "log file located at $0.log"
}

function paginate() {
    local url="$1"
    local token
    { token="$(curl -sSk "$url" | tee /dev/fd/3 | jq -r '.continuationToken // null')"; } 3>&1
    until [[ "$token" == "null" ]]; do
        {
            token="$(curl -sSk "$url&continuationToken=${token}" | tee /dev/fd/3 | jq -r '.continuationToken // null')";
        } 3>&1
    done
}

function install_csm_rpms() {

    # Verify nexus is available.  It's expected to *not* be available during initial install of the NCNs.
    if ! curl -sSf https://packages.local/service/rest/v1/components?repository=csm-sle-15sp3 >& /dev/null; then
        echo "unable to contact nexus, bailing"
        return 0
    fi

    # Retreive the packages from nexus
    goss_servers_url=$(paginate "https://packages.local/service/rest/v1/components?repository=csm-sle-15sp2" \
        | jq -r  '.items[] | .assets[] | .downloadUrl' | grep goss-servers | sort -V | tail -1)
    csm_testing_url=$(paginate "https://packages.local/service/rest/v1/components?repository=csm-sle-15sp2" \
        | jq -r  '.items[] | .assets[] | .downloadUrl' | grep csm-testing | sort -V | tail -1)
    platform_utils_url=$(paginate "https://packages.local/service/rest/v1/components?repository=csm-sle-15sp2" \
        | jq -r  '.items[] | .assets[] | .downloadUrl' | grep platform-utils | sort -V | tail -1)
    zypper install -y $goss_servers_url $csm_testing_url $platform_utils_url && systemctl enable goss-servers && systemctl restart goss-servers
}
