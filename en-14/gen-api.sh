#!/usr/bin/env bash
#
# MIT License
#
# (C) Copyright 2024 Hewlett Packard Enterprise Development LP
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

set -e -o pipefail
function usage() {
  echo "Generate API docs from swagger file URLs provided in csm manifests."
  echo ""
  echo "Usage: $0 <manifest-dir> <dest-dir>"
  echo ""
  exit 1
}

function error() {
  echo "${1}"
  exit 1
}

if [ $# -ne 2 ]; then
  usage
fi

manifest_dir=$(realpath "${1}")
dest_dir=$(realpath "${2}")
tmp_dir=$(mktemp -d)
mkdir -p "${dest_dir}" "${tmp_dir}"

echo "Preparing yq container ..."
docker run -u "$(id -u):$(id -g)" --rm --name yq-swagger --entrypoint sh --detach -i -v "${manifest_dir}:/manifests" -v "${tmp_dir}:/swagger" artifactory.algol60.net/docker.io/mikefarah/yq:4 > /dev/null
yq="docker exec yq-swagger yq"

echo "Preparing widdershins container ..."
docker run --rm --name widdershins --entrypoint bash --detach -i -v "${tmp_dir}:/swagger" -v "${dest_dir}:/api" node:16 > /dev/null
docker exec widdershins npm install -g widdershins

trap 'echo "Cleaning up ..."; docker rm -f widdershins >/dev/null; docker rm -f yq-swagger >/dev/null; rm -Rf "${tmp_dir}"' EXIT

find "${manifest_dir}" -name "*.yaml" | while read -r manifest_file; do
  echo "Parsing ${manifest_file} ..."
  while read -r swagger_def; do
    IFS='|' read -r endpoint_name endpoint_url endpoint_version endpoint_title <<< "${swagger_def}"
    echo ""
    echo "Downloading from ${endpoint_url} ..."
    curl -SsL -o "${tmp_dir}/${endpoint_name}.yaml" "${endpoint_url}"
    openapi_version=$(${yq} e '.openapi // .swagger' "/swagger/${endpoint_name}.yaml")
    if [ -n "${endpoint_title}" ]; then
      ${yq} e -i ".info.title=\"${endpoint_title}\"" "/swagger/${endpoint_name}.yaml"
    fi
    if [ -n "${endpoint_version}" ]; then
      ${yq} e -i ".info.version=\"${endpoint_version}\"" "/swagger/${endpoint_name}.yaml"
    fi
    if [[ ${openapi_version} == 3.* ]]; then
      ${yq} e -i '.components.securitySchemes.bearerAuth={"type": "http", "scheme": "bearer"}' "/swagger/${endpoint_name}.yaml"
      ${yq} e -i '.security=[{"bearerAuth": []}]' "/swagger/${endpoint_name}.yaml"
      # Many services have both external (through API Gateway, requires auth) and internal (does not require auth) sample URLs.
      # Auth requirement can not be scoped to URL, we remove all sample URLs and set one mandatory external URL instead.
      base_url=$(${yq} e '.servers[] | select(.url == "*/apis/*") | .url | sub(".+/apis/", "/apis/")' "/swagger/${endpoint_name}.yaml" | sort -u | head -1)
      if [ -z "${base_url}" ]; then
        base_url="/apis/${endpoint_name}"
        echo "WARNING: unable to identify sample URL for ${endpoint_name}, guessed as ${base_url}."
      fi
      ${yq} e -i ".servers=[{\"url\": \"https://api-gw-service-nmn.local${base_url}\"}]" "/swagger/${endpoint_name}.yaml"
    elif [[ ${openapi_version} == 2.* ]]; then
      ${yq} e -i '.securityDefinitions.bearerAuth={"type": "http", "scheme": "bearer"}' "/swagger/${endpoint_name}.yaml"
      ${yq} e -i '.security=[{"bearerAuth": []}]' "/swagger/${endpoint_name}.yaml"
      ${yq} e -i '.host="api-gw-service-nmn.local"' "/swagger/${endpoint_name}.yaml"
      ${yq} e -i '.schemes=["https"]' "/swagger/${endpoint_name}.yaml"
    fi
    echo "Producing markdown for ${endpoint_name} out of ${endpoint_url} ..."
    docker exec widdershins widdershins "/swagger/${endpoint_name}.yaml" -o "/api/${endpoint_name}.md" --omitHeader --language_tabs http shell python go
  done < <(${yq} e '.spec.charts[].swagger[] | (.name + "|" + .url + "|" + (.version // "") + "|" + (.title // ""))' "/manifests/$(basename "${manifest_file}")")
done

cd "${dest_dir}"
echo "# REST API Documentation" > README.md
for file in *.md; do
  if [ "${file}" != README.md ] && [ "${file}" != index.md ]; then
    title=$(grep -E '<h1 id=".*">.*</h1>' "${file}" | head -1 | sed -e 's/<h1 id=".*">//' | sed -e 's|</h1>||') || true
    if [ -z "${title}" ]; then
      error "ERROR: Could not determine title for service named ${file%.md}"
    fi
    echo " * [${title}](./${file})" >> README.md
  fi
done
ln -sf ./README.md ./index.md
