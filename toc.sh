#!/bin/bash
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

# Normalize grep incase one has it usefully bound to some short-cut.
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
