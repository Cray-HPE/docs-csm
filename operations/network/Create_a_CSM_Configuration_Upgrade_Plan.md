# Create a CSM Configuration Upgrade Plan

Creating an upgrade plan is unique and dependent on the requirements of the upgrade path. Some release versions of the network configuration require coupled upgrade of software to enable new software functionality, or bug fixes that may add time required to do the full upgrade.

For example, in CSM release 1.2, Aruba and Mellanox switches are being upgraded to newer code.

In this case and cases where configuration changes are extensive, consider taking the generated configurations after review and uploading them to the switches startup config prior to booting to new code to upgrade both configuration and software simultaneously. This will prevent human error, especially from extensive changes such as modifying a high number of ports away and installing the generated configuration via the system without having to do the individual changes by hand.

In addition to firmware upgrade paths, the application of CANU-generated switch configurations should be carefully considered and detailed. The following are important considerations:

* Critically analyze proposed changes to ensure the customer does not have an unexpected outage.
* Provide a holistic upgrade plan, which includes switch-by-switch ordered changes and minimizes system outages. Typically, this should begin on the periphery of the network (leaf-bmcs) and move centrally towards spines and site uplinks.
* Where system outages or interruptions are expected to occur, provide details on the change order of operations, expected timing of interruptions, and guidance should the interruption be beyond expected timing.

The resulting "plan" will provide a procedure to upgrade the system from the current state to a newer version.