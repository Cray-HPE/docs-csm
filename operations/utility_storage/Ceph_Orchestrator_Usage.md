# Ceph Orchestrator General Usage and Tips

## Description

"Is a module that provides a command line interface (CLI) to orchestrator modules (ceph-mgr modules which interface with external orchestration services)." - source (https://docs.ceph.com/en/latest/mgr/orchestrator/)

This provides a nice centralized interface for the management of the ceph cluster.  This includes:

1. Single command upgrades, assuming all images are in place.
2. Reduces the need to be on the physical server to address a large number of ceph service restarts or configuration changes
3. Better integration with the Ceph Dashboard (Coming soon)
4. Ability to write custom orchestration modules

## Troubleshooting Ceph Orchestrator

### Watching cephadm Log MEssages

This is useful when making changes via the orchestrator like add/remove/scale services or upgrades.

```bash
ncn-s# ceph -w cephadm
```

With Debug

```bash
ncn-s00(1/2/3)# ceph config set mgr mgr/cephadm/log_to_cluster_level debug
ncn-s# ceph -W cephadm --watch-debug
```

**`Note:`** For use with orchestration tasks, this can be typically run from a node running the ceph mon process (typically ncn-s00(1/2/3)).  There may be cases where you are running a cephadm locally on a host and it will be more efficient to tail /var/log/ceph/cephadm.log.



## Usage Examples

This section will provide some indepth usage with examples of the more commonly used `ceph orch` sub commands.

List Service Deployments

```bash
ncn-s00(1/2/3):~ # ceph orch ls
NAME                       RUNNING  REFRESHED  AGE  PLACEMENT                           IMAGE NAME                                       IMAGE ID
alertmanager                   1/1  6m ago     4h   count:1                             registry.local/prometheus/alertmanager:v0.20.0   0881eb8f169f
crash                          3/3  6m ago     4h   *                                   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c
grafana                        1/1  6m ago     4h   count:1                             registry.local/ceph/ceph-grafana:6.6.2           a0dce381714a
mds.cephfs                     3/3  6m ago     4h   ncn-s001;ncn-s002;ncn-s003;count:3  registry.local/ceph/ceph:v15.2.8                 5553b0cb212c
mgr                            3/3  6m ago     4h   ncn-s001;ncn-s002;ncn-s003;count:3  registry.local/ceph/ceph:v15.2.8                 5553b0cb212c
mon                            3/3  6m ago     4h   ncn-s001;ncn-s002;ncn-s003;count:3  registry.local/ceph/ceph:v15.2.8                 5553b0cb212c
node-exporter                  3/3  6m ago     4h   *                                   registry.local/prometheus/node-exporter:v0.18.1  e5a616e4b9cf
osd.all-available-devices      9/9  6m ago     4h   *                                   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c
prometheus                     1/1  6m ago     4h   count:1                             docker.io/prom/prometheus:v2.18.1                de242295e225
rgw.site1.zone1                3/3  6m ago     4h   ncn-s001;ncn-s002;ncn-s003;count:3  registry.local/ceph/ceph:v15.2.8                 5553b0cb212c
```

**`FILTERS:`** You can apply filters by adding `--service_type <service type>` or `--service_name <service name>`.

**`Refernce Key`**

1. PLACEMENT - Represents a service deployed on all nodes. Otherwise the listed placement is where it is expected to be deployed.
2. NAME - The deployment name.  this is a generalized name to reference the deployment.  This is being noted as additional subcommands the name is more specific to the actual deployed daemon.


List Deployed Daemons

```bashncn-s001:~ # ceph orch ps
NAME                             HOST      STATUS        REFRESHED  AGE  VERSION  IMAGE NAME                                       IMAGE ID      CONTAINER ID
alertmanager.ncn-s001            ncn-s001  running (5h)  5m ago     5h   0.20.0   registry.local/prometheus/alertmanager:v0.20.0   0881eb8f169f  0e6a24469465
crash.ncn-s001                   ncn-s001  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  b6a582ed7573
crash.ncn-s002                   ncn-s002  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  3778e29099eb
crash.ncn-s003                   ncn-s003  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  fe085e310cbd
grafana.ncn-s001                 ncn-s001  running (5h)  5m ago     5h   6.6.2    registry.local/ceph/ceph-grafana:6.6.2           a0dce381714a  2fabb486928c
mds.cephfs.ncn-s001.qrxkih       ncn-s001  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  03a3a1ce682e
mds.cephfs.ncn-s002.qhferv       ncn-s002  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  56dca5cca407
mds.cephfs.ncn-s003.ihwkop       ncn-s003  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  38ab6a6c8bc6
mgr.ncn-s001.vkfdue              ncn-s001  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  456587705eab
mgr.ncn-s002.wjaxkl              ncn-s002  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  48222c38dd7e
mgr.ncn-s003.inwpij              ncn-s003  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  76ff8e485504
mon.ncn-s001                     ncn-s001  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  bcca26f69191
mon.ncn-s002                     ncn-s002  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  43c8472465b2
mon.ncn-s003                     ncn-s003  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  7aa1b1f19a00
node-exporter.ncn-s001           ncn-s001  running (5h)  5m ago     5h   0.18.1   registry.local/prometheus/node-exporter:v0.18.1  e5a616e4b9cf  0be431766c8e
node-exporter.ncn-s002           ncn-s002  running (5h)  5m ago     5h   0.18.1   registry.local/prometheus/node-exporter:v0.18.1  e5a616e4b9cf  6ae81d01d963
node-exporter.ncn-s003           ncn-s003  running (5h)  5m ago     5h   0.18.1   registry.local/prometheus/node-exporter:v0.18.1  e5a616e4b9cf  330dc09d0845
osd.0                            ncn-s002  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  a8c7314b484b
osd.1                            ncn-s001  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  8f9941887053
osd.2                            ncn-s003  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  49cf2c532efb
osd.3                            ncn-s001  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  69e89cf18216
osd.4                            ncn-s002  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  72d7f51a3690
osd.5                            ncn-s003  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  76d598c40824
osd.6                            ncn-s001  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  d2372e45c8eb
osd.7                            ncn-s002  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  5bd22f1d4cad
osd.8                            ncn-s003  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  7c5282f2e107
prometheus.ncn-s001              ncn-s001  running (5h)  5m ago     5h   2.18.1   docker.io/prom/prometheus:v2.18.1                de242295e225  bf941a1306e9
rgw.site1.zone1.ncn-s001.qegfux  ncn-s001  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  e833fc05acfe
rgw.site1.zone1.ncn-s002.wqrzoa  ncn-s002  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  83a131a7022c
rgw.site1.zone1.ncn-s003.tzkxya  ncn-s003  running (5h)  5m ago     5h   15.2.8   registry.local/ceph/ceph:v15.2.8                 5553b0cb212c  c67d75adc620
```

**`FILTERS:`** You can apply filters by adding  any or all of  [--hostname <hostname> --service_name <service_name> --daemon_type <daemon_type> --daemon_id <daemon_id>]


Ceph daemon start|stop|restart|reconfig

`NOTE:` The service name is from `ceph orch ps` **NOT** `ceph orch ls`.
```bash
ncn-s00(1/2/3):~ # ceph orch daemon restart alertmanager.ncn-s001
Scheduled to restart alertmanager.ncn-s001 on host 'ncn-s001'
```

`Additional Task:` You should monitor the restart using the `ceph orch ps` command and the time associated with the `STATUS` should be reset and show "running (time since started)."

Depploy or Scale services

`NOTE:` The service name is from `ceph orch ls` **NOT** `ceph orch ps`.

```bash
ncn-s00(1/2/3):~ # ceph orch apply alertmanager --placement="2 ncn-s001 ncn-s002"
Scheduled alertmanager update...
```

**`Refernce Key`**

1. PLACEMENT - This will show the nodes and the count.  if you only specify `--placement="2"` then it will automatically pick where to put it.

**`IMPORTANT:`** When working with the placement, you can have serveral combinations.  For example you can specify a placement of 1 but list a sub set of your nodes.  This is a good way to contain the process to those nodes.

**`IMPORTANT:`** This is not available for any deployments with a `PLACEMENT` of *

List Hosts Known to Ceph Orchestrator

```bash
ncn-s00(1/2/3):~ # ceph orch host ls
HOST      ADDR      LABELS  STATUS
ncn-s001  ncn-s001
ncn-s002  ncn-s002
ncn-s003  ncn-s003
```

List Drives on Hosts Known to Ceph Orchestrator

```bash
ncn-s00(1/2/3):~ # ceph orch device ls
Hostname  Path      Type  Serial                Size   Health   Ident  Fault  Available
ncn-s001  /dev/vdb  hdd   fb794832-f402-4f4f-a   107G  Unknown  N/A    N/A    No
ncn-s001  /dev/vdc  hdd   9bdef369-6bac-40ca-a   107G  Unknown  N/A    N/A    No
ncn-s001  /dev/vdd  hdd   3cda8ba2-ccaf-4515-b   107G  Unknown  N/A    N/A    No
ncn-s002  /dev/vdb  hdd   775639a6-092e-4f3a-9   107G  Unknown  N/A    N/A    No
ncn-s002  /dev/vdc  hdd   261e8a40-2349-484e-8   107G  Unknown  N/A    N/A    No
ncn-s002  /dev/vdd  hdd   8f01f9c6-2c6c-449c-a   107G  Unknown  N/A    N/A    No
ncn-s003  /dev/vdb  hdd   46467f02-1d11-44b2-b   107G  Unknown  N/A    N/A    No
ncn-s003  /dev/vdc  hdd   4797e919-667e-4376-b   107G  Unknown  N/A    N/A    No
ncn-s003  /dev/vdd  hdd   3b2c090d-37a0-403b-a   107G  Unknown  N/A    N/A    No
```

**`IMPORTANT:`** If you use the `--wide` it will give the reasons a drive is not Available.  The `DOES NOT` mean something is wrong.  IF Ceph already has te drive provisioned, then you may see reasons simliar 

## General Use

Update the size or placement for a service or apply a large yaml spec

```bash
ceph orch apply [mon|mgr|rbd-mirror|crash|alertmanager|grafana|node-exporter|prometheus] [<placement>] [--dry-run] [plain|json|json-pretty|yaml] [--unmanaged]
```

Scale an iSCSI service

```bash
ceph orch apply iscsi <pool> <api_user> <api_password> [<trusted_ip_list>][<placement>] [--dry-run] [plain|json|json-pretty|yaml] [--unmanaged]           
```

Update the number of MDS instances for the given fs_name

```bash
ceph orch apply mds <fs_name> [<placement>] [--dry-run] [--unmanaged] [plain|json|json-pretty|yaml]    
```

Scale an NFS service

```bash
ceph orch apply nfs <svc_id> <pool> [<namespace>] [<placement>] [--dry-run] [plain|json|json-pretty|yaml] [--unmanaged]  
```

Create OSD daemon(s) using a drive group spec

```bash
ceph orch apply osd [--all-available-devices] [--dry-run] [--unmanaged] [plain|json|json-pretty|yaml]  
```

Update the number of RGW instances for the given zone

```bash
ceph orch apply rgw <realm_name> <zone_name> [<subcluster>] [<port:int>] [--ssl] [<placement>] [--dry-run] [plain|json|json-pretty|yaml] [--unmanaged]    
```

Cancels ongoing operations

```bash
ceph orch cancel                                                                      
```

Add daemon(s)

```bash
ceph orch daemon add [mon|mgr|rbd-mirror|crash|alertmanager|grafana|node-exporter|prometheus] [<placement>]    
```

Start iscsi daemon(s)

```bash
ceph orch daemon add iscsi <pool> <api_user> <api_password> [<trusted_ip_list>] [<placement>]      
```

Start MDS daemon(s)

```bash
ceph orch daemon add mds <fs_name> [<placement>]                                      
```

Start NFS daemon(s)

```bash
ceph orch daemon add nfs <svc_id> <pool> [<namespace>] [<placement>]                  
```

Create an OSD service. Either --svc_arg=host:drives

```bash
ceph orch daemon add osd [<svc_arg>]                                                  
```

Start RGW daemon(s)

```bash
ceph orch daemon add rgw <realm_name> <zone_name> [<subcluster>] [<port:int>] [--ssl] [<placement>]     
```

Redeploy a daemon (with a specifc image)

```bash
ceph orch daemon redeploy <name> [<image>]                                            
```

Remove specific daemon(s)

```bash
ceph orch daemon rm <names>... [--force]                                              
```

Start, stop, restart, (redeploy,) or reconfig a specific daemon

```bash
ceph orch daemon start|stop|restart|reconfig <name>                                   
```

List devices on a host

```bash
ceph orch device ls [<hostname>...] [plain|json|json-pretty|yaml] [--refresh] [--wide]    
```

Zap (erase!) a device so it can be re-used

```bash
ceph orch device zap <hostname> <path> [--force]
```

 Add a host

```bash
ceph orch host add <hostname> [<addr>] [<labels>...]                                 
```

Add a host label

```bash
ceph orch host label add <hostname> <label>                                           
```

Remove a host label

```bash
ceph orch host label rm <hostname> <label>                                            
```

List hosts

```bash
ceph orch host ls [plain|json|json-pretty|yaml]                                       
```

Check if the specified host can be safely stopped without reducing availability

```bash
ceph orch host ok-to-stop <hostname>                                                  
```

Remove a host

```bash
ceph orch host rm <hostname>                                                         
```

Update a host address

```bash
ceph orch host set-addr <hostname> <addr>                                             
```

List services known to orchestrator

```bash
ceph orch ls [<service_type>] [<service_name>] [--export] [plain|json|json-pretty|yaml] [--refresh]   
```

Remove OSD services

```bash
ceph orch osd rm <svc_id>... [--replace] [--force]                                    
```

Status of OSD removal operation

```bash
ceph orch osd rm status [plain|json|json-pretty|yaml]                                
```

Remove OSD services

```bash
ceph orch osd rm stop <svc_id>...                                                     
```

Pause orchestrator background work

```bash
ceph orch pause                                                                      
```

List daemons known to orchestrator

```bash
ceph orch ps [<hostname>] [<service_name>] [<daemon_type>] [<daemon_id>] [plain|json|json-pretty|yaml] [--refresh] 
```

Resume orchestrator background work (if paused)

```bash
ceph orch resume                                                                      
```

Remove a service

```bash
ceph orch rm <service_name> [--force]                                                
```

Select orchestrator module backend

```bash
ceph orch set backend <module_name>                                                   
```

Start, stop, restart, redeploy, or reconfig an entire service (i.e. all daemons)

```bash
ceph orch start|stop|restart|redeploy|reconfig <service_name>                         
```

Report configured backend and its status

```bash
ceph orch status [plain|json|json-pretty|yaml]                                        
```

Check service versions vs available and target containers

```bash
ceph orch upgrade check [<image>] [<ceph_version>]                                    
```

Pause an in-progress upgrade

```bash
ceph orch upgrade pause                                                              
```

Resume paused upgrade

```bash
ceph orch upgrade resume                                                              
```

Initiate upgrade

```bash
ceph orch upgrade start [<image>] [<ceph_version>]                                    
```

Check service versions vs available and target containers

```bash
ceph orch upgrade status                                                              
```

Stop an in-progress upgrade

```bash
ceph orch upgrade stop                                                               
```