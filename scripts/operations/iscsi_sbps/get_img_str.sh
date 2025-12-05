#!/bin/bash

#  MIT License
#
#  (C) Copyright 2025 Hewlett Packard Enterprise Development LP
#
#  Permission is hereby granted, free of charge, to any person obtaining a
#  copy of this software and associated documentation files (the "Software"),
#  to deal in the Software without restriction, including without limitation
#  the rights to use, copy, modify, merge, publish, distribute, sublicense,
#  and/or sell copies of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included
#  in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
#  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
#  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#  OTHER DEALINGS IN THE SOFTWARE.

# Script to list image identifier strings of images that are going to deleted
# which are mostly identified as unused images. This script expects a file as
# an argument which has the list of rootfs/PE image object to be deleted. The
# output of this script will be list of image identfier strings used to identify
# corresponding iSCSI luns on the iSCSI iniator.

set -euo pipefail

# output file for this script
OUTPUT_FILE="img_str.txt"

true > "$OUTPUT_FILE"

#This script takes a file having list of images to be deleted as an argument
FILE="$1"

if [ -z "$FILE" ]; then
  echo "Usage: $0 <filename>"
  echo "Error: No file argument provided."
  exit 1
fi

if [ ! -f "$FILE" ]; then
  echo "Error: File not found"
  exit 1
fi

while IFS= read -r line; do

  echo "image: $line"

  img_str=$(targetcli ls | grep "lun" | grep $line | awk 'NF-=2' | awk '{print $NF}' | sed "s/\[fileio\///g")

  if [[ -n $img_str ]]; then
    echo "$img_str" >> "$OUTPUT_FILE"
  else
    echo "Warning: No match found for $line" >&2
  fi

done < "$FILE"
