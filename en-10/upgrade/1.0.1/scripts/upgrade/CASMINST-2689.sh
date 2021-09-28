#!/usr/bin/env bash
#
# MIT License
#
# (C) Copyright 2021-2022 Hewlett Packard Enterprise Development LP
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

set -e
set -o pipefail

SCRIPT_DIR=$(dirname "$0")

if ! eval pdsh -b -S -w "$(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u | tr -t '\n' ',')" 'cat /etc/cray/xname' > /dev/null 2>&1; then
	echo "One or more NCN is not ready for this script. They must all be booted to an OS and accessible on the network"
fi

# Get all the xnames so we can query bss for their boot asset paths from a single node (usually the node this script is ran from)
XNAMES=$(pdsh -b -S -w "$(grep -oP 'ncn-\w\d+' /etc/hosts | sort -u |  tr -t '\n' ',')" 'cat /etc/cray/xname')

check_cray_init_status() {
	if eval cray bss bootparameters list; then
	  return 0
	else
		return 1
	fi
}

pit_check() {
	if [[ $HOSTNAME == *pit* ]]; then
		return 0
	else
		return 1
	fi
}

if eval pit_check; then
	echo "This workaround should be used post-livecd reboot."
	exit 1
fi

# Make an array of ncns-to-xnames
# shellcheck disable=SC2207
ncn_to_xname_dict=($(echo "${XNAMES// }"))

# We need the accurate info from BSS, which is called via a cray command so verify it is initialized before continuing
if ! eval check_cray_init_status >/dev/null 2>&1; then
	echo -n "\nPlease run 'cray init'"
	exit 1
else
	# for each ncn, we need the path to its assets in s3
	for i in "${ncn_to_xname_dict[@]}" ; do
		# the ncn is before the colon, the xname is after
		ncn="${i%%:*}"
		xname="${i##*:}"

		# Check the path listed in s3 based on this xname
		kernel_path=$(cray bss bootparameters list --hosts "${xname}" | awk -F '"' '/kernel = / {print $2}')
		initrd_path=$(cray bss bootparameters list --hosts "${xname}" | awk -F '"' '/initrd = / {print $2}')

		echo "==> $ncn..."
		# copy over the library
		ssh $ncn "mkdir -p $SCRIPT_DIR"
		scp $SCRIPT_DIR/CASMINST-2689-lib.sh $ncn:$SCRIPT_DIR
		# run the script, fix kernel and initrd
		ssh $ncn "chmod 755 $SCRIPT_DIR/CASMINST-2689-lib.sh"
		ssh $ncn "$SCRIPT_DIR/CASMINST-2689-lib.sh ${kernel_path}"
		ssh $ncn "$SCRIPT_DIR/CASMINST-2689-lib.sh ${initrd_path}"
	# end for i in ncn_to_xname_dict
	done
fi
