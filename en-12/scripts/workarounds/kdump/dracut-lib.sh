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

# Dracut Arguments
export OMIT=( "btrfs" "cifs" "dmraid" "dmsquash-live-ntfs" "fcoe" "fcoe-uefi" "iscsi" "modsign" "multipath" "nbd" "nfs" "ntfs-3g" )
export OMIT_DRIVERS=( "ecb" "hmac" "md5" )
export ADD=( "mdraid" )
export FORCE_ADD=( "dmsquash-live" "livenet" "mdraid" )
export INSTALL=( "less" "rmdir" "sgdisk" "vgremove" "wipefs" )

# Kernel Version
# This won't work well if multiple kernels are installed, because this'll return the highest installed, which might not what's actually running.
version_full=$(rpm -q --queryformat "%{VERSION}-%{RELEASE}.%{ARCH}\n" kernel-default)
version_base=${version_full%%-*}
version_suse=${version_full##*-}
version_suse=${version_suse%.*.*}
export KVER="${version_base}-${version_suse}-default"
