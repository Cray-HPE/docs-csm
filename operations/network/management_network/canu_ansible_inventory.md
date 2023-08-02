# Using `canu-inventory` with Ansible

`canu-inventory` is a dynamic inventory script that queries a `sls_input_file.json` in the working directory, or an API gateway (`$SLS_API_GW`).  It can be called directly to print the information or it can be passed as an argument to `ansible-inventory`.

- `$SLS_API_GW` and `$SLS_TOKEN` (or `$TOKEN`) must be set in order to query the API.
- `$SWITCH_USERNAME` and `$SWITCH_PASSWORD` must be set in order to execute playbooks.
- `ANSIBLE_HOST_KEY_CHECKING=False` can be set to ignore host key checking.
- `-e config_folder` should be set to the directory containing the switch configs.

```bash
# examples
ansible-inventory -i canu-inventory --list
ansible-playbook -i canu-inventory aruba-aoscx.yml -e config_folder=/switch_configs
```

When running the playbook you may need to input the full path to `canu-inventory`, the playbook, and the switch configs.

```bash
# example
ansible-playbook -i /Users/bin/canu-inventory /Users/bin/canu/inventory/plays/aruba-aoscx.yml -e config_folder=/Users/canu
```

If using the API, `$TOKEN` or `$SLS_TOKEN` need to be set.

If running this from outside the cluster over the CMN, `$REQUESTS_CA_BUNDLE` needs to be set.
