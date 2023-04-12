#!/usr/bin/bash
#
# MIT License
#
# (C) Copyright 2023 Hewlett Packard Enterprise Development LP
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
# This script exports all CFS data into JSON files. These files are then
# compressed into an tgz archive.
################################################################################

ARCHIVE_PREFIX="cfs-export-$(date +%Y%m%d%H%M%S)"

err_exit()
{
    echo "ERROR: $*" >&2
    exit 1
}

run_cmd()
{
    "$@" || err_exit "Command failed with return code $?: $*"
}

ARCHIVE_DIR=$(run_cmd mktemp -p /tmp -d "${ARCHIVE_PREFIX}-XXX")

# Export the CFS components, configurations, options, and sessions
# The session data is not likely to be something that would be restored from a backup,
# but retaining the historical data may be useful in some situations.
for OBJECT in components configurations options sessions ; do
    echo "Exporting CFS ${OBJECT}..."
    run_cmd cray cfs "${OBJECT}" list --format json > "${ARCHIVE_DIR}/${OBJECT}.json"
done

# Compress the results
echo "Creating compressed archive of exported data..."
ARCHIVE_FILE=$(run_cmd mktemp "${ARCHIVE_DIR}XXX.tgz")
ARCHIVE_DIR_BASENAME=$(run_cmd basename "${ARCHIVE_DIR}")
run_cmd tar --remove-files -C /tmp -czf "${ARCHIVE_FILE}" "${ARCHIVE_DIR_BASENAME}"
echo "SUCCESS: CFS data stored in file: ${ARCHIVE_FILE}"
