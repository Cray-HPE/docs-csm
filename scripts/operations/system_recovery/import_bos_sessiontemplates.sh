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
# This script imports BOS session templates from an archive and recreates them.
################################################################################
usage()
{
    echo "Usage: $0 <*.tgz file containing session template files>"
    exit 1
} 

#!/bin/sh
if [ $# -ne 1 ] ; then
    usage
else
    ARCHIVE=$1
fi

if [ ! -f "$ARCHIVE" ]; then
    echo "Error: archive file '${ARCHIVE}' does not exist!";
    exit 1;
fi

# Unpack the archive in temporary directory
TMPDIR=`mktemp -d` || exit 1;
tar xvfz ${ARCHIVE} --directory $TMPDIR

# Create a BOS session template for each file it contains.
# The 'name' attribute must be removed and the resulting file massaged.
find $TMPDIR -name '*.json' -print0 | while IFS= read -r -d '' st
do
    name=$(cat $st | jq -r '.name' )
    if [ ! -z "$name" ]; then
	cat $st | sed -z 's/,\n\s*"name": ".*"//' > ${st}.tmp
	cray bos v2 sessiontemplates create --file $st.tmp $name
    else
	echo "ERROR: Could not create a session template for ${st}."
	continue
    fi
done

# Clean up
rm -rf $TMPDIR
