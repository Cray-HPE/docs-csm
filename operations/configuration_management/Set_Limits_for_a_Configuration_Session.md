# Set Limits for a Configuration Session

The configuration layers and session hosts can be limited when running a Configuration Framework Service \(CFS\) session.

## Limit CFS session hosts

Subsets of nodes can be targeted in the inventory when running CFS sessions, which is useful specifically when running a session with
dynamic inventory. Use the CFS `--ansible-limit` option when creating a session to apply the limits. The option directly corresponds
to the `--limit` option offered by `ansible-playbook`, and can be used to specify hosts, groups, or combinations of them with
patterns. CFS passes the value of this option directly to the `ansible-playbook` command for each configuration layer in the session.
For more information, see the Ansible documentation on
[Patterns: targeting hosts and groups](https://docs.ansible.com/ansible/latest/user_guide/intro_patterns.html).

> **IMPORTANT:** The `--limit` option is useful for temporarily limiting the scope of targets for a configuration session. For
> example, it could be used to target a subset of the `Compute` group that has been separated for development use. However it should
> **not** be used to limit an Ansible playbook to target only the nodes that the playbook is intended to use. If a playbook should
> only be run on a specific group, target the proper groups with the `hosts:` section of the Ansible playbook.
>
> See [Using Ansible Limits](https://ansible-tips-and-tricks.readthedocs.io/en/latest/ansible/commands/#limiting-playbooktask-runs)
> for more information about limiting hosts and groups in playbooks.

(`ncn-mw#`) Use the following command to create a CFS session to run on all hosts in the `Compute` group, but not a previously
defined `dev` group:

```bash
cray cfs sessions create --name example --configuration-name configurations-example --ansible-limit 'Compute:!dev' --format json
```

Example output:

```json
{
  "ansible": {
    "config": "cfs-default-ansible-cfg",
    "limit": "Compute:!dev",
    "verbosity": 0
  },
  "configuration": {
    "limit": "",
    "name": "configurations-example"
  },
  "name": "example",
  "status": {
    "artifacts": [],
    "session": {
      "status": "pending",
      "succeeded": "none"
    }
  },
  "tags": {},
  "target": {
    "definition": "dynamic",
    "groups": null
  }
}
```

## Limit CFS session configuration layers

It is possible to limit the session to only specific layers of the configuration that is specified. This is useful when re-applying
configuration of a specific layer and applying the other layers is not necessary or desired. This option may also reduce the number
of configurations that need to be created and stored by CFS because sessions can specify layers from a master configuration layer list.

Use the `--configuration-limit` option when creating a CFS session to apply configuration layer limits. Multiple layers to limit the
session are specified as a comma-separated list either by name \(if layers were given names when created\) or by zero-based index as
defined in the configuration submitted to CFS.

(`ncn-mw#`) Use the following command to create a CFS session to run only on `example-layer1`, and then `example-layer5` of a
previously created `configurations-example` configuration:

> **WARNING:** If the configuration's layers do not have names, then indices must be specified. Do not mix layer names and layer
> indices when using limits.

```bash
cray cfs sessions create --name example --configuration-name configurations-example \
    --configuration-limit 'example-layer1,example-layer5' --format json
```

Example output:

```json
{
  "ansible": {
    "config": "cfs-default-ansible-cfg",
    "limit": "",
    "verbosity": 0
  },
  "configuration": {
    "limit": "example-layer1,example-layer5",
    "name": "configurations-example"
  },
  "name": "example",
  "status": {
    "artifacts": [],
    "session": {
      "status": "pending",
      "succeeded": "none"
    }
  },
  "tags": {},
  "target": {
    "definition": "dynamic",
    "groups": null
  }
}
```
