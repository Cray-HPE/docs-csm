# Upgrade CSM Install Workarounds RPM

Workarounds for CSM are built and can be distributed separately from the main CSM release. This allows for future alternations of workarounds without having to re-release all of CSM. If this happens, it is necessary to upgrade the RPM from the originally installed version to the newly distributed one to receive the latest workarounds.

The process for doing this is quite simple:

1. Download or copy the RPM to `ncn-m001`.
2. Run:
    ```bash
    ncn-m001# rpm -Uhv /path/to/csm-install-workarounds-*.noarch.rpm
    ```
