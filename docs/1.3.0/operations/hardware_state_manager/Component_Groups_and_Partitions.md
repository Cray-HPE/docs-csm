# Component Groups and Partitions

The Hardware State Manager \(HSM\) provides the group and partition services. Both are means of grouping \(also known as labeling\) system components that are tracked by HSM. Components include the nodes, blades, controllers, and more on a system.

There is no limit to the number of members a group or partition contains. The only limitation is that all members must be actual members of the system. The HSM needs to know that the components exist.

### Groups

Groups are collections of components \(primarily nodes\) in /hsm/v2/State/Components. Components can be members of any number of groups. Groups can be created freely, and HSM does not assign them any predetermined meaning.

If a group has `exclusiveGroup=EXCLUSIVE_LABEL_NAME` set, then a component may only be a member of one group that matches that exclusive label. For example, if the exclusive group label colors is associated with groups blue, red, and green, then a node that is part of the green group could not also be placed in the red group.

### Partitions

Partitions are isolated, non-overlapping groups. Each component can be a member of only one partition at a time, and partitions are used as an access control mechanism. Partitions have a specific predefined meaning, intended to provide logical divisions of a single physical system.

