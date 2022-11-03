# Log in to a Broker UAI

SSH to log into a broker UAI and reach the end-user UAIs on demand.

### Prerequisites

The broker UAI is running. See [Start a Broker UAI](Start_a_Broker_UAI.md).

### Procedure

1. Log in to the broker UAI.

    The following example is the first login for the `vers` user:

    ```
    vers> ssh vers@10.103.13.162
    The authenticity of host '10.103.13.162 (10.103.13.162)' can't be established.
    ECDSA key fingerprint is SHA256:k4ef6vTtJ1Dtb6H17cAFh5ljZYTl4IXtezR3fPVUKZI.
    Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
    Warning: Permanently added '10.103.13.162' (ECDSA) to the list of known hosts.
    Password:
    Creating a new UAI...

    The authenticity of host '10.21.138.52 (10.21.138.52)' can't be established.
    ECDSA key fingerprint is SHA256:TX5DMAMQ8yQuL4YHo9qFEJWpKaaiqfeSs4ndYXOTjkU.
    Are you sure you want to continue connecting (yes/no)? yes
    Warning: Permanently added '10.21.138.52' (ECDSA) to the list of known hosts.
    ```

    There are several things to notice here:
    * The first time the user logs in the broker UAI's SSH host key is unknown, as is normal for SSH.
    * The user is asked for a password in this example. If the user's home directory, as defined in LDAP had been mounted in the broker UAI and a `.ssh/authorized_keys` entry had been present, there would not have been a password prompt. Home directory trees can be mounted as volumes just as any other directory can.
    * The broker mechanism in the broker UAI creates a new UAI because `vers` has never logged into this broker UAI before.
    * There is a second prompt to acknowledge an unknown host which is, in this case, the end-user UAI itself. The broker UAI constructs a public/private key pair for the hidden SSH connection between the broker and the end-user UAI shown in the image in [Broker Mode UAI Management](Broker_Mode_UAI_Management.md).

1. Log out of the broker UAI.

1. Log in to the broker UAI again.

    The next time `vers` logs in, it will look similar to the following:

    ```
    vers> ssh vers@10.103.13.162
    Password:
    vers@uai-vers-ee6f427e-6c7468cdb8-2rqtv>
    ```

    Only the password prompt appears now, because the hosts are all known and the end-user UAI exists but there is no `.ssh/authorized_keys` known yet by the broker UAI for `vers`.