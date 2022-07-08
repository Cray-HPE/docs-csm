# NCN Workflows
This folder contains argo workflow template files for ncn operations

> NOTE: worker rebuild and its dependencies have to be submited to 
`worker-rebuild-workflow-files` configmap in `argo` workspace. It also has to be executed
from `cray-nls` REST APIs. `cray-nls` is responsible for rendering final argo template
such that we can control parallelism programmatically based on targeting worker nodes 

## Update worker rebuild template
```

```