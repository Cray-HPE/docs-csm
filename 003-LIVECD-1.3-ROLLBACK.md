# LiveCD 1.3 Rollback

1. Reboot into the BIOS and change the boot order so the USB drive is not first
2. Run `ansible-playbook /opt/cray/crayctl/ansible_framework/main/enable-dns-conflict-hosts.yml -l ncn-w001` once you are booted back into the 1.3 install
3. `systemctl start dhcpd`
4. `for i in ncn-{m,s}00{1..3}-mgmt ncn-w00{2..3}-mgmt; do echo "------$i--------"; ipmitool -I lanplus -U $username -P $password -H $i chassis power on; done`
5. `systemctl stop dhcpd && ansible-playbook /opt/cray/crayctl/ansible_framework/main/disable-dns-conflict-hosts.yml -l ncn-w001`
6. Wait a bit
7. `ansible ncn* -m ping` until all nodes are up
8. Get a quick overview of how things look:
```
kubectl get nodes
kubectl get pods -A | grep Running | wc -l
kubectl get pods -A | grep Completed | wc -l
kubectl get pods -A | grep Crash | wc -l
kubectl get pods -A | grep Image | wc -l
ansible ncn-m* -m command -a 'ceph health'
```

## Fixing Ceph and Kubernetes
If things aren't quite working, you can try starting these services back up on the affected nodes.
```
# Restart dead OSDs
for i in 0 3 6 9;do systemctl status ceph-osd@${i}.service | grep active;done
for i in 0 3 6 9;do systemctl start ceph-osd@${i}.service | grep active;done
# Do the same for mgr and mds services
for i in mgr mds;do systemctl start ceph-${i}@ncn-s003.service | grep Active;done
for i in mgr mds;do systemctl start ceph-${i}@ncn-s003.service | grep Active;done
ceph status
```
