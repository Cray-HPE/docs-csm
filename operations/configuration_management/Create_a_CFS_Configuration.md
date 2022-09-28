# Create a CFS Configuration

Create a Configuration Framework Service (CFS) configuration, which contains an
ordered list of layers. Each layer is defined by a Git repository clone URL, a
Git commit, a name, and the path in the repository to an Ansible playbook to execute.

## Prerequisites

* The Cray command line interface (CLI) tool is initialized and configured on the system.

## Procedure

1. Create a JSON file to hold data about the CFS configuration.

   ```bash
   cat configurations-example.json
   ```

   Example configuration:

   ```json
   {
    "description": "this is an optional field",
    "layers": [
      {
        "name": "configurations-layer-example-1",
        "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
        "playbook": "site.yml",
        "commit": "<git commit id>"
      },
      {
        "name": "configurations-layer-example-2",
        "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/example-repo2.git",
        "playbook": "site.yml",
        "commit": "<git commit id>"
      },
      # { ... add more configuration layers here, if needed ... }
    ]
   }
   ```

2. Add the configuration to CFS with the JSON file.

   ```bash
   cray cfs configurations update configurations-example \
      --file ./configurations-example.json --format json
   ```

   Example output:

   ```json
   {
     "lastUpdated": "2021-07-28T03:26:00:37Z",
     "layers": [ ... ],
     "name": "configurations-example"
   }
   ```
