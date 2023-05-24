# `iuf workflow` Examples

(`ncn-m001#`) List all workflows for a given activity

```bash
iuf -a admin.05-15 workflow
```

Example output:

```text
admin-05-15-5bkf6-pre-install-check-tzb74
admin-05-15-hkrtj-process-media-zxmkk
admin-05-15-o0o25-pre-install-check-9rlq6
admin-05-15-a5osq-pre-install-check-ghf4s
admin-05-15-a5osq-deliver-product-p7rt6
admin-05-15-a5osq-update-vcs-config-b8lc6
admin-05-15-psdlp-process-media-l8n8c
admin-05-15-o0o25-update-vcs-config-m6xdg
admin-05-15-sp4kz-process-media-7n92r
admin-05-15-a5osq-update-cfs-config-f2kww
admin-05-15-o0o25-deliver-product-7r4fb
admin-05-15-zjswc-process-media-w92fb
```

(`ncn-m001#`) List the details of a particular workflow

```bash
iuf -a admin.05-15 workflow admin-05-15-a5osq-deliver-product-p7rt6
```

Example output:

```text
iuf -i input.yaml workflow admin-05-15-5bkf6-pre-install-check-tzb74
workflow_id: admin-05-15-5bkf6-pre-install-check-tzb74
session: admin-05-15-5bkf6
command: ./iuf -a admin.05-15 run --site-vars /etc/cray/upgrade/csm/admin/site_vars.yaml
  --bootprep-config-managed /etc/cray/upgrade/csm/admin/compute-and-uan-bootprep.yaml
  -e update-vcs-config
status: Succeeded
args:
  activity: admin.05-15
  bootprep_config_managed: /etc/cray/upgrade/csm/admin/compute-and-uan-bootprep.yaml
  end_stage: update-vcs-config
  force: true
  func: !!python/name:__main__.process_install ''
  log_dir: /etc/cray/upgrade/csm/iuf/admin.05-15/log
  media_dir: /etc/cray/upgrade/csm/admin.05-15
  relative_bootprep_config_managed: .bootprep-admin.05-15/compute-and-uan-bootprep.yaml
  site_vars: /etc/cray/upgrade/csm/admin/site_vars.yaml
  state_dir: /etc/cray/upgrade/csm/iuf/admin.05-15/state
script_stdout:
  configurations:
  - name: username-compute-23.2.17-activity
  - name: username-lnet-23.2.17-activity
  - name: username-uan-23.2.17-activity
```
