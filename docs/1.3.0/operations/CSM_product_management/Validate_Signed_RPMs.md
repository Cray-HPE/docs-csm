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
   rpm -qpi PATH-TO-KEY/hpe-signing-key.asc
   ```

   Example output:

   ```text
   Name        : gpg-pubkey
   Version     : 9da39f44
   Release     : 5669d183
   Architecture: (none)
   Install Date: Thu 25 Feb 2021 08:58:19 AM CST
   Group       : Public Keys
   Size        : 0
   License     : pubkey
   Signature   : (none)
   Source RPM  : (none)
   Build Date  : Thu 10 Dec 2015 01:24:51 PM CST
   Build Host  : localhost
   Relocations : (not relocatable)
   Packager    : Hewlett Packard Enterprise Company RSA-2048-30 <signhp@hpe.com>
   Summary     : gpg(Hewlett Packard Enterprise Company RSA-2048-30 <signhp@hpe.com>)
   Description :
   -----BEGIN PGP PUBLIC KEY BLOCK-----
   Version: rpm-4.11.3 (NSS-3)

   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
   =pzE0
   -----END PGP PUBLIC KEY BLOCK-----
   ```

1. (`ncn-mw#`) Import the signing key.

    ```bash
    rpm --import hpe-signing-key.asc
    ```

1. (`ncn-mw#`) Search for the signed packages using the version number from the previous step.

    ```bash
    rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE} %{SIGGPG:pgpsig}\n' | grep '9da39f44'
    ```

1. (`ncn-mw#`) Validate the signature on an RPM.

    The RPM in this example is `csm-install-workarounds-0.1.11-20210504151148_bf748be.src.rpm`.

    ```bash
    rpm -Kvv csm-install-workarounds-0.1.11-20210504151148_bf748be.src.rpm
    ```

    Example output:

    ```text
    D: loading keyring from pubkeys in /var/lib/rpm/pubkeys/*.key
    D: couldn't find any keys in /var/lib/rpm/pubkeys/*.key
    D: loading keyring from rpmdb
    D: opening  db environment /var/lib/rpm cdb:0x401
    D: opening  db index       /var/lib/rpm/Packages 0x400 mode=0x0
    D: locked   db index       /var/lib/rpm/Packages
    D: opening  db index       /var/lib/rpm/Name 0x400 mode=0x0
    D:  read     442 Header SHA1 digest: OK (489efff35e604042709daf46fb78611fe90a75aa)
    D: added key gpg-pubkey-f4a80eb5-53a7ff4b to keyring
    D:  read     493 Header SHA1 digest: OK (29ff3649c04c90eb654c1b3b8938e4940ff1fbbd)
    D: added key gpg-pubkey-4255bf0c-5ec2e252 to keyring
    D:  read     494 Header SHA1 digest: OK (e934d6983ae30a7e12c9c1fb6e86abb1c76c69d3)
    D: added key gpg-pubkey-9da39f44-5669d183 to keyring
    D:  read     496 Header SHA1 digest: OK (a93ccf43d5479ff84dc896a576d6f329fd7d723a)
    D: added key gpg-pubkey-e09422b3-57744e9e to keyring
    D:  read     497 Header SHA1 digest: OK (019de42112ea85bfa979968273aafeca8d457936)
    D: added key gpg-pubkey-fd4bf915-5f573efe to keyring
    D: Using legacy gpg-pubkey(s) from rpmdb
    D: Expected size:        36575 = lead(96)+sigs(5012)+pad(4)+data(31463)
    D:   Actual size:        36575
    csm-install-workarounds-0.1.11-20210504151148_bf748be.src.rpm:
        Header V4 RSA/SHA256 Signature, key ID 9da39f44: OK
        Header SHA1 digest: OK (87c62923c905424eaddac56c5dda7f3b6421d30d)
        V4 RSA/SHA256 Signature, key ID 9da39f44: OK
        MD5 digest: OK (130e13f11aaca834408665a93b61a8e4)
    D: closed   db index       /var/lib/rpm/Name
    D: closed   db index       /var/lib/rpm/Packages
    D: closed   db environment /var/lib/rpm
    ```
