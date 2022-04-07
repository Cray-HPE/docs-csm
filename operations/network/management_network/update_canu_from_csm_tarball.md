# Update CANU From CSM Release Tarball

If doing a CSM install or upgrade, the release tarball contains a CANU RPM. It can be extracted and installed using the following steps.

## Procedure

1. Display the current CANU version.

    ```bash
    ncn# canu --version
    ```

1. Set the `TARBALL` variable to the path and filename of the CSM release tarball:

    ```bash
    ncn# TARBALL=/your/path/here/csm-version.tar.gz
    ```

1. Extract the CANU RPM from the tarball:

    ```bash
    ncn# tar -xzvf "$TARBALL" --wildcards "*/canu*.rpm"
    ```

    Output should look similar to the following:

    ```text
    csm-1.2.0-beta.81/rpm/cray/csm/sle-15sp2/x86_64/canu-1.2.1-1.x86_64.rpm
    ```

1. Note the path to the RPM from the output of the previous command, and install it:

    ```bash
    ncn# rpm -Uvh <path-to-canu-rpm>
    ```

1. Display the new CANU version.

    ```bash
    ncn# canu --version
    ```
