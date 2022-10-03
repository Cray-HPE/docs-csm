# Configuration Layers

The Configuration Framework Service \(CFS\) uses configuration layers to specify the location of configuration content that will be applied. Configurations may include one or more layers.
Each layer is defined by a Git repository clone URL, a Git commit, a name \(optional\), and the path in the repository to an Ansible playbook to execute.

Configurations with a single layer are useful when testing out a new configuration on targets, or when configuring system components with one product at a time.
To fully configure a node or boot image component with all of the software products required, multiple layers can be used to apply all configurations in a single CFS session.
When applying layers in a session, CFS runs through the configuration layers serially in the order specified.

## Example Configuration (Single Layer)

The following is an example configuration with a single layer. This can be used
as a template to create a new configuration JSON file to input to CFS.

```bash
cat configuration-single.json
```

Example configuration:

```json
{
  "layers": [
    {
      "name": "configurations-layer-example-1",
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
      "playbook": "site.yml",
      "commit": "43ecfa8236bed625b54325ebb70916f55884b3a4"
    }
  ]
}
```

## Example Configuration (Multiple Layers)

The following is an example configuration with multiple layers from one or more
different configuration repositories. This can be used as a template to create a
new configuration JSON file to input to CFS.

```bash
cat configuration-multiple.json
```

Example configuration:

```json
{
  "description": "example playbook",
  "layers": [
    {
      "name": "configurations-layer-example-1",
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
      "playbook": "site.yml",
      "commit": "43ecfa8236bed625b54325ebb70916f55884b3a4"
    },
    {
      "name": "configurations-layer-example-2",
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
      "playbook": "site-custom.yml",
      "commit": "43ecfa8236bed625b54325ebb70916f55884b3a4"
    },
    {
      "name": "configurations-layer-example-3",
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/second-example-repo.git",
      "playbook": "site.yml",
      "commit": "8236bed625b4b3a443ecfa54325ebb70916f5588"
    }
  ]
}
```

## Use Branches in Configuration Layers

When defining a configuration layer, the `branch` or `commit` values can be used to reference a Git commit.
The `commit` value is the recommended way to reference a Git commit.
In the following example, when the configuration is created or updated, CFS will automatically check with VCS to get the commit at the head of the branch.
Both the commit and the branch are then stored. The commit acts as normal, and the branch is stored to make future updates to the commit easier.

```bash
cat configurations-example.json
```

Example configuration:

```json
{
  "layers": [
    {
      "name": "configurations-layer-example-1",
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
      "playbook": "site.yml",
      "branch": "main"
    }
  ]
}
```

```bash
cray cfs configurations update configurations-example \
--file ./configurations-example.json \
--format json
```

Example output:

```json
{
  "lastUpdated": "2021-07-28T03:26:30:37Z",
  "layers": [
    {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
      "commit": "<git commit id>",
      "branch": "main",
      "name": "configurations-layer-example-1",
      "playbook": "site.yml"
    }
  ],
  "name": "configurations-example"
}
```

If changes are made to a repository and branches are specified in the configuration, users can then use the `--update-branches` flag to update a configuration so that all commits reflect the latest commit on the branches specified.

```bash
cray cfs configurations update configurations-example --update-branches
```

Example output:

```json
{
  "lastUpdated": "2021-07-28T03:26:30:37Z",
  "layers": [
    {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
      "commit": "<latest git commit id>",
      "branch": "main",
      "name": "configurations-layer-example-1",
      "playbook": "site.yml"
    }
  ],
  "name": "configurations-example"
}
```

## Manage Configurations

Use the `cray cfs configurations --help` command to manage CFS configurations on the system. The following operations are available:

* `list`: List all configurations.
* `describe`: Display info about a single configuration and its layer\(s\).
* `update`: Create a new configuration or modify an existing configuration.
* `delete`: Delete an existing configuration.
