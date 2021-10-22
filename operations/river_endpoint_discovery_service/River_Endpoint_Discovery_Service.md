## River Endpoint Discovery Service \(REDS\)

The River Endpoint Discovery Service \(REDS\) performs geolocation and initialization of compute nodes, based on a mapping file that is provided with each system. In geolocation, names are assigned to compute nodes based on their physical location in the system, and the nodes are added to the Hardware State Manager \(HSM\). In initialization, hardware is assigned the required base configuration.

REDS reads its configuration from the System Layout Service \(SLS\). Systems ship with management switches that are preconfigured, and compute nodes are initialized and geolocated as a part of the installation process. The procedures in this section are provided to customers for the following use cases.

### REDS Use Cases

---

**Use Case:** Switch replaced \(for example, if a switch fails\).

**Entry Point:** [Configure a Management Switch for REDS](Configure_a_Management_Switch_for_REDS.md)

---

**Use Case:**

-   A node has been removed/decommissioned.
-   A node that is new to the system needs to be discovered.
-   A node that was previously configured by the system needs to be discovered.
-   The system wiring changed.

**Entry Point:**

1.  Update the SLS configuration
2.  [Initialize and Geolocate Nodes](Initialize_and_Geolocate_Nodes.md)

---

**Use Case:** Cold Start.

**Entry Point:**

1.  If a switch is replaced, refer to [Configure a Management Switch for REDS](Configure_a_Management_Switch_for_REDS.md).
2.  Power up switches and non-compute nodes \(NCN\).
3.  If any nodes are added, or the wiring is changed, check the SLS configuration.
4.  [Initialize and Geolocate Nodes](Initialize_and_Geolocate_Nodes.md).

---

**Use Case:** Geolocation has failed for one or more compute nodes.

**Entry Point:** [Troubleshoot Common REDS Issues](Troubleshoot_Common_REDS_Issues.md)

