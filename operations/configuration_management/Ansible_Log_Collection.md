# Ansible Log Collection

* [ARA Records Ansible (ARA)](#ara-records-ansible-ara)
* [Accessing the UI](#accessing-the-ui)
* [Disabling ARA](#disabling-ara)

## ARA Records Ansible \(ARA\)

The Ansible logs from all Configuration Framework Service \(CFS\) sessions are recorded using ARA Records Ansible \(ARA\),
which provides an Ansible friendly way to view the logs for CFS.
ARA is an open-source log collector, API, and UI, specifically for collecting and parsing Ansible logs.
For more on ARA in general, see [the ARA home page](https://ara.recordsansible.org/).

## Accessing the UI

The ARA UI can be accessed via `https://ara.cmn.SYSTEM_DOMAIN_NAME`.

Additionally, links that include filters for specific components or sessions are included in the component and session records.

```json
{
  "configuration_status": "configured",
  "desired_config": "management-csm-1.5.0",
  "enabled": true,
  "error_count": 0,
  "id": "x3001c0s39b0n0",
  "logs": "ara.cmn.mug.hpc.amslabs.hpecorp.net/hosts?name=x3001c0s39b0n0",
  "tags": {}
}
```

The `logs` field in the above output is an example of a link including a filter for a specific component name (xname).

The links in records can be disabled by setting the `include_ara_links` option to false in the [CFS Global Options](CFS_Global_Options.md) if ARA is not being used.

## Disabling ARA

ARA is a plugin for Ansible that can easily be disabled if needed.

1. (`ncn-mw#`) Edit the `cfs-default-ansible-cfg` ConfigMap.

   ```bash
   kubectl edit cm cfs-default-ansible-cfg -n services
   ```

1. Remove `/usr/share/ansible/plugins/ara` from the list of `callback_plugins`.

   ```yaml
   callback_plugins = /usr/share/ansible/plugins/callback
   ```

1. Save the modified ConfigMap.

After the modified ConfigMap has been saved, all new CFS sessions that are created will no longer record logs to ARA.
