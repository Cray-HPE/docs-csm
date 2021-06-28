---
category: numbered
---

# UAI Management

An overview of the three methods of UAI management.

UAS supports two manual methods and one automated method of UAI management. These methods are:

-   Direct administrative UAI management
-   Legacy mode user-driven UAI management
-   UAI broker mode UAI management

This topic explains each of these UAI management methods.

## Direct administrative UAI management

Direct administrative UAI management allows HPE Cray EX administrators to:

-   Set up UAI brokers for the UAI broker mode of UAI management
-   Control UAIs that are created under one of the other two methods discussed in this topic.
-   Create end-user UAIs.

Administrators can create and manage end-user UAIs using the administrative UAI management API. This API provides commands for listing, creating, examining, and deleting UAIs. Such usage, however is not the intended use case as the other two UAI management methods are more efficient.

## Legacy mode user-driven UAI management

The legacy mode of UAI management gives users the authority to create, list, and delete UAIs that belong to them. While this method is a conceptually simple, it can lead to an unnecessary proliferation of UAIs belonging to a single user if the user is not careful to create UAIs only when needed. The legacy mode also cannot take advantage of UAI classes to create more than one kind of UAI for the needs of different users.

## Broker mode UAI management

The UAI broker mode creates and reuses UAIs on demand when a user logs into a broker UAI using SSH. A site may run multiple broker UAIs, each configured to create UAIs of a different class and each running with its own externally visible IP address. By choosing the correct IP address and logging into the broker, a user ultimately arrives in a UAI tailored for a given use case. Since the broker manages the underlying end-user UAIs, users need not be given authority to create UAIs directly and, therefore, cannot cause a proliferation of unneeded UAIs. Since the separate broker UAIs each run on different IP addresses with, potentially, different user authorizations configured, a site can control which users are given access to which classes of end-user UAIs.

