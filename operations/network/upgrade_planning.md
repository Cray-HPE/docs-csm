$ Create a CSM 1.2 configuration upgrade plan 

 
Creating an upgrade plan is always going to be unique and dependent on the requirements of the upgrade path.  

Some release versions of the network configuration require coupled upgrade of software to enable new software functionality or bug fixes that may add time required to do the full upgrade.  

For example: in rel/1.2 we will upgrade Aruba/Mellanox switches to newer code.  

In this case and cases where configuration changes are extensive you may want to consider taking the generated configurations after review and uploading them to the switches startup config prior to booting to new code to upgrade both configuration and software simultaneously.  

This will prevent human error, especially from the extensive changes like say modifying 10’s or 100’s of ports away and have you install the generated configuration via the system without having to do the individual changes by hand.  

In addition to firmware upgrade paths, the application of CANU-generated switch configurations should be carefully considered and detailed.  The following are important considerations: 

* Critically analyze proposed changes to ensure the customer does not have an unexpected outage. 

* Provide a holistic upgrade plan which includes switch-by-switch ordered changes and minimizes system outages. Typically this should begin on the periphery of the network (leaf-bmc's) and move centrally towards spines and site uplinks. 

* Where system outages or interruptions are expected to occur, provide details on the change order of operations, expected timing of interruptions and guidance should the interruption be beyond expected timing. 

The resulting “plan” should provide a procedure which can be followed by the customer to upgrade the system from current state to a newer version.   