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
# This script imports BOS session templates from a JSON list file and
# recreates them.
#
# For backwards compatability reasons, it also supports being passed a TGZ
# file containing individual session templates.
#
# Most of the work is done by a Python script. This shell script mostly just
# handles the TGZ case, if needed.
################################################################################
err_exit()
{
    echo "ERROR: $*" >&2
    exit 1
}

usage()
{
    echo "Usage: $0 [--ims-id-map-file <IMS ID JSON map file>] <JSON or TGZ file containing BOS session templates>"
    exit 1
}

IMS_ID_MAP_FILE=""
if [[ $# -eq 1 ]]; then
    ARCHIVE=$1
elif [[ $# -eq 3 && $1 == --ims-id-map-file ]]; then
    IMS_ID_MAP_FILE=$2
    ARCHIVE=$3
else
    usage
fi

basedir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
import_python_script="${basedir}/import_bos_sessiontemplates.py"
[[ -f ${import_python_script} ]] ||
    err_exit "File does not exist or is not a regular file: '${import_python_script}'"
[[ -f ${ARCHIVE} ]] ||
    err_exit "File does not exist or is not a regular file: '${ARCHIVE}'"
[[ -z ${IMS_ID_MAP_FILE} || -f ${IMS_ID_MAP_FILE} ]] ||
    err_exit "File does not exist or is not a regular file: '${IMS_ID_MAP_FILE}'"

if [[ ${ARCHIVE} =~ .*\.tgz$ ]]; then
    # Archive files generated by earlier versions of the BOS export script created
    # tgz archives with one JSON file for each BOS session template.
    # In this case, expand the archive, and then create a single JSON file containing
    # the contents of the others, as a list.

    # Unpack the archive in temporary directory
    TMPDIR=`mktemp -d` || err_exit "Command failed: mktemp -d"
    echo "Unpacking '${ARCHIVE}' to temporary directory '${TMPDIR}'"
    tar xvfz "${ARCHIVE}" --directory "${TMPDIR}" || err_exit "Command failed: tar xvfz ${ARCHIVE} --directory ${TMPDIR}"

    if [[ -z ${IMS_ID_MAP_FILE} ]]; then
        echo "Running: ${import_python_script} '${TMPDIR}'"
        "${import_python_script}" "${TMPDIR}" || err_exit "Command failed: ${import_python_script} '${TMPDIR}'"
    else
        echo "Running: ${import_python_script} --ims-id-map-file '${IMS_ID_MAP_FILE}' '${TMPDIR}'"
        "${import_python_script}" --ims-id-map-file "${IMS_ID_MAP_FILE}" "${TMPDIR}" ||
            err_exit "Command failed: ${import_python_script} --ims-id-map-file '${IMS_ID_MAP_FILE}' '${TMPDIR}'"
    fi

    # Clean up
    rm -rf "${TMPDIR}"
    exit 0
elif [[ ${ARCHIVE} =~ .*\.json$ ]]; then
    if [[ -z ${IMS_ID_MAP_FILE} ]]; then
        echo "Running: ${import_python_script} '${ARCHIVE}'"
        "${import_python_script}" "${ARCHIVE}" || err_exit "Command failed: ${import_python_script} '${ARCHIVE}'"
    else
        echo "Running: ${import_python_script} --ims-id-map-file '${IMS_ID_MAP_FILE}' '${ARCHIVE}'"
        "${import_python_script}" --ims-id-map-file "${IMS_ID_MAP_FILE}" "${ARCHIVE}" ||
            err_exit "Command failed: ${import_python_script} --ims-id-map-file '${IMS_ID_MAP_FILE}' '${ARCHIVE}'"
    fi
    exit 0
fi

err_exit "Final argument must be a .tgz or .json file. Invalid argument: '${ARCHIVE}'"
