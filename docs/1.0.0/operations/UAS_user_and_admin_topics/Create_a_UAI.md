# Create a UAI

It is rare that an an administrator would hand-craft a UAI in this way, but it is possible. This is the mechanism used to create broker UAIs for the broker mode of UAI management.

Refer to [Broker Mode UAI Management](Broker_Mode_UAI_Management.md) for more information.

### Prerequisites

This procedure requires administrative privileges.

### Procedure

1. Create a UAI manually.

    Use a command of the following form:

    ```
    cray uas admin uais create [options]
    ```
    The following options are available for use:

    * `--class-id <class-id>` - The class of the UAI to be created. This option must be specified unless a default UAI class exists, in which case, it can be omitted and the default will be used.
    * `--owner '<user-name>'` - Create the UAI as owned by the specified user.
    * `--passwd str '<passwd-string>'` - Specify the `/etc/password` format string for the user who owns the UAI. This will be used to set up credentials within the UAI for the owner when the owner logs into the UAI.
    * `--publickey-str '<public-ssh-key>'` - Specify the SSH public key that will be used to authenticate with the UAI. The key should be, for example, the contents of an `id_rsa.pub` file used by SSH.
