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

if ! grep -q "plugins.*artifactory.algol60.net" /etc/containerd/config.toml; then
  echo "Adding artifactory.algol60.net to containerd config"
tee -a /etc/containerd/config.toml 1>/dev/null << END
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors."artifactory.algol60.net"]
        endpoint = ["http://pit.nmn:5000/v2/artifactory.algol60.net", "http://pit.nmn:5000","https://registry.local/v2/artifactory.algol60.net", "https://registry.local", "dummy://artifactory.algol60.net"]
END
  echo "Restarting containerd"
  systemctl restart containerd
else
  echo "artifactory.algol60.net already in config.toml -- no reconfig needed"
fi
