#!/bin/bash
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

locOfScript=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
# Inform ShellCheck about the file we are sourcing
# shellcheck source=./common.sh
. "${locOfScript}/common.sh"

# Shared function and variable definitions between VCS backup and restore scripts

# These variables are not used in this file, but are used by scripts which source this file
#shellcheck disable=SC2034
SQL_BACKUP_NAME=gitea-vcs-postgres.sql
#shellcheck disable=SC2034
SEC_BACKUP_NAME=gitea-vcs-postgres.manifest
#shellcheck disable=SC2034
PVC_BACKUP_NAME=vcs.tar

function get_gitea_pod {
  # Sets $gitea_pod to the name of the gitea pod, or exits if it cannot be found
  gitea_pod=$(run_cmd kubectl -n services get pod -l app.kubernetes.io/instance=gitea -o custom-columns=":metadata.name" --no-headers) || err_exit
  [[ -n ${gitea_pod} ]] || err_exit "No gitea pod found"
}
