#! /usr/bin/env python3
#
# MIT License
#
# (C) Copyright 2022-2023 Hewlett Packard Enterprise Development LP
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

import subprocess
import json
import rbd
import rados
import sys
from argparse import ArgumentParser
from prettytable import PrettyTable
from packaging import version
import time
import os

"""
Start report block.
Basic report of the cluster for upgrade purposes.
Requires minimum podman version 3.4.4
"""

def print_function(print_data, service):
  print(print_data)


def fetch_status(service, cmd):
  try:
    cmd_results = cluster.mon_command(json.dumps(cmd), b'', timeout=5)
  except:
    print('something went wrong')

  refined_results = json.loads(cmd_results[1])
  table = PrettyTable(['Host', 'Daemon Type', 'ID', 'Version', 'Status', 'Image Name'])
  table.title = service
  for s in range(len(refined_results)):
      host = (refined_results[s]["hostname"])
      type = (refined_results[s]["daemon_type"])
      id = (refined_results[s]["daemon_id"])
      status = (refined_results[s]["status_desc"])
      image_name = (refined_results[s]["container_image_name"])
      if status == "running":
        vers = (refined_results[s]["version"])
      else:
        vers = "unknown"
      table.add_row([host, type, id, vers, status, image_name])
  print_function(table, service)

"""
End report block.
"""

"""
Start upgrade check and execute block.
All functions related to checking for valid upgrade options or initiating an
upgrade should live below.
"""

def fetch_base_current_vers():
    cmd = {"prefix":"version", "format":"json"}
    cmd_results = cluster.mon_command(json.dumps(cmd), b'', timeout=5)
    results = json.loads(cmd_results[1])
    for key,value in results.items():
      current_version = str(value.split(' ')[2])
    return current_version

def fetch_curr_sha(cmd, new_version):
    cmd_results = cluster.mon_command(json.dumps(cmd), b'', timeout=5)
    results = json.loads(cmd_results[1])
    for s in range(len(results)):
        current_sha = (results[s]["container_image_id"])
    return current_sha

def fetch_new_sha(registry, pretty_version):
    if registry == "localhost":
        remote_registry = "%s:5000" % registry
    else:
        remote_registry = registry
    new_sha = json.loads(subprocess.check_output(["podman", "inspect", remote_registry + "/ceph/ceph:" + pretty_version, "--format=json"]))[0]['Id']
    return new_sha

def image_check(registry, new_vers):
    if registry == "localhost":
        remote_registry = "%s:5000" % registry
    else:
        remote_registry = registry
    image_exists = subprocess.run(["podman", "image", "exists", remote_registry + "/ceph/ceph:" + new_vers], stdout=subprocess.PIPE)
    image_present = image_exists.returncode
    if image_present != 0:
        try:
            subprocess.run(["podman", "pull", remote_registry + "/ceph/ceph:" + new_vers])
            image_present = subprocess.run(["podman", "image", "exists", remote_registry + "/ceph/ceph:" + new_vers], check=True)
        except:
            print("The image cannot be pulled from the registry.  Please ensure you have the right image path and version.")
            exit(2)
    return image_present

def fetch_per_service_count(service, cmd, new_version, current_version):
    new_counter=0
    curr_counter=0
    cmd_results = cluster.mon_command(json.dumps(cmd), b'', timeout=5)
    results = json.loads(cmd_results[1])
    for s in range(len(results)):
      status = (results[s]["status_desc"])
      if status == "running":
        type = (results[s]["daemon_type"])
        vers = (results[s]["version"])
        if vers == new_version:
          new_counter+=1
        elif vers == current_version:
          curr_counter+=1
    globals()[f"{service}_curr_count"] = curr_counter
    globals()[f"{service}_new_count"] = new_counter

def fetch_per_service_sha_count(service, cmd, curr_sha, new_sha):
    new_sha_counter=0
    curr_sha_counter=0
    cmd_results = cluster.mon_command(json.dumps(cmd), b'', timeout=5)
    results = json.loads(cmd_results[1])
    for s in range(len(results)):
      status = (results[s]["status_desc"])
      if status == "running":
        type = (results[s]["daemon_type"])
        sha = (results[s]["container_image_id"])
        if sha == curr_sha:
          curr_sha_counter+=1
        elif sha == new_sha:
          new_sha_counter+=1
    globals()[f"{service}_sha_curr_count"] = curr_sha_counter
    globals()[f"{service}_sha_new_count"] = new_sha_counter

def fetch_service_count_total(service,cmd, new_version):
    counter=0
    total_count=0
    cmd_results = cluster.mon_command(json.dumps(cmd), b'', timeout=5)
    results = json.loads(cmd_results[1])
    for s in range(len(results)):
      status = (results[s]["status_desc"])
      if status == "running":
        type = (results[s]["daemon_type"])
        vers = (results[s]["version"])
        if vers != new_version:
          counter+=1
      else:
        vers = "unknown"
    total_count += counter
    return total_count

def upgrade_check(new_vers, registry, current_version, quiet, in_family_override, image_status):
    if registry == "localhost":
        remote_registry = "%s:5000" % registry
    else:
        remote_registry = registry
    #image_exists = subprocess.run(["podman", "image", "exists", remote_registry + "/ceph/ceph:" + new_vers], stdout=subprocess.PIPE)
    #image_present = image_exists.returncode
    if image_status != 0:
        try:
            subprocess.run(["podman", "pull", remote_registry + "/ceph/ceph:" + new_vers])
            image_present = subprocess.run(["podman", "image", "exists", remote_registry + "/ceph/ceph:" + new_vers], check=True)
        except:
            print("The image cannot be pulled from the registry.  Please ensure you have the right image path and version.")
            exit(2)
    registry_vers = json.loads(subprocess.check_output(["podman", "search", remote_registry + "/ceph/ceph", "--list-tags", "--format=json"]))[0]['Tags']
    upgrade_available = False
    if not in_family_override:
        if version.parse(new_vers) == version.parse(current_version):
            if not quiet:
                print("Your current version is the same as the proposed version %s" % current_version)
        elif new_vers in registry_vers:
            upgrade_available = True
            if not quiet:
              print ("Upgrade Available!!  The specified version %s has been found in the registry" % (new_vers))
    elif in_family_override:
        if version.parse(new_vers) == version.parse(current_version):
            upgrade_available = True
            if not quiet:
                print ("Upgrade Available!!  The specified version %s has been found in the registry" % (new_vers))
        elif version.parse(new_vers) != version.parse(current_version):
            if not quiet:
                print ("ERROR: in_family_upgrade requires the same version of Ceph that is currently running")
    if not upgrade_available:
        if not quiet:
            print("ERROR: Upgrade not available or the version specifeid is not a valid version")
            print("Available versions are %s" % (registry_vers))
    return upgrade_available

def upgrade_execute(new_version,registry, upgrade_cmd, current_version, services, quiet, in_family_override, curr_sha, new_sha):
    final_count = 0
    total = 0
    for service, cmd in services.items():
      total = fetch_service_count_total(service,cmd, new_version)
      final_count += total
    if not quiet:
      print ("Initiating Ceph upgrade from v%s to v%s" % (current_version, new_version))
    cluster.mon_command(json.dumps(upgrade_cmd), b'', timeout=5)
    total_upgr = 0
    while total_upgr <= final_count:
      total_upgr = 0
      upgr_table = PrettyTable(['Service', 'Total Current', 'Total Upgraded'])
      upgr_table.title = "Upgrade Progress"
      time.sleep(5)
      if not quiet:
        os.system('clear')
      for service, cmd in services.items():
        fetch_per_service_sha_count(service, cmd, curr_sha, new_sha)
        fetch_per_service_count(service, cmd, new_version, current_version)
        old_vers_count = ("%s_curr_count" % (service))
        new_vers_count = ("%s_new_count" % (service))
        old_sha_vers_count = ("%s_sha_curr_count" % (service))
        new_sha_vers_count = ("%s_sha_new_count" % (service))
        if in_family_override:
            service_upgr =  in_family_upgrade_watch(service, cmd, curr_sha, new_sha, total_upgr, old_sha_vers_count, new_sha_vers_count, final_count)
            if total_upgr == final_count:
                total_upgr += 1
            else:
                total_upgr += service_upgr
            old_sha_count = int(globals()[old_sha_vers_count])
            new_sha_count = service_upgr
            upgr_table.add_row([service, old_sha_count, new_sha_count])
        else:
            total_upgr =  watch_upgrade(service, cmd, new_version, current_version, total_upgr, old_vers_count, new_vers_count, final_count)
            old_count = int(globals()[old_vers_count])
            new_count = int(globals()[new_vers_count])
            upgr_table.add_row([service, old_count, new_count])
      if not quiet:
        print (upgr_table)
    upgrade_success=True
    return upgrade_success

def watch_upgrade(service, cmd, new_version, current_version, total_upgr, old_vers_count, new_vers_count, final_count):
    fetch_per_service_count(service, cmd, new_version, current_version)
    if total_upgr == 0:
      total_upgr = int(globals()[new_vers_count])
    elif total_upgr > 0:
      total_upgr += int(globals()[new_vers_count])
    if total_upgr == final_count:
      total_upgr += 1
    return total_upgr

def in_family_upgrade_watch(service, cmd, curr_sha, new_sha, total_img_upgr, old_sha_vers_count, new_sha_vers_count, final_count):
    if curr_sha != new_sha:
        fetch_per_service_sha_count(service, cmd, curr_sha, new_sha)
        if total_img_upgr == 0:
          total_img_upgr = int(globals()[f"{service}_sha_new_count"])
        elif total_img_upgr > 0:
          total_img_upgr += int(globals()[f"{service}_sha_new_count"])
        if total_img_upgr == final_count:
          total_img_upgr += 1
    else:
        total_img_upgr = globals()[f"{service}_sha_curr_count"]
    return total_img_upgr

"""
End upgrade check and execute block
"""

"""
Start Cluster Communications block
This section is for connecting and disconnecting to the cluster.
All functions or checks related to connecting/disconnecting to the cluster should live below.
"""

def init_connect():
    global cluster
    try:
      cluster = rados.Rados(conffile='/etc/ceph/ceph.conf')
    except rados.ObjectNotFound:
      print('ceph.conf not found in /etc/ceph')
      exit(1)
    try:
      cluster.connect(1)
    except rados.InvalidArgumentError:
      exit(2)

def disconnect():
    cluster.shutdown()

"""
End Cluster Communications block
"""

def main():
    parser =  ArgumentParser(description='Ceph upgrade script')
    parser.add_argument('--report',
                        required=False,
                        dest='report',
                        action='store_true',
                        help='Provides a report of the state and versions of ceph')
    parser.add_argument('--version',
                        required=False,
                        type=str,
                        dest='version',
                        help='The target version to upgrade to or to check against.  Format example v15.2.15')
    parser.add_argument('--registry',
                        required=False,
                        type=str,
                        #default='registry.local:5000',
                        dest='registry',
                        help='The registry where ceph container images are stored')
    parser.add_argument('--upgrade',
                        required=False,
                        dest='upgrade',
                        action='store_true',
                        help='Upgrade toggle.  Defaults to False')
    parser.add_argument('--in_family_override',
                        required=False,
                        dest='in_family_override',
                        action='store_true',
                        help='Flag to allow for "in family" upgrades and testing.')
    parser.add_argument('--quiet',
                         required=False,
                         dest='quiet',
                         action='store_true',
                         help='Toggle to enable/disable visual output')

    args = parser.parse_args()

    ## Provide 2 version strings to accommodate better output checking

    if args.version is not None:
      if args.version.startswith('v'):
        new_version = str(args.version.split('v',2)[1])
        pretty_version = args.version
      elif not args.version.startswith('v'):
        new_version = args.version
        pretty_version = 'v'+ args.version

    ## Set cmds ##

    mon = {"prefix":"orch ps", "daemon_type":"mon", "format":"json"}
    mgr = {"prefix":"orch ps", "daemon_type":"mgr", "format":"json"}
    osd = {"prefix":"orch ps", "daemon_type":"osd", "format":"json"}
    mds = {"prefix":"orch ps", "daemon_type":"mds", "format":"json"}
    rgw = {"prefix":"orch ps", "daemon_type":"rgw", "format":"json"}
    crash = {"prefix":"orch ps", "daemon_type":"crash", "format":"json"}

    ## Build dictionary ##

    """
    The order of the services is following the default upgrade order when using
    the ceph orchestrator.  Please do not change this.
    """

    services = {"MGR":mgr, "MON":mon, "Crash":crash, "OSD":osd, "MDS":mds, "RGW":rgw}

    """
    Check image status first
    """

    if args.report:
        init_connect()
        for service, cmd in services.items():
            fetch_status(service,cmd)
        disconnect()


    if (args.version is not None and (args.registry is not None and args.upgrade is False)):
        init_connect()
        image_status = image_check(args.registry, pretty_version)
        current_version = fetch_base_current_vers()
        upgrade_check_success = upgrade_check(pretty_version, args.registry, current_version, args.quiet, args.in_family_override, image_status)
        disconnect()
        if upgrade_check_success:
            exit(0)
        else:
            exit(1)

    elif (args.registry is not None and (args.version is not None or args.upgrade is True)):
        init_connect()
        image_status = image_check(args.registry, pretty_version)
        curr_sha = fetch_curr_sha(mon, new_version)
        new_sha = fetch_new_sha(args.registry, pretty_version)
        current_version = fetch_base_current_vers()
        upgrade_cmd = {"prefix":"orch upgrade start", "image":args.registry+"/ceph/ceph:"+ pretty_version}
        upgrade_proceed = upgrade_check(pretty_version, args.registry, current_version, args.quiet, args.in_family_override, image_status)
        if upgrade_proceed:
          upgrade_success = upgrade_execute(new_version, args.registry, upgrade_cmd, current_version, services, args.quiet, args.in_family_override, curr_sha, new_sha)
          disconnect()
          if upgrade_success:
            exit(0)
          else:
            exit(1)
        else:
          disconnect()
          exit(2)

    elif (args.version is not None and args.registry is None):
        print ("The --version option requires --registry option")
        exit(2)

    elif (args.registry is not None and (args.version is None or args.upgrade is True)):
        print ("The registry flag requires --version and/or --upgrade to be set")
        exit(2)

    elif (args.upgrade and (args.version is None or args.registry is None)):
        print ("Upgrade requires both --registry and --version to be set")
        exit(2)

if __name__ == '__main__':
    main()
