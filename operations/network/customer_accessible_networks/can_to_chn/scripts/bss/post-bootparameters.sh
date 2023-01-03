#!/usr/bin/env bash
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
# ----------------------------------------
function usage {
    echo "Usage:"
    echo "    ${0} -h               print help"
    echo "    ${0} -u <url>         post url"
    echo "    ${0} -f <data_file>   data_file"
}

# ----------------------------------------
# main parse args
# ----------------------------------------
if [ $# -eq 0 ]; then
    usage
    exit 1
fi

while getopts ":hf:u:" opt; do
    case ${opt} in
        h )
            usage
            exit 0
            ;;
        f )
            data_file=$OPTARG
            ;;
        u )
            url=$OPTARG
            ;;
        \? )
            usage
            echo "Invalid option: $OPTARG" 1>&2
            exit 1
            ;;
        : )
            usage
            echo "Missing argument: -$OPTARG requires an argument" 1>&2
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

if [ ! -n "$data_file" ]; then
    usage
    echo "Missing arg -f boot_parameters_json_file"
    exit 1
fi

if [ ! -n "$url" ]; then
    usage
    echo "Missing arg -u url"
    exit 1
fi

# ----------------------------------------
# main
# ----------------------------------------

echo "url: $url, data_file: $data_file"

total=$(jq length $data_file)
echo "total: $total"

i=0
while [ $i -ne $total ]

do
    echo "cat $data_file | jq '.['$i']' | curl -s -X PUT $url --data-binary @-"
    cat $data_file | jq '.['$i']' | curl -s -k -H "Authorization: Bearer ${TOKEN}" --header "Content-Type: application/json" --request PUT $url --data-binary @-
    i=$(($i+1))
done
