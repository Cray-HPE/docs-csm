# End-User UAIs

UAIs used for interactive logins are called End-User UAIs. End-User UAIs can be seen as lightweight User Access Nodes (UANs), but there are important differences between UAIs and UANs.

End-User UAIs are not dedicated hardware like UANs. They are implemented as containers orchestrated by Kubernetes, which makes them subject to Kubernetes scheduling and resource management rules.
One key element of Kubernetes orchestration is impermanence. While End-User UAIs are often long running, Kubernetes can reschedule or recreate them as needed to meet resource and node availability constraints. UAIs can also be removed administratively.

End-User UAIs can also be configured with `soft` and `hard` timeout values. Reaching a `soft` timeout causes the UAI to be removed automatically when it is or becomes idle -- defined as having no logged in user sessions.
Reaching a `hard` timeout causes the UAI to be removed immediately regardless of logged in user sessions.

When any of these things cause a UAI to terminate, a new UAI may be created, but that new UAI reverts to its initial state, discarding any internal changes that might have been made in its previous incarnation.
State residing on external storage is, of course, preserved and available in the new End-User UAI.

An administratively removed End-User UAI or an End-User UAI terminated by a timeout may or may not ever be re-created.
An End-User UAI that is preempted because of resource pressure or other Kubernetes scheduling reasons may become unavailable for an extended time until the pressure is relieved, but will usually return to service once the underlying issue is resolved.

The impermanence of End-User UAIs makes them suitable for tasks that are immediate and interactive over relatively short time frames, such as building and testing software or launching workloads.
This impermanence makes them unsuitable for unattended activities like executing cron jobs or continuous monitoring of workload progress from a logged-in shell.
These kinds of activities are more suited to UANs, which are more permanent and, unless they are re-installed, retain modified state through reboots and other interruptions.

Another way End-User UAIs differ from UANs is that any given End-User UAI is restricted to serving a single user.
This protects users from interfering with each other within UAIs and means that any user who wants to use a UAI has to arrange for the UAI to be created and assigned.
The [Brokered UAI Management](Broker_Mode_UAI_Management.md) mode simplifies this process by providing automatic creation of and connection to UAIs using SSH logins. Once a user has an End-User UAI assigned,
the user may initiate any number of SSH sessions to that UAI (or, in the case of Broker UAIs the broker serving that UAI), but no other user will be recognized by the UAI when attempting to connect.
In case of Broker UAIs each unique user will be assigned a unique End-User UAI upon successful login. Multiple sessions of the same user will be will be forwarded by the Broker UAI to the same End-User UAI.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Special Purpose UAIs](Special_Purpose_UAIs.md)
