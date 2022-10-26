# Fixing incorrect number of PG Issues

## Scenario 1

**Symptom:** Ceph is reporting a `HEALTH_WARN` and the warning message is `1 pools have many more objects per pg than average`.

**Cause:**

When an additional pool to the store the CSM artifacts was introduced, it caused the amount of PGs created per OSD to not allow for the amount of data stored in that device.
This will typically be seen on three node Ceph clusters since the number of PGs is set by the number of OSDs.

**Fix:**

1. Get the current `pg_num` and `pgp_num` value for the pool that is warning.

   ```bash
   ceph osd pool get csm_admin_pool pg_num
   ceph osd pool get csm_admin_pool pgp_num
   ```

   Example Output:

   ```screen
   pg_num: 32
   pgp_num: 32
   ```

2. Set the new values.

   ```bash
   ceph osd pool set csm_admin_pool pg_num 64
   ceph osd pool set csm_admin_pool pgp_num 128
   ceph osd pool set csm_admin_pool pg_num_min 64
   ceph osd pool set csm_admin_pool pg_num_max 128
   ```

   Expected Output:

   **NOTE:** Each line in the below output is related to the line above and is only reflecting the output for each line above when it is executed.

   ```screen
   set pool 15 pg_num to 64
   set pool 15 pgp_num to 128
   set pool 15 pg_num_min to 64
   set pool 15 pg_num_max to 128
   ```

