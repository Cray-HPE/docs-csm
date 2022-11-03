#! /usr/bin/env python3
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
virt_file = "/opt/cray/csm/scripts/csm_rbd_tool/bin/activate_this.py"
exec(compile(open(virt_file, "rb").read(), virt_file, 'exec'), dict(__file__=virt_file))

import subprocess
import socket
import json
import rbd
import rados
import sys
from argparse import ArgumentParser
import time
import os
import platform
from fabric import *
import paramiko
from psutil import disk_partitions
import shutil



"""
 Checks section
"""

def check_pool_rm_flag():
    init_connect()
    cmd = {"prefix":"config get", "who":"mon", "key":"mon_allow_pool_delete", "format":"json"}
    flags = cluster.mon_command(json.dumps(cmd), b'')
    flag = json.loads(flags[1])
    disconnect()
    return flag;

def rbd_exists(pool, rbd_name):
    if pool_status(pool):
        map_json = subprocess.getoutput("rbd ls -p %s --format json" % pool)
        map = json.loads(map_json)
        if rbd_name in map:
            return True;
        else:
            return False;

    elif not pool_status(pool):
        print('Pool %s does not exist' % pool)

def is_watched(pool, rbd_name):
    if rbd_exists(pool, rbd_name):
        map_json = subprocess.getoutput("rbd -p %s status %s --format json" % (pool, rbd_name))
        try:
           mapped = json.loads(map_json)
        except:
             print('is watched error')
        if mapped['watchers']:
            if len(mapped['watchers']) > 0:
                watcher_ip = mapped['watchers'][0]['address'].split(":")[:1]
                watcher_name = socket.gethostbyaddr(watcher_ip[0])
                return True, watcher_ip[0], watcher_name;
        else:
            watcher_ip = []
            watcher_name = 'None'
            return False, watcher_ip, watcher_name;

def is_mounted(local_host, mnt_path, watcher_name):
    if watcher_name == local_host:
        mount_status = os.path.ismount(mnt_path)
        return mount_status;
    else:
        try:
            mounted = Connection(watcher_name,
                connect_kwargs={"key_filename":"/root/.ssh/id_rsa"}).run('mountpoint -q %s' % mnt_path)
            if mounted:
                return True;
            else:
                return False;
        except:
            return False;

def local_hostname():
    hostname = platform.node()
    return hostname

def pool_status(pool):
    init_connect()
    pool_exist = cluster.pool_exists(pool)
    disconnect()
    return pool_exist

def dir_exists(local_host, mnt_path, manager):
    if local_host == manager:
        is_dir = os.path.isdir(mnt_path)
        if not is_dir:
            os.makedirs(mnt_path)
        else:
            return is_dir

    else:
        try:
            cmd_results = Connection(manager,
                connect_kwargs={"key_filename":"/root/.ssh/id_rsa"}).run('test -d %s' % mnt_path)
            is_dir = cmd_results.stdout
            if is_dir == '0':
                return is_dir

        except:
            mkdir_results = Connection(manager,
                 connect_kwargs={"key_filename":"/root/.ssh/id_rsa"}).run('mkdir -pv %s' % mnt_path)
            is_dir = mkdir_results.stdout
            if is_dir == '0':
                 return is_dir
                 
def fs_exists(local_host, device, watcher_name):
    if local_host == watcher_name:
        results = subprocess.getoutput("file -s %s" % device)
        if 'ext4' in results:
            return True;
        else:
            return False;
    else:
        try:
            results = Connection(watcher_name,
                   connect_kwargs={"key_filename":"/root/.ssh/id_rsa"}).run('file -s %s' % device)
            if 'ext4' in results:
                return True;
        except:
            return False;

def rbd_path(local_host, watcher_name):
    if local_host == watcher_name:
        devices = []
        map_json = subprocess.getoutput("rbd showmapped --format json")
        map = json.loads(map_json)
        for item in map:
            devices.append(item['device'])
        return devices;
    else:
        devices = []
        try:
            map_json = Connection(watcher_name,
                   connect_kwargs={"key_filename":"/root/.ssh/id_rsa"}).run('rbd showmapped --format json')
            map = json.loads(map_json.stdout)
            for item in map:
                devices.append(item['device'])
            return devices;
        except:
            devices = ['N']
            return devices;

def is_mapped(pool, rbd_name):
    devices = []
    map_json = subprocess.getoutput("rbd showmapped --format json")
    map = json.loads(map_json)
    for item in map:
        devices.append(os.path.join(item['pool'], item['name']))
    return devices;

"""
Actions
"""

def toggle_pool_rm_flag(pool_action):
    current_flag = check_pool_rm_flag()
    init_connect()
    if current_flag and pool_action == 'post_delete':
        cmd = {"prefix":"config set", "who":"mon", "name":"mon_allow_pool_delete", "value":"false"}
        flags = cluster.mon_command(json.dumps(cmd), b'')
    elif not current_flag and pool_action == 'delete':
        cmd = {"prefix":"config set", "who":"mon", "name":"mon_allow_pool_delete", "value":"true"}
        flags = cluster.mon_command(json.dumps(cmd), b'')
    time.sleep(5)
    disconnect()

def pool_maint(pool_action, pool):
    # Create/Delete of the rbd pool. This includes quotas.
    p_stat = pool_status(pool)
    if pool_action == "create":
        if not p_stat:
            init_connect()
            cluster.create_pool(pool)
            p_stat = pool_status(pool)
            if p_stat:
                print('Pool csm_1.3 created')
            disconnect()
        if p_stat:
            init_connect()
            cmd = json.dumps({"prefix": "osd pool application enable", "pool": pool, "app": "rbd"})
            cluster.mon_command(cmd, b'', timeout=5)
            check_cmd = json.dumps({"prefix": "osd pool application get", "pool": pool, "format": "json"})
            check = cluster.mon_command(check_cmd, b'', timeout=5)
            results = json.loads(check[1])
            if "rbd" in results:
                print('Pool: %s has RBD set as the application' % pool)
            else:
                print('Whoops, something went wrong with setting the pool aplication, exiting now.')
                exit(1)
            quota_cmd = subprocess.getoutput("ceph osd pool set-quota %s max_bytes 2000G" % pool)
            time.sleep(5)
            check_quota_cmd = json.dumps({"prefix": "osd pool get-quota", "pool":pool, "format":"json"})
            check_quota = cluster.mon_command(check_quota_cmd, b'', timeout=5)
            quota_results = json.loads(check_quota[1])
            quota = quota_results['quota_max_bytes']
            disconnect()

    elif pool_action == "delete":
        if p_stat:
            toggle_pool_rm_flag(pool_action)
            init_connect()
            cluster.delete_pool(pool)
            disconnect()
            toggle_pool_rm_flag('post_delete')

def device_create(pool, rbd_name, mnt_path):
    # Create/Delete of the rbd device.
    path = os.path.join(pool, rbd_name)
    init_connect()
    ioctx = cluster.open_ioctx(pool)
    rbd_inst = rbd.RBD()
    # Size will be 1 TB
    size = 1000 * 1024**3
    rbd_inst.create(ioctx, rbd_name, size)
    ioctx.close()
    disconnect()
    #mount_maint('map', mnt_path, 'None')

def device_remove(pool, rbd_name):
    path = os.path.join(pool, rbd_name)
    init_connect()
    ioctx = cluster.open_ioctx(pool)
    rbd_inst = rbd.RBD()
    rbd_inst.remove(ioctx, rbd_name)
    ioctx.close()
    disconnect()

def device_map(local_host, pool, rbd_name, target_host):
    device = os.path.join(pool, rbd_name)
    if target_host == local_host:
        if device not in is_mapped(pool, rbd_name):
            results = subprocess.getoutput("rbd map %s" % device )
            return results;
    else: 
        results = Connection(target_host,
                     connect_kwargs={"key_filename":"/root/.ssh/id_rsa"}).run('rbd map -p %s %s' % (pool, rbd_name))
        return results.stdout;

def device_unmap(local_host, pool, rbd_name, watcher_name):
    device = os.path.join(pool, rbd_name)
    if watcher_name == local_host:
        map = subprocess.getoutput("rbd unmap %s" % device )
    else:
        results = Connection(watcher_name,
                     connect_kwargs={"key_filename":"/root/.ssh/id_rsa"}).run('rbd unmap %s' % device)

def device_mount(local_host, rbd_device, dev_path, mnt_path, watcher_name):
    if watcher_name == local_host:
        os.system("mount %s %s" % (dev_path, mnt_path))
    else:
        Connection(watcher_name,
                     connect_kwargs={"key_filename":"/root/.ssh/id_rsa"}).run("mount %s %s" % (dev_path, mnt_path))
    enable_node_auto_mount(local_host, watcher_name, mnt_path)

def device_unmount(local_host, mnt_path, watcher_name):
    if watcher_name == local_host:
        os.system("umount %s " % (mnt_path))
    else:
        Connection(watcher_name,
                         connect_kwargs={"key_filename":"/root/.ssh/id_rsa"}).run('umount %s' % mnt_path)
    disable_node_auto_mount(local_host, watcher_name, mnt_path)

def move_rbd(test, local_host, pool, rbd_name, mnt_path, target_host, watcher_name, managers):
    rbd_device = os.path.join(pool, rbd_name)
    if is_mounted(local_host, mnt_path, watcher_name):
        device_unmount(local_host, mnt_path, watcher_name)
        test, watcher_ip, watcher_name = is_watched(pool, rbd_name)
    if test and (watcher_name != 'N' or watcher_name != 'None'):
        device_unmap(local_host, pool, rbd_name, watcher_name)
    device = device_map(local_host, pool, rbd_name, target_host).strip('\n')
    test, watcher_ip, watcher_name = is_watched(pool, rbd_name)
    device_mount(local_host, rbd_device, device, mnt_path, watcher_name[0])

def mkfs(device, target_host, managers):
    local_host = local_hostname()
    if local_host == target_host:
        results = subprocess.call(["mkfs.ext4", device],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.STDOUT)
    elif target_host in managers:
        Connection(target_host,
            connect_kwargs={"key_filename":"/root/.ssh/id_rsa"}).run('mkfs.ext4 %s' % device)

def enable_node_auto_mount(local_host, watcher_name, mnt_path):
    rbdmap_line = "csm_admin_pool/csm_scratch_img id=admin,keyring=/etc/ceph/ceph.client.admin.keyring"
    fstab_line = "/dev/rbd/csm_admin_pool/csm_scratch_img %s ext4 defaults,noatime,_netdev 0" % mnt_path
    if local_host == watcher_name:
        shutil.copy2('/etc/ceph/rbdmap', '/tmp/tmp_rbdmap')
        shutil.copy2('/etc/fstab', '/tmp/tmp_fstab')
    else:
        with Connection(watcher_name,connect_kwargs={"key_filename":"/root/.ssh/id_rsa"}) as conn:
            conn.get('/etc/ceph/rbdmap', '/tmp/tmp_rbdmap')
            conn.get('/etc/fstab', '/tmp/tmp_fstab')
        time.sleep(5)

    with open('/tmp/tmp_rbdmap', 'r+') as file:
        if not "csm_scratch_img" in file.read():
            file.write('%s' % rbdmap_line)
            file.close()
    with open('/tmp/tmp_fstab', 'r+') as file:
        if not "csm_scratch_img" in file.read():
            file.write('%s' % fstab_line)
            file.close()

    if local_host == watcher_name:
        shutil.copy2('/tmp/tmp_rbdmap', '/etc/ceph/rbdmap')
        shutil.copy2('/tmp/tmp_fstab', '/etc/fstab')
        os.system('systemctl enable rbdmap.service >/dev/null 2>&1')
        os.system('systemctl start rbdmap.service >/dev/null 2>&1')

    else:
        with Connection(watcher_name,connect_kwargs={"key_filename":"/root/.ssh/id_rsa"}) as conn:
            conn.put('/tmp/tmp_rbdmap', '/etc/ceph/rbdmap')
            conn.put('/tmp/tmp_fstab', '/etc/fstab')
            conn.run('systemctl enable rbdmap.service', hide=True)
            conn.run('systemctl start rbdmap.service', hide=True)

    if os.path.isfile('/tmp/tmp_fstab'):
        os.remove('/tmp/tmp_fstab')
    if os.path.isfile('/tmp/tmp_rbdmap'):
        os.remove('/tmp/tmp_rbdmap')

def disable_node_auto_mount(local_host, watcher_name, mnt_path):
    if local_host == watcher_name:
        shutil.copy2('/etc/ceph/rbdmap', '/tmp/tmp_rbdmap')
        shutil.copy2('/etc/fstab', '/tmp/tmp_fstab')
    else:
        with Connection(watcher_name,connect_kwargs={"key_filename":"/root/.ssh/id_rsa"}) as conn:
           conn.get('/etc/ceph/rbdmap', '/tmp/tmp_rbdmap')
           conn.get('/etc/fstab', '/tmp/tmp_fstab')

        with open('/tmp/tmp_rbdmap', 'r+') as file:
            lines = file.readlines()
            for line in lines:
                if "csm_admin_pool/csm_scratch_img" in line:
                    file.seek(0)
                    file.truncate()
                    file.writelines(lines[:-1])
                    file.close()
        with open('/tmp/tmp_fstab', 'r+') as file:
            lines = file.readlines()
            for line in lines:
                if "csm_admin_pool/csm_scratch_img" in line:
                    file.seek(0)
                    file.truncate()
                    file.writelines(lines[:-1])
                    file.close()
    if local_host == watcher_name:
        shutil.copy2('/tmp/tmp_rbdmap', '/etc/ceph/rbdmap')
        shutil.copy2('/tmp/tmp_fstab', '/etc/fstab')
        os.system('systemctl stop rbdmap.service >/dev/null 2>&1')
        os.system('systemctl disable rbdmap.service >/dev/null 2>&1')
    else:
        with Connection(watcher_name,connect_kwargs={"key_filename":"/root/.ssh/id_rsa"}) as conn:
            conn.put('/tmp/tmp_rbdmap', '/etc/ceph/rbdmap')
            conn.put('/etc/fstab', '/tmp/tmp_fstab')
            conn.run('systemctl stop rbdmap.service', hide=True)
            conn.run('systemctl disable rbdmap.service', hide=True)

    
    if os.path.isfile('/tmp/tmp_fstab'):
        os.remove('/tmp/tmp_fstab')
    if os.path.isfile('/tmp/tmp_rbdmap'):
        os.remove('/tmp/tmp_rbdmap')



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


"""
Main
"""

def main():
    parser = ArgumentParser(description='A Helper tool to utilize an rbd device so additional upgrade space.')
    parser.add_argument('--status',
                        required=False,
                        dest='status',
                        default=False,
                        action="store_true",
                        help='Provides the status of an rbd device managed by this script')
    parser.add_argument('--rbd_action',
                        required=False,
                        dest='rbd_action',
                        default=False,
                        help='"create/delete/move" an rbd device to store and decompress the csm tarball')
    parser.add_argument('--pool_action',
                        required=False,
                        dest='pool_action',
                        help='Use with "--pool_action delete" to delete a predefined pool and rbd device used with the csm tarball')
    parser.add_argument('--target_host',
                        dest='target_host',
                        required=False,
                        default='',
                        help='Destination node to map the device to.  Must be a k8s master host')
    parser.add_argument('--csm_version',
                        required=False,
                        default='',
                        help='The CSM version being installed or upgraded to.  This is used for the mount point name. [Future place holder]')

    args = parser.parse_args()

    """
    Static & Pre-fetched variables
    """
    rbd_name = "csm_scratch_img"
    rbd_devices = [rbd_name]
    args = parser.parse_args()

    """
    Static & Pre-fetched variables
    """
    rbd_name = "csm_scratch_img"
    rbd_devices = [rbd_name]
    managers = ['ncn-m001', 'ncn-m002', 'ncn-m003']
    mnt_path = "/etc/cray/upgrade/csm"
    pool = "csm_admin_pool"
    dir = '/etc/cray/upgrade/csm'
    watcher_name = []
    rbd_device = os.path.join(pool, rbd_name)
    dev_exists = rbd_exists(pool, rbd_name)
    pool_exists = pool_status(pool)
    rbd_mapped = is_mapped(pool, rbd_name)
    device = ''
    local_host = local_hostname()

    for manager in managers:
        dir_exists(local_host, mnt_path, manager)


    if dev_exists:
        test, watcher_ip, watcher_name = is_watched(pool, rbd_name)
        mounted = is_mounted(local_host, mnt_path, watcher_name[0])
        if watcher_name[0] == local_hostname():
            device = rbd_path(local_host, watcher_name[0])
        else:
            target_host = watcher_name[0]
            device = rbd_path(local_host, watcher_name[0])

    if args.status:
        print('Pool %s exists: %s ' % (pool, pool_exists))
        print('RBD device exists %s ' % dev_exists)
        if dev_exists:
            if is_mounted(local_host, mnt_path, watcher_name[0]):
                print('RBD device mounted at - %s:%s' % (watcher_name[0], mnt_path))
        exit(0)

    if args.pool_action == 'delete' or args.rbd_action == "delete":
        if args.rbd_action == "delete" and dev_exists:
            watcher = watcher_name[0]
            if watcher == 'N':
                device_remove(pool, rbd_name)
            else:
                test, watcher_ip, watcher_name = is_watched(pool, rbd_name)
                if mounted:
                    device_unmount(local_host, mnt_path, watcher_name[0])
                    time.sleep(5)
                    test, watcher_ip, watcher_name = is_watched(pool, rbd_name)
                if test:
                    device_unmap(local_host, pool, rbd_name, watcher_name[0])
                    time.sleep(5)
                    test, watcher_ip, watcher_name = is_watched(pool, rbd_name)
                device_remove(pool, rbd_name)
                while dev_exists and not test:
                  time.sleep(5)
                  dev_exists = rbd_exists(pool, rbd_name)

        if args.pool_action == 'delete':
            target_host = 'None'
            if pool_status:
                if dev_exists:
                    device = rbd_path(local_host, watcher_name[0])
                    if rbd_mapped:
                        test, watcher_ip, watcher_name = is_watched(pool, rbd_name)
                        watcher = watcher_name[0]
                    else:
                        watcher = 'None'
                    if watcher != 'None' and watcher in managers:
                        device_unmount(local_host, mnt_path, watcher_name[0])
                        time.sleep(5)
                        test, watcher_ip, watcher_name = is_watched(pool, rbd_name)
                        if test:
                            device_unmap(local_host, pool, rbd_name, watcher_name[0])
                    device_remove(pool, rbd_name)
                pool_maint(args.pool_action, pool)
            elif not pool_status:
                print('Pool %s does not exist.' % pool)
                exit(1)

    if args.pool_action == 'create' or args.rbd_action == "create":
        if not pool_exists:
            watcher_name = ['None']
            if not args.pool_action:
                pool_action = 'create'
            elif args.pool_action != 'create':
                print('Cannot create an rbd device unless the --pool_action is == create or undefined')
                exit(1)
            else:
                pool_action = args.pool_action
            pool_maint(pool_action, pool)
        if not dev_exists:
            device_create(pool, rbd_name, mnt_path)
            dev_exists = rbd_exists(pool, rbd_name)
        if dev_exists:
               dev_path = device_map(local_host, pool, rbd_name, args.target_host).strip('\n')
               test, watcher_ip, watcher_name = is_watched(pool, rbd_name)
               device = rbd_path(local_host, watcher_name[0])
               mkfs(device[0], args.target_host, managers)
               test, watcher_ip, watcher_name = is_watched(pool, rbd_name)
               device_mount(local_host, rbd_device, device[0], mnt_path, watcher_name[0])
               if is_mounted(local_host, mnt_path, watcher_name[0]):
                   print('RBD device mounted at - %s:%s' % (watcher_name[0], mnt_path))
            

    if args.rbd_action == "move":
        if dev_exists:
            if watcher_name[0] == 'N':
                watcher = 'None'
            else:
                watcher = watcher_name[0]
            if args.target_host != watcher_name[0] and args.target_host in managers:
                test, watcher_ip, watcher_name = is_watched(pool, rbd_name)
                move_rbd(test, local_host, pool, rbd_name, mnt_path, args.target_host, watcher_name[0], managers)
                test, watcher_ip, watcher_name = is_watched(pool, rbd_name)
                if is_mounted(local_host, mnt_path, watcher_name[0]):
                    print('RBD device mounted at - %s:%s' % (watcher_name[0], mnt_path))

if __name__ == '__main__':
    main()
