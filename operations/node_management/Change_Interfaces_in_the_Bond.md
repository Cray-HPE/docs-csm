## Change Interfaces in the Bond

Configure the interfaces for `bond0` on `ncn-w001` and establish an "up" `bond0` on all other NCNs.

### Prerequisites

This procedure requires administrative privileges.

### Procedure

1.  Customize the interfaces applied by Ansible for the bond configuration by editing the `nics.yml` file in the NCN group variables.

    ```bash
    ncn-w001# vi /opt/cray/crayctl/files/group_vars/ncn/nics.yml
    ...
    # Interface configuration.
    # Whether to use the bond or not during NCN installs.
    ansible_hw_bond_enabled: yes
    # Use Jumboframes if networking is configured as such.
    ansible_hw_bond_jumboframes: yes
    ## Default: LACP LAGG on PCI-E NICs; or non-LAGG (single nic).
    ansible_hw_bond:
      unix_name: bond0
    # 9238 is the Mellanox SN2100 Max per-port.
      mtu: "{{ ansible_hw_bond_jumboframes | ternary(9238, 1500) }}"
      members:
      - eth0
      - eth1
      - em1
      - em2
      module_opts:
      - 'mode=802.3ad'   # General default LACP --------------> : 802.3ad
      - 'miimon=100'     # General default link monitor time -> : 100ms
      - 'lacp_rate=fast' # General default rate --------------> : fast
      - 'xmit_hash_policy=layer2+3' # Enable IP Space --------> : layer2+3
    ```

2.  Update the /opt/cray/crayctl/files/group\_vars/ncn/platform.yml values for lan1 and lan3.

    ```bash
    ncn-w001# vi /opt/cray/crayctl/files/group_vars/ncn/platform.yml
    ```

    The following is a summary of the bond:

    -   lan1 is the first member of the bond.
    -   lan3 is the second member of the bond.
    -   lan2 counter-intuitively has nothing to do with the bond. This is the external interface on `ncn-w001` and the leaf interface for the other NCNs.

3.  Run the `baremetal-interface` Ansible play so the changes can be picked up by the installer.

    Stage 1 of the install will apply it to `ncn-w001` \(BIS\), and the other NCNs will have it included in their AutoYaST files.

    ```bash
    ncn-w001# ansible-playbook /opt/cray/crayctl/ansible_framework/main/baremetal-interface.yml
    ```

4.  Restart the handlers for the interfaces so that the network manager reacquires bond members from a clean slate.

    This is a quick and safe way to clear out many networking bugs in the field.

    ```bash
    ncn-w001# systemctl restart wickedd-nanny
    ```

5.  Verify the bond is correct.

    ```bash
    ncn-w001# ansible ncn -m shell -a 'ip a show bond0 && \
    ip l show bond0 && wicked ifstatus --verbose bond0'
    ```



