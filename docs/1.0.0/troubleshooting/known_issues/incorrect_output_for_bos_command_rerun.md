# BOS/BOA Incorrect command is output to rerun a failed operation.
When the Boot Orchestration Agent (BOA), an agent of the Boot Orchestration Service (BOS), encounters a failure, it issues a command to rerun the operation for any nodes that experienced the failure. However, the syntax of this command is faulty.

The faulty command includes squiggly braces around a comma separated list of quoted nodes. These squiggly braces, single quotes, and the spaces separating the individual nodes all need to be removed. Then, this reformatted command can be run.

Example of a faulty command in the BOA log:
```text
ERROR   - cray.boa.agent - You can attempt to boot these nodes by issuing the command:
cray bos v1 session create --template-uuid shasta-1.4-csm-bare-bones-image --operation boot --limit {'x3000c0s25b3n0', 'x3000c0s23b4n0', 'x3000c0s20b4n0', 'x3000c0s37b2n0', 'x1000c0s7b0n0', 'x1000c3s3b0n0', 'x1000c1s1b1n1', 'x1000c0s7b1n0', 'x1000c2s3b1n1', 'x3000c0s20b3n0', 'x3000c0s25b1n0', 'x3000c0s20b1n0', 'x3000c0s20b2n0', 'x3000c0s25b2n0', 'x3000c0s23b3n0', 'x3000c0s25b4n0', 'x1000c1s1b1n0', 'x3000c0s37b1n0', 'x3000c0s37b4n0', 'x1000c2s3b1n0', 'x3000c0s23b2n0', 'x3000c0s23b1n0', 'x1000c0s7b1n1', 'x3000c0s37b3n0', 'x1000c0s7b0n1'}
```

Example of the correct command:
```text
cray bos v1 session create --template-uuid shasta-1.4-csm-bare-bones-image --operation boot --limit x3000c0s25b3n0,x3000c0s23b4n0,x3000c0s20b4n0,x3000c0s37b2n0,x1000c0s7b0n0,x1000c3s3b0n0,x1000c1s1b1n1,x1000c0s7b1n0,x1000c2s3b1n1,x3000c0s20b3n0,x3000c0s25b1n0,x3000c0s20b1n0,x3000c0s20b2n0,x3000c0s25b2n0,x3000c0s23b3n0,x3000c0s25b4n0,x1000c1s1b1n0,x3000c0s37b1n0,x3000c0s37b4n0,x1000c2s3b1n0,x3000c0s23b2n0,x3000c0s23b1n0,x1000c0s7b1n1,x3000c0s37b3n0,x1000c0s7b0n1
```

Cut and paste the faulty command and assign to an environment variable.
```bash
linux# CMD="cray bos v1 session create --template-uuid shasta-1.4-csm-bare-bones-image --operation boot --limit {'x3000c0s25b3n0', 'x3000c0s23b4n0', 'x3000c0s20b4n0', 'x3000c0s37b2n0', 'x1000c0s7b0n0', 'x1000c3s3b0n0', 'x1000c1s1b1n1', 'x1000c0s7b1n0', 'x1000c2s3b1n1', 'x3000c0s20\
b3n0', 'x3000c0s25b1n0', 'x3000c0s20b1n0', 'x3000c0s20b2n0', 'x3000c0s25b2n0', 'x3000c0s23b3n0', 'x3000c0s25b4n0', 'x1000c1s1b1n0', 'x3000c0s37b1n0', 'x3000c0s37b4n0', 'x1000c2s3b1n0', 'x3000c0s23b2n0', 'x3000c0s23b1n0', 'x1000c0s7b1n1', 'x3000c0s37b3n0', 'x1000c0s7b0n\
1'}"
```

Then, paste this command to get the corrected output.
```bash
linux# echo $CMD |sed s/,\ /,/g|sed s/{//g|sed s/}//g|sed s/\'//g
```
