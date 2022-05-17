# Log in to a Broker UAI

SSH to log into a Broker UAI and reach the End-User UAIs on demand.

## Prerequisites

* The user must be logged into a host that can reach the external IP address of the Broker UAI
* The user must know the external IP address or DNS host name of the Broker UAI

## Procedure

1. Log in to the Broker UAI.

    The following example is the first login for the `vers` user:

    ```bash
    vers> ssh vers@35.226.246.154
    The authenticity of host '35.226.246.154 (35.226.246.154)' can't be established.
    ECDSA key fingerprint is SHA256:k4ef6vTtJ1Dtb6H17cAFh5ljZYTl4IXtezR3fPVUKZI.
    Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
    Warning: Permanently added '35.226.246.154' (ECDSA) to the list of known hosts.
    Password:
    Creating a new UAI...

    The authenticity of host '10.21.138.52 (10.21.138.52)' can't be established.
    ECDSA key fingerprint is SHA256:TX5DMAMQ8yQuL4YHo9qFEJWpKaaiqfeSs4ndYXOTjkU.
    Are you sure you want to continue connecting (yes/no)? yes
    Warning: Permanently added '10.21.138.52' (ECDSA) to the list of known hosts.
    ```

    There are several things to notice here:

    * The first time the user logs in the Broker UAI's SSH host key is unknown, as is normal for SSH.
    * The user is asked for a password in this example.
      If the user's home directory, as defined in LDAP had been mounted in the Broker UAI and a `.ssh/authorized_keys`
      entry had been present, there would not have been a password prompt.
      Home directory trees can be mounted as volumes just as any other directory can.
    * The broker mechanism in the Broker UAI creates a new UAI because `vers` has never logged into this Broker UAI before.
    * There is a second prompt to acknowledge an unknown host which is, in this case, the End-User UAI itself.
      The Broker UAI constructs a public/private key pair for the hidden SSH connection between the broker
      and the End-User UAI shown in the image in [Broker Mode UAI Management](Broker_Mode_UAI_Management.md).

2. Log out of the Broker UAI.

3. Log in to the Broker UAI again.

    The next time `vers` logs in, it will look similar to the following:

    ```bash
    vers> ssh vers@35.226.246.154
    Password:
    vers@uai-vers-ee6f427e-6c7468cdb8-2rqtv>
    ```

    Only the password prompt appears now, because the hosts are all known and the End-User UAI exists but there is no `.ssh/authorized_keys` known yet by the Broker UAI for `vers`.

[Top: User Access Service (UAS)](index.md)

[Next Topic: UAI Image Customization](UAI_Image_Customization.md)
