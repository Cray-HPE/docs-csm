# Hardware State Manager \(HSM\) State and Flag Fields

HSM manages important information for hardware components in the system. Administrators can use the data returned by HSM to learn about the state of the system. To do so, it is critical that the State and Flag fields are understood, and the next steps to take are known when viewing output returned by HSM commands. It is also beneficial to understand what services can cause State or Flag changes in HSM.

The following describes what causes State and Flag changes for all HSM components:

- Initial State/Flag is set upon discovery. This is generally `Off/OK` or `On/OK`. BMCs go to `Ready/OK` instead of `On/OK`.
- A component in the `Populated` state after discovery has an unknown power state. If one is expected for nodes, BMCs, or another component, this is likely due to a firmware issue.
- Flags can be set to `Warning` or `Alert` if the component's `Status.Health` reads as `Warning` or `Critical` via Redfish during discovery.
- State for all components associated with a BMC is set to `Empty` if that BMC is removed from the network.
- State change events from components are consumed by HSM via subscriptions to Redfish events. These are subscribed to and placed on the Kafka bus by `hmcollector` for HSM's consumption. HSM will update component state based on the information in the Redfish events.

The following describes what causes State and Flag changes for nodes only:

- Heartbeat Tracking Daemon \(HBTD\) updates the state of nodes based on heartbeats it receives from nodes.
- HBTD sets the node to `Ready/OK` when it starts heartbeats.
- HBTD sets the node to `Ready/Warning` after a few missed heartbeats.
- HBTD sets the node to `Standby` after many missed heartbeats and the node is presumed dead.

State descriptions:

- **`Empty`**

    The location is not populated with a component.

- **`Populated`**

    Present \(not empty\), but no further track can or is being done.

- **`Off`**

    Present but powered off.

- **`On`**

    Powered on. If no heartbeat mechanism is available, its software state may be unknown.

- **`Standby`**

    No longer `Ready` and presumed dead. It typically means the heartbeat has been lost \(w/ alert\).

- **`Ready`**

    Both `On` and `Ready` to provide its expected services. For example, used for jobs.


Flag descriptions:

- **`OK`**

    Component is OK.

- **`Warning`**

    There is a non-critical error. Generally coupled with a `Ready` state.

- **`Alert`**

    There is a critical error. Generally coupled with a `Standby` state. Otherwise, reported via Redfish.

### Hardware State Transitions

The following table describes how to interpret when the state of hardware changes:

| Prior State | New State     | Reason                                                       |
| ---------   | ------------- | ------------------------------------------------------------ |
| Ready       | Standby       | HBTD if node has many missed heartbeats                      |
| Ready       | Ready/Warning | HBTD if node has a few missed heartbeats                     |
| Standby     | Ready         | HBTD node re-starts heartbeating                             |
| On          | Ready         | HBTD node started heartbeating                               |
| Off         | Ready         | HBTD sees heartbeats before Redfish Event (On)               |
| Standby     | On            | Redfish Event (On) or if re-discovered while in the standby state |
| Off         | On            | Redfish Event (On)                                           |
| Standby     | Off           | Redfish Event (Off)                                          |
| Ready       | Off           | Redfish Event (Off)                                          |
| On          | Off           | Redfish Event (Off)                                          |
| Any State   | Empty         | Redfish Endpoint is disabled meaning component removal       |

Generally, nodes transition from `Off` to `On` to `Ready` when going from `Off` to booted, and from `Ready` to `Ready/Warning` to `Standby` to `Off` when shut down.

