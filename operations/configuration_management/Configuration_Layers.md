## Configuration Layers

The Configuration Framework Service \(CFS\) uses configuration layers to specify the location of configuration content that will be applied. Configurations may include one or more layers. Each layer is defined by a Git repository clone URL, a Git commit, a name \(optional\), and the path in the repository to an Ansible playbook to execute.

Configurations with a single layer are useful when testing out a new configuration on targets, or when configuring system components with one product at a time. To fully configure a node or boot image component with all of the software products required, multiple layers can be used to apply all configurations in a single CFS session. When applying layers in a session, CFS runs through the configuration layers serially in the order specified.


### Manage Configurations

See the cray cfs configurations --help command to manage CFS configurations on the system. The following operations are available:

-   list: List all configurations.
-   describe: Display info about a single configuration and its layer\(s\).
-   update: Create a new configuration or modify an existing configuration.
-   delete: Delete an existing configuration.


