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
  echo "Removes FAS actions > # of days ago"
  echo "Usage: $0 num_of_days [-y]"
  echo "Optional parameter -y skips confirmation prompt"
  exit 1
}

if [ $# -lt 1 ]
then
  usage
fi

re='^[0-9]+$'
if ! [[ $1 =~ $re ]]
then
  echo "$1 not a number"
  usage
fi

yes=0
if [ $# -gt 1 ]
then
  if [ $2 == "-y" ]
  then
    yes=1
  else
    usage
  fi
fi

date=`date +%Y-%m-%d -d "$1 days ago"`

echo Removing FAS Actions before $date

actionIDs=`cray fas actions list --format json | jq -r '.actions | .[] | select(.endTime < '\"$date\"') | .actionID'`
if [ ${#actionIDs} -eq 0 ]
then
  echo "No actions found before date $date"
  exit 0
fi

echo $actionIDs

if [ $yes -ne 1 ]
then
  echo "-----------------------"
  echo "Removing these actions:"

  count=0
  for actionid in $actionIDs
  do
    ((count++))
    cray fas actions status list $actionid --format json | jq -r '. | "\(.actionID),\(.endTime),\(.command.description),\(.operationCounts.total)"'
  done

  echo "-----------------------"
  read -p "Continue to remove $count FAS actions? " -n 1 -r
  echo    # (optional) move to a new line
  if ! [[ $REPLY =~ ^[Yy]$ ]]
  then
    echo "Action aborted"
    exit 0
  fi
fi

for actionid in $actionIDs
do
  echo "Removing: $actionid"
  cray fas actions delete $actionid --format json
done
exit 0