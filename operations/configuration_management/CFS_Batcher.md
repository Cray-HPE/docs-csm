# CFS Batcher

The CFS Batcher manages the configuration state of system components (nodes).
It is responsible for noticing when a node's actual configuration does not match its
desired configuration, and then creating [CFS sessions](CFS_Sessions.md) to rectify that.

## More information

* [Automatic Configuration Management](Automatic_Configuration_Management.md)
* [Automated session flow](CFS_Flow_Diagrams.md#automated-session-flow)
* The following [CFS Global Options](CFS_Global_Options.md):
    * [Batch size](CFS_Global_Options.md#batch-size)
    * [Batch window](CFS_Global_Options.md#batch-window)
    * [Batcher check interval](CFS_Global_Options.md#batcher-check-interval)
    * [Batcher disable](CFS_Global_Options.md#batcher-disable)
    * [Batcher maximum backoff](CFS_Global_Options.md#batcher-maximum-backoff)
    * [Batcher pending timeout](CFS_Global_Options.md#batcher-pending-timeout)
    * [Default batcher retry policy](CFS_Global_Options.md#default-batcher-retry-policy)
* [CFS Components](CFS_Components.md)
* [Increasing verbosity for sessions that are not created directly](Change_the_Ansible_Verbosity.md#increasing-verbosity-for-sessions-that-are-not-created-directly)

## Known issues

* [Troubleshoot CFS Sessions Failing to Start](Troubleshoot_CFS_Sessions_Failing_to_Start.md)
* [CFS Batcher Can Be Slow To See Updated CFS Options](../../troubleshooting/known_issues/CFS_Batcher_Can_Be_Slow_To_See_Updated_CFS_Options.md)
* [CFS Batcher Creating Multiple Sessions For Same Batch](../../troubleshooting/known_issues/CFS_Batcher_Creating_Multiple_Sessions_For_Same_Batch.md)
* [CFS Batcher Crashes And Does Not Restart](../../troubleshooting/known_issues/CFS_Batcher_Crashes_And_Does_Not_Restart.md)
* [CFS Sessions Stuck Pending](../../troubleshooting/known_issues/CFS_Sessions_Stuck_Pending.md)
* [CFS Component State Updates Allow Invalid Values](../../troubleshooting/known_issues/CFS_Component_State_Updates_Allow_Invalid_Values.md)
* [Race Conditions in BOS and CFS](../../troubleshooting/known_issues/Race_Conditions_in_BOS_and_CFS.md)
