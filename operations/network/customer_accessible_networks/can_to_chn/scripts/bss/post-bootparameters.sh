#!/usr/bin/env bash

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
