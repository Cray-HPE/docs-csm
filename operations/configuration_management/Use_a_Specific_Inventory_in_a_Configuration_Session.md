# Use a Specific Inventory in a Configuration Session

A special repository can be added to a Configuration Framework Service (CFS) configuration to help with certain scenarios, specifically when developing Ansible plays for use on the system. A static inventory often changes along with the Ansible content, and CFS users may need to test different configuration values simultaneously and not be forced to use the global `additionalInventoryUrl`.

Therefore, an `additional_inventory` mapping can be added to the CFS configuration. Similar to a standard configuration layer, the additional inventory only requires a commit and repository clone URL, and it overrides the global `additionalInventoryUrl` if it is specified in the global CFS options.

For example:

```bash
ncn-m001# cat configurations-example-additional-inventory.json
```

Example configuration:

```json
{
  "layers": [
    {
      "name": "configurations-layer-example-1",
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/example-repo.git",
      "playbook": "site.yml",
      "commit": "<git commit id>"
    }
  ],
  "additional_inventory": {
    "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/inventory.git",
    "commit": "a7d08b6e1be590ac01711e39c684b6893c1da0a9"
  }
}
```

