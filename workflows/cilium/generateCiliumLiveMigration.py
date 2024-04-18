#!/usr/bin/env python3
#
# MIT License
#
# (C) Copyright 2023-2024 Hewlett Packard Enterprise Development LP
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

import yaml
import datetime
import os

try:
  from kubernetes import client, config
  from kubernetes.client import ApiClient
except:
  client = None
  config = None

from jinja2 import Environment, FileSystemLoader


def get_node_list(client_output):
  temp_list=[]

  json_data=ApiClient().sanitize_for_serialization(client_output)
  if len(json_data["items"]) != 0:
      for node in json_data["items"]:
          temp_list.append(node["metadata"]["name"])
  return temp_list


if __name__ == "__main__":


  template_file = "cilium-live-migration.j2"
  render_file = "cilium-live-migration.yaml"

  # Get current time
  now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S") 
  config.load_kube_config()
  k8s_api = client.CoreV1Api()
  this_dir = os.path.dirname(os.path.realpath(__file__))

  response = k8s_api.list_node()
  node_list=get_node_list(response)
  print("Generating workflow for nodes ")
  print(node_list)
  print(this_dir)

  # Load templates file from templates folder
  env = Environment(loader = FileSystemLoader(this_dir),   trim_blocks=True, lstrip_blocks=True)
  template = env.get_template(template_file)
  file=open(this_dir + "/" + render_file, "w")
  file.write(template.render(target_ncns=node_list, now=now))
  file.close()
  print("Workflow rendered in " + this_dir + "/" + render_file) 
