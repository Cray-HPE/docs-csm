#!/bin/bash
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

set -exo pipefail

nexus-get-blob-usage(){
    NEXUS_USERNAME="$(kubectl -n nexus get secret nexus-admin-credential --template '{{.data.username}}' | base64 -d)";
    NEXUS_PASSWORD="$(kubectl -n nexus get secret nexus-admin-credential --template '{{.data.password}}' | base64 -d)";
    BASIC_AUTH=$(echo -ne "$NEXUS_USERNAME:$NEXUS_PASSWORD" | base64 --wrap 0)

    echo "Nexus blob usage by size in descending order."
    echo "Blob Size (Gb), Blob Name"
    echo ""
    curl -sk --header "Authorization: Basic $BASIC_AUTH" https://packages.local/service/rest/v1/blobstores | \
      jq -r '.[] | {"bsize":(.totalSizeInBytes/1024/1024/1024), "bname":.name} | join(", ")' | sort -g -r

    echo ""
    echo "Remaining free storage (Gb):"
    curl -sk --header "Authorization: Basic $BASIC_AUTH" https://packages.local/service/rest/v1/blobstores | \
      jq -r '.[0].availableSpaceInBytes/1024/1024/1024'
}

nexus-get-repo-usage(){
  script_dir=$(dirname "${BASH_SOURCE[0]}")
  if [ ! -f $script_dir/orient-console.jar ]; then
    echo "Getting orient-console.jar now"
    wget https://sonatype.zendesk.com/hc/article_attachments/4412115223955/orient-console.jar
  fi

  odata_dir=${ORIENT_DIR:-$script_dir/orient_$(date +%s)}
  if [ ! -d $odata_dir ]; then
    mkdir $odata_dir
  fi

  pod=$(kubectl get pods -n nexus --selector app=nexus    -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'    | grep -v nexus-init);

  echo "Getting the Nexus DB contents now. Writing to $odata_dir"
  kubectl -n nexus cp $pod:/opt/sonatype/sonatype-work/nexus3/db $odata_dir

  # Join the asset (all assets) table to the bucket (all repositories) table (implied join - where asset.bucket=bucket.rid).
  # Get the sum of all assets by bucket and print in descending order of size.
  echo "Running repository usage report now."
  echo "select bucket.repository_name as repository,eval('sum(size) / ( 1024 * 1024 * 1024.0 )') as gbytes from asset group by bucket.repository_name order by gbytes desc;" | java -XX:MaxDirectMemorySize=32768m -jar orient-console.jar $odata_dir/component

}

nexus-get-blob-usage
nexus-get-repo-usage