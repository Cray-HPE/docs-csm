#! /bin/sh
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

################################################################################
# This script exports all existing BOS session templates.
# Specifically, it creates an archive file containing a JSON file for each
# session template. These files can be used to re-create the session templates.
#
# The name of the archive file is defined in the ARCHIVE variable.
################################################################################
ARCHIVE="bos-session-templates.tgz"

if [ -e ${ARCHIVE} ]; then
    echo "Error archive file '${ARCHIVE}' already exists!";
    exit 1;
fi

# Create a JSON file for each session template
TMPDIR=`mktemp -d` || exit 1;
for st in $(cray bos v2 sessiontemplates list --format json | jq .[].name|tr -d \"); do
    cray bos v2 sessiontemplates describe $st --format json > ${TMPDIR}/${st}.json;
done

# Store the JSON files in an archive
tar --create --file ${ARCHIVE} -v -z -C ${TMPDIR} . 1>/dev/null
echo "BOS session templates stored in archive: ${ARCHIVE}"

# Clean up
rm -rf $TMPDIR
