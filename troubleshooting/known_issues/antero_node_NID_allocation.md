# Antero node NID allocation

There is a known issue with Antero nodes where node NIDs are not correctly allocated. When Cray Site Init (CSI) generates hardware for the liquid-cooled cabinets for the System Layout Service (SLS) input file it assumes all blades in the cabinet are Windom
compute blades. Even though both Antero and Windom blades both have 4 nodes, they have different physical layouts.

- Windom blades have 2 node BMCs with 2 nodes per node BMC with the following nodes: `b0n0`, `b0n1`, `b1n0`, `b1n1`
- Antero blades have 1 Node BMC with 4 nodes per node BMC with the following nodes: `b0n0`, `b0n1`, `b0n2`, `b0n3`

SLS has NIDS only allocated for nodes `b0n0`, `b0n1`, `b1n0`, `b1n1` on a compute node blade. On a Antero blade the nodes `b0n2`, `b0n3` will have automatically assigned NIDs that are not contiguous with the NIDs on nodes `b0n0` and `b0n1`.

It is important to note the nodes `b0n2` and `b0n3` on a Antero blade are functional, but do not have NIDs in contiguous range with its peers.

## How to identity NIDs on Antero blades

To work around this issue the appropriate NID values for nodes `b0n2` and `n0n3` on Antero blades need to be supplied to Work Load Manager (WLM) when launch jobs. The following commands are some examples to determine the NIDs in use for Antero blades.

1. (`ncn#`) View the NIDs for Antero blades in the system:

    ```bash
    ANTERO_FILTER=$(sat hwinv --list-node-enclosures --fields=xname --filter='Model=ANTERO' --format json  | jq '.node_enclosure_list[] | "xname=\(.xname)*"' -r | sed 's/e0//' | paste -sd " " | sed 's/ / or /g')
    sat status --type Node --fields 'xname,role,nid' --filter "$ANTERO_FILTER"
    ```

    Example output:

    ```text
    +---------------+---------+-----------+
    | xname         | Role    | NID       |
    +---------------+---------+-----------+
    | x9000c1s4b0n0 | Compute | 1016      |
    | x9000c1s4b0n1 | Compute | 1017      |
    | x9000c1s4b0n2 | Compute | 147474562 |
    | x9000c1s4b0n3 | Compute | 147474563 |
    | x9000c1s5b0n0 | Compute | 1020      |
    | x9000c1s5b0n1 | Compute | 1021      |
    | x9000c1s5b0n2 | Compute | 147474594 |
    | x9000c1s5b0n3 | Compute | 147474595 |
    +---------------+---------+-----------+
    ```

    > (`ncn#`) Identify the Antero nodes present in the system:
    >
    > ```bash
    > sat hwinv --list-nodes --fields 'xname,"Model"' --filter='Model="HPE EX4252"'
    > ```
    >
    > Example output:
    >
    > ```text
    > ################################################################################
    > Listing of all nodes
    > ################################################################################
    > +---------------+------------+
    > | xname         | Model      |
    > +---------------+------------+
    > | x9000c1s7b0n0 | HPE EX4252 |
    > | x9000c1s7b0n1 | HPE EX4252 |
    > | x9000c1s7b0n2 | HPE EX4252 |
    > | x9000c1s7b0n3 | HPE EX4252 |
    > | x9000c3s0b0n0 | HPE EX4252 |
    > | x9000c3s0b0n1 | HPE EX4252 |
    > | x9000c3s0b0n2 | HPE EX4252 |
    > | x9000c3s0b0n3 | HPE EX4252 |
    > +---------------+------------+
    > ```

1. (`ncn#`) View NIDS for all compute nodes in the system:

    ```bash
    sat status --type Node --fields 'xname,role,nid' --filter 'role=compute'
    ```

    Example output:

    ```text
    +---------------+---------+-----------+
    | xname         | Role    | NID       |
    +---------------+---------+-----------+
    | x9000c1s0b0n0 | Compute | 1000      |
    | x9000c1s0b0n1 | Compute | 1001      |
    | x9000c1s1b0n0 | Compute | 1004      |
    | x9000c1s1b0n1 | Compute | 1005      |
    | x9000c1s7b0n0 | Compute | 1028      |
    | x9000c1s7b0n1 | Compute | 1029      |
    | x9000c1s7b0n2 | Compute | 147474562 |
    | x9000c1s7b0n3 | Compute | 147474563 |
    | x9000c3s0b0n0 | Compute | 1032      |
    | x9000c3s0b0n1 | Compute | 1033      |
    | x9000c3s0b0n2 | Compute | 147474594 |
    | x9000c3s0b0n3 | Compute | 147474595 |
    +---------------+---------+-----------+
    ```
