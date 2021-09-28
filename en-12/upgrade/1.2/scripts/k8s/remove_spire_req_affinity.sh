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

function remove_spire_req_affinity() {
    deployment=$1
    shift
    namespace="${1:-spire}"

    if kubectl get deployment -n "${namespace}" "${deployment}" >/dev/null 2>&1; then
       kubectl patch deployment -n "${namespace}" "${deployment}" -p '{
           "spec": {
           "template": {
               "spec": {
                   "affinity": {
                       "podAntiAffinity": {
                           "requiredDuringSchedulingIgnoredDuringExecution": null
                       }
                   }
               }
           }
       }}'

       kubectl rollout status deployment -n "${namespace}" "${deployment}"
    fi
}

remove_spire_req_affinity spire-wjks

function remove_spireserver_req_affinity() {
    deployment=$1
    shift
    namespace="${1:-spire}"

    if kubectl get statefulset -n "${namespace}" "${deployment}" >/dev/null 2>&1; then
       kubectl patch statefulset -n "${namespace}" "${deployment}" -p '{
           "spec": {
           "template": {
               "spec": {
                   "affinity": {
                       "podAntiAffinity": {
                           "requiredDuringSchedulingIgnoredDuringExecution": null
                       }
                   }
               }
           }
       }}'

       kubectl rollout status statefulset -n "${namespace}" "${deployment}"
    fi
}

remove_spireserver_req_affinity spire-server
