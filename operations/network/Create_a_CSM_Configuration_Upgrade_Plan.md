# Create a CSM Configuration Upgrade Plan

Creating an upgrade plan is unique and dependent on the requirements of the upgrade
path. Some release versions of the network configuration require coupled upgrade of
software to enable new software functionality, or bug fixes that may add time
required to do the full upgrade.

For example, when upgrading to CSM release 1.2, Aruba and Mellanox switches upgrade
to newer code. In cases like this, where configuration changes are extensive,
consider reviewing the generated configurations and uploading them to the switches'
startup configurations prior to booting to new code; that is, to upgrade both
the configuration and software simultaneously. This helps to prevent human error.

In addition to firmware upgrade paths, the application of CANU-generated switch
configurations should be carefully considered and detailed. The following are
important considerations:

* Critically analyze proposed changes to ensure the customer does not have an
  unexpected outage.
* Provide a holistic upgrade plan, which includes switch-by-switch ordered changes
  and minimizes system outages.
    * Typically, this should begin on the periphery of the network (`leaf-bmcs`) and
      move centrally towards spines and site uplinks.
* Where system outages or interruptions are expected to occur, provide details on the
  change order of operations, expected timing of interruptions, and guidance should
  the interruption be beyond expected timing.

The resulting plan will provide a procedure to upgrade the system from the current
state to a newer version.
