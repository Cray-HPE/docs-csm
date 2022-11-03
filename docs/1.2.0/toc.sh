#!/bin/bash
#
# MIT License
#
# (C) Copyright 2021-2022 Hewlett Packard Enterprise Development LP
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

set -u
# dump table-of-contents to stdout
# usage:
#
# all pages
#
#   ./toc.sh
#
# pages 050-059)
#
#   ./toc.sh 05
#
# namespace patterns
#
#   ./toc.sh *-CSM-*
#
# product patterns
#
#   ./toc.sh *-NCN-*
# one file:
#
#   ./toc.sh README
#

pattern=${1%%.*}

# Normalize grep in case one has it usefully bound to some short-cut.
# (devs can reload their .bashrc/.profile/.bash_profile to fix this after).
unalias grep >/dev/null 2>&1

# match one or more; bail if zero, read the error.
for file in ${pattern}*.md; do

    # trim...
    fname="$file"
    fname="${fname#"${fname%%[![:space:]]*}"}"   # remove leading whitespace characters
    fname="${fname%"${fname##*[![:space:]]}"}"   # remove trailing whitespace characters
    printf "::%s\n" "$fname::"


    # the needful...
    cat $file |\
	grep "^#" |\
	sed 's|^[ ]*||g' |\
	awk  -F, '\
BEGIN {
}{
  basic_name=$1;
  anchor=basic_name
  basic_name_no_hash=basic_name
  gsub(/^[#]* /,"",basic_name_no_hash)
  gsub(/[ ]*$/,"",basic_name_no_hash)
  subs_string=basic_name
  subs = gsub(/#/,"",subs_string);
  gsub(/^[#]+ /,"",anchor);
  gsub(/ /,"-",anchor);
  anchor = tolower(anchor);
  {for (i=0;i<subs-1;i++) printf "    " }
  print "* [" basic_name_no_hash "]('$fname'#" anchor ") <a name=\"" anchor "\"></a>";
}
END {
}'
done
