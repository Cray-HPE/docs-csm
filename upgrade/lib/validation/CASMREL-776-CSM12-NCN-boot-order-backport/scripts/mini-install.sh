#!/bin/bash
# Author: Russell Bunch <doomslayer@hpe.com>
# Permalink to original script: https://github.com/Cray-HPE/node-image-build/blob/8ec558f712bd894792758058fbdabdb6c2addf38/boxes/ncn-common/files/scripts/metal/install.sh
trap "printf >&2 'Metal Install: [ % -20s ]' 'failed'" ERR TERM HUP INT
trap "echo 'See logfile at: /var/log/cloud-init-metal.log'" EXIT
set -e

# Echo that we're the original, but stripped down script.
echo "Running stripped CSM 1.2 install.sh script, $0"
# See the original "install.sh" here: https://raw.githubusercontent.com/Cray-HPE/node-image-build/develop/boxes/ncn-common/files/scripts/metal/install.sh?token=AB3JQE4CBRQKCKMZ5UAKHH3BL4264'

# Load the metal library.
printf 'Metal Install: [ % -20s ]\n' 'loading ...' && . /srv/cray/scripts/metal/metal-lib.sh && printf 'Metal Install: [ % -20s ]\n' 'loading done' && sleep 2

# 1. Run this first; disable bootstrap info to level the playing field for configuration.
breakaway() {
    # clean bootstrap/ephemeral TCP/IP information
    (
        set -x
        clean_bogies
        drop_metal_tcp_ip bond0
        write_default_route
    ) 2>/var/log/cloud-init-metal-breakaway.error
}

# 2. After detaching bootstrap, setup our bootloader..
bootloader() {
    (
        set -x
        local working_path=/metal/recovery
        update_auxiliary_fstab $working_path
        get_boot_artifacts $working_path
        install_grub2 $working_path
    ) 2>/var/log/cloud-init-metal-bootloader.error
}

# 3. Metal configuration for servers and networks.
hardware() {
    (
        set -x
        setup_uefi_bootorder
#         configure_lldp
#         set_static_fallback
#         enable_amsd
    ) 2>/var/log/cloud-init-metal-hardware.error
}

# 4. CSM Testing and dependencies
csm() {
    (
        set -x
        install_csm_rpms
    ) 2>/var/log/cloud-init-metal-csm.error
}

# MAIN
(
    # 1.
#     printf 'Metal Install: [ % -20s ]\n' 'running: breakaway' >&2
#     [ -n "$METAL_TIME" ] && time breakaway || breakaway

    # 2.
    printf 'Metal Install: [ % -20s ]\n' 'running: fallback' >&2
    [ -n "$METAL_TIME" ] && time bootloader || bootloader

    # 3.
    printf 'Metal Install: [ % -20s ]\n' 'running: hardware' >&2
    [ -n "$METAL_TIME" ] && time hardware || hardware

    # 4.
#     printf 'Metal Install: [ % -20s ]\n' 'running: CSM layer' >&2
#     [ -n "$METAL_TIME" ] && time csm || csm

) >/var/log/cloud-init-metal.log

printf 'Metal Install: [ % -20s ]\n' 'done and complete'
