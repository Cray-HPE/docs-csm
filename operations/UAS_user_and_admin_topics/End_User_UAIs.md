---
category: numbered
---

# End-User UAIs

What User Access Instances \(UAIs\) are, what their purpose is, and how they differ from UANs.

## Purpose of end-user UAIs

UAIs used for interactive logins are called end-user UAIs. These UAIs are suitable for tasks that are immediate and interactive over relatively short time frames. Building and testing software, and launching workloads are two examples of such tasks. End-user UAIs are not suitable for unattended activities that require a long time period. Such activities include executing cron jobs or monitoring progress of a job in a logged-in shell. These types of activities, however, can be run if they are built into a custom UAI image.

## Differences between end-user UAIs and UANs

End-user UAIs behave like virtualized, lightweight User Access Nodes \(UANs\), but there are important differences between UAIs and UANs.

First, end-user UAIs are not dedicated hardware like UANs. They are implemented as containers orchestrated by Kubernetes, which makes them subject to Kubernetes scheduling and resource management rules. One key element of Kubernetes orchestration is impermanence. While in practice end-user UAIs are often long running, either of following can happen at any moment:

-   Kubernetes can reschedule or recreate them as needed at any moment to meet resource and node availability constraints.
-   An administrator can remove an UAI.

When either of these things happen, a new UAI may be created. That new UAI, however, will revert to its initial state, discarding any internal changes that might have been made in its previous instance. An administratively removed end-user UAI may or may not ever be recreated. Also, a preempted end-user UAI may become unavailable for an extended time until resource pressure is relieved.

The impermanence of end-user UAIs makes them suitable only for brief tasks and unsuitable for longer, unattended ones. The latter type of activities is more suited to UANs. UANs are more permanent and, unless they are reinstalled, retain modified state through reboots.

UAIs are restricted to serving a single user. This restriction is a second difference between end-user UAIs and UANs. UAIs thus protect users from interfering with each other. As a consequence, any user who wants to use a UAI has to arrange for the UAI to be created and assigned. Once a user has a UAI assigned, that user may initiate any number of SSH sessions to that UAI. The UAI, however, will not recognize any other user that attempts to connect.

**Parent topic:**[User Access Service \(UAS\)](User_Access_Service_UAS.md)

