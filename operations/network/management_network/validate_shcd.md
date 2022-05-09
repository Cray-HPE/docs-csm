# Validate the SHCD

Use the CSM Automated Network Utility (CANU) to validate the SHCD. SHCD validation is required to ensure Plan-of-Record network configurations are generated. This is an iterative process to create a model of the entire network topology connection-by-connection.

## Topics

* [Prerequisites before validating the SHCD](#prerequisites)
* [Begin validation in the following order](#begin-validation-in-the-following-order)
* [Checks and Validations](#checks-and-validations)
* [Logging and Updates](#logging-and-updates)
* [Output SHD to JSON](#output-shcd-to-json)

## Prerequisites

* Up to date SHCD.
* CANU installed with version 1.1.11 or greater.
  * Run `canu --version` to see version.
  * If doing a CSM install or upgrade, a CANU RPM is located in the release tarball. For more information, see this procedure: [Update CANU From CSM Tarball](canu/update_canu_from_csm_tarball.md)

## Prepare to Validate

1. Open existing SHCD in Excel.

1. Save a new copy with an incremented revision number and make sure the updated version is being edited.

Several worksheets (tabs) are used to store the topology of the management network.

## Begin Validation

The SHCD must be validated in the following order:

1. `10G_25G_40G_100G` tab (or some variation thereof) contains switch-to-switch connections, as well as NCN server connections to the switch
1. Node Management Network (NMN) contains network management nodes
1. Hardware Management Network (HMN) contains device BMCs and other 1G management ports
1. `MTN_TDS`, `Mountain-TDS-Management`, or some variation thereof for Mountain cabinets
1. `PDU`

### Validation Steps

1. Validate the `10G_25G_40G_100G` tab and select the upper left corner and lower right corner of the spreadsheet with the `Source Rack Location Slot Port Destination Rack Location Port` information.

   This is a block of data on the right hand of the worksheet and is not the calculated values used for cable labels on the left-hand side.

   ![SHCD example](./img/shcd_example.png "SHCD example")

   In this example above, the `10G_25G_40G_100G` worksheet has the upper left and lower right corners of `I37` and `T107` respectively.
   Note, the above screenshot is trimmed and only the first full 68 rows are shown.

1. Use CANU to validate this worksheet.

   ```bash
   ncn# canu validate shcd -a full --shcd ./HPE\ System\ Hela\ CCD.revA27.xlsx --tabs 10G_25G_40G_100G --corners I37,T107
   ```

   The `-a` or `–architecture` parameter can be set to `tds`, `full`, or `v1` (case insensitive):

   * `tds` – Aruba-based Test and Development System. These are small systems characterized by Kubernetes NCNs cabled directly to the spine.
   * `full` – Aruba-based Leaf-Spine systems. These are usually customer production systems.
   * `v1` – Dell and Mellanox based systems of either a TDS or Full layout.

   CANU will ensure that each cell has valid data and that the connections between devices are allowed. Errors will stop processing and must be fixed in
   the spreadsheet before moving on. A "clean run" through a worksheet will include the model, a port-map of each node and may include warnings. See a
   list of typical errors at the end of this document to help in fixing the worksheet data.

1. Check for errors after validating the worksheet.

   ```bash
   ncn# canu validate shcd -a full --shcd ./HPE\ System\ Hela\ CCD.revA27.xlsx --tabs 10G_25G_40G_100G,NMN --corners I37,T107,J15,T16 --log DEBUG
   ```

### Checks and Validation

A worksheet that runs "cleanly" will have checked that:

* Nodes are "architecturally allowed" to connect to each other.

* No overlapping ports specified.

A worksheet that runs *cleanly* will have checked that:

* Nodes are *architecturally allowed* to connect to each other.

* No overlapping ports specified.

* Node connections can be made at the appropriate speeds.

In addition, a clean run will have the following sections:

* SHCD Node Connections – A high level list of all node connections on the system.

* SHCD Port Usage – A Port-by-port detailed listing of all node connections on the system.

* Warnings:
  * A list of nodes found that are not categorized on the system.

    **Note:** This list is important as it could include misspellings of nodes that should be included!

  * A list of cell-by-cell warnings of misspellings and other nit-picking items that CANU has autocorrected on the system.

#### Check Warnings

**Critical:** The `Warnings` output will contain a section headed `Node type could not be determined for the following`. This needs to
be carefully reviewed because it may contain site uplinks that are not tracked by CANU, and may also contain misspelled or mis-categorized
nodes. As an example:

For example:

```text
Node type could not be determined for the following.

These nodes are not currently included in the model.

(This may be a missing architectural definition/lookup or a spelling error)

--------------------------------------------------------------------------------
Sheet: 10G_25G_40G_100G
Cell: I96      Name: CAN switch
Cell: I97      Name: CAN switch
Cell: O87      Name: CAN switch
Cell: O90      Name: CAN switch
Cell: O93      Name: CAN switch
Cell: O100     Name: CAN switch
Cell: O103     Name: CAN switch
Cell: I38      Name: sw-spinx-002

Sheet: HMN
Cell: R36      Name: SITE

Sheet: NMN
Cell: P16      Name: SITE
```

**From the above example, two important observations can be made:**

1. CAN and SITE uplinks are not in the *clean run* model. This means that these ports will not be configured.

1. Critically, cell `I38` has a name of `sw-spinx-002`. This should be noted as a misspelling of `sw-spine-002` and corrected.

## Check SHCD Port Usage

Today CANU validates many things, but a future feature is full cable specification checking of nodes (e.g. which NCN ports go to
which switches to properly form bonds). There are several CANU roadmap items, but today a manual review of the `SHCD Port Usage`
connections list is vital. Specifically, check:

* Both Management NCNs (manager, worker, storage) and UAN NCNs (UAN, viz, and other Application Nodes) follow Plan of Record (PoR)
  cabling. See [Cable Management Network Servers](../../../install/cable_management_network_servers.md).

* Switch pair cabling is appropriate for VSX, MAGP, etc.

* Switch-to-switch cabling is appropriate for LAG formation.

* **Other** nodes on the network seem sane.

## Logging and Updates

Once the SHCD has run cleanly through CANU and CANU output has been manually validated, changes to the SHCD should be
*committed* so that work is not lost, and other users can take advantage of the CANU changes.

1. Add an entry to the changelog on the first worksheet (`Summary`).

   The changelog should include:

   * The CANU command line used to validate the spreadsheet
   * The CANU version being used to validate the spreadsheet
   * An overview of changes made to the spreadsheet

1. Upload the SHCD to an official storage location after it has been validated.

   Either of the following options can be used:

   * `customer communication` (CAST ticket for customers)
   * SharePoint (internal systems and sometimes customer systems)

## Output SHCD to JSON

* Once the SHCD is fully validated, the user will be able to output all the connection details to a `json` file.
* This output `json` file is used to generate switch configurations.

```bash
ncn# canu validate shcd -a v1 --shcd ./test.xlsx --tabs 40G_10G,NMN,HMN --corners I12,S37,I9,S20,I20,S31  --json --out cabling.json
```
