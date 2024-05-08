# CFS Configurations

The Configuration Framework Service \(CFS\) uses configurations to allow users to define the Ansible content that CFS should run when configuring a target.
Configurations consists of one or more layers which define a Git repository clone URL, a Git commit id, and the path in the repository to an Ansible playbook to execute.
Layers can also contain an optional name, and an optional Git branch, which is converted into a Git commit id when the configuration is uploaded to CFS.

Configurations with a single layer are useful when testing out a new configuration on targets, or when configuring system components with one product at a time.
To fully configure a node or boot image component with all of the software products required, multiple layers can be used to apply all configurations in a single CFS session.
When applying layers in a session, CFS runs through the configuration layers serially in the order specified.

## Example configuration (single layer)

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
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
      "playbook": "site.yml",
      "commit": "43ecfa8236bed625b54325ebb70916f55884b3a4"
    }
  ]
}
```

## Example configuration (multiple layers)

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
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
      "playbook": "site.yml",
      "commit": "43ecfa8236bed625b54325ebb70916f55884b3a4"
    },
    {
      "name": "configurations-layer-example-2",
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
      "playbook": "site-custom.yml",
      "commit": "43ecfa8236bed625b54325ebb70916f55884b3a4"
    },
    {
      "name": "configurations-layer-example-3",
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/second-example-repo.git",
      "playbook": "site.yml",
      "commit": "8236bed625b4b3a443ecfa54325ebb70916f5588"
    }
  ]
}
```

## Using branches in configuration layers

When defining a configuration layer, either the `branch` or `commit` values can be used to reference a Git commit.
If `branch` is specified, CFS will automatically find the commit id at the top of that branch and insert it into the configuration.
This is necessary so that CFS can easily monitor the desired state of components.

(`ncn-mw#`) In the following example, when the configuration is created or updated, CFS will automatically check with VCS to get the commit at the head of the branch.
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
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
      "playbook": "site.yml",
      "branch": "main"
    }
  ]
}
```

```bash
cray cfs v3 configurations update configurations-example \
    --file ./configurations-example.json --format json
```

Example output:

```json
{
  "last_updated": "2021-07-28T03:26:30:37Z",
  "layers": [
    {
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
      "commit": "43ecfa8236bed625b54325ebb70916f55884b3a4",
      "branch": "main",
      "name": "configurations-layer-example-1",
      "playbook": "site.yml"
    }
  ],
  "name": "configurations-example"
}
```

(`ncn-mw#`) If the branch information does not need to be stored, use `--drop-branches`.
This is useful in cases where the branch is being provided to allow CFS to find the correct commit, but the branch should not be stored to avoid accidentally updating the commit ID in the future.

```bash
cat configurations-example.json
```

Example configuration:

```json
{
  "layers": [
    {
      "name": "configurations-layer-example-1",
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
      "playbook": "site.yml",
      "branch": "main"
    }
  ]
}
```

```bash
cray cfs v3 configurations update configurations-example \
    --file ./configurations-example.json --format json \
    --drop-branches true
```

Example output:

```json
{
  "last_updated": "2021-07-28T03:26:30:37Z",
  "layers": [
    {
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
      "commit": "43ecfa8236bed625b54325ebb70916f55884b3a4",
      "name": "configurations-layer-example-1",
      "playbook": "site.yml"
    }
  ],
  "name": "configurations-example"
}
```

(`ncn-mw#`) If changes are made to a repository and branches are specified in the configuration,
users can then use the `--update-branches` flag to update a configuration so that all commits reflect the latest commit on the branches specified.

```bash
cray cfs v3 configurations update configurations-example --update-branches
```

Example output:

```json
{
  "last_updated": "2021-07-28T03:26:30:37Z",
  "layers": [
    {
      "clone_url": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
      "commit": "<latest git commit id>",
      "branch": "main",
      "name": "configurations-layer-example-1",
      "playbook": "site.yml"
    }
  ],
  "name": "configurations-example"
}
```

## Using sources in a configuration layer

When defining a configuration layer, either the `clone_url` or `source` values can be used to reference a Git repo.
`clone_url` can be used for repos where CFS can use the default username, password and CA certificate, such as internal repos.
`source` allows the layer to reference a CFS source which can include information beyond a single `clone_url`. See [CFS Sources](CFS_Sources.md) for more information.

(`ncn-mw#`) In the following example, a `source` is specified rather than a `clone_url`.

```bash
cat configurations-example.json
```

Example configuration:

```json
{
  "layers": [
    {
      "name": "configurations-layer-example-1",
      "source": "example",
      "playbook": "site.yml",
      "branch": "main"
    }
  ]
}
```

```bash
cray cfs v3 configurations update configurations-example \
    --file ./configurations-example.json --format json
```

Example output:

```json
{
  "last_updated": "2021-07-28T03:26:30:37Z",
  "layers": [
    {
      "source": "example",
      "commit": "43ecfa8236bed625b54325ebb70916f55884b3a4",
      "branch": "main",
      "name": "configurations-layer-example-1",
      "playbook": "site.yml"
    }
  ],
  "name": "configurations-example"
}
```

## Create a CFS configuration

Use the `cray cfs v3 configurations update` command to create a configuration.

1. (`ncn-mw#`) Create a JSON file to hold data about the CFS configuration.

   ```bash
   cat example-config.json
   ```

   Example configuration:

   ```json
   {
    "description": "this is an optional field",
    "layers": [
      {
        "name": "configurations-layer-example-1",
        "clone_url": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
        "playbook": "site.yml",
        "commit": "<git commit id>"
      },
      {
        "name": "configurations-layer-example-2",
        "clone_url": "https://api-gw-service-nmn.local/vcs/cray/example-repo2.git",
        "playbook": "site.yml",
        "commit": "<git commit id>"
      },
      "... add more configuration layers here, if needed ..."
    ]
   }
   ```

1. (`ncn-mw#`) Add the configuration to CFS with the JSON file.

   ```bash
   cray cfs v3 configurations update example-config \
      --file ./example-config.json --format json
   ```

   Example output:

   ```json
   {
     "last_updated": "2021-07-28T03:26:00:37Z",
     "layers": [ "..." ],
     "name": "example-config"
   }
   ```

## Update a CFS configuration

Use the `cray cfs v3 configurations update` command, similar to creating a configuration.

1. (`ncn-mw#`) Add and/or remove the configuration layers from an existing JSON configuration file.

    Do not include the name of the configuration in the JSON file. This is specified on the command line in the next step.

    ```bash
    cat configurations-example.json
    ```

    Example configuration:

    ```json
    {
      "layers": [
        {
          "name": "configurations-layer-example-1",
          "clone_url": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
          "playbook": "site.yml",
          "commit": "<git commit id>"
        }
      ]
    }
    ```

1. (`ncn-mw#`) Update the configuration in CFS.

    ```bash
    cray cfs v3 configurations update configurations-example --file ./configurations-example.json --format json
    ```

    Example output:

    ```json
    {
      "last_updated": "2021-07-28T03:26:30:37Z",
      "layers": [
        {
          "clone_url": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
          "commit": "<git commit id>",
          "name": "configurations-layer-example-1",
          "playbook": "site.yml"
        }
      ],
      "name": "configurations-example"
    }
    ```
