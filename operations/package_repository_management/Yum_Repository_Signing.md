# Yum Repository Signing

## Overview

Nexus Repository Manager can act as a Yum-compatible host for your Cray System Management (CSM) artifacts. Signing ensures that clients can verify the integrity and authenticity of the metadata before installing packages.

Repository metadata signing is a practice to ensure that the repository index is authentic.

## Prerequisites

* GPG installed on your build/signing server (e.g., `gpg (GnuPG) 2.x`).
* A Yum hosted repository in Nexus 3 (or a Yum proxy/group repository) where your CSM RPMs live.
* Write access (via Nexus API or UI) for uploading RPMs and configure signing keys.

## Generating Your GPG Key Pair

### Generate a new signing key on your signing server

   ```bash
   gpg --full-generate-key
   ```

This will generate a folder `/root/.gnupg/` in which the keys are stored.

### Export your public key so that it can be used for verification

   ```bash
   gpg --armor --output RPM-GPG-KEY-nxrmtest --export <email from the 1st step>
   ```

The public key is now stored as a file named `RPM-GPG-KEY-nxrmtest` under the path: `/root/.gnupg/private-keys-v1.d`

### Similarly, export the private key using the following command

```bash
gpg --armor --output RPM-GPG-KEY-nxrmtest.secret --export-secret-key <email from the 1st step>
```

The private key is now stored as a file named `RPM-GPG-KEY-nxrmtest.secret` under the path: `/root/.gnupg/private-keys-v1.d`
This private key needs to be configured in the settings of yum proxy repo using the Nexus UI.

`Yum Settings → Signing Key: paste entire contents of RPM-GPG-KEY-CSM.sec` along with the passphrase under the passphrase field.

<img width="1032" height="677" alt="image" src="https://github.com/user-attachments/assets/70a0fefb-bd51-46f6-b8cf-1d09a2277e83" />

## Configuring Yum to verify the signed yum repository

On the cluster that consumes CSM RPMs, create a file under`/etc/zypp/repos.d/csm-proxy-yum-test.repo` with the content below:

```bash
[csm-proxy-yum-test]
name=Nexus Yum Proxy Test Repo
enabled=1
autorefresh=1
baseurl=https://packages.local/repository/csm-proxy-yum-test
gpgcheck=1
repo_gpgcheck=1
gpgkey=file:///root/.gnupg/private-keys-v1.d/RPM-GPG-KEY-nxrmtest 
```

`repo_gpgcheck=1` instructs Yum/DNF to verify `repomd.xml.asc` against `repomd.xml` using the public key (`/root/.gnupg/private-keys-v1.d/RPM-GPG-KEY-nxrmtest`).

After this step, run `zypper refresh` and it should verify the yum repository with the public key.
The output looks similar to this:

```bash
Repository 'Virtualization:containers (5.5)' is up to date.
Repository 'cray-sdu-rda' is up to date.
Repository 'CSM Embedded NCN Packages (added by Ansible)' is up to date.
Repository 'CSM No-OS Packages (added by Ansible)' is up to date.
Looking for gpg key ID 8601C704 in cache /var/cache/zypp/pubkeys.
Looking for gpg key ID 8601C704 in repository Nexus Yum Proxy Test Repo.
  gpgkey=file:/root/.gnupg/private-keys-v1.d/RPM-GPG-KEY-nxrmtest

New repository or package signing key received:

  Repository:       Nexus Yum Proxy Test Repo
  Key Fingerprint:  0ED1 B6B0 8461 0039 B188 65AC 229A 046D 8601 C704
  Key Name:         dinesh <fomrdj007@gmail.com>
  Key Algorithm:    EdDSA 255
  Key Created:      Tue Jul  8 13:59:51 2025
  Key Expires:      Fri Jul  7 13:59:51 2028
  Subkey:           720565D0FD67CE44 2025-07-08 [expires: 2028-07-07]
  Rpm Name:         gpg-pubkey-8601c704-686d2457

    Note: Signing data enables the recipient to verify that no modifications occurred after the data
    were signed. Accepting data with no, wrong or unknown signature can lead to a corrupted system
    and in extreme cases even to a system compromise.

    Note: A GPG pubkey is clearly identified by its fingerprint. Do not rely on the key's name. If
    you are not sure whether the presented key is authentic, ask the repository provider or check
    their web site. Many providers maintain a web page showing the fingerprints of the GPG keys they
    are using.

Do you want to reject the key, or trust always? [r/a/?] (r): a
Retrieving repository 'Nexus Yum Proxy Test Repo' metadata .....................................................................................................................................[done]
Building repository 'Nexus Yum Proxy Test Repo' cache ..........................................................................................................................................[done]
Repository 'CSM SLE Packages (added by Ansible)' is up to date.
Repository 'Live Media Builds (standard)' is up to date.
All repositories have been refreshed.
```

This message ensures that the yum repository is verified against the provided public key.
