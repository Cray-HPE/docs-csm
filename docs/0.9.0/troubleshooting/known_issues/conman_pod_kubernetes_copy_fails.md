# Copying file from the cray-conman pod fails
The 'tar' command is not installed in the pod image, so the usual kubernetes command to copy files from the cray-conman pod fails:
```
$ kubectl -n services cp cray-conman-92a6cb7d2a:/var/log/conman/console.x3000c1s2b0n1 console.x3000c1s2b0n1
Defaulting container name to cray-conman.
error: Internal error occurred: error executing command in container: failed to exec in container: failed to start exec "e5054fd1452d04993a1e200435416168476621b8a44b8019a45a225fcb5c36f7": OCI runtime exec failed: exec failed: container_linux.go:349: starting container process caused "exec: \"tar\": executable file not found in $PATH": unknown
```

The files may still be copied by executing the 'cat' command instead and redirecting the output to a file:
```
$ kubectl -n services exec cray-conman-92a6cb7d2a -- cat /var/log/conman/console.x3000c1s2b0n1 > console.x3000c1s2b0n1
```

The console logs are also collected in SMF and may be accessed through the system monitoring tools.