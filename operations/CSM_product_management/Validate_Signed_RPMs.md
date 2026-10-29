# Validate Signed RPMs

The HPE Cray EX system signs RPMs to provide an extra level of security. Use the following procedure to import a key from either My HPE Software Center or a Kubernetes Secret, and then use that key to validate the RPM package signatures on each node type.

The RPMs will vary on compute, application, worker, master, and storage nodes. Check each node type to ensure the RPMs are correctly signed.

## Procedure

1. (`ncn-mw#`) Retrieve the signing key required to validate the RPMs.

    Use either the My HPE Software Center or Kubernetes Secret method to find the signing key.

    * **My HPE Software Center:**

        Download the signing key.

        ```bash
        curl LINK_TO_KEY_IN_My_HPE_Software_Center
        ```

    * **Kubernetes Secret:**

        Find the key and write it to a file.

        ```bash
        kubectl -n services get secrets hpe-signing-key -o jsonpath='{.data.gpg-pubkey}' | base64 -d | tee hpe-signing-key.asc
        ```

        Example output:

        ```text
        -----BEGIN PGP PUBLIC KEY BLOCK-----
        Version: GnuPG v2.0.22 (GNU/Linux)
        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
        =pzE0
        -----END PGP PUBLIC KEY BLOCK-----
        ```

1. (`ncn-mw#`) Verify that HPE is the issuer of the signed packages.

   Replace the *PATH-TO-KEY* value in the following command with the path to the signing key.

   ```bash
   gpg --show-keys PATH-TO-KEY/hpe-signing-key-dst-2026.asc
   ```

   Example output:

   ```text
    pub   rsa4096 2025-09-03 [SC] [expires: 2028-10-31]
      0E6F2E1C3329E28C0A25828C17BDA7C219CFB373
    uid                      Hewlett Packard Enterprise Company 2025-3-27 <signing@hpe.com>

   ```

1. (`ncn-mw#`) Import the signing key.

    ```bash
    rpm --import hpe-signing-key-dst-2026.asc
    ```

1. (`ncn-mw#`) Search for the signed packages using the version number from the previous step.

    ```bash
    rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE} %{SIGGPG:pgpsig}\n' | grep '19CFB373'
    ```

    Example output:

    ```text
    gpg-pubkey-19cfb373-68b86a53 (none)
    ```

1. (`ncn-mw#`) Validate the signature on an RPM.

    The RPM in this example is `platform-utils-1.8.6-1.noarch.rpm`.
    Replace the *PATH-TO-RPM* value in the following command with the path to the RPM.

    ```bash
    rpm -Kvv PATH-TO-RPM/platform-utils-1.8.6-1.noarch.rpm
    ```

    Example output:

    ```text
    ufdio:       1 reads,    19077 total bytes in 0.000025 secs
    D: loading keyring from pubkeys in /usr/lib/sysimage/rpm/pubkeys/*.key
    D: couldn't find any keys in /usr/lib/sysimage/rpm/pubkeys/*.key
    D: loading keyring from rpmdb
    D: opening  db environment /usr/lib/sysimage/rpm cdb:private:0x201
    D: opening  db index       /usr/lib/sysimage/rpm/Packages 0x400 mode=0x0
    D: locked   db index       /usr/lib/sysimage/rpm/Packages
    D: opening  db index       /usr/lib/sysimage/rpm/Name nofsync:0x400 mode=0x0
    D:  read h#       1
    Header SHA1 digest: OK
    D: added key gpg-pubkey-09d9ea69-67c857f3 to keyring
    D:  read h#       2
    Header SHA1 digest: OK
    D: added key gpg-pubkey-39db7c82-66c5d91a to keyring
    D:  read h#       3
    Header SHA1 digest: OK
    D: added key gpg-pubkey-3fa1d6ce-67c856ee to keyring
    D:  read h#       4
    Header SHA1 digest: OK
    D: added key gpg-pubkey-50a3dd1c-50f35137 to keyring
    D:  read h#       5
    Header SHA1 digest: OK
    D: added key gpg-pubkey-6f5da62b-67c8590f to keyring
    D:  read h#       6
    Header SHA1 digest: OK
    D: added key gpg-pubkey-73f03759-626bd414 to keyring
    D:  read h#       7
    Header SHA1 digest: OK
    D: added key gpg-pubkey-af5425f7-67c858a1 to keyring
    D:  read h#       8
    Header SHA1 digest: OK
    D: added key gpg-pubkey-d588dc46-63c939db to keyring
    D:  read h#     250
    Header SHA1 digest: OK
    D: added key gpg-pubkey-25db7ae0-645bae34 to keyring
    D:  read h#     251
    Header SHA1 digest: OK
    D: added key gpg-pubkey-9a296436-67145df8 to keyring
    D:  read h#     412
    Header SHA1 digest: OK
    D: added key gpg-pubkey-08570fc0-64ef9793 to keyring
    D:  read h#    1100
    Header SHA1 digest: OK
    D: added key gpg-pubkey-9da39f44-5669d183 to keyring
    D:  read h#    1101
    Header SHA1 digest: OK
    D: added key gpg-pubkey-26c2b797-5669d0b9 to keyring
    D:  read h#    1102
    Header SHA1 digest: OK
    D: added key gpg-pubkey-324e6311-63b2a922 to keyring
    D:  read h#    1103
    Header SHA1 digest: OK
    D: added key gpg-pubkey-29b700a4-62b07e22 to keyring
    D:  read h#    1128
    Header SHA1 digest: OK
    D: added key gpg-pubkey-74c3a4a2-66d9d955 to keyring
    D:  read h#    1237
    Header SHA1 digest: OK
    D: added key gpg-pubkey-19cfb373-68b86a53 to keyring
    D: Using legacy gpg-pubkey(s) from rpmdb
    /etc/cray/upgrade/csm/media/171p2alpha5/csm-1.7.1-p2alpha.5/rpm/cray/csm/noos/noarch/platform-utils-1.8.6-1.noarch.rpm:
        Header V4 RSA/SHA256 Signature, key ID 19cfb373: OK
        Header SHA256 digest: OK
        Header SHA1 digest: OK
        Payload SHA256 digest: OK
        MD5 digest: OK
    ufdio:       8 reads,    26749 total bytes in 0.000040 secs
    D: closed   db index       /usr/lib/sysimage/rpm/Packages
    D: closed   db index       /usr/lib/sysimage/rpm/Name
    D: closed   db environment /usr/lib/sysimage/rpm

    ```
