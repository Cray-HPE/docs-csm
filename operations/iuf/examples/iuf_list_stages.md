# `iuf list-stages` Examples

(ncn-m001#) << TODO >>

```bash
iuf -a roe-install-20230107-2 list-stages
+----------------------------+--------------------------------------------------------------------------------------------+-----------+----------+
| stage                      | description                                                                                | status    | duration |
+----------------------------+--------------------------------------------------------------------------------------------+-----------+----------+
| process-media              | Inventory and extract products in the media directory for use in subsequent stages         | Succeeded | 0:01:30  |
| pre-install-check          | Perform pre-install readyness checks                                                       | Succeeded | 0:00:22  |
| deliver-product            | Upload product content onto the system                                                     | Succeeded | 0:07:14  |
| update-vcs-config          | Merge working branches and perform, automated VCS configuration                            | N/A       | N/A      |
| update-cfs-config          | Update CFS configuration (sat bootprep run --config)                                       | N/A       | N/A      |
| prepare-images             | Build and configure management node and/or managed node images (sat bootprep run --images) | N/A       | N/A      |
| management-nodes-rollout   | Rolling reboot or liveupdate of management nodes                                           | N/A       | N/A      |
| deploy-product             | Deploy services to system                                                                  | N/A       | N/A      |
| post-install-service-check | Perform post-install checks of processed services                                          | N/A       | N/A      |
| managed-nodes-rollout      | Rolling reboot or liveupdate of managed nodes nodes                                        | N/A       | N/A      |
| post-install-check         | Perform post-install checks                                                                | N/A       | N/A      |
+----------------------------+--------------------------------------------------------------------------------------------+-----------+----------+
Stage Summary
activity session: roe-install-20230107-2
command line: iuf -a roe-install-20230107-2 run -r deliver-product
log dir: /etc/cray/upgrade/csm/iuf/roe-install-20230107-2/log
media dir: /opt/cray/iuf/roe-install-20230107-2
ran stages: process-media pre-install-check deliver-product
```
