# Power On Compute Cabinets

Power on liquid-cooled and standard rack cabinet PDUs.

**Liquid-cooled Cabinets** - HPE Cray EX liquid-cooled cabinet CDU and PDU circuit breakers are controlled manually.

After the CDU is switched on and healthy, the liquid-cooled PDU circuit breakers can be switched ON. With PDU breakers ON, the Chassis Management Modules \(CMM\) and Cabinet Environmental Controllers \(CEC\) power on and boot.
These devices can then communicate with the management cluster and larger system management network. HVDC power remains OFF on liquid-cooled chassis until environmental conditions are normal and the CMMs receive a chassis
power-on command from Cray System Management \(CSM\) software.

**Standard Racks** - HPE Cray standard EIA racks include redundant PDUs. Some PDU models may require a flat-blade screw driver to open or close the PDU circuit breakers.

## Prerequisites

* The cabinet PDUs and coolant distribution units are connected to facility power and are healthy.
* An authentication token is required to access the API gateway and to use the `sat` command. See
  the "SAT Authentication" section of the HPE Cray EX System Admin Toolkit (SAT) product stream documentation (`S-8031`) for
  instructions on how to acquire a SAT authentication token.

## Procedure

1. Verify with site management that it is safe to power on the system.

1. If the system does not have Cray EX liquid-cooled cabinets, proceed to [Power On Standard Rack PDU Circuit Breakers](#power-on-standard-rack-pdu-circuit-breakers).

### Power On Cray Ex Liquid-Cooled Cabinet Circuit Breakers

1. Power on the CDU for the cabinet cooling group.

   1. Open the rear door of the CDU.

   1. Set the control panel circuit breakers to ON.

      ![CDU Circuit Breakers](../../../img/operations/CDU_Circuit_Breakers.png)

1. Set the PDU circuit breakers to on in each Cray EX cabinet.

   ![Liquid-cooled Cabinet PDU](../../../img/operations/Liquid_Cooled_Cabinet_PDU.svg)

1. Verify the status LEDs on the PSU are OK.

   ![PSU Status LEDs](../../../img/operations/PSU_Status.svg)

1. (`ncn-m001#`) Use the System Admin Toolkit \(`sat`\) to power on liquid-cooled cabinets, chassis, and slots.

   ```console
   sat bootsys boot --stage cabinet-power
   ```

   This command first resumes the `hms-discovery` Kubernetes cronjob and waits for it to be
   scheduled. Then, the `hms-discovery` job initiates power-on of the liquid-cooled cabinets.
   Finally, the `sat bootsys` command waits for the components in the liquid-cooled cabinets to be
   powered on. The `sat bootsys` command controls power only to liquid-cooled cabinets.

   The `sat bootsys` command may time out while waiting for the `hms-discovery` cronjob to be
   scheduled and display the following message:

   ```text
   ERROR: The cronjob hms-discovery in namespace services was not scheduled within expected window after being resumed.
   ```

   If this occurs, first check if the cronjob needs to be re-created. To do this, follow the instructions
   in the [Check `cronjobs`](../Power_On_and_Start_the_Management_Kubernetes_Cluster.md#check-cronjobs)
   section of the [Power On and Start the Management Kubernetes Cluster](../Power_On_and_Start_the_Management_Kubernetes_Cluster.md)
   procedure.

   If the cronjob does not need to be re-created and has been scheduled within the time expected
   (based on its cron schedule), execute the `sat bootsys boot --stage cabinet-power` command
   again.

   If `sat bootsys` fails to power on the cabinets through `hms-discovery`, then use PCS to manually power on the cabinet chassis,
   compute blade slots, and all populated switch blade slots \(1, 3, 5, and 7\). This example shows cabinets 1000-1003.

   ```bash
   cray power transition on --xnames "x[1000-1003]c[0-7]" --format json
   cray power transition on --xnames "x[1000-1003]c[0-7]s[0-7]" --format json
   cray power transition on --xnames "x[1000-1003]c[0-7]r[1,3,5,7]" --format json
   ```

   Verify the status of each of the power operations.

   ```bash
   cray power transition describe TRANSITION_ID --format json
   ```

### Power On Standard Rack PDU Circuit Breakers

1. Switch the standard rack compute cabinet PDU circuit breakers to ON.

   This applies power to the server BMCs and connects them to the management network. Compute nodes
   **do not power on and boot automatically**. The Boot Orchestration Service \(BOS\) brings up compute nodes and User Access Nodes \(UANs\).

   If necessary, use IPMI commands to power on individual servers as needed.

1. Verify that all system management network switches and Slingshot network switches are powered on in each rack, and that
   there are no error LEDS or hardware failures.

## Next Step

Return to [System Power On Procedures](../System_Power_On_Procedures.md) and continue with next step.
