#! /bin/sh

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

if [[ ! -f $ARCHIVE ]]; then
    echo "Error: archive file '${ARCHIVE}' does not exist!";
    exit 1;
fi

# Unpack the archive in temporary directory
TMPDIR=`mktemp -d` || exit 1;
tar xvfz ${ARCHIVE} --directory $TMPDIR

# Create a BOS session template for each file it contains.
# The 'name' attribute must be removed and the resulting file massaged.
for st in $(find $TMPDIR -name "*.json"); do
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
