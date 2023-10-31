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
