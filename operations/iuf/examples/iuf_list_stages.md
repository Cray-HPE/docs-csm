# `iuf list-stages` Examples

(`ncn-m001#`) List the stages for activity `admin-230126` along with their status and duration values.

```bash
iuf -a admin-230126 list-stages
+----------------------------+---------------------------------------------------------------------------------------+-----------+----------+
| Stage                      | Description                                                                           | Status    | Duration |
+----------------------------+---------------------------------------------------------------------------------------+-----------+----------+
| process-media              | Inventory and extract products in the media directory for use in subsequent stages    | Succeeded | 0:01:21  |
| pre-install-check          | Perform pre-install readiness checks                                                  | Succeeded | 0:01:13  |
| deliver-product            | Upload product content onto the system                                                | Succeeded | 0:09:56  |
| update-vcs-config          | Merge working branches and perform automated VCS configuration                        | Succeeded | 0:01:12  |
| update-cfs-config          | Update CFS configuration utilizing sat bootprep                                       | N/A       | N/A      |
| prepare-images             | Build and configure management node and/or managed node images utilizing sat bootprep | N/A       | N/A      |
| management-nodes-rollout   | Rolling rebuild of management nodes                                                   | N/A       | N/A      |
| deploy-product             | Deploy services to system                                                             | N/A       | N/A      |
| post-install-service-check | Perform post-install checks of deployed product services                              | N/A       | N/A      |
| managed-nodes-rollout      | Rolling reboot of managed nodes                                                       | N/A       | N/A      |
| post-install-check         | Perform post-install checks                                                           | N/A       | N/A      |
+----------------------------+---------------------------------------------------------------------------------------+-----------+----------+
Stage Summary
activity: admin-230126
command line: iuf -a admin-230126 -m admin-230126/media run --site-vars /mnt/developer/admin/admin_site_vars.yaml --bootprep-config-dir /etc/cray/upgrade/csm/iuf/hpc-csm-software-recipe-23.1.18/vcs -r deliver-product
log dir: /etc/cray/upgrade/csm/iuf/admin-230126/log
media dir: /opt/cray/iuf/admin-230126/media
ran stages: process-media pre-install-check deliver-product update-vcs-config
```
