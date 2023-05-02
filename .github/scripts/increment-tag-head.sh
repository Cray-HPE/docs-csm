#!/usr/bin/env bash
#
# MIT License
#
# (C) Copyright 2023 Hewlett Packard Enterprise Development LP
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
set -euo pipefail

if [ $# -ge 1 ] && [ -n "$1" ]
then
      DOCS_CSM_BRANCH=$1
      echo "checking ${DOCS_CSM_BRANCH} branch in docs-csm repo to verify head is tagged"
else
      echo "ERROR: branch to verify in docs-csm repo not specified in arguments"
      exit 1
fi

#check if the docs-csm directory is present
if [ -d "docs-csm" ]
then
      #checkout out the requested branch of docs-csm
      cd docs-csm
      git checkout $DOCS_CSM_BRANCH
      HEAD_TAG=$(git tag --points-at HEAD)
      if [ -z "$HEAD_TAG" ]
      then
            echo "head of doc-csm ${DOCS_CSM_BRANCH} is not tagged, creating new tag"
            #read current tag, parse, increment current tag, create new tag, and push new tag
            CURRENT_TAG=$(git describe --tags)                                                                                                                            
            TOKENS=(${CURRENT_TAG//./ })                                                                                                                                  
            CURRENT_PATCH_TOKENS=(${TOKENS[2]//-/ })
            CURRENT_PATCH_VERSION=${CURRENT_PATCH_TOKENS[0]}
            NEW_PATCH_VERSION=$((CURRENT_PATCH_VERSION + 1))
            NEW_TAG=${tokens[0]}.${tokens[1]}.$NEW_PATCH_VERSION
            git tag $NEW_TAG
            git push origin $NEW_TAG
            echo "head of doc-csm ${DOCS_CSM_BRANCH} is now has new tag ${NEW_TAG}" 
      else
            echo "head of doc-csm ${DOCS_CSM_BRANCH} is already tagged as ${HEAD_TAG}" 
      fi
      cd ..
else
      echo "ERROR: docs-csm repo not checked out, unable to determine head tag"
      exit 1 
fi



