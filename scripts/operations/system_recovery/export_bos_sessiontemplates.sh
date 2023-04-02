#!/usr/bin/bash
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

################################################################################
# This script exports all existing BOS session templates as a list in a JSON
# file. This file can be used to re-create the session templates.
################################################################################
ARCHIVE="bos-session-templates-$(date +%Y%m%d%H%M%S).json"

err_exit()
{
    echo "ERROR: $*" >&2
    exit 1
}

[[ ! -e ${ARCHIVE} ]] || err_exit "Archive file '${ARCHIVE}' already exists!"

# Write all of the session templates to the file
cray bos v2 sessiontemplates list --format json > "${ARCHIVE}" ||
    err_exit "Command failed: cray bos v2 sessiontemplates list --format json"
echo "BOS session templates stored in file: ${ARCHIVE}"
