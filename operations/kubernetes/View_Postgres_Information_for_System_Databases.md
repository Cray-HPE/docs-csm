# View Postgres Information for System Databases

Postgres uses SQL language to store and manage databases on the system. This procedure describes how to view and obtain helpful information about system databases, as well as the types of data being stored.

## Prerequisites

This procedure requires administrative privileges.

## Procedure

1. Log in to the Postgres container.

    ```bash
    ncn-mw# kubectl -n services exec -it cray-smd-postgres-0 -c postgres -- bash
    ```

    Example output:

    ```text
    Defaulting container name to postgres.
    Use 'kubectl describe pod/cray-smd-postgres-0 -n services' to see all of the containers in this pod.

     ____        _ _
    / ___| _ __ (_) | ___
    \___ \| '_ \| | |/ _ \
     ___) | |_) | | | (_) |
    |____/| .__/|_|_|\___/
          |_|

    This container is managed by runit, when stopping/starting services use sv

    Examples:

    sv stop cron
    sv restart patroni

    Current status: (sv status /etc/service/*)

    run: /etc/service/cron: (pid 26) 487273s
    run: /etc/service/patroni: (pid 24) 487273s
    run: /etc/service/pgqd: (pid 25) 487273s
    ```

1. Log in as the `postgres` user.

    ```bash
    postgres-container# psql -U postgres
    ```

    Example output:

    ```text
    psql (12.2 (Ubuntu 12.2-1.pgdg18.04+1), server 11.7 (Ubuntu 11.7-1.pgdg18.04+1))
    Type "help" for help.

    postgres=#
    ```

1. List the existing databases.

    ```text
    postgres# \l
    ```

    Example output:

    ```text
                                          List of databases
        Name    |      Owner      | Encoding |   Collate   |    Ctype    |   Access privileges
    ------------+-----------------+----------+-------------+-------------+-----------------------
     hmsds      | hmsdsuser       | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
     postgres   | postgres        | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
     service_db | service_account | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
     template0  | postgres        | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
                |                 |          |             |             | postgres=CTc/postgres
     template1  | postgres        | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
                |                 |          |             |             | postgres=CTc/postgres
    (5 rows)
    ```

1. Establish a connection to the desired database.

    In the example below, the `hmsds` database is used.

    ```text
    postgres# \c hmsds
    ```

    Example output:

    ```text
    psql (12.2 (Ubuntu 12.2-1.pgdg18.04+1), server 11.7 (Ubuntu 11.7-1.pgdg18.04+1))
    You are now connected to database "hmsds" as user "postgres".
    hmsds=#
    ```

1. List the data types that are in the database being viewed.

    ```text
    postgres# \dt
    ```

    Example output:

    ```text
                      List of relations
     Schema |          Name           | Type  |   Owner
    --------+-------------------------+-------+-----------
     public | comp_endpoints          | table | hmsdsuser
     public | comp_eth_interfaces     | table | hmsdsuser
     public | component_group_members | table | hmsdsuser
     public | component_groups        | table | hmsdsuser
     public | component_lock_members  | table | hmsdsuser
     public | component_locks         | table | hmsdsuser
     public | components              | table | hmsdsuser
     public | discovery_status        | table | hmsdsuser
     public | hwinv_by_fru            | table | hmsdsuser
     public | hwinv_by_loc            | table | hmsdsuser
     public | hwinv_hist              | table | hmsdsuser
     public | job_state_rf_poll       | table | hmsdsuser
     public | job_sync                | table | hmsdsuser
     public | node_nid_mapping        | table | hmsdsuser
     public | power_mapping           | table | hmsdsuser
     public | rf_endpoints            | table | hmsdsuser
     public | schema_migrations       | table | hmsdsuser
     public | scn_subscriptions       | table | hmsdsuser
     public | service_endpoints       | table | hmsdsuser
     public | system                  | table | hmsdsuser
    (20 rows)
    ```
