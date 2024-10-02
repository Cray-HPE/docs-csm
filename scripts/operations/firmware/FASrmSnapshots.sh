#!/bin/bash
#
# MIT License
#
# (C) Copyright [2024] Hewlett Packard Enterprise Development LP
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

usage() {
  echo "Removes FAS snapshots > # of days ago"
  echo "Usage: $0 num_of_days [-y]"
  echo "Optional parameter -y skips confirmation prompt"
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

re='^[0-9]+$'
if ! [[ $1 =~ $re ]]; then
  echo "$1 not a number"
  usage
fi

yes=0
if [ $# -gt 1 ]; then
  if [ $2 == "-y" ]; then
    yes=1
  else
    usage
  fi
fi

date=$(date +%Y-%m-%d -d "$1 days ago")

echo Removing FAS Snapshots before $date

ssIDs=$(cray fas snapshots list --format json | jq -r '.snapshots | .[] | select(.captureTime < '\"$date\"') | .name')
if [ ${#ssIDs} -eq 0 ]; then
  echo "No snapshots found before date $date"
  exit 0
fi

echo $ssIDs

if [ $yes -ne 1 ]; then
  echo "-------------------------"
  echo "Removing these snapshots:"

  count=0
  for ss in $ssIDs; do
    ((count++))
    cray fas snapshots describe $ss --format json | jq -r '. | "\(.name),\(.captureTime)"'
  done

  echo "-----------------------"
  read -p "Continue to remove $count FAS snapshots? " -n 1 -r
  echo    # (optional) move to a new line
  if  ! [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Action aborted"
    exit 0
  fi
fi

for ss in $ssIDs
do
  echo "Removing: $ss"
  cray fas snapshots delete $ss --format json
done
exit 0
