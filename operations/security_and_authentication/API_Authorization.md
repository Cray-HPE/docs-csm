# API Authorization

Authorization for REST API calls is only done at the API gateway. This is facilitated through policy checks to the Open Policy Agent \(OPA\). Every REST API call into the system is sent to the OPA to make an authorization decision. The decision is based on the Authenticated JSON Web Token \(JWT\) passed into the request.

The following is a list of available personas and the supported REST API endpoints for each:

-   **`admin`**

    Authorized for every possible REST API endpoint.

-   **`user`**

    Authorized for a subset of endpoints to allow users to create and use User Access Instances \(UAI\), run jobs, view job results, and use capsules.

    REST API endpoints for the `user` persona:

    ```screen
    # UAS
    {"method": "GET", "path": `^/apis/uas-mgr/v1/$`}, # Get UAS API Version
    {"method": "GET", "path": `^/apis/uas-mgr/v1/uas$`}, # List UAIs for current user
    {"method": "POST", "path": `^/apis/uas-mgr/v1/uas$`}, # Create a UAI for current user
    {"method": "DELETE", "path": `^/apis/uas-mgr/v1/uas$`}, # Delete a UAI(s) for current user
    {"method": "GET", "path": `^/apis/uas-mgr/v1/images$`}, # List Available UAI Images
    {"method": "GET", "path": `^/apis/uas-mgr/v1/mgr-info$`}, # Get UAS Service Version
    # PALS
    {"method": "GET", "path": `^/apis/pals/v1/.*$`}, # All PALs API Calls - GET
    {"method": "PUT", "path": `^/apis/pals/v1/.*$`}, # All PALs API Calls - PUT
    {"method": "POST", "path": `^/apis/pals/v1/.*$`}, # All PALs API Calls - POST
    {"method": "DELETE", "path": `^/apis/pals/v1/.*$`}, # All PALs API Calls - DELETE
    {"method": "HEAD", "path": `^/apis/pals/v1/.*$`}, # All PALs API Calls - HEAD
    {"method": "PATCH", "path": `^/apis/pals/v1/.*$`}, # All PALs API Calls - PATCH
    # Replicant
    {"method": "GET", "path": `^/apis/rm/v1/report/[\d\w|-]+$`}, # Get Report by id
    {"method": "GET", "path": `^/apis/rm/v1/reports$`}, # Get Reports
    # Analytics Capsules
    {"method": "DELETE", "path": `^/apis/capsules/.*$`}, # All Capsules API Calls - DELETE
    {"method": "GET", "path": `^/apis/capsules/.*$`}, # All Capsules API Calls - GET
    {"method": "HEAD", "path": `^/apis/capsules/.*$`}, # All Capsules API Calls - HEAD
    {"method": "PATCH", "path": `^/apis/capsules/.*$`}, # All Capsules API Calls - PATCH
    {"method": "POST", "path": `^/apis/capsules/.*$`}, # All Capsules API Calls - POST
    {"method": "PUT", "path": `^/apis/capsules/.*$`}, # All Capsules API Calls - PUT
    ```

-   **`system-pxe`**

    Authorized for endpoints related to booting.

    REST API endpoints for the `system-pxe` persona:

    ```screen
    {"method": "GET",  "path": `^/apis/bss/.*$`},
    {"method": "HEAD",  "path": `^/apis/bss/.*$`},
    {"method": "POST",  "path": `^/apis/bss/.*$`},
    ```

-   **`system-compute`**

    Authorized for endpoints required by the Cray Operating System \(COS\) to manage compute nodes and NCN services.

    REST API endpoints for the `system-compute` persona:

    ```screen
    {"method": "GET",  "path": `^/apis/cfs/.*$`},
    {"method": "HEAD",  "path": `^/apis/cfs/.*$`},
    {"method": "PATCH",  "path": `^/apis/cfs/.*$`},

    {"method": "GET",  "path": `^/apis/v2/cps/.*$`},
    {"method": "HEAD",  "path": `^/apis/v2/cps/.*$`},
    {"method": "POST",  "path": `^/apis/v2/cps/.*$`},

    {"method": "GET",  "path": `^/apis/hbtd/.*$`},
    {"method": "HEAD",  "path": `^/apis/hbtd/.*$`},
    {"method": "POST",  "path": `^/apis/hbtd/.*$`},

    {"method": "GET",  "path": `^/apis/v2/nmd/.*$`},
    {"method": "HEAD",  "path": `^/apis/v2/nmd/.*$`},
    {"method": "POST",  "path": `^/apis/v2/nmd/.*$`},
    {"method": "PUT",  "path": `^/apis/v2/nmd/.*$`},

    {"method": "GET",  "path": `^/apis/smd/.*$`},
    {"method": "HEAD",  "path": `^/apis/smd/.*$`},

    {"method": "GET",  "path": `^/apis/hmnfd/.*$`},
    {"method": "HEAD",  "path": `^/apis/hmnfd/.*$`},
    {"method": "PATCH",  "path": `^/apis/hmnfd/.*$`},
    {"method": "POST",  "path": `^/apis/hmnfd/.*$`},
    {"method": "DELETE",  "path": `^/apis/hmnfd/.*$`},
    ```

-   **`wlm`**

    Authorized for endpoints related to the use of the Slurm or PBS workload managers.

    REST API endpoints for the `wlm` persona:

    ```screen
    # PALS - application launch
    {"method": "GET", "path": `^/apis/pals/.*$`},
    {"method": "HEAD", "path": `^/apis/pals/.*$`},
    {"method": "POST", "path": `^/apis/pals/.*$`},
    {"method": "DELETE", "path": `^/apis/pals/.*$`},
    # CAPMC - power capping
    {"method": "GET", "path": `^/apis/capmc/.*$`},
    {"method": "HEAD", "path": `^/apis/capmc/.*$`},
    {"method": "POST", "path": `^/apis/capmc/.*$`},
    # BOS - node boot
    {"method": "GET", "path": `^/apis/bos/.*$`},
    {"method": "HEAD", "path": `^/apis/bos/.*$`},
    {"method": "POST", "path": `^/apis/bos/.*$`},
    {"method": "PATCH", "path": `^/apis/bos/.*$`},
    {"method": "DELETE", "path": `^/apis/bos/.*$`},
    # SLS - hardware query
    {"method": "GET", "path": `^/apis/sls/.*$`},
    {"method": "HEAD", "path": `^/apis/sls/.*$`},
    # SMD - hardware state query
    {"method": "GET", "path": `^/apis/smd/.*$`},
    {"method": "HEAD", "path": `^/apis/smd/.*$`},
    # FC - VNI reservation
    {"method": "GET", "path": `^/apis/fc/.*$`},
    {"method": "HEAD", "path": `^/apis/fc/.*$`},
    {"method": "POST", "path": `^/apis/fc/.*$`},
    {"method": "PUT", "path": `^/apis/fc/.*$`},
    {"method": "DELETE", "path": `^/apis/fc/.*$`},
    ```

